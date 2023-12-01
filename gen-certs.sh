#!/usr/bin/env bash

set -ue

CERT_PATH=${CERT_PATH:-/tmp}
ROOT_CA_CERTS_NAME=${ROOT_CA_CERT_NAME:-cluster-ca}
CLIENT_CERTS_NAME=${CLIENT_CERTS_NAME:-client}

mkdir -p "$CERT_PATH";
echo "Generating certificates to $CERT_PATH"
openssl req -new -x509 -nodes -out "$CERT_PATH/$ROOT_CA_CERTS_NAME".pem -keyout "$CERT_PATH/$ROOT_CA_CERTS_NAME".key -subj "/CN=cluster-ca"


openssl req  -noenc -new -newkey \
  rsa:2048 \
  -keyout "$CERT_PATH/$CLIENT_CERTS_NAME".key \
  -out "$CERT_PATH/$CLIENT_CERTS_NAME".csr \
  -subj "/CN=rskafka/OU=TEST/O=rskafka/L=Oslo/C=NO";

openssl x509 -req \
  -CA "$CERT_PATH/$ROOT_CA_CERTS_NAME".pem \
  -CAkey "$CERT_PATH/$ROOT_CA_CERTS_NAME".key \
  -in "$CERT_PATH/$CLIENT_CERTS_NAME".csr \
  -out "$CERT_PATH/$CLIENT_CERTS_NAME"-signed.pem \
  -sha256 \
  -days 365 \
  -CAcreateserial \
  -extensions v3_req \
  -extfile <(cat <<EOF
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
commonName =  rskafka
[ v3_req ]
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
DNS.2 = kafka-0
DNS.3 = kafka-1
DNS.4 = kafka-2
EOF
);

openssl pkcs8 \
  -topk8 \
  -in "$CERT_PATH/$CLIENT_CERTS_NAME".key \
  -out "$CERT_PATH/$CLIENT_CERTS_NAME"-pkcs8.key \
  -nocrypt

chmod g+r,o+r "$CERT_PATH/$CLIENT_CERTS_NAME"-pkcs8.key

rm -f "$CERT_PATH/$ROOT_CA_CERTS_NAME".srl \
    "$CERT_PATH/$CLIENT_CERTS_NAME".csr \
    "$CERT_PATH/$CLIENT_CERTS_NAME".key \
