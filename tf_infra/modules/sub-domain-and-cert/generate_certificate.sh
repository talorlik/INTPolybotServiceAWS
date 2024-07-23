#!/bin/bash
C=$1
ST=$2
L=$3
O=$4
CN=$5

openssl req -newkey rsa:2048 -sha256 -nodes -keyout sub-domain-cert.key -x509 -days 365 -out sub-domain-cert.pem -subj "/C=$C/ST=$ST/L=$L/O=$O/CN=$CN"

CERT_CONTENT=$(awk 'BEGIN{ORS="\\n"} {print}' sub-domain-cert.pem)
KEY_CONTENT=$(awk 'BEGIN{ORS="\\n"} {print}' sub-domain-cert.key)

echo "{\"cert_file\": \"$CERT_CONTENT\", \"key_file\": \"$KEY_CONTENT\"}"