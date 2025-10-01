-- Script pour synchroniser les marques hardcodées du store vers la base de données
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier la structure actuelle
SELECT '=== VÉRIFICATION STRUCTURE ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_brands' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les marques existantes
SELECT '=== MARQUES EXISTANTES ===' as info;
SELECT id, name, description, user_id, created_at 
FROM public.device_brands 
ORDER BY name;

-- 3. Insérer les marques hardcodées du store si elles n'existent pas
DO $$
DECLARE
    current_user_id UUID;
    brand_record RECORD;
BEGIN
    -- Récupérer l'ID de l'utilisateur connecté
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Aucun utilisateur connecté, utilisation du premier utilisateur';
        SELECT id INTO current_user_id FROM auth.users ORDER BY created_at LIMIT 1;
        
        IF current_user_id IS NULL THEN
            RAISE EXCEPTION 'Aucun utilisateur trouvé dans la base de données';
        END IF;
    END IF;

    RAISE NOTICE 'Utilisateur utilisé: %', current_user_id;

    -- Insérer les marques smartphones
    INSERT INTO public.device_brands (id, name, description, logo, is_active, user_id, created_by, updated_by, created_at, updated_at)
    VALUES 
        ('1', 'Apple', 'Fabricant américain de produits électroniques premium', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('2', 'Samsung', 'Fabricant coréen leader en électronique et smartphones', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('3', 'Xiaomi', 'Fabricant chinois de smartphones et IoT', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('4', 'Huawei', 'Fabricant chinois de télécommunications et smartphones', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('5', 'OnePlus', 'Marque de smartphones premium', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('6', 'Google', 'Fabricant des smartphones Pixel', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('7', 'Sony', 'Fabricant japonais d''électronique', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('8', 'LG', 'Fabricant coréen d''électronique', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('9', 'Nokia', 'Fabricant finlandais de télécommunications', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('10', 'Motorola', 'Fabricant américain de télécommunications', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW())
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_by = current_user_id,
        updated_at = NOW();

    -- Insérer les marques tablettes
    INSERT INTO public.device_brands (id, name, description, logo, is_active, user_id, created_by, updated_by, created_at, updated_at)
    VALUES 
        ('21', 'iPad', 'Tablettes Apple', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('22', 'Samsung Galaxy Tab', 'Tablettes Samsung', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('23', 'Lenovo', 'Fabricant chinois d''ordinateurs et tablettes', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW())
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_by = current_user_id,
        updated_at = NOW();

    -- Insérer les marques ordinateurs portables
    INSERT INTO public.device_brands (id, name, description, logo, is_active, user_id, created_by, updated_by, created_at, updated_at)
    VALUES 
        ('28', 'Dell', 'Fabricant américain d''ordinateurs', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('29', 'HP', 'Fabricant américain d''imprimantes et ordinateurs', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('30', 'Lenovo', 'Fabricant chinois d''ordinateurs', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('31', 'Acer', 'Fabricant taïwanais d''ordinateurs', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('32', 'ASUS', 'Fabricant taïwanais d''ordinateurs', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('33', 'MSI', 'Fabricant taïwanais d''ordinateurs gaming', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('34', 'Razer', 'Fabricant américain d''ordinateurs gaming', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('35', 'Alienware', 'Marque gaming de Dell', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('45', 'Apple', 'Fabricant des MacBook', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW())
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_by = current_user_id,
        updated_at = NOW();

    -- Insérer les marques ordinateurs fixes
    INSERT INTO public.device_brands (id, name, description, logo, is_active, user_id, created_by, updated_by, created_at, updated_at)
    VALUES 
        ('46', 'Dell', 'Ordinateurs de bureau Dell', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('47', 'HP', 'Ordinateurs de bureau HP', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('48', 'Lenovo', 'Ordinateurs de bureau Lenovo', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('49', 'Acer', 'Ordinateurs de bureau Acer', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('50', 'ASUS', 'Ordinateurs de bureau ASUS', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('51', 'MSI', 'Ordinateurs de bureau gaming MSI', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('52', 'Alienware', 'Ordinateurs de bureau gaming Alienware', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW()),
        ('60', 'Apple', 'Fabricant des iMac et Mac Pro', '', true, current_user_id, current_user_id, current_user_id, NOW(), NOW())
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        updated_by = current_user_id,
        updated_at = NOW();

    RAISE NOTICE '✅ Marques hardcodées synchronisées avec succès';
END $$;

-- 4. Vérifier les marques après synchronisation
SELECT '=== MARQUES APRÈS SYNCHRONISATION ===' as info;
SELECT id, name, description, user_id, created_at 
FROM public.device_brands 
ORDER BY name;

-- 5. Compter les marques par utilisateur
SELECT '=== RÉPARTITION DES MARQUES PAR UTILISATEUR ===' as info;
SELECT 
    u.email,
    COUNT(b.id) as nombre_marques
FROM auth.users u
LEFT JOIN public.device_brands b ON u.id = b.user_id
GROUP BY u.id, u.email
ORDER BY nombre_marques DESC;

SELECT '✅ Synchronisation des marques terminée !' as result;
