---
title: Installation de ce serveur Wiki
description: Comment est installé et configuré ce serveur
published: true
date: 2022-06-13T22:47:42.625Z
tags: 
editor: markdown
dateCreated: 2022-05-29T10:50:06.101Z
---

# Informations générales

* Nom de la machine: wiki
* Système d'exploitation: Debian 11
* vCPU: 1
* RAM: 1 GiB
* Stockage: 32 GiB
* IP publique: 51.210.71.10
* Nom public: wiki.paris8-ied.net

## Editeur de fichier

Les commandes ci-dessous utilise l'editeur de fichier en ligne de commande `micro` (https://micro-editor.github.io). Remplacez-le par votre éditeur préféré (vi, nano, ...)


# Serveur web

Le serveur web (NGINX) est utilisé comme mandataire inverse (reverse proxy) pour Wiki.js. Il est également directement utilisé pour Let's Encrypt (certificat TLS).

## Installation

```bash
sudo apt update
sudo apt install -y nginx-full
```

## Configuration

```bash
sudo micro /etc/nginx/nginx.conf
```

Changer la ligne avec `server_tokens` par:

```nginx
server_tokens off;
```

Pour optimiser la compression:


```nginx
	##
	# Gzip Settings
	##

	gzip on;
	gzip_vary on;
	gzip_proxied any;
	gzip_comp_level 6;
	gzip_buffers 16 8k;
	gzip_http_version 1.1;
	gzip_min_length 256;
	gzip_types
	  application/atom+xml
	  application/geo+json
	  application/javascript
	  application/x-javascript
	  application/json
	  application/ld+json
	  application/manifest+json
	  application/rdf+xml
	  application/rss+xml
	  application/xhtml+xml
	  application/xml
	  font/eot
	  font/otf
	  font/ttf
	  image/svg+xml
	  text/css
	  text/javascript
	  text/plain
	  text/xml;
```

La taille pour les téléversements est trop petite. Pour la changer et limiter à 6MB:

```bash
sudo micro /etc/nginx/conf.d/client-body-size.conf
```

Ajouter:

```
client_max_body_size 6M
```

## Outils d'activation

Pour avoir des commandes `nginx_ensite` et `nginx_dissite` similaires à celles d'Apache.

```bash
git clone https://github.com/perusio/nginx_ensite.git
cd nginx_ensite
sudo make install
cd ..
rm -rf nginx_ensite
```

Pour activer un site web virtuel:

```bash
nginx_ensite nom-du-fichier.conf
```

Pour le désactiver:

```bash
nginx_dissite nom-du-fichier.conf
```


## Génération d'un certificat TLS (SSL)

Il nous faut d'abord un serveur web actif, installer les outils et générer le certificat.

### Installation de Certbot (Let's Encrypt)

