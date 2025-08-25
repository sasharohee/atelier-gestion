-- Correction de la structure de la table system_settings
-- Date: 2024-01-24

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE
SELECT 
    '=== STRUCTURE ACTUELLE SYSTEM_SETTINGS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'system_settings'
ORDER BY ordinal_position;

-- 2. AJOUTER LES COLONNES MANQUANTES

-- Ajouter user_id si manquant
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Ajouter category si manquant
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS category VARCHAR(50);

-- Ajouter key si manquant
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS key VARCHAR(100);

-- Ajouter value si manquant
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS value TEXT;

-- Ajouter description si manquant
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS description TEXT;

-- Ajouter created_at si manquant
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Ajouter updated_at si manquant
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. CRÉER LES INDEX
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON system_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_system_settings_category ON system_settings(category);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(key);

-- 4. VÉRIFIER LA STRUCTURE FINALE
SELECT 
    '=== STRUCTURE FINALE SYSTEM_SETTINGS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'system_settings'
ORDER BY ordinal_position;

-- 5. CRÉER DES DONNÉES PAR DÉFAUT POUR L'UTILISATEUR CONNECTÉ
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
    
    -- Insérer des paramètres par défaut
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
        (current_user_id, 'appointments', 'working_hours_end', '18:00', 'Heure de fin de travail')
    ON CONFLICT (user_id, category, key) DO NOTHING;
    
    RAISE NOTICE '✅ Paramètres par défaut créés pour l''utilisateur: %', current_user_id;
END $$;

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
    'La structure de system_settings a été corrigée et des données par défaut ont été créées !' as message;
