-- =====================================================
-- AJOUT COLONNE WORKSHOP_ID À SUBSCRIPTION_STATUS
-- =====================================================

SELECT 'AJOUT COLONNE WORKSHOP_ID' as section;

-- 1. VÉRIFIER SI LA COLONNE EXISTE DÉJÀ
-- =====================================================

SELECT 
    'VÉRIFICATION COLONNE' as verification,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'subscription_status' 
  AND column_name = 'workshop_id';

-- 2. AJOUTER LA COLONNE SI ELLE N'EXISTE PAS
-- =====================================================

DO $$
BEGIN
    -- Vérifier si la colonne workshop_id existe
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'subscription_status' 
          AND column_name = 'workshop_id'
    ) THEN
        -- Ajouter la colonne workshop_id
        ALTER TABLE subscription_status 
        ADD COLUMN workshop_id uuid;
        
        RAISE NOTICE 'Colonne workshop_id ajoutée à subscription_status';
    ELSE
        RAISE NOTICE 'Colonne workshop_id existe déjà dans subscription_status';
    END IF;
END $$;

-- 3. VÉRIFIER L'AJOUT DE LA COLONNE
-- =====================================================

SELECT 
    'COLONNE AJOUTÉE' as verification,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'subscription_status' 
  AND column_name = 'workshop_id';

-- 4. CRÉER UN WORKSHOP_ID PAR DÉFAUT
-- =====================================================

-- Générer un workshop_id par défaut
DO $$
DECLARE
    default_workshop_id uuid;
BEGIN
    -- Créer un workshop_id par défaut
    default_workshop_id := gen_random_uuid();
    
    -- Mettre à jour tous les utilisateurs sans workshop_id
    UPDATE subscription_status 
    SET workshop_id = default_workshop_id
    WHERE workshop_id IS NULL;
    
    RAISE NOTICE 'Workshop_id par défaut créé: %', default_workshop_id;
    RAISE NOTICE 'Utilisateurs mis à jour avec le workshop_id par défaut';
END $$;

-- 5. VÉRIFIER LA MISE À JOUR
-- =====================================================

SELECT 
    'VÉRIFICATION MISE À JOUR' as verification,
    COUNT(*) as total_utilisateurs,
    COUNT(workshop_id) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM subscription_status;

-- 6. AFFICHER LES UTILISATEURS AVEC LEUR WORKSHOP_ID
-- =====================================================

SELECT 
    id,
    user_id,
    first_name,
    last_name,
    email,
    workshop_id,
    status,
    created_at
FROM subscription_status 
ORDER BY created_at DESC;

-- 7. VÉRIFIER LES WORKSHOP_ID DISTINCTS
-- =====================================================

SELECT 
    workshop_id,
    COUNT(*) as nombre_utilisateurs,
    STRING_AGG(email, ', ') as emails
FROM subscription_status 
GROUP BY workshop_id
ORDER BY nombre_utilisateurs DESC;

-- 8. CRÉER UN INDEX SUR WORKSHOP_ID
-- =====================================================

-- Créer un index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_subscription_status_workshop_id 
ON subscription_status(workshop_id);

-- 9. VÉRIFIER L'INDEX
-- =====================================================

SELECT 
    'INDEX CRÉÉ' as verification,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'subscription_status' 
  AND indexname = 'idx_subscription_status_workshop_id';

-- 10. RÉSULTAT
-- =====================================================

SELECT 
    'AJOUT TERMINÉ' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Colonne workshop_id ajoutée et configurée' as description;
