-- TEST DIRECT DU SERVICE SYSTEM_SETTINGS (CORRIGÉ)
-- Ce script teste directement les opérations CRUD

-- 1. TEST DE LECTURE - Récupérer tous les paramètres
SELECT 
    'TEST LECTURE' as test_type,
    'getAll()' as operation,
    COUNT(*) as result_count
FROM public.system_settings 
WHERE user_id = auth.uid();

-- 2. TEST DE LECTURE - Récupérer par catégorie
SELECT 
    'TEST LECTURE' as test_type,
    'getByCategory(general)' as operation,
    COUNT(*) as result_count
FROM public.system_settings 
WHERE user_id = auth.uid() AND category = 'general';

-- 3. TEST DE LECTURE - Récupérer par clé
SELECT 
    'TEST LECTURE' as test_type,
    'getByKey(workshop_name)' as operation,
    key,
    value
FROM public.system_settings 
WHERE user_id = auth.uid() AND key = 'workshop_name';

-- 4. TEST DE MISE À JOUR - Modifier un paramètre
UPDATE public.system_settings 
SET value = 'TEST_UPDATE_' || EXTRACT(EPOCH FROM NOW())::text
WHERE user_id = auth.uid() AND key = 'workshop_name';

-- Vérifier la mise à jour
SELECT 
    'TEST UPDATE' as test_type,
    'update(workshop_name)' as operation,
    CASE 
        WHEN value LIKE 'TEST_UPDATE_%' THEN 'SUCCESS'
        ELSE 'FAILED'
    END as result
FROM public.system_settings 
WHERE user_id = auth.uid() AND key = 'workshop_name';

-- 5. TEST DE MISE À JOUR MULTIPLE
WITH updates AS (
    SELECT 
        'workshop_name' as key,
        'Atelier de réparation' as value
    UNION ALL
    SELECT 
        'vat_rate' as key,
        '20' as value
)
UPDATE public.system_settings 
SET value = updates.value
FROM updates
WHERE public.system_settings.user_id = auth.uid() 
AND public.system_settings.key = updates.key;

-- Vérifier la mise à jour multiple
SELECT 
    'TEST UPDATE MULTIPLE' as test_type,
    'updateMultiple()' as operation,
    CASE 
        WHEN value = 'Atelier de réparation' THEN 'SUCCESS'
        ELSE 'FAILED'
    END as result
FROM public.system_settings 
WHERE user_id = auth.uid() AND key = 'workshop_name';

-- 6. TEST DE CRÉATION - Créer un nouveau paramètre
INSERT INTO public.system_settings (user_id, key, value, description, category)
VALUES (
    auth.uid(), 
    'test_param_' || EXTRACT(EPOCH FROM NOW())::text, 
    'Valeur de test', 
    'Paramètre de test', 
    'system'
)
ON CONFLICT (user_id, key) DO NOTHING;

-- Vérifier la création
SELECT 
    'TEST CREATE' as test_type,
    'create()' as operation,
    CASE 
        WHEN COUNT(*) > 0 THEN 'SUCCESS'
        ELSE 'FAILED'
    END as result
FROM public.system_settings 
WHERE user_id = auth.uid() 
AND key LIKE 'test_param_%';

-- 7. TEST DE SUPPRESSION - Supprimer le paramètre de test
DELETE FROM public.system_settings 
WHERE user_id = auth.uid() 
AND key LIKE 'test_param_%';

-- Vérifier la suppression
SELECT 
    'TEST DELETE' as test_type,
    'delete()' as operation,
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCESS'
        ELSE 'FAILED'
    END as result
FROM public.system_settings 
WHERE user_id = auth.uid() 
AND key LIKE 'test_param_%';

-- 8. VÉRIFICATION FINALE
SELECT 
    'VÉRIFICATION FINALE' as test_type,
    'Tous les tests' as operation,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings 
WHERE user_id = auth.uid();
