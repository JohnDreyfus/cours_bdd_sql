# **TP Module 9 - Sécurité et contrôle d'accès PostgreSQL**

## **Partie 1 : Préparation de l'environnement**

### **Étape 1.1 : Connexion et vérification**

Connectez-vous à PostgreSQL et positionnez-vous sur le bon schéma :

```sql
SET search_path TO ecommerce;

-- Vérifier que la base est bien installée
SELECT COUNT(*) AS nb_produits FROM produits;
SELECT COUNT(*) AS nb_clients FROM clients;
SELECT COUNT(*) AS nb_commandes FROM commandes;
```

### **Étape 1.2 : Vérification des rôles existants**

```sql
-- Lister tous les rôles PostgreSQL
SELECT rolname, rolsuper, rolcreatedb, rolcanlogin 
FROM pg_roles 
WHERE rolname NOT LIKE 'pg_%'
ORDER BY rolname;
```

---

## **Partie 2 : Création d'une hiérarchie de rôles**

### **Étape 2.1 : Création des rôles de groupe**

Créez les trois rôles de groupe (sans possibilité de connexion).
Vous allez créer trois groupes de rôles pour votre application e-commerce :
- **lecteur_shop** : peut uniquement consulter les produits et catégories
- **client_shop** : peut consulter et passer des commandes
- **admin_shop** : a tous les droits

### **Étape 2.2 : Attribution des privilèges aux groupes**

#### **Groupe lecteur_shop**

Ce groupe doit pouvoir :

- Accéder au schéma ecommerce
- Consulter les produits, catégories et fournisseurs
- Voir la vue v_produits_complets
#### **Groupe client_shop**

Ce groupe hérite de lecteur_shop et peut en plus :

- Consulter les commandes et lignes de commande
- Insérer des commandes et lignes de commande
- Utiliser les séquences (pour les ID auto-générés)
#### **Groupe admin_shop**

- Attribution de tous les privilèges pour admin_shop
### **Étape 2.3 : Création des utilisateurs**

Créez trois utilisateurs et associez-les aux groupes :

```sql
-- Utilisateur en lecture seule
lecteur_shop TO visiteur;

-- Utilisateur client normal
client_shop TO gerard;

-- Utilisateur administrateur
admin_shop TO superadmin;
```

### **Étape 2.4 : Test des privilèges**

**Test 1 : Visiteur (lecture seule)**

Connectez-vous en tant que visiteur :

```bash
SET ROLE le_role;
```

```sql
SET search_path TO ecommerce;

-- Test 1 : Lecture des produits (doit fonctionner)
SELECT nom, prix FROM produits LIMIT 3;

-- Test 2 : Tentative d'insertion (doit échouer)
INSERT INTO produits (nom, prix, stock) VALUES ('Test', 100, 10);
```

**Test 2 : gerard (client)**

```bash
SET ROLE le_role;
```

```sql
SET search_path TO ecommerce;

-- Test 1 : Lecture des produits (doit fonctionner)
SELECT nom, prix FROM produits LIMIT 3;

-- Test 2 : Créer une commande (doit fonctionner)
INSERT INTO commandes (client_id, statut) VALUES (2, 'en_attente');

-- Test 3 : Modifier un produit (doit échouer)
UPDATE produits SET prix = 999 WHERE id = 1;
```

---

## **Partie 3 : Row-Level Security (RLS) (30 min)**

### **Étape 3.1 : Comprendre le besoin**

Actuellement, tous les clients peuvent voir toutes les commandes. Vous allez mettre en place RLS pour que chaque client ne voie que ses propres commandes.

### **Étape 3.2 : Activer RLS sur la table commandes**

Reconnectez-vous avec votre compte principal (dev).

```sql
SET search_path TO ecommerce;

-- Activer RLS
ALTER TABLE commandes ENABLE ROW LEVEL SECURITY;

-- Forcer RLS même pour le propriétaire de la table
ALTER TABLE commandes FORCE ROW LEVEL SECURITY;
```

### **Étape 3.3 : Créer les politiques RLS**

#### **Politique 1 : Les clients voient leurs propres commandes**

Utiliser une variable de session pour identifier l'utilisateur connecté.
Créez une politique qui permet à un client de voir uniquement ses commandes.

Indications :
- Utilisez `CREATE POLICY ... ON commandes FOR SELECT`
- La condition `USING` doit comparer `client_id` avec une variable de session
- Utilisez `current_setting('app.client_id')::INTEGER` pour récupérer l'ID du client

#### **Politique 2 : Les clients créent des commandes pour eux-mêmes**

Créez une politique qui permet à un client de créer uniquement des commandes avec son propre client_id.

#### **Politique 3 : Les administrateurs voient tout**

Créez une politique qui permet à l'administrateur de tout voir.

### **Étape 3.4 : Test du RLS**

**Test 1 : Client 1**

```sql
-- Simuler la connexion du client 1 (Jean Dupont)
SET app.client_id = 1;

-- Vérifier l'ID configuré
SELECT current_setting('app.client_id', true)::INTEGER AS mon_client_id;

-- Voir ses commandes (devrait retourner uniquement les commandes du client 1)
SELECT id, numero, date_commande, statut, client_id FROM commandes;

-- Compter le nombre de commandes visibles
SELECT COUNT(*) FROM commandes;
```

**Test 2 : Client 2**

```sql
-- Changer pour le client 2 (Sophie Martin)
SET app.client_id = 2;

-- Voir ses commandes
SELECT id, numero, date_commande, statut, client_id FROM commandes;
```

**Test 3 : Tentative de triche**

```sql
-- Toujours en tant que client 2
SET app.client_id = 2;

-- Essayer de créer une commande pour le client 1 (doit échouer)
INSERT INTO commandes (client_id, statut) VALUES (1, 'en_attente');
```

**Test 4 : Administrateur**

```sql
-- Se connecter en tant qu'admin (ou faire GRANT admin_shop TO votre_user)
SET ROLE admin;
SET search_path TO ecommerce;

-- L'admin voit toutes les commandes
SELECT COUNT(*) FROM commandes;
```