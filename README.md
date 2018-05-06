# secure-webtty
A basic webtty you can use over the cloud with Basic Auth and Client SSL Certificate configured.

## Contents
- [Configuration](./config/README.md)
- [Authentication](./secrets/README.md)

## Get Started
The configurations are already reasonable. Set up the authentication by going through the steps in [the Authentication section](./secrets/README.md). Alternative, run:

```sh
npm run create-secrets;
# or to use defaults:
npm run create-secrets -- --auto
```

> For the prompt for *"Enter the DOMAIN for the CLIENT certificate"*, this has to be your domain name. When running locally, this should be `localhost`. If deploying onto `webtty.mydomain.com`, this should be `webtty.mydomain.com`.

From the generated files, move `./secrets/browser/user.pfx` out, this is the client-side authentication certificate that will be used when connecting on port 443.

This will provision everything you'll need and passwords/authentication credentials will be found in `./secrets/auth/.passwords`. You should move this file out of the repository before deploying.

After generating the secrets, run the following to get the system up:

```sh
docker build -t secure-webtty .;
docker run --name secure-webtty -p 8443:443 -p 8080:80 -p 8000:3000 secure-webtty;
```

To use Docker in the image, bind the path at `/var/run/docker.sock` to your host docker socket:

```sh
docker run --name secure-webtty -p 8443:443 -p 8080:80 -p 8000:3000 -v "/path/to/docker.sock:/var/run/docker.sock" secure-webtty;
```

You can now access the services via:

- https://localhost:8443 (ssl + basic-auth protected)
- http://localhost:8080 (basic-auth protected)
- http://localhost:8000 (unprotected endpoint)

To access the SSL protected variant, you will need to add the generated `./secrets/browser/user.pfx` to your browser.

The password for importing the certificate is under the `USER_CERT_PASSWORD` key in `./secrets/auth/.passwords`.

The username/password for basic authentication is under the `BASIC_AUTH` key in `./secrets/auth/.passwords`

## What's Inside
This image comes with some useful stuff to debug systems.

- mysql client tools
- redis client tools
- postgresql client tools
- mongo db client tools
- docker (with compose)
- kubectl
- bash
- git
- vim
- curl
- dnsutils
- python runtime
- ruby runtime
- node runtime

Be careful when deploying and exposing this!

## Development
To achieve a faster feedback loop, you may want to mount the secrets and configurations as volumes:

```sh
# build the docker image
docker build -t secure-webtty-dev .;

# run the docker image, the 'ro' binding is so that it doesn't remove our local copy
docker run --name secure-webtty-dev -p 8080:80 -p 8443:443 -p 8000:3000 \
  -v "$(pwd)/config/nginx.conf:/etc/nginx/nginx.conf:ro" \
  -v "$(pwd)/config/supervisord.conf:/root/supervisord.conf:ro" \
  -v "$(pwd)/config/.profile:/root/.profile:ro" \
  -v "$(pwd)/secrets/auth/basic:/etc/nginx/auth/basic:ro" \
  -v "$(pwd)/secrets/certs/cert.pem:/etc/nginx/certs/cert.pem:ro" \
  -v "$(pwd)/secrets/certs/key.pem:/etc/nginx/certs/key.pem:ro" \
  -v "$(pwd)/secrets/auth/user.crt:/etc/nginx/auth/user.crt:ro" \
  -v "$(pwd)/secrets/auth/passwords:/etc/nginx/auth/passwords:ro" \
secure-webtty-dev;

# interactively enter the docker container
docker exec -it secure-webtty-dev /bin/bash;
```