#!/bin/sh
NGINX_UP=0;
if [ "${@}" ] && [ -z "${@##*"--nginx"*}" ]; then
  printf -- 'Waiting for nginx to be up before clearing secrets..';
  while [ $NGINX_UP -eq 0 ]; do
    printf -- '.';
    sleep 1;
    ps | grep nginx;
    if [ "$?" = "0" ]; then NGINX_UP=1; fi;
  done;
  printf -- '. Nginx is up. ';
fi;

printf -- 'Clearing secrets... ';

rm -rf \
  ./secrets/auth/basic \
  ./secrets/auth/passwords \
  ./secrets/auth/.passwords \
  ./secrets/auth/*.crt \
  ./secrets/browser/*.crt \
  ./secrets/browser/*.pfx \
  ./secrets/certs/*.pem \
  ./secrets/*.key \
  ./secrets/*.csr \
  ./secrets/*.crt \
;

if [ "${@}" ] && [ -z "${@##*"--nginx"*}" ]; then
  rm -rf \
    /etc/nginx/certs/cert.pem \
    /etc/nginx/certs/key.pem \
    /etc/nginx/auth/passwords \
    /etc/nginx/auth/user.crt \
  ;
fi;

printf -- '\033[32m\033[1mDONE\033[0m\n';