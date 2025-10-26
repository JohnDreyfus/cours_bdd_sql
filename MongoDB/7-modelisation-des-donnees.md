# **7. Modélisation des données dans MongoDB**

## **1. Introduction**

La modélisation des données dans MongoDB consiste à organiser les documents de manière efficace selon la manière dont ils seront utilisés.

Contrairement aux bases de données relationnelles, MongoDB ne gère pas des tables liées par des clés étrangères, mais des **documents JSON** qui peuvent contenir des sous-documents ou des références.

Le choix entre les deux principales approches dépend du type de relation entre les données, du volume d’informations et des opérations les plus fréquentes (lecture, écriture, mise à jour).

---

## **2. Les deux principales approches**

### **2.1. Modélisation embarquée (Embedded)**

**Principe :**
Les données liées sont stockées dans un même document.
C’est la méthode la plus directe et la plus rapide à lire.

**Exemple :**
```
{
  nom: "Dupont",
  prenom: "Marie",
  adresse: {
    rue: "15 rue de la Paix",
    ville: "Paris",
    codePostal: "75001"
  }
}
```

**Avantages :**
- Toutes les données sont accessibles en une seule requête.
- Les opérations sont atomiques (elles réussissent ou échouent entièrement).
- Très bonnes performances en lecture.

**Inconvénients :**
- Risque de duplication des données si elles sont répétées ailleurs.
- Taille maximale d’un document limitée à 16 Mo.
- Les mises à jour sont plus complexes si plusieurs sous-parties doivent changer séparément.

**Quand l’utiliser :**
- Lorsque les données sont toujours consultées ensemble.
- Lorsque la relation est simple (par exemple : 1 à 1 ou 1 à quelques éléments).
- Lorsque les sous-données ne sont pas trop volumineuses.

---

### **2.2. Modélisation référencée (Referenced)**

**Principe :**
Les données liées sont stockées dans des documents distincts, reliés entre eux par des identifiants (souvent de type ObjectId).

**Exemple :**
```
// Collection utilisateurs
{
  _id: ObjectId("user1"),
  nom: "Dupont",
  prenom: "Marie"
}

// Collection commandes
{
  _id: ObjectId("cmd1"),
  userId: ObjectId("user1"),
  montant: 150.00,
  date: ISODate("2025-01-15")
}
```

**Avantages :**
- Pas de duplication des données.
- Documents plus petits et plus simples à maintenir.
- Plus flexible pour les relations complexes.

**Inconvénients :**
- Nécessite plusieurs requêtes pour obtenir toutes les informations.
- Pas de jointures automatiques (il faut utiliser l’opérateur $lookup).
- Pas de transactions automatiques entre plusieurs documents.

**Quand l’utiliser :**
- Lorsque les données sont souvent consultées séparément.
- Lorsque la relation est de type 1-à-beaucoup ou beaucoup-à-beaucoup.
- Lorsque le volume de données est important ou sujet à des mises à jour fréquentes.

---

## **3. Modèles de relations**

### **3.1. Relation un-à-un (One-to-One)**

**Approche embarquée :**
```
{
  _id: ObjectId("..."),
  username: "jdupont",
  profil: {
    dateNaissance: ISODate("1990-05-20"),
    biographie: "Développeur passionné",
    avatar: "https://..."
  }
}
```

**Approche référencée (si le profil est volumineux) :**
```
// Collection utilisateurs
{
  _id: ObjectId("user1"),
  username: "jdupont",
  profilId: ObjectId("profil1")
}

// Collection profils
{
  _id: ObjectId("profil1"),
  dateNaissance: ISODate("1990-05-20"),
  biographie: "...",
  preferences: { /* nombreuses préférences */ }
}
```

---

### **3.2. Relation un-à-plusieurs (One-to-Many)**

**Approche 1 : Embarquée**
(Utile lorsqu’il y a peu d’éléments)
```
{
  _id: ObjectId("..."),
  titre: "Introduction à MongoDB",
  auteur: "Martin",
  commentaires: [
    {
      auteur: "Sophie",
      texte: "Très bon article",
      date: ISODate("2025-01-10")
    },
    {
      auteur: "Luc",
      texte: "Merci pour les explications",
      date: ISODate("2025-01-11")
    }
  ]
}
```

**Approche 2 : Référencée**
(Recommandée lorsqu’il y a beaucoup d’éléments)
```
// Collection articles
{
  _id: ObjectId("article1"),
  titre: "Introduction à MongoDB",
  auteur: "Martin"
}

// Collection commentaires
{
  _id: ObjectId("comment1"),
  articleId: ObjectId("article1"),
  auteur: "Sophie",
  texte: "Très bon article",
  date: ISODate("2025-01-10")
}
```

---

### **3.3. Relation plusieurs-à-plusieurs (Many-to-Many)**

**Approche 1 : Tableaux d’identifiants dans les deux collections**
```
// Étudiants
{
  _id: ObjectId("etud1"),
  nom: "Dubois",
  coursIds: [ ObjectId("cours1"), ObjectId("cours2") ]
}

// Cours
{
  _id: ObjectId("cours1"),
  titre: "MongoDB Avancé",
  etudiantIds: [ ObjectId("etud1"), ObjectId("etud2") ]
}
```

**Approche 2 : Collection intermédiaire**
```
// Collection inscriptions
{
  _id: ObjectId("..."),
  etudiantId: ObjectId("etud1"),
  coursId: ObjectId("cours1"),
  dateInscription: ISODate("2025-01-05"),
  note: 15
}
```

---

## **4. Exemples de modélisation**

### **4.1. Blog**
- Les commentaires récents sont stockés dans le document de l’article (pour affichage rapide).
- Tous les commentaires complets sont conservés dans une collection séparée (pour la pagination).
### **4.2. Site e-commerce**
- Les commandes contiennent un **snapshot** des produits (nom et prix au moment de l’achat).
- Les produits eux-mêmes sont stockés séparément.
  Cela permet de garder un historique fidèle des commandes même si les produits changent ensuite.
### **4.3. Réseau social**
- Les utilisateurs ont une liste d’amis (identifiants).
- Les publications sont stockées séparément, avec le nom de l’auteur enregistré dans chaque document (pour éviter les jointures).

---

## **5. Anti-patterns à éviter**

|**Mauvaise pratique**|**Conséquence**|**Solution**|
|---|---|---|
|Documents trop volumineux|Dépasse la limite de 16 Mo|Séparer les données en plusieurs collections|
|Trop de petites collections (ex. userSettings)|Complexité inutile|Regrouper dans le document utilisateur|
|Trop de références entre documents|Requêtes lentes|Embarquer les données les plus consultées|
|Duplication non contrôlée|Incohérences possibles|Utiliser des snapshots seulement si nécessaire|
|Absence d’index sur les champs de référence|Recherches lentes|Créer des index (db.collection.createIndex({ userId: 1 }))|

---

## **6. Conclusion**

Le choix entre un modèle embarqué ou référencé dépend principalement :
- de la fréquence de consultation conjointe des données,
- du volume d’informations,
- et du besoin de mise à jour indépendante.

|**Situation**|**Recommandation**|
|---|---|
|Données toujours utilisées ensemble|Modèle embarqué|
|Données volumineuses ou indépendantes|Modèle référencé|
|Relations complexes ou besoin d’historique|Modèle mixte (snapshot + référence)|
