-- Script pour vérifier et corriger la structure de la table clients
-- Ce script vérifie si tous les champs nécessaires existent et les ajoute si nécessaire

-- 1. Vérifier la structure actuelle de la table
SELECT '=== STRUCTURE ACTUELLE DE LA TABLE CLIENTS ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients'
ORDER BY ordinal_position;

-- 2. Vérifier si les champs d'entreprise existent
SELECT '=== VÉRIFICATION DES CHAMPS ENTREPRISE ===' as etape;

SELECT 
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'company_name'
    ) THEN '✅ company_name existe' ELSE '❌ company_name manquant' END as company_name_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'vat_number'
    ) THEN '✅ vat_number existe' ELSE '❌ vat_number manquant' END as vat_number_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'siren_number'
    ) THEN '✅ siren_number existe' ELSE '❌ siren_number manquant' END as siren_number_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'address_complement'
    ) THEN '✅ address_complement existe' ELSE '❌ address_complement manquant' END as address_complement_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'region'
    ) THEN '✅ region existe' ELSE '❌ region manquant' END as region_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'postal_code'
    ) THEN '✅ postal_code existe' ELSE '❌ postal_code manquant' END as postal_code_status,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'city'
    ) THEN '✅ city existe' ELSE '❌ city manquant' END as city_status;

-- 3. Ajouter les champs manquants
SELECT '=== AJOUT DES CHAMPS MANQUANTS ===' as etape;

-- Ajouter company_name si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'company_name'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN company_name VARCHAR(255) DEFAULT '';
        RAISE NOTICE '✅ Colonne company_name ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne company_name existe déjà';
    END IF;
END $$;

-- Ajouter vat_number si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'vat_number'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN vat_number VARCHAR(50) DEFAULT '';
        RAISE NOTICE '✅ Colonne vat_number ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne vat_number existe déjà';
    END IF;
END $$;

-- Ajouter siren_number si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'siren_number'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN siren_number VARCHAR(50) DEFAULT '';
        RAISE NOTICE '✅ Colonne siren_number ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne siren_number existe déjà';
    END IF;
END $$;

-- Ajouter address_complement si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'address_complement'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN address_complement VARCHAR(255) DEFAULT '';
        RAISE NOTICE '✅ Colonne address_complement ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne address_complement existe déjà';
    END IF;
END $$;

-- Ajouter region si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'region'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN region VARCHAR(100) DEFAULT '';
        RAISE NOTICE '✅ Colonne region ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne region existe déjà';
    END IF;
END $$;

-- Ajouter postal_code si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'postal_code'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN postal_code VARCHAR(20) DEFAULT '';
        RAISE NOTICE '✅ Colonne postal_code ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne postal_code existe déjà';
    END IF;
END $$;

-- Ajouter city si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'city'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN city VARCHAR(100) DEFAULT '';
        RAISE NOTICE '✅ Colonne city ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne city existe déjà';
    END IF;
END $$;

-- Ajouter category si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'category'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN category VARCHAR(50) DEFAULT 'particulier';
        RAISE NOTICE '✅ Colonne category ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne category existe déjà';
    END IF;
END $$;

-- Ajouter title si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'title'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN title VARCHAR(10) DEFAULT 'mr';
        RAISE NOTICE '✅ Colonne title ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne title existe déjà';
    END IF;
END $$;

-- Ajouter country_code si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'country_code'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN country_code VARCHAR(10) DEFAULT '33';
        RAISE NOTICE '✅ Colonne country_code ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne country_code existe déjà';
    END IF;
END $$;

-- Ajouter accounting_code si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'accounting_code'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN accounting_code VARCHAR(50) DEFAULT '';
        RAISE NOTICE '✅ Colonne accounting_code ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne accounting_code existe déjà';
    END IF;
END $$;

-- Ajouter cni_identifier si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'cni_identifier'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN cni_identifier VARCHAR(50) DEFAULT '';
        RAISE NOTICE '✅ Colonne cni_identifier ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne cni_identifier existe déjà';
    END IF;
END $$;

-- Ajouter internal_note si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'internal_note'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN internal_note TEXT DEFAULT '';
        RAISE NOTICE '✅ Colonne internal_note ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne internal_note existe déjà';
    END IF;
END $$;

-- Ajouter status si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'status'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN status VARCHAR(20) DEFAULT 'displayed';
        RAISE NOTICE '✅ Colonne status ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne status existe déjà';
    END IF;
END $$;

-- Ajouter les champs de préférences si manquants
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'sms_notification'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN sms_notification BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne sms_notification ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne sms_notification existe déjà';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'email_notification'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN email_notification BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne email_notification ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne email_notification existe déjà';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'sms_marketing'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN sms_marketing BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne sms_marketing ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne sms_marketing existe déjà';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'email_marketing'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN email_marketing BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Colonne email_marketing ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne email_marketing existe déjà';
    END IF;
END $$;

-- 4. Vérifier la structure finale
SELECT '=== STRUCTURE FINALE DE LA TABLE CLIENTS ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients'
ORDER BY ordinal_position;

-- 5. Test des données
SELECT '=== TEST DES DONNÉES ===' as etape;

SELECT 
    id,
    first_name,
    last_name,
    email,
    company_name,
    vat_number,
    siren_number,
    address_complement,
    region,
    postal_code,
    city,
    accounting_code,
    cni_identifier,
    internal_note
FROM public.clients 
LIMIT 5;

SELECT '✅ Script terminé avec succès!' as resultat;
