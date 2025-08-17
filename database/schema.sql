-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table des clients
CREATE TABLE IF NOT EXISTS clients (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telephone VARCHAR(20) NOT NULL,
    adresse TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des produits
CREATE TABLE IF NOT EXISTS produits (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    description TEXT,
    prix DECIMAL(10,2) NOT NULL,
    stock INTEGER DEFAULT 0,
    categorie VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des services
CREATE TABLE IF NOT EXISTS services (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    description TEXT,
    prix DECIMAL(10,2) NOT NULL,
    duree_estimee INTEGER, -- en minutes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des réparations
CREATE TABLE IF NOT EXISTS reparations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    appareil VARCHAR(255) NOT NULL,
    probleme TEXT NOT NULL,
    statut VARCHAR(20) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'en_cours', 'terminee', 'annulee')),
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_fin_estimee TIMESTAMP WITH TIME ZONE,
    date_fin_reelle TIMESTAMP WITH TIME ZONE,
    prix_estime DECIMAL(10,2),
    prix_final DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des pièces détachées
CREATE TABLE IF NOT EXISTS pieces (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    description TEXT,
    prix DECIMAL(10,2) NOT NULL,
    stock INTEGER DEFAULT 0,
    fournisseur VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des commandes
CREATE TABLE IF NOT EXISTS commandes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    statut VARCHAR(20) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'confirmee', 'en_preparation', 'expediee', 'livree', 'annulee')),
    total DECIMAL(10,2) DEFAULT 0,
    date_commande TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date_livraison_estimee TIMESTAMP WITH TIME ZONE,
    date_livraison_reelle TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table de liaison commandes-produits
CREATE TABLE IF NOT EXISTS commande_produits (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    commande_id UUID REFERENCES commandes(id) ON DELETE CASCADE,
    produit_id UUID REFERENCES produits(id) ON DELETE CASCADE,
    quantite INTEGER NOT NULL,
    prix_unitaire DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des utilisateurs (pour l'authentification)
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    nom VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('admin', 'user', 'technicien')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des rendez-vous
CREATE TABLE IF NOT EXISTS rendez_vous (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    date_rdv TIMESTAMP WITH TIME ZONE NOT NULL,
    duree INTEGER DEFAULT 60, -- en minutes
    motif TEXT,
    statut VARCHAR(20) DEFAULT 'confirme' CHECK (statut IN ('confirme', 'annule', 'termine')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pour mettre à jour updated_at
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_produits_updated_at BEFORE UPDATE ON produits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON services FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reparations_updated_at BEFORE UPDATE ON reparations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pieces_updated_at BEFORE UPDATE ON pieces FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_commandes_updated_at BEFORE UPDATE ON commandes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_rendez_vous_updated_at BEFORE UPDATE ON rendez_vous FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Données de test
INSERT INTO clients (nom, email, telephone, adresse) VALUES
('Jean Dupont', 'jean.dupont@email.com', '0123456789', '123 Rue de la Paix, Paris'),
('Marie Martin', 'marie.martin@email.com', '0987654321', '456 Avenue des Champs, Lyon'),
('Pierre Durand', 'pierre.durand@email.com', '0555666777', '789 Boulevard Central, Marseille')
ON CONFLICT (email) DO NOTHING;

INSERT INTO produits (nom, description, prix, stock, categorie) VALUES
('Écran iPhone 12', 'Écran de remplacement pour iPhone 12', 89.99, 15, 'Écrans'),
('Batterie Samsung Galaxy', 'Batterie de remplacement Galaxy S21', 45.50, 25, 'Batteries'),
('Câble USB-C', 'Câble de charge USB-C 2m', 12.99, 50, 'Accessoires')
ON CONFLICT DO NOTHING;

INSERT INTO services (nom, description, prix, duree_estimee) VALUES
('Remplacement d''écran', 'Remplacement complet d''écran smartphone', 29.99, 60),
('Diagnostic complet', 'Diagnostic complet de l''appareil', 19.99, 30),
('Nettoyage interne', 'Nettoyage complet de l''appareil', 24.99, 45)
ON CONFLICT DO NOTHING;

INSERT INTO pieces (nom, description, prix, stock, fournisseur) VALUES
('Vis iPhone', 'Lot de vis pour iPhone', 5.99, 100, 'Apple Parts'),
('Joint d''étanchéité', 'Joint pour étanchéité smartphone', 3.50, 75, 'TechParts'),
('Connecteur de charge', 'Connecteur de charge universel', 8.99, 30, 'ElectroParts')
ON CONFLICT DO NOTHING;

-- Politiques RLS (Row Level Security)
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE produits ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE reparations ENABLE ROW LEVEL SECURITY;
ALTER TABLE pieces ENABLE ROW LEVEL SECURITY;
ALTER TABLE commandes ENABLE ROW LEVEL SECURITY;
ALTER TABLE commande_produits ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE rendez_vous ENABLE ROW LEVEL SECURITY;

-- Politiques pour permettre l'accès complet (à ajuster selon vos besoins)
CREATE POLICY "Enable read access for all users" ON clients FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON clients FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON clients FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON clients FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON produits FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON produits FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON produits FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON produits FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON services FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON services FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON services FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON services FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON reparations FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON reparations FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON reparations FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON reparations FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON pieces FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON pieces FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON pieces FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON pieces FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON commandes FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON commandes FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON commandes FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON commandes FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON commande_produits FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON commande_produits FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON commande_produits FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON commande_produits FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON users FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON users FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON users FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON rendez_vous FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON rendez_vous FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON rendez_vous FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON rendez_vous FOR DELETE USING (true);
