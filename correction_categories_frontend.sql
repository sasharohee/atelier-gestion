-- =====================================================
-- CORRECTION CATÉGORIES FRONTEND
-- =====================================================
-- Synchronisation des catégories avec la base de données
-- =====================================================

-- 1. VÉRIFIER LES CATÉGORIES EXISTANTES
SELECT 'CATÉGORIES EXISTANTES' as section;
SELECT 
    name,
    description,
    icon,
    color,
    is_active,
    workshop_id
FROM public.product_categories
ORDER BY sort_order;

-- 2. INSÉRER LES CATÉGORIES PAR DÉFAUT SI ELLES N'EXISTENT PAS
INSERT INTO public.product_categories (name, description, icon, color, sort_order, is_active) VALUES
    ('smartphone', 'Téléphones mobiles et smartphones', 'smartphone', '#9c27b0', 1, true),
    ('tablet', 'Tablettes et iPads', 'tablet', '#ff9800', 2, true),
    ('laptop', 'Ordinateurs portables et laptops', 'laptop', '#2196f3', 3, true),
    ('desktop', 'Ordinateurs de bureau et fixes', 'desktop_windows', '#4caf50', 4, true),
    ('console', 'Consoles de jeux (PlayStation, Xbox, Nintendo)', 'games', '#ff6b35', 5, true),
    ('smartwatch', 'Montres connectées et smartwatches', 'watch', '#ff9800', 6, true),
    ('headphones', 'Écouteurs et casques audio', 'headphones', '#795548', 7, true),
    ('camera', 'Appareils photo et caméras', 'camera_alt', '#607d8b', 8, true),
    ('tv', 'Téléviseurs et écrans', 'tv', '#e91e63', 9, true),
    ('speaker', 'Haut-parleurs et systèmes audio', 'speaker', '#9e9e9e', 10, true),
    ('keyboard', 'Claviers et périphériques', 'keyboard', '#795548', 11, true),
    ('mouse', 'Souris et périphériques', 'mouse', '#607d8b', 12, true),
    ('router', 'Routeurs et équipements réseau', 'router', '#2196f3', 13, true),
    ('printer', 'Imprimantes et scanners', 'print', '#ff5722', 14, true),
    ('accessory', 'Accessoires divers', 'device_hub', '#9e9e9e', 15, true)
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    color = EXCLUDED.color,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- 3. METTRE À JOUR LES WORKSHOP_ID POUR L'ISOLATION
UPDATE public.product_categories 
SET workshop_id = (
    SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
) 
WHERE workshop_id IS NULL;

-- 4. VÉRIFICATION FINALE
SELECT 'VÉRIFICATION FINALE' as section;
SELECT 
    name,
    description,
    icon,
    color,
    is_active,
    CASE 
        WHEN workshop_id IS NOT NULL THEN '✅ Isolé'
        ELSE '❌ Pas isolé'
    END as isolation_status
FROM public.product_categories
ORDER BY sort_order;


