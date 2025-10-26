# 1. Introduction aux bases de données type documents

## 1.1 Les bases de type documents

### Principe de fonctionnement

Les bases de type documents stockent les données sous forme de documents autonomes :
- Chaque document est une unité complète d'information
- Pas de schéma imposé (schema-less)
- Structure hiérarchique naturelle
- Requêtes directement sur le contenu des documents

### Cas d'usage adaptés

Les bases documentaires excellent dans les contextes suivants :
- **Catalogues produits** : variations nombreuses d'attributs selon les catégories
- **Gestion de contenu** : articles, pages web avec structure variable
- **Profils utilisateurs** : informations hétérogènes selon les types d'utilisateurs
- **Données IoT** : événements avec structures différentes
- **Applications temps réel** : nécessitant une grande flexibilité

### Avantages et inconvénients

**Avantages**
- **Flexibilité** : ajout de champs sans migration
- **Performance en lecture** : données regroupées, moins de jointures
- **Scalabilité** : distribution horizontale native
- **Développement rapide** : structure proche des objets applicatifs

**Inconvénients**
- **Redondance** : duplication de données
- **Cohérence** : garanties ACID limitées (selon la configuration)
- **Transactions complexes** : support limité des transactions multi-documents
- **Requêtes analytiques** : moins performant que le relationnel pour certaines analyses

## 1.2 Présentation de MongoDB

### Histoire et positionnement
- **Création** : 2007 par 10gen (devenu MongoDB Inc.)
- **Open Source** : licence Server Side Public License (SSPL)
- **Leader** : base de données documentaire la plus populaire
- **Versions** : Community (gratuite) et Enterprise (payante)

### Architecture générale

**Composants principaux**
- **mongod** : serveur de base de données
- **mongos** : routeur pour les clusters distribués
- **mongo shell** : interface en ligne de commande
- **MongoDB Compass** : interface graphique
### Écosystème et outils

**Outils officiels**
- **MongoDB Compass** : GUI pour explorer et manipuler les données
- **MongoDB Atlas** : service cloud managé
- **MongoDB Charts** : visualisation de données
- **Realm** : base de données mobile synchronisée

**Drivers**
Disponibles pour tous les langages principaux :
- Node.js, Python, Java, C#, PHP, Go, Ruby, etc.

**Outils communautaires**
- **Mongoose** : ODM pour Node.js (_Object Document Mapper_)
- **ODM** → pour bases **documentaires** (MongoDB)
- **ORM** → pour bases **relationnelles** (SQL)