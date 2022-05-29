---
title: Installation de ce serveur Wiki
description: Comment est installé et configuré ce serveur
published: true
date: 2022-05-29T12:13:34.041Z
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
sudo mkdir -p /opt/www/letsencrypt/www
sudo chown -R www-data:www-data /opt/www/letsencrypt
```

### Configuration du serveur web

Cette configuration sera modifiée par la suite après la génération d'un certificat TLS. On supprime la configuration existante et on créer la configuration du serveur web par défault:

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

### (Re-)Démarrage du serveur web

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
sudo micro /opt/letsencrypt/after-renew.sh
```

```
#!/bin/sh
/bin/systemctl reload nginx
```

Changer les doits:

```
sudo chmod 500 /opt/letsencrypt/after-renew.sh
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
ExecStart=/usr/bin/certbot renew --quiet --post-hook "/bin/sh /opt/letsencrypt/after-renew.sh"
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
	listen 443 default_server;
	listen [::]:443 default_server;

	server_name _;
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


