#!/bin/bash
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y
sudo apt-get install nginx -y
sudo apt-get install software-properties-common -y
sudo apt-get install
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt-get update
sudo apt-get install python-certbot-nginx -y
sudo apt-get install python-pip -y
sudo pip install --upgrade pip
sudo pip install future
sudo pip install certbot-external-auth
sudo pip install awscli --upgrade
# create app folders
sudo mkdir -p /var/www/backend
sudo mkdir -p /var/www/frontend

#create example files
cat <<EOF >/var/www/backend/index.html
<h1>This is the back-end</h1>
EOF

cat <<EOF >/var/www/frontend/index.html
<h1>This is the frontend-end</h1>
EOF

# stop Nginx
sudo service nginx stop
# Download front-end files on server if exist
cd /var/www/frontend
aws s3 sync s3://${s3_frontend_bucket_name} . --delete
sudo echo "*/10 * * * * root aws s3 sync s3://${s3_frontend_bucket_name} /var/www/frontend --delete" >> /etc/crontab

#set-up certbot renewing process
cat <<EOF >/etc/cron.daily/renew-certs
#!/bin/sh
# This script renews all the Let's Encrypt certificates with a validity < 30 days

if ! certbot renew > /var/log/letsencrypt/renew.log 2>&1 ; then
    echo Automated renewal failed:
    cat /var/log/letsencrypt/renew.log
    exit 1
fi
/usr/sbin/nginx -t && /usr/sbin/nginx -s reload
EOF

#Configure Nginx back-end
cat <<'EOF' >/tmp/default.conf
server {
    listen 443 ssl;
    listen 80;
    server_name ${be_subdomain};
    root /var/www/backend;
    ssl_certificate /etc/letsencrypt/live/${be_subdomain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${be_subdomain}/privkey.pem;

    location / {
    proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
    proxy_set_header Host \$$http_host;

    if ($$scheme = http) {
            return 301 https://$$server_name$$request_uri;
        }

    if (-f $$request_filename) {
      break;
    }
    if (-f $$request_filename/index.html) {
      rewrite (.*) $$1/index.html break;
    }
    if (-f $$request_filename.html) {
      rewrite (.*) $$1.html break;
    }
  }
}
EOF

# Configure Nginx front-end
cat <<'EOF' >/tmp/frontend.conf
server {
    listen 443 ssl;
    listen 80;
    server_name ${fe_subdomain};
    root /var/www/frontend;
    ssl_certificate /etc/letsencrypt/live/${fe_subdomain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${fe_subdomain}/privkey.pem;

    location / {
    proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
    proxy_set_header Host \$$http_host;

    if ($$scheme = http) {
            return 301 https://$$server_name$$request_uri;
        }
    if (-f $$request_filename) {
      break;
    }
    if (-f $$request_filename/index.html) {
      rewrite (.*) $$1/index.html break;
    }
    if (-f $$request_filename.html) {
      rewrite (.*) $$1.html break;
    }
    if (!-f $$request_filename) {
      rewrite (.*) /index.html break;
    }
  }
}
EOF

sudo mv /tmp/default.conf /etc/nginx/sites-enabled/default.conf
sudo mv /tmp/frontend.conf /etc/nginx/sites-enabled/frontend.conf

#setup

sudo service nginx stop
sudo certbot certonly --standalone --non-interactive --agree-tos --email ${certificate_email} --domains ${fe_subdomain}

sudo certbot certonly --standalone --non-interactive --agree-tos --email ${certificate_email} --domains ${be_subdomain}

sudo service nginx start