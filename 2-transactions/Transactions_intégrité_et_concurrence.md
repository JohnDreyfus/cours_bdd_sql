# **2 – Transactions, intégrité et concurrence** {#2-transactions}

## **Objectifs**
- Comprendre les mécanismes de cohérence et de concurrence dans PostgreSQL
- Maîtriser le fonctionnement des transactions SQL
- Savoir gérer les conflits, les verrous et éviter les anomalies de concurrence

---

## **2.1 Introduction : Pourquoi les transactions ?**

Une **transaction** est une suite d'opérations SQL exécutées comme une unité logique de travail.
Toutes les opérations d'une transaction doivent **réussir ensemble** ou **échouer ensemble**.

> 💡 Exemple : Lors d'un virement bancaire :
- > On débite le compte A de 100 €
- > On crédite le compte B de 100 €

> Ces deux opérations doivent être atomiques : si l'une échoue, l'autre doit être annulée.

---

## **2.2 Principe ACID**

Les transactions respectent quatre propriétés fondamentales connues sous l'acronyme **ACID** :

|**Propriété**|**Définition**|**Exemple**|
|---|---|---|
|**A**tomacité|Toutes les opérations réussissent ou échouent ensemble.|Si une requête échoue, la transaction est annulée.|
|**C**ohérence|Le passage d'un état valide à un autre respecte les contraintes.|Aucune contrainte CHECK, FOREIGN KEY ne doit être violée.|
|**I**solation|Les transactions concurrentes n'interfèrent pas entre elles.|Deux utilisateurs modifiant la même table ne se gênent pas.|
|**D**urabilité|Une fois validée (COMMIT), la transaction est enregistrée de façon permanente.|Même après un redémarrage, les données restent sauvegardées.|

---

## **2.3 Commandes de gestion de transactions**

PostgreSQL gère les transactions explicitement ou implicitement.
Par défaut, chaque requête est une transaction autonome ("autocommit").

### **Démarrer et valider une transaction**
```sql
BEGIN;

-- Débiter le stock du produit 1
UPDATE produits SET stock = stock - 2 WHERE id = 1;

-- Créditer le stock du produit 2 (transfert)
UPDATE produits SET stock = stock + 2 WHERE id = 2;

COMMIT;
```

### **Annuler une transaction**
```sql
BEGIN;

-- Débiter le stock du produit 100
UPDATE produits SET stock = stock - 100 WHERE id = 1;

-- Créditer le stock du produit 100 (transfert)
UPDATE produits SET stock = stock + 100 WHERE id = 2;

ROLLBACK;  -- Annule tout
```

### **Utiliser un SAVEPOINT**

Un **savepoint** permet de sauvegarder un état intermédiaire et d'y revenir sans tout annuler.
```sql
BEGIN;

-- Créer une nouvelle commande
INSERT INTO commandes (client_id, statut) 
VALUES (1, 'en_attente');

SAVEPOINT avant_lignes;

-- Ajouter des lignes de commande
INSERT INTO lignes_commande (commande_id, produit_id, quantite, prix_unitaire)
VALUES (LASTVAL(), 1, 1, 2499.00);

-- Erreur : produit inexistant
INSERT INTO lignes_commande (commande_id, produit_id, quantite, prix_unitaire)
VALUES (LASTVAL(), 999, 1, 100.00);  -- Erreur

ROLLBACK TO avant_lignes;  -- Retour avant l'erreur
COMMIT;                     -- Valide la commande créée
```

---

## **2.4 Simulation de concurrence et anomalies**

**Terminal A :**
```sql
BEGIN;
SELECT stock FROM produits WHERE id = 4;  -- retourne 25
UPDATE produits SET stock = stock - 2 WHERE id = 4;
-- Ne pas faire COMMIT tout de suite
```

**Terminal B (simultané) :**
```sql
BEGIN;
SELECT stock FROM produits WHERE id = 4;  -- 25 (READ COMMITTED)
UPDATE produits SET stock = stock - 3 WHERE id = 4;
-- Bloqué jusqu'au COMMIT de la transaction A
```

**Terminal A :**
```sql
COMMIT;  -- Transaction B reprend et s'exécute
```

**Terminal B :**
```sql
COMMIT;  -- Stock final = 20 (25 - 2 - 3)
```

#### **Résultat**
- Après le COMMIT de A, B reprend l'exécution.
- Le stock final est **20** (25 - 2 - 3).
- Si une transaction échoue, un **ROLLBACK** garantit la cohérence.

---

## 2.5 Verrouillage explicite

```sql
BEGIN;

-- Verrouiller une ligne pour modification
SELECT * FROM produits WHERE id = 1 FOR UPDATE;

-- Modifier le prix
UPDATE produits SET prix = 2399.00 WHERE id = 1;

COMMIT;
```

---
## **Résumé **

|**Concept**|**Commande / Mécanisme**|**Objectif**|
|---|---|---|
|**Transaction**|BEGIN, COMMIT, ROLLBACK|Grouper plusieurs requêtes|
|**Point de reprise**|SAVEPOINT, ROLLBACK TO|Annuler partiellement|
|**Isolation**|SET TRANSACTION ISOLATION LEVEL ...|Gérer la visibilité concurrente|
|**Verrouillage**|SELECT ... FOR UPDATE, LOCK TABLE|Empêcher les conflits|
|**Détection de blocage**|Automatique par PostgreSQL|Évite les deadlocks|
|**Cohérence ACID**|Mécanisme interne|Garantit l'intégrité des données|


---
