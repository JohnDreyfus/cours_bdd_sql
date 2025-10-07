# **8 – Interface et administration PostgreSQL** {#8-interface}

## **Objectifs pédagogiques**

- Comprendre l'architecture interne de PostgreSQL
- Maîtriser les outils d'administration (psql, pgAdmin)
- Naviguer efficacement dans l'arborescence des objets
- Connaître les catalogues système et leur utilisation
- Gérer les extensions et fonctionnalités avancées

---

## **8.1 Arborescence Catégories**
```
Database
├── Casts
├── Catalogs
├── Event Triggers
├── Extensions
├── Foreign Data Wrappers
├── Languages
├── Publications
├── Schemas
└── Subscriptions
```

---
### **8.1.1 Casts**

**Conversion explicite ou implicite entre types de données**
- PostgreSQL permet de convertir des valeurs d'un type vers un autre.
  Par exemple, convertir un integer en text ou un text en date.
- Ces conversions sont appelées **casts**.

Exemple :
```sql
SELECT '2025-10-05'::date;  -- cast explicite de texte vers date
```

- Vous pouvez **créer vos propres casts** si vous définissez des types personnalisés :
```sql
CREATE CAST (integer AS text) WITH FUNCTION int4_to_text(integer);
```

**Utilité** : personnaliser comment PostgreSQL convertit des données entre types (utile pour extensions ou domaines spécifiques).

---
### **8.1.2 Catalogs**

**Contient les tables système internes (métadonnées de PostgreSQL)**
- C'est ici que PostgreSQL **enregistre toutes les informations sur la base** :
    - tables, colonnes, index, rôles, privilèges, etc.

- Par défaut, vous verrez :
    - pg_catalog → catalogue interne du serveur
    - information_schema → standard SQL (tables descriptives portables)

Exemple :
```sql
SELECT * FROM pg_catalog.pg_tables;
```

**Utilité** : introspection du système – vous pouvez y lire la structure interne de la base.

---
### **8.1.3 Event Triggers**

**Déclencheurs (triggers) liés aux événements DDL (création/modification de schéma)**
- Contrairement aux triggers normaux (sur des tables DML : INSERT/UPDATE/DELETE),
  les **event triggers** réagissent à des **commandes DDL** : CREATE TABLE, ALTER TABLE, etc.

Exemple :
```sql
CREATE EVENT TRIGGER log_ddl
ON ddl_command_start
EXECUTE FUNCTION log_ddl_changes();
```

**Utilité** : audit, contrôle ou automatisation des modifications de schéma.

---
### **8.1.4 Extensions**

**Modules externes ajoutant des fonctionnalités à PostgreSQL**
- Les extensions sont comme des **plugins** officiels (ou tiers).
  Vous les installez via CREATE EXTENSION.

Exemples utiles :
```sql
CREATE EXTENSION pgcrypto;   -- chiffrement et hachage
CREATE EXTENSION postgis;    -- géolocalisation
CREATE EXTENSION hstore;     -- paires clé/valeur
CREATE EXTENSION "uuid-ossp";  -- génération d'identifiants UUID
```

**Utilité** : étendre PostgreSQL sans recompiler le serveur.

---
### **8.1.5 Foreign Data Wrappers (FDW)**

**Permettent d'accéder à des données externes comme si elles étaient locales**
- PostgreSQL peut se connecter à d'autres bases ou fichiers et les interroger via SQL standard.

Exemple :
```sql
CREATE EXTENSION postgres_fdw;
CREATE SERVER srv_remote FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host '10.0.0.5', dbname 'remote_db');
```

**Utilité** : fédération de données – lire des données d'autres bases (PostgreSQL, MySQL, CSV, etc.).

---
### **8.1.6 Languages**

**Langages utilisés pour écrire des fonctions ou procédures**
- Par défaut, PostgreSQL comprend **SQL** et **PL/pgSQL**.
- Vous pouvez aussi activer d'autres langages : **PL/Python**, **PL/Perl**, **PLV8 (JavaScript)**.

Exemple :
```sql
CREATE FUNCTION test_func() RETURNS text AS $
BEGIN
  RETURN 'Bonjour PG!';
END;
$ LANGUAGE plpgsql;
```

**Utilité** : écrire de la logique métier côté serveur.

---
### **8.1.7 Publications**

**Éléments de la réplication logique (publisher → subscriber)**
- Une publication définit **quelles tables** ou **colonnes** sont envoyées à d'autres serveurs.

Exemple :
```sql
CREATE PUBLICATION my_pub FOR TABLE clients, commandes;
```

**Utilité** : répliquer certaines données vers d'autres serveurs PostgreSQL (par exemple pour de la synchronisation applicative).

---
### **8.1.8 Schemas**

**Regroupement logique d'objets (tables, vues, fonctions, etc.)**
- Un schéma est comme un **dossier** dans la base.
- Par défaut, chaque base a un schéma public.

