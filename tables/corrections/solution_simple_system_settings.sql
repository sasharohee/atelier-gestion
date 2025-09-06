-- SOLUTION SIMPLE POUR SYSTEM_SETTINGS
-- Supprime la contrainte de clé étrangère problématique

-- ============================================================================
-- 1. SUPPRESSION DE LA CONTRAINTE DE CLÉ ÉTRANGÈRE
-- ============================================================================

-- Supprimer la contrainte de clé étrangère si elle existe
DO $$
BEGIN
    -- Vérifier si la contrainte existe et la supprimer
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'system_settings_user_id_fkey' 
        AND table_name = 'system_settings'
    ) THEN
        ALTER TABLE system_settings DROP CONSTRAINT system_settings_user_id_fkey;
        RAISE NOTICE 'Contrainte system_settings_user_id_fkey supprimée';
    ELSE
        RAISE NOTICE 'Contrainte system_settings_user_id_fkey n''existe pas';
    END IF;
END $$;

-- ============================================================================
-- 2. VÉRIFICATION DE LA STRUCTURE
-- ============================================================================

-- Vérifier la structure actuelle de system_settings
SELECT 
    'Structure system_settings' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
ORDER BY ordinal_position;

-- ============================================================================
-- 3. TEST D'INSERTION
-- ============================================================================

-- Test d'insertion d'un paramètre système (commenté pour sécurité)
/*
INSERT INTO system_settings (user_id, key, value, category, description)
VALUES (
    (SELECT id FROM auth.users LIMIT 1), -- Utiliser le premier utilisateur disponible
    'test_setting',
    'test_value',
    'test',
    'Paramètre de test'
) ON CONFLICT (user_id, key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();
*/

-- ============================================================================
-- 4. VÉRIFICATION FINALE
-- ============================================================================

-- Vérifier que la table est prête
SELECT 
    'Status final' as check_type,
    'Contrainte supprimée - Prêt pour utilisation' as status;

-- Vérifier les contraintes restantes
SELECT 
    'Contraintes restantes' as check_type,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public' 
    AND tc.table_name = 'system_settings';
