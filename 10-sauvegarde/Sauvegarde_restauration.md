# **10 – Sauvegarde, restauration** {#10-sauvegarde}

## **Objectifs pédagogiques**

- Maîtriser les différentes stratégies de sauvegarde PostgreSQL
- Savoir restaurer une base de données dans différents contextes
- Comprendre les mécanismes de maintenance (VACUUM, ANALYZE)
- Mettre en place une réplication pour la haute disponibilité
- Planifier et automatiser les tâches de maintenance

---

## **10.1 Stratégies de sauvegarde**

### **10.1.1 Types de sauvegardes**

| **Type**           | **Méthode**     | **Granularité** | **Temps de restauration** | **Usage**                    |
| ------------------ | --------------- | --------------- | ------------------------- | ---------------------------- |
| Logique            | pg_dump         | Base/Table      | Moyen                     | Migration, export sélectif   |
| Physique (à froid) | Copie fichiers  | Cluster entier  | Rapide                    | Test, développement          |
| Physique (à chaud) | pg_basebackup   | Cluster entier  | Rapide                    | Production, PITR             |
| Continue (WAL)     | Archive WAL     | Transaction     | Très précis               | Point-in-Time Recovery       |

---

## **10.2 Sauvegardes logiques avec pg_dump**

### **10.2.1 Sauvegarder une base complète**

```bash
# Format personnalisé (recommandé)
pg_dump -U postgres -d ma_base -F c -f ma_base_backup.dump

# Format SQL simple
pg_dump -U postgres -d ma_base -f ma_base_backup.sql

# Format directory (parallélisation possible)
pg_dump -U postgres -d ma_base -F d -f ma_base_backup_dir -j 4
```

**Options importantes :**
- `-F c` : format custom (compressé, restauration sélective)
- `-F p` : format plain SQL
- `-F d` : format directory
- `-j 4` : parallélisation (4 jobs)
- `--schema=nom_schema` : schéma spécifique
- `--table=nom_table` : table spécifique
- `--exclude-table=pattern` : exclure des tables

### **10.2.2 Sauvegarder toutes les bases**

```bash
# Sauvegarder toutes les bases + rôles globaux
pg_dumpall -U postgres -f cluster_complet.sql

# Sauvegarder uniquement les rôles et tablespaces
pg_dumpall -U postgres --globals-only -f globals.sql
```

### **10.2.3 Exemples avancés**

```bash
# Sauvegarder uniquement la structure (sans données)
pg_dump -U postgres -d ma_base --schema-only -f structure.sql

# Sauvegarder uniquement les données
pg_dump -U postgres -d ma_base --data-only -f donnees.sql

# Sauvegarder avec compression gzip
pg_dump -U postgres -d ma_base | gzip > ma_base.sql.gz

# Exclure certaines tables volumineuses
pg_dump -U postgres -d ma_base \
  --exclude-table=logs \
  --exclude-table=sessions \
  -f ma_base_sans_logs.dump
```

---

## **10.3 Restauration avec pg_restore**

### **10.3.1 Restauration complète**

```bash
# Restaurer depuis format custom
pg_restore -U postgres -d ma_base_restauree ma_base_backup.dump

# Restaurer en mode parallèle (plus rapide)
pg_restore -U postgres -d ma_base -j 4 ma_base_backup.dump

# Restaurer depuis format SQL
psql -U postgres -d ma_base -f ma_base_backup.sql
```

### **10.3.2 Restauration sélective**

```bash
# Lister le contenu d'une sauvegarde
pg_restore -l ma_base_backup.dump > contenu.txt

# Restaurer uniquement certaines tables
pg_restore -U postgres -d ma_base -t clients -t commandes ma_base_backup.dump

# Restaurer uniquement un schéma
pg_restore -U postgres -d ma_base --schema=public ma_base_backup.dump

# Restaurer en nettoyant d'abord (DROP CASCADE puis CREATE)
pg_restore -U postgres -d ma_base --clean --if-exists ma_base_backup.dump
```

### **10.3.3 Restauration avec modification**

```bash
# Créer une liste de restauration personnalisée
pg_restore -l ma_base_backup.dump > liste_restauration.txt

# Éditer liste_restauration.txt pour commenter ce qu'on ne veut pas
# ; ligne commentée = non restaurée

# Restaurer selon la liste modifiée
pg_restore -U postgres -d ma_base -L liste_restauration.txt ma_base_backup.dump
```

