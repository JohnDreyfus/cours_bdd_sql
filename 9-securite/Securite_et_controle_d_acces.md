# **9 – Sécurité et contrôle d'accès** {#9-securite}

## **Objectifs pédagogiques**

- Maîtriser la gestion des rôles et privilèges PostgreSQL
- Comprendre et implémenter Row-Level Security (RLS)
- Sécuriser les accès et protéger les données sensibles
- Appliquer les bonnes pratiques de sécurité en production
- Mettre en place un audit trail des modifications

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

### **9.2.2 Hiérarchie des rôles**

PostgreSQL distingue :
- **Rôles de groupe** (NOLOGIN) : contiennent des privilèges
- **Rôles utilisateurs** (LOGIN) : peuvent se connecter

#### **Création de rôles structurés**

```sql
-- Rôles applicatifs (groupes)
CREATE ROLE lecteur NOLOGIN;
CREATE ROLE redacteur NOLOGIN;
CREATE ROLE admin_app NOLOGIN;

-- Attribution des droits aux groupes
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lecteur;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO redacteur;
GRANT ALL PRIVILEGES ON SCHEMA public TO admin_app;

-- Rôles utilisateurs
CREATE ROLE alice LOGIN PASSWORD 'mot_de_passe_securise';
CREATE ROLE bob LOGIN PASSWORD 'mot_de_passe_securise';
CREATE ROLE charlie LOGIN PASSWORD 'mot_de_passe_securise';

-- Attribution des groupes aux utilisateurs
GRANT lecteur TO alice;
GRANT redacteur TO bob;
GRANT admin_app TO charlie;
```

### **9.2.3 Privilèges sur les objets**

#### **Privilèges disponibles**

| **Objet**  | **Privilèges disponibles**                      |
| ---------- | ----------------------------------------------- |
| Table      | SELECT, INSERT, UPDATE, DELETE, TRUNCATE        |
| Séquence   | USAGE, SELECT, UPDATE                           |
| Schéma     | CREATE, USAGE                                   |
| Base       | CREATE, CONNECT, TEMPORARY                      |
| Fonction   | EXECUTE                                         |

#### **Attribution de privilèges**

```sql
-- Sur une table spécifique
GRANT SELECT, INSERT ON clients TO redacteur;

-- Sur toutes les tables d'un schéma
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lecteur;

-- Privilèges par défaut pour les futurs objets
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO lecteur;

-- Révocation de privilèges
REVOKE INSERT ON clients FROM redacteur;
```

### **9.2.4 Gestion des schémas**

Les schémas permettent d'organiser logiquement les objets et d'isoler les permissions.

```sql
-- Créer un schéma par domaine fonctionnel
CREATE SCHEMA comptabilite AUTHORIZATION admin_compta;
CREATE SCHEMA inventaire AUTHORIZATION admin_stock;
CREATE SCHEMA ventes AUTHORIZATION admin_ventes;

-- Limiter l'accès au schéma public
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE ma_base FROM PUBLIC;

-- Donner accès à un schéma spécifique
GRANT USAGE ON SCHEMA comptabilite TO user_compta;
GRANT SELECT ON ALL TABLES IN SCHEMA comptabilite TO user_compta;
```

### **9.2.5 Attributs de rôle**

```sql
-- Créer un rôle avec attributs spécifiques
CREATE ROLE dev_user 
  LOGIN 
  PASSWORD 'dev_password'
  VALID UNTIL '2025-12-31'
  CONNECTION LIMIT 5
  NOCREATEDB
  NOCREATEROLE
  NOSUPERUSER;

-- Modifier les attributs d'un rôle existant
ALTER ROLE alice VALID UNTIL '2026-01-01';
ALTER ROLE bob CONNECTION LIMIT 10;
ALTER ROLE charlie CREATEDB;

-- Limiter l'usage du superuser
ALTER ROLE dev_user NOSUPERUSER;
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

---

### **9.3.2 Activation du RLS**

```sql
-- Activer RLS sur une table
ALTER TABLE commandes ENABLE ROW LEVEL SECURITY;

