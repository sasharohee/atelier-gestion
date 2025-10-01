-- Script pour réinitialiser le mot de passe d'un utilisateur existant
-- À exécuter dans l'éditeur SQL de Supabase

-- ATTENTION: Ce script nécessite les droits d'administration
-- Utilisez plutôt l'interface Supabase pour réinitialiser le mot de passe

-- 1. Vérifier l'utilisateur
SELECT 
    'Utilisateur à réinitialiser:' as info,
    id,
    email,
    created_at,
    email_confirmed_at
FROM auth.users
WHERE email = 'sasharohee@icloud.com';

-- 2. Générer un nouveau mot de passe (remplacez 'nouveau_mot_de_passe' par votre mot de passe)
-- ATTENTION: Ne pas exécuter cette commande en production
-- Utilisez plutôt l'interface Supabase

/*
UPDATE auth.users 
SET 
    encrypted_password = crypt('nouveau_mot_de_passe', gen_salt('bf')),
    updated_at = NOW()
WHERE email = 'sasharohee@icloud.com';
*/

-- 3. Alternative: Créer un token de réinitialisation
-- Cette méthode est plus sûre
DO $$
DECLARE
    user_id UUID;
    reset_token TEXT;
BEGIN
    -- Récupérer l'ID de l'utilisateur
    SELECT id INTO user_id
    FROM auth.users
    WHERE email = 'sasharohee@icloud.com';
    
    IF user_id IS NULL THEN
        RAISE NOTICE '❌ Utilisateur non trouvé';
        RETURN;
    END IF;
    
    -- Générer un token de réinitialisation
    reset_token := encode(gen_random_bytes(32), 'base64');
    
    -- Mettre à jour l'utilisateur avec le token
    UPDATE auth.users 
    SET 
        recovery_token = reset_token,
        updated_at = NOW()
    WHERE id = user_id;
    
    RAISE NOTICE '✅ Token de réinitialisation généré pour l''utilisateur: %', user_id;
    RAISE NOTICE '🔑 Token: %', reset_token;
    RAISE NOTICE '📧 Utilisez ce token pour réinitialiser le mot de passe via l''API';
    
END $$;

-- 4. Vérifier le résultat
SELECT 
    'État après réinitialisation:' as info,
    id,
    email,
    recovery_token IS NOT NULL as has_reset_token,
    updated_at
FROM auth.users
WHERE email = 'sasharohee@icloud.com';




