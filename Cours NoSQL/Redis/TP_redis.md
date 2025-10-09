# 3. TP redis : Découverte pratique avec RedisInsight

## 3.1 Installation et configuration


### Étape 1 : Lancement de Redis

**docker-compose.yml**
```bash
services:
  redis:
    image: redis:7.4-alpine        # dernière LTS légère
    container_name: redis-server
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: ["redis-server", "--appendonly", "yes"]
    networks:
      - redisnet

  redisinsight:
    image: redis/redisinsight:latest
    container_name: redis-insight
    restart: unless-stopped
    ports:
      - "5540:5540"
    depends_on:
      - redis
    networks:
      - redisnet
    environment:
      - TZ=Europe/Paris

volumes:
  redis-data:

networks:
  redisnet:
    driver: bridge
```

**Lancement**

```bash
docker compose up -d
```

### Étape 2 : connexion à RedisInsight

- 'localhost:5540'

### Étape 3 : Connexion à Redis

1. Ouvrir RedisInsight
2. Cliquer sur "Add Redis Database"
3. Configurer la connexion :
    - Host : `localhost`
    - Port : `6379`
    - Name : `TP Redis`
4. Tester la connexion
5. Sauvegarder

### Étape 4 : Découverte de l'interface

**Browser** : Visualisation et manipulation des clés **Workbench** : Console pour exécuter des commandes **Analysis Tools** : Outils d'analyse et de monitoring

---

## 3.2 Exercice 1 : Cache de données utilisateur

### Contexte

Simuler un système de cache pour des profils utilisateurs. L'objectif est de stocker temporairement des informations utilisateur pour éviter des appels répétés à une base de données.

### Instructions

**Partie A : Stockage simple avec Strings **

Dans le Workbench, créer des profils utilisateurs :
```redis
# Créer 5 utilisateurs avec leurs informations
SET user:1001:name "Alice Martin"
SET user:1001:email "alice.martin@exemple.fr"
SET user:1001:role "admin"

SET user:1002:name "Bob Dupont"
SET user:1002:email "bob.dupont@exemple.fr"
SET user:1002:role "user"

SET user:1003:name "Claire Bernard"
SET user:1003:email "claire.bernard@exemple.fr"
SET user:1003:role "moderator"

SET user:1004:name "David Petit"
SET user:1004:email "david.petit@exemple.fr"
SET user:1004:role "user"

SET user:1005:name "Emma Rousseau"
SET user:1005:email "emma.rousseau@exemple.fr"
SET user:1005:role "admin"
```

1. Utiliser le Browser pour visualiser toutes les clés créées
2. Utiliser `KEYS user:*` pour lister les clés
3. Récupérer toutes les informations de l'utilisateur 1003 avec `MGET`

**Partie B : Ajout d'expiration**

Les données de cache doivent expirer après un certain temps.

```redis
# Ajouter une expiration de 4 minutes (1800 secondes) à tous les utilisateurs
EXPIRE user:1001:name 240
EXPIRE user:1001:email 240
EXPIRE user:1001:role 240

# Pour l'utilisateur 1002, utiliser un temps plus court (2 minutes)
EXPIRE user:1002:name 120
EXPIRE user:1002:email 120
EXPIRE user:1002:role 120
```

1. Vérifier le TTL de plusieurs clés avec `TTL user:1001:name`
2. Observer dans le Browser la colonne TTL
3. Que se passe-t-il si on attend 2 minutes et qu'on essaie de récupérer les données de l'utilisateur 1002 ?

**Partie C : Optimisation avec SETEX**

Recréer les utilisateurs en utilisant SETEX pour combiner SET et EXPIRE :

```redis
# Supprimer les anciennes clés
DEL user:1001:name user:1001:email user:1001:role

# Recréer avec SETEX (3600 secondes = 1 heure)
SETEX user:1001:name 3600 "Alice Martin"
SETEX user:1001:email 3600 "alice.martin@exemple.fr"
SETEX user:1001:role 3600 "admin"
```


**Partie D : Stockage JSON **

Pour éviter la multiplication des clés, stocker le profil complet en JSON :

