FROM alpine:latest

RUN apk add --no-cache dhcp curl tftp-hpa
VOLUME /data
ADD tftpboot /data/tftpboot
ADD dhcpd.sh /dhcpd
EXPOSE 67 67/udp 547 547/udp 647 647/udp 847 847/udp 69 69/udp 4100-4110/udp

ENTRYPOINT ["/dhcpd"]
CMD ["-f" "-cf" "/data/dhcpd.conf" "-lf" "/data/dhcpd.leases" "--no-pid"]
