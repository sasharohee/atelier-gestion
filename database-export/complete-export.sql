
-- ============================================
-- EXPORT COMPLET DE TOUTES LES TABLES
-- Généré automatiquement le 2025-09-06T16:40:15.281Z
-- Source: https://wlqyrmntfxwdvkzzsujv.supabase.co
-- ============================================

-- 1. DROP des tables existantes (si elles existent)
-- ================================================

DROP TABLE IF EXISTS factures CASCADE;
DROP TABLE IF EXISTS interventions CASCADE;
DROP TABLE IF EXISTS reparations CASCADE;
DROP TABLE IF EXISTS produits CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS utilisateurs CASCADE;

-- 2. Suppression des fonctions existantes
-- ======================================

DROP FUNCTION IF EXISTS update_clients_modified_time() CASCADE;
DROP FUNCTION IF EXISTS update_produits_modified_time() CASCADE;
DROP FUNCTION IF EXISTS update_reparations_modified_time() CASCADE;
DROP FUNCTION IF EXISTS update_factures_modified_time() CASCADE;
DROP FUNCTION IF EXISTS generate_facture_number() CASCADE;
DROP FUNCTION IF EXISTS calculate_reparation_total(UUID) CASCADE;

-- 3. Création des tables principales
-- ==================================

-- Table des clients
CREATE TABLE clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    telephone VARCHAR(20),
    adresse TEXT,
    ville VARCHAR(100),
    code_postal VARCHAR(10),
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_modification TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    actif BOOLEAN DEFAULT true
);

-- Table des produits
CREATE TABLE produits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    marque VARCHAR(100),
    modele VARCHAR(100),
    type_produit VARCHAR(50),
    description TEXT,
    prix_achat DECIMAL(10,2),
    prix_vente DECIMAL(10,2),
    stock INTEGER DEFAULT 0,
    stock_minimum INTEGER DEFAULT 0,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_modification TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actif BOOLEAN DEFAULT true
);

-- Table des réparations
CREATE TABLE reparations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    produit_id UUID REFERENCES produits(id) ON DELETE SET NULL,
    description_probleme TEXT NOT NULL,
    diagnostic TEXT,
    solution_appliquee TEXT,
    statut VARCHAR(50) DEFAULT 'en_attente',
    priorite VARCHAR(20) DEFAULT 'normale',
    date_reception TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_debut_travaux TIMESTAMP WITH TIME ZONE,
    date_fin_travaux TIMESTAMP WITH TIME ZONE,
    date_livraison TIMESTAMP WITH TIME ZONE,
    cout_reparation DECIMAL(10,2),
    cout_pieces DECIMAL(10,2),
    cout_total DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des interventions
CREATE TABLE interventions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reparation_id UUID REFERENCES reparations(id) ON DELETE CASCADE,
    type_intervention VARCHAR(100) NOT NULL,
    description TEXT,
    duree_minutes INTEGER,
    cout DECIMAL(10,2),
    technicien VARCHAR(255),
    date_intervention TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des factures
CREATE TABLE factures (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    numero_facture VARCHAR(50) UNIQUE NOT NULL,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    reparation_id UUID REFERENCES reparations(id) ON DELETE SET NULL,
    date_facture DATE DEFAULT CURRENT_DATE,
    date_echeance DATE,
    montant_ht DECIMAL(10,2) NOT NULL,
    taux_tva DECIMAL(5,2) DEFAULT 20.00,
    montant_tva DECIMAL(10,2),
    montant_ttc DECIMAL(10,2) NOT NULL,
    statut VARCHAR(20) DEFAULT 'brouillon',
    mode_paiement VARCHAR(50),
    date_paiement DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des utilisateurs
CREATE TABLE utilisateurs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255),
    role VARCHAR(50) DEFAULT 'technicien',
    actif BOOLEAN DEFAULT true,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_derniere_connexion TIMESTAMP WITH TIME ZONE
);

-- 4. Création des index pour optimiser les performances
-- ====================================================

CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_clients_nom ON clients(nom);
CREATE INDEX idx_clients_telephone ON clients(telephone);
CREATE INDEX idx_produits_nom ON produits(nom);
CREATE INDEX idx_produits_marque ON produits(marque);
CREATE INDEX idx_produits_type ON produits(type_produit);
CREATE INDEX idx_reparations_client_id ON reparations(client_id);
CREATE INDEX idx_reparations_produit_id ON reparations(produit_id);
CREATE INDEX idx_reparations_statut ON reparations(statut);
CREATE INDEX idx_reparations_date_reception ON reparations(date_reception);
CREATE INDEX idx_reparations_priorite ON reparations(priorite);
CREATE INDEX idx_interventions_reparation_id ON interventions(reparation_id);
CREATE INDEX idx_interventions_type ON interventions(type_intervention);
CREATE INDEX idx_interventions_technicien ON interventions(technicien);
CREATE INDEX idx_factures_client_id ON factures(client_id);
CREATE INDEX idx_factures_reparation_id ON factures(reparation_id);
CREATE INDEX idx_factures_numero ON factures(numero_facture);
CREATE INDEX idx_factures_statut ON factures(statut);
CREATE INDEX idx_factures_date_facture ON factures(date_facture);
CREATE INDEX idx_utilisateurs_email ON utilisateurs(email);
CREATE INDEX idx_utilisateurs_role ON utilisateurs(role);

