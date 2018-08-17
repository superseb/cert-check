# cert-check

Check supplied certificate files for:
* Given FQDN is present in Subject Alternative Name (SAN)
* Check if certificate file and key file match
* Check is certificate chain is complete (based on given certificate file)
* Show certificate chain order
* Optionally retrieve intermediate certificate(s) and save to `/certs/cert-check-fullchain.pem` using [cert-chain-resolver](https://github.com/zakjan/cert-chain-resolver)

## How to use

### Docker

**Self signed certificate, providing CA certificate**
```
docker run -v /mylocation/cert.pem:/certs/cert.pem \
           -v /mylocation/key.pem:/certs/key.pem \
           -v /mylocation/ca.pem:/certs/cacerts.pem \
           superseb/cert-check:latest \
           test.yourdomain.com
```

**Certificate signed by recognized Certificate Authority, not providing CA certificate**
```
docker run -v /mylocation/cert.pem:/certs/cert.pem \
           -v /mylocation/privkey.pem:/certs/key.pem \
           superseb/cert-check:latest \
           test.yourdomain.com
```

**Certificate signed by recognized Certificate Authority, not providing CA certificate, retrieve intermediate certificate(s)**
```
docker run -v /mylocation/cert.pem:/certs/cert.pem \
           -v /mylocation/privkey.pem:/certs/key.pem \
           superseb/cert-check:latest \
           test.yourdomain.com \
           resolve
```

## Example

### Self signed with providing CA certficate

```
# docker run -v /yourlocation/cert.pem:/certs/cert.pem -v /yourlocation/key.pem:/certs/key.pem -v /yourlocation/ca.pem:/certs/cacerts.pem superseb/cert-check test.yourdomain.com
INFO: Found CN test.yourdomain.com
INFO: Found Subject Alternative Name(s) (SANs): test.yourdomain.com
OK: test.yourdomain.com was found in SANs (test.yourdomain.com)
OK: Certificate and certificate key match
OK: Certificate chain is complete
INFO: Showing certificate chain from /certs/cert.pem
subject=/CN=test.yourdomain.com
issuer=/CN=test-ca
```

### Let's Encrypt certificate with chain

```
# docker run -v /yourlocation/fullchain.pem:/certs/cert.pem -v /yourlocation/privkey.pem:/certs/key.pem -v /yourlocation/cert-check:/cert-check superseb/cert-check test.yourdomain.com
INFO: CA certificate file not found at /certs/cacerts.pem, validating without CA certificate
INFO: Found CN test.yourdomain.com
INFO: Found Subject Alternative Name(s) (SANs): test.yourdomain.com
OK: test.yourdomain.com was found in SANs (test.yourdomain.com)
OK: Certificate and certificate key match
OK: Certificate chain is complete
INFO: Showing certificate chain from /certs/cert.pem
subject=/CN=test.yourdomain.com
issuer=/C=US/O=Let's Encrypt/CN=Let's Encrypt Authority X3

subject=/C=US/O=Let's Encrypt/CN=Let's Encrypt Authority X3
issuer=/O=Digital Signature Trust Co./CN=DST Root CA X3
```

### Let's Encrypt certificate without chain, retrieve intermediate certificate(s) and save in /cert-check/cert-check-fullchain.pem

```
# docker run -v /yourlocation/cert.pem:/certs/cert.pem -v /yourlocation/privkey.pem:/certs/key.pem -v /yourlocation/cert-check:/cert-check superseb/cert-check test.yourdomain.com resolv
INFO: CA certificate file not found at /certs/cacerts.pem, validating without CA certificate
INFO: Found CN test.yourdomain.com
INFO: Found Subject Alternative Name(s) (SANs): test.yourdomain.com
OK: test.yourdomain.com was found in SANs (test.yourdomain.com)
OK: Certificate and certificate key match
ERR: Certificate chain is not complete
INFO: Showing certificate chain from /certs/cert.pem
subject=/CN=test.yourdomain.com
issuer=/C=US/O=Let's Encrypt/CN=Let's Encrypt Authority X3

Trying to get intermediates to complete chain and writing to /cert-check/cert-check-fullchain.pem
Note: this usually only works when using certificates signed by a recognized Certificate Authority
1: test.yourdomain.com
2: Let's Encrypt Authority X3
Certificate chain complete.
Total 2 certificate(s) found.
```
