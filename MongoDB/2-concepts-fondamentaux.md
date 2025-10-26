# 2. Concepts fondamentaux

## 2.1 Le modèle BASE dans MongoDB

MongoDB ne suit pas le modèle **ACID** classique des bases de données relationnelles, mais plutôt le modèle **BASE**, plus flexible et adapté aux systèmes distribués.

**BASE** signifie :
- **Basically Available** (Fondamentalement disponible)
- **Soft state** (État flexible)
- **Eventual consistency** (Cohérence finale)

### Basically Available (Fondamentalement disponible)

MongoDB garantit que le système reste **disponible** même en cas de panne partielle.

Cela signifie qu’une requête obtiendra toujours une réponse, même si certaines données ne sont pas à jour.

**Exemple :**
Si un nœud du cluster est hors ligne, un autre peut encore répondre aux requêtes de lecture.
```
db.produits.find() // renvoie les données disponibles sur un autre nœud
```

### Soft State (État flexible)

L’état du système peut **changer avec le temps** sans intervention.

Les répliques peuvent ne pas être synchronisées immédiatement, mais elles se mettront à jour automatiquement.

**Exemple :**
Après une écriture sur un nœud principal (primary), les nœuds secondaires (secondary) se mettent à jour après un court délai.
```
// Écriture sur le primary
db.produits.insertOne({ nom: "Clavier", prix: 89.99 })
```
Les autres nœuds répliquent ensuite cette donnée.
### Eventual Consistency (Cohérence finale)

MongoDB assure une **cohérence à terme** : les données deviennent identiques sur tous les nœuds après propagation.

Il peut y avoir un court délai pendant lequel certaines répliques ont des données plus anciennes.

**Exemple :**
Une lecture juste après une écriture peut retourner l’ancienne version du document, mais après quelques secondes, toutes les copies seront cohérentes.


MongoDB privilégie la **disponibilité** et la **résilience** au détriment d’une cohérence immédiate, ce qui le rend particulièrement adapté aux systèmes distribués et aux applications à grande échelle.

## 2.2 Modèle de données

### Documents et collections

**Collections**
- Équivalent d'une table en relationnel
- Conteneur de documents
- Pas de schéma imposé (schemaless)
- Nommage : minuscules, pluriel recommandé (users, products, orders)

**Documents**
- Unité de base de stockage
- Équivalent d'une ligne/enregistrement
- Structure flexible et hiérarchique
- Peut contenir des sous-documents et tableaux

### Format BSON vs JSON

**JSON (JavaScript Object Notation)**
- Format texte lisible par l'humain
- Utilisé pour l'affichage et les échanges
- Types limités : string, number, boolean, null, array, object

```json
{
  "nom": "Dupont",
  "age": 30,
  "actif": true
}
```

**BSON (Binary JSON)**
- Format binaire utilisé en interne par MongoDB
- Plus compact et plus rapide à parcourir
- Types supplémentaires : Date, ObjectId, Binary, Decimal128, etc.

### Types de données supportés
- **String** : chaînes de caractères UTF-8
- **Number** : Integer (32/64 bits), Double, Decimal128
- **Boolean** : true/false
- **Date** : horodatage en millisecondes depuis epoch
- **ObjectId** : identifiant unique sur 12 octets
- **Array** : tableaux de valeurs
- **Object** : documents imbriqués
- **Null** : valeur nulle
- **Binary** : données binaires
- **Regular Expression** : expressions régulières

**Exemple de document complet**
```json
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),
  "nom": "Dupont",
  "prenom": "Jean",
  "age": 30,
  "email": "jean.dupont@example.com",
  "dateInscription": ISODate("2024-01-15T10:30:00Z"),
  "actif": true,
  "tags": ["premium", "newsletter"],
  "adresse": {
    "rue": "123 rue de la Paix",
    "ville": "Paris",
    "codePostal": "75001"
  },
  "score": 98.5
}
```

### Identification des documents : `_id`

**Caractéristiques**
- Champ obligatoire dans chaque document
- Unique au sein d'une collection
- **Immuable** après insertion
- Index automatiquement créé

