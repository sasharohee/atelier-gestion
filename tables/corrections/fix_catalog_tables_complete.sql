-- CORRECTION COMPLÈTE DES TABLES DU CATALOGUE
-- Ce script corrige toutes les tables du catalogue pour résoudre les erreurs d'insertion

-- ============================================================================
-- 1. CORRECTION DE LA TABLE PRODUCTS
-- ============================================================================

-- Ajouter user_id si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.products ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à products';
    END IF;
END $$;

-- Ajouter is_active si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.products ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Colonne is_active ajoutée à products';
    END IF;
END $$;

-- Ajouter stock_quantity si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'stock_quantity'
    ) THEN
        ALTER TABLE public.products ADD COLUMN stock_quantity INTEGER DEFAULT 0;
        RAISE NOTICE 'Colonne stock_quantity ajoutée à products';
    END IF;
END $$;

-- ============================================================================
-- 2. CORRECTION DE LA TABLE PARTS
-- ============================================================================

-- Ajouter user_id si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'parts' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.parts ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à parts';
    END IF;
END $$;

-- Ajouter is_active si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'parts' 
            AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.parts ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Colonne is_active ajoutée à parts';
    END IF;
END $$;

-- Ajouter part_number si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'parts' 
            AND column_name = 'part_number'
    ) THEN
        ALTER TABLE public.parts ADD COLUMN part_number TEXT;
        RAISE NOTICE 'Colonne part_number ajoutée à parts';
    END IF;
END $$;

-- Ajouter brand si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'parts' 
            AND column_name = 'brand'
    ) THEN
        ALTER TABLE public.parts ADD COLUMN brand TEXT;
        RAISE NOTICE 'Colonne brand ajoutée à parts';
    END IF;
END $$;

-- Ajouter compatible_devices si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'parts' 
            AND column_name = 'compatible_devices'
    ) THEN
        ALTER TABLE public.parts ADD COLUMN compatible_devices TEXT[];
        RAISE NOTICE 'Colonne compatible_devices ajoutée à parts';
    END IF;
END $$;

-- Ajouter min_stock_level si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'parts' 
            AND column_name = 'min_stock_level'
    ) THEN
        ALTER TABLE public.parts ADD COLUMN min_stock_level INTEGER DEFAULT 5;
        RAISE NOTICE 'Colonne min_stock_level ajoutée à parts';
    END IF;
END $$;

-- Ajouter supplier si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'parts' 
            AND column_name = 'supplier'
    ) THEN
        ALTER TABLE public.parts ADD COLUMN supplier TEXT;
        RAISE NOTICE 'Colonne supplier ajoutée à parts';
    END IF;
END $$;

-- ============================================================================
-- 3. CORRECTION DE LA TABLE SERVICES
-- ============================================================================

-- Ajouter user_id si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'services' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.services ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à services';
    END IF;
END $$;

-- Ajouter is_active si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'services' 
            AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.services ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Colonne is_active ajoutée à services';
    END IF;
END $$;

-- Ajouter duration si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'services' 
            AND column_name = 'duration'
    ) THEN
        ALTER TABLE public.services ADD COLUMN duration INTEGER DEFAULT 60;
        RAISE NOTICE 'Colonne duration ajoutée à services';
    END IF;
END $$;

-- Ajouter category si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'services' 
            AND column_name = 'category'
    ) THEN
        ALTER TABLE public.services ADD COLUMN category TEXT;
        RAISE NOTICE 'Colonne category ajoutée à services';
    END IF;
END $$;

-- Ajouter applicable_devices si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'services' 
            AND column_name = 'applicable_devices'
    ) THEN
        ALTER TABLE public.services ADD COLUMN applicable_devices TEXT[];
        RAISE NOTICE 'Colonne applicable_devices ajoutée à services';
    END IF;
END $$;

-- ============================================================================
-- 4. CORRECTION DE LA TABLE DEVICES
-- ============================================================================

-- Ajouter user_id si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à devices';
    END IF;
END $$;

-- Ajouter brand si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'brand'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN brand TEXT;
        RAISE NOTICE 'Colonne brand ajoutée à devices';
    END IF;
END $$;

-- Ajouter model si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'model'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN model TEXT;
        RAISE NOTICE 'Colonne model ajoutée à devices';
    END IF;
END $$;

-- Ajouter serial_number si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'serial_number'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN serial_number TEXT;
        RAISE NOTICE 'Colonne serial_number ajoutée à devices';
    END IF;
END $$;

