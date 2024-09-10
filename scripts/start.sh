#!/bin/sh

# Check variables DUCKDNS_TOKEN, DUCKDNS_DOMAIN
if [ -z "$DUCKDNS_TOKEN" ] || [ "$DUCKDNS_TOKEN" = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" ]; then
  echo "ERROR: Variable DUCKDNS_TOKEN is unset or still its default value"
  exit 1
fi

if [ -z "$DUCKDNS_DOMAIN" ]; then
  echo "ERROR: Variable DUCKDNS_DOMAIN is unset or still its default value"
  exit 1
fi

# Print email notice if applicable
if [ -z "$LETSENCRYPT_EMAIL" ]; then
  echo "WARNING: You will not receive SSL certificate expiration notices"
fi

# Set LETSENCRYPT_DOMAIN to DUCKDNS_DOMAIN if not specified
if [ -z "$LETSENCRYPT_DOMAIN" ]; then
  echo "INFO: LETSENCRYPT_DOMAIN is unset, using DUCKDNS_DOMAIN"
  LETSENCRYPT_DOMAIN=$DUCKDNS_DOMAIN
fi

# Set certificate url based on LETSENCRYPT_WILDCARD value
if [ "$LETSENCRYPT_WILDCARD" = "true" ]; then
  echo "INFO: A wildcard SSL certificate will be created"
  LETSENCRYPT_DOMAIN="*.$LETSENCRYPT_DOMAIN"
else
  LETSENCRYPT_WILDCARD="false"
fi

# Set default preferred chain if no value specified
if [ -z "$LETSENCRYPT_CHAIN" ]; then
  echo "INFO: LETSENCRYPT_CHAIN is unset, using default chain"
  LETSENCRYPT_CHAIN="default"
fi

# Set user and group ID's for files
if [ -z "$UID" ]; then
  echo "INFO: No UID specified, using root UID of 0"
  UID=0
fi

if [ -z "$GID" ]; then
  echo "INFO: No GID specified, using root GID of 0"
  GID=0
fi

if [ -z "$PKCS12_PASSWORD" ]; then
  echo "INFO: No PKCS12_PASSWORD specified, using blank password"
  PKCS12_PASSWORD=""
fi

get_pkcs12_cert()
{
  echo "INFO: Generating pkcs12 certificate"
  openssl pkcs12 -export -out /etc/letsencrypt/live/$DUCKDNS_DOMAIN/certificate.p12 \
    -inkey /etc/letsencrypt/live/$DUCKDNS_DOMAIN/privkey.pem \
    -in /etc/letsencrypt/live/$DUCKDNS_DOMAIN/cert.pem \
    -certfile /etc/letsencrypt/live/$DUCKDNS_DOMAIN/chain.pem \
    -passout pass:$PKCS12_PASSWORD
  chown -R $UID:$GID /etc/letsencrypt
}

# Print variables
echo "DUCKDNS_TOKEN: $DUCKDNS_TOKEN"
echo "DUCKDNS_DOMAIN: $DUCKDNS_DOMAIN"
echo "LETSENCRYPT_DOMAIN: $LETSENCRYPT_DOMAIN"
echo "LETSENCRYPT_EMAIL: $LETSENCRYPT_EMAIL"
echo "LETSENCRYPT_WILDCARD: $LETSENCRYPT_WILDCARD"
echo "LETSENCRYPT_CHAIN: $LETSENCRYPT_CHAIN"
echo "TESTING: $TESTING"
echo "UID: $UID"
echo "GID: $GID"
echo "PKCS12_PASSWORD: $PKCS12_PASSWORD"

if [ -z "$LETSENCRYPT_EMAIL" ]; then
  EMAIL_PARAM="--register-unsafely-without-email"
else
  EMAIL_PARAM="-m $LETSENCRYPT_EMAIL --no-eff-email"
fi

if [ "$LETSENCRYPT_CHAIN" = "default" ]; then
  unset CHAIN_PARAM
else
  CHAIN_PARAM=( --preferred-chain "$LETSENCRYPT_CHAIN" )
fi

if [ "$TESTING" = "true" ]; then
  echo "INFO: Generating staging certificate"
  TEST_PARAM="--test-cert"
else
  unset TEST_PARAM
fi

echo "certbot certonly --manual --preferred-challenges dns \
  --manual-auth-hook /scripts/auth.sh \
  --manual-cleanup-hook /scripts/cleanup.sh \
  ${CHAIN_PARAM[@]} $EMAIL_PARAM -d $LETSENCRYPT_DOMAIN \
  --agree-tos --keep $TEST_PARAM"

# Create certificates
certbot certonly --manual --preferred-challenges dns \
  --manual-auth-hook /scripts/auth.sh \
  --manual-cleanup-hook /scripts/cleanup.sh \
  "${CHAIN_PARAM[@]}" $EMAIL_PARAM -d $LETSENCRYPT_DOMAIN \
  --agree-tos --keep $TEST_PARAM

# Check for successful certificate generation
if [ ! -d "/etc/letsencrypt/live/${LETSENCRYPT_DOMAIN#\*\.}" ] || \
   [ ! -f "/etc/letsencrypt/live/${LETSENCRYPT_DOMAIN#\*\.}/fullchain.pem" ] || \
   [ ! -f "/etc/letsencrypt/live/${LETSENCRYPT_DOMAIN#\*\.}/privkey.pem" ]; then
  echo "ERROR: Failed to create SSL certificates"
  exit 1
fi

get_pkcs12_cert

# Check if certificates require renewal twice a day
while :; do
  # Wait for a random period within the next 12 hours
  LETSENCRYPT_DELAY=$(shuf -i 1-720 -n 1)
  echo "Sleeping for $(($LETSENCRYPT_DELAY / 60)) hour(s) and $(($LETSENCRYPT_DELAY % 60)) minute(s)"
  sleep $((${LETSENCRYPT_DELAY} * 60)) # Convert to seconds

  echo "INFO: Attempting SSL certificate renewal"
  certbot renew
  get_pkcs12_cert
done
