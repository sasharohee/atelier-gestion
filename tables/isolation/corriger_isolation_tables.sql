-- CORRECTION DE L'ISOLATION DES TABLES
-- Ce script ajoute les colonnes user_id manquantes et corrige l'isolation

-- ============================================================================
-- 1. VÉRIFICATION ET AJOUT DES COLONNES USER_ID MANQUANTES
-- ============================================================================

-- Vérifier si la colonne user_id existe dans chaque table et l'ajouter si nécessaire

-- Table clients
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table clients';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà dans la table clients';
    END IF;
END $$;

-- Table devices
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table devices';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà dans la table devices';
    END IF;
END $$;

-- Table services
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'services' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.services ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table services';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà dans la table services';
    END IF;
END $$;

-- Table parts
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'parts' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.parts ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table parts';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà dans la table parts';
    END IF;
END $$;

-- Table products
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.products ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table products';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà dans la table products';
    END IF;
END $$;

-- Table repairs
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table repairs';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà dans la table repairs';
    END IF;
END $$;

-- Table appointments
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà dans la table appointments';
    END IF;
END $$;

-- Table sales
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'sales' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table sales';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà dans la table sales';
    END IF;
END $$;

-- Table messages
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'messages' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.messages ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à la table messages';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà dans la table messages';
    END IF;
END $$;

-- ============================================================================
-- 2. ASSIGNATION DES DONNÉES EXISTANTES À UN UTILISATEUR PAR DÉFAUT
-- ============================================================================

-- Récupérer l'ID du premier utilisateur (ou créer un utilisateur par défaut)
DO $$
DECLARE
    default_user_id UUID;
BEGIN
    -- Essayer de récupérer le premier utilisateur
    SELECT id INTO default_user_id FROM public.users LIMIT 1;
    
    -- Si aucun utilisateur n'existe, créer un utilisateur par défaut
    IF default_user_id IS NULL THEN
        INSERT INTO public.users (id, first_name, last_name, email, role, created_at, updated_at)
        VALUES (
            gen_random_uuid(),
            'Utilisateur',
            'Par Défaut',
            'default@atelier.com',
            'admin',
            NOW(),
            NOW()
        ) RETURNING id INTO default_user_id;
        RAISE NOTICE 'Utilisateur par défaut créé avec l''ID: %', default_user_id;
    END IF;
    
    -- Assigner les données existantes à cet utilisateur
    UPDATE public.clients SET user_id = default_user_id WHERE user_id IS NULL;
    UPDATE public.devices SET user_id = default_user_id WHERE user_id IS NULL;
    UPDATE public.services SET user_id = default_user_id WHERE user_id IS NULL;
    UPDATE public.parts SET user_id = default_user_id WHERE user_id IS NULL;
    UPDATE public.products SET user_id = default_user_id WHERE user_id IS NULL;
    UPDATE public.repairs SET user_id = default_user_id WHERE user_id IS NULL;
    UPDATE public.appointments SET user_id = default_user_id WHERE user_id IS NULL;
    UPDATE public.sales SET user_id = default_user_id WHERE user_id IS NULL;
    UPDATE public.messages SET user_id = default_user_id WHERE user_id IS NULL;
    UPDATE public.system_settings SET user_id = default_user_id WHERE user_id IS NULL;
    
    RAISE NOTICE 'Toutes les données existantes assignées à l''utilisateur: %', default_user_id;
END $$;

-- ============================================================================
-- 3. CRÉATION D'INDEX POUR OPTIMISER LES PERFORMANCES
-- ============================================================================

-- Créer des index sur les colonnes user_id pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_services_user_id ON public.services(user_id);
CREATE INDEX IF NOT EXISTS idx_parts_user_id ON public.parts(user_id);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON public.repairs(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON public.appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON public.sales(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_user_id ON public.messages(user_id);
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON public.system_settings(user_id);

-- ============================================================================
-- 4. VÉRIFICATION FINALE
-- ============================================================================

-- Vérifier que toutes les colonnes user_id existent maintenant
SELECT 
    'Vérification finale' as check_type,
    table_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
                AND table_name = t.table_name 
                AND column_name = 'user_id'
        ) THEN 'OK'
        ELSE 'MANQUANT'
    END as user_id_status
FROM (
    SELECT 'clients' as table_name
    UNION ALL SELECT 'devices'
    UNION ALL SELECT 'services'
    UNION ALL SELECT 'parts'
    UNION ALL SELECT 'products'
    UNION ALL SELECT 'repairs'
    UNION ALL SELECT 'appointments'
    UNION ALL SELECT 'sales'
    UNION ALL SELECT 'messages'
    UNION ALL SELECT 'system_settings'
) t
ORDER BY table_name;

-- Vérifier qu'il n'y a plus de données sans user_id
SELECT 
    'Données sans user_id' as check_type,
    'clients' as table_name,
    COUNT(*) as count
FROM public.clients 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'devices' as table_name,
    COUNT(*) as count
FROM public.devices 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'services' as table_name,
    COUNT(*) as count
FROM public.services 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'parts' as table_name,
    COUNT(*) as count
FROM public.parts 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'products' as table_name,
    COUNT(*) as count
FROM public.products 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'repairs' as table_name,
    COUNT(*) as count
FROM public.repairs 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'appointments' as table_name,
    COUNT(*) as count
FROM public.appointments 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'sales' as table_name,
    COUNT(*) as count
FROM public.sales 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'messages' as table_name,
    COUNT(*) as count
FROM public.messages 
WHERE user_id IS NULL
UNION ALL
SELECT 
    'Données sans user_id' as check_type,
    'system_settings' as table_name,
    COUNT(*) as count
FROM public.system_settings 
WHERE user_id IS NULL;
