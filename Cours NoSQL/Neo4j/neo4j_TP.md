# 4. Travaux pratiques : Gestion d’un réseau de films

```yml
services:
  neo4j:
    image: neo4j:5.23-community
    container_name: neo4j-tp
    ports:
      - "7474:7474"  # HTTP Browser
      - "7687:7687"  # Bolt protocol
    environment:
      - NEO4J_AUTH=neo4j/password
      - NEO4J_PLUGINS=["apoc"]
      - NEO4J_apoc_export_file_enabled=true
      - NEO4J_apoc_import_file_enabled=true
      - NEO4J_apoc_import_file_use__neo4j__config=true
      - NEO4J_dbms_security_procedures_unrestricted=apoc.*
    volumes:
      - neo4j_data:/data
      - neo4j_logs:/logs
      - neo4j_import:/var/lib/neo4j/import
      - neo4j_plugins:/plugins
    restart: unless-stopped

volumes:
  neo4j_data:
  neo4j_logs:
  neo4j_import:
  neo4j_plugins:
```

### Connexion à Neo4j
1. Ouvrir Neo4j Browser (<http://localhost:7474>)
2. Se connecter avec les identifiants
3. On n’a pas de base  ‘leave empty’

### Nettoyage initial

```cypher
// Supprimer toutes les données existantes
MATCH (n) DETACH DELETE n
```

## Partie 1 : Création du modèle de données

### Étape 1.1 : Créer les films

```cypher
CREATE (:Movie {title: 'The Matrix', released: 1999, tagline: 'Welcome to the Real World'})
CREATE (:Movie {title: 'The Matrix Reloaded', released: 2003, tagline: 'Free your mind'})
CREATE (:Movie {title: 'The Matrix Revolutions', released: 2003, tagline: 'Everything that has a beginning has an end'})
CREATE (:Movie {title: 'Cloud Atlas', released: 2012, tagline: 'Everything is connected'})
CREATE (:Movie {title: 'The Devil\'s Advocate', released: 1997, tagline: 'Evil has its winning ways'})
```

Vérifier la création :

```cypher
MATCH (m:Movie) RETURN m
```

### Étape 1.2 : Créer les personnes

```cypher
CREATE (:Person {name: 'Keanu Reeves', born: 1964})
CREATE (:Person {name: 'Carrie-Anne Moss', born: 1967})
CREATE (:Person {name: 'Laurence Fishburne', born: 1961})
CREATE (:Person {name: 'Hugo Weaving', born: 1960})
CREATE (:Person {name: 'Lana Wachowski', born: 1965})
CREATE (:Person {name: 'Lilly Wachowski', born: 1967})
CREATE (:Person {name: 'Tom Hanks', born: 1956})
CREATE (:Person {name: 'Halle Berry', born: 1966})
CREATE (:Person {name: 'Al Pacino', born: 1940})
CREATE (:Person {name: 'Charlize Theron', born: 1975})
```

Vérifier :

```cypher
MATCH (p:Person) RETURN p.name, p.born ORDER BY p.born
```

### Étape 1.3 : Créer les relations ACTED_IN

```cypher
MATCH (keanu:Person {name: 'Keanu Reeves'})
MATCH (carrie:Person {name: 'Carrie-Anne Moss'})
MATCH (laurence:Person {name: 'Laurence Fishburne'})
MATCH (hugo:Person {name: 'Hugo Weaving'})
MATCH (tom:Person {name: 'Tom Hanks'})
MATCH (halle:Person {name: 'Halle Berry'})
MATCH (al:Person {name: 'Al Pacino'})
MATCH (charlize:Person {name: 'Charlize Theron'})
MATCH (m1:Movie {title: 'The Matrix'})
MATCH (m2:Movie {title: 'The Matrix Reloaded'})
MATCH (m3:Movie {title: 'The Matrix Revolutions'})
MATCH (m4:Movie {title: 'Cloud Atlas'})
MATCH (m5:Movie {title: 'The Devil\'s Advocate'})
CREATE 
  (keanu)-[:ACTED_IN {role: 'Neo'}]->(m1),
  (carrie)-[:ACTED_IN {role: 'Trinity'}]->(m1),
  (laurence)-[:ACTED_IN {role: 'Morpheus'}]->(m1),
  (hugo)-[:ACTED_IN {role: 'Agent Smith'}]->(m1),
  (keanu)-[:ACTED_IN {role: 'Neo'}]->(m2),
  (carrie)-[:ACTED_IN {role: 'Trinity'}]->(m2),
  (laurence)-[:ACTED_IN {role: 'Morpheus'}]->(m2),
  (keanu)-[:ACTED_IN {role: 'Neo'}]->(m3),
  (carrie)-[:ACTED_IN {role: 'Trinity'}]->(m3),
  (tom)-[:ACTED_IN {role: 'Multiple Roles'}]->(m4),
  (halle)-[:ACTED_IN {role: 'Multiple Roles'}]->(m4),
  (hugo)-[:ACTED_IN {role: 'Multiple Roles'}]->(m4),
  (keanu)-[:ACTED_IN {role: 'Kevin Lomax'}]->(m5),
  (al)-[:ACTED_IN {role: 'John Milton'}]->(m5),
  (charlize)-[:ACTED_IN {role: 'Mary Ann Lomax'}]->(m5)
```

### Étape 1.4 : Créer les relations DIRECTED

```cypher
// Wachowski pour Matrix
MATCH (lana:Person {name: 'Lana Wachowski'})
MATCH (m1:Movie {title: 'The Matrix'})
MATCH (m2:Movie {title: 'The Matrix Reloaded'})
MATCH (m3:Movie {title: 'The Matrix Revolutions'})
MATCH (m4:Movie {title: 'Cloud Atlas'})
CREATE (lana)-[:DIRECTED]->(m1)
CREATE (lana)-[:DIRECTED]->(m2)
CREATE (lana)-[:DIRECTED]->(m3)
CREATE (lana)-[:DIRECTED]->(m4)
```

```cypher
MATCH (lilly:Person {name: 'Lilly Wachowski'})
MATCH (m1:Movie {title: 'The Matrix'})
MATCH (m2:Movie {title: 'The Matrix Reloaded'})
MATCH (m3:Movie {title: 'The Matrix Revolutions'})
MATCH (m4:Movie {title: 'Cloud Atlas'})
CREATE (lilly)-[:DIRECTED]->(m1)
CREATE (lilly)-[:DIRECTED]->(m2)
CREATE (lilly)-[:DIRECTED]->(m3)
CREATE (lilly)-[:DIRECTED]->(m4)
```

Visualiser le graphe complet :

```cypher
MATCH (n) RETURN n LIMIT 50
```

## Partie 2 : Requêtes de consultation

### Étape 2.1 : Requêtes simples

- Lister tous les films : title, released

- Trouver tous les acteurs : nom

- Films sortis après 2000 : title, released

### Étape 2.2 : Requêtes avec relations

Acteurs de The Matrix : name, role

Films avec Keanu Reeves : title, released

### Étape 2.3 : Requêtes d’analyse

Compter les films par acteur : nom acteur, nombre

Acteurs ayant joué ensemble :

```cypher
MATCH (a1:Person)-[:ACTED_IN]->(m:Movie)<-[:ACTED_IN]-(a2:Person)
WHERE a1.name = 'Keanu Reeves' AND a1 <> a2
RETURN DISTINCT a2.name, m.title
```

Films réalisés par les Wachowski : title, released

## Partie 3 : Modifications de données

### Étape 3.1 : Ajouter des données

Ajouter un nouveau film 
Ajouter Keanu Reeves au film 
### Étape 3.2 : Mettre à jour des propriétés

Mettre 8 à la note du film Matrix

### Étape 3.3 : Utiliser MERGE

Ajouter un acteur s’il n’existe pas :

```cypher
MERGE (p:Person {name: 'Ian McShane'})
ON CREATE SET p.born = 1942
RETURN p
```

Créer une relation si elle n’existe pas :

```cypher
MATCH (ian:Person {name: 'Ian McShane'}), (movie:Movie {title: 'John Wick'})
MERGE (ian)-[r:ACTED_IN]->(movie)
ON CREATE SET r.role = 'Winston'
RETURN ian, r, movie
```

## Partie 4 : Requêtes avancées

### Étape 4.1 : Recommandations

Recommander des films basés sur les acteurs :

```cypher
// Films recommandés pour les fans de The Matrix
MATCH (m1:Movie {title: 'The Matrix'})<-[:ACTED_IN]-(actor)-[:ACTED_IN]->(m2:Movie)
WHERE m1 <> m2
RETURN m2.title, count(actor) AS commonActors
ORDER BY commonActors DESC
LIMIT 5
```

### Étape 4.2 : Agrégations complexes

Statistiques par décennie :

```cypher
MATCH (m:Movie)
WITH m, m.released / 10 * 10 AS decade
RETURN decade, 
       count(m) AS movieCount, 
       collect(m.title) AS movies
ORDER BY decade
```

Acteurs les plus connectés :

```cypher
MATCH (p:Person)-[:ACTED_IN]->()<-[:ACTED_IN]-(coactor:Person)
WHERE p <> coactor
RETURN p.name, count(DISTINCT coactor) AS coactorCount
ORDER BY coactorCount DESC
LIMIT 5
```
