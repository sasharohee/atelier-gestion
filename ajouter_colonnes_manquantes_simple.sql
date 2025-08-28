-- =====================================================
-- AJOUT DES COLONNES MANQUANTES - VERSION SIMPLE
-- =====================================================
-- Ce script ajoute directement toutes les colonnes manquantes
-- Date: 2025-01-27
-- =====================================================

-- Ajouter toutes les colonnes manquantes en une seule fois
ALTER TABLE public.clients 
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'particulier',
ADD COLUMN IF NOT EXISTS title TEXT DEFAULT 'mr',
ADD COLUMN IF NOT EXISTS company_name TEXT,
ADD COLUMN IF NOT EXISTS vat_number TEXT,
ADD COLUMN IF NOT EXISTS siren_number TEXT,
ADD COLUMN IF NOT EXISTS country_code TEXT DEFAULT '33',
ADD COLUMN IF NOT EXISTS address_complement TEXT,
ADD COLUMN IF NOT EXISTS region TEXT,
ADD COLUMN IF NOT EXISTS postal_code TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS billing_address_same BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS billing_address TEXT,
ADD COLUMN IF NOT EXISTS billing_address_complement TEXT,
ADD COLUMN IF NOT EXISTS billing_region TEXT,
ADD COLUMN IF NOT EXISTS billing_postal_code TEXT,
ADD COLUMN IF NOT EXISTS billing_city TEXT,
ADD COLUMN IF NOT EXISTS accounting_code TEXT,
ADD COLUMN IF NOT EXISTS cni_identifier TEXT,
ADD COLUMN IF NOT EXISTS attached_file_path TEXT,
ADD COLUMN IF NOT EXISTS internal_note TEXT,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'displayed',
ADD COLUMN IF NOT EXISTS sms_notification BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS email_notification BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS sms_marketing BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS email_marketing BOOLEAN DEFAULT true;

-- Vérifier que toutes les colonnes ont été ajoutées
SELECT '=== VÉRIFICATION FINALE ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';

SELECT '✅ Toutes les colonnes ont été ajoutées avec succès !' as status;
