# Conclusion : Bases de Données Relationnelles vs NoSQL

## 1. Comparaison Structurelle

### 1.1 Modèle de Données

**PostgreSQL (Relationnel)**

- Structure en tables avec lignes et colonnes
- Schéma rigide et prédéfini
- Relations entre tables via clés étrangères
- Normalisation des données pour éviter la redondance

**MongoDB (NoSQL - Document)**

- Structure en collections de documents JSON/BSON
- Schéma flexible et dynamique
- Documents imbriqués et tableaux
- Dénormalisation acceptable pour optimiser les lectures

### 1.2 Exemple Comparatif

**PostgreSQL:**

```sql
-- Table Utilisateurs
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- Table Articles
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    title VARCHAR(200),
    content TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

**MongoDB:**

```javascript
// Collection users avec articles imbriqués
{
    "_id": ObjectId("..."),
    "username": "john_doe",
    "email": "john@example.com",
    "articles": [
        {
            "title": "Mon premier article",
            "content": "Contenu...",
            "created_at": ISODate("2025-01-15")
        }
    ]
}
```

---

## 2. Propriétés ACID vs BASE

### 2.1 PostgreSQL - ACID

- **Atomicity** : Les transactions sont complètes ou annulées
- **Consistency** : Les données respectent toujours les contraintes
- **Isolation** : Les transactions concurrentes ne s'interfèrent pas
- **Durability** : Les données validées sont permanentes

**Exemple de transaction ACID:**

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT; -- Les deux opérations réussissent ou échouent ensemble
```

### 2.2 MongoDB - BASE

- **Basically Available** : Disponibilité même en cas de panne partielle
- **Soft state** : L'état peut changer sans input (réplication)
- **Eventually consistent** : Cohérence finale garantie

**Exemple:**

```javascript
// Peut avoir une latence de cohérence entre réplicas
db.users.updateOne(
    { _id: ObjectId("...") },
    { $set: { status: "active" } }
);
// Le changement se propage graduellement aux nœuds secondaires
```

---

## 3. Cas d'Usage Typiques

### 3.1 Quand Choisir PostgreSQL ?

**Applications bancaires et financières**

- Besoin de transactions ACID strictes
- Cohérence des données critique
- Relations complexes entre entités

**Systèmes ERP et CRM**

- Données structurées et interconnectées
- Requêtes complexes avec JOIN
- Intégrité référentielle importante

**Applications avec schéma stable**

- Structure de données bien définie
- Peu de changements de schéma
- Besoin de contraintes strictes

### 3.2 Quand Choisir MongoDB ?

**Applications web et mobiles modernes**

- Données semi-structurées ou variables
- Évolution rapide du schéma
- Performance en lecture importante

**Big Data et Analytics**

- Volume massif de données
- Scalabilité horizontale nécessaire
- Données non relationnelles

**Catalogues de produits**

- Attributs variables par produit
- Recherche et filtrage rapides
- Stockage de données imbriquées

**Logs et événements**

- Insertion massive de données
- Pas de transactions complexes
- Données orientées temps réel

---

## 4. Architectures Hybrides

### 4.1 Polyglot Persistence

L'approche moderne consiste à utiliser les deux types de bases de données selon les besoins de chaque module.

**Exemple d'architecture e-commerce:**

- **PostgreSQL** : Gestion des commandes, paiements, inventaire
- **MongoDB** : Catalogue produits, avis clients, sessions utilisateurs

### 4.2 Synchronisation de Données

**Techniques courantes:**

- Change Data Capture (CDC)
- Event Sourcing avec Kafka
- ETL/ELT pipelines
- API de synchronisation

---

## 5. Performance et Scalabilité

### Scaling Vertical vs Horizontal

**PostgreSQL:**

- Principalement vertical (augmenter CPU/RAM)
- Réplication lecture possible
- Sharding complexe mais possible

**MongoDB:**

- Horizontal natif (ajout de serveurs)
- Sharding automatique
- Réplication intégrée

---

## 6. Conclusion

Le choix entre PostgreSQL et MongoDB n'est pas binaire. Dans les architectures modernes, les deux coexistent souvent :

**Utilisez PostgreSQL quand:**

- L'intégrité des données est critique
- Vous avez besoin de transactions ACID
- Les relations entre données sont complexes
- Le schéma est stable

**Utilisez MongoDB quand:**

- Vous avez besoin de flexibilité de schéma
- La scalabilité horizontale est requise
- Les performances en lecture sont prioritaires
- Les données sont naturellement hiérarchiques