```redis
# Stocker l'utilisateur complet en une seule clé
SETEX user:1001:profile 3600 '{"name":"Alice Martin","email":"alice.martin@exemple.fr","role":"admin","created_at":"2025-01-15"}'

SETEX user:1002:profile 3600 '{"name":"Bob Dupont","email":"bob.dupont@exemple.fr","role":"user","created_at":"2025-01-10"}'

SETEX user:1003:profile 3600 '{"name":"Claire Bernard","email":"claire.bernard@exemple.fr","role":"moderator","created_at":"2025-01-12"}'
```

1. Comparer le nombre de clés entre les deux approches
2. Quels sont les avantages et inconvénients de chaque méthode ?
3. Récupérer et lire le JSON de l'utilisateur 1001

---

## 3.3 Exercice 2 : Compteurs et statistiques temps réel

### Contexte

Implémenter un système de compteurs pour suivre l'activité d'un site web : vues de pages, clics, connexions.

### Instructions

**Partie A : Compteurs simples**

```redis
# Initialiser des compteurs
SET stats:pages:accueil:vues 0
SET stats:pages:produits:vues 0
SET stats:pages:contact:vues 0
SET stats:connexions:total 0

# Simuler de l'activité
INCR stats:pages:accueil:vues
INCR stats:pages:accueil:vues
INCR stats:pages:accueil:vues
INCR stats:pages:produits:vues
INCR stats:pages:produits:vues
INCR stats:pages:contact:vues
INCR stats:connexions:total

# Incrémenter par lots
INCRBY stats:pages:accueil:vues 25
INCRBY stats:connexions:total 10
```

1. Consulter tous les compteurs avec `MGET`
2. Quelle est la valeur actuelle de `stats:pages:accueil:vues` ?
3. Pourquoi utiliser INCR plutôt que GET puis SET ?

**Partie B : Statistiques quotidiennes avec expiration **

Créer des compteurs qui se réinitialisent automatiquement chaque jour :

```redis
# Statistiques du jour (expirent à minuit = 86400 secondes)
SETEX stats:daily:2025-10-08:connexions 86400 0
INCR stats:daily:2025-10-08:connexions
INCRBY stats:daily:2025-10-08:connexions 15

SETEX stats:daily:2025-10-08:pages_vues 86400 0
INCRBY stats:daily:2025-10-08:pages_vues 150

SETEX stats:daily:2025-10-08:inscriptions 86400 0
INCRBY stats:daily:2025-10-08:inscriptions 3
```

1. Vérifier le TTL des statistiques quotidiennes
2. Comment adapter ce système pour des statistiques horaires ?
3. Créer des statistiques pour l'heure actuelle avec une expiration de 3600 secondes

**Partie C : Rate limiting (limitation de débit)**

Implémenter une limitation du nombre de requêtes par utilisateur :

```redis
# Limiter à 100 requêtes par heure pour chaque utilisateur
SETEX ratelimit:user:1001 3600 0

# Simuler des requêtes de l'utilisateur 1001
INCR ratelimit:user:1001
INCR ratelimit:user:1001
INCR ratelimit:user:1001

# Vérifier le nombre de requêtes
GET ratelimit:user:1001

# Simuler beaucoup de requêtes
INCRBY ratelimit:user:1001 50
GET ratelimit:user:1001
```

**Questions :**

1. Comment vérifier si un utilisateur a dépassé la limite de 100 requêtes ?
2. Que se passe-t-il après 1 heure ?
3. Créer un rate limiter pour l'utilisateur 1002 avec une limite de 50 requêtes

---

## 3.4 Exercice 3 : Hashes pour objets structurés

### Contexte

Les Hashes permettent de stocker des objets avec plusieurs champs, similaire à un objet JSON mais avec un accès granulaire aux propriétés.

### Instructions

**Partie A : Création et manipulation**

```redis
# Créer un profil utilisateur avec HSET
HSET user:2001 name "Sophie Lambert"
HSET user:2001 email "sophie.lambert@exemple.fr"
HSET user:2001 age 28
HSET user:2001 city "Paris"
HSET user:2001 role "developer"

# Ou en une seule commande
HSET user:2002 name "Lucas Moreau" email "lucas.moreau@exemple.fr" age 35 city "Lyon" role "manager"

# Créer plusieurs utilisateurs
HSET user:2003 name "Marie Dubois" email "marie.dubois@exemple.fr" age 42 city "Marseille" role "designer"
HSET user:2004 name "Thomas Roux" email "thomas.roux@exemple.fr" age 31 city "Toulouse" role "developer"
```

