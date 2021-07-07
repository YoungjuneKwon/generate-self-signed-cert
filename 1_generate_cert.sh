#/bin/bash

if [ ! $2 ]; then
    echo usage : $0 org_name domain
    exit
fi

NAME=$1
DOMAIN=$2

mkdir -p tls/certs tls/keys tls/conf

openssl genrsa -aes256 -out tls/keys/${DOMAIN}.key 2048

mv tls/keys/${DOMAIN}.key tls/keys/${DOMAIN}.key.enc
openssl rsa -in tls/keys/${DOMAIN}.key.enc -out tls/keys/${DOMAIN}.key
chmod 600 tls/keys/${DOMAIN}.key*

cat <<EOT >> tls/conf/host_openssl.conf
[ req ]
default_bits            = 2048
default_md              = sha1
default_keyfile         = ${NAME}-rootca.key
distinguished_name      = req_distinguished_name
extensions             = v3_user

[ v3_user ]
basicConstraints = CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectKeyIdentifier = hash
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

extendedKeyUsage = serverAuth,clientAuth
subjectAltName          = @alt_names

[ alt_names ]
DNS.1   = www.${DOMAIN}
DNS.2   = ${DOMAIN}
DNS.3   = *.${DOMAIN}

[req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = KR
countryName_min                 = 2
countryName_max                 = 2

organizationName              = Organization Name (eg, company)
organizationName_default      = ${NAME} Inc.

commonName                      = Common Name (eg, your name or your server's hostname)
commonName_default             = ${DOMAIN}
commonName_max                  = 64
EOT

openssl req -new -key tls/keys/${DOMAIN}.key -out tls/certs/${DOMAIN}.csr -config tls/conf/host_openssl.conf
openssl x509 -req -days 1825 -extensions v3_user \
  -in tls/certs/${DOMAIN}.csr \
  -CA tls/certs/${NAME}-rootca.crt -CAcreateserial \
  -CAkey  tls/keys/${NAME}-rootca.key \
  -out tls/certs/${DOMAIN}.crt  -extfile tls/conf/host_openssl.conf

openssl x509 -text -in tls/certs/${DOMAIN}.crt