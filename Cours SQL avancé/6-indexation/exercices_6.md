## Exercices Module 6 - Indexation

### Exercice 1 : Analyse de performance
```sql
-- Analyser cette requête et proposer un index adapté
EXPLAIN ANALYZE
SELECT * FROM commandes 
WHERE client_id = 3 
  AND date_commande >= '2025-01-01'
  AND statut = 'livree';

-- Index à créer :
```

### Exercice 2 : Index optimal
```sql
-- Quelle serait le meilleur type d'index pour ces requêtes ?

-- 1. Recherche plein texte dans la description des produits
-- Réponse :

-- 2. Recherche exacte par email client
-- Réponse :

-- 3. Recherche dans les caractéristiques JSONB
-- Réponse :
```
