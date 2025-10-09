# 2. Les fondamentaux de Redis

## 2.1 Commandes de base

### SET et GET : Opérations élémentaires

**SET** permet de définir une paire clé-valeur

```
SET cle valeur
```

Exemples :

```
SET nom "Dupont"
SET age "30"
SET email "dupont@exemple.com"
```

**GET** permet de récupérer la valeur associée à une clé

```
GET cle
```

Exemples :

```
GET nom
"Dupont"

GET age
"30"

GET cle_inexistante
(nil)
```

### DEL : Suppression de clés

**DEL** supprime une ou plusieurs clés

```
DEL cle1 [cle2 cle3 ...]
```

Exemples :

```
DEL age
(integer) 1

DEL nom email
(integer) 2
```

La commande retourne le nombre de clés effectivement supprimées.

### EXISTS : Vérification d'existence

**EXISTS** vérifie si une ou plusieurs clés existent

```
EXISTS cle [cle2 cle3 ...]
```

Exemples :

```
SET ville "Paris"
OK

EXISTS ville
(integer) 1

EXISTS ville pays
(integer) 1

EXISTS region
(integer) 0
```

La commande retourne le nombre de clés qui existent.

### KEYS : Recherche de clés (à utiliser avec précaution)

**KEYS** recherche les clés correspondant à un pattern

```
KEYS pattern
```

Exemples :

```
SET user:1:name "Alice"
SET user:2:name "Bob"
SET user:3:name "Charlie"

KEYS user:*
1) "user:1:name"
2) "user:2:name"
3) "user:3:name"

KEYS user:*:name
1) "user:1:name"
2) "user:2:name"
3) "user:3:name"
```

**Attention** : KEYS est une opération bloquante qui parcourt toutes les clés. En production, préférer SCAN pour éviter de bloquer Redis.

La commande **SCAN** dans Redis permet de parcourir progressivement les clés d’une base sans tout charger en mémoire (contrairement à KEYS *).

Elle est souvent utilisée pour rechercher des clés correspondant à un motif.
```
SCAN 0 MATCH user:* COUNT 10
```

**Explication :**
- 0 → le **curseur de départ** (Redis renvoie un nouveau curseur à chaque appel).
- MATCH user:* → filtre les clés qui commencent par user:.
- COUNT 10 → demande environ **10 clés** par itération (valeur indicative).

## 2.2 Gestion de l'expiration des clés

### EXPIRE : Définir une durée de vie

**EXPIRE** définit un délai d'expiration en secondes

```
EXPIRE cle secondes
```

Exemples :

```
SET session:abc123 "donnees_session"
EXPIRE session:abc123 3600
(integer) 1
```

La session expirera automatiquement après 1 heure (3600 secondes).

### EXPIREAT : Expiration à une date précise

**EXPIREAT** définit une expiration à un timestamp Unix

```
EXPIREAT cle timestamp
```

Exemple :

```
SET evenement "Conference"
EXPIREAT evenement 1735689600
```

### TTL : Vérifier le temps restant

**TTL** (Time To Live) retourne le nombre de secondes restantes avant expiration

```
TTL cle
```

Exemples :

```
SET code_promo "NOEL2024"
EXPIRE code_promo 7200

TTL code_promo
(integer) 7195

TTL code_promo
(integer) 7189
```

Valeurs de retour :

- Nombre positif : secondes restantes
- -1 : la clé existe mais n'a pas d'expiration
- -2 : la clé n'existe pas

### PERSIST : Supprimer l'expiration

**PERSIST** supprime l'expiration d'une clé

```
PERSIST cle
```

Exemple :

```
SET donnee "importante"
EXPIRE donnee 60

TTL donnee
(integer) 57

PERSIST donnee
(integer) 1

TTL donnee
(integer) -1
```

### SETEX : SET avec expiration atomique

**SETEX** combine SET et EXPIRE en une seule commande atomique

```
SETEX cle secondes valeur
```

Exemple :

```
SETEX token:xyz789 1800 "valeur_token"
```

Équivalent à :

```
SET token:xyz789 "valeur_token"
EXPIRE token:xyz789 1800
```

---

## 2.3 Conventions de nommage des clés (3 min)

