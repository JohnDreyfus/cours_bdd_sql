
# **10 — Sauvegarde, restauration et maintenance** {#10-sauvegarde}

## **Objectifs pédagogiques**

- Maîtriser les différentes stratégies de sauvegarde PostgreSQL
- Savoir restaurer une base de données dans différents contextes
- Comprendre les mécanismes de maintenance (VACUUM, ANALYZE)
- Mettre en place une réplication pour la haute disponibilité
- Planifier et automatiser les tâches de maintenance

---

## **10.1 Stratégies de sauvegarde**

### **10.1.1 Types de sauvegardes**

PostgreSQL propose plusieurs approches de sauvegarde, chacune adaptée à des besoins spécifiques.

|**Type**|**Méthode**|**Granularité**|**Temps de restauration**|**Usage**|
|---|---|---|---|---|
|Logique|pg_dump|Base/Table|Moyen|Migration, export sélectif|
|Physique (à froid)|Copie fichiers|Cluster entier|Rapide|Test, développement|
|Physique (à chaud)|pg_basebackup|Cluster entier|Rapide|Production, PITR|
|Continue (WAL)|Archive WAL|Transaction|Très précis|Point-in-Time Recovery|

**Choix de la stratégie :**

- **Développement/Test** : sauvegarde logique quotidienne avec pg_dump
- **Production** : combinaison de pg_basebackup hebdomadaire + archivage WAL continu
- **Haute disponibilité** : réplication streaming + sauvegardes régulières

**WAL** signifie **Write-Ahead Log**, ou en français : **Journal des écritures anticipées**.
C’est un **mécanisme de journalisation** qui enregistre **toutes les modifications** effectuées sur la base **avant** qu’elles ne soient réellement écrites sur le disque.
```
Application
   │
   ├──> Transaction : UPDATE, INSERT, DELETE
   │
   ├──> WAL : écrit d'abord ici (séquentiel, rapide)
   │
   └──> Données réelles (appliquées plus tard)
```


---

## **10.2 Sauvegardes logiques avec pg_dump**

Les sauvegardes logiques exportent les données sous forme de commandes SQL ou dans un format propriétaire compressé. Elles sont **indépendantes de la plateforme** et permettent une restauration sélective.

### **10.2.1 Sauvegarder une base complète**

```bash
# Format custom (recommandé) : compressé et restauration sélective possible
pg_dump -U postgres -d ma_base -F c -f ma_base_backup.dump

# Format SQL simple : fichier texte lisible, restauration via psql
pg_dump -U postgres -d ma_base -f ma_base_backup.sql

# Format directory : permet la parallélisation (utile pour grandes bases)
pg_dump -U postgres -d ma_base -F d -f ma_base_backup_dir -j 4
```

**Options importantes :**

- `-F c` : format custom (compressé, restauration sélective)
- `-F p` : format plain SQL (texte)
- `-F d` : format directory (un fichier par table)
- `-j 4` : parallélisation sur 4 cœurs (format directory uniquement)
- `--schema=nom_schema` : sauvegarder un schéma spécifique
- `--table=nom_table` : sauvegarder une table spécifique
- `--exclude-table=pattern` : exclure certaines tables (ex: logs temporaires)

### **10.2.2 Sauvegarder toutes les bases**

```bash
# Sauvegarder toutes les bases + objets globaux (rôles, tablespaces)
pg_dumpall -U postgres -f cluster_complet.sql

# Sauvegarder uniquement les objets globaux
pg_dumpall -U postgres --globals-only -f globals.sql
```

> **Note** : `pg_dumpall` produit uniquement du SQL plain text (pas de format custom).

### **10.2.3 Exemples avancés**

```bash
# Sauvegarder uniquement la structure (DDL, sans données)
pg_dump -U postgres -d ma_base --schema-only -f structure.sql

# Sauvegarder uniquement les données (sans CREATE TABLE)
pg_dump -U postgres -d ma_base --data-only -f donnees.sql

# Sauvegarder avec compression gzip externe
pg_dump -U postgres -d ma_base | gzip > ma_base.sql.gz

# Exclure des tables volumineuses ou temporaires
pg_dump -U postgres -d ma_base \
  --exclude-table=logs \
  --exclude-table=sessions \
  -f ma_base_sans_logs.dump

# Sauvegarder uniquement un schéma spécifique
pg_dump -U postgres -d ma_base -n ecommerce -F c -f ecommerce_backup.dump
```

