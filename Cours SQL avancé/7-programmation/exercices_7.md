## Exercices Module 7 - Programmation

### Exercice 1 : Fonction de calcul de remise
```sql
-- Créer une fonction qui calcule le prix après remise
-- Paramètres : prix_initial, pourcentage_remise
-- Retour : prix final arrondi à 2 décimales

CREATE OR REPLACE FUNCTION appliquer_remise(/* vos paramètres */)
RETURNS /* votre type */
LANGUAGE plpgsql
AS $$
BEGIN
    -- Votre code
END;
$$;
```
-- Test 1 : Remise de 20% sur 100€
SELECT appliquer_remise(100, 20);


### Exercice 2 : Procédure d'annulation de commande
```sql
-- Créer une procédure qui annule une commande et recrédite le stock

CREATE OR REPLACE PROCEDURE annuler_commande(/* vos paramètres */)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Votre code
END;
$$;
```

### Exercice 3 : Trigger de validation
```sql
-- Créer un trigger qui vérifie que le stock est positif avant insertion dans lignes_commande

CREATE OR REPLACE FUNCTION verifier_stock_avant_commande()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Votre code
END;
$$;

-- Créer le trigger
```

### Exercice 4 : Fonction de statistiques client
```sql
-- Créer une fonction qui retourne les statistiques d'un client
-- (nombre de commandes, total dépensé, panier moyen)

CREATE OR REPLACE FUNCTION stats_client(p_client_id INTEGER)
RETURNS TABLE(/* vos colonnes */)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Votre code
END;
$$;
```