-- 5. Création des triggers pour la mise à jour automatique des timestamps
-- ======================================================================

-- Trigger pour clients
CREATE OR REPLACE FUNCTION update_clients_modified_time()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_clients_updated_at
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION update_clients_modified_time();

-- Trigger pour produits
CREATE OR REPLACE FUNCTION update_produits_modified_time()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_produits_updated_at
    BEFORE UPDATE ON produits
    FOR EACH ROW
    EXECUTE FUNCTION update_produits_modified_time();

-- Trigger pour réparations
CREATE OR REPLACE FUNCTION update_reparations_modified_time()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reparations_updated_at
    BEFORE UPDATE ON reparations
    FOR EACH ROW
    EXECUTE FUNCTION update_reparations_modified_time();

-- Trigger pour factures
CREATE OR REPLACE FUNCTION update_factures_modified_time()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_factures_updated_at
    BEFORE UPDATE ON factures
    FOR EACH ROW
    EXECUTE FUNCTION update_factures_modified_time();

-- 6. Fonctions utilitaires
-- ========================

-- Fonction pour générer un numéro de facture
CREATE OR REPLACE FUNCTION generate_facture_number()
RETURNS TEXT AS $$
DECLARE
    year_part TEXT;
    month_part TEXT;
    sequence_part TEXT;
    new_number TEXT;
BEGIN
    year_part := EXTRACT(YEAR FROM CURRENT_DATE)::TEXT;
    month_part := LPAD(EXTRACT(MONTH FROM CURRENT_DATE)::TEXT, 2, '0');
    
    -- Récupérer le prochain numéro de séquence pour ce mois
    SELECT COALESCE(MAX(CAST(SUBSTRING(numero_facture FROM 8) AS INTEGER)), 0) + 1
    INTO sequence_part
    FROM factures
    WHERE numero_facture LIKE year_part || month_part || '%';
    
    new_number := year_part || month_part || LPAD(sequence_part, 4, '0');
    RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour calculer le coût total d'une réparation