-- Ajouter type si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'type'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN type TEXT DEFAULT 'other';
        RAISE NOTICE 'Colonne type ajoutée à devices';
    END IF;
END $$;

-- Ajouter specifications si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'specifications'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN specifications JSONB;
        RAISE NOTICE 'Colonne specifications ajoutée à devices';
    END IF;
END $$;

-- ============================================================================
-- 5. CORRECTION DE LA TABLE CLIENTS
-- ============================================================================

-- Ajouter user_id si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN user_id UUID REFERENCES public.users(id);
        RAISE NOTICE 'Colonne user_id ajoutée à clients';
    END IF;
END $$;

-- Ajouter first_name si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'first_name'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN first_name TEXT;
        RAISE NOTICE 'Colonne first_name ajoutée à clients';
    END IF;
END $$;

-- Ajouter last_name si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'last_name'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN last_name TEXT;
        RAISE NOTICE 'Colonne last_name ajoutée à clients';
    END IF;
END $$;

-- Ajouter phone si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'phone'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN phone TEXT;
        RAISE NOTICE 'Colonne phone ajoutée à clients';
    END IF;
END $$;

-- Ajouter address si manquant
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'address'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN address TEXT;
        RAISE NOTICE 'Colonne address ajoutée à clients';
    END IF;
END $$;

-- ============================================================================
-- 6. RÉFRESH DU CACHE POSTGREST
-- ============================================================================

-- Notifier PostgREST de rafraîchir son cache de schéma
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- 7. VÉRIFICATION FINALE
-- ============================================================================

-- Vérifier la structure de toutes les tables
SELECT 
    'Structure finale' as check_type,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('products', 'parts', 'services', 'devices', 'clients')
ORDER BY table_name, ordinal_position;

-- ============================================================================
-- 8. TEST D'INSERTION POUR CHAQUE TABLE
-- ============================================================================

-- Test products
INSERT INTO public.products (
    name, description, category, price, stock_quantity, is_active, user_id
) VALUES (
    'Test Product', 'Test', 'test', 10.00, 5, true, 
    (SELECT id FROM public.users LIMIT 1)
) ON CONFLICT DO NOTHING;

-- Test parts
INSERT INTO public.parts (
    name, description, part_number, brand, compatible_devices, 
    stock_quantity, min_stock_level, price, supplier, is_active, user_id
) VALUES (
    'Test Part', 'Test', 'TEST001', 'Test Brand', ARRAY['smartphone'], 
    10, 5, 15.00, 'Test Supplier', true, 
    (SELECT id FROM public.users LIMIT 1)
) ON CONFLICT DO NOTHING;

-- Test services
INSERT INTO public.services (
    name, description, duration, price, category, 
    applicable_devices, is_active, user_id
) VALUES (
    'Test Service', 'Test', 60, 25.00, 'test', 
    ARRAY['smartphone'], true, 
    (SELECT id FROM public.users LIMIT 1)
) ON CONFLICT DO NOTHING;

-- Test devices
INSERT INTO public.devices (
    brand, model, serial_number, type, specifications, user_id
) VALUES (
    'Test Brand', 'Test Model', 'TEST123', 'smartphone', 
    '{"ram": "4GB"}', 
    (SELECT id FROM public.users LIMIT 1)
) ON CONFLICT DO NOTHING;

-- Test clients
INSERT INTO public.clients (
    first_name, last_name, email, phone, address, user_id
) VALUES (
    'Test', 'Client', 'test@test.com', '123456789', 'Test Address', 
    (SELECT id FROM public.users LIMIT 1)
) ON CONFLICT DO NOTHING;

-- Vérifier les insertions
SELECT 'Test products' as table_name, COUNT(*) as count FROM public.products WHERE name = 'Test Product'
UNION ALL
SELECT 'Test parts' as table_name, COUNT(*) as count FROM public.parts WHERE name = 'Test Part'
UNION ALL
SELECT 'Test services' as table_name, COUNT(*) as count FROM public.services WHERE name = 'Test Service'
UNION ALL
SELECT 'Test devices' as table_name, COUNT(*) as count FROM public.devices WHERE brand = 'Test Brand'
UNION ALL
SELECT 'Test clients' as table_name, COUNT(*) as count FROM public.clients WHERE first_name = 'Test';

-- Nettoyer les données de test
DELETE FROM public.products WHERE name = 'Test Product';
DELETE FROM public.parts WHERE name = 'Test Part';
DELETE FROM public.services WHERE name = 'Test Service';
DELETE FROM public.devices WHERE brand = 'Test Brand';
DELETE FROM public.clients WHERE first_name = 'Test';
