#!/bin/sh
echo "INFO: Generating pkcs12 certificate for domain: $LETSENCRYPT_DOMAIN"
openssl pkcs12 -export -out /etc/letsencrypt/live/$LETSENCRYPT_DOMAIN/certificate.p12 \
  -inkey /etc/letsencrypt/live/$LETSENCRYPT_DOMAIN/privkey.pem \
  -in /etc/letsencrypt/live/$LETSENCRYPT_DOMAIN/cert.pem \
  -certfile /etc/letsencrypt/live/$LETSENCRYPT_DOMAIN/chain.pem \
  -passout pass:$PKCS12_PASSWORD
chown -R $UID:$GID /etc/letsencrypt