```bash
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

### Préparation

```
sudo mkdir -p /opt/letsencrypt/www
sudo chown -R www-data:www-data /opt/letsencrypt/www
```

### Configuration du serveur web

Cette configuration sera modifiée par la suite après la génération d'un certificat TLS. On supprime la configuration existante et on créer la configuration du serveur web par défaut:

```bash
sudo rm /etc/nginx/sites-available/*
sudo rm /etc/nginx/sites-enabled/*
sudo micro /etc/nginx/sites-available/default.conf
```

```
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	server_name *.paris8-ied.net;

  include /etc/nginx/templates/letsencrypt.tmpl;
}
```

On créé la configuration pour Let's Encrypt:

```bash
sudo mkdir -p /etc/nginx/templates
sudo micro /etc/nginx/templates/letsencrypt.tmpl
```

```
location ~ /\.well-known/acme-challenge/ {
    default_type "text/plain";
    allow all;
    root /opt/letsencrypt/www;
}
```

### (Re-)démarrage du serveur web

On vérifie la configuration et on démarre le serveur:

```bash
sudo nginx_ensite default.conf
sudo nginx -t
sudo systemctl restart nginx
```

### Génération du certificat TLS

```
sudo certbot certonly --webroot -w /opt/letsencrypt/www -d wiki.paris8-ied.net,www.paris8-ied.net,ordipapier.paris8-ied.net
```

### Renouvellement du certificat

Créer un script shell pour mettre à jour la configuration du serveur web après renouvellement du certificat:

```bash
sudo mkdir -p /opt/letsencrypt/bin
sudo micro /opt/letsencrypt/bin/after-renew.sh
```

Avec ce contenu:

```
#!/bin/sh
/bin/systemctl reload nginx
```

Changer les droits:

```
sudo chmod 500 /opt/letsencrypt/bin/after-renew.sh
```

Créer un service systemd:

```bash
sudo micro /etc/systemd/system/renew-letsencrypt.service
```

```
[Unit]
Description=Renew Let's Encrypt certificates

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --post-hook "/bin/sh /opt/letsencrypt/bin/after-renew.sh"
```

Créer un timer systemd:

```bash
sudo micro /etc/systemd/system/renew-letsencrypt.timer
```

```
[Unit]
Description=Daily renewal of Let's Encrypt's certificates

[Timer]
# once a day, at 04:00, add a random delay of 0–3600 seconds
OnCalendar=*-*-* 04:00:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
```

Pour démarrer le timer et l'activer au démarrage de la machine:

```bash
sudo systemctl daemon-reload
sudo systemctl start renew-letsencrypt.timer
sudo systemctl enable renew-letsencrypt.timer
```

Pour tester le renouvellement (sans réellement le faire):

```bash
sudo certbot renew --dry-run
```

### Paramètres TLS

Ces paramètres sont communs à tous les serveurs virtuels:

```bash
sudo micro /etc/nginx/templates/ssl-params.tmpl
```

```
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES256-GCM-SHA384;
ssl_ecdh_curve secp521r1:secp384r1;

ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;

ssl_stapling on;
ssl_stapling_verify on;

resolver 1.1.1.1 1.0.0.1 [2606:4700:4700::1111] [2606:4700:4700::1001] valid=300s; # Cloudflare
resolver_timeout 5s;

add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
```

**IMPORTANT**: *Ces paramètres ne permettent **pas** pour l´instant d´obtenir un score de A+ sur Qualys SSL Labs (https://www.ssllabs.com/ssltest/index.html), ce sera amélioré par la suite.*


## Configuration des serveurs web virtuels

### Serveur web par défaut

Ce serveur répond par une erreur 404 pour tout nom de domaine iconnu.

```bash
sudo micro /etc/nginx/sites-available/default.conf
```

Remplacer le contenu par:

```
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  listen 443 ssl http2 default_server;
  listen [::]:ssl http2 443 default_server;

  server_name _;
  
  ssl_certificate /etc/letsencrypt/live/wiki.paris8-ied.net/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/wiki.paris8-ied.net/privkey.pem;

  return 404;
}
```

### Serveur web virtuel du Wiki

```bash
sudo micro /etc/nginx/sites-available/wiki.conf
```

```
server {
    listen 80;
    listen [::]:80;
    server_name *.paris8-ied.net;
    return 301 https://$host$request_uri;
 }

server {
    listen 443;
    listen [::]:443;
    server_name *.paris8-ied.net ;

    ssl_certificate /etc/letsencrypt/live/wiki.paris8-ied.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/wiki.paris8-ied.net/privkey.pem;

    include /etc/nginx/templates/letsencrypt.tmpl;
    include /etc/nginx/templates/ssl-params.tmpl;

    location / {
        proxy_set_header   X-Forwarded-For $remote_addr;
        proxy_set_header   Host $http_host;
        proxy_pass         http://127.0.0.1:3000;
    }

    error_log /var/log/nginx/wiki-error.log;
    access_log /var/log/nginx/wiki-access.log;
}
```

### Mise à jour du serveur web

On active le nouveau serveur web virtuel, on vérifie la configuration et on recharge la configuration:

```bash
sudo nginx_ensite wiki.conf
sudo nginx -t
sudo systemctl reload nginx
```

# Base de données

## Installation de Postgres

Installation et vérification:

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl status postgresql
```

## Création de la base de données pour le wiki

On se connecte à Postgres:

```bash
sudo -u postgres psql
```

On crée une base de données et un utilisateur dédié. On active également une extension pour la recherche:

```
CREATE DATABASE wiki;
CREATE USER wiki WITH PASSWORD 'mot-de-passe';
GRANT ALL PRIVILEGES ON DATABASE wiki TO wiki;
\c wiki
CREATE EXTENSION pg_trgm;
\q
```

**Note**: *Mettre un mot de passe approprié.*

# Wiki.js

## Installation de Node.js

Installation et vérification:

```bash
sudo apt install -y nodejs npm
node -v
npm -v
```

## Installation de Wiki.js

Wiki.js est installé dans `/opt/wiki`:

```bash
sudo mkdir /opt/wiki
sudo mkdir /var/wiki
sudo chown wiki:wiki /opt/wiki
sudo chown wiki:wiki /var/wiki
sudo -iu wiki
wget https://github.com/Requarks/wiki/releases/latest/download/wiki-js.tar.gz
tar xzf wiki-js.tar.gz -C /opt/wiki
cd /opt/wiki
mv config.sample.yml config.yml
```

Edition de la configuration de base:

```bash
micro config.yml
```
```
port: 3000

db:
  type: postgres
  host: localhost
  port: 5432
  user: wiki
  pass: mot-de-passe
  db: wiki

logLevel: info

dataPath: /var/wiki
```

**Note**: *Utilisez le même mot de passe que précédemment.*

## Création d'un service systemd pour le wiki

Cela permet de démarrer le wiki lors du démarrage de la machine.

```bash
sudo micro /etc/systemd/system/wiki.service
```

```
[Unit]
Description=Wiki.js
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node server
Restart=always
User=wiki
Environment=NODE_ENV=production
WorkingDirectory=/opt/wiki

[Install]
WantedBy=multi-user.target
```

## Démarrage et activation du service

```bash
sudo systemctl daemon-reload
sudo systemctl start wiki
sudo systemctl enable wiki
```

## Visualisation des logs

```
sudo journalctl -u wiki -f
```


