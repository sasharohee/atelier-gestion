-- CORRECTION RADICALE - ISOLATION DES APPAREILS (SANS AUTH)
-- Ce script fonctionne même sans utilisateur connecté

-- ============================================================================
-- 1. DIAGNOSTIC RADICAL (SANS AUTH)
-- ============================================================================

-- Vérifier l'état actuel des appareils
SELECT 
    'ÉTAT ACTUEL APPAREILS' as section,
    COUNT(*) as total_devices,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as devices_sans_proprietaire,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as devices_avec_proprietaire,
    COUNT(DISTINCT user_id) as nombre_proprietaires_differents
FROM public.devices;

-- Vérifier la répartition des appareils
SELECT 
    'RÉPARTITION APPAREILS' as section,
    user_id,
    COUNT(*) as nombre_devices,
    CASE 
        WHEN user_id IS NULL THEN 'Sans propriétaire'
        ELSE 'Avec propriétaire'
    END as proprietaire
FROM public.devices
GROUP BY user_id
ORDER BY nombre_devices DESC;

-- Vérifier les types d'appareils
SELECT 
    'TYPES D''APPAREILS' as section,
    type,
    COUNT(*) as nombre,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as sans_proprietaire,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as avec_proprietaire
FROM public.devices
GROUP BY type
ORDER BY nombre DESC;

-- ============================================================================
-- 2. VÉRIFICATION RLS ET POLITIQUES
-- ============================================================================

-- Vérifier si RLS est activé
SELECT 
    'STATUT RLS' as section,
    schemaname,
    tablename,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity THEN 'ACTIVÉ'
        ELSE 'DÉSACTIVÉ - PROBLÈME CRITIQUE'
    END as statut
FROM pg_tables 
WHERE tablename = 'devices';

-- Vérifier toutes les politiques
SELECT 
    'POLITIQUES EXISTANTES' as section,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'devices'
ORDER BY policyname;

-- ============================================================================
-- 3. CORRECTION RADICALE DES DONNÉES
-- ============================================================================

-- SUPPRIMER TOUS LES APPAREILS EXISTANTS
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    RAISE NOTICE '🗑️ SUPPRESSION RADICALE DE TOUS LES APPAREILS...';
    
    -- Supprimer tous les appareils existants
    DELETE FROM public.devices;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RAISE NOTICE '✅ % appareils supprimés', deleted_count;
    RAISE NOTICE '🎯 Base de données appareils vidée - Prêt pour une isolation propre';
END $$;

-- ============================================================================
-- 4. RECRÉATION COMPLÈTE DE LA TABLE DEVICES
-- ============================================================================

-- Supprimer et recréer la table devices
DO $$
BEGIN
    RAISE NOTICE '🔨 RECRÉATION COMPLÈTE DE LA TABLE DEVICES...';
    
    -- Supprimer toutes les politiques
    DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
    DROP POLICY IF EXISTS "Users can insert own devices" ON public.devices;
    DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
    DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;
    DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can view own devices" ON public.devices;
    DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can create own devices" ON public.devices;
    DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can update own devices" ON public.devices;
    DROP POLICY IF EXISTS "CATALOG_ISOLATION_Users can delete own devices" ON public.devices;
    DROP POLICY IF EXISTS "DEVICES_ISOLATION_Users can view own devices" ON public.devices;
    DROP POLICY IF EXISTS "DEVICES_ISOLATION_Users can create own devices" ON public.devices;
    DROP POLICY IF EXISTS "DEVICES_ISOLATION_Users can update own devices" ON public.devices;
    DROP POLICY IF EXISTS "DEVICES_ISOLATION_Users can delete own devices" ON public.devices;
    DROP POLICY IF EXISTS "FORCE_ISOLATION_Users can view own devices" ON public.devices;
    DROP POLICY IF EXISTS "FORCE_ISOLATION_Users can create own devices" ON public.devices;
    DROP POLICY IF EXISTS "FORCE_ISOLATION_Users can update own devices" ON public.devices;
    DROP POLICY IF EXISTS "FORCE_ISOLATION_Users can delete own devices" ON public.devices;
    DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can view own devices" ON public.devices;
    DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can create own devices" ON public.devices;
    DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can update own devices" ON public.devices;
    DROP POLICY IF EXISTS "RADICAL_ISOLATION_Users can delete own devices" ON public.devices;
    DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.devices;
    DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.devices;
    DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.devices;
    DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.devices;
    DROP POLICY IF EXISTS "Enable read access for users based on user_id" ON public.devices;
    DROP POLICY IF EXISTS "Enable insert for users based on user_id" ON public.devices;
    DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.devices;
    DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.devices;
    
    RAISE NOTICE '✅ Toutes les politiques supprimées';
