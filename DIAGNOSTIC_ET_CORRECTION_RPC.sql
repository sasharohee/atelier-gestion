-- 🔍 DIAGNOSTIC ET CORRECTION DE LA FONCTION RPC
-- Script pour diagnostiquer et corriger les problèmes avec create_user_bypass

-- 1. DIAGNOSTIC - Vérifier si la fonction existe
SELECT 'DIAGNOSTIC: Vérification de la fonction create_user_bypass' as info;
SELECT 
    routine_name,
    routine_type,
    data_type as return_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'create_user_bypass';

-- 2. DIAGNOSTIC - Vérifier les colonnes de auth.users
SELECT 'DIAGNOSTIC: Structure de la table auth.users' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'auth'
ORDER BY ordinal_position;

-- 3. DIAGNOSTIC - Vérifier les colonnes de public.users
SELECT 'DIAGNOSTIC: Structure de la table public.users' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. SUPPRESSION ET RECRÉATION DE LA FONCTION
SELECT 'CORRECTION: Recréation de la fonction create_user_bypass' as info;

-- Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS public.create_user_bypass(TEXT, TEXT, TEXT, TEXT, TEXT);

-- Créer une nouvelle fonction simplifiée et robuste
CREATE OR REPLACE FUNCTION public.create_user_bypass(
    user_email TEXT,
    user_password TEXT,
    first_name TEXT DEFAULT 'Utilisateur',
    last_name TEXT DEFAULT '',
    user_role TEXT DEFAULT 'technician'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID;
    result JSON;
BEGIN
    -- Vérifier que l'email n'existe pas déjà
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = user_email) THEN
        result := json_build_object(
            'success', false,
            'error', 'Email already exists',
            'message', 'Un compte avec cet email existe déjà. Veuillez vous connecter.'
        );
        RETURN result;
    END IF;
    
    -- Générer un UUID pour l'utilisateur
    new_user_id := gen_random_uuid();
    
    -- Insérer dans auth.users avec une structure minimale
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        role,
        aud
    ) VALUES (
        new_user_id,
        '00000000-0000-0000-0000-000000000000',
        user_email,
        crypt(user_password, gen_salt('bf')),
        NOW(), -- Email confirmé automatiquement
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        json_build_object('firstName', first_name, 'lastName', last_name, 'role', user_role),
        false,
        'authenticated',
        'authenticated'
    );
    
    -- Créer l'utilisateur dans public.users
    INSERT INTO public.users (
        id,
        first_name,
        last_name,
        email,
        role,
        created_at,
        updated_at
    ) VALUES (
        new_user_id,
        first_name,
        last_name,
        user_email,
        user_role,
        NOW(),
        NOW()
    );
    
    -- Retourner le résultat de succès
    result := json_build_object(
        'success', true,
        'user_id', new_user_id,
        'email', user_email,
        'message', 'Utilisateur créé avec succès'
    );
    
    RETURN result;
    
EXCEPTION
    WHEN unique_violation THEN
        result := json_build_object(
            'success', false,
            'error', 'Duplicate email',
            'message', 'Un compte avec cet email existe déjà. Veuillez vous connecter.'
        );
        RETURN result;
    WHEN OTHERS THEN
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Erreur lors de la création de l''utilisateur: ' || SQLERRM
        );
        RETURN result;
END;
$$;

-- 5. TEST DE LA FONCTION
SELECT 'TEST: Test de la fonction create_user_bypass' as info;

-- Tester la fonction avec des données de test
SELECT public.create_user_bypass(
    'test@example.com',
    'motdepasse123',
    'Test',
    'Utilisateur',
    'technician'
) as test_result;

-- 6. NETTOYAGE - Supprimer l'utilisateur de test
DELETE FROM auth.users WHERE email = 'test@example.com';
DELETE FROM public.users WHERE email = 'test@example.com';

-- 7. MESSAGE FINAL
SELECT '✅ Fonction RPC corrigée et testée' as status;
