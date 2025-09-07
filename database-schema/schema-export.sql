
-- Script d'export du schéma de base de données
-- Généré automatiquement le 2025-09-06T16:31:59.435Z
-- Source: https://wlqyrmntfxwdvkzzsujv.supabase.co

-- ============================================
-- EXPORT DU SCHÉMA DE BASE DE DONNÉES
-- ============================================

-- 1. Tables principales
-- ====================

-- Table des clients
CREATE TABLE IF NOT EXISTS clients (
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
CREATE TABLE IF NOT EXISTS produits (
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
CREATE TABLE IF NOT EXISTS reparations (
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
CREATE TABLE IF NOT EXISTS interventions (
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
CREATE TABLE IF NOT EXISTS factures (
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

-- Table des utilisateurs (pour l'authentification)
CREATE TABLE IF NOT EXISTS utilisateurs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255),
    role VARCHAR(50) DEFAULT 'technicien',
    actif BOOLEAN DEFAULT true,
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_derniere_connexion TIMESTAMP WITH TIME ZONE
);

-- 2. Index pour optimiser les performances
-- ========================================

CREATE INDEX IF NOT EXISTS idx_clients_email ON clients(email);
CREATE INDEX IF NOT EXISTS idx_clients_nom ON clients(nom);
CREATE INDEX IF NOT EXISTS idx_reparations_client_id ON reparations(client_id);
CREATE INDEX IF NOT EXISTS idx_reparations_statut ON reparations(statut);
CREATE INDEX IF NOT EXISTS idx_reparations_date_reception ON reparations(date_reception);
CREATE INDEX IF NOT EXISTS idx_interventions_reparation_id ON interventions(reparation_id);
CREATE INDEX IF NOT EXISTS idx_factures_client_id ON factures(client_id);
CREATE INDEX IF NOT EXISTS idx_factures_numero ON factures(numero_facture);

-- 3. Triggers pour la mise à jour automatique des timestamps
-- ==========================================================

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

-- 4. Fonctions utilitaires
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

-- 5. Données de test (optionnel)
-- ==============================

-- Insérer des données de test si nécessaire
-- (Décommentez les lignes suivantes si vous voulez des données de test)

/*
-- Client de test
INSERT INTO clients (nom, prenom, email, telephone) VALUES
('Dupont', 'Jean', 'jean.dupont@email.com', '0123456789'),
('Martin', 'Marie', 'marie.martin@email.com', '0987654321');

-- Produit de test
INSERT INTO produits (nom, marque, modele, type_produit, prix_vente) VALUES
('iPhone 12', 'Apple', 'A2172', 'Smartphone', 899.00),
('Samsung Galaxy S21', 'Samsung', 'SM-G991B', 'Smartphone', 799.00);
*/

-- 6. Politiques RLS (Row Level Security)
-- =====================================

-- Activer RLS sur toutes les tables
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE produits ENABLE ROW LEVEL SECURITY;
ALTER TABLE reparations ENABLE ROW LEVEL SECURITY;
ALTER TABLE interventions ENABLE ROW LEVEL SECURITY;
ALTER TABLE factures ENABLE ROW LEVEL SECURITY;
ALTER TABLE utilisateurs ENABLE ROW LEVEL SECURITY;

-- Politiques de base (à adapter selon vos besoins)
-- Tous les utilisateurs authentifiés peuvent lire et modifier
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

-- ============================================
-- FIN DU SCRIPT D'EXPORT
-- ============================================

SELECT 'Schéma exporté avec succès' as status;
