-- Restauration de la table clients à son état d'origine
-- Suppression des colonnes ajoutées et restauration des types VARCHAR

BEGIN;

-- 1. Suppression des colonnes ajoutées (si elles existent)
DO $$
DECLARE
    col_exists BOOLEAN;
BEGIN
    -- Suppression de chaque colonne ajoutée
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'cni'
    ) INTO col_exists;
    
    IF col_exists THEN
        ALTER TABLE public.clients DROP COLUMN cni;
        RAISE NOTICE 'Colonne cni supprimée';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'siren'
    ) INTO col_exists;
    
    IF col_exists THEN
        ALTER TABLE public.clients DROP COLUMN siren;
        RAISE NOTICE 'Colonne siren supprimée';
    END IF;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'vat'
    ) INTO col_exists;
    
    IF col_exists THEN
        ALTER TABLE public.clients DROP COLUMN vat;
        RAISE NOTICE 'Colonne vat supprimée';
    END IF;
END $$;

-- 2. Restauration des colonnes VARCHAR (si elles ont été converties en TEXT)
DO $$
DECLARE
    col_type TEXT;
BEGIN
    -- Restauration de chaque colonne
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'region';
    
    IF col_type = 'text' THEN
        ALTER TABLE public.clients ALTER COLUMN region TYPE VARCHAR(255);
        RAISE NOTICE 'Colonne region restaurée en VARCHAR';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'postal_code';
    
    IF col_type = 'text' THEN
        ALTER TABLE public.clients ALTER COLUMN postal_code TYPE VARCHAR(10);
        RAISE NOTICE 'Colonne postal_code restaurée en VARCHAR';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'city';
    
    IF col_type = 'text' THEN
        ALTER TABLE public.clients ALTER COLUMN city TYPE VARCHAR(100);
        RAISE NOTICE 'Colonne city restaurée en VARCHAR';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'accounting_code';
    
    IF col_type = 'text' THEN
        ALTER TABLE public.clients ALTER COLUMN accounting_code TYPE VARCHAR(50);
        RAISE NOTICE 'Colonne accounting_code restaurée en VARCHAR';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'address_complement';
    
    IF col_type = 'text' THEN
        ALTER TABLE public.clients ALTER COLUMN address_complement TYPE VARCHAR(255);
        RAISE NOTICE 'Colonne address_complement restaurée en VARCHAR';
    END IF;
    
    SELECT data_type INTO col_type 
    FROM information_schema.columns 
    WHERE table_name = 'clients' 
    AND column_name = 'company_name';
    
    IF col_type = 'text' THEN
        ALTER TABLE public.clients ALTER COLUMN company_name TYPE VARCHAR(255);
        RAISE NOTICE 'Colonne company_name restaurée en VARCHAR';
    END IF;
END $$;

-- 3. Vérification de l'état final
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
AND column_name IN (
    'region', 
    'postal_code', 
    'city', 
    'accounting_code', 
    'address_complement', 
    'company_name'
)
ORDER BY column_name;

COMMIT;
