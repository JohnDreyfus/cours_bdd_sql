# 1. Introduction

## 1.1 Contexte : Les limites du modèle relationnel

### Rappel sur les bases de données relationnelles

Les bases de données relationnelles (MySQL, PostgreSQL, Oracle) reposent sur le modèle ACID et les schémas normalisés. Elles excellent pour garantir la cohérence des données et gérer des relations complexes entre entités.

### Émergence de nouveaux besoins

Avec l'évolution du web et des applications modernes, de nouveaux défis sont apparus :

- Volume de données massif (Big Data)
- Besoin de performances extrêmes (temps de réponse < 1ms)
- Scalabilité horizontale simplifiée
- Flexibilité du schéma de données
- Gestion de données non structurées

**Scalabilité horizontale** : augmentation de la capacité d’un système en **ajoutant plusieurs machines** (serveurs supplémentaires).

**Scalabilité verticale** : augmentation de la capacité d’une machine en **améliorant ses ressources** (CPU, RAM, stockage).
### Le mouvement NoSQL

NoSQL signifie "Not Only SQL". Ce terme regroupe différentes familles de bases de données non relationnelles, chacune optimisée pour des cas d'usage spécifiques. Le NoSQL privilégie souvent la disponibilité et la performance au détriment de la cohérence stricte (théorème CAP).

---

## 1.2 Les différents types de bases NoSQL

### Base de données clé-valeur

Structure la plus simple : une clé unique associée à une valeur. Comparable à une HashMap ou un dictionnaire distribué.

- Exemples : Redis, Memcached, DynamoDB
- Usage : cache, session, configuration

### Base de données orientée document

Stockage de documents semi-structurés (JSON, BSON, XML).

- Exemples : MongoDB, CouchDB
- Usage : CMS, catalogues produits, profils utilisateurs

### Base de données orientée colonnes

Optimisée pour l'analyse de grandes quantités de données par colonnes.

- Exemples : Cassandra, HBase
- Usage : analytics, séries temporelles

### Base de données orientée graphe

Modélisation des relations complexes entre entités.

- Exemples : Neo4j, ArangoDB
- Usage : réseaux sociaux, recommandations, détection de fraude

---

## 1.3 Redis : la base clé-valeur haute performance

### Présentation générale

Redis (Remote Dictionary Server) est une base de données clé-valeur open source créée en 2009 par Salvatore Sanfilippo. C'est l'une des bases de données les plus populaires au monde.

### Caractéristiques principales

**Architecture in-memory**

- Toutes les données sont stockées en RAM
- Temps de réponse de l'ordre de la microseconde
- Performances exceptionnelles en lecture et écriture

**Structures de données riches** Contrairement à d'autres bases clé-valeur, Redis supporte plusieurs types de données :

- Strings (chaînes de caractères)
- Lists (listes chaînées)
- Sets (ensembles non ordonnés)
- Sorted Sets (ensembles triés)
- Hashes (tables de hachage)
- Bitmaps, HyperLogLogs, Streams

**Persistance optionnelle** Bien qu'in-memory, Redis peut persister les données sur disque selon deux modes :

- RDB : snapshots périodiques
- AOF : journal des opérations

**Simplicité et performance**

- API simple avec des commandes intuitives
- Single-threaded (modèle mono-thread pour les opérations)
- Débit de plusieurs centaines de milliers d'opérations par seconde

---

## 1.4 Cas d'usage typiques de Redis

### Cache applicatif

Réduire la charge sur la base de données principale en mettant en cache les données fréquemment consultées.

- Cache de résultats de requêtes SQL
- Cache de pages HTML
- Cache d'objets métier

### Gestion de sessions

Stocker les sessions utilisateurs dans un système distribué.

- Sessions web partagées entre plusieurs serveurs
- Expiration automatique des sessions inactives

### Files d'attente et pub/sub

Implémenter des systèmes de messaging légers.

- File de tâches asynchrones
- Communication temps réel entre services

### Compteurs et statistiques temps réel

Gérer des métriques avec des opérations atomiques.

- Compteurs de vues, de likes
- Rate limiting (limitation de débit)
- Analytics en temps réel

### Classements et leaderboards

Maintenir des classements triés efficacement.

- Top scores dans un jeu
- Classement de produits populaires
- Trending topics

### Données de géolocalisation

Stocker et interroger des données spatiales.

- Recherche de points d'intérêt à proximité
- Suivi de véhicules en temps réel