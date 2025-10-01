-- Script de création des tables pour les demandes de devis
-- À exécuter dans l'éditeur SQL de Supabase

-- Tables pour le système de demandes de devis en ligne
-- Création des tables pour gérer les demandes de devis avec URLs personnalisées

-- Table pour les URLs personnalisées des réparateurs
CREATE TABLE IF NOT EXISTS technician_custom_urls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    custom_url VARCHAR(50) NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour optimiser les recherches par URL personnalisée
CREATE INDEX IF NOT EXISTS idx_technician_custom_urls_custom_url ON technician_custom_urls(custom_url);
CREATE INDEX IF NOT EXISTS idx_technician_custom_urls_technician_id ON technician_custom_urls(technician_id);
CREATE INDEX IF NOT EXISTS idx_technician_custom_urls_active ON technician_custom_urls(is_active);

-- Table pour les demandes de devis
CREATE TABLE IF NOT EXISTS quote_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_number VARCHAR(20) NOT NULL UNIQUE,
    custom_url VARCHAR(50) NOT NULL,
    technician_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Informations client
    client_first_name VARCHAR(100) NOT NULL,
    client_last_name VARCHAR(100) NOT NULL,
    client_email VARCHAR(255) NOT NULL,
    client_phone VARCHAR(20) NOT NULL,
    
    -- Détails de la demande
    description TEXT NOT NULL,
    device_type VARCHAR(50),
    device_brand VARCHAR(100),
    device_model VARCHAR(100),
    issue_description TEXT NOT NULL,
    urgency VARCHAR(10) DEFAULT 'medium' CHECK (urgency IN ('low', 'medium', 'high')),
    
    -- Statut et suivi
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_review', 'quoted', 'accepted', 'rejected', 'cancelled')),
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    
    -- Réponse du réparateur
    response TEXT,
    estimated_price DECIMAL(10,2),
    estimated_duration INTEGER, -- en jours
    response_date TIMESTAMP WITH TIME ZONE,
    
    -- Métadonnées
    ip_address INET,
    user_agent TEXT,
    source VARCHAR(20) DEFAULT 'website' CHECK (source IN ('website', 'mobile', 'api')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_quote_requests_technician_id ON quote_requests(technician_id);
CREATE INDEX IF NOT EXISTS idx_quote_requests_custom_url ON quote_requests(custom_url);
CREATE INDEX IF NOT EXISTS idx_quote_requests_status ON quote_requests(status);
CREATE INDEX IF NOT EXISTS idx_quote_requests_urgency ON quote_requests(urgency);
CREATE INDEX IF NOT EXISTS idx_quote_requests_created_at ON quote_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_quote_requests_client_email ON quote_requests(client_email);

-- Table pour les pièces jointes des demandes de devis
CREATE TABLE IF NOT EXISTS quote_request_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_request_id UUID NOT NULL REFERENCES quote_requests(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_path TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_quote_request_attachments_quote_request_id ON quote_request_attachments(quote_request_id);

-- Fonction pour générer un numéro de demande unique
CREATE OR REPLACE FUNCTION generate_quote_request_number()
RETURNS TEXT AS $$
DECLARE
    new_number TEXT;
    counter INTEGER := 1;
BEGIN
    LOOP
        -- Format: QR-YYYYMMDD-XXXX (ex: QR-20241201-0001)
        new_number := 'QR-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(counter::TEXT, 4, '0');
        
        -- Vérifier si le numéro existe déjà
        IF NOT EXISTS (SELECT 1 FROM quote_requests WHERE request_number = new_number) THEN
            RETURN new_number;
        END IF;
        
        counter := counter + 1;
        
        -- Sécurité pour éviter les boucles infinies
        IF counter > 9999 THEN
            RAISE EXCEPTION 'Impossible de générer un numéro de demande unique';
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger aux tables
CREATE TRIGGER update_technician_custom_urls_updated_at
    BEFORE UPDATE ON technician_custom_urls
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quote_requests_updated_at
    BEFORE UPDATE ON quote_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) pour la sécurité
ALTER TABLE technician_custom_urls ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_request_attachments ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour technician_custom_urls
CREATE POLICY "Les utilisateurs peuvent voir leurs propres URLs personnalisées" ON technician_custom_urls
    FOR SELECT USING (auth.uid() = technician_id);

CREATE POLICY "Les utilisateurs peuvent créer leurs propres URLs personnalisées" ON technician_custom_urls
    FOR INSERT WITH CHECK (auth.uid() = technician_id);

CREATE POLICY "Les utilisateurs peuvent modifier leurs propres URLs personnalisées" ON technician_custom_urls
    FOR UPDATE USING (auth.uid() = technician_id);

CREATE POLICY "Les utilisateurs peuvent supprimer leurs propres URLs personnalisées" ON technician_custom_urls
    FOR DELETE USING (auth.uid() = technician_id);

-- Politiques RLS pour quote_requests
CREATE POLICY "Les utilisateurs peuvent voir leurs demandes de devis" ON quote_requests
    FOR SELECT USING (auth.uid() = technician_id);

CREATE POLICY "Les utilisateurs peuvent créer des demandes de devis" ON quote_requests
    FOR INSERT WITH CHECK (auth.uid() = technician_id);

CREATE POLICY "Les utilisateurs peuvent modifier leurs demandes de devis" ON quote_requests
    FOR UPDATE USING (auth.uid() = technician_id);

-- Politique spéciale pour permettre l'accès public aux URLs personnalisées (pour le formulaire)
CREATE POLICY "Accès public en lecture aux URLs personnalisées actives" ON technician_custom_urls
    FOR SELECT USING (is_active = true);

-- Politique pour permettre l'insertion de demandes de devis depuis l'extérieur
CREATE POLICY "Insertion publique des demandes de devis" ON quote_requests
    FOR INSERT WITH CHECK (true);

-- Politiques RLS pour quote_request_attachments
CREATE POLICY "Les utilisateurs peuvent voir les pièces jointes de leurs demandes" ON quote_request_attachments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM quote_requests 
            WHERE id = quote_request_attachments.quote_request_id 
            AND technician_id = auth.uid()
        )
    );

