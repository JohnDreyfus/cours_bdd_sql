# **9 — Sécurité et contrôle d'accès** {#9-securite}

## **Objectifs pédagogiques**

- Maîtriser la gestion des rôles et privilèges PostgreSQL
- Comprendre et implémenter Row-Level Security (RLS)
- Sécuriser les accès et protéger les données sensibles
- Appliquer les bonnes pratiques de sécurité en production

---

## **9.1 Architecture de sécurité PostgreSQL**

PostgreSQL utilise un modèle de sécurité en couches :

```
┌─────────────────────────────────────┐
│   1. Authentification (pg_hba.conf) │  Qui peut se connecter ?
├─────────────────────────────────────┤
│   2. Rôles et Privilèges            │  Que peut-on faire ?
├─────────────────────────────────────┤
│   3. Row-Level Security (RLS)       │  Quelles lignes voir ?
├─────────────────────────────────────┤
│   4. Chiffrement (SSL/TLS)          │  Protection des données
└─────────────────────────────────────┘
```

---

## **9.2 Gestion des rôles et privilèges**

### **9.2.1 Principe du moindre privilège**

**Règle d'or :** Donner uniquement les droits nécessaires à chaque rôle.

### **9.2.2 Rôles système PostgreSQL (préexistants)**

PostgreSQL crée automatiquement des rôles système lors de l'installation :

```sql
-- Voir tous les rôles système
SELECT rolname, rolsuper, rolcreatedb, rolcanlogin 
FROM pg_roles 
ORDER BY rolname;
```

|**Rôle**|**Description**|**Privilèges**|
|---|---|---|
|`postgres`|Superutilisateur par défaut|Tous les droits|
|`pg_monitor`|Monitoring du système|Lecture des statistiques|
|`pg_read_all_settings`|Lecture de la configuration|SHOW ALL|
|`pg_read_all_stats`|Lecture de toutes les stats|pg_stat_*|
|`pg_stat_scan_tables`|Scan des tables|VACUUM, ANALYZE|
|`pg_read_server_files`|Lecture des fichiers serveur|COPY FROM|
|`pg_write_server_files`|Écriture des fichiers serveur|COPY TO|
|`pg_execute_server_program`|Exécution de programmes|COPY PROGRAM|
|`pg_signal_backend`|Envoi de signaux|pg_cancel_backend()|

### **9.2.3 Création d'un rôle**

Chaque rôle PostgreSQL possède des **attributs** :

```sql
CREATE ROLE nom_du_role
    [LOGIN | NOLOGIN]             -- Peut-on se connecter ?
    [SUPERUSER | NOSUPERUSER]     -- Est-ce un super-admin ?
    [CREATEDB | NOCREATEDB]       -- Peut créer des bases ?
    [CREATEROLE | NOCREATEROLE]   -- Peut créer d'autres rôles ?
    [INHERIT | NOINHERIT]         -- Hérite des privilèges ?
    [REPLICATION | NOREPLICATION] -- Peut faire de la réplication ?
    [PASSWORD 'mot_de_passe']     -- Mot de passe (si LOGIN)
    [CONNECTION LIMIT n]          -- Limite de connexions
    [VALID UNTIL 'date'];         -- Date d'expiration
```

**Exemple pratique :**

```sql
-- Créer un utilisateur avec connexion
CREATE ROLE alice LOGIN PASSWORD 'secure_password_123';

-- Créer un rôle de groupe (sans connexion)
CREATE ROLE lecteur_ecommerce NOLOGIN;

-- Créer un rôle avec attributs spécifiques
CREATE ROLE dev_user 
  LOGIN 
  PASSWORD 'dev_password'
  VALID UNTIL '2025-12-31'
  CONNECTION LIMIT 5
  NOCREATEDB
  NOCREATEROLE
  NOSUPERUSER;
```

> **Note importante :** Par défaut, un rôle nouvellement créé n'a **aucun privilège** sur les objets existants. Il faut les attribuer explicitement avec `GRANT`.

### **9.2.4 Attribution des privilèges**

Le DCL (Data Control Language) gère les **droits d'accès et la sécurité**.

|**Commande**|**Rôle**|
|---|---|
|GRANT|Accorder un privilège|
|REVOKE|Retirer un privilège|
|CREATE ROLE|Créer un rôle ou utilisateur|

#### **Privilèges disponibles par type d'objet**

|**Objet**|**Privilèges disponibles**|
|---|---|
|Table|SELECT, INSERT, UPDATE, DELETE, TRUNCATE|
|Séquence|USAGE, SELECT, UPDATE|
|Schéma|CREATE, USAGE|
|Base|CREATE, CONNECT, TEMPORARY|
|Fonction|EXECUTE|

#### **Attribution de privilèges**

