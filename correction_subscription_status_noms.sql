-- Correction du problème des noms hardcodés dans subscription_status
-- Date: 2024-09-21
-- Problème: La fonction create_user_default_data_permissive utilise 'Utilisateur' et '' comme valeurs par défaut
-- Solution: Créer une nouvelle fonction qui récupère les vraies données utilisateur

-- 1. CRÉER UNE NOUVELLE FONCTION CORRIGÉE
CREATE OR REPLACE FUNCTION create_user_default_data_corrected(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    user_data RECORD;
    result JSON;
BEGIN
    -- Récupérer les vraies données utilisateur depuis la table users
    SELECT first_name, last_name, email, role
    INTO user_data
    FROM users
    WHERE id = p_user_id;
    
    -- Vérifier que l'utilisateur existe
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Utilisateur non trouvé dans la table users'
        );
    END IF;
    
    -- Insérer dans subscription_status avec les vraies données
    INSERT INTO subscription_status (
        user_id, 
        first_name, 
        last_name, 
        email, 
        is_active, 
        subscription_type, 
        notes
    )
    VALUES (
        p_user_id, 
        user_data.first_name, 
        user_data.last_name, 
        user_data.email, 
        FALSE, 
        'free', 
        'Compte créé automatiquement'
    )
    ON CONFLICT (user_id) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        email = EXCLUDED.email,
        updated_at = NOW();
    
    -- Créer les paramètres système par défaut
    INSERT INTO system_settings (user_id, category, key, value, description)
    VALUES 
        (p_user_id, 'general', 'workshop_name', 'Mon Atelier', 'Nom de l''atelier'),
        (p_user_id, 'general', 'workshop_address', '', 'Adresse de l''atelier'),
        (p_user_id, 'general', 'workshop_phone', '', 'Téléphone de l''atelier'),
        (p_user_id, 'general', 'workshop_email', user_data.email, 'Email de l''atelier'),
        (p_user_id, 'notifications', 'email_notifications', 'true', 'Activer les notifications par email'),
        (p_user_id, 'notifications', 'sms_notifications', 'false', 'Activer les notifications par SMS'),
        (p_user_id, 'appointments', 'appointment_duration', '60', 'Durée par défaut des rendez-vous (minutes)'),
        (p_user_id, 'appointments', 'working_hours_start', '08:00', 'Heure de début de travail'),
        (p_user_id, 'appointments', 'working_hours_end', '18:00', 'Heure de fin de travail')
    ON CONFLICT (user_id, category, key) DO NOTHING;

    RETURN json_build_object(
        'success', true, 
        'message', 'Données créées avec succès',
        'user_data', json_build_object(
            'first_name', user_data.first_name,
            'last_name', user_data.last_name,
            'email', user_data.email
        )
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false, 
        'error', 'Erreur lors de la création des données: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. DONNER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION create_user_default_data_corrected(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_default_data_corrected(UUID) TO anon;
GRANT EXECUTE ON FUNCTION create_user_default_data_corrected(UUID) TO service_role;

-- 3. CORRIGER LES DONNÉES EXISTANTES
-- Mettre à jour les enregistrements existants dans subscription_status avec les vraies données
UPDATE subscription_status 
SET 
    first_name = u.first_name,
    last_name = u.last_name,
    email = u.email,
    updated_at = NOW()
FROM users u
WHERE subscription_status.user_id = u.id
AND (subscription_status.first_name = 'Utilisateur' OR subscription_status.last_name = 'Test' OR subscription_status.last_name = '');

-- 4. FONCTION DE TEST
CREATE OR REPLACE FUNCTION test_corrected_function()
RETURNS TABLE(test_name TEXT, result TEXT, details TEXT) AS $$
DECLARE
    test_user_id UUID;
    test_result JSON;
BEGIN
    -- Trouver un utilisateur existant pour le test
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RETURN QUERY SELECT 'Test utilisateur'::TEXT, 'ERREUR'::TEXT, 'Aucun utilisateur trouvé'::TEXT;
        RETURN;
    END IF;
    
    -- Tester la nouvelle fonction
    SELECT create_user_default_data_corrected(test_user_id) INTO test_result;
    
    IF (test_result->>'success')::boolean THEN
        RETURN QUERY SELECT 'Fonction corrigée'::TEXT, 'OK'::TEXT, 'Fonction fonctionne correctement'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction corrigée'::TEXT, 'ERREUR'::TEXT, (test_result->>'error')::TEXT;
    END IF;
    
    -- Vérifier que les données sont correctes
    IF EXISTS (
        SELECT 1 FROM subscription_status ss
        JOIN users u ON ss.user_id = u.id
        WHERE ss.user_id = test_user_id
        AND ss.first_name = u.first_name
        AND ss.last_name = u.last_name
    ) THEN
        RETURN QUERY SELECT 'Données correctes'::TEXT, 'OK'::TEXT, 'Les noms correspondent'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Données correctes'::TEXT, 'ERREUR'::TEXT, 'Les noms ne correspondent pas'::TEXT;
    END IF;
    
END;
$$ LANGUAGE plpgsql;

-- 5. EXÉCUTER LE TEST
SELECT * FROM test_corrected_function();

-- 6. MESSAGE DE CONFIRMATION
SELECT 'Correction appliquée - Les nouveaux comptes auront les bons noms dans subscription_status' as status;

