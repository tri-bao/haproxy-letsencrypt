Scripts in this folder were downloaded from https://github.com/janeczku/haproxy-acme-validation-plugin/releases

Then customizing the following

cert-renewal-haproxy.sh
* Remove EMAIL variable as it is set in system-wide environment variable (when
   starting a container)
* LE_CLIENT="certbot"
* HAPROXY_RELOAD_CMD="pkill -HUP haproxy"
* WEBROOT="/var/lib/haproxy" (the chroot folder)