CREATE OR REPLACE FUNCTION calculate_reparation_total(reparation_uuid UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    total_cost DECIMAL(10,2) := 0;
    reparation_cost DECIMAL(10,2) := 0;
    pieces_cost DECIMAL(10,2) := 0;
BEGIN
    -- Récupérer le coût de la réparation
    SELECT COALESCE(cout_reparation, 0) INTO reparation_cost
    FROM reparations
    WHERE id = reparation_uuid;
    
    -- Récupérer le coût des pièces
    SELECT COALESCE(cout_pieces, 0) INTO pieces_cost
    FROM reparations
    WHERE id = reparation_uuid;
    
    total_cost := reparation_cost + pieces_cost;
    
    -- Mettre à jour le coût total
    UPDATE reparations
    SET cout_total = total_cost
    WHERE id = reparation_uuid;
    
    RETURN total_cost;
END;
$$ LANGUAGE plpgsql;

-- 7. Données de test pour le développement
-- =======================================

-- Clients de test
INSERT INTO clients (nom, prenom, email, telephone, adresse, ville, code_postal) VALUES
('Dupont', 'Jean', 'jean.dupont@email.com', '0123456789', '123 Rue de la Paix', 'Paris', '75001'),
('Martin', 'Marie', 'marie.martin@email.com', '0987654321', '456 Avenue des Champs', 'Lyon', '69001'),
('Bernard', 'Pierre', 'pierre.bernard@email.com', '0147258369', '789 Boulevard Saint-Germain', 'Marseille', '13001'),
('Dubois', 'Sophie', 'sophie.dubois@email.com', '0258147369', '321 Rue de Rivoli', 'Toulouse', '31000'),
('Moreau', 'Luc', 'luc.moreau@email.com', '0369258147', '654 Place Bellecour', 'Lille', '59000');

-- Produits de test
INSERT INTO produits (nom, marque, modele, type_produit, description, prix_achat, prix_vente, stock, stock_minimum) VALUES
('iPhone 12', 'Apple', 'A2172', 'Smartphone', 'Smartphone Apple iPhone 12 64GB', 699.00, 899.00, 5, 2),
('Samsung Galaxy S21', 'Samsung', 'SM-G991B', 'Smartphone', 'Smartphone Samsung Galaxy S21 128GB', 599.00, 799.00, 3, 1),
('MacBook Air M1', 'Apple', 'MGN63LL/A', 'Ordinateur', 'MacBook Air 13" avec puce M1 256GB', 999.00, 1299.00, 2, 1),
('Dell XPS 13', 'Dell', 'XPS9310', 'Ordinateur', 'Dell XPS 13 13.4" FHD+ 512GB', 1199.00, 1499.00, 1, 1),
('iPad Air', 'Apple', 'MYFM2LL/A', 'Tablette', 'iPad Air 10.9" 64GB Wi-Fi', 499.00, 649.00, 4, 2),
('Surface Pro 8', 'Microsoft', 'Surface Pro 8', 'Tablette', 'Surface Pro 8 13" 256GB', 1099.00, 1399.00, 2, 1);

-- Utilisateurs de test
INSERT INTO utilisateurs (email, nom, prenom, role) VALUES
('admin@atelier.com', 'Admin', 'Super', 'admin'),
('technicien1@atelier.com', 'Technicien', 'Jean', 'technicien'),
('technicien2@atelier.com', 'Technicien', 'Marie', 'technicien'),
('comptable@atelier.com', 'Comptable', 'Pierre', 'comptable');

-- Réparations de test
INSERT INTO reparations (client_id, produit_id, description_probleme, statut, priorite, cout_reparation, cout_pieces, cout_total) 
SELECT 
    c.id,
    p.id,
    'Écran cassé, besoin de remplacement',
    'en_cours',
    'haute',
    150.00,
    200.00,
    350.00
FROM clients c, produits p 
WHERE c.email = 'jean.dupont@email.com' AND p.nom = 'iPhone 12'
LIMIT 1;

INSERT INTO reparations (client_id, produit_id, description_probleme, statut, priorite, cout_reparation, cout_pieces, cout_total) 
SELECT 
    c.id,
    p.id,
    'Batterie qui se décharge rapidement',
    'termine',
    'normale',
    80.00,
    120.00,
    200.00
FROM clients c, produits p 
WHERE c.email = 'marie.martin@email.com' AND p.nom = 'Samsung Galaxy S21'
LIMIT 1;

-- Interventions de test
INSERT INTO interventions (reparation_id, type_intervention, description, duree_minutes, cout, technicien)
SELECT 
    r.id,
    'Remplacement écran',
    'Remplacement de l'écran LCD endommagé',
    120,
    150.00,
    'Jean Technicien'
FROM reparations r
WHERE r.description_probleme = 'Écran cassé, besoin de remplacement'
LIMIT 1;

INSERT INTO interventions (reparation_id, type_intervention, description, duree_minutes, cout, technicien)
SELECT 
    r.id,
    'Remplacement batterie',
    'Remplacement de la batterie défaillante',
    90,
    80.00,
    'Marie Technicien'
FROM reparations r
WHERE r.description_probleme = 'Batterie qui se décharge rapidement'
LIMIT 1;

-- Factures de test
INSERT INTO factures (numero_facture, client_id, reparation_id, montant_ht, taux_tva, montant_tva, montant_ttc, statut)
SELECT 
    '2025010001',
    r.client_id,
    r.id,
    r.cout_total,
    20.00,
    r.cout_total * 0.20,
    r.cout_total * 1.20,
    'paye'
FROM reparations r
WHERE r.description_probleme = 'Batterie qui se décharge rapidement'
LIMIT 1;

-- 8. Configuration des politiques RLS (Row Level Security)
-- ======================================================

-- Activer RLS sur toutes les tables
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE produits ENABLE ROW LEVEL SECURITY;
ALTER TABLE reparations ENABLE ROW LEVEL SECURITY;
ALTER TABLE interventions ENABLE ROW LEVEL SECURITY;
ALTER TABLE factures ENABLE ROW LEVEL SECURITY;
ALTER TABLE utilisateurs ENABLE ROW LEVEL SECURITY;

-- Politiques pour les utilisateurs authentifiés
CREATE POLICY "Enable all for authenticated users" ON clients
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all for authenticated users" ON produits
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all for authenticated users" ON reparations
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all for authenticated users" ON interventions
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all for authenticated users" ON factures
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all for authenticated users" ON utilisateurs
    FOR ALL USING (auth.role() = 'authenticated');

-- 9. Vérification finale
-- =====================

SELECT 'Export complet terminé avec succès' as status;
SELECT 'Tables créées:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

SELECT 'Données insérées:' as info;
SELECT 'clients' as table_name, COUNT(*) as count FROM clients
UNION ALL
SELECT 'produits' as table_name, COUNT(*) as count FROM produits
UNION ALL
SELECT 'reparations' as table_name, COUNT(*) as count FROM reparations
UNION ALL
SELECT 'interventions' as table_name, COUNT(*) as count FROM interventions
UNION ALL
SELECT 'factures' as table_name, COUNT(*) as count FROM factures
UNION ALL
SELECT 'utilisateurs' as table_name, COUNT(*) as count FROM utilisateurs;

-- ============================================
-- FIN DU SCRIPT D'EXPORT COMPLET
-- ============================================