---

## **10.4 Sauvegardes physiques**

### **10.4.1 pg_basebackup**

```bash
# Sauvegarde physique complète
pg_basebackup -U postgres -D /backup/pg_basebackup -F tar -z -P

# Options recommandées pour production
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
- `-D` : répertoire destination
- `-F tar` : format tar (compressible)
- `-z` : compression gzip
- `-P` : afficher la progression
- `-X stream` : inclure les WAL nécessaires
- `--checkpoint=fast` : forcer un checkpoint immédiat

### **10.4.2 Sauvegarde à froid (arrêt du serveur)**

```bash
# Arrêter PostgreSQL
sudo systemctl stop postgresql

# Copier le répertoire de données
sudo cp -r /var/lib/postgresql/16/main /backup/pg_data_$(date +%Y%m%d)

# Redémarrer PostgreSQL
sudo systemctl start postgresql
```

---

## **10.5 Point-in-Time Recovery (PITR)**

### **10.5.1 Configuration de l'archivage WAL**

**Dans postgresql.conf :**
```conf
# Activer l'archivage
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /archives/wal/%f && cp %p /archives/wal/%f'

# Rétention des WAL
wal_keep_size = 1GB
```

### **10.5.2 Procédure de PITR**

```bash
# 1. Restaurer la sauvegarde de base
pg_basebackup -D /var/lib/postgresql/16/recovery -F plain -X none

# 2. Créer recovery.signal
touch /var/lib/postgresql/16/recovery/recovery.signal

# 3. Configurer la restauration (postgresql.conf ou postgresql.auto.conf)
cat >> /var/lib/postgresql/16/recovery/postgresql.auto.conf << EOF
restore_command = 'cp /archives/wal/%f %p'
recovery_target_time = '2025-10-07 14:30:00'
recovery_target_action = 'promote'
EOF

# 4. Démarrer PostgreSQL
sudo systemctl start postgresql
```

### **10.5.3 Exemples de cibles de restauration**

```conf
# Restaurer jusqu'à une date/heure précise
recovery_target_time = '2025-10-07 14:30:00'

# Restaurer jusqu'à un LSN spécifique
recovery_target_lsn = '0/3000000'

# Restaurer jusqu'à une transaction nommée
recovery_target_name = 'avant_suppression_massive'

# Restaurer jusqu'à la transaction X
recovery_target_xid = '12345'

# Action après restauration
recovery_target_action = 'promote'  # Promouvoir en principal
recovery_target_action = 'pause'    # Pause pour inspection
recovery_target_action = 'shutdown' # Arrêter
```

---

## **10.6 Réplication et haute disponibilité**

### **10.6.1 Réplication streaming**

**Configuration du serveur principal (postgresql.conf) :**
```conf
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1GB
hot_standby = on
```

**Créer un utilisateur de réplication :**
```sql
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'mot_de_passe_securise';
```

**Configuration pg_hba.conf (serveur principal) :**
```conf
host    replication     replicator      10.0.0.0/8              scram-sha-256
```

**Configuration du serveur secondaire :**
```bash
# Créer une sauvegarde de base depuis le principal
pg_basebackup -h serveur_principal -U replicator -D /var/lib/postgresql/16/replica -P -R

# Démarrer le serveur replica
sudo systemctl start postgresql
```

Le flag `-R` crée automatiquement le fichier `postgresql.auto.conf` avec :
```conf
primary_conninfo = 'host=serveur_principal port=5432 user=replicator password=xxx'
```

### **10.6.2 Réplication logique**

**Sur le serveur source :**
```sql
-- Créer une publication
CREATE PUBLICATION pub_clients FOR TABLE clients, commandes;

-- Ou pour toutes les tables
CREATE PUBLICATION pub_all FOR ALL TABLES;
```

**Sur le serveur destinataire :**
```sql
-- Créer les tables avec la même structure
-- (peut être fait via pg_dump --schema-only)

-- Créer une souscription
CREATE SUBSCRIPTION sub_clients
CONNECTION 'host=serveur_source port=5432 dbname=ma_base user=replicator password=xxx'
PUBLICATION pub_clients;
```

**Monitoring :**
```sql
-- État de la réplication (source)
SELECT * FROM pg_stat_replication;

