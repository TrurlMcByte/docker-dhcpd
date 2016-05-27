# docker-dhcpd

Dockerized isc-dhcp with tftp

## Usage

Recommended to run it in `--net=host` mode only

```bash
docker run -d --restart=always --name some_dhcpd_container_name \
  --net=host \
  -v dhcpd_data:/data \
  -e DOMAIN="example.org" \
  trurlmcbyte/dhcpd:latest
```

where `dhcpd_data` is named data volume (will be created automaticaly on first run and usually placed in `/var/lib/docker/volumes`)

## Env setting

* `DOMAIN` - default domain name (option domain-name), by default not set
* `DNS` - list of dns servers, default "`8.8.8.8, 8.8.4.4`"
* `IP`, `SUBNET`, `NETMASK`, `ROUTER` - network settings, by default will try to detect automatically
* `RANGE` - range IP's to lease (for example `192.168.0.150 192.168.0.250`, no default)
* `FIXED` - list of presetted host in format "`MAC-addr`, `hostname`, `IP`" per line or separated by '`;`'

for example 
`-e FIXED="08:00:27:94:FB:73 core01 192.168.1.51; 08:00:27:61:7F:00 core02 192.168.1.52"`
or 
```
    -e FIXED='
08:00:27:94:FB:73 core01 192.168.1.51
08:00:27:61:7F:00 core02 192.168.1.52
08:00:27:7B:DC:84 core03 192.168.1.53' \
```


### tftp server

* `TFTP` - enable builtin tftp server if set
* `TFTPIP` - IP of tftp server (if not used builtin - no any default)
* `COREOS=stable` - use PXE images for coreos (download it automatically), one of `stable`,`beta`,`alpha`
* `PXE_AUTOLOGIN` - enable autologin on PXE (only) if set
* `CLOUD_CONFIG` - cloud-config-url, configuration file or bootstrap script