**ObjectId**
- Valeur par défaut si non fourni
- Format : `ObjectId("507f1f77bcf86cd799439011")`

**Valeurs personnalisées**
```javascript
// _id personnalisé
{
  "_id": "USER001",
  "nom": "Martin"
}

// _id numérique
{
  "_id": 12345,
  "reference": "REF-A"
}
```

---

## 2.3 Différences avec le modèle relationnel

### Comparaison terminologique

| Relationnel          | MongoDB            |
| -------------------- | ------------------ |
| Base de données      | Base de données    |
| Table                | Collection         |
| Ligne/Enregistrement | Document           |
| Colonne              | Champ              |
| Index                | Index              |
| JOIN                 | $lookup, embedding |
| Clé primaire         | _id                |

### Absence de schéma strict

**Relationnel**
- Schéma défini à l'avance (DDL)
- Structure fixe pour toutes les lignes
- Modification = ALTER TABLE

**MongoDB**
- Schéma flexible par défaut
- Documents d'une même collection peuvent avoir des structures différentes
- Ajout de champs sans migration

**Exemple**
```javascript
// Document 1
{
  "_id": 1,
  "nom": "Dupont",
  "email": "dupont@example.com"
}

// Document 2 - structure différente dans la même collection
{
  "_id": 2,
  "nom": "Martin",
  "email": "martin@example.com",
  "telephone": "0612345678",
  "adresse": {
    "ville": "Lyon"
  }
}
```

### Dénormalisation vs normalisation

**Approche relationnelle (normalisée)**
```sql
-- Table utilisateurs
id | nom    | email
1  | Dupont | dupont@example.com

-- Table commandes
id | user_id | total
1  | 1       | 150.00

-- Nécessite JOIN pour récupérer l'ensemble
```

**Approche MongoDB (dénormalisée)**
```javascript
{
  "_id": 1,
  "nom": "Dupont",
  "email": "dupont@example.com",
  "commandes": [
    {
      "numero": "CMD001",
      "total": 150.00,
      "date": ISODate("2024-10-20")
    }
  ]
}
```

**Avantages de la dénormalisation**
- Lecture plus rapide (une seule requête)
- Pas de JOIN coûteux
- Données atomiques

**Inconvénients**
- Duplication potentielle
- Mise à jour plus complexe si données répétées

### Relations entre documents
**1. Embedding (embarqué) - recommandé pour relations 1-to-1 et 1-to-few**
```javascript
{
  "_id": 1,
  "titre": "Introduction à MongoDB",
  "auteur": {
    "nom": "Dupont",
    "email": "dupont@example.com"
  }
}
```

**2. Référencement - recommandé pour relations 1-to-many et many-to-many**
```javascript
// Collection articles
{
  "_id": 1,
  "titre": "Introduction à MongoDB",
  "auteur_id": 42
}

// Collection auteurs
{
  "_id": 42,
  "nom": "Dupont",
  "email": "dupont@example.com"
}
```

---

## 2.4 Bases, collections et documents

### Organisation hiérarchique
```
Serveur MongoDB
│
├── Base de données 1 (ex: blog)
│   ├── Collection articles
│   │   ├── Document 1
│   │   ├── Document 2
│   │   └── Document n
│   ├── Collection utilisateurs
│   └── Collection commentaires
│
└── Base de données 2 (ex: ecommerce)
	├── Collection utilisateurs
    ├── Collection produits
    └── Collection commandes
```

### Conventions de nommage

**Bases de données**
- Minuscules
- Pas d'espaces
- Caractères alphanumériques et underscore
- Exemples : `blog_db`, `ecommerce`, `mon_application`

**Collections**
- Minuscules
- Pluriel recommandé
- Pas d'espaces
- Exemples : `users`, `articles`, `order_items`

**Champs**
- camelCase ou snake_case (cohérence dans le projet)
- Descriptifs et explicites
- Exemples : `firstName` ou `first_name`, `createdAt` ou `created_at`