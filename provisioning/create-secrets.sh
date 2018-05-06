#!/bin/sh
CURRDIR="$(dirname $0)";

# > error handling
handle_quit() {
  RECEIVED_SIGNAL="$1";
  set +e;
  stty echo;
  printf -- "\n\033[31m\033[1mAn error occurred (${RECEIVED_SIGNAL}), cleaning up...\033[0m ";
  ${CURRDIR}/clear-secrets.sh;
  printf -- '\033[31m\033[1mDONE.\033[0m\n';
  exit 255;
}
trap 'handle_quit "SIGQUIT"' QUIT;
trap 'handle_quit "SIGINT"' INT;
trap 'handle_quit "SIGTERM"' TERM;
trap 'handle_quit "SIGKILL"' KILL;
trap 'handle_quit "SIGHUP"' HUP;
trap 'handle_quit "exit code 1"' 1;
# / error handling

# > configuration
PASSWORD_LENGTH=20;
DOT_PASSWORDS_PATH="${CURRDIR}/../secrets/auth/.passwords";
PASSWORDS_PATH="${CURRDIR}/../secrets/auth/passwords";
BASIC_AUTH_PATH="${CURRDIR}/../secrets/auth/basic";
# / configuration

# > defaults
USER_NAME='user';
USER_PASSWORD="$(cat /dev/urandom | head -c ${PASSWORD_LENGTH} | base64 | tr -dc 'a-zA-Z0-9')";
USER_CERT_PASSWORD="$(cat /dev/urandom | head -c ${PASSWORD_LENGTH} | base64 | tr -dc 'a-zA-Z0-9')";
USER_CERT_ID='Secure WebTTY';
USER_CERT_DOMAIN='localhost';
SERVER_CERT_PASSWORD="$(cat /dev/urandom | head -c ${PASSWORD_LENGTH} | base64 | tr -dc 'a-zA-Z0-9')";
# /defaults

if [ "${@}" ] && [ -z "${@##*"--auto"*}" ]; then
  printf -- 'Credentials were automatically provisioned.\n';
else
  printf -- "Enter the USERNAME for *BASIC AUTH* (\033[90mdefaults to \"${USER_NAME}\"\033[0m): ";
  read -p '' USER_NAME_ENTERED;
  if [ -n "${USER_NAME_ENTERED}" ]; then USER_NAME="${USER_NAME_ENTERED}"; fi;

  printf -- "Enter the PASSWORD for *BASIC AUTH* (\033[90mdefaults to \"${USER_PASSWORD}\"\033[0m): ";
  stty -echo && read -p  '' USER_PASSWORD_ENTERED && stty echo && printf -- '\n';
  if [ -n "${USER_PASSWORD_ENTERED}" ]; then USER_PASSWORD="${USER_PASSWORD_ENTERED}"; fi;

  printf -- "Enter the PASSWORD for the *SERVER* certificate generation (\033[90mdefaults to \"${SERVER_CERT_PASSWORD}\"\033[0m): ";
  stty -echo && read -p '' SERVER_CERT_PASSWORD_ENTERED && stty echo && printf -- '\n';
  if [ -n "${SERVER_CERT_PASSWORD_ENTERED}" ]; then SERVER_CERT_PASSWORD="${SERVER_CERT_PASSWORD_ENTERED}"; fi;

  printf -- "Enter the PASSWORD for the *CLIENT* certificate authentication (\033[90mdefaults to \"${USER_CERT_PASSWORD}\"\033[0m): ";
  stty -echo && read -p '' USER_CERT_PASSWORD_ENTERED && stty echo && printf -- '\n';
  if [ -n "${USER_CERT_PASSWORD_ENTERED}" ]; then USER_CERT_PASSWORD="${USER_CERT_PASSWORD_ENTERED}"; fi;

  printf -- "Enter the DOMAIN for the *CLIENT* certificate (\033[90mdefaults to \"${USER_CERT_DOMAIN}\"\033[0m): ";
  read -p '' USER_CERT_DOMAIN_ENTERED;
  if [ -n "${USER_CERT_DOMAIN_ENTERED}" ]; then USER_CERT_DOMAIN="${USER_CERT_DOMAIN_ENTERED}"; fi;

  printf -- "Enter the CERT IDENTIFIER for the *CLIENT* certificate (\033[90mdefaults to \"${USER_CERT_ID}\"\033[0m): ";
  read -p '' USER_CERT_ID_ENTERED;
  if [ -n "${USER_CERT_ID_ENTERED}" ]; then USER_CERT_ID="${USER_CERT_ID_ENTERED}"; fi;
fi;

printf -- '' > "${DOT_PASSWORDS_PATH}";
printf -- "BASIC_AUTH:${USER_NAME}:${USER_PASSWORD}\n" >> "${DOT_PASSWORDS_PATH}";
printf -- "USER_CERT_DOMAIN:${USER_CERT_DOMAIN}\n" >> "${DOT_PASSWORDS_PATH}";
printf -- "USER_CERT_ID:${USER_CERT_ID}\n" >> "${DOT_PASSWORDS_PATH}";
printf -- "USER_CERT_PASSWORD:${USER_CERT_PASSWORD}\n" >> "${DOT_PASSWORDS_PATH}";
printf -- "SERVER_CERT_PASSWORD:${SERVER_CERT_PASSWORD}" >> "${DOT_PASSWORDS_PATH}";

