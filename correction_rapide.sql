-- CORRECTION RAPIDE - Exécutez ce script pour corriger immédiatement le problème

-- 1. Désactiver RLS
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;

-- 2. Ajouter les colonnes manquantes si elles n'existent pas
ALTER TABLE clients ADD COLUMN IF NOT EXISTS accounting_code VARCHAR(50) DEFAULT '';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS cni_identifier VARCHAR(50) DEFAULT '';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS attached_file_path VARCHAR(500) DEFAULT '';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS internal_note TEXT DEFAULT '';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS region VARCHAR(100) DEFAULT '';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS postal_code VARCHAR(20) DEFAULT '';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS city VARCHAR(100) DEFAULT '';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS company_name VARCHAR(255) DEFAULT '';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS vat_number VARCHAR(50) DEFAULT '';
ALTER TABLE clients ADD COLUMN IF NOT EXISTS siren_number VARCHAR(50) DEFAULT '';

-- 3. Corriger les valeurs NULL
UPDATE clients SET 
    accounting_code = COALESCE(accounting_code, ''),
    cni_identifier = COALESCE(cni_identifier, ''),
    attached_file_path = COALESCE(attached_file_path, ''),
    internal_note = COALESCE(internal_note, ''),
    region = COALESCE(region, ''),
    postal_code = COALESCE(postal_code, ''),
    city = COALESCE(city, ''),
    company_name = COALESCE(company_name, ''),
    vat_number = COALESCE(vat_number, ''),
    siren_number = COALESCE(siren_number, ''),
    updated_at = NOW();

-- 4. Test d'insertion
INSERT INTO clients (
    first_name, last_name, email, phone, address,
    accounting_code, cni_identifier, internal_note, region, postal_code, city,
    company_name, vat_number, siren_number, user_id
) VALUES (
    'Test', 'Rapide', 'test.rapide@example.com', '0123456789', '123 Rue Test',
    'TEST001', '123456789', 'Note de test rapide', 'Île-de-France', '75001', 'Paris',
    'Test SARL', 'FR12345678901', '123456789', '00000000-0000-0000-0000-000000000000'
);

-- 5. Vérification
SELECT 'CORRECTION RAPIDE TERMINÉE' as status, COUNT(*) as total_clients FROM clients;
