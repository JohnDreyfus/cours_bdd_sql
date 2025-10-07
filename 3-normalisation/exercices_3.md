### Exercice 1 : Identifier les anomalies
```sql
-- Analyser cette table et identifier les problèmes de normalisation
CREATE TEMP TABLE commandes_denormalisees AS
SELECT 
    co.id,
    cl.nom AS client_nom,
    cl.email AS client_email,
    p.nom AS produit_nom,
    p.prix AS produit_prix,
    lc.quantite
FROM commandes co
JOIN clients cl ON cl.id = co.client_id
JOIN lignes_commande lc ON lc.commande_id = co.id
JOIN produits p ON p.id = lc.produit_id;

-- Lister les anomalies :
-- 1. 
-- 2.
-- 3.
```
