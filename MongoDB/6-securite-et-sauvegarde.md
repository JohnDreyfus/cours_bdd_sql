# 6. Sécurité et sauvegarde
## 6.1 Validation de schéma

### Définition d'un schéma de validation

**Syntaxe de base :**
```javascript
db.createCollection("utilisateurs", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["nom", "email", "dateInscription"],
         properties: {
            nom: {
               bsonType: "string",
               description: "Nom obligatoire de type string"
            },
            email: {
               bsonType: "string",
               pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
               description: "Email valide obligatoire"
            },
            age: {
               bsonType: "int",
               minimum: 18,
               maximum: 120,
               description: "Age optionnel entre 18 et 120"
            },
            dateInscription: {
               bsonType: "date"
            }
         }
      }
   }
});
```

```javascript
db.getCollectionInfos({ name: "utilisateurs" })
```

```javascript
db.utilisateurs.insertOne({ 
    email: "jean.dupont@example.com",
    nom: "jean dupont",
    dateInscription: new Date()
})
```


### Modification de la validation existante
```javascript
db.runCommand({
   collMod: "utilisateurs",
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["nom", "email"]
      }
   },
   validationLevel: "moderate", // strict | moderate
   validationAction: "error"    // error | warn
});
```

**Options de validation :**
- `validationLevel: "strict"` : validation sur tous les documents (insertion et modification)
- `validationLevel: "moderate"` : validation uniquement sur les documents valides existants
- `validationAction: "error"` : rejette les documents invalides
- `validationAction: "warn"` : enregistre un avertissement mais accepte le document

### Exemple complet avec types avancés
```javascript
db.createCollection("produits", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["nom", "prix", "categorie"],
         properties: {
            nom: {
               bsonType: "string",
               minLength: 3,
               maxLength: 100
            },
            prix: {
               bsonType: "decimal",
               minimum: 0
            },
            categorie: {
               enum: ["Électronique", "Vêtements", "Alimentation", "Mobilier"],
               description: "Catégorie limitée aux valeurs définies"
            },
            tags: {
               bsonType: "array",
               items: {
                  bsonType: "string"
               }
            },
            stock: {
               bsonType: "object",
               required: ["quantite", "entrepot"],
               properties: {
                  quantite: {
                     bsonType: "int",
                     minimum: 0
                  },
                  entrepot: {
                     bsonType: "string"
                  }
               }
            }
         }
      }
   }
});
```

---

## 6.2 Sécurité de base

### Activation de l'authentification

**1. Créer un administrateur :**
```javascript
use admin
db.createUser({
   user: "adminDB",
   pwd: "motDePasseSecurise",
   roles: [{ role: "userAdminAnyDatabase", db: "admin" }]
});
```

**2. Redémarrer MongoDB avec authentification activée :**
```bash
mongod --auth --dbpath /data/db
```

**3. Se connecter avec authentification :**
```bash
mongosh -u adminDB -p motDePasseSecurise --authenticationDatabase admin
```

### Gestion des rôles

**Rôles prédéfinis courants :**
- `read` : lecture seule sur une base
- `readWrite` : lecture et écriture sur une base
- `dbAdmin` : administration d'une base (index, statistiques)
- `userAdmin` : gestion des utilisateurs d'une base
- `dbOwner` : tous les privilèges sur une base
- `readAnyDatabase` : lecture sur toutes les bases
- `readWriteAnyDatabase` : lecture/écriture sur toutes les bases
- `userAdminAnyDatabase` : gestion des utilisateurs sur toutes les bases
- `dbAdminAnyDatabase` : administration de toutes les bases

**Créer un utilisateur avec des rôles spécifiques :**
```javascript
use maBoutique

db.createUser({
   user: "appUser",
   pwd: "password123",
   roles: [
      { role: "readWrite", db: "maBoutique" },
      { role: "read", db: "analytics" }
   ]
});
```

**Créer un utilisateur en lecture seule :**
```javascript
db.createUser({
   user: "lecteur",
   pwd: "password456",
   roles: [{ role: "read", db: "maBoutique" }]
});
```

---

## 6.3 Sauvegarde et restauration

### Sauvegarde avec mongodump

**Sauvegarde complète :**
```bash
mongodump --uri="mongodb://localhost:27017" --out=/backup/mongodb
```

**Sauvegarde d'une base spécifique :**
```bash
mongodump --db=maBoutique --out=/backup/mongodb
```

**Sauvegarde d'une collection spécifique :**
```bash
mongodump --db=maBoutique --collection=produits --out=/backup/mongodb
```

**Sauvegarde avec authentification :**
```bash
mongodump --uri="mongodb://user:password@localhost:27017/maBoutique?authSource=admin" --out=/backup/mongodb
```

**Sauvegarde compressée :**
```bash
mongodump --db=maBoutique --gzip --out=/backup/mongodb
```

### Restauration avec mongorestore

**Restauration complète :**
```bash
mongorestore --uri="mongodb://localhost:27017" /backup/mongodb
```

**Restauration d'une base spécifique :**
```bash
mongorestore --db=maBoutique /backup/mongodb/maBoutique
```

**Restauration d'une collection spécifique :**
```bash
mongorestore --db=maBoutique --collection=produits /backup/mongodb/maBoutique/produits.bson
```

**Restauration avec écrasement des données existantes :**
```bash
mongorestore --drop --db=maBoutique /backup/mongodb/maBoutique
```

**Restauration depuis une archive compressée :**
```bash
mongorestore --gzip --db=maBoutique /backup/mongodb/maBoutique
```