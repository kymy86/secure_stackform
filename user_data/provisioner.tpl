#!/bin/bash

until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

sudo service nginx stop
sudo certbot certonly --standalone --non-interactive --agree-tos --email ${certificate_email} --domains ${fe_subdomain}

sudo certbot certonly --standalone --non-interactive --agree-tos --email ${certificate_email} --domains ${be_subdomain}

sudo service nginx start