# **1 – Introduction et rappels fondamentaux** {#1-introduction}

## **1. Architecture d'un SGBD relationnel**

Un **Système de Gestion de Base de Données Relationnel (SGBDR)** est un ensemble de logiciels permettant :
- le stockage structuré de données ;
- la manipulation de ces données via le langage **SQL** ;
- la gestion de la concurrence, de la sécurité et de la persistance des données.

Un SGBD relationnel est composé de plusieurs couches logicielles :
```
+--------------------------------------------------+
|  Interface utilisateur / Application (SQL, API)  |
+--------------------------------------------------+
|  Gestionnaire de requêtes (Parser, Optimiseur)   |
+--------------------------------------------------+
|  Gestionnaire de transactions (ACID)             |
+--------------------------------------------------+
|  Moteur de stockage (tables, index, journaux)    |
+--------------------------------------------------+
|  Système de fichiers (OS)                        |
+--------------------------------------------------+
```

---

## **2. Le modèle client-serveur**
### **2.1. Principe général**

Le modèle **client-serveur** sépare :
- le **client** (application, interface graphique, script SQL) ;
- le **serveur** (processus qui héberge et exécute le SGBD).

```
     +-----------+        SQL Query         +-------------+
     |  Client   | -----------------------> |   Serveur   |
     | (psql,    |                         | (PostgreSQL)|
     |  pgAdmin) | <----------------------- |             |
     +-----------+     Résultat/Requêtes    +-------------+
```

### **2.2. Fonctionnement**

1. Le client ouvre une **connexion TCP/IP** vers le serveur (port 5432 pour PostgreSQL, 3306 pour MySQL).
2. Le client envoie des requêtes SQL.
3. Le serveur traite la requête, exécute le plan d'exécution et renvoie le résultat.
4. Le serveur gère la **concurrence** (plusieurs clients simultanés) et la **sécurité** (authentification, droits).

---

## **3. MySQL vs PostgreSQL : comparaison détaillée**

| **Aspect**                  | **MySQL**                                                | **PostgreSQL**                                                          |
| --------------------------- | -------------------------------------------------------- | ----------------------------------------------------------------------- |
| **Type de licence**         | GPL (Oracle)                                             | Open Source (PostgreSQL License, type BSD)                              |
| **Respect du standard SQL** | Partiel                                                  | Très élevé (SQL:2023)                                                   |
| **Types de données**        | Classiques : INT, VARCHAR, TEXT, DATE                    | Très riches : JSONB, ARRAY, UUID, HSTORE, GEOMETRY                      |
| **Contraintes**             | Vérification partielle (CHECK souvent ignoré avant v8.0) | Respect total : CHECK, FOREIGN KEY, UNIQUE, EXCLUDE                     |
| **Extensions SQL**          | Moins d'extensions                                       | Très extensible : fonctions, types, opérateurs, langages PL/pgSQL, etc. |
| **Transactions**            | Engine dépendant (InnoDB requis)                         | Transactions complètes (ACID garanti)                                   |
| **Performances**            | Très rapide en lecture simple, léger                     | Performant pour requêtes complexes, forte charge concurrente            |
| **Réplicas / Clusters**     | Réplication maître-esclave                               | Réplication native, logique ou physique                                 |
| **JSON**                    | JSON non indexable efficacement                          | JSONB indexable et performant                                           |
| **Sécurité**                | Moins stricte par défaut                                 | Gestion fine (rôles, ACL, politiques RLS)                               |

