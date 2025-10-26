# 2. Le langage Cypher

## Syntaxe de base

### Présentation générale

Cypher est le langage de requêtage déclaratif de Neo4j, conçu spécifiquement pour les graphes. Sa syntaxe utilise des motifs visuels ASCII-art qui représentent naturellement les graphes, rendant les requêtes intuitives et lisibles.

### Notation ASCII-art pour représenter les graphes

**Représentation des nœuds**

Les nœuds sont représentés entre parenthèses :

```cypher
()              // Nœud anonyme
(n)             // Nœud avec variable n
(:Person)       // Nœud avec label Person
(p:Person)      // Nœud Person assigné à la variable p
```

**Représentation des relations**

Les relations utilisent des flèches avec crochets :

```cypher
-->                    // Relation dirigée vers la droite
<--                    // Relation dirigée vers la gauche
-[:KNOWS]->            // Relation typée KNOWS
-[r:KNOWS]->           // Relation KNOWS assignée à r
```

**Exemples de patterns**

```cypher
// Pattern simple
(alice:Person)-[:KNOWS]->(bob:Person)

// Pattern multi-relations
(a:Person)-[:LIVES_IN]->(c:City)

// Relation bidirectionnelle
(a)-[:KNOWS]-(b)  // Match dans les deux directions
```

### Propriétés et labels

**Syntaxe des propriétés**

```cypher
// Propriétés dans un pattern
(p:Person {name: 'Alice', age: 30})

// Accès aux propriétés
MATCH (p:Person)
RETURN p.name, p.age
```

**Types de données supportés**

- Chaînes : `'texte'`
- Nombres : `42`, `3.14`
- Booléens : `true`, `false`
- Listes : `['a', 'b', 'c']`
- Null : `null`

## Opérations CRUD

### CREATE : création de nœuds et relations

**Création de nœuds**

```cypher
// Nœud simple avec propriétés
CREATE (:Person {name: 'Alice', age: 30})

// Création multiple
CREATE 
  (:Person {name: 'Alice', age: 30}),
  (:Person {name: 'Bob', age: 25})
```

**Création de relations**

```cypher
// Entre nœuds existants
MATCH (a:Person {name: 'Alice'}), (b:Person {name: 'Bob'})
CREATE (a)-[:KNOWS {since: 2020}]->(b)

// Création atomique
CREATE (a:Person {name: 'Alice'})-[:KNOWS]->(b:Person {name: 'Bob'})
```

**MERGE : création conditionnelle**

```cypher
// Créer uniquement si n'existe pas
MERGE (p:Person {email: 'alice@example.com'})
ON CREATE SET p.name = 'Alice', p.created = timestamp()
ON MATCH SET p.lastSeen = timestamp()
```

### MATCH : recherche et filtrage

**Recherches de base**

```cypher
// Tous les nœuds d'un type
MATCH (p:Person)
RETURN p.name
LIMIT 10

// Recherche par propriété
MATCH (p:Person {name: 'Alice'})
RETURN p

// Pattern de relation
MATCH (p:Person)-[:KNOWS]->(friend)
RETURN p.name, friend.name
```

**Recherches avec chemins**

```cypher
// Relation de longueur variable
MATCH (a:Person {name: 'Alice'})-[:KNOWS*1..3]->(connections)
RETURN connections.name

// Plus court chemin
MATCH path = shortestPath((a:Person {name: 'Alice'})-[:KNOWS*]-(b:Person {name: 'Bob'}))
RETURN length(path)
```

### WHERE : conditions de filtrage

**Opérateurs de base**

```cypher
// Comparaisons
MATCH (p:Person)
WHERE p.age > 25 AND p.age < 50
RETURN p.name, p.age

// Test de chaînes
MATCH (p:Person)
WHERE p.name STARTS WITH 'A'
RETURN p.name

// Liste
MATCH (p:Person)
WHERE p.name IN ['Alice', 'Bob', 'Charlie']
RETURN p.name

// Test d'existence
MATCH (p:Person)
WHERE p.email IS NOT NULL
RETURN p.name
```

### SET et REMOVE : modification

**Mise à jour de propriétés**

```cypher
// Mise à jour simple
MATCH (p:Person {name: 'Alice'})
SET p.age = 31
RETURN p

// Multiples propriétés
MATCH (p:Person {name: 'Alice'})
SET p.age = 31, p.city = 'Paris'
```

**Gestion des labels**

```cypher
// Ajouter un label
MATCH (p:Person {department: 'IT'})
SET p:Developer

// Supprimer un label
MATCH (p:Person:Inactive)
REMOVE p:Inactive
```

### DELETE : suppression

**Suppression de base**

```cypher
// Supprimer un nœud et ses relations
MATCH (p:Person {name: 'Alice'})
DETACH DELETE p

// Supprimer une relation
MATCH (a:Person {name: 'Alice'})-[r:KNOWS]->(b:Person {name: 'Bob'})
DELETE r
```

## Requêtes avancées

### Agrégations et fonctions

**Fonctions d’agrégation courantes**

```cypher
// COUNT
MATCH (p:Person)
RETURN count(p) AS totalPersons

// Compter les relations
MATCH (p:Person)-[:KNOWS]->(friend)
RETURN p.name, count(friend) AS friendCount
ORDER BY friendCount DESC

// COLLECT : créer une liste
MATCH (p:Person)-[:LIKES]->(m:Movie)
RETURN p.name, collect(m.title) AS likedMovies

// AVG, MIN, MAX
MATCH (p:Person)
RETURN avg(p.age) AS averageAge, min(p.age) AS youngest, max(p.age) AS oldest
```

### Clauses WITH et OPTIONAL MATCH

**WITH : chaînage de requêtes**

```cypher
// Filtrer après agrégation
MATCH (p:Person)-[:KNOWS]->(friend)
WITH p, count(friend) AS friendCount
WHERE friendCount > 5
RETURN p.name, friendCount
```

**OPTIONAL MATCH : jointure externe**

```cypher
// Comme un LEFT JOIN
MATCH (p:Person)
OPTIONAL MATCH (p)-[:KNOWS]->(friend)
RETURN p.name, friend.name
```

### Ordre et limitation

**ORDER BY et LIMIT**

```cypher
// Tri simple
MATCH (p:Person)
RETURN p.name, p.age
ORDER BY p.age DESC

// Tri multiple avec limitation
MATCH (p:Person)
RETURN p.name, p.age
ORDER BY p.age DESC, p.name ASC
LIMIT 10

// Pagination avec SKIP
MATCH (p:Person)
RETURN p.name
ORDER BY p.name
SKIP 20 LIMIT 10
```

### Fonctions utiles

**Fonctions de chaînes**

```cypher
MATCH (p:Person)
RETURN toUpper(p.name), toLower(p.email), size(p.name)
```

**Fonctions de liste**

```cypher
MATCH (p:Person)
RETURN size(p.skills), head(p.skills)
```

**Fonctions temporelles**

```cypher
RETURN date() AS today, datetime() AS now
```
