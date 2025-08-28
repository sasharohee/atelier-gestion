-- =====================================================
-- AJOUT DES COLONNES MANQUANTES À LA TABLE CLIENTS
-- =====================================================
-- Ce script ajoute toutes les colonnes manquantes nécessaires pour le formulaire ClientForm
-- Date: 2025-01-27
-- =====================================================

-- Vérifier la structure actuelle de la table clients
SELECT '=== STRUCTURE ACTUELLE ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- =====================================================
-- 1. AJOUT DES COLONNES POUR LES INFORMATIONS PERSONNELLES ET ENTREPRISE
-- =====================================================

-- Catégorie client
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'category'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN category TEXT DEFAULT 'particulier';
        RAISE NOTICE '✅ Colonne category ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne category existe déjà dans clients';
    END IF;
END $$;

-- Titre (M., Mme, etc.)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'title'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN title TEXT DEFAULT 'mr';
        RAISE NOTICE '✅ Colonne title ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne title existe déjà dans clients';
    END IF;
END $$;

-- Nom de l'entreprise
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'company_name'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN company_name TEXT;
        RAISE NOTICE '✅ Colonne company_name ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne company_name existe déjà dans clients';
    END IF;
END $$;

-- Numéro de TVA
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'vat_number'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN vat_number TEXT;
        RAISE NOTICE '✅ Colonne vat_number ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne vat_number existe déjà dans clients';
    END IF;
END $$;

-- Numéro SIREN
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'siren_number'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN siren_number TEXT;
        RAISE NOTICE '✅ Colonne siren_number ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne siren_number existe déjà dans clients';
    END IF;
END $$;

-- Code pays
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'country_code'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN country_code TEXT DEFAULT '33';
        RAISE NOTICE '✅ Colonne country_code ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne country_code existe déjà dans clients';
    END IF;
END $$;

-- =====================================================
-- 2. AJOUT DES COLONNES POUR L'ADRESSE DÉTAILLÉE
-- =====================================================

-- Complément d'adresse
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'address_complement'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN address_complement TEXT;
        RAISE NOTICE '✅ Colonne address_complement ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne address_complement existe déjà dans clients';
    END IF;
END $$;

-- Région
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'region'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN region TEXT;
        RAISE NOTICE '✅ Colonne region ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne region existe déjà dans clients';
    END IF;
END $$;

-- Code postal
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'postal_code'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN postal_code TEXT;
        RAISE NOTICE '✅ Colonne postal_code ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne postal_code existe déjà dans clients';
    END IF;
END $$;

-- Ville
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'city'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN city TEXT;
        RAISE NOTICE '✅ Colonne city ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne city existe déjà dans clients';
    END IF;
END $$;

-- =====================================================
-- 3. AJOUT DES COLONNES POUR L'ADRESSE DE FACTURATION
-- =====================================================

-- Adresse de facturation identique
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'billing_address_same'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN billing_address_same BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne billing_address_same ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne billing_address_same existe déjà dans clients';
    END IF;
END $$;

-- Adresse de facturation
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'billing_address'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN billing_address TEXT;
        RAISE NOTICE '✅ Colonne billing_address ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne billing_address existe déjà dans clients';
    END IF;
END $$;

-- Complément adresse de facturation
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'billing_address_complement'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN billing_address_complement TEXT;
        RAISE NOTICE '✅ Colonne billing_address_complement ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne billing_address_complement existe déjà dans clients';
    END IF;
END $$;

-- Région de facturation
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'billing_region'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN billing_region TEXT;
        RAISE NOTICE '✅ Colonne billing_region ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne billing_region existe déjà dans clients';
    END IF;
END $$;

-- Code postal de facturation
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'billing_postal_code'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN billing_postal_code TEXT;
        RAISE NOTICE '✅ Colonne billing_postal_code ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne billing_postal_code existe déjà dans clients';
    END IF;
END $$;

-- Ville de facturation
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'billing_city'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN billing_city TEXT;
        RAISE NOTICE '✅ Colonne billing_city ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne billing_city existe déjà dans clients';
    END IF;
END $$;

-- =====================================================
-- 4. AJOUT DES COLONNES POUR LES INFORMATIONS COMPLÉMENTAIRES
-- =====================================================

-- Code comptable
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'accounting_code'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN accounting_code TEXT;
        RAISE NOTICE '✅ Colonne accounting_code ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne accounting_code existe déjà dans clients';
    END IF;
END $$;

-- Identifiant CNI
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'cni_identifier'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN cni_identifier TEXT;
        RAISE NOTICE '✅ Colonne cni_identifier ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne cni_identifier existe déjà dans clients';
    END IF;
END $$;

-- Chemin du fichier attaché
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'attached_file_path'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN attached_file_path TEXT;
        RAISE NOTICE '✅ Colonne attached_file_path ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne attached_file_path existe déjà dans clients';
    END IF;
END $$;

-- Note interne
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'internal_note'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN internal_note TEXT;
        RAISE NOTICE '✅ Colonne internal_note ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne internal_note existe déjà dans clients';
    END IF;
END $$;

-- =====================================================
-- 5. AJOUT DES COLONNES POUR LES PRÉFÉRENCES
-- =====================================================

-- Statut (affiché/masqué)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'status'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN status TEXT DEFAULT 'displayed';
        RAISE NOTICE '✅ Colonne status ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne status existe déjà dans clients';
    END IF;
END $$;

-- Notification SMS
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'sms_notification'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN sms_notification BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne sms_notification ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne sms_notification existe déjà dans clients';
    END IF;
END $$;

-- Notification Email
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'email_notification'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN email_notification BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne email_notification ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne email_notification existe déjà dans clients';
    END IF;
END $$;

-- Marketing SMS
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'sms_marketing'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN sms_marketing BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne sms_marketing ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne sms_marketing existe déjà dans clients';
    END IF;
END $$;

-- Marketing Email
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'email_marketing'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN email_marketing BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne email_marketing ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne email_marketing existe déjà dans clients';
    END IF;
END $$;

-- =====================================================
-- 6. VÉRIFICATION FINALE
-- =====================================================

SELECT '=== STRUCTURE FINALE ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- =====================================================
-- 7. RAFRAÎCHIR LE CACHE POSTGREST
-- =====================================================

NOTIFY pgrst, 'reload schema';

SELECT '✅ Script terminé avec succès !' as status;
