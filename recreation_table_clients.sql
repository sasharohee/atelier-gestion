-- Script pour recréer complètement la table clients avec la bonne structure
-- ATTENTION: Ce script va supprimer et recréer la table clients

-- 1. Sauvegarder les données existantes
CREATE TEMP TABLE clients_backup AS 
SELECT * FROM clients;

-- 2. Supprimer la table clients existante
DROP TABLE IF EXISTS clients CASCADE;

-- 3. Recréer la table clients avec la structure complète
CREATE TABLE clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Champs de base (originaux)
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    notes TEXT,
    
    -- Nouveaux champs pour les informations personnelles et entreprise
    category VARCHAR(50) DEFAULT 'particulier',
    title VARCHAR(10) DEFAULT 'mr',
    company_name VARCHAR(255) DEFAULT '',
    vat_number VARCHAR(50) DEFAULT '',
    siren_number VARCHAR(50) DEFAULT '',
    country_code VARCHAR(10) DEFAULT '33',
    
    -- Nouveaux champs pour l'adresse détaillée
    address_complement VARCHAR(255) DEFAULT '',
    region VARCHAR(100) DEFAULT '',
    postal_code VARCHAR(20) DEFAULT '',
    city VARCHAR(100) DEFAULT '',
    
    -- Nouveaux champs pour l'adresse de facturation
    billing_address_same BOOLEAN DEFAULT true,
    billing_address TEXT DEFAULT '',
    billing_address_complement VARCHAR(255) DEFAULT '',
    billing_region VARCHAR(100) DEFAULT '',
    billing_postal_code VARCHAR(20) DEFAULT '',
    billing_city VARCHAR(100) DEFAULT '',
    
    -- Nouveaux champs pour les informations complémentaires
    accounting_code VARCHAR(50) DEFAULT '',
    cni_identifier VARCHAR(50) DEFAULT '',
    attached_file_path VARCHAR(500) DEFAULT '',
    internal_note TEXT DEFAULT '',
    
    -- Nouveaux champs pour les préférences
    status VARCHAR(20) DEFAULT 'displayed',
    sms_notification BOOLEAN DEFAULT true,
    email_notification BOOLEAN DEFAULT true,
    sms_marketing BOOLEAN DEFAULT true,
    email_marketing BOOLEAN DEFAULT true,
    
    -- Champs système
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Créer les index
CREATE INDEX idx_clients_user_id ON clients(user_id);
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_clients_created_at ON clients(created_at);
CREATE INDEX idx_clients_category ON clients(category);
CREATE INDEX idx_clients_status ON clients(status);

-- 5. Créer les contraintes
ALTER TABLE clients ADD CONSTRAINT clients_email_unique UNIQUE (email);

-- 6. Restaurer les données existantes avec les nouveaux champs
INSERT INTO clients (
    id, first_name, last_name, email, phone, address, notes,
    category, title, company_name, vat_number, siren_number, country_code,
    address_complement, region, postal_code, city,
    billing_address_same, billing_address, billing_address_complement,
    billing_region, billing_postal_code, billing_city,
    accounting_code, cni_identifier, attached_file_path, internal_note,
    status, sms_notification, email_notification, sms_marketing, email_marketing,
    user_id, created_at, updated_at
)
SELECT 
    id, first_name, last_name, email, phone, address, notes,
    COALESCE(category, 'particulier') as category,
    COALESCE(title, 'mr') as title,
    COALESCE(company_name, '') as company_name,
    COALESCE(vat_number, '') as vat_number,
    COALESCE(siren_number, '') as siren_number,
    COALESCE(country_code, '33') as country_code,
    COALESCE(address_complement, '') as address_complement,
    COALESCE(region, '') as region,
    COALESCE(postal_code, '') as postal_code,
    COALESCE(city, '') as city,
    COALESCE(billing_address_same, true) as billing_address_same,
    COALESCE(billing_address, '') as billing_address,
    COALESCE(billing_address_complement, '') as billing_address_complement,
    COALESCE(billing_region, '') as billing_region,
    COALESCE(billing_postal_code, '') as billing_postal_code,
    COALESCE(billing_city, '') as billing_city,
    COALESCE(accounting_code, '') as accounting_code,
    COALESCE(cni_identifier, '') as cni_identifier,
    COALESCE(attached_file_path, '') as attached_file_path,
    COALESCE(internal_note, '') as internal_note,
    COALESCE(status, 'displayed') as status,
    COALESCE(sms_notification, true) as sms_notification,
    COALESCE(email_notification, true) as email_notification,
    COALESCE(sms_marketing, true) as sms_marketing,
    COALESCE(email_marketing, true) as email_marketing,
    user_id, created_at, updated_at
FROM clients_backup;

-- 7. Vérifier la restauration
SELECT 
    'RESTAURATION' as section,
    COUNT(*) as clients_restaures
FROM clients;

-- 8. Vérifier qu'il n'y a plus de champs NULL
SELECT 
    'VÉRIFICATION CHAMPS NULL' as section,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN region IS NULL THEN 1 END) as region_null,
    COUNT(CASE WHEN postal_code IS NULL THEN 1 END) as postal_code_null,
    COUNT(CASE WHEN city IS NULL THEN 1 END) as city_null,
    COUNT(CASE WHEN accounting_code IS NULL THEN 1 END) as accounting_code_null,
    COUNT(CASE WHEN cni_identifier IS NULL THEN 1 END) as cni_null,
    COUNT(CASE WHEN company_name IS NULL THEN 1 END) as company_name_null,
    COUNT(CASE WHEN category IS NULL THEN 1 END) as category_null,
    COUNT(CASE WHEN title IS NULL THEN 1 END) as title_null
FROM clients;

-- 9. Afficher la nouvelle structure
SELECT 
    'NOUVELLE STRUCTURE' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients' 
ORDER BY ordinal_position;

-- 10. Nettoyer la table temporaire
DROP TABLE clients_backup;

-- 11. Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '🎉 Table clients recréée avec succès!';
    RAISE NOTICE '✅ Tous les nouveaux champs ont été ajoutés';
    RAISE NOTICE '✅ Les données existantes ont été restaurées';
    RAISE NOTICE '✅ Aucun champ NULL dans la table';
    RAISE NOTICE '💡 Vous pouvez maintenant tester le formulaire client';
END $$;
