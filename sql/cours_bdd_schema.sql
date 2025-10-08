-- Nettoyage initial
DROP SCHEMA IF EXISTS ecommerce CASCADE;
CREATE SCHEMA ecommerce;
SET search_path TO ecommerce;

-- ============================================================================
-- EXTENSIONS NÉCESSAIRES
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm; -- Pour les recherches textuelles

-- ============================================================================
-- TYPES PERSONNALISÉS
-- ============================================================================

-- Type pour les adresses
CREATE TYPE adresse_type AS (
    rue TEXT,
    code_postal TEXT,
    ville TEXT,
    pays TEXT
    );

-- Domaine pour les emails
CREATE DOMAIN email AS TEXT
    CHECK (VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Domaine pour les prix (toujours positifs)
CREATE DOMAIN prix_positif AS NUMERIC(10,2)
    CHECK (VALUE >= 0);

-- ============================================================================
-- TABLES PRINCIPALES
-- ============================================================================

-- Table des catégories (hiérarchique)
CREATE TABLE categories (
                            id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                            nom TEXT NOT NULL UNIQUE,
                            parent_id INTEGER REFERENCES categories(id) ON DELETE CASCADE,
                            description TEXT,
                            actif BOOLEAN DEFAULT true,
                            created_at TIMESTAMP DEFAULT NOW()
);

-- Table des fournisseurs
CREATE TABLE fournisseurs (
                              id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                              nom TEXT NOT NULL,
                              email email,
                              telephone TEXT,
                              adresse adresse_type,
                              pays TEXT DEFAULT 'France',
                              actif BOOLEAN DEFAULT true,
                              created_at TIMESTAMP DEFAULT NOW()
);

-- Table des produits
CREATE TABLE produits (
                          id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                          reference UUID DEFAULT uuid_generate_v4() UNIQUE,
                          nom TEXT NOT NULL,
                          description TEXT,
                          categorie_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
                          fournisseur_id INTEGER REFERENCES fournisseurs(id) ON DELETE SET NULL,
                          prix prix_positif NOT NULL,
                          stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
                          stock_minimum INTEGER DEFAULT 10,
                          caracteristiques JSONB,
                          tags TEXT[],
                          actif BOOLEAN DEFAULT true,
                          created_at TIMESTAMP DEFAULT NOW(),
                          updated_at TIMESTAMP DEFAULT NOW()
);

-- Table des clients
CREATE TABLE clients (
                         id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
                         nom TEXT NOT NULL,
                         prenom TEXT NOT NULL,
                         email email UNIQUE NOT NULL,
                         password_hash TEXT NOT NULL,
                         telephone TEXT,
                         date_naissance DATE,
                         adresse_livraison adresse_type,
                         adresse_facturation adresse_type,
                         newsletter BOOLEAN DEFAULT false,
                         points_fidelite INTEGER DEFAULT 0,
                         actif BOOLEAN DEFAULT true,
                         created_at TIMESTAMP DEFAULT NOW(),
                         updated_at TIMESTAMP DEFAULT NOW()
);

-- Table des utilisateurs (pour la sécurité et RLS)
CREATE TABLE utilisateurs (
                              id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                              username TEXT UNIQUE NOT NULL,
                              password_hash TEXT NOT NULL,
                              client_id INTEGER REFERENCES clients(id) ON DELETE CASCADE,
                              role TEXT NOT NULL CHECK (role IN ('client', 'vendeur', 'admin')) DEFAULT 'client',
                              derniere_connexion TIMESTAMP,
                              actif BOOLEAN DEFAULT true,
                              created_at TIMESTAMP DEFAULT NOW()
);

-- Table des commandes
CREATE TABLE commandes (
                           id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                           numero TEXT UNIQUE NOT NULL,
                           client_id INTEGER NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
                           date_commande TIMESTAMP DEFAULT NOW(),
                           statut TEXT CHECK (statut IN ('en_attente', 'confirmee', 'expediee', 'livree', 'annulee')) DEFAULT 'en_attente',
                           montant_ht NUMERIC(10,2) DEFAULT 0,
                           montant_tva NUMERIC(10,2) DEFAULT 0,
                           montant_ttc NUMERIC(10,2) DEFAULT 0,
                           adresse_livraison adresse_type,
                           notes TEXT,
                           created_at TIMESTAMP DEFAULT NOW(),
                           updated_at TIMESTAMP DEFAULT NOW()
);

-- Table des lignes de commande
CREATE TABLE lignes_commande (
                                 id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                 commande_id INTEGER NOT NULL REFERENCES commandes(id) ON DELETE CASCADE,
                                 produit_id INTEGER NOT NULL REFERENCES produits(id) ON DELETE RESTRICT,
                                 quantite INTEGER NOT NULL CHECK (quantite > 0),
                                 prix_unitaire prix_positif NOT NULL,
                                 reduction_pourcent NUMERIC(5,2) DEFAULT 0 CHECK (reduction_pourcent BETWEEN 0 AND 100),
                                 montant_ligne NUMERIC(10,2) GENERATED ALWAYS AS (
                                     quantite * prix_unitaire * (1 - reduction_pourcent / 100)
                                     ) STORED,
                                 created_at TIMESTAMP DEFAULT NOW()
);

-- Table des avis produits
CREATE TABLE avis_produits (
                               id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                               produit_id INTEGER NOT NULL REFERENCES produits(id) ON DELETE CASCADE,
                               client_id INTEGER NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
                               note INTEGER NOT NULL CHECK (note BETWEEN 1 AND 5),
                               commentaire TEXT,
                               date_avis TIMESTAMP DEFAULT NOW(),
                               verifie BOOLEAN DEFAULT false,
                               UNIQUE(produit_id, client_id)
);

-- Table des promotions
CREATE TABLE promotions (
                            id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                            code TEXT UNIQUE NOT NULL,
                            description TEXT,
                            type TEXT CHECK (type IN ('pourcentage', 'montant_fixe', 'livraison_gratuite')) NOT NULL,
                            valeur NUMERIC(10,2) NOT NULL,
                            date_debut DATE NOT NULL,
                            date_fin DATE NOT NULL,
                            utilisation_max INTEGER DEFAULT NULL,
                            utilisation_actuelle INTEGER DEFAULT 0,
                            actif BOOLEAN DEFAULT true,
                            created_at TIMESTAMP DEFAULT NOW(),
                            CONSTRAINT dates_coherentes CHECK (date_fin >= date_debut)
);

-- Table d'association clients-promotions
CREATE TABLE utilisations_promotions (
                                         id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                         promotion_id INTEGER NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
                                         commande_id INTEGER NOT NULL REFERENCES commandes(id) ON DELETE CASCADE,
                                         date_utilisation TIMESTAMP DEFAULT NOW(),
                                         UNIQUE(promotion_id, commande_id)
);

-- Table des mouvements de stock
CREATE TABLE mouvements_stock (
                                  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                  produit_id INTEGER NOT NULL REFERENCES produits(id) ON DELETE CASCADE,
                                  type_mouvement TEXT CHECK (type_mouvement IN ('entree', 'sortie', 'ajustement', 'retour')) NOT NULL,
                                  quantite INTEGER NOT NULL,
                                  stock_avant INTEGER NOT NULL,
                                  stock_apres INTEGER NOT NULL,
                                  reference_commande INTEGER REFERENCES commandes(id),
                                  motif TEXT,
                                  user_name TEXT DEFAULT current_user,
                                  date_mouvement TIMESTAMP DEFAULT NOW()
);

-- Table d'audit générique
CREATE TABLE audit_log (
                           id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                           table_name TEXT NOT NULL,
                           operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
                           row_id INTEGER,
                           user_name TEXT DEFAULT current_user,
                           timestamp TIMESTAMP DEFAULT NOW(),
                           old_data JSONB,
                           new_data JSONB,
                           ip_address INET
);

-- ============================================================================
-- FONCTION POUR GÉNÉRER LES NUMÉROS DE COMMANDE
-- ============================================================================
CREATE OR REPLACE FUNCTION generer_numero_commande()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.numero := 'CMD-' || to_char(NOW(), 'YYYYMMDD') || '-' || LPAD(NEW.id::TEXT, 6, '0');
RETURN NEW;
END;
$$;

CREATE TRIGGER trg_generer_numero_commande
    BEFORE INSERT ON commandes
    FOR EACH ROW
    WHEN (NEW.numero IS NULL)
    EXECUTE FUNCTION generer_numero_commande();

-- ============================================================================
-- INDEX POUR OPTIMISATION
-- ============================================================================

-- Index sur les clés étrangères
CREATE INDEX idx_produits_categorie ON produits(categorie_id);
CREATE INDEX idx_produits_fournisseur ON produits(fournisseur_id);
CREATE INDEX idx_commandes_client ON commandes(client_id);
CREATE INDEX idx_lignes_commande_commande ON lignes_commande(commande_id);
CREATE INDEX idx_lignes_commande_produit ON lignes_commande(produit_id);

-- Index sur les colonnes fréquemment recherchées
CREATE INDEX idx_produits_nom ON produits(nom);
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_commandes_date ON commandes(date_commande DESC);
CREATE INDEX idx_commandes_statut ON commandes(statut);

-- Index sur les colonnes avec WHERE fréquent
CREATE INDEX idx_produits_actifs ON produits(id) WHERE actif = true;
CREATE INDEX idx_stock_faible ON produits(id) WHERE stock < stock_minimum;

-- Index JSONB (GIN)
CREATE INDEX idx_produits_caracteristiques ON produits USING gin (caracteristiques);

-- Index sur les tableaux
CREATE INDEX idx_produits_tags ON produits USING gin (tags);

-- Index partial pour les commandes en cours
CREATE INDEX idx_commandes_en_cours ON commandes(id)
    WHERE statut IN ('en_attente', 'confirmee', 'expediee');

-- Index pour les recherches textuelles
CREATE INDEX idx_produits_nom_trgm ON produits USING gin (nom gin_trgm_ops);

-- ============================================================================
-- VUES UTILES
-- ============================================================================

-- Vue des produits avec informations enrichies
CREATE VIEW v_produits_complets AS
SELECT
    p.id,
    p.reference,
    p.nom,
    p.description,
    p.prix,
    p.stock,
    c.nom AS categorie,
    f.nom AS fournisseur,
    COALESCE(AVG(ap.note), 0) AS note_moyenne,
    COUNT(DISTINCT ap.id) AS nombre_avis,
    p.actif,
    CASE
        WHEN p.stock = 0 THEN 'rupture'
        WHEN p.stock < p.stock_minimum THEN 'stock_faible'
        ELSE 'disponible'
        END AS statut_stock
FROM produits p
         LEFT JOIN categories c ON p.categorie_id = c.id
         LEFT JOIN fournisseurs f ON p.fournisseur_id = f.id
         LEFT JOIN avis_produits ap ON p.id = ap.produit_id
GROUP BY p.id, c.nom, f.nom;

-- Vue des commandes avec totaux
CREATE VIEW v_commandes_details AS
SELECT
    co.id,
    co.numero,
    co.date_commande,
    co.statut,
    cl.nom || ' ' || cl.prenom AS client_nom,
    cl.email AS client_email,
    COUNT(lc.id) AS nombre_articles,
    SUM(lc.quantite) AS quantite_totale,
    co.montant_ttc,
    co.created_at,
    co.updated_at
FROM commandes co
         JOIN clients cl ON co.client_id = cl.id
         LEFT JOIN lignes_commande lc ON co.id = lc.commande_id
GROUP BY co.id, cl.nom, cl.prenom, cl.email;

-- Vue matérialisée pour les statistiques de ventes
CREATE MATERIALIZED VIEW mv_stats_ventes_mensuelles AS
SELECT
    date_trunc('month', c.date_commande) AS mois,
    COUNT(DISTINCT c.id) AS nombre_commandes,
    COUNT(DISTINCT c.client_id) AS nombre_clients,
    SUM(c.montant_ttc) AS chiffre_affaires,
    AVG(c.montant_ttc) AS panier_moyen,
    SUM(lc.quantite) AS articles_vendus
FROM commandes c
         JOIN lignes_commande lc ON c.id = lc.commande_id
WHERE c.statut != 'annulee'
GROUP BY date_trunc('month', c.date_commande)
ORDER BY mois DESC;

CREATE UNIQUE INDEX ON mv_stats_ventes_mensuelles (mois);

-- ============================================================================
-- FONCTIONS UTILITAIRES
-- ============================================================================

-- Fonction pour calculer le TTC
CREATE OR REPLACE FUNCTION calculer_ttc(prix_ht NUMERIC, taux_tva NUMERIC DEFAULT 0.20)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF taux_tva < 0 THEN
        RAISE EXCEPTION 'Taux de TVA négatif interdit';
END IF;
RETURN ROUND(prix_ht * (1 + taux_tva), 2);
END;
$$;

-- Fonction pour obtenir les produits d'une catégorie (récursif)
CREATE OR REPLACE FUNCTION produits_par_categorie(categorie_nom TEXT)
RETURNS TABLE(id INTEGER, nom TEXT, prix NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
RETURN QUERY
    WITH RECURSIVE arbre_categories AS (
        SELECT c.id FROM categories c WHERE c.nom = categorie_nom
        UNION ALL
        SELECT c.id
        FROM categories c
        JOIN arbre_categories ac ON c.parent_id = ac.id
    )
SELECT p.id, p.nom, p.prix
FROM produits p
WHERE p.categorie_id IN (SELECT ac.id FROM arbre_categories ac)
  AND p.actif = true;
END;
$$;

-- Fonction pour vérifier la disponibilité d'un produit
CREATE OR REPLACE FUNCTION verifier_stock(p_produit_id INTEGER, p_quantite INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
v_stock_actuel INTEGER;
BEGIN
SELECT stock INTO v_stock_actuel
FROM produits
WHERE id = p_produit_id;

IF NOT FOUND THEN
        RAISE EXCEPTION 'Produit % introuvable', p_produit_id;
END IF;

RETURN v_stock_actuel >= p_quantite;
END;
$$;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger pour normaliser les emails
CREATE OR REPLACE FUNCTION normaliser_email()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.email := lower(trim(NEW.email));
RETURN NEW;
END;
$$;

CREATE TRIGGER trg_normaliser_email_clients
    BEFORE INSERT OR UPDATE ON clients
                         FOR EACH ROW
                         EXECUTE FUNCTION normaliser_email();

-- Trigger pour mettre à jour le timestamp
CREATE OR REPLACE FUNCTION maj_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := NOW();
RETURN NEW;
END;
$$;

CREATE TRIGGER trg_produits_updated
    BEFORE UPDATE ON produits
    FOR EACH ROW
    EXECUTE FUNCTION maj_updated_at();

CREATE TRIGGER trg_clients_updated
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION maj_updated_at();

CREATE TRIGGER trg_commandes_updated
    BEFORE UPDATE ON commandes
    FOR EACH ROW
    EXECUTE FUNCTION maj_updated_at();

-- Trigger pour enregistrer les mouvements de stock
CREATE OR REPLACE FUNCTION enregistrer_mouvement_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.stock != NEW.stock THEN
        INSERT INTO mouvements_stock (
            produit_id,
            type_mouvement,
            quantite,
            stock_avant,
            stock_apres,
            motif
        ) VALUES (
            NEW.id,
            CASE WHEN NEW.stock > OLD.stock THEN 'entree' ELSE 'sortie' END,
            ABS(NEW.stock - OLD.stock),
            OLD.stock,
            NEW.stock,
            'Modification manuelle'
        );
END IF;
RETURN NEW;
END;
$$;

CREATE TRIGGER trg_stock_mouvement
    AFTER UPDATE ON produits
    FOR EACH ROW
    EXECUTE FUNCTION enregistrer_mouvement_stock();

-- Trigger pour mettre à jour les totaux de commande
CREATE OR REPLACE FUNCTION calculer_totaux_commande()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
v_commande_id INTEGER;
    v_total_ht NUMERIC;
    v_tva NUMERIC;
BEGIN
    -- Récupérer l'ID de la commande concernée
    IF TG_OP = 'DELETE' THEN
        v_commande_id := OLD.commande_id;
ELSE
        v_commande_id := NEW.commande_id;
END IF;

    -- Calculer le total HT
SELECT COALESCE(SUM(montant_ligne), 0)
INTO v_total_ht
FROM lignes_commande
WHERE commande_id = v_commande_id;

-- Calculer la TVA (20%)
v_tva := ROUND(v_total_ht * 0.20, 2);

    -- Mettre à jour la commande
UPDATE commandes
SET
    montant_ht = v_total_ht,
    montant_tva = v_tva,
    montant_ttc = v_total_ht + v_tva
WHERE id = v_commande_id;

RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_calculer_totaux
    AFTER INSERT OR UPDATE OR DELETE ON lignes_commande
    FOR EACH ROW
    EXECUTE FUNCTION calculer_totaux_commande();

-- Trigger pour déduire le stock lors d'une commande
CREATE OR REPLACE FUNCTION deduire_stock_commande()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
v_stock_actuel INTEGER;
BEGIN
    -- Récupérer le stock actuel
SELECT stock INTO v_stock_actuel
FROM produits
WHERE id = NEW.produit_id;

-- Vérifier si le stock est suffisant
IF v_stock_actuel < NEW.quantite THEN
        RAISE EXCEPTION 'Stock insuffisant pour le produit % (stock: %, demandé: %)',
            NEW.produit_id, v_stock_actuel, NEW.quantite;
END IF;

    -- Déduire le stock
UPDATE produits
SET stock = stock - NEW.quantite
WHERE id = NEW.produit_id;

-- Enregistrer le mouvement
INSERT INTO mouvements_stock (
    produit_id,
    type_mouvement,
    quantite,
    stock_avant,
    stock_apres,
    reference_commande,
    motif
) VALUES (
             NEW.produit_id,
             'sortie',
             NEW.quantite,
             v_stock_actuel,
             v_stock_actuel - NEW.quantite,
             NEW.commande_id,
             'Vente - Commande #' || NEW.commande_id
         );

RETURN NEW;
END;
$$;

CREATE TRIGGER trg_deduire_stock
    AFTER INSERT ON lignes_commande
    FOR EACH ROW
    EXECUTE FUNCTION deduire_stock_commande();

-- Fonction pour restaurer le stock lors d'un retour
CREATE OR REPLACE FUNCTION restaurer_stock_annulation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
v_ligne RECORD;
BEGIN
    -- Si la commande passe en statut annulée
    IF NEW.statut = 'annulee' AND OLD.statut != 'annulee' THEN
        -- Restaurer le stock pour chaque ligne de commande
        FOR v_ligne IN
SELECT produit_id, quantite
FROM lignes_commande
WHERE commande_id = NEW.id
    LOOP
UPDATE produits
SET stock = stock + v_ligne.quantite
WHERE id = v_ligne.produit_id;

-- Enregistrer le mouvement
INSERT INTO mouvements_stock (
    produit_id,
    type_mouvement,
    quantite,
    stock_avant,
    stock_apres,
    reference_commande,
    motif
)
SELECT
    v_ligne.produit_id,
    'retour',
    v_ligne.quantite,
    stock - v_ligne.quantite,
    stock,
    NEW.id,
    'Annulation commande #' || NEW.id
FROM produits
WHERE id = v_ligne.produit_id;
END LOOP;
END IF;

RETURN NEW;
END;
$$;

CREATE TRIGGER trg_restaurer_stock_annulation
    AFTER UPDATE ON commandes
    FOR EACH ROW
    WHEN (NEW.statut = 'annulee' AND OLD.statut != 'annulee')
EXECUTE FUNCTION restaurer_stock_annulation();

-- Trigger d'audit générique
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, row_id, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.id, to_jsonb(NEW));
RETURN NEW;
ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, row_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.id, to_jsonb(OLD), to_jsonb(NEW));
RETURN NEW;
ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, row_id, old_data)
        VALUES (TG_TABLE_NAME, TG_OP, OLD.id, to_jsonb(OLD));
