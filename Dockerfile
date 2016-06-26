FROM debian:jessie
MAINTAINER Bao Ho <hotribao@gmail.com>
LABEL description="Base Docker image for HAProxy with letsencrypt" \
      version="1.6.5"

EXPOSE 80 443 8888 514/udp

ENV HAPROXY_MAJOR 1.6
ENV HAPROXY_VERSION 1.6.5
ENV HAPROXY_MD5 5290f278c04e682e42ab71fed26fc082

ENV LUA_VERSION 5.3.0
ENV LUA_VERSION_SHORT 53

# for certbot
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie.backports.list

ENV BUILD_DEPS="curl gcc libc6-dev libpcre3-dev libssl-dev libreadline-dev make patch"
ENV RUN_DEPS="ca-certificates cron libssl1.0 libpcre3 logrotate nano rsyslog"

RUN set -x \
 && apt-get update && apt-get install -y --force-yes --no-install-recommends \
        $BUILD_DEPS \
        $RUN_DEPS \
 && apt-get install --no-install-recommends -yqq certbot -t jessie-backports

RUN cd /usr/src \
    && curl -R -O http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz \
    && tar zxf lua-${LUA_VERSION}.tar.gz \
    && rm lua-${LUA_VERSION}.tar.gz \
    && cd lua-${LUA_VERSION} \
    && make linux \
    && make INSTALL_TOP=/opt/lua${LUA_VERSION_SHORT} install

# see http://discourse.haproxy.org/t/dynamic-dns-resolution-does-not-work-for-me-after-1-6-4-to-1-6-5-upgrade/310/2
COPY haproxy-dns.patch /tmp

RUN curl -SL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" -o haproxy.tar.gz \
	&& echo "${HAPROXY_MD5}  haproxy.tar.gz" | md5sum -c \
	&& mkdir -p /usr/src/haproxy \
	&& tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
	&& rm haproxy.tar.gz \
	&& patch -d /usr/src/haproxy -p1 < /tmp/haproxy-dns.patch \
	&& rm /tmp/haproxy-*.patch \
	&& make -C /usr/src/haproxy \
        CPU=native \
		TARGET=linux2628 \
        USE_LUA=1 \
		USE_LUA=yes LUA_LIB=/opt/lua53/lib/ \
        LUA_INC=/opt/lua53/include/ LDFLAGS=-ldl \
        USE_OPENSSL=1 \
		USE_PCRE=1 PCREDIR= \
        USE_ZLIB=1 \
		all \
		install-bin \
	&& mkdir -p /etc/haproxy \
	&& rm -rf /usr/src/haproxy \
	&& apt-get purge -y --auto-remove $BUILD_DEPS

RUN groupadd haproxy \
 && useradd -r -g haproxy haproxy \
 && groupadd syslog \
 && useradd -r -g syslog syslog

RUN mkdir -p /etc/haproxy.d \
  && mkdir -p /etc/rsyslog.d \
  && mkdir -p /etc/letsencrypt \
  && mkdir -p /etc/logrotate.d \
  && mkdir -p /var/lib/haproxy \
  && mkdir -p /var/log/haproxy \
  && chown root:syslog /var/log

# See https://github.com/janeczku/haproxy-acme-validation-plugin
COPY haproxy-acme-validation-plugin/acme-http01-webroot.lua /etc/haproxy
COPY haproxy-acme-validation-plugin/cert-renewal-haproxy.sh /

# configure logging, have haproxy send logs via rsyslog
#
COPY etc/rsyslog.conf /etc/rsyslog.conf
COPY etc/rsyslog.d/30-haproxy.conf /etc/rsyslog.d/30-haproxy.conf
COPY etc/logrotate.d/haproxy /etc/logrotate.d/haproxy

COPY script/docker-entrypoint.sh /
COPY script/certs.sh /

RUN chmod 777 /docker-entrypoint.sh \
 && chmod 777 /certs.sh \
 && chmod 777 /cert-renewal-haproxy.sh

COPY errors.tar.gz /tmp/
RUN tar -zxf /tmp/errors.tar.gz -C /etc/haproxy/ \
    && rm /tmp/errors.tar.gz

# schedule cert renewal weekly
RUN crontab -l | { cat; echo "5 8 * * 6 /cert-renewal-haproxy.sh"; } | crontab -

VOLUME /etc/letsencrypt
VOLUME /etc/haproxy.d
VOLUME /var/log

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy"]
