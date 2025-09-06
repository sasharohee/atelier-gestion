-- =====================================================
-- MIGRATION : NETTOYAGE DES ANCIENNES DONNÉES
-- =====================================================
-- Script pour nettoyer les anciennes données et préparer
-- le nouveau système de commandes avec isolation
-- Date: 2025-01-23
-- =====================================================

-- 1. NETTOYAGE DES TABLES EXISTANTES (si nécessaire)
-- =====================================================

-- Supprimer les anciennes données qui pourraient causer des conflits
DELETE FROM order_items WHERE order_id NOT IN (
    SELECT id FROM orders WHERE id IS NOT NULL
);

-- Supprimer les commandes avec des IDs non-UUID (ancien système)
DELETE FROM orders WHERE id::text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- 2. VÉRIFICATION ET CORRECTION DES DONNÉES
-- =====================================================

-- Vérifier les commandes restantes
SELECT 
    'Commandes valides restantes' as info,
    COUNT(*) as nombre
FROM orders;

-- Vérifier les articles restants
SELECT 
    'Articles valides restants' as info,
    COUNT(*) as nombre
FROM order_items;

-- 3. RÉINITIALISATION DES SÉQUENCES (si nécessaire)
-- =====================================================

-- Réinitialiser les séquences pour éviter les conflits
-- Note: Les UUIDs n'utilisent pas de séquences, mais on peut nettoyer les autres

-- 4. VÉRIFICATION DES POLITIQUES RLS
-- =====================================================

-- Vérifier que les politiques RLS sont correctement configurées
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation correcte'
        ELSE '⚠️ Vérification nécessaire'
    END as status
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('orders', 'order_items', 'suppliers')
ORDER BY tablename, policyname;

-- 5. VÉRIFICATION DES TRIGGERS
-- =====================================================

-- Vérifier que les triggers sont actifs
SELECT 
    trigger_name,
    event_object_table,
    CASE 
        WHEN trigger_name LIKE '%isolation%' THEN '✅ Trigger isolation'
        WHEN trigger_name LIKE '%total%' THEN '✅ Trigger calcul'
        ELSE 'ℹ️ Autre trigger'
    END as type_trigger,
    CASE 
        WHEN tg_enabled = 'O' THEN '✅ Actif'
        ELSE '❌ Inactif'
    END as status
FROM pg_trigger 
WHERE tgrelid IN (
    SELECT oid FROM pg_class 
    WHERE relname IN ('orders', 'order_items', 'suppliers')
)
ORDER BY event_object_table, trigger_name;

-- 6. INSÉRER DES DONNÉES DE TEST (optionnel)
-- =====================================================

-- Insérer quelques commandes de test pour vérifier le fonctionnement
DO $$
DECLARE
    v_workshop_id UUID;
    v_test_order_id UUID;
    v_test_item_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Insérer une commande de test
    INSERT INTO orders (
        order_number,
        supplier_name,
        supplier_email,
        supplier_phone,
        order_date,
        expected_delivery_date,
        status,
        total_amount,
        notes,
        workshop_id
    ) VALUES (
        'CMD-TEST-001',
        'Fournisseur Test',
        'test@fournisseur.com',
        '0123456789',
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '7 days',
        'pending',
        0,
        'Commande de test après migration'
    ) RETURNING id INTO v_test_order_id;
    
    -- Insérer un article de test
    INSERT INTO order_items (
        order_id,
        product_name,
        description,
        quantity,
        unit_price,
        total_price,
        workshop_id
    ) VALUES (
        v_test_order_id,
        'Produit Test',
        'Description du produit test',
        2,
        25.50,
        51.00
    ) RETURNING id INTO v_test_item_id;
    
    RAISE NOTICE '✅ Données de test insérées - Commande: %, Article: %', v_test_order_id, v_test_item_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Erreur lors de l''insertion des données de test: %', SQLERRM;
END $$;

-- 7. VÉRIFICATION FINALE
-- =====================================================

-- Vérifier que tout fonctionne correctement
SELECT 
    '=== VÉRIFICATION FINALE ===' as section;

-- Compter les commandes
SELECT 
    'Commandes totales' as type,
    COUNT(*) as nombre
FROM orders
UNION ALL
SELECT 
    'Articles totaux' as type,
    COUNT(*) as nombre
FROM order_items;

-- Vérifier les statistiques
SELECT 
    'Statistiques des commandes' as info,
    status,
    COUNT(*) as nombre
FROM orders
GROUP BY status
ORDER BY status;

-- Vérifier l'isolation
SELECT 
    'Vérification isolation' as info,
    COUNT(DISTINCT workshop_id) as nombre_workshops,
    CASE 
        WHEN COUNT(DISTINCT workshop_id) = 1 THEN '✅ Isolation correcte'
        ELSE '⚠️ Vérification nécessaire'
    END as status
FROM orders;

-- 8. MESSAGE DE CONFIRMATION
-- =====================================================

SELECT 
    '🎉 MIGRATION TERMINÉE' as message,
    'Le système de commandes est maintenant prêt' as description,
    CURRENT_TIMESTAMP as timestamp;

