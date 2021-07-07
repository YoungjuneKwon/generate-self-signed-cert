#/bin/bash

if [ ! $1 ]; then
    echo usage : $0 org_name
    exit
fi

NAME=$1

mkdir -p tls/certs tls/keys tls/conf

openssl genrsa -aes256 -out tls/keys/${NAME}-rootca.key 2048
chmod 600 tls/keys/${NAME}-rootca.key

cat <<EOT >> tls/conf/rootca_openssl.conf
[ req ]
default_bits            = 2048
default_md              = sha1
default_keyfile         = ${NAME}-rootca.key
distinguished_name      = req_distinguished_name
extensions              = v3_ca
req_extensions          = v3_ca

[ v3_ca ]
basicConstraints       = critical, CA:TRUE, pathlen:0
subjectKeyIdentifier   = hash
##authorityKeyIdentifier = keyid:always, issuer:always
keyUsage               = keyCertSign, cRLSign
nsCertType             = sslCA, emailCA, objCA

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = KR
countryName_min                 = 2
countryName_max                 = 2

organizationName              = Organization Name (eg, company)
organizationName_default      = ${NAME} Inc.

commonName                      = Common Name (eg, your name or your server's hostname)
commonName_default             = ${NAME}'s Self Signed CA
commonName_max                  = 64
EOT

openssl req -new -key tls/keys/${NAME}-rootca.key -out tls/certs/${NAME}-rootca.csr -config tls/conf/rootca_openssl.conf
openssl x509 -req -days 3650 -extensions v3_ca -set_serial 1 \
    -in tls/certs/${NAME}-rootca.csr \
    -signkey tls/keys/${NAME}-rootca.key \
    -out tls/certs/${NAME}-rootca.crt \
    -extfile tls/conf/rootca_openssl.conf

openssl x509 -text -in tls/certs/${NAME}-rootca.crt