---

## **10.3 Restauration avec pg_restore**

La restauration dépend du format de sauvegarde utilisé :

- **Format custom/directory** : utiliser `pg_restore`
- **Format SQL** : utiliser `psql`

### **10.3.1 Restauration complète**

```bash
# Restaurer depuis format custom
pg_restore -U postgres -d ma_base_restauree ma_base_backup.dump

# Restaurer en mode parallèle (accélère la restauration)
pg_restore -U postgres -d ma_base -j 4 ma_base_backup.dump

# Restaurer depuis format SQL plain text
psql -U postgres -d ma_base -f ma_base_backup.sql
```

> **Important** : la base de destination doit exister. Créez-la avec `CREATE DATABASE` si nécessaire.

### **10.3.2 Restauration sélective**

Le format custom permet de restaurer uniquement certains objets.

```bash
# Lister le contenu d'une sauvegarde
pg_restore -l ma_base_backup.dump > contenu.txt

# Restaurer uniquement certaines tables
pg_restore -U postgres -d ma_base -t clients -t commandes ma_base_backup.dump

# Restaurer uniquement un schéma
pg_restore -U postgres -d ma_base --schema=public ma_base_backup.dump

# Nettoyer avant restauration (DROP CASCADE puis CREATE)
# ⚠️ Attention : supprime les objets existants !
pg_restore -U postgres -d ma_base --clean --if-exists ma_base_backup.dump
```

### **10.3.3 Restauration avec modification**

Il est possible de personnaliser la restauration en éditant la liste des objets.

```bash
# Créer une liste de restauration
pg_restore -l ma_base_backup.dump > liste_restauration.txt

# Éditer liste_restauration.txt :
# - Commenter (;) les lignes à exclure
# - Réordonner si nécessaire

# Restaurer selon la liste modifiée
pg_restore -U postgres -d ma_base -L liste_restauration.txt ma_base_backup.dump
```

**Cas d'usage :** migrer certaines tables vers une nouvelle base sans tout importer.

---

## **10.4 Sauvegardes physiques**

Les sauvegardes physiques copient directement les fichiers de données du cluster PostgreSQL. Elles sont **plus rapides** mais **dépendantes de la version et de l'architecture**.

### **10.4.1 pg_basebackup (à chaud)**

`pg_basebackup` effectue une copie cohérente du cluster **sans arrêter le serveur**.

```bash
# Sauvegarde physique complète
pg_basebackup -U postgres -D /backup/pg_basebackup -F tar -z -P

# Configuration recommandée pour la production
pg_basebackup \
  -U replication_user \
  -h serveur_principal \
  -D /backup/base_$(date +%Y%m%d) \
  -F tar \
  -z \
  -P \
  -X stream \
  --checkpoint=fast
```

**Options importantes :**

- `-D` : répertoire de destination de la sauvegarde
- `-F tar` : format tar (permet la compression externe)
- `-z` : compression gzip intégrée
- `-P` : affiche la progression
- `-X stream` : inclut les WAL nécessaires à la cohérence
- `--checkpoint=fast` : force un checkpoint immédiat (accélère le démarrage)

**Prérequis :**

- Un utilisateur avec le privilège `REPLICATION`
- Configuration `wal_level = replica` dans `postgresql.conf`
- Autorisation dans `pg_hba.conf` pour les connexions de réplication

### **10.4.2 Sauvegarde à froid (arrêt du serveur)**

Cette méthode simple consiste à copier le répertoire de données après arrêt du serveur.

```bash
# Arrêter PostgreSQL proprement
sudo systemctl stop postgresql

# Copier le répertoire de données
sudo cp -r /var/lib/postgresql/16/main /backup/pg_data_$(date +%Y%m%d)

# Redémarrer PostgreSQL
sudo systemctl start postgresql
```

**Avantages :**

- Simplicité maximale
- Sauvegarde garantie cohérente

**Inconvénients :**

- Nécessite un arrêt du serveur (indisponibilité)
- Sauvegarde volumineuse (pas de compression)

> **Usage recommandé** : environnements de développement ou tests uniquement.

---

## **10.5 Bonnes pratiques de sauvegarde**

### **Stratégie de sauvegarde 3-2-1**

1. **3 copies** des données (production + 2 sauvegardes)
2. **2 supports** différents (disque local + stockage réseau/cloud)
3. **1 copie hors site** (protection contre les sinistres)