RETURN OLD;
END IF;
END;
$$;

-- Appliquer l'audit sur les tables importantes
CREATE TRIGGER audit_clients
    AFTER INSERT OR UPDATE OR DELETE ON clients
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_commandes
    AFTER INSERT OR UPDATE OR DELETE ON commandes
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- ============================================================================
-- SÉCURITÉ : RÔLES ET PERMISSIONS
-- ============================================================================

-- Créer les rôles
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'lecteur_ecommerce') THEN
CREATE ROLE lecteur_ecommerce NOLOGIN;
END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'vendeur_ecommerce') THEN
CREATE ROLE vendeur_ecommerce NOLOGIN;
END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'admin_ecommerce') THEN
CREATE ROLE admin_ecommerce NOLOGIN;
END IF;
END
$$;

-- Attribution des droits
GRANT USAGE ON SCHEMA ecommerce TO lecteur_ecommerce;
GRANT SELECT ON ALL TABLES IN SCHEMA ecommerce TO lecteur_ecommerce;

GRANT lecteur_ecommerce TO vendeur_ecommerce;
GRANT INSERT, UPDATE ON commandes, lignes_commande TO vendeur_ecommerce;
GRANT UPDATE(stock) ON produits TO vendeur_ecommerce;

GRANT ALL PRIVILEGES ON SCHEMA ecommerce TO admin_ecommerce;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ecommerce TO admin_ecommerce;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ecommerce TO admin_ecommerce;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Activer RLS sur les commandes
ALTER TABLE commandes ENABLE ROW LEVEL SECURITY;

