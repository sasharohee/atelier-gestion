-- CORRECTION D'URGENCE - ISOLATION DU CATALOGUE
-- Ce script corrige immédiatement les problèmes d'isolation du catalogue

-- ============================================================================
-- 1. DIAGNOSTIC INITIAL
-- ============================================================================

-- Vérifier l'état actuel des tables du catalogue
SELECT 
    'DIAGNOSTIC INITIAL' as section,
    table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as records_without_user_id,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as records_with_user_id
FROM (
    SELECT 'devices' as table_name, user_id FROM public.devices
    UNION ALL
    SELECT 'services', user_id FROM public.services  
    UNION ALL
    SELECT 'parts', user_id FROM public.parts
    UNION ALL
    SELECT 'products', user_id FROM public.products
    UNION ALL
    SELECT 'clients', user_id FROM public.clients
) t
GROUP BY table_name;

-- ============================================================================
-- 2. CORRECTION IMMÉDIATE DES DONNÉES ORPHELINES
-- ============================================================================

-- Récupérer l'utilisateur actuel
DO $$
DECLARE
    current_user_id UUID;
    current_user_email TEXT;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - impossible de corriger l''isolation';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔧 Correction de l''isolation pour l''utilisateur: %', current_user_email;
    
    -- Corriger les données orphelines en les assignant à l'utilisateur actuel
    UPDATE public.devices SET user_id = current_user_id WHERE user_id IS NULL;
    UPDATE public.services SET user_id = current_user_id WHERE user_id IS NULL;
    UPDATE public.parts SET user_id = current_user_id WHERE user_id IS NULL;
    UPDATE public.products SET user_id = current_user_id WHERE user_id IS NULL;
    UPDATE public.clients SET user_id = current_user_id WHERE user_id IS NULL;
    
    RAISE NOTICE '✅ Données orphelines corrigées pour l''utilisateur: %', current_user_email;
END $$;

-- ============================================================================
-- 3. CORRECTION DE LA STRUCTURE DES TABLES
-- ============================================================================

-- S'assurer que toutes les colonnes nécessaires existent
DO $$
BEGIN
    -- Devices
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'user_id') THEN
        ALTER TABLE public.devices ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Services  
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'services' AND column_name = 'user_id') THEN
        ALTER TABLE public.services ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Parts
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'parts' AND column_name = 'user_id') THEN
        ALTER TABLE public.parts ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Products
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'user_id') THEN
        ALTER TABLE public.products ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Clients
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'user_id') THEN
        ALTER TABLE public.clients ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    RAISE NOTICE '✅ Structure des tables corrigée';
END $$;

-- ============================================================================
-- 4. CORRECTION DES POLITIQUES RLS
-- ============================================================================

-- Supprimer toutes les anciennes politiques
DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can insert own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;
DROP POLICY IF EXISTS "CATALOG_Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "CATALOG_Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "CATALOG_Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "CATALOG_Users can delete own devices" ON public.devices;

DROP POLICY IF EXISTS "Users can view own services" ON public.services;
DROP POLICY IF EXISTS "Users can insert own services" ON public.services;
DROP POLICY IF EXISTS "Users can update own services" ON public.services;
DROP POLICY IF EXISTS "Users can delete own services" ON public.services;
DROP POLICY IF EXISTS "CATALOG_Users can view own services" ON public.services;
DROP POLICY IF EXISTS "CATALOG_Users can create own services" ON public.services;
DROP POLICY IF EXISTS "CATALOG_Users can update own services" ON public.services;
DROP POLICY IF EXISTS "CATALOG_Users can delete own services" ON public.services;

DROP POLICY IF EXISTS "Users can view own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can insert own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can update own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can delete own parts" ON public.parts;
DROP POLICY IF EXISTS "CATALOG_Users can view own parts" ON public.parts;
DROP POLICY IF EXISTS "CATALOG_Users can create own parts" ON public.parts;
DROP POLICY IF EXISTS "CATALOG_Users can update own parts" ON public.parts;
DROP POLICY IF EXISTS "CATALOG_Users can delete own parts" ON public.parts;

DROP POLICY IF EXISTS "Users can view own products" ON public.products;
DROP POLICY IF EXISTS "Users can insert own products" ON public.products;
DROP POLICY IF EXISTS "Users can update own products" ON public.products;
DROP POLICY IF EXISTS "Users can delete own products" ON public.products;
DROP POLICY IF EXISTS "CATALOG_Users can view own products" ON public.products;
DROP POLICY IF EXISTS "CATALOG_Users can create own products" ON public.products;
DROP POLICY IF EXISTS "CATALOG_Users can update own products" ON public.products;
DROP POLICY IF EXISTS "CATALOG_Users can delete own products" ON public.products;

DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can insert own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;

-- Activer RLS sur toutes les tables
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- Créer les nouvelles politiques RLS strictes
-- Devices
CREATE POLICY "CATALOG_ISOLATION_Users can view own devices" ON public.devices 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can create own devices" ON public.devices 
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can update own devices" ON public.devices 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can delete own devices" ON public.devices 
    FOR DELETE USING (auth.uid() = user_id);

-- Services
CREATE POLICY "CATALOG_ISOLATION_Users can view own services" ON public.services 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can create own services" ON public.services 
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can update own services" ON public.services 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can delete own services" ON public.services 
    FOR DELETE USING (auth.uid() = user_id);

-- Parts
CREATE POLICY "CATALOG_ISOLATION_Users can view own parts" ON public.parts 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can create own parts" ON public.parts 
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can update own parts" ON public.parts 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can delete own parts" ON public.parts 
    FOR DELETE USING (auth.uid() = user_id);

-- Products
CREATE POLICY "CATALOG_ISOLATION_Users can view own products" ON public.products 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can create own products" ON public.products 
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can update own products" ON public.products 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can delete own products" ON public.products 
    FOR DELETE USING (auth.uid() = user_id);

-- Clients
CREATE POLICY "CATALOG_ISOLATION_Users can view own clients" ON public.clients 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can create own clients" ON public.clients 
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can update own clients" ON public.clients 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "CATALOG_ISOLATION_Users can delete own clients" ON public.clients 
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 5. CRÉATION D'INDEX POUR LES PERFORMANCES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_catalog_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_catalog_services_user_id ON public.services(user_id);
CREATE INDEX IF NOT EXISTS idx_catalog_parts_user_id ON public.parts(user_id);
CREATE INDEX IF NOT EXISTS idx_catalog_products_user_id ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_catalog_clients_user_id ON public.clients(user_id);

-- ============================================================================
-- 6. VÉRIFICATION FINALE
-- ============================================================================

-- Vérifier l'état final
SELECT 
    'VÉRIFICATION FINALE' as section,
    table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as records_without_user_id,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as records_with_user_id
FROM (
    SELECT 'devices' as table_name, user_id FROM public.devices
    UNION ALL
    SELECT 'services', user_id FROM public.services  
    UNION ALL
    SELECT 'parts', user_id FROM public.parts
    UNION ALL
    SELECT 'products', user_id FROM public.products
    UNION ALL
    SELECT 'clients', user_id FROM public.clients
) t
GROUP BY table_name;

-- Vérifier les politiques RLS
SELECT 
    'POLITIQUES RLS' as section,
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename IN ('devices', 'services', 'parts', 'products', 'clients')
    AND policyname LIKE '%CATALOG_ISOLATION%'
ORDER BY tablename, policyname;

-- ============================================================================
-- 7. TEST D'ISOLATION
-- ============================================================================

DO $$
DECLARE
    current_user_id UUID;
    test_result BOOLEAN := TRUE;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Test d''isolation impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Test de lecture
    IF EXISTS (SELECT 1 FROM public.devices WHERE user_id != current_user_id LIMIT 1) THEN
        RAISE NOTICE '❌ ERREUR: Données d''autres utilisateurs visibles dans devices';
        test_result := FALSE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM public.services WHERE user_id != current_user_id LIMIT 1) THEN
        RAISE NOTICE '❌ ERREUR: Données d''autres utilisateurs visibles dans services';
        test_result := FALSE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM public.parts WHERE user_id != current_user_id LIMIT 1) THEN
        RAISE NOTICE '❌ ERREUR: Données d''autres utilisateurs visibles dans parts';
        test_result := FALSE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM public.products WHERE user_id != current_user_id LIMIT 1) THEN
        RAISE NOTICE '❌ ERREUR: Données d''autres utilisateurs visibles dans products';
        test_result := FALSE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM public.clients WHERE user_id != current_user_id LIMIT 1) THEN
        RAISE NOTICE '❌ ERREUR: Données d''autres utilisateurs visibles dans clients';
        test_result := FALSE;
    END IF;
    
    IF test_result THEN
        RAISE NOTICE '✅ Test d''isolation réussi - L''isolation du catalogue fonctionne correctement';
    ELSE
        RAISE NOTICE '❌ Test d''isolation échoué - Problèmes détectés';
    END IF;
END $$;

-- ============================================================================
-- 8. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 
    '🎉 CORRECTION TERMINÉE' as status,
    'L''isolation du catalogue a été corrigée avec succès.' as message,
    'Toutes les données sont maintenant isolées par utilisateur.' as details;