### Importance de la nomenclature

Dans Redis, il n'y a pas de notion de base de données ou de tables au sens relationnel. Toutes les clés coexistent dans le même espace de noms. Une convention de nommage claire est donc essentielle.

### Pattern recommandé : notation par deux-points

Format général :

```
objet:identifiant:attribut
```

Exemples :

```
user:1001:name
user:1001:email
user:1001:created_at

product:5432:title
product:5432:price
product:5432:stock

session:abc123def:user_id
session:abc123def:expires_at

cache:api:users:list
cache:api:products:featured
```

### Avantages de cette convention

**Organisation logique** Les clés sont groupées naturellement :

```
KEYS user:1001:*
1) "user:1001:name"
2) "user:1001:email"
3) "user:1001:created_at"
```

**Lisibilité** La structure hiérarchique facilite la compréhension.

**Maintenance** Suppression facile d'un groupe de clés (en développement) :

```
KEYS session:* | xargs redis-cli DEL
```

### Exemples de conventions courantes

**Namespacing par application**

```
app1:user:1001:profile
app2:user:1001:profile
```

**Versioning**

```
cache:v2:products:list
config:v3:app:settings
```

**Environnement**

```
dev:user:1001:session
prod:user:1001:session
```

---

## 2.4 Types de données : Strings

### Présentation

Les strings sont le type de données le plus basique de Redis. Malgré leur nom, elles peuvent contenir n'importe quel type de données binaires (texte, nombres, JSON, images sérialisées) jusqu'à 512 Mo.

### Opérations sur les chaînes de caractères

**APPEND** : Concaténation

```
SET message "Bonjour"
APPEND message " le monde"
(integer) 16

GET message
"Bonjour le monde"
```

**STRLEN** : Longueur de la chaîne

```
STRLEN message
(integer) 16
```

**GETRANGE** : Extraction de sous-chaîne

```
SET texte "Redis est rapide"
GETRANGE texte 0 4
"Redis"

GETRANGE texte 10 15
"rapide"

GETRANGE texte -6 -1
"rapide"
```

**SETRANGE** : Modification partielle

```
SET phrase "Hello World"
SETRANGE phrase 6 "Redis"
(integer) 11

GET phrase
"Hello Redis"
```

### Opérations sur les nombres

**INCR** : Incrémenter de 1

```
SET compteur 0
INCR compteur
(integer) 1

INCR compteur
(integer) 2
```

**DECR** : Décrémenter de 1

```
DECR compteur
(integer) 1
```

**INCRBY** : Incrémenter d'une valeur spécifique

```
INCRBY compteur 10
(integer) 11

INCRBY compteur -5
(integer) 6
```

**DECRBY** : Décrémenter d'une valeur spécifique

```
DECRBY compteur 3
(integer) 3
```

**INCRBYFLOAT** : Incrémenter avec des décimales

```
SET temperature 20.5
INCRBYFLOAT temperature 1.3
"21.8"

INCRBYFLOAT temperature -0.5
"21.3"
```

### Cas d'usage pratiques des strings

**Compteur de vues**

```
INCR page:accueil:vues
INCR page:contact:vues
GET page:accueil:vues
```

**Cache de valeurs simples**

```
SETEX cache:user:1001:nom 3600 "Dupont"
GET cache:user:1001:nom
```

**Stockage de JSON**

```
SET user:1001:profile '{"nom":"Dupont","age":30,"ville":"Paris"}'
GET user:1001:profile
```

**Drapeaux binaires (flags)**

```
SET feature:new_ui:enabled "1"
SET maintenance:mode "0"
```

**Verrous distribués**

```
SET lock:resource:123 "server1" NX EX 30
```

(NX = seulement si la clé n'existe pas, EX = expiration)

### Opérations multiples

**MSET** : Définir plusieurs clés simultanément

```
MSET user:1:nom "Alice" user:1:age "25" user:1:ville "Lyon"
OK
```

**MGET** : Récupérer plusieurs clés simultanément

```
MGET user:1:nom user:1:age user:1:ville
1) "Alice"
2) "25"
3) "Lyon"
```

Ces opérations multiples sont atomiques et plus performantes que plusieurs commandes individuelles.