-- Les clients ne voient que leurs commandes
CREATE POLICY commandes_client_policy
ON commandes
FOR SELECT
               TO PUBLIC
               USING (
               client_id = (
               SELECT client_id FROM utilisateurs
               WHERE username = current_user
               )
               );

-- Les admins voient tout
CREATE POLICY commandes_admin_policy
ON commandes
FOR ALL
TO admin_ecommerce
USING (true);

-- ============================================================================
-- DONNÉES DE TEST
-- ============================================================================

-- Insertion des catégories (hiérarchique)
INSERT INTO categories (nom, parent_id, description) VALUES
                                                         ('Électronique', NULL, 'Produits électroniques et high-tech'),
                                                         ('Informatique', 1, 'Ordinateurs et accessoires'),
                                                         ('Smartphones', 1, 'Téléphones mobiles et accessoires'),
                                                         ('Audio', 1, 'Écouteurs, enceintes et audio'),
                                                         ('Maison', NULL, 'Articles pour la maison'),
                                                         ('Cuisine', 5, 'Ustensiles et électroménager'),
                                                         ('Décoration', 5, 'Objets de décoration'),
                                                         ('Vêtements', NULL, 'Mode et habillement'),
                                                         ('Homme', 8, 'Vêtements homme'),
                                                         ('Femme', 8, 'Vêtements femme');