-- Forcer RLS même pour les propriétaires de table
ALTER TABLE commandes FORCE ROW LEVEL SECURITY;

-- Désactiver RLS
ALTER TABLE commandes DISABLE ROW LEVEL SECURITY;
```

---

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

#### **Exemple complet : système multi-tenant**

```sql
-- Table avec identification du tenant
CREATE TABLE documents (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id INTEGER NOT NULL,
    titre TEXT NOT NULL,
    contenu TEXT,
    created_by TEXT DEFAULT current_user,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Activer RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Politique de lecture : voir uniquement ses documents
CREATE POLICY documents_select_policy
ON documents
FOR SELECT
TO PUBLIC
USING (tenant_id = current_setting('app.tenant_id')::INTEGER);

-- Politique d'insertion : créer uniquement pour son tenant
CREATE POLICY documents_insert_policy
ON documents
FOR INSERT
TO PUBLIC
WITH CHECK (tenant_id = current_setting('app.tenant_id')::INTEGER);

-- Politique de modification
CREATE POLICY documents_update_policy
ON documents
FOR UPDATE
TO PUBLIC
USING (tenant_id = current_setting('app.tenant_id')::INTEGER)
WITH CHECK (tenant_id = current_setting('app.tenant_id')::INTEGER);

-- Politique pour les administrateurs (voient tout)
CREATE POLICY documents_admin_policy
ON documents
FOR ALL
TO admin_role
USING (true);
```

#### **Utilisation dans l'application**

```sql
-- Définir le tenant pour la session
SET app.tenant_id = 42;

-- L'utilisateur ne verra que ses documents
SELECT * FROM documents;

-- Impossible d'insérer pour un autre tenant
INSERT INTO documents (tenant_id, titre) VALUES (99, 'Test');  -- Échouera
```

---

### **9.3.4 Politiques avancées**

#### **Politique basée sur le rôle**

```sql
CREATE POLICY commandes_vendeur_policy
ON commandes
FOR SELECT
TO vendeur_role
USING (region = current_setting('app.user_region'));
```

#### **Politique avec jointure**

```sql
CREATE POLICY projets_equipe_policy
ON projets
FOR ALL
TO PUBLIC
USING (
    EXISTS (
        SELECT 1 FROM membres_equipe
        WHERE projet_id = projets.id
        AND user_id = current_user::regrole::oid
    )
);
```

#### **Politique temporelle**

```sql
CREATE POLICY documents_archives_policy
ON documents
FOR SELECT
TO PUBLIC
USING (
    archive_date IS NULL 
    OR archive_date > CURRENT_DATE - INTERVAL '1 year'
);
```

---

## **9.4 Chiffrement et protection des données**

### **9.4.1 Extension pgcrypto**

```sql
CREATE EXTENSION pgcrypto;

-- Hachage de mots de passe
CREATE TABLE utilisateurs (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL
);

-- Insertion avec hachage
INSERT INTO utilisateurs (username, password_hash)
VALUES ('alice', crypt('mon_mot_de_passe', gen_salt('bf')));

-- Vérification du mot de passe
SELECT * FROM utilisateurs
WHERE username = 'alice'
AND password_hash = crypt('mon_mot_de_passe', password_hash);
```

### **9.4.2 Chiffrement de colonnes**

```sql
-- Chiffrement symétrique
CREATE TABLE donnees_sensibles (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    data_chiffree BYTEA
);

-- Insertion avec chiffrement
INSERT INTO donnees_sensibles (data_chiffree)
VALUES (pgp_sym_encrypt('Données confidentielles', 'clé_secrète'));

-- Déchiffrement
SELECT pgp_sym_decrypt(data_chiffree, 'clé_secrète')
FROM donnees_sensibles;
```

---

## **9.5 Audit et journalisation**

### **9.5.1 Table d'audit générique**

```sql
CREATE TABLE audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    user_name TEXT DEFAULT current_user,
    timestamp TIMESTAMP DEFAULT NOW(),
    old_data JSONB,
    new_data JSONB
);