1. Observer la structure d'un Hash dans le Browser
2. Comparer avec le stockage JSON précédent
3. Récupérer uniquement le nom de l'utilisateur 2001 : `HGET user:2001 name`
4. Récupérer l'âge et la ville : `HMGET user:2001 age city`
5. Récupérer tout le profil : `HGETALL user:2001`

**Partie B : Modifications et opérations**

```redis
# Modifier un champ
HSET user:2001 city "Bordeaux"

# Vérifier l'existence d'un champ
HEXISTS user:2001 email
HEXISTS user:2001 phone

# Supprimer un champ
HDEL user:2001 role

# Compter les champs
HLEN user:2001

# Lister tous les champs
HKEYS user:2001

# Lister toutes les valeurs
HVALS user:2001
```

1. Combien de champs reste-t-il dans user:2001 après suppression du role ?
2. Ajouter un champ "phone" et "department" à l'utilisateur 2002
3. Lister uniquement les noms de tous les champs de user:2003

**Partie C : Compteurs dans les Hashes **

Les Hashes supportent les opérations d'incrémentation :

```redis
# Créer un produit avec stock
HSET product:5001 name "Ordinateur portable" price 899.99 stock 50

# Vendre des produits (décrémenter le stock)
HINCRBY product:5001 stock -1
HINCRBY product:5001 stock -3

# Vérifier le stock restant
HGET product:5001 stock

# Créer des statistiques produit
HSET product:5001:stats views 0 purchases 0 cart_additions 0

# Simuler de l'activité
HINCRBY product:5001:stats views 1
HINCRBY product:5001:stats views 1
HINCRBY product:5001:stats cart_additions 1
HINCRBY product:5001:stats purchases 1

# Consulter les statistiques
HGETALL product:5001:stats
```

1. Créer un produit 5002 avec un stock de 30 unités
2. Simuler la vente de 5 unités
3. Créer un système de likes/dislikes pour un article avec HINCRBY

---

## 3.5 Exercice 4 : Lists pour files d'attente

### Contexte

Les Lists sont des listes chaînées permettant d'implémenter des files d'attente (queues) ou des piles (stacks).

### Instructions

**Partie A : File d'attente FIFO (First In First Out)**

```redis
# Créer une file de tâches à traiter
RPUSH queue:tasks "Envoyer email de bienvenue"
RPUSH queue:tasks "Générer rapport mensuel"
RPUSH queue:tasks "Nettoyer fichiers temporaires"
RPUSH queue:tasks "Sauvegarder base de données"

# Visualiser la file
LRANGE queue:tasks 0 -1

# Traiter les tâches (retirer du début)
LPOP queue:tasks
LPOP queue:tasks

# Vérifier les tâches restantes
LRANGE queue:tasks 0 -1

# Ajouter de nouvelles tâches
RPUSH queue:tasks "Envoyer newsletter" "Optimiser images"
```

1. Combien de tâches reste-t-il dans la file ?
2. Quelle est la prochaine tâche à traiter ? (utiliser `LINDEX queue:tasks 0`)
3. Vider complètement la file en traitant toutes les tâches

**Partie B : Pile LIFO (Last In First Out)**

```redis
# Créer un historique de navigation
LPUSH history:user:3001 "https://exemple.fr/accueil"
LPUSH history:user:3001 "https://exemple.fr/produits"
LPUSH history:user:3001 "https://exemple.fr/contact"
LPUSH history:user:3001 "https://exemple.fr/panier"

# Visualiser l'historique
LRANGE history:user:3001 0 -1

# Bouton "retour" (retirer le dernier élément)
LPOP history:user:3001

# Vérifier la page actuelle
LINDEX history:user:3001 0
```

**Questions :**

1. Sur quelle page l'utilisateur se trouve-t-il maintenant ?
2. Simuler 2 retours en arrière supplémentaires
3. Quelle est la longueur de l'historique ? (utiliser `LLEN`)

**Partie C : Notifications et messages**

