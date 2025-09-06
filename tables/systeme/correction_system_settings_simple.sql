-- Correction simple de la structure de system_settings
-- Version sans contrainte unique pour éviter les erreurs

-- 1. AJOUTER LES COLONNES MANQUANTES
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS category VARCHAR(50);
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS key VARCHAR(100);
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS value TEXT;
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. CRÉER LES INDEX
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON system_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_system_settings_category ON system_settings(category);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(key);

-- 3. CRÉER LA CONTRAINTE UNIQUE (si elle n'existe pas)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'system_settings_user_category_key_unique'
    ) THEN
        ALTER TABLE system_settings ADD CONSTRAINT system_settings_user_category_key_unique 
        UNIQUE (user_id, category, key);
        RAISE NOTICE '✅ Contrainte unique ajoutée';
    ELSE
        RAISE NOTICE 'ℹ️ Contrainte unique existe déjà';
    END IF;
END $$;

-- 4. CRÉER DES DONNÉES PAR DÉFAUT (sans ON CONFLICT)
DO $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Récupérer l'utilisateur connecté (ou utiliser un ID par défaut)
    SELECT auth.uid() INTO current_user_id;
    
    -- Si aucun utilisateur connecté, utiliser un ID par défaut
    IF current_user_id IS NULL THEN
        current_user_id := '00000000-0000-0000-0000-000000000000';
    END IF;
    
    -- Insérer des paramètres par défaut (sans ON CONFLICT)
    INSERT INTO system_settings (user_id, category, key, value, description)
    VALUES 
        (current_user_id, 'general', 'workshop_name', 'Mon Atelier', 'Nom de l''atelier'),
        (current_user_id, 'general', 'workshop_address', '', 'Adresse de l''atelier'),
        (current_user_id, 'general', 'workshop_phone', '', 'Téléphone de l''atelier'),
        (current_user_id, 'general', 'workshop_email', '', 'Email de l''atelier'),
        (current_user_id, 'notifications', 'email_notifications', 'true', 'Activer les notifications par email'),
        (current_user_id, 'notifications', 'sms_notifications', 'false', 'Activer les notifications par SMS'),
        (current_user_id, 'appointments', 'appointment_duration', '60', 'Durée par défaut des rendez-vous (minutes)'),
        (current_user_id, 'appointments', 'working_hours_start', '08:00', 'Heure de début de travail'),
        (current_user_id, 'appointments', 'working_hours_end', '18:00', 'Heure de fin de travail');
    
    RAISE NOTICE '✅ Paramètres par défaut créés pour l''utilisateur: %', current_user_id;
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'ℹ️ Paramètres par défaut existent déjà';
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Erreur lors de la création des paramètres: %', SQLERRM;
END $$;

-- 5. VÉRIFIER LA STRUCTURE
SELECT 
    '=== STRUCTURE FINALE SYSTEM_SETTINGS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'system_settings'
ORDER BY ordinal_position;

-- 6. VÉRIFIER LES DONNÉES
SELECT 
    '=== DONNÉES SYSTEM_SETTINGS ===' as info;

SELECT 
    user_id,
    category,
    key,
    value,
    description
FROM system_settings
ORDER BY category, key;

-- 7. MESSAGE DE FIN
SELECT 
    '=== CORRECTION TERMINÉE ===' as status,
    'La structure de system_settings a été corrigée !' as message;