-- Insertion des fournisseurs
INSERT INTO fournisseurs (nom, email, telephone, pays) VALUES
                                                           ('TechDistrib', 'contact@techdistrib.fr', '0123456789', 'France'),
                                                           ('GlobalElectronics', 'info@globalelec.com', '0987654321', 'Allemagne'),
                                                           ('HomeStyle', 'commande@homestyle.fr', '0147258369', 'France'),
                                                           ('FashionWorld', 'contact@fashionworld.it', '0369258147', 'Italie');

-- Insertion des produits avec caractéristiques JSONB
INSERT INTO produits (nom, description, categorie_id, fournisseur_id, prix, stock, caracteristiques, tags) VALUES
                                                                                                               ('MacBook Pro 16"', 'Ordinateur portable haute performance', 2, 1, 2499.00, 15,
                                                                                                                '{"processeur": "M3 Pro", "ram": "32GB", "stockage": "1TB SSD", "ecran": "16 pouces"}',
                                                                                                                ARRAY['apple', 'laptop', 'pro']),
                                                                                                               ('iPhone 15 Pro', 'Smartphone dernière génération', 3, 1, 1299.00, 30,
                                                                                                                '{"processeur": "A17 Pro", "ram": "8GB", "stockage": "256GB", "ecran": "6.1 pouces"}',
                                                                                                                ARRAY['apple', 'smartphone', '5g']),
                                                                                                               ('AirPods Pro', 'Écouteurs sans fil avec réduction de bruit', 4, 1, 279.00, 50,
                                                                                                                '{"type": "intra-auriculaires", "autonomie": "6h", "recharge_sans_fil": true}',
                                                                                                                ARRAY['apple', 'audio', 'bluetooth']),
                                                                                                               ('Clavier mécanique RGB', 'Clavier gaming rétroéclairé', 2, 2, 129.00, 25,
                                                                                                                '{"switches": "Cherry MX Red", "retroeclairage": "RGB", "type": "mécanique"}',
                                                                                                                ARRAY['gaming', 'peripherique', 'rgb']),
                                                                                                               ('Souris gaming', 'Souris haute précision 16000 DPI', 2, 2, 79.00, 40,
                                                                                                                '{"dpi": 16000, "boutons": 8, "rgb": true, "sans_fil": true}',
                                                                                                                ARRAY['gaming', 'peripherique']),
                                                                                                               ('Robot cuiseur', 'Robot multifonction connecté', 6, 3, 399.00, 12,
                                                                                                                '{"capacite": "4.5L", "puissance": "1200W", "programmes": 150, "wifi": true}',
                                                                                                                ARRAY['cuisine', 'electromenager', 'connecte']),
                                                                                                               ('Lampe design LED', 'Lampe de bureau moderne', 7, 3, 89.00, 20,
                                                                                                                '{"type": "LED", "intensite_variable": true, "temperature_couleur": "2700-6500K"}',
                                                                                                                ARRAY['decoration', 'led', 'moderne']),
                                                                                                               ('T-shirt coton bio', 'T-shirt écologique et confortable', 9, 4, 29.00, 100,
                                                                                                                '{"matiere": "coton bio", "tailles": ["S", "M", "L", "XL"], "couleurs": ["blanc", "noir", "bleu"]}',
                                                                                                                ARRAY['vetements', 'bio', 'basique']),
                                                                                                               ('Jean slim', 'Jean moderne coupe ajustée', 9, 4, 79.00, 60,
                                                                                                                '{"coupe": "slim", "matiere": "denim stretch", "tailles": ["28", "30", "32", "34", "36"]}',
                                                                                                                ARRAY['vetements', 'jean', 'mode']),
                                                                                                               ('Robe d''été', 'Robe légère et élégante', 10, 4, 59.00, 45,
                                                                                                                '{"saison": "été", "tailles": ["36", "38", "40", "42"], "motif": "floral"}',
                                                                                                                ARRAY['vetements', 'femme', 'ete']);

