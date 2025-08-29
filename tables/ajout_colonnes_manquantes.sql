-- Ajout des colonnes manquantes et conversion VARCHAR vers TEXT
-- Pour résoudre le problème d'affichage des nouveaux champs

BEGIN;

-- 1. D'abord, vérifions quelles colonnes existent déjà
DO $$
DECLARE
    col_exists BOOLEAN;
BEGIN
    -- Vérification et ajout de chaque colonne manquante
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'region'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.clients ADD COLUMN region TEXT;
        RAISE NOTICE 'Colonne region ajoutée';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'postal_code'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.clients ADD COLUMN postal_code TEXT;
        RAISE NOTICE 'Colonne postal_code ajoutée';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'city'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.clients ADD COLUMN city TEXT;
        RAISE NOTICE 'Colonne city ajoutée';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'accounting_code'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.clients ADD COLUMN accounting_code TEXT;
        RAISE NOTICE 'Colonne accounting_code ajoutée';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'cni'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.clients ADD COLUMN cni TEXT;
        RAISE NOTICE 'Colonne cni ajoutée';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'address_complement'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.clients ADD COLUMN address_complement TEXT;
        RAISE NOTICE 'Colonne address_complement ajoutée';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'company_name'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.clients ADD COLUMN company_name TEXT;
        RAISE NOTICE 'Colonne company_name ajoutée';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'siren'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.clients ADD COLUMN siren TEXT;
        RAISE NOTICE 'Colonne siren ajoutée';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'vat'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.clients ADD COLUMN vat TEXT;
        RAISE NOTICE 'Colonne vat ajoutée';
    END IF;
END $$;

-- 2. Conversion des colonnes VARCHAR existantes en TEXT (si elles existent)
DO $$
DECLARE
    col_type TEXT;
BEGIN
    -- Vérification et conversion de chaque colonne
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'region';
    
    IF col_type = 'character varying' THEN
        ALTER TABLE public.clients ALTER COLUMN region TYPE TEXT;
        RAISE NOTICE 'Colonne region convertie de VARCHAR vers TEXT';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'postal_code';
    
    IF col_type = 'character varying' THEN
        ALTER TABLE public.clients ALTER COLUMN postal_code TYPE TEXT;
        RAISE NOTICE 'Colonne postal_code convertie de VARCHAR vers TEXT';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'city';
    
    IF col_type = 'character varying' THEN
        ALTER TABLE public.clients ALTER COLUMN city TYPE TEXT;
        RAISE NOTICE 'Colonne city convertie de VARCHAR vers TEXT';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'accounting_code';
    
    IF col_type = 'character varying' THEN
        ALTER TABLE public.clients ALTER COLUMN accounting_code TYPE TEXT;
        RAISE NOTICE 'Colonne accounting_code convertie de VARCHAR vers TEXT';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'cni';
    
    IF col_type = 'character varying' THEN
        ALTER TABLE public.clients ALTER COLUMN cni TYPE TEXT;
        RAISE NOTICE 'Colonne cni convertie de VARCHAR vers TEXT';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'address_complement';
    
    IF col_type = 'character varying' THEN
        ALTER TABLE public.clients ALTER COLUMN address_complement TYPE TEXT;
        RAISE NOTICE 'Colonne address_complement convertie de VARCHAR vers TEXT';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'company_name';
    
    IF col_type = 'character varying' THEN
        ALTER TABLE public.clients ALTER COLUMN company_name TYPE TEXT;
        RAISE NOTICE 'Colonne company_name convertie de VARCHAR vers TEXT';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'siren';
    
    IF col_type = 'character varying' THEN
        ALTER TABLE public.clients ALTER COLUMN siren TYPE TEXT;
        RAISE NOTICE 'Colonne siren convertie de VARCHAR vers TEXT';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'vat';
    
    IF col_type = 'character varying' THEN
        ALTER TABLE public.clients ALTER COLUMN vat TYPE TEXT;
        RAISE NOTICE 'Colonne vat convertie de VARCHAR vers TEXT';
    END IF;
END $$;

-- 3. Vérification finale
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
AND column_name IN (
    'region', 
    'postal_code', 
    'city', 
    'accounting_code', 
    'cni', 
    'address_complement', 
    'company_name', 
    'siren', 
    'vat'
)
ORDER BY column_name;

COMMIT;
