1. Introduction aux bases de données NoSQL et graphes

### Positionnement des bases graphes

Les bases de données graphes excellent particulièrement lorsque les relations entre les données sont aussi importantes, voire plus importantes, que les données elles-mêmes. Contrairement aux autres familles NoSQL qui optimisent le stockage et l’accès direct aux données, les bases graphes optimisent la traversée et l’analyse des connexions.

## Cas d’usage privilégiés des bases de données graphes

### Réseaux sociaux

Les plateformes sociales représentent l’exemple archétypal des bases graphes. Les utilisateurs (nœuds) sont connectés par des relations d’amitié, de suivi, de mention ou de partage. Les requêtes typiques incluent la recherche d’amis d’amis, la suggestion de connexions, ou l’analyse d’influence.

### Systèmes de recommandation

Les moteurs de recommandation exploitent les relations entre utilisateurs, produits, catégories et comportements. En analysant les chemins dans le graphe (utilisateurs ayant acheté des produits similaires, produits fréquemment associés), il devient possible de générer des recommandations personnalisées avec une grande précision.

### Détection de fraude

Dans le domaine bancaire et assurantiel, les bases graphes permettent d’identifier des schémas frauduleux en détectant des patterns suspects : comptes liés par des adresses IP communes, chaînes de transactions circulaires, réseaux de faux comptes. La capacité à naviguer rapidement dans les relations rend ces analyses temps réel possibles.

### Logistique et routage

L’optimisation de parcours, la gestion de chaînes d’approvisionnement ou la planification de réseaux de transport exploitent naturellement la structure graphe pour calculer les chemins optimaux, identifier les goulets d’étranglement ou analyser la résilience des réseaux.

### Bioinformatique

L’analyse de réseaux de protéines, de voies métaboliques ou d’interactions génétiques nécessite des outils capables de naviguer dans des structures complexes et interconnectées.

## Limites des bases relationnelles pour les données fortement connectées

### Complexité des jointures multiples

Dans un modèle relationnel, les relations entre entités sont représentées par des clés étrangères et nécessitent des jointures SQL. Pour explorer des relations à plusieurs niveaux (amis d’amis d’amis), le nombre de jointures croît exponentiellement, rendant les requêtes complexes à écrire et coûteuses à exécuter.

Exemple : trouver tous les amis à distance 3 dans un réseau social nécessite trois auto-jointures récursives sur une table unique, ce qui devient rapidement impraticable sur de gros volumes.

### Performance dégradée avec la profondeur

Les bases relationnelles sont optimisées pour les opérations ensemblistes et les accès par index. Lorsqu’il faut parcourir un graphe en profondeur, chaque niveau nécessite une nouvelle requête ou jointure. Les performances se dégradent de manière non linéaire avec la profondeur d’exploration, là où une base graphe maintient des performances constantes.

### Rigidité du schéma

Le modèle relationnel impose un schéma fixe défini à l’avance. Ajouter un nouveau type de relation nécessite souvent des modifications structurelles (nouvelles tables, migrations). Les bases graphes offrent une flexibilité naturelle pour faire évoluer le modèle au fil du temps.

### Difficulté de modélisation

Certaines structures de données sont contre-intuitives à modéliser en relationnel. Les hiérarchies variables, les réseaux maillés ou les ontologies nécessitent des stratégies complexes (tables de closure, nested sets, ou EAV) qui compliquent le code et les requêtes.

### Requêtes récursives limitées

Bien que SQL propose des CTE récursives (Common Table Expressions), leur syntaxe reste lourde et leur performance limitée. Elles ne sont pas conçues pour des parcours de graphe complexes avec multiples types de relations et conditions.

## Le modèle de données graphe

### Concepts fondamentaux

**Nœuds (Nodes)**
Les nœuds représentent les entités du domaine métier. Chaque nœud peut posséder des propriétés sous forme de paires clé-valeur et être étiqueté par un ou plusieurs labels qui catégorisent le type d’entité.

Exemple : un nœud Personne avec les propriétés nom, prénom, date_naissance et le label :Personne.

**Relations (Relationships)**
Les relations connectent deux nœuds et possèdent toujours une direction, un type et peuvent avoir des propriétés. Contrairement aux bases relationnelles où les relations sont implicites via les clés étrangères, ici elles sont des entités de première classe.