-- Insertion des clients
INSERT INTO clients (nom, prenom, email, password_hash, telephone, date_naissance, newsletter, points_fidelite) VALUES
                                                                                                                    ('Dupont', 'Jean', 'jean.dupont@email.fr', crypt('password123', gen_salt('bf')), '0601020304', '1985-03-15', true, 150),
                                                                                                                    ('Martin', 'Sophie', 'sophie.martin@email.fr', crypt('password123', gen_salt('bf')), '0602030405', '1990-07-22', true, 75),
                                                                                                                    ('Bernard', 'Pierre', 'pierre.bernard@email.fr', crypt('password123', gen_salt('bf')), '0603040506', '1978-11-08', false, 0),
                                                                                                                    ('Dubois', 'Marie', 'marie.dubois@email.fr', crypt('password123', gen_salt('bf')), '0604050607', '1995-01-30', true, 220),
                                                                                                                    ('Leroy', 'Thomas', 'thomas.leroy@email.fr', crypt('password123', gen_salt('bf')), '0605060708', '1988-09-12', false, 50);

-- Insertion des utilisateurs
INSERT INTO utilisateurs (username, password_hash, client_id, role) VALUES
                                                                        ('jean.dupont', crypt('pass123', gen_salt('bf')), 1, 'client'),
                                                                        ('sophie.martin', crypt('pass123', gen_salt('bf')), 2, 'client'),
                                                                        ('pierre.bernard', crypt('pass123', gen_salt('bf')), 3, 'client'),
                                                                        ('marie.dubois', crypt('pass123', gen_salt('bf')), 4, 'client'),
                                                                        ('admin', crypt('admin123', gen_salt('bf')), NULL, 'admin'),
                                                                        ('vendeur1', crypt('vendeur123', gen_salt('bf')), NULL, 'vendeur');

