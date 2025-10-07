# **7 – Programmation SQL et automatisation** {#7-programmation}
## **Objectifs pédagogiques**

- Comprendre et utiliser la logique procédurale avec **PL/pgSQL**
- Créer des **fonctions** et **procédures stockées** efficaces et maintenables
- Automatiser des règles métier via des **triggers** (déclencheurs)
- Mettre en place un **audit** et un **historique des modifications**
- Savoir implémenter un **exemple complet** d'automatisation (mise à jour du stock ou du total de commande)

---
## **7.1. Le langage procédural PL/pgSQL**

### **7.1.1 Définition**

**PL/pgSQL (Procedural Language / PostgreSQL)** est un langage procédural intégré à PostgreSQL.

Il permet d'ajouter de la **logique de programmation** à vos requêtes SQL : déclarations de variables, conditions, boucles, gestion d'exceptions, etc.

Ce langage permet de **centraliser la logique métier dans la base de données**, plutôt que dans l'application.

> PL/pgSQL est activé par défaut dans PostgreSQL 16.

---
### **7.1.2 Structure d'un bloc PL/pgSQL**

Un bloc PL/pgSQL suit cette structure :
```sql
DO $
DECLARE
    -- Déclaration des variables
    compteur INTEGER := 0;
BEGIN
    -- Bloc principal
    RAISE NOTICE 'Compteur = %', compteur;

EXCEPTION
    WHEN others THEN
        RAISE WARNING 'Une erreur est survenue : %', SQLERRM;
END $;
```
#### **Explication**
- DO : exécute un bloc anonyme (sans créer de fonction).
- DECLARE : zone de déclaration des variables.
- BEGIN ... END : bloc principal exécuté.
- EXCEPTION : gestion des erreurs.
- RAISE : permet d'afficher un message (NOTICE, WARNING, EXCEPTION).

---
### **7.1.3 Variables et types**

Les variables peuvent être de **tout type PostgreSQL** (integer, text, date, jsonb, etc.).

- Déclaration : nom type
- **Types** : tous les types SQL/PostgreSQL (int, numeric, text, date, jsonb…), plus **record**, **%ROWTYPE**.
- Assignations : `:= Valeur ou SELECT ... INTO`.
#### **Exemple :**
```sql
DO $
DECLARE
    v_nom TEXT := 'PostgreSQL';
    v_annee INT := 2025;
    v_message TEXT;
BEGIN
    v_message := format('Bienvenue dans %s version %s', v_nom, v_annee);
    RAISE NOTICE '%', v_message;
END $;
```

> 📘 On peut aussi copier la structure d'une table :
> ma_var `:= public.ma_table%ROWTYPE`;

---
### **7.1.4 Conditions et boucles**

#### **Conditions IF / ELSIF / ELSE**
```sql
IF v_annee > 2024 THEN
    RAISE NOTICE 'Version récente';
ELSIF v_annee = 2024 THEN
    RAISE NOTICE 'Version 2024';
ELSE
    RAISE NOTICE 'Ancienne version';
END IF;
```

#### **Boucles**

- **FOR … IN … LOOP**
```sql
FOR i IN 1..5 LOOP
    RAISE NOTICE 'Itération %', i;
END LOOP;
```

- **WHILE**
```sql
WHILE compteur < 3 LOOP
    compteur := compteur + 1;
    RAISE NOTICE 'Compteur = %', compteur;
END LOOP;
```

---

## **7.2. Création de fonctions et procédures**

### **7.2.1 Fonctions (CREATE FUNCTION)**

Les **fonctions** permettent d'exécuter une série d'instructions et de **retourner une valeur**.
Elles sont souvent utilisées pour encapsuler une logique métier réutilisable.
#### **Exemple 1 : fonction simple**
```sql
CREATE OR REPLACE FUNCTION calcul_ttc(prix_ht NUMERIC, taux NUMERIC)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $
BEGIN
    IF taux < 0 THEN
        RAISE EXCEPTION 'Taux négatif interdit';
    END IF;
    RETURN round(prix_ht * (1 + taux), 2);
END $;
```
##### **Appel :**
```sql
SELECT calcul_ttc(100, 0.20);  -- Résultat : 120.00
```

#### **Exemple 2 : fonction retournant un ensemble de lignes**

```sql
CREATE OR REPLACE FUNCTION clients_par_ville(ville TEXT)
RETURNS TABLE(id BIGINT, nom TEXT)
LANGUAGE plpgsql
AS $
BEGIN
    RETURN QUERY
    SELECT id, nom FROM clients WHERE ville = clients_par_ville.ville;
END $;
```
##### **Appel :**
```sql
SELECT * FROM clients_par_ville('Paris');
```

---
### **7.2.2 Procédures (CREATE PROCEDURE)**

Les **procédures** sont similaires aux fonctions, mais elles **ne retournent pas de valeur** et peuvent contenir des **transactions** (COMMIT, ROLLBACK).
#### **Exemple :**
```sql
CREATE OR REPLACE PROCEDURE ajout_client(nom TEXT, ville TEXT)
LANGUAGE plpgsql
AS $
BEGIN
    INSERT INTO clients(nom, ville) VALUES (nom, ville);
    COMMIT;
END $;

CALL ajout_client('Dupont', 'Lyon');
```

---
## **7.3. Les Triggers (Déclencheurs)**
### **7.3.1 Définition**

Un **trigger** est une fonction qui s'exécute **automatiquement** lorsqu'un événement survient sur une table :
- INSERT
- UPDATE
- DELETE

Ils permettent d'**automatiser** des actions :
- Mise à jour automatique d'un total
- Journalisation (audit)
- Contrôle de cohérence

---
### **7.3.2 Types de triggers**

|**Type**|**Moment**|**Niveau**|**Description**|
|---|---|---|---|
|BEFORE|avant l'opération|ligne|permet de modifier ou d'annuler l'opération|
|AFTER|après l'opération|ligne ou commande|utilisé pour actions dérivées|
|INSTEAD OF|sur une vue|ligne|remplace l'action normale|

---
### **7.3.3 Exemple de trigger**

#### **Objectif :**

Normaliser une adresse email avant insertion.
```sql
CREATE OR REPLACE FUNCTION normaliser_email()
RETURNS trigger
LANGUAGE plpgsql
AS $
BEGIN
    NEW.email := lower(trim(NEW.email));
    RETURN NEW;
END $;

CREATE TRIGGER trg_normaliser_email
BEFORE INSERT OR UPDATE ON utilisateurs
FOR EACH ROW
EXECUTE FUNCTION normaliser_email();
```

---
## **7.4. Résumé du module**

| **Thème**      | **Objectif principal**                                           | **Exemple clé**           |
| -------------- | ---------------------------------------------------------------- | ------------------------- |
| **PL/pgSQL**   | Ajouter de la logique procédurale dans SQL                       | Bloc DO $ avec variables |
| **Fonctions**  | Encapsuler une logique réutilisable                              | calcul_ttc()              |
| **Procédures** | Automatiser une suite d'opérations avec transactions sans retour | ajout_client()            |
| **Triggers**   | Réagir automatiquement à des actions sur les tables              | normaliser_email()        |