Exemple : une relation TRAVAILLE_POUR entre un nœud Personne et un nœud Entreprise, avec les propriétés depuis et poste.

**Propriétés (Properties)**
Les propriétés sont des paires clé-valeur attachées aux nœuds ou aux relations. Elles stockent les attributs descriptifs des entités. Les types supportés incluent généralement les chaînes, nombres, booléens, dates et listes.

**Labels**
Les labels permettent de typer et catégoriser les nœuds. Un nœud peut avoir zéro, un ou plusieurs labels. Ils servent à la fois d’outil de modélisation conceptuelle et d’optimisation des requêtes via l’indexation.

### Différence avec le modèle relationnel

**Structure**

- Relationnel : tables avec lignes et colonnes, schéma rigide
- Graphe : nœuds et relations avec propriétés, schéma flexible

**Relations**

- Relationnel : jointures calculées à l’exécution via clés étrangères
- Graphe : relations physiquement stockées et directement traversables

**Requêtage**

- Relationnel : opérations ensemblistes, jointures multiples pour les relations
- Graphe : parcours de graphe, pattern matching, navigation naturelle

**Performance**

- Relationnel : dégradation avec la profondeur des jointures
- Graphe : performance constante indépendamment de la taille du graphe pour les parcours locaux

**Flexibilité**

- Relationnel : modifications de schéma coûteuses
- Graphe : ajout de nouveaux types de nœuds ou relations sans migration

## Exemples concrets de modélisation

### Réseau social

**Modèle relationnel**

```
Table Utilisateurs (id, nom, email, date_inscription)
Table Relations (id, utilisateur_source_id, utilisateur_cible_id, type, date_creation)
```

Requête pour trouver les amis d’amis :

```sql
SELECT u3.*
FROM Utilisateurs u1
JOIN Relations r1 ON u1.id = r1.utilisateur_source_id
JOIN Utilisateurs u2 ON r1.utilisateur_cible_id = u2.id
JOIN Relations r2 ON u2.id = r2.utilisateur_source_id
JOIN Utilisateurs u3 ON r2.utilisateur_cible_id = u3.id
WHERE u1.id = 123 AND r1.type = 'AMI' AND r2.type = 'AMI'
```

**Modèle graphe**

- Nœuds : (:Utilisateur {nom, email, date_inscription})
- Relations : (u1)-[:AMI {depuis}]->(u2)

La même requête devient intuitive et performante avec la notion de pattern.

### Système de recommandation e-commerce

**Nœuds**

- (:Client {nom, email, segment})
- (:Produit {nom, prix, catégorie})
- (:Categorie {nom, description})

**Relations**

- (:Client)-[:A_ACHETE {date, quantite}]->(:Produit)
- (:Client)-[:A_VU {date}]->(:Produit)
- (:Produit)-[:APPARTIENT_A]->(:Categorie)
- (:Produit)-[:SIMILAIRE_A {score}]->(:Produit)

Cette modélisation permet de répondre naturellement à des questions comme : quels produits achètent les clients similaires, ou quels produits sont fréquemment achetés ensemble.

### Index et performances

**Types d’index disponibles**

Index sur propriétés :

- B-tree : recherches exactes et par plage (par défaut)
- Full-text : recherches textuelles avancées (Lucene)
- Composites : plusieurs propriétés simultanément (Enterprise)

Contraintes :

- UNIQUE : unicité d’une propriété par label
- NODE KEY : unicité composite (Enterprise)
- EXISTENCE : propriété obligatoire (Enterprise)

**Bonnes pratiques d’indexation**

- Indexer les propriétés utilisées dans WHERE et MATCH
- Créer des index sur les points d’entrée des requêtes
- Utiliser UNIQUE pour les identifiants métier
- Éviter la sur-indexation (pénalise les écritures)

**Optimisation**

L’optimiseur de requêtes analyse statistiques et cardinalités, choisit les index appropriés et réordonne les opérations. Outils d’analyse :

- EXPLAIN : plan d’exécution sans exécution
- PROFILE : statistiques détaillées après exécution
- USING INDEX : forcer un index spécifique
