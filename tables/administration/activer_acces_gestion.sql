-- =====================================================
-- ACTIVATION ACCÈS GESTION
-- =====================================================
-- Activer l'accès spécial pour l'atelier de gestion
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état actuel
SELECT '=== ÉTAT ACTUEL ===' as etape;

SELECT 
    key,
    value,
    category
FROM system_settings 
WHERE key IN ('workshop_id', 'workshop_type')
ORDER BY key;

-- 2. Activer l'accès gestion
SELECT '=== ACTIVATION ACCÈS GESTION ===' as etape;

-- Insérer ou mettre à jour le type d'atelier
DO $$
BEGIN
    -- Vérifier si workshop_type existe déjà
    IF EXISTS (SELECT 1 FROM system_settings WHERE key = 'workshop_type') THEN
        -- Mettre à jour la valeur existante
        UPDATE system_settings 
        SET value = 'gestion', updated_at = NOW()
        WHERE key = 'workshop_type';
        RAISE NOTICE '✅ Workshop_type mis à jour vers gestion';
    ELSE
        -- Insérer une nouvelle valeur
        INSERT INTO system_settings (key, value, user_id, category, created_at, updated_at)
        VALUES (
            'workshop_type', 
            'gestion',
            COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1)),
            'general',
            NOW(),
            NOW()
        );
        RAISE NOTICE '✅ Workshop_type créé avec valeur gestion';
    END IF;
END $$;

-- 3. Vérifier l'activation
SELECT '=== VÉRIFICATION ===' as etape;

SELECT 
    key,
    value,
    CASE 
        WHEN key = 'workshop_type' AND value = 'gestion' THEN '✅ Accès gestion activé'
        WHEN key = 'workshop_id' THEN '✅ Workshop ID défini'
        ELSE 'ℹ️ Autre paramètre'
    END as statut
FROM system_settings 
WHERE key IN ('workshop_id', 'workshop_type')
ORDER BY key;

-- 4. Test d'accès gestion
SELECT '=== TEST ACCÈS GESTION ===' as etape;

-- Vérifier que l'atelier de gestion peut voir tous les modèles
SELECT 
    COUNT(*) as total_modeles_visibles,
    COUNT(DISTINCT workshop_id) as nombre_workshops_visibles
FROM device_models;

-- 5. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Accès gestion activé' as message;
SELECT '✅ L''atelier peut maintenant voir tous les modèles' as acces_info;
SELECT '✅ Testez la création et modification de modèles' as next_step;
SELECT 'ℹ️ Pour désactiver, changez workshop_type vers une autre valeur' as note;
