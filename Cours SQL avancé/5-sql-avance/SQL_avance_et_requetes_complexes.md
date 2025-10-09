# **5 – SQL avancé et requêtes complexes** {#5-sql-avance}

## **Objectifs pédagogiques**

- Approfondir la maîtrise du SQL relationnel au-delà des requêtes simples.
- Comprendre les concepts avancés de PostgreSQL 16 et leurs avantages.
- Savoir écrire des requêtes **puissantes, performantes et lisibles**.
- Être capable d'extraire, agréger et transformer des données complexes.

---
## **5.1 Rappels fondamentaux : DDL, DML, DCL, TCL**
### **5.1.1 DDL – Data Definition Language**

Le DDL (langage de définition des données) permet de **créer, modifier ou supprimer la structure** de la base de données.
#### **Principales commandes :**

|**Commande**|**Rôle**|
|---|---|
|CREATE|Créer un objet (table, vue, schéma, index, séquence, etc.)|
|ALTER|Modifier un objet existant|
|DROP|Supprimer un objet|
|TRUNCATE|Vider une table sans supprimer sa structure|
  
---
### **5.1.2 DML – Data Manipulation Language**

Le DML gère les **données contenues dans les tables**.
#### **Commandes principales :**

|**Commande**|**Rôle**|
|---|---|
|INSERT|Ajouter des enregistrements|
|UPDATE|Modifier des enregistrements|
|DELETE|Supprimer des enregistrements|
|SELECT|Interroger des données|

#### **PostgreSQL 16 – Fonctionnalités avancées :**
- **UPSERT (INSERT ON CONFLICT)** : évite les doublons.
```sql
-- Mise à jour du stock ou insertion si le produit n'existe pas
INSERT INTO produits (id, nom, categorie_id, fournisseur_id, prix, stock)
VALUES (1, 'MacBook Pro 16"', 2, 1, 2399.00, 20)
ON CONFLICT (id) DO UPDATE
  SET prix = EXCLUDED.prix,
      stock = EXCLUDED.stock,
      updated_at = NOW();
```

---
### **5.1.3 DCL – Data Control Language**

Le DCL gère les **droits d'accès et la sécurité**.

|**Commande**|**Rôle**|
|---|---|
|GRANT|Accorder un privilège|
|REVOKE|Retirer un privilège|
|CREATE ROLE|Créer un rôle ou utilisateur|

---
### **5.1.4 TCL – Transaction Control Language**

Le TCL contrôle la **gestion des transactions**.

|**Commande**|**Rôle**|
|---|---|
|BEGIN|Démarre une transaction|
|COMMIT|Valide la transaction|
|ROLLBACK|Annule la transaction|
|SAVEPOINT|Crée un point de restauration|
Exemple :
```sql
BEGIN;
UPDATE produit SET prix = prix * 1.10 WHERE id = 1;
SAVEPOINT avant_remise;
UPDATE produit SET prix = prix - 5 WHERE id = 1;
ROLLBACK TO avant_remise;  -- annule la remise mais garde la première maj
COMMIT;
```

---
## **5.2. Fonctions d'agrégation et GROUP BY avancé**

### **Définition**
Les **fonctions d'agrégation** calculent une valeur unique à partir d'un ensemble de lignes.
Elles s'utilisent avec GROUP BY pour regrouper des données par catégorie.

|**Fonction**|**Description**|
|---|---|
|COUNT()|Compte le nombre de lignes|
|SUM()|Calcule la somme|
|AVG()|Moyenne|
|MIN() / MAX()|Valeur min/max|
|STRING_AGG()|Concatène des chaînes|
Exemple :
```sql
-- Statistiques par catégorie
SELECT 
    c.nom AS categorie,
    COUNT(p.id) AS nb_produits,
    AVG(p.prix) AS prix_moyen,
    MIN(p.prix) AS prix_min,
    MAX(p.prix) AS prix_max,
    SUM(p.stock) AS stock_total
FROM categories c
LEFT JOIN produits p ON p.categorie_id = c.id
GROUP BY c.id, c.nom
HAVING COUNT(p.id) > 0
ORDER BY prix_moyen DESC;
```

