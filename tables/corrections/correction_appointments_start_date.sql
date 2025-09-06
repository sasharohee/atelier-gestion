-- Correction des colonnes start_date dans appointments
-- Date: 2024-01-24

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE

SELECT 
    '=== STRUCTURE ACTUELLE APPOINTMENTS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'appointments'
ORDER BY ordinal_position;

-- 2. AJOUTER LA COLONNE START_DATE

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'start_date') THEN
        ALTER TABLE appointments ADD COLUMN start_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne start_date ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne start_date existe déjà dans appointments';
    END IF;
END $$;

-- 3. AJOUTER LA COLONNE END_DATE

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'end_date') THEN
        ALTER TABLE appointments ADD COLUMN end_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne end_date ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne end_date existe déjà dans appointments';
    END IF;
END $$;

-- 4. AJOUTER LA COLONNE USER_ID SI MANQUANTE

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'user_id') THEN
        ALTER TABLE appointments ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà dans appointments';
    END IF;
END $$;

-- 5. CRÉER LES INDEX

CREATE INDEX IF NOT EXISTS idx_appointments_start_date ON appointments(start_date);
CREATE INDEX IF NOT EXISTS idx_appointments_end_date ON appointments(end_date);
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON appointments(user_id);

-- 6. VÉRIFIER LA STRUCTURE FINALE

SELECT 
    '=== STRUCTURE FINALE APPOINTMENTS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'appointments'
ORDER BY ordinal_position;

-- 7. TEST DES REQUÊTES

SELECT 
    '=== TEST DES REQUÊTES ===' as info;

-- Test start_date
SELECT 
    'Test start_date' as test,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'start_date') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status;

-- Test end_date
SELECT 
    'Test end_date' as test,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'end_date') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status;

-- Test user_id
SELECT 
    'Test user_id' as test,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'user_id') 
        THEN 'OK' 
        ELSE 'ERREUR' 
    END as status;

-- 8. MESSAGE DE FIN

SELECT 
    '=== CORRECTION TERMINÉE ===' as status,
    'Les colonnes start_date et end_date ont été ajoutées à la table appointments. Rechargez votre application !' as message;