Exemple :
```sql
CREATE SCHEMA gestion_commerciale;
CREATE TABLE gestion_commerciale.clients (...);
```

**Utilité** : organiser les objets, gérer des permissions ou séparer des modules.

---
### **8.1.9 Subscriptions**

**Autre côté de la réplication logique (subscriber)**
- Une subscription se connecte à une **publication distante** pour recevoir les données.

Exemple :
```sql
CREATE SUBSCRIPTION my_sub
CONNECTION 'host=10.0.0.2 dbname=ma_base user=replicator password=secret'
PUBLICATION my_pub;
```

**Utilité** : créer une base secondaire synchronisée en temps réel avec une autre.

## **8.2 Arborescence d'un schéma PostgreSQL (ex. public)**

```
public
├── Aggregates
├── Collations
├── Domains
├── FTS Configurations
├── FTS Dictionaries
├── FTS Parsers
├── FTS Templates
├── Foreign Tables
├── Functions
├── Materialized Views
├── Operators
├── Procedures
├── Sequences
├── Tables
├── Trigger Functions
├── Types
└── Views
```

---
### **8.2.1 Aggregates**

Fonctions d'**agrégation personnalisées** (comme SUM, AVG, etc.)
- PostgreSQL permet de créer vos propres **fonctions d'agrégation**.
- Elles combinent plusieurs lignes en une seule valeur.

Exemple :
```sql
CREATE AGGREGATE public.concat_text(text) (
  SFUNC = textcat,
  STYPE = text
);
```

---
### **8.2.2 Collations**

Définit **les règles de tri et de comparaison de texte** selon une langue.

Exemple :
```sql
CREATE COLLATION fr_ci (locale = 'fr_FR.utf8');
```

---
### **8.2.3 Domains**

Créer un **type de données personnalisé** basé sur un type existant avec des contraintes.

Exemple :
```sql
CREATE DOMAIN email AS TEXT
  CHECK (VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,});
```

---
### **8.2.4 FTS (Full Text Search)**

PostgreSQL offre une recherche plein texte puissante via :
- **Configurations** : définissent comment analyser le texte
- **Dictionaries** : transforment les mots (stop-words, racinisation)
- **Parsers** : découpent le texte en tokens
- **Templates** : modèles pour créer des dictionnaires

---
### **8.2.5 Foreign Tables**

Tables **externes** accessibles comme si elles étaient locales.

---
### **8.2.6 Functions, Procedures, Trigger Functions**

Voir module 7 (Programmation SQL).

---
### **8.2.7 Sequences**

Générateurs de **valeurs uniques** (souvent pour les IDs).

Exemple :
```sql
CREATE SEQUENCE commandes_id_seq START 1;
```

---
### **8.2.8 Types**

Définition de **types de données personnalisés**.

Exemple :
```sql
CREATE TYPE coordonnees AS (
  latitude FLOAT,
  longitude FLOAT
);
```

---
### **8.2.9 Views et Materialized Views**

Voir module 5 (SQL avancé).

---

## **8.3 Outils d'administration**

### **8.3.1 psql - Interface en ligne de commande**

**Commandes essentielles :**
```bash
# Connexion
psql -U utilisateur -d base_de_donnees

# Lister les bases
\l

# Lister les tables
\dt

# Décrire une table
\d nom_table

# Décrire avec détails
\d+ nom_table

# Lister les fonctions
\df

# Exécuter un fichier SQL
\i chemin/vers/fichier.sql

# Afficher la durée des requêtes
\timing on

# Quitter
\q
```

### **8.3.2 pgAdmin - Interface graphique**

pgAdmin est l'outil d'administration graphique le plus populaire pour PostgreSQL.

**Fonctionnalités principales :**
- Navigation dans l'arborescence des objets
- Éditeur de requêtes avec coloration syntaxique
- Visualisation des plans d'exécution (EXPLAIN)
- Gestion des rôles et privilèges
- Monitoring en temps réel
- Import/Export de données

**Navigation typique :**
```
Serveurs
└── PostgreSQL 16
    └── Bases de données
        └── ma_base
            ├── Schémas
            │   └── public
            │       ├── Tables
            │       ├── Vues
            │       └── Fonctions
            └── Rôles
```

---

## **8.4 Monitoring et maintenance**

### **8.4.1 Vues système utiles**

```sql
-- Tables les plus volumineuses
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS taille
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Activité des connexions
SELECT * FROM pg_stat_activity;

-- Statistiques des tables
SELECT * FROM pg_stat_user_tables;

-- Index non utilisés
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

### **8.4.2 Logs et configuration**

```sql
-- Voir la configuration actuelle
SHOW all;

-- Modifier une configuration pour la session
SET work_mem = '256MB';

-- Localisation des fichiers de configuration
SHOW config_file;
SHOW hba_file;
SHOW data_directory;
```

---