-- État de la réplication (cible)
SELECT * FROM pg_stat_subscription;
```

---

## **10.7 Maintenance avec VACUUM et ANALYZE**

### **10.7.1 VACUUM**

VACUUM nettoie les tuples morts (lignes supprimées ou mises à jour) pour libérer de l'espace.

```sql
-- VACUUM simple (ne bloque pas les lectures/écritures)
VACUUM;

-- VACUUM sur une table spécifique
VACUUM clients;

-- VACUUM FULL (réécrit la table, libère l'espace au système)
-- ⚠️ Bloque complètement la table
VACUUM FULL clients;

-- VACUUM avec ANALYZE
VACUUM ANALYZE clients;

-- VACUUM VERBOSE pour voir les détails
VACUUM VERBOSE clients;
```

**Autovacuum (automatique) :**
```conf
# postgresql.conf
autovacuum = on
autovacuum_naptime = 1min
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 50
autovacuum_vacuum_scale_factor = 0.2
autovacuum_analyze_scale_factor = 0.1
```

### **10.7.2 ANALYZE**

ANALYZE met à jour les statistiques utilisées par l'optimiseur de requêtes.

```sql
-- ANALYZE sur toute la base
ANALYZE;

-- ANALYZE sur une table
ANALYZE clients;

-- ANALYZE sur des colonnes spécifiques
ANALYZE clients (nom, prenom);

-- ANALYZE VERBOSE
ANALYZE VERBOSE clients;
```

### **10.7.3 REINDEX**

Reconstruit les index corrompus ou fragmentés.

```sql
-- Réindexer une table
REINDEX TABLE clients;

-- Réindexer un index spécifique
REINDEX INDEX idx_client_nom;

-- Réindexer un schéma complet
REINDEX SCHEMA public;

-- Réindexer toute la base
REINDEX DATABASE ma_base;

-- REINDEX CONCURRENTLY (PostgreSQL 12+, ne bloque pas)
REINDEX INDEX CONCURRENTLY idx_client_nom;
```

### **10.7.4 Monitoring de la maintenance**

```sql
-- Tables nécessitant un VACUUM
SELECT 
    schemaname,
    tablename,
    n_dead_tup,
    n_live_tup,
    round(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100, 2) AS dead_ratio
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC;

-- Dernière exécution d'autovacuum et autoanalyze
SELECT 
    schemaname,
    tablename,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    vacuum_count,
    autovacuum_count
FROM pg_stat_user_tables
ORDER BY last_autovacuum DESC NULLS LAST;

-- Bloat (gonflement) des tables
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS taille_totale,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS taille_table,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS taille_index
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## **10.8 Scripts d'automatisation**

### **10.8.1 Script de sauvegarde quotidienne**

```bash
#!/bin/bash
# backup_daily.sh

# Configuration
DB_NAME="ma_base"
DB_USER="postgres"
BACKUP_DIR="/backup/postgresql"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)

# Créer le répertoire si nécessaire
mkdir -p $BACKUP_DIR

# Effectuer la sauvegarde
echo "Début de la sauvegarde de $DB_NAME à $(date)"
pg_dump -U $DB_USER -d $DB_NAME -F c -f $BACKUP_DIR/${DB_NAME}_${DATE}.dump

# Vérifier le succès
if [ $? -eq 0 ]; then
    echo "Sauvegarde réussie : ${DB_NAME}_${DATE}.dump"
    
    # Compresser la sauvegarde
    gzip $BACKUP_DIR/${DB_NAME}_${DATE}.dump
    
    # Supprimer les sauvegardes anciennes
    find $BACKUP_DIR -name "${DB_NAME}_*.dump.gz" -mtime +$RETENTION_DAYS -delete
    echo "Nettoyage des sauvegardes > $RETENTION_DAYS jours effectué"
else
    echo "ERREUR : La sauvegarde a échoué !" >&2
    exit 1
fi

echo "Fin de la sauvegarde à $(date)"
```

### **10.8.2 Script de maintenance hebdomadaire**

```bash
#!/bin/bash
# maintenance_weekly.sh

DB_NAME="ma_base"
DB_USER="postgres"
LOG_FILE="/var/log/postgresql/maintenance_$(date +%Y%m%d).log"

echo "=== Début de la maintenance $(date) ===" | tee -a $LOG_FILE

# VACUUM ANALYZE complet
echo "Exécution de VACUUM ANALYZE..." | tee -a $LOG_FILE
psql -U $DB_USER -d $DB_NAME -c "VACUUM ANALYZE;" 2>&1 | tee -a $LOG_FILE

# REINDEX sur les index fragmentés
echo "Réindexation des index critiques..." | tee -a $LOG_FILE
psql -U $DB_USER -d $DB_NAME << EOF 2>&1 | tee -a $LOG_FILE
DO \$\$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'REINDEX TABLE ' || quote_ident(r.schemaname) || '.' || quote_ident(r.tablename);
        RAISE NOTICE 'Réindexation de %.% terminée', r.schemaname, r.tablename;
    END LOOP;
END \$\$;
EOF

# Mise à jour des statistiques
echo "Mise à jour des statistiques..." | tee -a $LOG_FILE
psql -U $DB_USER -d $DB_NAME -c "ANALYZE;" 2>&1 | tee -a $LOG_FILE

echo "=== Fin de la maintenance $(date) ===" | tee -a $LOG_FILE
```

### **10.8.3 Planification avec cron**

```bash
# Éditer la crontab
crontab -e

# Ajouter les tâches planifiées
# Sauvegarde quotidienne à 2h du matin
0 2 * * * /usr/local/bin/backup_daily.sh >> /var/log/postgresql/backup.log 2>&1

# Maintenance hebdomadaire le dimanche à 3h du matin
0 3 * * 0 /usr/local/bin/maintenance_weekly.sh

# VACUUM ANALYZE quotidien à 1h du matin
0 1 * * * psql -U postgres -d ma_base -c "VACUUM ANALYZE;" >> /var/log/postgresql/vacuum.log 2>&1
```

---

## **10.9 Surveillance et monitoring**

### **10.9.1 Requêtes de monitoring essentielles**

```sql
-- Taille de la base de données
SELECT 
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS taille
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;

-- Tables les plus volumineuses
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS taille_totale,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS taille_table,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS taille_index
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;

-- Requêtes les plus lentes
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Activité en temps réel
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query_start,
    state_change,
    wait_event_type,
    wait_event,
    left(query, 100) AS query_preview
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Cache hit ratio (doit être > 99%)
SELECT 
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit) as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) * 100 AS cache_hit_ratio
FROM pg_statio_user_tables;

-- Connexions par base
SELECT 
    datname,
    count(*) as connexions
FROM pg_stat_activity
GROUP BY datname
ORDER BY connexions DESC;
```

### **10.9.2 Extension pg_stat_statements**

```sql
-- Activer l'extension (nécessite ajout dans postgresql.conf puis redémarrage)
-- shared_preload_libraries = 'pg_stat_statements'

CREATE EXTENSION pg_stat_statements;

-- Requêtes les plus consommatrices
SELECT 
    query,
    calls,
    total_exec_time / 1000 AS total_time_sec,
    mean_exec_time / 1000 AS mean_time_sec,
    min_exec_time / 1000 AS min_time_sec,
    max_exec_time / 1000 AS max_time_sec,
    stddev_exec_time / 1000 AS stddev_time_sec,
    rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Réinitialiser les statistiques
SELECT pg_stat_statements_reset();
```

---

## **10.10 Gestion des incidents**

### **10.10.1 Corruption de données**

```sql
-- Détecter la corruption avec pg_amcheck (PostgreSQL 14+)
pg_amcheck --all

-- Vérifier l'intégrité d'une table
SELECT * FROM clients LIMIT 0;  -- Erreur si corruption

-- Tenter une réparation
REINDEX TABLE clients;
VACUUM FULL clients;

-- Si irréparable : restaurer depuis sauvegarde
```

### **10.10.2 Espace disque saturé**

```bash
# Identifier les tables volumineuses
psql -U postgres -d ma_base -c "
SELECT 
    schemaname || '.' || tablename AS table_complete,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS taille
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;"

# Libérer de l'espace immédiatement
psql -U postgres -d ma_base << EOF
-- Supprimer les anciennes données
DELETE FROM logs WHERE date < CURRENT_DATE - INTERVAL '30 days';

-- VACUUM FULL pour récupérer l'espace
VACUUM FULL logs;

-- Tronquer les tables temporaires
TRUNCATE TABLE sessions_temporaires;
EOF

# Archiver et supprimer les anciens WAL
pg_archivecleanup /archives/wal $(pg_controldata /var/lib/postgresql/16/main | grep "Latest checkpoint's REDO WAL file" | awk '{print $6}')
```

### **10.10.3 Connexions bloquées**

```sql
-- Identifier les verrous
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Terminer une connexion bloquante
SELECT pg_terminate_backend(pid);

-- Annuler une requête longue
SELECT pg_cancel_backend(pid);
```

---

## **10.11 Bonnes pratiques**

### **Stratégie de sauvegarde recommandée**

1. **Sauvegardes quotidiennes**
    - pg_dump avec format custom
    - Rétention : 7 jours minimum
    - Stockage externe (NAS, S3, etc.)

2. **Sauvegardes physiques hebdomadaires**
    - pg_basebackup complet
    - Rétention : 4 semaines
    - Test de restauration mensuel

3. **Archivage WAL continu**
    - Pour Point-in-Time Recovery
    - Archivage vers stockage sécurisé
    - Rétention alignée avec les sauvegardes de base

4. **Réplication streaming**
    - Serveur standby pour haute disponibilité
    - Monitoring automatique
    - Procédure de bascule documentée

### **Checklist de maintenance**

**Quotidien :**
- ✅ Vérifier les sauvegardes automatiques
- ✅ Surveiller l'espace disque
- ✅ Consulter les logs d'erreur
- ✅ Vérifier le cache hit ratio

**Hebdomadaire :**
- ✅ VACUUM ANALYZE complet
- ✅ Vérifier les tables gonflées (bloat)
- ✅ Analyser les requêtes lentes
- ✅ Nettoyer les anciennes sauvegardes

**Mensuel :**
- ✅ Test de restauration complet
- ✅ REINDEX des tables critiques
- ✅ Audit des permissions
- ✅ Mise à jour des statistiques étendues

**Trimestriel :**
- ✅ Revue de la configuration
- ✅ Planification de capacité
- ✅ Mise à jour PostgreSQL (si disponible)
- ✅ Test du plan de reprise d'activité

---

## **10.12 Outils de monitoring tiers**

### **10.12.1 pgAdmin**
Interface graphique officielle avec monitoring intégré.

### **10.12.2 pg_top**
```bash
# Installation
sudo apt-get install pg_top

# Utilisation
pg_top -d ma_base
```

### **10.12.3 pgBadger**
Analyseur de logs PostgreSQL.

```bash
# Installation
sudo apt-get install pgbadger

# Analyse des logs
pgbadger /var/log/postgresql/postgresql-16-main.log -o rapport.html
```

### **10.12.4 Solutions professionnelles**
- **Prometheus + Grafana** : monitoring temps réel
- **Datadog** : monitoring cloud
- **New Relic** : APM et monitoring
- **pganalyze** : optimisation de requêtes

---

## **10.13 Cas pratique : Plan de reprise d'activité (PRA)**

### **Scénario : Perte du serveur principal**

```bash
# 1. Identifier le problème
# Le serveur principal ne répond plus

# 2. Promouvoir le serveur standby
pg_ctl promote -D /var/lib/postgresql/16/standby

# 3. Vérifier le statut
psql -c "SELECT pg_is_in_recovery();"  # Doit retourner false

# 4. Reconfigurer l'application
# Modifier les chaînes de connexion pour pointer vers le nouveau principal

# 5. Reconstruire un nouveau standby
# Une fois le serveur principal réparé ou remplacé

# Sur le nouveau standby:
pg_basebackup -h nouveau_principal -D /var/lib/postgresql/16/standby -U replicator -P -R

# 6. Documenter l'incident
# - Heure de détection
# - Actions entreprises
# - Temps de bascule
# - Leçons apprises
```

---

## **Résumé du module 10**

| **Aspect**          | **Outil/Méthode**         | **Fréquence recommandée** |
| ------------------- | ------------------------- | ------------------------- |
| Sauvegarde logique  | pg_dump                   | Quotidienne               |
| Sauvegarde physique | pg_basebackup             | Hebdomadaire              |
| Archivage WAL       | archive_command           | Continue                  |
| VACUUM              | Autovacuum / manuel       | Continue / Hebdomadaire   |
| ANALYZE             | Autoanalyze / manuel      | Continue / Hebdomadaire   |
| REINDEX             | REINDEX CONCURRENTLY      | Mensuelle                 |
| Test restauration   | pg_restore                | Mensuelle                 |
| Réplication         | Streaming / Logique       | Continue                  |
| Monitoring          | pg_stat_*, extensions     | Continue                  |

