-- CORRECTION DE LA TABLE REFERRALS
-- Script pour ajouter workshop_id à la table referrals

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE
SELECT '🔍 VÉRIFICATION DE LA STRUCTURE' as diagnostic;

-- Vérifier si la table referrals existe
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'referrals'
ORDER BY ordinal_position;

-- 2. AJOUTER LA COLONNE WORKSHOP_ID SI NÉCESSAIRE
SELECT '🔧 AJOUT DE LA COLONNE WORKSHOP_ID' as diagnostic;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'referrals' AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE referrals ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à referrals';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans referrals';
    END IF;
END $$;

-- 3. METTRE À JOUR LES DONNÉES EXISTANTES
SELECT '📝 MISE À JOUR DES DONNÉES' as diagnostic;

-- Mettre à jour workshop_id pour les parrainages existants
UPDATE referrals 
SET workshop_id = (
    SELECT c.workshop_id 
    FROM clients c 
    WHERE c.id = referrals.referrer_client_id 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- Si aucun workshop_id trouvé, utiliser celui de l'utilisateur actuel
UPDATE referrals 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- 4. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

-- Afficher la structure finale
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'referrals'
ORDER BY ordinal_position;

-- Afficher les données
SELECT 
    id,
    referrer_client_id,
    referred_client_id,
    workshop_id,
    created_at
FROM referrals
ORDER BY created_at DESC;

-- 5. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION TERMINÉE !' as result;
SELECT '📋 La table referrals a été corrigée.' as next_step;
SELECT '🔄 Vous pouvez maintenant recharger la page de fidélité.' as instruction;