```redis
# File de notifications pour un utilisateur
RPUSH notifications:user:4001 '{"type":"message","text":"Nouveau message de Bob","time":"10:30"}'
RPUSH notifications:user:4001 '{"type":"like","text":"Alice a aimé votre post","time":"10:45"}'
RPUSH notifications:user:4001 '{"type":"comment","text":"Nouveau commentaire","time":"11:00"}'

# Consulter les notifications
LRANGE notifications:user:4001 0 -1

# Limiter à 10 notifications maximum
LTRIM notifications:user:4001 0 9

# File de logs applicatifs
RPUSH logs:app:errors '{"level":"error","message":"Connection timeout","timestamp":"2025-10-08T10:30:00"}'
RPUSH logs:app:errors '{"level":"error","message":"File not found","timestamp":"2025-10-08T10:35:00"}'
RPUSH logs:app:errors '{"level":"error","message":"Invalid token","timestamp":"2025-10-08T10:40:00"}'

# Récupérer les 5 dernières erreurs
LRANGE logs:app:errors -5 -1

# Garder seulement les 100 derniers logs
LTRIM logs:app:errors -100 -1
```

1. Combien de notifications l'utilisateur 4001 a-t-il ?
2. Ajouter 5 nouvelles notifications et appliquer LTRIM pour ne garder que les 10 dernières
3. Créer une file de tâches prioritaires où les tâches urgentes sont ajoutées au début avec LPUSH

---

## 3.6 Exercice 5 : Sorted Sets pour classements

### Contexte

Les Sorted Sets (ensembles triés) permettent de maintenir des classements avec scores, idéal pour les leaderboards, les tendances, etc.

### Instructions

**Partie A : Leaderboard de jeu**

```redis
# Ajouter des scores de joueurs
ZADD leaderboard:game1 1250 "player:alice"
ZADD leaderboard:game1 980 "player:bob"
ZADD leaderboard:game1 1450 "player:charlie"
ZADD leaderboard:game1 1100 "player:diana"
ZADD leaderboard:game1 1380 "player:emma"

# Ajouter plusieurs joueurs en une commande
ZADD leaderboard:game1 1290 "player:frank" 1150 "player:grace" 1420 "player:henry"

# Top 3 joueurs (ordre décroissant)
ZREVRANGE leaderboard:game1 0 2 WITHSCORES

# Tous les joueurs classés
ZREVRANGE leaderboard:game1 0 -1 WITHSCORES

# Position d'un joueur (rank)
ZREVRANK leaderboard:game1 "player:alice"

# Score d'un joueur
ZSCORE leaderboard:game1 "player:charlie"
```

1. Qui est en première position ?
2. Quelle est la position de "player:diana" ?
3. Ajouter votre propre score et vérifier votre classement

**Partie B : Mise à jour des scores **

```redis
# Un joueur améliore son score
ZINCRBY leaderboard:game1 200 "player:bob"

# Vérifier le nouveau classement
ZREVRANGE leaderboard:game1 0 -1 WITHSCORES

# Nombre total de joueurs
ZCARD leaderboard:game1

# Joueurs avec un score entre 1200 et 1400
ZCOUNT leaderboard:game1 1200 1400
ZRANGEBYSCORE leaderboard:game1 1200 1400 WITHSCORES
```

1. "player:bob" a-t-il changé de position après l'amélioration ?
2. Combien de joueurs ont un score supérieur à 1300 ?
3. Incrémenter le score de "player:diana" de 300 points

**Partie C : Articles populaires **

```redis
# Trending articles basé sur les vues
ZADD trending:articles 1250 "article:101"
ZADD trending:articles 3400 "article:102"
ZADD trending:articles 890 "article:103"
ZADD trending:articles 2100 "article:104"
ZADD trending:articles 1780 "article:105"

# Top 3 articles
ZREVRANGE trending:articles 0 2 WITHSCORES

# Un article reçoit 500 vues supplémentaires
ZINCRBY trending:articles 500 "article:103"

# Nouveau top 3
ZREVRANGE trending:articles 0 2 WITHSCORES
```

1. Quel article était le plus populaire initialement ?
2. "article:103" est-il entré dans le top 3 après l'augmentation ?
3. Créer un classement de produits par nombre de ventes

---

## 3.7 Synthèse et analyse

### Comparaison des structures de données

Dans le Workbench, exécuter :

```redis
# Compter les clés par type
INFO keyspace

# Voir toutes les clés créées
KEYS *

# Taille de la mémoire utilisée
INFO memory
```