-- Insertion des commandes
INSERT INTO commandes (client_id, date_commande, statut, numero) VALUES
                                                                     (1, NOW() - INTERVAL '10 days', 'livree', 'CMD-' || to_char(NOW() - INTERVAL '10 days', 'YYYYMMDD') || '-000001'),
                                                                     (1, NOW() - INTERVAL '5 days', 'expediee', 'CMD-' || to_char(NOW() - INTERVAL '5 days', 'YYYYMMDD') || '-000002'),
                                                                     (2, NOW() - INTERVAL '3 days', 'confirmee', 'CMD-' || to_char(NOW() - INTERVAL '3 days', 'YYYYMMDD') || '-000003'),
                                                                     (3, NOW() - INTERVAL '2 days', 'confirmee', 'CMD-' || to_char(NOW() - INTERVAL '2 days', 'YYYYMMDD') || '-000004'),
                                                                     (4, NOW() - INTERVAL '1 day', 'en_attente', 'CMD-' || to_char(NOW() - INTERVAL '1 day', 'YYYYMMDD') || '-000005'),
                                                                     (1, NOW(), 'en_attente', 'CMD-' || to_char(NOW(), 'YYYYMMDD') || '-000006');

-- Insertion des lignes de commande
INSERT INTO lignes_commande (commande_id, produit_id, quantite, prix_unitaire, reduction_pourcent) VALUES
-- Commande 1
(1, 1, 1, 2499.00, 0),
(1, 3, 2, 279.00, 10),
-- Commande 2
(2, 4, 1, 129.00, 0),
(2, 5, 1, 79.00, 0),
-- Commande 3
(3, 2, 1, 1299.00, 5),
(3, 3, 1, 279.00, 0),
-- Commande 4
(4, 8, 3, 29.00, 0),
(4, 9, 2, 79.00, 15),
-- Commande 5
(5, 6, 1, 399.00, 0),
(5, 7, 2, 89.00, 0),
-- Commande 6
(6, 10, 1, 59.00, 0);

