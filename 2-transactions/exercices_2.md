## Configuration initiale

Avant de commencer, assurez-vous d'être sur le bon schéma :

```sql
SET search_path TO ecommerce;

-- Cache hit ratio (doit être > 99%)
SELECT 
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit) as heap_hit,
    ROUND(sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0) * 100, 2) AS cache_hit_ratio
FROM pg_statio_user_tables
WHERE schemaname = 'ecommerce';

-- Bloat des tables (gonflement)
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS taille_totale,
    ROUND(100 * pg_total_relation_size(schemaname||'.'||tablename) / 
          NULLIF(pg_database_size(current_database()), 0), 2) AS pourcent_bdd
FROM pg_tables
WHERE schemaname = 'ecommerce'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## Exercices Module 2 - Transactions

### Exercice 1 : Transfert de stock
```sql
-- Transférer 5 unités du produit 5 vers le produit 6
-- En utilisant une transaction avec SAVEPOINT

-- Votre code ici
```

### Exercice 2 : Gestion d'erreur
```sql
-- Créer une commande avec plusieurs lignes
-- Si une ligne échoue, annuler uniquement cette ligne
-- Garder les lignes valides

-- Votre code ici
```

