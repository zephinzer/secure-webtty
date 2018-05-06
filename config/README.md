# Config Directory
This directory contains configuration related files for the server.

## .profile
This gives us a nicer layout when logging into the system via the TTY.

## nginx.conf
This configures the `nginx` service.

## supervisord.conf
This controls the `supervisord` service and allows for both `nginx` and the webtty service to run at the same time.

## Docker Volume Mappings
Assuming you are running the Docker image locally, use the following `-v` flags to map the files correctly:

```sh
-v "$(pwd)/config/nginx.conf:/etc/nginx/nginx.conf" \
-v "$(pwd)/config/supervisord.conf:/root/supervisord.conf" \
-v "$(pwd)/config/.profile:/root/.profile" \
```