```sql
-- Sur une table spécifique
GRANT SELECT, INSERT ON clients TO alice;

-- Sur toutes les tables d'un schéma
GRANT SELECT ON ALL TABLES IN SCHEMA ecommerce TO lecteur_ecommerce;

-- Privilèges par défaut pour les futurs objets
ALTER DEFAULT PRIVILEGES IN SCHEMA ecommerce
GRANT SELECT ON TABLES TO lecteur_ecommerce;

-- Révocation de privilèges
REVOKE INSERT ON clients FROM alice;
```

### **9.2.5 Gestion des schémas et privilèges imbriqués**

**Les schémas sont comme des "dossiers" dans une base de données.**

Pour accéder aux objets d'un schéma, il faut **2 privilèges** :

1. **`USAGE`** sur le **schéma** (pour "entrer" dans le dossier)
2. **Privilèges spécifiques** sur les **objets** (tables, vues, etc.)

```sql
-- Créer un schéma par domaine fonctionnel
CREATE SCHEMA comptabilite;
CREATE SCHEMA inventaire;
CREATE SCHEMA ventes;

-- Limiter l'accès au schéma public
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Donner accès à un schéma spécifique
GRANT USAGE ON SCHEMA ecommerce TO lecteur_ecommerce;
GRANT SELECT ON ALL TABLES IN SCHEMA ecommerce TO lecteur_ecommerce;
```

### **9.2.6 Hiérarchie des rôles : rôles de groupe**

PostgreSQL permet de créer des **rôles de groupe** qui contiennent d'autres rôles.

```sql
-- Créer un rôle de groupe (NOLOGIN = pas de connexion directe)
CREATE ROLE application NOLOGIN;

-- Attribuer des privilèges au groupe
GRANT USAGE ON SCHEMA ecommerce TO application;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ecommerce TO application;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ecommerce TO application;

-- Ajouter Alice au groupe
GRANT application TO alice;
```

**Résultat :** Alice hérite automatiquement de tous les privilèges du groupe `application`.

**Test pratique :**

```sql
-- Se connecter en tant qu'alice
SET ROLE alice;

-- Alice peut maintenant insérer des données
INSERT INTO utilisateurs (username, password_hash, client_id, role)
VALUES ('john.doe', crypt('pass123', gen_salt('bf')), 1, 'client');

-- Retour au rôle initial
RESET ROLE;
```

> **Bonne pratique :** Utilisez toujours des rôles de groupe plutôt que d'attribuer des privilèges directement aux utilisateurs. Cela simplifie la gestion et la maintenance.

### **9.2.7 Cas particulier : séquences**

Les séquences (pour les colonnes `IDENTITY` ou `SERIAL`) nécessitent un privilège spécifique :

```sql
-- Donner l'accès aux séquences (pour les INSERT)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ecommerce TO application;

-- Pour les futures séquences
ALTER DEFAULT PRIVILEGES IN SCHEMA ecommerce
GRANT USAGE, SELECT ON SEQUENCES TO application;
```

**Sans ce privilège, les `INSERT` échoueront avec :**

```
ERROR: permission denied for sequence produits_id_seq
```

### **9.2.8 Commandes de gestion des rôles**

```sql
-- Lister tous les rôles
\du

-- Voir les privilèges d'un rôle
\du alice

-- Voir les privilèges sur une table
\dp ecommerce.clients

-- Modifier un rôle existant
ALTER ROLE alice VALID UNTIL '2026-01-01';
ALTER ROLE alice CONNECTION LIMIT 10;

-- Supprimer un rôle
DROP ROLE alice;

-- Révoquer tous les privilèges
REVOKE ALL PRIVILEGES ON SCHEMA ecommerce FROM alice;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA ecommerce FROM alice;
```

---

## **9.3 Row-Level Security (RLS)**

### **9.3.1 Principe**

La **sécurité au niveau des lignes (RLS)** permet de définir des **politiques d'accès qui filtrent les lignes visibles** pour chaque utilisateur.

**Cas d'usage typiques :**

- Applications multi-tenants (chaque client voit ses données)
- Séparation par département
- Hiérarchie organisationnelle
- Données personnelles (RGPD)

> **Important :** RLS ne remplace pas les privilèges classiques. Un utilisateur doit **d'abord avoir le privilège `SELECT`** sur la table avant que RLS ne filtre les lignes.

### **9.3.2 Activation du RLS**

```sql
-- Activer RLS sur une table
ALTER TABLE commandes ENABLE ROW LEVEL SECURITY;

-- Forcer RLS même pour les propriétaires de table
ALTER TABLE commandes FORCE ROW LEVEL SECURITY;

-- Désactiver RLS
ALTER TABLE commandes DISABLE ROW LEVEL SECURITY;
```

**Différence entre `ENABLE` et `FORCE` :**

- `ENABLE` : RLS s'applique aux utilisateurs normaux, mais pas au propriétaire de la table
- `FORCE` : RLS s'applique à **tous**, y compris le propriétaire (sauf les superutilisateurs)

### **9.3.3 Création de politiques**

#### **Syntaxe générale**

```sql
CREATE POLICY nom_policy
ON table
[ FOR { ALL | SELECT | INSERT | UPDATE | DELETE } ]
[ TO { role_name | PUBLIC | CURRENT_USER } ]
[ USING (condition_visibilite) ]
[ WITH CHECK (condition_insertion) ];
```