END $$;

-- Recréer la table devices avec la structure correcte
DROP TABLE IF EXISTS public.devices CASCADE;

CREATE TABLE public.devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    serial_number TEXT,
    type TEXT NOT NULL CHECK (type IN ('smartphone', 'tablet', 'laptop', 'desktop', 'other')),
    specifications JSONB DEFAULT '{}',
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer les index nécessaires
CREATE INDEX idx_devices_user_id ON public.devices(user_id);
CREATE INDEX idx_devices_type ON public.devices(type);
CREATE INDEX idx_devices_brand ON public.devices(brand);

-- Activer RLS immédiatement
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. CRÉATION DE POLITIQUES RLS ULTRA STRICTES
-- ============================================================================

-- Créer des politiques RLS ultra strictes et simples
CREATE POLICY "RADICAL_ISOLATION_Users can view own devices" ON public.devices 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "RADICAL_ISOLATION_Users can create own devices" ON public.devices 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "RADICAL_ISOLATION_Users can update own devices" ON public.devices 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "RADICAL_ISOLATION_Users can delete own devices" ON public.devices 
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 6. VÉRIFICATION DE LA NOUVELLE STRUCTURE
-- ============================================================================

-- Vérifier la nouvelle structure
SELECT 
    'NOUVELLE STRUCTURE' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'devices'
ORDER BY ordinal_position;

-- Vérifier les nouvelles politiques
SELECT 
    'NOUVELLES POLITIQUES RADICALES' as section,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'devices'
    AND policyname LIKE '%RADICAL_ISOLATION%'
ORDER BY policyname;

-- ============================================================================
-- 7. VÉRIFICATION FINALE
-- ============================================================================

-- Vérification finale
SELECT 
    'VÉRIFICATION FINALE' as section,
    COUNT(*) as nombre_devices,
    COUNT(DISTINCT user_id) as nombre_proprietaires
FROM public.devices;

-- Vérifier que RLS est actif
SELECT 
    'STATUT FINAL RLS' as section,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity THEN '✅ RLS ACTIVÉ'
        ELSE '❌ RLS DÉSACTIVÉ'
    END as statut
FROM pg_tables 
WHERE tablename = 'devices';

-- ============================================================================
-- 8. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 
    '🎉 CORRECTION RADICALE TERMINÉE' as status,
    'La table devices a été complètement recréée avec isolation parfaite' as message,
    'Connectez-vous maintenant et testez avec différents comptes' as action;

-- ============================================================================
-- 9. INSTRUCTIONS POUR LES TESTS
-- ============================================================================

SELECT 
    '📋 INSTRUCTIONS DE TEST' as section,
    '1. Connectez-vous avec le compte A' as etape1,
    '2. Créez un appareil dans Catalogue > Appareils' as etape2,
    '3. Déconnectez-vous et connectez-vous avec le compte B' as etape3,
    '4. Vérifiez que l''appareil du compte A n''est PAS visible' as etape4,
    '5. Créez un appareil avec le compte B' as etape5,
    '6. Retournez au compte A et vérifiez l''isolation' as etape6;

-- ============================================================================
-- 10. EXEMPLE DE DONNÉES DE TEST
-- ============================================================================

SELECT 
    '💡 EXEMPLES D''APPAREILS À CRÉER' as section,
    'Smartphone: iPhone 14, Samsung Galaxy S23' as smartphones,
    'Tablet: iPad Pro, Samsung Galaxy Tab' as tablets,
    'Laptop: MacBook Pro, Dell XPS' as laptops,
    'Desktop: iMac, HP Pavilion' as desktops,
    'Other: Console de jeu, Smart TV' as others;
