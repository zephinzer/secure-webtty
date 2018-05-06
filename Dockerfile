FROM node:8-alpine
WORKDIR /app
RUN apk update --no-cache \
  && apk add --no-cache bash jq vim git nginx make g++ mysql-client redis postgresql-client mongodb-tools curl bind-tools docker python py-pip ruby \
  && pip install docker-compose supervisor \
  && curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
  && chmod +x kubectl \
  && mv kubectl /usr/local/bin/kubectl
## this section is always run
COPY . /app
RUN chmod +x /app/src/app.js \
  && cp ./config/supervisord.conf /root/supervisord.conf \
## nginx server configurations
  && mkdir -p /run/nginx \
  && rm -rf /etc/nginx/nginx.conf \
  && cp ./config/nginx.conf /etc/nginx/nginx.conf \
## nginx authentication configurations
  && mkdir -p /etc/nginx/auth \
  && mkdir -p /etc/nginx/certs \
  && cp ./secrets/auth/basic /etc/nginx/auth/basic \
  && cp ./secrets/certs/cert.pem /etc/nginx/certs/cert.pem \
  && cp ./secrets/certs/key.pem /etc/nginx/certs/key.pem \
  && cp ./secrets/auth/user.crt /etc/nginx/auth/user.crt \
  && cp ./secrets/auth/passwords /etc/nginx/auth/passwords \
## .profile configurations
  && cp ./config/.profile /root/.profile \
  && printf -- "source /root/.profile;" >> /root/.bashrc \
  && npm i
WORKDIR /app
# for nginx basic-auth
EXPOSE 80
# for nginx basic-auth + ssl-auth
EXPOSE 443
# for naked application
EXPOSE 3000
VOLUME [ \
  "/var/run/docker.sock" \
]
ENTRYPOINT [ "/app/docker-entrypoint.sh" ]