#### **Clauses principales**

|**Clause**|**Question**|**S'applique à**|**Exemple**|
|---|---|---|---|
|`FOR`|Quelle opération ?|Toutes policies|`FOR SELECT`|
|`TO`|Pour qui ?|Toutes policies|`TO alice` ou `TO PUBLIC`|
|`USING`|Quelles lignes **lire** ?|SELECT, UPDATE, DELETE|`USING (client_id = current_setting('app.user_id')::INTEGER)`|
|`WITH CHECK`|Quelles lignes **écrire** ?|INSERT, UPDATE|`WITH CHECK (prix > 0)`|

#### **Exemple complet : commandes par client**

```sql
-- 1. Définir une variable de session (simule l'utilisateur connecté)
SET app.user_id = 1;

-- Vérifier la valeur
SELECT current_setting('app.user_id')::INTEGER;

-- 2. Activer RLS sur la table
ALTER TABLE commandes ENABLE ROW LEVEL SECURITY;

-- 3. Créer une politique de lecture
CREATE POLICY voir_mes_commandes
ON commandes
FOR SELECT                    -- ← Seulement la lecture
TO PUBLIC                     -- ← Tout le monde
USING (                       -- ← Filtre : quelles lignes voir ?
    client_id = current_setting('app.user_id')::INTEGER
);

-- 4. Créer une politique d'insertion
CREATE POLICY creer_mes_commandes
ON commandes
FOR INSERT
TO PUBLIC
WITH CHECK (                  -- ← Condition pour insérer
    client_id = current_setting('app.user_id')::INTEGER
);

-- 5. Politique pour les administrateurs (voient tout)
CREATE POLICY admin_voit_tout
ON commandes
FOR ALL
TO admin_ecommerce
USING (true);                 -- ← Aucune restriction
```

#### **Test pratique**

```sql
-- Utilisateur 1 voit uniquement ses commandes
SET app.user_id = 1;
SELECT * FROM commandes;  -- Retourne uniquement les commandes du client 1

-- Utilisateur 2 ne voit pas les commandes de 1
SET app.user_id = 2;
SELECT * FROM commandes;  -- Retourne uniquement les commandes du client 2

-- Tentative d'insertion pour un autre client (échoue)
INSERT INTO commandes (client_id, statut)
VALUES (999, 'en_attente');   -- ERREUR : WITH CHECK violation
```

### **9.3.4 Politiques avancées**

#### **Politique avec jointure**

```sql
-- Un utilisateur voit les commandes de son entreprise
CREATE POLICY commandes_entreprise
ON commandes
FOR SELECT
TO PUBLIC
USING (
    client_id IN (
        SELECT id FROM clients
        WHERE entreprise_id = current_setting('app.entreprise_id')::INTEGER
    )
);
```

#### **Politique temporelle**

```sql
-- Masquer les commandes archivées de plus d'un an
CREATE POLICY commandes_recentes
ON commandes
FOR SELECT
TO PUBLIC
USING (
    date_commande > CURRENT_DATE - INTERVAL '1 year'
    OR statut != 'archivee'
);
```

### **9.3.5 Gestion des politiques**

```sql
-- Lister toutes les politiques
SELECT schemaname, tablename, policyname, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'ecommerce';

-- Supprimer une politique
DROP POLICY voir_mes_commandes ON commandes;

-- Modifier une politique (il faut la recréer)
DROP POLICY voir_mes_commandes ON commandes;
CREATE POLICY voir_mes_commandes ON commandes
FOR SELECT TO PUBLIC
USING (client_id = current_setting('app.user_id')::INTEGER);

-- Désactiver temporairement RLS (pour tests)
ALTER TABLE commandes DISABLE ROW LEVEL SECURITY;
```

---

## **9.4 Audit et traçabilité**

### **9.4.1 Consulter l'audit log**

```sql
-- Voir les dernières modifications sur les clients
SELECT 
    id,
    table_name,
    operation,
    user_name,
    timestamp,
    new_data->>'nom' AS nouveau_nom,
    new_data->>'email' AS nouvel_email
FROM audit_log
WHERE table_name = 'clients'
ORDER BY timestamp DESC
LIMIT 10;
```

### **9.4.2 Suivre les modifications d'une commande**

```sql
-- Historique des changements de statut
SELECT 
    operation,
    user_name,
    timestamp,
    old_data->>'statut' AS ancien_statut,
    new_data->>'statut' AS nouveau_statut
FROM audit_log
WHERE table_name = 'commandes'
  AND row_id = 1
ORDER BY timestamp;
```

### **9.4.3 Surveillance des connexions**

```sql
-- Voir les connexions actives
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    backend_start,
    state,
    query
FROM pg_stat_activity
WHERE state = 'active';

-- Historique des connexions (nécessite configuration dans postgresql.conf)
-- log_connections = on
-- log_disconnections = on
```