printf -- "\033[1mCREDENTIALS GENERATION > ${DOT_PASSWORDS_PATH}\n\033[0m";

printf -- "Creating the certificate passwords file at ${PASSWORDS_PATH}... ";
printf -- "${SERVER_CERT_PASSWORD}\n${USER_CERT_PASSWORD}" > "${PASSWORDS_PATH}";
printf -- '\033[1m\033[32mDONE.\033[0m\n';

# create basic auth stuff
printf -- "Creating the password files at ${BASIC_AUTH_PATH}... ";
stty -echo && htpasswd -b -c "${BASIC_AUTH_PATH}" "${USER_NAME}" "${USER_PASSWORD}" && stty echo;
if [ "$?" = "0" ]; then 
  printf -- '\033[1m\033[32mDONE.\033[0m\n';
else
  handle_quit;
fi;

printf -- "Verifying BASIC AUTH credentials at ${BASIC_AUTH_PATH}... ";
htpasswd -b -v "${BASIC_AUTH_PATH}" "${USER_NAME}" "${USER_PASSWORD}";
if [ "$?" = "0" ]; then 
  printf -- '\033[1m\033[32mDONE.\033[0m\n';
else
  handle_quit;
fi;

printf -- 'Creating the server KEY & CERTIFICATE at ./secrets/certs/key.pem and ./secrets/certs/cert.pem... ';
# generate server certificate
openssl req \
  -x509 \
  -newkey rsa:4096 \
  -keyout ./secrets/certs/key.pem \
  -passout pass:${SERVER_CERT_PASSWORD} \
  -out ./secrets/certs/cert.pem \
  -days 365 \
  -subj "/CN=${USER_CERT_DOMAIN}/O=${USER_CERT_ID}/C=US";
printf -- '\033[32m\033[1mDONE\033[0m\n';

printf -- 'Creating the CERTIFICATE AUTHORITY key at ./secrets/ca.key... ';
# create the certifcate authority (ca)
openssl genrsa \
  -des3 \
  -out ./secrets/ca.key \
  -passout pass:${SERVER_CERT_PASSWORD} \
  4096;
printf -- '\033[32m\033[1mDONE\033[0m\n';

printf -- 'Creating the CERTIFICATE AUTHORITY certifcate at ./secrets/ca.crt... ';
# create the certificate of the ca
openssl req \
  -new \
  -x509 \
  -key ./secrets/ca.key \
  -passin pass:${SERVER_CERT_PASSWORD} \
  -out ./secrets/ca.crt \
  -days 365 \
  -subj "/CN=${USER_CERT_DOMAIN}/O=${USER_CERT_ID}/C=US";
printf -- '\033[32m\033[1mDONE\033[0m\n';

printf -- 'Creating the USER private key at ./secrets/user.key... ';
# create the user
openssl genrsa \
  -des3 \
  -out ./secrets/user.key \
  -passout pass:${SERVER_CERT_PASSWORD} \
  4096;
printf -- '\033[32m\033[1mDONE\033[0m\n';

printf -- 'Creating the USER certificate signing request (CSR) at ./secrets/user.csr... ';
# create the user certificate signing request (csr)
openssl req \
  -new \
  -key ./secrets/user.key \
  -passin pass:${SERVER_CERT_PASSWORD} \
  -out ./secrets/user.csr \
  -subj "/CN=${USER_CERT_DOMAIN}/O=${USER_CERT_ID}/C=US";
printf -- '\033[32m\033[1mDONE\033[0m\n';

printf -- 'Signing USER certificate signing request (CSR) at ./secrets/auth/user.crt... ';
# sign the user csr with the ca's certificate
openssl x509 \
  -req \
  -days 365 \
  -in ./secrets/user.csr \
  -CA ./secrets/ca.crt \
  -CAkey ./secrets/ca.key \
  -passin pass:${SERVER_CERT_PASSWORD} \
  -set_serial 01 \
  -out ./secrets/auth/user.crt;
printf -- '\033[32m\033[1mDONE\033[0m\n';

printf -- 'Exporting user certificate into pfx at ./secrets/browser/user.pfx... ';
# export the user's certificate into pfx format
openssl pkcs12 \
  -export \
  -out ./secrets/browser/user.pfx \
  -inkey ./secrets/user.key \
  -passin pass:${SERVER_CERT_PASSWORD} \
  -in ./secrets/auth/user.crt \
  -passout pass:${USER_CERT_PASSWORD} \
  -certfile ./secrets/ca.crt;
printf -- '\033[32m\033[1mDONE\033[0m\n';

printf -- '\n\033[32m\033[1mALL SECRETS SUCCESSFULLY CREATED\033[0m\n';
