-- Correction des colonnes de la table appointments
-- Date: 2024-01-24

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE DE LA TABLE APPOINTMENTS

SELECT 
    '=== DIAGNOSTIC TABLE APPOINTMENTS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'appointments'
ORDER BY ordinal_position;

-- 2. VÉRIFIER LES COLONNES DE DATE/TIME

SELECT 
    '=== COLONNES DE DATE/TIME ===' as info;

SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'appointments'
AND column_name LIKE '%date%' OR column_name LIKE '%time%'
ORDER BY column_name;

-- 3. AJOUTER LA COLONNE START_DATE SI MANQUANTE

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'start_date') THEN
        ALTER TABLE appointments ADD COLUMN start_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne start_date ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne start_date existe déjà dans appointments';
    END IF;
END $$;

-- 4. AJOUTER LA COLONNE END_DATE SI MANQUANTE

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'end_date') THEN
        ALTER TABLE appointments ADD COLUMN end_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne end_date ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne end_date existe déjà dans appointments';
    END IF;
END $$;

-- 5. AJOUTER LA COLONNE START_TIME SI MANQUANTE

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'start_time') THEN
        ALTER TABLE appointments ADD COLUMN start_time TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne start_time ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne start_time existe déjà dans appointments';
    END IF;
END $$;

-- 6. AJOUTER LA COLONNE END_TIME SI MANQUANTE

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'end_time') THEN
        ALTER TABLE appointments ADD COLUMN end_time TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne end_time ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne end_time existe déjà dans appointments';
    END IF;
END $$;

-- 7. AJOUTER LA COLONNE USER_ID SI MANQUANTE

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'user_id') THEN
        ALTER TABLE appointments ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans appointments';
    END IF;
END $$;

-- 8. CRÉER LES INDEX POUR LES PERFORMANCES

CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_start_date ON appointments(start_date);
CREATE INDEX IF NOT EXISTS idx_appointments_start_time ON appointments(start_time);

-- 9. VÉRIFIER LA STRUCTURE FINALE

SELECT 
    '=== STRUCTURE FINALE APPOINTMENTS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'appointments'
ORDER BY ordinal_position;

-- 10. TEST DES REQUÊTES

SELECT 
    '=== TEST DES REQUÊTES ===' as info;

-- Test avec start_date
SELECT 
    'Test start_date' as test,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'start_date') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status;

-- Test avec start_time
SELECT 
    'Test start_time' as test,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'start_time') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status;

-- Test avec user_id
SELECT 
    'Test user_id' as test,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'user_id') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status;

-- 11. MESSAGE DE FIN

SELECT 
    '=== CORRECTION TERMINÉE ===' as status,
    'Les colonnes de la table appointments ont été corrigées. Rechargez votre application !' as message;
