---
title: Outils et méthodologie de développement
description: 
published: true
date: 2026-10-19T14:45:38.657Z
tags: 
editor: markdown
dateCreated: 2026-10-12T14:53:39.958Z
---

> Professeur s'occupant de la matière : Mr Philippe KISLIN
> Son adresse mail : philippe.kislin@gmail.com

# Git et Github

Voici une petite présentation de Git et Github ainsi que les commandes principales qui vous servirons pour le cours et possiblement dans la réalisation de projet en groupe pour le versioning

## Présentation

**Git** est un logiciel de gestion de versions décentralisé qui va permettre de suivre les modifications apportées à un projet et de travailler à plusieurs, permettant si besoin, le retour à une version antérieur en cas de problème. 

**Github** est la plateforme en ligne hébergeant les dépôts Git. Il va permettre de stocket et partager les codes, collaborer entre développeurs et gérer les issues, pull requests et workflow de développement. 

## Installation

### Sur Linux 

Pour installer git sur linux, rien de plus simple, il suffit de faire : 

```
sudo apt install git
```

Cela va installer le nécessaire et vous pourrez commencer à utiliser le logiciel. 

### Sur Windows

Rendez-vous sur le site officiel https://git-scm.com/downloads/win

Télécharger et installer le .exe

Suivez les étapes. 

### Vérification

Pour vérifier si l'installation est bonne, faites : 

```
git --version
```

## Commandes utiles 

Voici la liste des commandes que vous aller souvent utiliser

### Commandes de base (initialisation et configuration) 

Commande git | Explication
-------------|---------------
git init | Initialise un nouveau dépôt Git dans le dossier courant.
git clone http://github.com/pseudo/projet.git | Copie un dépôt distant sur votre ordinateur avec ses fichiers et dossiers.
git config --global user.name "Nom" | Définit votre nom d'utilisateur global pour git (reprendre le pseudo Github).
git config --global user.email “votre.mail@mail.com” | Définit l'adresse mail (reprendre celui sur github).
git config list | Affiche la configuration Git actuelle.
git --version | Vérifie la version installée de Git.

### Commandes de suivi et de gestion des fichiers

Commande git | Explication
-------------|-------------
git status | Affiche l’état des fichiers : modifiés, ajoutés, non suivis.
git add nom_fichier | Ajoute un fichier à la zone de préparation (staging).
git add . | Ajoute tous les fichiers modifiés à la zone de préparation.
git commit -m “Message” | Enregistre les modifications avec un message.
git log | Montre l’historique des commits.
git diff | Affiche les différences entre les fichiers modifiés et le dernier commit.
git show id_commit | Affiche les détails d’un commit spécifique.
git rm nom_fichier | Supprime un fichier du projet et du suivi Git.
git mv ancien nouveau | Renomme ou déplace un fichier.

### Commandes de branches (travail parallèle) 

Commande git | Explication
-------------|-------------
git branch | Liste les branches locales.
git branch nom_branche | Crée une nouvelle branche.
git checkout nom_branche | Change de branche.
git checkout -b nom_branche | Crée et change directement vers une nouvelle branche.
git branch -d nom_branche | Supprime une branche locale.
git switch nom_branche | Alternative moderne à checkout pour changer de branche.
git merge nom_branche | Fusionne une autre branche dans la branche actuelle.

### Commandes pour le dépôt distant

Commande git | Explication
-------------|-------------
git remote -v | Liste les dépôts distants configurés.
git remote add origin url | Lie ton dépôt local à un dépôt distant.
git push -u origin main | Envoie les commits vers la branche principale distante.
git push | Envoie les modifications locales vers le dépôt distant.
git pull | Récupère et fusionne les changements du dépôt distant.
git fetch | Récupère les changements sans les fusionner.

### Commandes de correction et d'annulation

Commande git | Explication
-------------|-------------
git reset nom_fichier | Retire un fichier de la zone de préparation.
git reset --hard id_commit | Restaure le projet à un commit précis.
git restore nom_fichier | Annule les modifications d’un fichier non encore ajouté.
git revert id_commit | Crée un nouveau commit qui annule un commit précédent.
git stash | Met temporairement de côté les changements non commités.
git stash pop | Restaure les changements mis de côté.

### Commandes d'inspection et de nettoyage

Commande git | Explication
-------------|-------------
git log --oneline --graph | Affiche un historique compact et visuel des commits.
git tag | Liste les balises (versions).
git tag nom | Crée une nouvelle balise (par ex. une version).
git gc | Nettoie les fichiers inutiles du dépôt.
git fsck | Vérifie l’intégrité du dépôt Git.
