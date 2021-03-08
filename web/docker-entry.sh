#!/bin/bash

HTTP_AUTH_ENABLED=${HTTP_AUTH_ENABLED:-false}
HTTP_AUTH_USER=${HTTP_AUTH_USER:-""}
HTTP_AUTH_PASS=${HTTP_AUTH_PASS:-""}
CORS_OPEN=${CORS_OPEN:-true}

if [ -f "/cert/cert.pem" -a -f "/cert/key-no-password.pem" ]; then
  echo "found certificate and key, linking ssl config"
  ssl="-ssl"
else
  echo "linking plain config"
fi

ln -s /etc/nginx/sites-available/catmaid$ssl /etc/nginx/conf.d/catmaid.conf

# Enable HTTP Basic Authentication only if a username and password is provided,
# else disable it.
if [ "$HTTP_AUTH_ENABLED" = true ] && [ -n "$HTTP_AUTH_USER" ] && [ -n "$HTTP_AUTH_PASS" ]
then
  sed -ri 's/auth_basic .*$/auth_basic "Restricted";/' /etc/nginx/conf.d/catmaid.conf
  htpasswd -c -b /etc/nginx/auth.htpasswd $HTTP_AUTH_USER $HTTP_AUTH_PASS
  echo "HTTP Basic Authentication enabled"
else
  sed -ri 's/auth_basic *$/auth_basic off;/' /etc/nginx/conf.d/catmaid.conf
  echo "HTTP Basic Authentication disabled"
fi

# CORS
if [[ "$CORS_OPEN" = true ]]; then
  echo "Allowing open CORS access: linking nginx-cors-open.conf"
  ln -sf /etc/nginx/nginx-cors-open.conf /etc/nginx/cors.conf
else
  echo "CORS access will not be allowed"
  echo '' > /etc/nginx/cors.conf
fi

exec nginx -g 'daemon off;'