-- Fonction d'audit générique
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, old_data, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, old_data)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END;
$;

-- Appliquer l'audit sur une table
CREATE TRIGGER audit_clients
AFTER INSERT OR UPDATE OR DELETE ON clients
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
```

### **9.5.2 Suivi des connexions**

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

---

## **9.6 Bonnes pratiques de sécurité**

### **Checklist de sécurité**

1. **Authentification**
    - ✅ Utiliser des mots de passe forts
    - ✅ Configurer pg_hba.conf strictement
    - ✅ Activer SSL/TLS pour les connexions distantes
    - ✅ Limiter les connexions par IP

2. **Autorisation**
    - ✅ Appliquer le principe du moindre privilège
    - ✅ Utiliser des rôles plutôt que des utilisateurs directs
    - ✅ Séparer les environnements (dev/test/prod)
    - ✅ Révoquer public de façon systématique

3. **Protection des données**
    - ✅ Activer RLS pour les données sensibles
    - ✅ Chiffrer les données au repos (transparent data encryption)
    - ✅ Hacher les mots de passe avec bcrypt
    - ✅ Masquer les données sensibles dans les logs

4. **Audit**
    - ✅ Logger toutes les modifications critiques
    - ✅ Surveiller les tentatives d'accès non autorisées
    - ✅ Conserver les logs d'audit
    - ✅ Réviser régulièrement les privilèges

5. **Maintenance**
    - ✅ Mettre à jour PostgreSQL régulièrement
    - ✅ Supprimer les comptes inutilisés
    - ✅ Faire expirer les mots de passe
    - ✅ Limiter les connexions superuser

### **Configuration pg_hba.conf sécurisée**

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Connexions locales (socket Unix)
local   all             postgres                                peer

# Connexions locales TCP
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256

# Connexions depuis le réseau interne
host    production_db   app_user        10.0.0.0/8              scram-sha-256

# Refuser tout le reste
host    all             all             0.0.0.0/0               reject
```

---

## **9.7 Cas pratique : Application multi-tenant sécurisée**

```sql
-- 1. Structure de base
CREATE TABLE tenants (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom TEXT UNIQUE NOT NULL,
    actif BOOLEAN DEFAULT true
);

CREATE TABLE users (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    tenant_id INTEGER REFERENCES tenants(id),
    role TEXT CHECK (role IN ('admin', 'user', 'readonly'))
);

CREATE TABLE data (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES tenants(id),
    contenu TEXT,
    created_by INTEGER REFERENCES users(id)
);

-- 2. Activer RLS
ALTER TABLE data ENABLE ROW LEVEL SECURITY;

-- 3. Politiques RLS
CREATE POLICY data_tenant_isolation
ON data
FOR ALL
TO PUBLIC
USING (tenant_id = current_setting('app.current_tenant_id')::INTEGER);

-- 4. Fonction de connexion
CREATE OR REPLACE FUNCTION app_login(p_username TEXT, p_password TEXT)
RETURNS TABLE(user_id INT, tenant_id INT, user_role TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $
DECLARE
    v_user users%ROWTYPE;
BEGIN
    SELECT * INTO v_user
    FROM users
    WHERE username = p_username
    AND password_hash = crypt(p_password, password_hash);
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Authentification échouée';
    END IF;
    
    -- Définir les variables de session
    PERFORM set_config('app.current_tenant_id', v_user.tenant_id::TEXT, false);
    PERFORM set_config('app.current_user_id', v_user.id::TEXT, false);
    PERFORM set_config('app.current_user_role', v_user.role, false);
    
    RETURN QUERY SELECT v_user.id, v_user.tenant_id, v_user.role;
END;
$;

-- 5. Utilisation
SELECT * FROM app_login('alice', 'password123');
SELECT * FROM data;  -- Ne verra que les données de son tenant
```

---