### **FILTER : condition sur agrégat**

```sql
-- Compter les produits selon leur disponibilité
SELECT 
    COUNT(*) AS total_produits,
    COUNT(*) FILTER (WHERE stock > 0) AS en_stock,
    COUNT(*) FILTER (WHERE stock = 0) AS rupture,
    COUNT(*) FILTER (WHERE stock < stock_minimum) AS stock_faible
FROM produits;
```

---
## **5.3 Jointures, sous-requêtes et CTE (WITH)**

### **5.3.1 Les types de jointures**

|**Type**|**Description**|**Exemple**|
|---|---|---|
|INNER JOIN|lignes correspondantes uniquement|A JOIN B ON condition|
|LEFT JOIN|toutes les lignes de gauche + correspondances|A LEFT JOIN B|
|RIGHT JOIN|toutes les lignes de droite|A RIGHT JOIN B|
|FULL JOIN|union des deux côtés|A FULL JOIN B|
|CROSS JOIN|produit cartésien|A CROSS JOIN B|
Exemple :
```sql
-- Commandes avec détails clients et produits
SELECT 
    co.numero AS numero_commande,
    cl.nom || ' ' || cl.prenom AS client,
    cl.email,
    p.nom AS produit,
    lc.quantite,
    lc.prix_unitaire,
    lc.montant_ligne,
    co.statut
FROM commandes co
INNER JOIN clients cl ON cl.id = co.client_id
INNER JOIN lignes_commande lc ON lc.commande_id = co.id
INNER JOIN produits p ON p.id = lc.produit_id
WHERE co.statut IN ('confirmee', 'expediee')
ORDER BY co.date_commande DESC;
```

### **5.3.2 Sous-requêtes corrélées**

Une sous-requête dépend d'une ligne de la requête principale.
```sql
-- Produits avec un prix supérieur à la moyenne de leur catégorie
SELECT 
    p.nom,
    p.prix,
    c.nom AS categorie,
    (SELECT ROUND(AVG(prix), 2) 
     FROM produits p2 
     WHERE p2.categorie_id = p.categorie_id) AS prix_moyen_categorie
FROM produits p
JOIN categories c ON c.id = p.categorie_id
WHERE p.prix > (
    SELECT AVG(prix) 
    FROM produits p2 
    WHERE p2.categorie_id = p.categorie_id
)
ORDER BY p.categorie_id, p.prix DESC;
```

### **5.3.3 CTE – Common Table Expression**

Les CTE (introduits par WITH) structurent les requêtes complexes.
```sql
-- Clients VIP (plus de 3 commandes)
WITH clients_vip AS (
    SELECT 
        client_id,
        COUNT(*) AS nb_commandes,
        SUM(montant_ttc) AS total_achats
    FROM commandes
    WHERE statut != 'annulee'
    GROUP BY client_id
    HAVING COUNT(*) > 2
)
SELECT 
    c.nom,
    c.prenom,
    c.email,
    cv.nb_commandes,
    cv.total_achats,
    c.points_fidelite
FROM clients_vip cv
JOIN clients c ON c.id = cv.client_id
ORDER BY cv.total_achats DESC;
```

---
## **5.4 Vues et vues matérialisées**

### **5.4.1 Vues**
Une vue est une **requête enregistrée**.
```sql
-- Vue déjà créée : v_produits_complets
SELECT * FROM v_produits_complets
WHERE statut_stock = 'disponible'
ORDER BY note_moyenne DESC
LIMIT 10;

-- Vue des meilleurs clients
CREATE OR REPLACE VIEW v_meilleurs_clients AS
SELECT 
    c.id,
    c.nom || ' ' || c.prenom AS client,
    c.email,
    COUNT(DISTINCT co.id) AS nb_commandes,
    COALESCE(SUM(co.montant_ttc), 0) AS total_achats,
    COALESCE(AVG(co.montant_ttc), 0) AS panier_moyen,
    c.points_fidelite
FROM clients c
LEFT JOIN commandes co ON co.client_id = c.id AND co.statut != 'annulee'
GROUP BY c.id, c.nom, c.prenom, c.email, c.points_fidelite
ORDER BY total_achats DESC;

SELECT * FROM v_meilleurs_clients;
```
- Pas de stockage physique.
- Actualisée à chaque lecture.

