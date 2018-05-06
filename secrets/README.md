# Secrets Directory
This directory should contain authentication details and certificates for the server.

## Automatic Generation
To automatically generate the required files, run the following from the project root:

```sh
./provisioning/create-secrets.sh --auto
```

For manual generation, read on below...

## Basic Authentication
Run the following from the project root to generate the appropriate files:

```sh
htpasswd -c ./secrets/auth/basic user;
# enter password for the user "user"
```

## SSL Client Certificate Authentication

### Generate self-signed server SSL certificates
Create a file at `./secrets/auth/passwords` with the password you used to create the `.pem` files.

```sh
PASSWORD="__YOUR_PASSWORD__";
printf -- "${PASSWORD}" > ./secrets/auth/passwords;
```

Run the following from the project root to generate the appropriate files:

```sh
openssl req \
  -x509 \
  -newkey rsa:4096 \
  -keyout ./secrets/certs/key.pem \
  -passout pass:$(cat ./secrets/auth/passwords) \
  -out ./secrets/certs/cert.pem \
  -days 365 \
  -subj '/CN=secure-webtty.com/O=Secure WebTTY/C=SG';
```

### Generate client authentication SSL certificates

Run the following from the project root to generate the appropriate files:

```sh
# create the certifcate authority (ca)
openssl genrsa \
  -des3 \
  -out ./secrets/ca.key \
  -passout pass:$(cat ./secrets/auth/passwords) \
  4096;
# create the certificate of the ca
openssl req \
  -new \
  -x509 \
  -key ./secrets/ca.key \
  -passin pass:$(cat ./secrets/auth/passwords) \
  -out ./secrets/ca.crt \
  -days 365 \
  -subj '/CN=secure-webtty.com/O=Secure WebTTY/C=SG';
# create the user
openssl genrsa \
  -des3 \
  -out ./secrets/user.key \
  -passout pass:$(cat ./secrets/auth/passwords) \
  4096;
# create the user certificate signing request (csr)
openssl req \
  -new \
  -key ./secrets/user.key \
  -passin pass:$(cat ./secrets/auth/passwords) \
  -out ./secrets/user.csr \
  -subj '/CN=secure-webtty.com/O=Secure WebTTY/C=SG';
# sign the user csr with the ca's certificate
openssl x509 \
  -req \
  -days 365 \
  -in ./secrets/user.csr \
  -CA ./secrets/ca.crt \
  -CAkey ./secrets/ca.key \
  -passin pass:$(cat ./secrets/auth/passwords) \
  -set_serial 01 \
  -out ./secrets/auth/user.crt;
# export the user's certificate into pfx format
openssl pkcs12 \
  -export \
  -out ./secrets/browser/user.pfx \
  -inkey ./secrets/user.key \
  -passin pass:$(cat ./secrets/auth/passwords) \
  -in ./secrets/auth/user.crt \
  -passout pass:$(cat ./secrets/auth/passwords) \
  -certfile ./secrets/ca.crt;
```

Copy the `./secrets/browser/user.pfx` file out. This will be imported into your browser to provide you access to the server.

## Docker Volume Mappings
Assuming you are running the Docker image locally, use the following `-v` flags to map the files correctly according to the `./config/nginx.conf` configuration file:

```sh
-v "$(pwd)/secrets/auth/basic:/etc/nginx/auth/basic" \
-v "$(pwd)/secrets/certs/cert.pem:/etc/nginx/certs/cert.pem" \
-v "$(pwd)/secrets/certs/key.pem:/etc/nginx/certs/key.pem" \
-v "$(pwd)/secrets/auth/user.crt:/etc/nginx/auth/user.crt" \
-v "$(pwd)/secrets/auth/passwords:/etc/nginx/auth/passwords" \
```

## References
- https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/
- https://fardog.io/blog/2017/12/30/client-side-certificate-authentication-with-nginx/
- https://stackoverflow.com/questions/33084347/pass-cert-password-to-nginx-with-https-site-during-restart