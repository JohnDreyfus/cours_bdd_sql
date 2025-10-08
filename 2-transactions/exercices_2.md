-- EXERCICE 1
-- Créer une transaction qui met à jour le prix de deux produits
-- Objectif : Comprendre BEGIN, COMMIT
/*
Instructions :
1. Démarrer une transaction
2. Augmenter le prix du produit id=8 de 5€
3. Diminuer le prix du produit id=9 de 10€
4. Valider la transaction
5. Vérifier les nouveaux prix
*/

-- À COMPLÉTER :
BEGIN;

-- Votre code ici


COMMIT;

-- Vérification :
SELECT id, nom, prix FROM produits WHERE id IN (8, 9);


-- EXERCICE 2
-- Utiliser ROLLBACK pour annuler une modification
-- Objectif : Comprendre l'annulation de transaction
/*
Instructions :
1. Démarrer une transaction
2. Supprimer tous les avis du client id=1
3. Vérifier combien d'avis ont été supprimés
4. Finalement, annuler la transaction (ROLLBACK)
5. Vérifier que les avis sont toujours présents
*/

-- À COMPLÉTER :
BEGIN;

-- Votre code ici


ROLLBACK;

-- Vérification :
SELECT COUNT(*) FROM avis_produits WHERE client_id = 1;

-- EXERCICE 3
-- Créer une transaction avec SAVEPOINT
-- Objectif : Utiliser les points de sauvegarde
/*
Instructions :
1. Démarrer une transaction
2. Créer un nouveau client (nom: Test, prenom: User, email: test@test.fr, password: 'test123')
3. Créer un SAVEPOINT après l'insertion du client
4. Créer une commande pour ce client
5. Essayer d'ajouter une ligne de commande avec un produit inexistant (id=999)
6. Revenir au SAVEPOINT (le client reste, la commande est annulée)
7. Valider la transaction
*/

-- À COMPLÉTER :
BEGIN;

-- Insérer le client


-- Créer le savepoint


-- Créer la commande


-- Tenter d'ajouter une ligne (va échouer)


-- Revenir au savepoint


COMMIT;

-- Vérification :
SELECT * FROM clients WHERE email = 'test@test.fr';


-- EXERCICE 4
-- Gérer la concurrence avec FOR UPDATE
-- Objectif : Verrouiller des lignes pour modification
/*
Instructions :
1. Démarrer une transaction
2. Sélectionner le produit id=1 avec FOR UPDATE (verrou)
3. Vérifier le stock actuel
4. Si stock > 5, diminuer de 5
5. Afficher le nouveau stock
6. Valider
*/

-- À COMPLÉTER :
BEGIN;

-- Verrouiller et récupérer le produit


-- Mettre à jour si stock suffisant


COMMIT;

-- Vérification :
SELECT id, nom, stock FROM produits WHERE id = 1;


--