-- Insertion des avis produits
INSERT INTO avis_produits (produit_id, client_id, note, commentaire, verifie) VALUES
(1, 1, 5, 'Excellent ordinateur, très rapide et silencieux!', true),
(1, 2, 4, 'Très bon produit mais un peu cher', true),
(2, 1, 5, 'Le meilleur smartphone que j''ai eu', true),
(3, 2, 5, 'Son exceptionnel, je recommande', true),
(4, 3, 4, 'Bon clavier mais un peu bruyant', true),
(6, 4, 5, 'Robot cuiseur incroyable, très pratique', true),
(8, 1, 3, 'Qualité correcte pour le prix', true);

-- Insertion des promotions
INSERT INTO promotions (code, description, type, valeur, date_debut, date_fin, utilisation_max) VALUES
('BIENVENUE10', 'Réduction de bienvenue', 'pourcentage', 10, '2025-01-01', '2025-12-31', 100),
('NOEL2025', 'Promo de Noël', 'pourcentage', 20, '2025-12-01', '2025-12-31', 500),
('LIVRAISONGRATUITE', 'Livraison offerte', 'livraison_gratuite', 0, '2025-01-01', '2025-12-31', NULL),
('SOLDES50', 'Soldes d''hiver', 'pourcentage', 50, '2025-01-10', '2025-02-15', 1000);
