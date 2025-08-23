-- VIDER COMPLÈTEMENT LE CATALOGUE
-- Ce script supprime toutes les données des tables du catalogue pour faire des tests propres

-- ============================================================================
-- 1. DIAGNOSTIC AVANT VIDAGE
-- ============================================================================

-- Compter les données avant suppression
SELECT 
    'AVANT VIDAGE' as periode,
    table_name,
    COUNT(*) as nombre_enregistrements
FROM (
    SELECT 'devices' as table_name, id FROM public.devices
    UNION ALL
    SELECT 'services', id FROM public.services  
    UNION ALL
    SELECT 'parts', id FROM public.parts
    UNION ALL
    SELECT 'products', id FROM public.products
    UNION ALL
    SELECT 'clients', id FROM public.clients
) t
GROUP BY table_name
ORDER BY table_name;

-- ============================================================================
-- 2. VIDAGE COMPLET DES TABLES (MÉTHODE SÛRE)
-- ============================================================================

-- Vider toutes les tables du catalogue avec DELETE (plus sûr que TRUNCATE)
-- Cette méthode respecte les contraintes et triggers sans nécessiter de permissions spéciales

-- Vider les tables dans l'ordre pour respecter les contraintes de clés étrangères
DELETE FROM public.devices;
DELETE FROM public.services;
DELETE FROM public.parts;
DELETE FROM public.products;
DELETE FROM public.clients;

-- ============================================================================
-- 3. VÉRIFICATION APRÈS VIDAGE
-- ============================================================================

-- Vérifier que toutes les tables sont vides
SELECT 
    'APRÈS VIDAGE' as periode,
    table_name,
    COUNT(*) as nombre_enregistrements
FROM (
    SELECT 'devices' as table_name, id FROM public.devices
    UNION ALL
    SELECT 'services', id FROM public.services  
    UNION ALL
    SELECT 'parts', id FROM public.parts
    UNION ALL
    SELECT 'products', id FROM public.products
    UNION ALL
    SELECT 'clients', id FROM public.clients
) t
GROUP BY table_name
ORDER BY table_name;

-- ============================================================================
-- 4. VÉRIFICATION DE LA STRUCTURE
-- ============================================================================

-- Vérifier que la structure des tables est intacte
SELECT 
    'STRUCTURE' as verification,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('devices', 'services', 'parts', 'products', 'clients')
ORDER BY table_name, ordinal_position;

-- ============================================================================
-- 5. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

-- Vérifier que les politiques RLS sont toujours en place
SELECT 
    'POLITIQUES RLS' as verification,
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename IN ('devices', 'services', 'parts', 'products', 'clients')
    AND policyname LIKE '%CATALOG_ISOLATION%'
ORDER BY tablename, policyname;

-- ============================================================================
-- 6. TEST D'INSERTION VIDE
-- ============================================================================

-- Tester qu'on peut toujours insérer des données
DO $$
DECLARE
    current_user_id UUID;
    test_result BOOLEAN := TRUE;
BEGIN
    -- Récupérer l'utilisateur connecté
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté - test d''insertion impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Test d''insertion avec utilisateur: %', current_user_id;
    
    -- Test d'insertion dans chaque table
    BEGIN
        INSERT INTO public.devices (brand, model, type, user_id) 
        VALUES ('Test Brand', 'Test Model', 'smartphone', current_user_id);
        RAISE NOTICE '✅ Insertion devices: OK';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur insertion devices: %', SQLERRM;
        test_result := FALSE;
    END;
    
    BEGIN
        INSERT INTO public.services (name, description, user_id) 
        VALUES ('Test Service', 'Test Description', current_user_id);
        RAISE NOTICE '✅ Insertion services: OK';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur insertion services: %', SQLERRM;
        test_result := FALSE;
    END;
    
    BEGIN
        INSERT INTO public.parts (name, part_number, brand, user_id) 
        VALUES ('Test Part', 'TEST001', 'Test Brand', current_user_id);
        RAISE NOTICE '✅ Insertion parts: OK';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur insertion parts: %', SQLERRM;
        test_result := FALSE;
    END;
    
    BEGIN
        INSERT INTO public.products (name, description, user_id) 
        VALUES ('Test Product', 'Test Description', current_user_id);
        RAISE NOTICE '✅ Insertion products: OK';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur insertion products: %', SQLERRM;
        test_result := FALSE;
    END;
    
    BEGIN
        INSERT INTO public.clients (first_name, last_name, email, user_id) 
        VALUES ('Test', 'Client', 'test@test.com', current_user_id);
        RAISE NOTICE '✅ Insertion clients: OK';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur insertion clients: %', SQLERRM;
        test_result := FALSE;
    END;
    
    -- Nettoyer les données de test
    DELETE FROM public.devices WHERE brand = 'Test Brand';
    DELETE FROM public.services WHERE name = 'Test Service';
    DELETE FROM public.parts WHERE name = 'Test Part';
    DELETE FROM public.products WHERE name = 'Test Product';
    DELETE FROM public.clients WHERE first_name = 'Test';
    
    IF test_result THEN
        RAISE NOTICE '🎉 Tous les tests d''insertion réussis - Catalogue prêt pour les tests';
    ELSE
        RAISE NOTICE '⚠️ Certains tests d''insertion ont échoué';
    END IF;
END $$;

-- ============================================================================
-- 7. MESSAGE DE CONFIRMATION FINAL
-- ============================================================================

SELECT 
    '🎉 CATALOGUE VIDÉ' as status,
    'Toutes les tables du catalogue ont été vidées avec succès.' as message,
    'Le catalogue est maintenant prêt pour des tests propres.' as details,
    'Vous pouvez maintenant ajouter vos propres données de test.' as next_step;
