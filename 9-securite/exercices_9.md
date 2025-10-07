## Exercices Module 9 - Sécurité

### Exercice 1 : Créer une hiérarchie de rôles
```sql
-- Créer 3 rôles : lecteur, gestionnaire, administrateur
-- Avec une hiérarchie de permissions appropriée

-- Votre code ici
```

### Exercice 2 : Politique RLS personnalisée
```sql
-- Créer une politique RLS sur la table avis_produits
-- Un client ne peut voir et modifier que ses propres avis

-- Votre code ici
```

### Exercice 3 : Fonction de connexion sécurisée
```sql
-- Créer une fonction qui vérifie l'authentification
-- et retourne les informations de session

CREATE OR REPLACE FUNCTION authentifier(p_username TEXT, p_password TEXT)
RETURNS TABLE(/* vos colonnes */)
LANGUAGE plpgsql
SECURITY DEFINER
AS $
BEGIN
    -- Votre code
END;
$;
```
