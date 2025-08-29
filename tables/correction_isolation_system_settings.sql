-- Correction de l'isolation des paramètres système
-- Date: 2024-01-24

-- ============================================================================
-- 1. DIAGNOSTIC DU PROBLÈME
-- ============================================================================

SELECT '=== DIAGNOSTIC DU PROBLÈME ===' as section;

-- Vérifier la structure de la table system_settings
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'system_settings'
ORDER BY ordinal_position;

-- Vérifier les politiques RLS existantes
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'system_settings';

-- Vérifier si RLS est activé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'system_settings';

-- ============================================================================
-- 2. ANALYSE DES DONNÉES
-- ============================================================================

SELECT '=== ANALYSE DES DONNÉES ===' as section;

-- Compter les enregistrements par user_id
SELECT 
    user_id,
    COUNT(*) as nombre_parametres,
    COUNT(CASE WHEN key LIKE 'user_%' THEN 1 END) as parametres_utilisateur,
    COUNT(CASE WHEN key LIKE 'workshop_%' THEN 1 END) as parametres_atelier
FROM system_settings
GROUP BY user_id
ORDER BY user_id;

-- Vérifier les paramètres sans user_id
SELECT 
    COUNT(*) as parametres_sans_user_id
FROM system_settings
WHERE user_id IS NULL;

-- Afficher quelques exemples de paramètres
SELECT 
    id,
    key,
    value,
    user_id,
    created_at,
    updated_at
FROM system_settings
ORDER BY user_id, key
LIMIT 20;

-- ============================================================================
-- 3. CORRECTION DE L'ISOLATION
-- ============================================================================

SELECT '=== CORRECTION DE L''ISOLATION ===' as section;

-- Activer RLS si ce n'est pas déjà fait
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Supprimer les politiques existantes pour les recréer
DROP POLICY IF EXISTS "Users can view their own system settings" ON system_settings;
DROP POLICY IF EXISTS "Users can insert their own system settings" ON system_settings;
DROP POLICY IF EXISTS "Users can update their own system settings" ON system_settings;
DROP POLICY IF EXISTS "Users can delete their own system settings" ON system_settings;

-- Créer les nouvelles politiques RLS
CREATE POLICY "Users can view their own system settings"
ON system_settings
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own system settings"
ON system_settings
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own system settings"
ON system_settings
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own system settings"
ON system_settings
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ============================================================================
-- 4. NETTOYAGE DES DONNÉES
-- ============================================================================

SELECT '=== NETTOYAGE DES DONNÉES ===' as section;

-- Supprimer les paramètres sans user_id (données orphelines)
DELETE FROM system_settings 
WHERE user_id IS NULL;

-- Vérifier s'il y a des doublons de clés pour le même utilisateur
SELECT 
    user_id,
    key,
    COUNT(*) as nombre_doublons
FROM system_settings
GROUP BY user_id, key
HAVING COUNT(*) > 1
ORDER BY user_id, key;

-- Supprimer les doublons en gardant le plus récent
DELETE FROM system_settings 
WHERE id IN (
    SELECT id FROM (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY user_id, key ORDER BY updated_at DESC) as rn
        FROM system_settings
    ) t
    WHERE t.rn > 1
);

-- ============================================================================
-- 5. CRÉATION DE PARAMÈTRES PAR DÉFAUT
-- ============================================================================

SELECT '=== CRÉATION DE PARAMÈTRES PAR DÉFAUT ===' as section;

-- Fonction pour créer des paramètres par défaut pour un utilisateur
CREATE OR REPLACE FUNCTION create_default_system_settings(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Paramètres utilisateur par défaut
    INSERT INTO system_settings (user_id, key, value, description, category, created_at, updated_at)
    VALUES 
        (p_user_id, 'user_first_name', '', 'Prénom de l''utilisateur', 'user', NOW(), NOW()),
        (p_user_id, 'user_last_name', '', 'Nom de l''utilisateur', 'user', NOW(), NOW()),
        (p_user_id, 'user_email', '', 'Email de l''utilisateur', 'user', NOW(), NOW()),
        (p_user_id, 'user_phone', '', 'Téléphone de l''utilisateur', 'user', NOW(), NOW()),
        
        -- Paramètres atelier par défaut
        (p_user_id, 'workshop_name', 'Mon Atelier', 'Nom de l''atelier', 'workshop', NOW(), NOW()),
        (p_user_id, 'workshop_address', '', 'Adresse de l''atelier', 'workshop', NOW(), NOW()),
        (p_user_id, 'workshop_phone', '', 'Téléphone de l''atelier', 'workshop', NOW(), NOW()),
        (p_user_id, 'workshop_email', '', 'Email de l''atelier', 'workshop', NOW(), NOW()),
        (p_user_id, 'workshop_siret', '', 'Numéro SIRET', 'workshop', NOW(), NOW()),
        (p_user_id, 'workshop_vat_number', '', 'Numéro de TVA', 'workshop', NOW(), NOW()),
        (p_user_id, 'vat_rate', '20', 'Taux de TVA (%)', 'workshop', NOW(), NOW()),
        (p_user_id, 'currency', 'EUR', 'Devise', 'workshop', NOW(), NOW()),
        
        -- Paramètres système par défaut
        (p_user_id, 'language', 'fr', 'Langue de l''interface', 'system', NOW(), NOW()),
        (p_user_id, 'theme', 'light', 'Thème de l''interface', 'system', NOW(), NOW())
    ON CONFLICT (user_id, key) DO NOTHING;
END;
$$;

-- ============================================================================
-- 6. VÉRIFICATION FINALE
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier que RLS est activé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'system_settings';

-- Vérifier les politiques créées
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'system_settings'
ORDER BY policyname;

-- Compter les paramètres par utilisateur après nettoyage
SELECT 
    user_id,
    COUNT(*) as nombre_parametres
FROM system_settings
GROUP BY user_id
ORDER BY user_id;

-- Afficher un message de succès
SELECT '✅ Isolation des paramètres système corrigée avec succès !' as result;
