FROM new5tt/php-docker:7.4

LABEL author="new5tt"
LABEL description="build php and nginx environment base alpine linux"
LABEL version="1.0.0"

ARG BASE_DIR="/opt/websrv"

ENV NGINX_VERSION="nginx-1.18.0" \
 PCRE_VERSION="pcre-8.43" \
 ZLIB_VERSION="zlib-1.2.11" \
 CONFIG_DIR="${BASE_DIR}/config" \
 INSTALL_DIR=${BASE_DIR}/program/nginx \
 EXTEND="gcc g++ make bzip2 perl openssl-dev file" \
 WWWROOT_DIR="${BASE_DIR}/data/wwwroot"

 ENV NGINX_URL="http://nginx.org/download/${NGINX_VERSION}.tar.gz" \
 PCRE_URL="https://ftp.pcre.org/pub/pcre/${PCRE_VERSION}.tar.gz" \
 ZLIB_URL="http://zlib.net/${ZLIB_VERSION}.tar.gz" \
 CONFIGURE="./configure \
 --user=www \
 --group=wwww \
 --prefix=${INSTALL_DIR} \
 --conf-path=${CONFIG_DIR}/nginx/nginx.conf \
 --error-log-path=${BASE_DIR}/logs/error.log \
 --http-log-path=${BASE_DIR}/logs/access.log \
 --lock-path=${BASE_DIR}/tmp/nginx.lock \
 --pid-path=${BASE_DIR}/tmp/nginx.pid \
 --sbin-path=${INSTALL_DIR}/sbin/nginx \
 --with-http_v2_module \
 --with-http_slice_module \
 --with-http_addition_module \
 --with-http_dav_module \
 --with-http_degradation_module \
 --with-http_flv_module \
 --with-http_gzip_static_module \
 --with-http_mp4_module \
 --with-http_random_index_module \
 --with-http_realip_module \
 --with-http_secure_link_module \
 --with-http_ssl_module \
 --with-http_stub_status_module \
 --with-http_sub_module \
 --with-mail \
 --with-mail_ssl_module \
 --with-pcre=/tmp/${PCRE_VERSION} \
 --with-stream_realip_module \
 --with-stream_ssl_module \
 --with-zlib=/tmp/${ZLIB_VERSION}"

WORKDIR /tmp
COPY    conf ./conf
COPY errors ${BASE_DIR}/data/errors

RUN \
 sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories &&\
 apk update && apk add --no-cache tzdata &&\
 cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
 echo 'Asia/Shanghai' > /etc/timezone &&\
 apk del tzdata &&\
 rm -rf /var/cache/apk/*
 
RUN apk update && apk add ${EXTEND} &&\
 wget ${NGINX_URL} &&\
 wget ${PCRE_URL} &&\
 wget ${ZLIB_URL} &&\
 tar -zxf ${NGINX_VERSION}.tar.gz &&\
 tar -zxf ${PCRE_VERSION}.tar.gz &&\
 tar -zxf ${ZLIB_VERSION}.tar.gz &&\
 mkdir -p ${WWWROOT_DIR} ${BASE_DIR}/logs ${BASE_DIR}/tmp ${CONFIG_DIR}/nginx/certs.d &&\
 addgroup wwww && adduser -H -D -G wwww www &&\
 cd ${NGINX_VERSION} &&\
 ${CONFIGURE} &&\
 make && make install &&\
 ln -s ${INSTALL_DIR}/sbin/nginx /usr/bin/nginx &&\
 cp -Rf /tmp/conf/* ${CONFIG_DIR}/nginx &&\
 apk del ${EXTEND} &&\
 rm -rf /var/cache/apk/* &&\
 rm -rf /tmp/*

VOLUME ["${CONFIG_DIR}/nginx/conf.d", "${CONFIG_DIR}/nginx/certs.d", "${BASE_DIR}/logs", "${WWWROOT_DIR}", "${BASE_DIR}/tmp"]

EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]