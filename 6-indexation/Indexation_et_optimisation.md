# **6 – Indexation et optimisation** {#6-indexation}

## **Objectifs :**

- Comprendre comment PostgreSQL optimise les requêtes.
- Savoir choisir, créer et analyser les bons index.
- Utiliser les outils d'analyse de performance (EXPLAIN, ANALYZE).
- Identifier et corriger les requêtes lentes.

---
## **6.1 Introduction à l'optimisation dans PostgreSQL**

PostgreSQL dispose d'un **optimiseur de requêtes** très puissant, appelé **Query Planner**, qui choisit automatiquement le **meilleur plan d'exécution** pour chaque requête SQL.
### **Rôle de l'optimiseur**

- Évaluer plusieurs **plans d'exécution possibles**.
- Estimer leur **coût** (CPU, I/O, tri, mémoire, etc.).
- Sélectionner le plan **le plus performant**.

Les index permettent d'**accélérer l'accès aux données**, mais peuvent ralentir les **INSERT**, **UPDATE** et **DELETE** (car l'index doit être mis à jour).

---
## **6.2 Les types d'index dans PostgreSQL**

PostgreSQL offre plusieurs types d'index selon les usages.
Par défaut, les index créés sont de type **B-tree**.

| **Type d'Index** | **Usage principal**          | **Exemple**                     |
| ---------------- | ---------------------------- | ------------------------------- |
| **B-Tree**       | Égalité, ordre               | CREATE INDEX ... ON table(col); |
| **Hash**         | Égalité uniquement           | USING hash                      |
| **GIN**          | Textes, JSONB, tableaux      | USING gin                       |
| **GiST**         | Données spatiales, proximité | USING gist                      |
| **BRIN**         | Grandes tables triées        | USING brin                      |

### **6.2.1. B-tree (par défaut)**

- **Utilisation principale :** égalités et comparaisons d'ordre (=, <, >, BETWEEN, ORDER BY).
- **Structure :** Arbre équilibré (balanced tree).
#### **Exemple :**
```sql
CREATE INDEX idx_client_nom ON clients (nom);
```

Utilisé automatiquement pour :
```sql
SELECT * FROM clients WHERE nom = 'Durand';
```
#### **Avantage :**
- Très performant sur les recherches précises et les tris.

---
### **6.2.2. Hash**
- **Utilisé uniquement pour les comparaisons d'égalité (=)**.
- Plus léger que le B-tree pour ce type de requêtes.
#### **Exemple :**
```sql
CREATE INDEX idx_user_email_hash ON utilisateurs USING hash (email);
```

Utile pour :
```sql
SELECT * FROM utilisateurs WHERE email = 'test@mail.com';
```
#### **Note :**
Les index **Hash** sont moins polyvalents que les **B-tree** et souvent remplacés par ceux-ci dans la pratique.

---
### **6.2.3. GiST (Generalized Search Tree)**
- Index générique pour des **données non ordonnées** : géographiques, textuelles, recherche par proximité.
#### **Exemple :**
Index sur des coordonnées géographiques :
```sql
CREATE INDEX idx_lieu_position ON lieux USING gist (geom);
```

Utilisé avec des extensions comme **PostGIS** pour des requêtes spatiales :
```sql
SELECT * FROM lieux WHERE ST_DWithin(geom, ST_Point(1,1), 1000);
```

---
### **6.2.4. GIN (Generalized Inverted Index)**
- Spécialisé pour **les recherches sur des tableaux**, **du texte** (full-text search), ou des colonnes JSONB.
#### **Exemple :**

Index sur une colonne JSONB :
```sql
CREATE INDEX idx_data_jsonb ON produits USING gin (data);
```

Requête :
```sql
SELECT * FROM produits WHERE data @> '{"couleur": "rouge"}';
```
#### **Exemple pour la recherche plein texte :**
```sql
CREATE INDEX idx_articles_fts ON articles USING gin (to_tsvector('french', contenu));
```

Requête :
```sql
SELECT * FROM articles WHERE to_tsvector('french', contenu) @@ plainto_tsquery('performance');
```

---
### **6.2.5. BRIN (Block Range Index)**

- Index compact pour **de très grandes tables triées naturellement** (dates, identifiants croissants).
- Stocke les **valeurs min/max** par bloc de pages.
#### **Exemple :**
```sql
CREATE INDEX idx_logs_date_brin ON logs USING brin (date_event);
```

Idéal pour les tables volumineuses (millions de lignes) triées chronologiquement.

---
## **6.3. Index avancés**

### **6.3.1. Index sur plusieurs colonnes**

Permet d'indexer une **combinaison** de colonnes.
#### **Exemple :**
```sql
CREATE INDEX idx_commande_client_date ON commandes (id_client, date_commande);
```

Requêtes utilisant le **préfixe de l'index** :
```sql
SELECT * FROM commandes WHERE id_client = 5;
SELECT * FROM commandes WHERE id_client = 5 AND date_commande > '2024-01-01';
```

Mais pas :
```sql
SELECT * FROM commandes WHERE date_commande > '2024-01-01';
```
(l'ordre des colonnes dans l'index compte)

---
### **6.3.2. Index partiels**

Permet de créer un index sur une **partie des données** (filtrée par une condition).
#### **Exemple :**
```sql
CREATE INDEX idx_factures_payees ON factures (date_paiement)
WHERE statut = 'payée';
```

Utilisé uniquement pour :
```sql
SELECT * FROM factures WHERE statut = 'payée' AND date_paiement > '2025-01-01';
```
Avantage : gain de place et de performance sur les grands volumes.

---
### **6.3.3. Index sur expression**

Index basé sur le **résultat d'une expression**.
#### **Exemple :**
```sql
CREATE INDEX idx_nom_minuscule ON clients (lower(nom));
```

Requête correspondante :
```sql
SELECT * FROM clients WHERE lower(nom) = 'dupont';
```

Évite de recalculer lower(nom) à chaque recherche.

---
## **6.4. Analyse de performance avec EXPLAIN**

### **6.4.1. EXPLAIN**

Affiche le **plan d'exécution estimé** d'une requête :

```sql
EXPLAIN SELECT * FROM clients WHERE nom = 'Durand';
```

Exemple de résultat :
```
Index Scan using idx_client_nom on clients  (cost=0.15..8.17 rows=1 width=50)
```

---
### **6.4.2. EXPLAIN ANALYZE**

Exécute réellement la requête et affiche le **plan réel + temps mesuré** :
```sql
EXPLAIN ANALYZE SELECT * FROM clients WHERE nom = 'Durand';
```

Exemple de sortie :
```
Index Scan using idx_client_nom on clients  (cost=0.15..8.17 rows=1 width=50)
(actual time=0.030..0.032 rows=1 loops=1)
```

**Interprétation :**
- cost → estimation du coût par PostgreSQL
- actual time → durée réelle
- rows → nombre de lignes trouvées
- loops → nombre d'exécutions du plan

---
### **6.4.3. Outils utiles**

- ANALYZE : met à jour les statistiques du planificateur.
```sql
ANALYZE clients;
```

- VACUUM : nettoie les tuples morts et améliore les performances.
```sql
VACUUM (ANALYZE);
```

---
## **6.5. Stratégies d'optimisation**

### **Bonnes pratiques :**

1. **Analyser les requêtes lentes** avec EXPLAIN ANALYZE.

2. **Créer des index ciblés**, pas systématiques.

3. **Éviter les fonctions non indexées** dans les clauses WHERE.

4. **Mettre à jour les statistiques** (ANALYZE, VACUUM).

5. **Vérifier les jointures** : préférer les clés numériques aux textes.

6. **Limiter les sous-requêtes imbriquées** si possible.

7. **Utiliser des vues matérialisées** pour des résultats pré-calculés.

