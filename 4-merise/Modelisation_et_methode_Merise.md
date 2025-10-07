# **4 – Modélisation et méthode Merise** {#4-merise}
## **Objectifs pédagogiques**

À la fin de ce module, l'étudiant sera capable de :
- Comprendre les principes de la méthode **Merise** pour la conception de bases de données.
- Identifier et modéliser les **entités**, **associations**, **cardinalités** et **attributs** d'un système d'information.
- Transformer un **MCD** (Modèle Conceptuel de Données) en **MLD** (Modèle Logique de Données), puis en **MPD** (Modèle Physique de Données) conforme à **PostgreSQL 16**.
- Optimiser la structure relationnelle en respectant les bonnes pratiques de **performance**, **intégrité**, et **maintenabilité**.
- Implémenter la base dans PostgreSQL à partir d'un cas concret.

---

## **1. Présentation de la méthode Merise**

### **1.1 Qu'est-ce que Merise ?**

**Merise** est une méthode d'analyse, de conception et de gestion de projets informatiques, née dans les années 1980.

Elle repose sur une approche **structurée** qui sépare les **données**, les **traitements** et les **flux** d'un système d'information.
### **1.2 Les niveaux d'abstraction**

Merise distingue **trois niveaux** :

| **Niveau**     | **Objectif**                                      | **Exemple** |
| -------------- | ------------------------------------------------- | ----------- |
| **Conceptuel** | Représenter la réalité sans contrainte technique  | MCD         |
| **Logique**    | Adapter le modèle à un type de SGBD relationnel   | MLD         |
| **Physique**   | Définir la structure concrète dans le SGBD choisi | MPD         |
### **1.3 Avantages**

- Modélisation claire et hiérarchisée.
- Réduction des anomalies et incohérences.
- Passage progressif du besoin fonctionnel à la base de données réelle.

---
## **2. Le MCD (Modèle Conceptuel de Données)**
### **2.1 Les entités**

Une **entité** représente un objet du monde réel que l'on souhaite stocker dans la base.

**Exemple :**
```
LIVRE, AUTEUR, ADHERENT, EMPRUNT
```

Chaque entité possède :
- Un **identifiant** (clé unique logique, ex. id_livre)
- Des **attributs** (propriétés descriptives, ex. titre, date_publication)

**Notation :**
```
LIVRE (id_livre, titre, date_publication, genre)
```

### **2.2 Les associations**

Une **association** représente le lien entre deux ou plusieurs entités.

**Exemple :**
```
AUTEUR écrit LIVRE
ADHERENT emprunte LIVRE
```

### **2.3 Les cardinalités**

Les **cardinalités** indiquent le **nombre minimum et maximum** de participations d'une entité dans une association.

|**Exemple**|**Lecture**|
|---|---|
|(1,1)|exactement un|
|(0,N)|aucun ou plusieurs|
|(1,N)|au moins un|

**Exemple visuel (notation textuelle) :**
```
AUTEUR (1,N) – écrit – (1,1) LIVRE
```

Cela signifie : Un auteur peut écrire plusieurs livres, mais chaque livre a un seul auteur.
### **2.4 Les attributs d'association**

Certains attributs appartiennent à l'association, et non aux entités.

**Exemple :**
```
ADHERENT – emprunte – LIVRE
→ date_emprunt, date_retour
```

---
## **3. Du MCD au MLD (Modèle Logique de Données)**
### **3.1 Principe**

Le **MLD** traduit le modèle conceptuel en un **ensemble de relations** (tables) adaptées au modèle **relationnel**.

Les règles de passage :
1. **Chaque entité** devient une **table**.
2. **Chaque association** :
    - devient une **table à part entière** si elle relie plusieurs entités en **N:N** ;
    - se traduit par une **clé étrangère** si elle relie **1:N**.
3. Les **attributs d'association** deviennent des **colonnes** dans la table correspondante.
### **3.2 Exemple de transformation**

MCD :
```
ADHERENT – emprunte – LIVRE
```

Cardinalités :
```
ADHERENT (1,N) – (0,N) LIVRE
```

MLD :
```
ADHERENT(id_adherent, nom, prenom, email)
LIVRE(id_livre, titre, genre)
EMPRUNT(id_adherent, id_livre, date_emprunt, date_retour)
```

- EMPRUNT devient une table associative avec **deux clés étrangères** :
    - id_adherent → ADHERENT(id_adherent)
    - id_livre → LIVRE(id_livre)

- Clé primaire composée : (id_adherent, id_livre, date_emprunt)


---
## **4. Du MLD au MPD (Modèle Physique de Données)**
### **4.1 Traduction en SQL**
#### **Table adherent**
```sql
CREATE TABLE adherent (
  id_adherent INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nom TEXT NOT NULL,
  prenom TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL
);
```

#### **Table livre**
```sql
CREATE TABLE livre (
  id_livre INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  titre TEXT NOT NULL,
  genre TEXT,
  date_publication DATE
);
```

#### **Table emprunt**
```sql
CREATE TABLE emprunt (
  id_adherent INTEGER NOT NULL,
  id_livre INTEGER NOT NULL,
  date_emprunt DATE NOT NULL DEFAULT CURRENT_DATE,
  date_retour DATE,
  CONSTRAINT pk_emprunt PRIMARY KEY (id_adherent, id_livre, date_emprunt),
  CONSTRAINT fk_emprunt_adherent FOREIGN KEY (id_adherent)
    REFERENCES adherent (id_adherent) ON DELETE CASCADE,
  CONSTRAINT fk_emprunt_livre FOREIGN KEY (id_livre)
    REFERENCES livre (id_livre) ON DELETE CASCADE,
  CONSTRAINT chk_date_retour CHECK (date_retour IS NULL OR date_retour >= date_emprunt)
);
```

**Bonnes pratiques PostgreSQL 16 :**
- Utilisation de GENERATED ALWAYS AS IDENTITY (remplace SERIAL).
- Contraintes nommées (pk_, fk_, chk_).
- Contraintes de cohérence (CHECK) et d'intégrité référentielle (FOREIGN KEY).