CREATE POLICY "Insertion publique des pièces jointes" ON quote_request_attachments
    FOR INSERT WITH CHECK (true);

-- Fonction pour obtenir les statistiques des demandes de devis
CREATE OR REPLACE FUNCTION get_quote_request_stats(technician_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total', COUNT(*),
        'pending', COUNT(*) FILTER (WHERE status = 'pending'),
        'in_review', COUNT(*) FILTER (WHERE status = 'in_review'),
        'quoted', COUNT(*) FILTER (WHERE status = 'quoted'),
        'accepted', COUNT(*) FILTER (WHERE status = 'accepted'),
        'rejected', COUNT(*) FILTER (WHERE status = 'rejected'),
        'by_urgency', json_build_object(
            'low', COUNT(*) FILTER (WHERE urgency = 'low'),
            'medium', COUNT(*) FILTER (WHERE urgency = 'medium'),
            'high', COUNT(*) FILTER (WHERE urgency = 'high')
        ),
        'by_status', json_build_object(
            'pending', COUNT(*) FILTER (WHERE status = 'pending'),
            'in_review', COUNT(*) FILTER (WHERE status = 'in_review'),
            'quoted', COUNT(*) FILTER (WHERE status = 'quoted'),
            'accepted', COUNT(*) FILTER (WHERE status = 'accepted'),
            'rejected', COUNT(*) FILTER (WHERE status = 'rejected'),
            'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled')
        ),
        'monthly', COUNT(*) FILTER (WHERE created_at >= date_trunc('month', NOW())),
        'weekly', COUNT(*) FILTER (WHERE created_at >= date_trunc('week', NOW())),
        'daily', COUNT(*) FILTER (WHERE created_at >= date_trunc('day', NOW()))
    ) INTO result
    FROM quote_requests
    WHERE technician_id = technician_uuid;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour valider une URL personnalisée
CREATE OR REPLACE FUNCTION validate_custom_url(url_text TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Vérifier que l'URL contient seulement des caractères alphanumériques et des tirets
    IF url_text !~ '^[a-zA-Z0-9-]+$' THEN
        RETURN FALSE;
    END IF;
    
    -- Vérifier la longueur (entre 3 et 50 caractères)
    IF LENGTH(url_text) < 3 OR LENGTH(url_text) > 50 THEN
        RETURN FALSE;
    END IF;
    
    -- Vérifier qu'elle ne commence ou ne finit pas par un tiret
    IF url_text ~ '^-|-$' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Contrainte pour valider les URLs personnalisées
ALTER TABLE technician_custom_urls 
ADD CONSTRAINT check_custom_url_format 
CHECK (validate_custom_url(custom_url));

-- Commentaires sur les tables
COMMENT ON TABLE technician_custom_urls IS 'URLs personnalisées pour les réparateurs permettant aux clients de faire des demandes de devis';
COMMENT ON TABLE quote_requests IS 'Demandes de devis envoyées par les clients via les URLs personnalisées';
COMMENT ON TABLE quote_request_attachments IS 'Pièces jointes associées aux demandes de devis';

COMMENT ON COLUMN technician_custom_urls.custom_url IS 'URL personnalisée (ex: repphone, test12)';
COMMENT ON COLUMN quote_requests.request_number IS 'Numéro unique de demande (ex: QR-20241201-0001)';
COMMENT ON COLUMN quote_requests.urgency IS 'Niveau d''urgence: low, medium, high';
COMMENT ON COLUMN quote_requests.status IS 'Statut de la demande: pending, in_review, quoted, accepted, rejected, cancelled';
COMMENT ON COLUMN quote_requests.source IS 'Source de la demande: website, mobile, api';
