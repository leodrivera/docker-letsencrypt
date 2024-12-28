#!/bin/sh
echo "INFO: Generating pkcs12 certificate for domain: $LETSENCRYPT_MAIN_DOMAIN"
openssl pkcs12 -export -out /etc/letsencrypt/live/$LETSENCRYPT_MAIN_DOMAIN/certificate.p12 \
  -inkey /etc/letsencrypt/live/$LETSENCRYPT_MAIN_DOMAIN/privkey.pem \
  -in /etc/letsencrypt/live/$LETSENCRYPT_MAIN_DOMAIN/cert.pem \
  -certfile /etc/letsencrypt/live/$LETSENCRYPT_MAIN_DOMAIN/chain.pem \
  -passout pass:$PKCS12_PASSWORD
chown -R $UID:$GID /etc/letsencrypt
