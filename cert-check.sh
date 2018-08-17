#!/bin/bash
if [[ $DEBUG == "true" ]]; then
  set -x
fi

# Check if FQDN is given
if [ -z "$1" ]; then
    echo "Usage: $0 FQDN [resolve]"
    exit 1
fi

if [ -n "$2" ]; then
  export RESOLVCHAIN=1
fi

FQDN=$1

if [ ! -f /certs/cert.pem ]; then
  echo "ERR: Certificate file not found at /certs/cert.pem"
  exit 1
elif [ ! -f /certs/key.pem ]; then
  echo "ERR: Certificate key file not found at /certs/key.pem"
  exit 1
elif [ ! -f /certs/cacerts.pem ]; then
  export CACERTS=false
  echo "INFO: CA certificate file not found at /certs/cacerts.pem, validating without CA certificate"
fi

# Check if FQDN is present in SANs
# https://stackoverflow.com/questions/20983217
# https://gist.github.com/stevenringo/2fe5000d8091f800aee4bb5ed1e800a6
CN=$(openssl x509 -in /certs/cert.pem -noout -subject -nameopt multiline | awk '/commonName/ {print $NF}')
SANS=$(openssl x509 -in /certs/cert.pem -noout -text|grep -oP '(?<=DNS:|IP Address:)[^,]+'|sort -uV | paste -sd " " -)
echo "INFO: Found CN ${CN}"
if [[ -z $SANS ]]; then
  echo "ERR: No Subject Alternative Name(s) (SANs) found"
  echo "ERR: Certificate will not be valid in applications that dropped support for commonName (CN) matching (Chrome/Firefox among others)"
else
  echo "INFO: Found Subject Alternative Name(s) (SANs): ${SANS}"
fi
if [[ $SANS = *"*"* ]]; then
  echo "OK: Wildcard certificate found in SANs (${SANS})"
elif [[ $SANS = *"${FQDN}"* ]]; then
  echo "OK: ${FQDN} was found in SANs (${SANS})"
else
  echo "ERR: ${FQDN} was not found in SANs"
fi

# Check if certificate and key match
# https://security.stackexchange.com/questions/56697/determine-if-private-key-belongs-to-certificate
if $(cmp <(openssl x509 -pubkey -in /certs/cert.pem -noout) <(openssl pkey -pubout -in /certs/key.pem -outform PEM) > /dev/null); then
  echo "OK: Certificate and certificate key match"
else
  echo "ERR: Certificate and certificate key do not match"
  exit 1
fi

if [[ $CACERTS == "false" ]]; then
  # Check certificate chain
  if openssl verify -untrusted /certs/cert.pem /certs/cert.pem > /dev/null; then
    echo "OK: Certificate chain is complete"
  else
    echo "ERR: Certificate chain is not complete"
    export CERTCHAIN=1
  fi
else
  # Check certificate chain
  if openssl verify -CAfile /certs/cacerts.pem -untrusted /certs/cert.pem /certs/cert.pem > /dev/null; then
    echo "OK: Certificate chain is complete"
  else
    echo "ERR: Certificate chain is not complete"
    export CERTCHAIN=1
  fi
fi

# Show order of certificate in certificate file
echo "INFO: Showing certificate chain from /certs/cert.pem"
openssl crl2pkcs7 -nocrl -certfile /certs/cert.pem | openssl pkcs7 -print_certs -noout

if [[ -n $CERTCHAIN ]]; then
  if [[ -n $RESOLVCHAIN ]]; then
    echo "Trying to get intermediates to complete chain and writing to /cert-check/cert-check-fullchain.pem"
    echo "Note: this usually only works when using certificates signed by a recognized Certificate Authority"
    cert-chain-resolver -o /cert-check/cert-check-fullchain.pem /certs/cert.pem
  fi
fi