### **5.4.2 Vue matérialisée**

Une vue matérialisée **stocke les résultats**.
```sql
CREATE MATERIALIZED VIEW mv_stats_ventes_mensuelles AS
SELECT
    date_trunc('month', c.date_commande) AS mois,
    COUNT(DISTINCT c.id) AS nombre_commandes,
    COUNT(DISTINCT c.client_id) AS nombre_clients,
    SUM(c.montant_ttc) AS chiffre_affaires,
    AVG(c.montant_ttc) AS panier_moyen,
    SUM(lc.quantite) AS articles_vendus
FROM commandes c
         JOIN lignes_commande lc ON c.id = lc.commande_id
WHERE c.statut != 'annulee'
GROUP BY date_trunc('month', c.date_commande)
ORDER BY mois DESC;

-- Rafraîchir la vue matérialisée des stats mensuelles
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_stats_ventes_mensuelles;

-- Consulter les statistiques
SELECT 
    TO_CHAR(mois, 'YYYY-MM') AS periode,
    nombre_commandes,
    nombre_clients,
    TO_CHAR(chiffre_affaires, '999G999G999D99€') AS ca,
    TO_CHAR(panier_moyen, '999G999D99€') AS panier_moyen,
    articles_vendus
FROM mv_stats_ventes_mensuelles
ORDER BY mois DESC
LIMIT 12;
```
- Stockage réel → requêtes plus rapides.
- Nécessite un **rafraîchissement manuel** (REFRESH).

---

## **5.5 Types de données avancés**

### **5.5.1 JSONB**

PostgreSQL permet de stocker et interroger des données JSON de manière performante.

```sql
-- Rechercher des produits avec des caractéristiques spécifiques
SELECT 
    nom,
    prix,
    caracteristiques
FROM produits
WHERE caracteristiques @> '{"processeur": "M3 Pro"}';

-- Extraire une valeur du JSONB
SELECT 
    nom,
    prix,
    caracteristiques->>'processeur' AS processeur,
    caracteristiques->>'ram' AS ram
FROM produits
WHERE caracteristiques ? 'processeur'
ORDER BY prix DESC;

-- Recherche dans les tags (array)
SELECT nom, prix, tags
FROM produits
WHERE 'apple' = ANY(tags)
ORDER BY prix DESC;
```

### **5.5.2 ARRAY (Tableaux)**

```sql
CREATE TABLE etudiants (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom TEXT,
    notes INTEGER[]
);

INSERT INTO etudiants (nom, notes) VALUES 
('Alice', ARRAY[15, 18, 12, 16]),
('Bob', ARRAY[10, 14, 11]);

-- Recherche dans un tableau
SELECT * FROM etudiants WHERE 18 = ANY(notes);

-- Agrégation
SELECT nom, array_length(notes, 1) AS nb_notes, 
       (SELECT AVG(n) FROM unnest(notes) AS n) AS moyenne
FROM etudiants;
```

### **5.5.3 UUID**

Identifiants universellement uniques, utiles pour les systèmes distribués.

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE commandes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id INTEGER,
    date_commande TIMESTAMP DEFAULT NOW()
);

INSERT INTO commandes (client_id) VALUES (1);
```

### **5.5.4 Types personnalisés (DOMAIN et TYPE)**

#### **DOMAIN**
```sql
CREATE DOMAIN email AS TEXT
CHECK (VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,});

CREATE TABLE utilisateurs (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom TEXT,
    adresse_email email
);
```

#### **TYPE composite**
```sql
CREATE TYPE adresse AS (
    rue TEXT,
    code_postal TEXT,
    ville TEXT
);

CREATE TABLE clients (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom TEXT,
    adresse adresse
);

INSERT INTO clients (nom, adresse) 
VALUES ('Dupont', ROW('12 rue Victor Hugo', '75001', 'Paris'));
```

---
