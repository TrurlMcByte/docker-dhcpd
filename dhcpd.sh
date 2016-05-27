#!/bin/sh

#FIXED="08:00:27:94:FB:73 core01 192.168.1.51; 08:00:27:61:7F:00 core02 192.168.1.52; 08:00:27:7B:DC:84 core03 192.168.1.53"

mkdir -p /data

#set -x
if test ! -s /data/dhcpd.conf ; then
    if test "${CONF_URL}" ; then
        curl -s "${CONF_URL}" > /data/dhcpd.conf
    else
        DEF_CIDR=$(ip -o -4 ad show scope global up | awk '{print $4; exit}')
        DEF_IP=${DEF_CIDR%/*}
        DEF_MASK=${DEF_CIDR#*/}
        DEF_NETMASK=`awk -v num="${DEF_MASK}"  'BEGIN{for (i=1; i<=4; i++){ if (num>=8) printf 255; else if (num<=0) printf 0; else printf 256-2^(8-num); if (i<=3) printf "."; num-=8 }}'`
        DEF_SUBNET=`awk -vip="${DEF_IP}" -vmask="${DEF_NETMASK}" 'BEGIN{split(ip,a, "."); split(mask,b,".");for(i=1;i<=4;i++)a[i]=b[i]==255?a[i]:b[i];;for(i=1;i<=3;i++)printf a[i]".";printf a[4]}'`
        DEF_ROUTER=`ip -o ro get 8.8.8.8 | awk '{print $3; exit}'`
        C_DNS=${DNS:-8.8.8.8, 8.8.4.4}
        C_IP=${IP:-$DEF_IP}
        C_SUBNET=${SUBNET:-$DEF_SUBNET}
        C_NETMASK=${NETMASK:-$DEF_NETMASK}
        C_ROUTER=${ROUTER:-$DEF_ROUTER}

        test "${TFTP}" && TFTPIP=${C_IP}

        echo "#generated" > /data/dhcpd.conf
        echo "allow booting;" >> /data/dhcpd.conf
        echo "allow bootp;" >> /data/dhcpd.conf
        echo "ddns-update-style none;" >> /data/dhcpd.conf
        test "${DOMAIN}" && echo "option domain-name \"$DOMAIN\";" >> /data/dhcpd.conf
        echo "option domain-name-servers ${C_DNS};" >> /data/dhcpd.conf
        echo "option routers ${C_ROUTER};" >> /data/dhcpd.conf
        echo "option ntp-servers ${C_IP};" >> /data/dhcpd.conf
        echo "default-lease-time 7776000;" >> /data/dhcpd.conf
        echo "subnet ${C_SUBNET} netmask ${C_NETMASK} {" >> /data/dhcpd.conf
        test "${RANGE}" && echo "  range dynamic-bootp ${RANGE};" >> /data/dhcpd.conf
        echo "  default-lease-time 7776000;" >> /data/dhcpd.conf
        echo "  max-lease-time     2592000;" >> /data/dhcpd.conf
        test "${BOOTFILE}" && echo "  filename \"${BOOTFILE}\";" >> /data/dhcpd.conf
        test "${TFTPIP}" && echo "  next-server ${TFTPIP};" >> /data/dhcpd.conf
        test "${FIXED}" && echo "${FIXED}" | awk 'BEGIN{FS="[, ]+"; RS="[;\n][ ]*"} $3 { print " host " $2 " { hardware ethernet " $1 "; fixed-address " $3 "; }"}' >> /data/dhcpd.conf
        echo "}" >> /data/dhcpd.conf
    fi
fi

if test "${TFTP}" ; then
    mkdir -p /data/tftpboot
    if test ! -d /data/tftpboot/pxelinux.cfg; then
        mkdir -p /data/tftpboot/pxelinux.cfg
        if test "${COREOS}"; then
            echo 'Check kernel...'
            test ! -f /data/tftpboot/coreos_production_pxe.vmlinuz && \
                curl --progress-bar -o /data/tftpboot/coreos_production_pxe.vmlinuz https://${COREOS}.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz  2>&1 | tr -s "\r #" "\n"
            echo 'done, check image...'
            test ! -f /data/tftpboot/coreos_production_pxe_image.cpio.gz && \
                curl --progress-bar -o /data/tftpboot/coreos_production_pxe_image.cpio.gz https://${COREOS}.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz 2>&1 | tr -s "\r #" "\n"
            echo 'done'
            cat /data/tftpboot/default.pre > /data/tftpboot/pxelinux.cfg/default
            test "${PXE_AUTOLOGIN}" && sed -i "/append initrd/ s^$^ console=tty0 console=ttyS0 coreos.autologin=tty1 coreos.autologin=ttyS0^" /data/tftpboot/pxelinux.cfg/default
            test "${CLOUD_CONFIG}" && sed -i "/append initrd/ s^$^ cloud-config-url=${CLOUD_CONFIG}^" /data/tftpboot/pxelinux.cfg/default
        fi

    fi
    /usr/sbin/in.tftpd -l --port-range 4100:4110 --address 0.0.0.0:69 --secure "/data/tftpboot"
fi

if test ! -f /data/dhcpd.leases ; then
    touch /data/dhcpd.leases
fi

exec /usr/sbin/dhcpd $@
