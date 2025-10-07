# **3 – Normalisation des bases de données** {#3-normalisation}

## **Objectifs pédagogiques**

- Identifier les **anomalies de conception** dans une base de données.
- Comprendre et appliquer les **trois premières formes normales (1NF, 2NF, 3NF)**, ainsi que la **forme normale de Boyce-Codd (BCNF)**.
- Manipuler les notions de **dépendances fonctionnelles** et de **clés candidates**.
- Évaluer les compromis entre **normalisation** et **performance** dans des contextes réels.
- Transformer un **schéma non normalisé** en **modèle relationnel cohérent et optimisé**.

---
## **3.1 – Les anomalies dans les bases de données non normalisées**

Une base mal conçue peut provoquer des **redondances** et des **incohérences** lors des opérations courantes.

### **Exemple de table non normalisée**
```sql
-- NE PAS CRÉER CETTE TABLE - C'est un contre-exemple
CREATE TABLE ventes_non_normalisees (
    id SERIAL PRIMARY KEY,
    client_nom TEXT,
    client_email TEXT,
    produit_nom TEXT,
    produit_prix NUMERIC(10,2),
    quantite INTEGER,
    total NUMERIC(10,2)
);
```

**Problèmes :**
- Redondance : nom et email du client répétés
- Anomalie d'insertion : impossible d'ajouter un client sans vente
- Anomalie de suppression : supprimer une vente supprime les infos client
- Anomalie de mise à jour : changer l'email nécessite de modifier toutes les lignes


---
## **3.2 – Les formes normales**

### **3.2.1 – Première Forme Normale (1NF)**

**Principe :**
- Chaque colonne contient **une seule valeur atomique**.
- Aucune **répétition de groupe de colonnes** (comme produit1, produit2, etc.).
#### **Exemple avant 1NF**
```sql
CREATE TABLE commandes (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_nom TEXT,
    produits TEXT  -- "Chaise, Table, Lampe"
);
```

#### **Exemple après normalisation (1NF)**
```sql
CREATE TABLE commandes (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_nom TEXT
);

CREATE TABLE commande_produits (
    commande_id INTEGER REFERENCES commandes(id) ON DELETE CASCADE,
    produit_nom TEXT,
    PRIMARY KEY (commande_id, produit_nom)
);
```

Chaque produit est maintenant **une ligne distincte**, donc la donnée est atomique.

---
### **3.2.2 – Deuxième Forme Normale (2NF)**

**Principe :**
- Être en **1NF**
- Aucune **dépendance partielle** d'un attribut non clé sur une **partie** de la clé primaire.
  Autrement dit, **chaque colonne dépend de la clé entière**, pas d'une partie.
#### **Exemple avant 2NF**

```sql
CREATE TABLE ligne_commande (
    commande_id INTEGER,
    produit_id INTEGER,
    produit_nom TEXT,
    prix NUMERIC(10,2),
    quantite INTEGER,
    PRIMARY KEY (commande_id, produit_id)
);
```

Ici, produit_nom et prix dépendent seulement de produit_id, pas de la clé (commande_id, produit_id).
#### **Après normalisation (2NF)**

```sql
CREATE TABLE produits (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom TEXT NOT NULL,
    prix NUMERIC(10,2) CHECK (prix >= 0)
);

CREATE TABLE commandes (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_commande DATE DEFAULT CURRENT_DATE
);

CREATE TABLE ligne_commande (
    commande_id INTEGER REFERENCES commandes(id) ON DELETE CASCADE,
    produit_id INTEGER REFERENCES produits(id) ON DELETE RESTRICT,
    quantite INTEGER CHECK (quantite > 0),
    PRIMARY KEY (commande_id, produit_id)
);
```

Chaque donnée dépend **uniquement de la clé complète** de sa table.

---
### **3.2.3 – Troisième Forme Normale (3NF)**

**Principe :**
- Être en **2NF**.
- Aucune **dépendance transitive** (un attribut non clé ne dépend pas d'un autre attribut non clé).
#### **Exemple avant 3NF**
```sql
CREATE TABLE clients (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom TEXT,
    code_postal TEXT,
    ville TEXT
);
```
Ici, ville dépend du code_postal → dépendance **transitive**.
#### **Après normalisation (3NF)**
```sql
CREATE TABLE codes_postaux (
    code_postal TEXT PRIMARY KEY,
    ville TEXT NOT NULL
);

CREATE TABLE clients (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom TEXT,
    code_postal TEXT REFERENCES codes_postaux(code_postal)
);
```
Chaque attribut dépend **directement de la clé primaire**, et non d'un autre attribut.

---
### **3.2.4 – Forme Normale de Boyce-Codd (BCNF)**

**Principe :**
- Extension stricte de la 3NF.
- Pour chaque **dépendance fonctionnelle X → Y**, X doit être une **super-clé**.
#### **Exemple**
Si une salle (num_salle) a un seul **professeur responsable** (prof_id), mais un professeur peut gérer plusieurs salles :

```sql
CREATE TABLE cours (
    prof_id INTEGER,
    num_salle TEXT,
    horaire TEXT,
    PRIMARY KEY (prof_id, num_salle)
);
```
Ici, num_salle → prof_id viole BCNF car num_salle n'est pas une clé.
#### **Correction :**
```sql
CREATE TABLE salles (
    num_salle TEXT PRIMARY KEY,
    prof_id INTEGER NOT NULL
);

CREATE TABLE cours (
    num_salle TEXT REFERENCES salles(num_salle),
    horaire TEXT,
    PRIMARY KEY (num_salle, horaire)
);
```


### 3.3 Vérification de la normalisation

```sql
-- 1NF : Chaque colonne contient une valeur atomique
SELECT id, nom, prenom, email FROM clients LIMIT 5;

-- 2NF : Pas de dépendance partielle
-- Les attributs de lignes_commande dépendent de (commande_id, produit_id)
SELECT * FROM lignes_commande LIMIT 5;

-- 3NF : Pas de dépendance transitive
-- La ville ne dépend plus directement du code_postal dans notre modèle
SELECT * FROM clients LIMIT 5;
```


---
