-- Correction de l'assignation des clients à votre compte (VERSION CORRIGÉE)
-- Date: 2024-01-24
-- Solution pour assigner tous les clients à votre compte utilisateur

-- ========================================
-- 1. DIAGNOSTIC - VÉRIFIER LA STRUCTURE DE LA TABLE
-- ========================================

-- Vérifier la structure réelle de la table clients
SELECT 
    'STRUCTURE TABLE CLIENTS' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients'
ORDER BY ordinal_position;

-- Vérifier votre ID utilisateur actuel
SELECT 
    'VOTRE ID UTILISATEUR' as check_type,
    auth.uid() as your_user_id,
    auth.jwt() ->> 'email' as your_email;

-- ========================================
-- 2. DIAGNOSTIC - VÉRIFIER L'ÉTAT ACTUEL DES CLIENTS
-- ========================================

-- Vérifier tous les clients et leurs créateurs (sans colonne company)
SELECT 
    'CLIENTS ET LEURS CRÉATEURS' as check_type,
    id,
    first_name,
    last_name,
    email,
    phone,
    created_by,
    created_at,
    CASE 
        WHEN created_by = auth.uid() THEN '✅ VOS CLIENTS'
        WHEN created_by IS NULL THEN '⚠️ SANS CRÉATEUR'
        ELSE '❌ CLIENTS D''AUTRES'
    END as ownership_status
FROM public.clients 
ORDER BY created_at DESC;

-- Compter les clients par statut
SELECT 
    'COMPTE PAR STATUT' as check_type,
    CASE 
        WHEN created_by = auth.uid() THEN 'Vos clients'
        WHEN created_by IS NULL THEN 'Sans créateur'
        ELSE 'Clients d''autres'
    END as status,
    COUNT(*) as count
FROM public.clients 
GROUP BY 
    CASE 
        WHEN created_by = auth.uid() THEN 'Vos clients'
        WHEN created_by IS NULL THEN 'Sans créateur'
        ELSE 'Clients d''autres'
    END;

-- ========================================
-- 3. SOLUTION - ASSIGNER TOUS LES CLIENTS À VOTRE COMPTE
-- ========================================

-- Option 1: Assigner tous les clients à votre compte actuel
DO $$
DECLARE
    your_user_id UUID;
    updated_count INTEGER;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RAISE NOTICE '❌ Utilisateur non authentifié';
        RETURN;
    END IF;
    
    -- Assigner tous les clients à votre compte
    UPDATE public.clients 
    SET created_by = your_user_id,
        updated_at = NOW()
    WHERE created_by IS NULL OR created_by != your_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    RAISE NOTICE '✅ % clients assignés à votre compte (ID: %)', updated_count, your_user_id;
END $$;

-- ========================================
-- 4. VÉRIFICATION APRÈS ASSIGNATION
-- ========================================

-- Vérifier que tous les clients sont maintenant à vous
SELECT 
    'VÉRIFICATION APRÈS ASSIGNATION' as check_type,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN created_by = auth.uid() THEN 1 END) as your_clients,
    COUNT(CASE WHEN created_by IS NULL THEN 1 END) as clients_without_creator,
    COUNT(CASE WHEN created_by != auth.uid() AND created_by IS NOT NULL THEN 1 END) as other_users_clients
FROM public.clients;

-- Lister vos clients (sans colonne company)
SELECT 
    'VOS CLIENTS' as check_type,
    id,
    first_name,
    last_name,
    email,
    phone,
    address,
    city,
    created_at
FROM public.clients 
WHERE created_by = auth.uid()
ORDER BY created_at DESC;

-- ========================================
-- 5. CRÉER UNE FONCTION POUR AJOUTER UN CLIENT (SANS COMPANY)
-- ========================================

-- Fonction pour ajouter un client qui sera automatiquement assigné à vous
CREATE OR REPLACE FUNCTION add_my_client(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_postal_code TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client assigné à vous (sans colonne company)
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté et assigné à votre compte'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction
GRANT EXECUTE ON FUNCTION add_my_client(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- ========================================
-- 6. CRÉER UNE FONCTION POUR VÉRIFIER VOS CLIENTS
-- ========================================

-- Fonction pour vérifier que vous voyez bien vos clients
CREATE OR REPLACE FUNCTION check_my_clients()
RETURNS JSON AS $$
DECLARE
    your_user_id UUID;
    client_count INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter vos clients
    SELECT COUNT(*) INTO client_count FROM public.clients WHERE created_by = your_user_id;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'your_clients_count', client_count,
        'message', 'Vérification de vos clients terminée'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction
GRANT EXECUTE ON FUNCTION check_my_clients() TO authenticated;

-- ========================================
-- 7. TEST DE LA FONCTION
-- ========================================

-- Tester la fonction de vérification
SELECT check_my_clients() as verification_result;

-- ========================================
-- 8. AJOUTER LA COLONNE COMPANY SI NÉCESSAIRE
-- ========================================

-- Ajouter la colonne company si elle n'existe pas (optionnel)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'company'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN company TEXT;
        RAISE NOTICE 'Colonne company ajoutée à la table clients';
    ELSE
        RAISE NOTICE 'Colonne company existe déjà dans la table clients';
    END IF;
END $$;

-- ========================================
-- 9. CRÉER UNE FONCTION COMPLÈTE AVEC COMPANY (SI AJOUTÉE)
-- ========================================

-- Fonction complète pour ajouter un client avec company (si la colonne existe)
CREATE OR REPLACE FUNCTION add_my_client_complete(
    p_first_name TEXT,
    p_last_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_postal_code TEXT DEFAULT NULL,
    p_company TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client assigné à vous (avec company si disponible)
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté et assigné à votre compte'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction complète
GRANT EXECUTE ON FUNCTION add_my_client_complete(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- ========================================
-- 10. MESSAGES DE CONFIRMATION
-- ========================================

DO $$
DECLARE
    your_user_id UUID;
    your_clients_count INTEGER;
BEGIN
    your_user_id := auth.uid();
    SELECT COUNT(*) INTO your_clients_count FROM public.clients WHERE created_by = your_user_id;
    
    RAISE NOTICE '🎯 ASSIGNATION DES CLIENTS TERMINÉE !';
    RAISE NOTICE '✅ Tous les clients assignés à votre compte';
    RAISE NOTICE '✅ Votre ID utilisateur: %', your_user_id;
    RAISE NOTICE '✅ Nombre de vos clients: %', your_clients_count;
    RAISE NOTICE '✅ Colonne company ajoutée si nécessaire';
    RAISE NOTICE '';
    RAISE NOTICE '📋 TESTEZ MAINTENANT:';
    RAISE NOTICE '1. Rechargez votre page clients';
    RAISE NOTICE '2. Vous devriez voir tous vos clients';
    RAISE NOTICE '3. Testez l''ajout d''un nouveau client';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FONCTIONS DISPONIBLES:';
    RAISE NOTICE '- add_my_client(...) pour ajouter un client (sans company)';
    RAISE NOTICE '- add_my_client_complete(...) pour ajouter un client (avec company)';
    RAISE NOTICE '- check_my_clients() pour vérifier vos clients';
    RAISE NOTICE '';
    RAISE NOTICE '✅ VOS CLIENTS SONT MAINTENANT VISIBLES !';
END $$;
