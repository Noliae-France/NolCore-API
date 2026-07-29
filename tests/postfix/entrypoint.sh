#!/bin/sh
set -eu

mkdir -p /certs
useradd -m -s /usr/sbin/nologin ci || true
mkdir -p /home/ci/Maildir/{cur,new,tmp}
chown -R ci:ci /home/ci/Maildir
if [ ! -f /certs/ca.crt ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 2 \
    -subj '/CN=NolCore CI CA' -keyout /certs/ca.key -out /certs/ca.crt
  openssl req -newkey rsa:2048 -nodes -subj '/CN=smtp-test' \
    -keyout /certs/server.key -out /certs/server.csr
  printf 'subjectAltName=DNS:smtp-test\n' > /certs/server.ext
  openssl x509 -req -days 2 -in /certs/server.csr \
    -CA /certs/ca.crt -CAkey /certs/ca.key -CAcreateserial \
    -out /certs/server.crt -extfile /certs/server.ext
fi

postconf -e 'myhostname = smtp-test'
postconf -e 'inet_interfaces = all'
postconf -e 'mynetworks = 0.0.0.0/0'
postconf -e 'mydestination = localhost, localhost.localdomain, smtp-test, example.test'
postconf -e 'home_mailbox = Maildir/'
postconf -e 'smtpd_tls_cert_file = /certs/server.crt'
postconf -e 'smtpd_tls_key_file = /certs/server.key'
postconf -e 'smtpd_tls_security_level = may'
postconf -e 'smtpd_tls_auth_only = yes'
postconf -e 'smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination'
cat >> /etc/postfix/master.cf <<'EOF'

smtps     inet  n       -       y       -       -       smtpd
  -o smtpd_tls_wrappermode=yes
  -o smtpd_tls_security_level=encrypt
  -o smtpd_tls_auth_only=no
submission inet n       -       y       -       -       smtpd
  -o smtpd_tls_security_level=encrypt
  -o smtpd_tls_auth_only=no
EOF

printf '%s\n' \
  'protocols = imap' \
  'mail_location = maildir:~/Maildir' \
  'ssl = no' \
  'disable_plaintext_auth = no' \
  'auth_mechanisms = plain login' \
  'userdb {' \
  '  driver = passwd' \
  '}' \
  'passdb {' \
  '  driver = pam' \
  '}' \
  'service auth {' \
  '  unix_listener auth-userdb {' \
  '    mode = 0600' \
  '    user = dovecot' \
  '  }' \
  '}' \
  > /etc/dovecot/dovecot.conf
dovecot -c /etc/dovecot/dovecot.conf

postfix start
trap 'postfix stop; exit 0' TERM INT
tail -F /var/log/mail.log /dev/null &
wait
