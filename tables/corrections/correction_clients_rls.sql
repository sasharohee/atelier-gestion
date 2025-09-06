-- Correction des politiques RLS pour la table clients
-- Date: 2024-01-24
-- Solution pour permettre l'affichage des clients après activation RLS

-- ========================================
-- 1. VÉRIFIER LA STRUCTURE DE LA TABLE CLIENTS
-- ========================================

-- Vérifier si la table clients existe et sa structure
SELECT 
    'VÉRIFICATION TABLE CLIENTS' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients'
ORDER BY ordinal_position;

-- Vérifier les politiques RLS actuelles sur clients
SELECT 
    'POLITIQUES CLIENTS ACTUELLES' as check_type,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'clients';

-- ========================================
-- 2. SUPPRIMER LES POLITIQUES CLIENTS PROBLÉMATIQUES
-- ========================================

-- Supprimer toutes les politiques existantes sur clients
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can insert own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can view clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can insert clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can update clients" ON public.clients;
DROP POLICY IF EXISTS "Authenticated users can delete clients" ON public.clients;

-- ========================================
-- 3. CRÉER LA TABLE CLIENTS SI ELLE N'EXISTE PAS
-- ========================================

-- Créer la table clients avec une structure standard
CREATE TABLE IF NOT EXISTS public.clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    postal_code TEXT,
    notes TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- 4. ACTIVER RLS SUR CLIENTS
-- ========================================

-- Activer RLS sur la table clients
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 5. CRÉER DES POLITIQUES RLS FLEXIBLES POUR CLIENTS
-- ========================================

-- Politique pour SELECT - permettre aux utilisateurs de voir leurs clients
-- Si la colonne created_by existe, l'utiliser, sinon permettre à tous les utilisateurs authentifiés
DO $$
BEGIN
    -- Vérifier si la colonne created_by existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'created_by'
    ) THEN
        -- Créer des politiques avec created_by
        EXECUTE 'CREATE POLICY "clients_select_own" ON public.clients FOR SELECT USING (created_by = auth.uid())';
        EXECUTE 'CREATE POLICY "clients_insert_own" ON public.clients FOR INSERT WITH CHECK (created_by = auth.uid())';
        EXECUTE 'CREATE POLICY "clients_update_own" ON public.clients FOR UPDATE USING (created_by = auth.uid())';
        EXECUTE 'CREATE POLICY "clients_delete_own" ON public.clients FOR DELETE USING (created_by = auth.uid())';
        
        -- Politique pour les admins
        EXECUTE 'CREATE POLICY "clients_admin_all" ON public.clients FOR ALL USING (
            auth.jwt() ->> ''email'' IN (''srohee32@gmail.com'', ''repphonereparation@gmail.com'')
        )';
        
        RAISE NOTICE 'Politiques créées pour clients avec created_by';
    ELSE
        -- Créer des politiques sans created_by (accès pour tous les utilisateurs authentifiés)
        EXECUTE 'CREATE POLICY "clients_select_authenticated" ON public.clients FOR SELECT USING (auth.role() = ''authenticated'')';
        EXECUTE 'CREATE POLICY "clients_insert_authenticated" ON public.clients FOR INSERT WITH CHECK (auth.role() = ''authenticated'')';
        EXECUTE 'CREATE POLICY "clients_update_authenticated" ON public.clients FOR UPDATE USING (auth.role() = ''authenticated'')';
        EXECUTE 'CREATE POLICY "clients_delete_authenticated" ON public.clients FOR DELETE USING (auth.role() = ''authenticated'')';
        
        RAISE NOTICE 'Politiques créées pour clients sans created_by (accès authentifié)';
    END IF;
    
    -- Politique pour le service role (nécessaire pour les opérations système)
    EXECUTE 'CREATE POLICY "clients_service_role" ON public.clients FOR ALL USING (auth.role() = ''service_role'')';
    
END $$;

-- ========================================
-- 6. AJOUTER LA COLONNE CREATED_BY SI ELLE N'EXISTE PAS
-- ========================================

-- Ajouter la colonne created_by si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'clients' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE 'Colonne created_by ajoutée à la table clients';
    ELSE
        RAISE NOTICE 'Colonne created_by existe déjà dans la table clients';
    END IF;
END $$;

-- ========================================
-- 7. METTRE À JOUR LES CLIENTS EXISTANTS
-- ========================================

-- Mettre à jour les clients existants qui n'ont pas de created_by
-- Assigner le premier utilisateur admin comme créateur par défaut
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Récupérer l'ID du premier utilisateur admin
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email IN ('srohee32@gmail.com', 'repphonereparation@gmail.com')
    LIMIT 1;
    
    -- Si aucun admin trouvé, prendre le premier utilisateur
    IF admin_user_id IS NULL THEN
        SELECT id INTO admin_user_id FROM auth.users LIMIT 1;
    END IF;
    
    -- Mettre à jour les clients sans created_by
    IF admin_user_id IS NOT NULL THEN
        UPDATE public.clients 
        SET created_by = admin_user_id 
        WHERE created_by IS NULL;
        
        RAISE NOTICE 'Clients existants mis à jour avec created_by: %', admin_user_id;
    ELSE
        RAISE NOTICE 'Aucun utilisateur trouvé pour assigner created_by';
    END IF;
END $$;

-- ========================================
-- 8. CRÉER UNE FONCTION POUR AJOUTER UN CLIENT
-- ========================================

-- Fonction pour ajouter un client avec created_by automatique
CREATE OR REPLACE FUNCTION add_client(
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
    current_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_notes, current_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permissions pour la fonction
GRANT EXECUTE ON FUNCTION add_client(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- ========================================
-- 9. VÉRIFICATIONS FINALES
-- ========================================

-- Vérifier la structure finale de la table clients
SELECT 
    'STRUCTURE FINALE CLIENTS' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients'
ORDER BY ordinal_position;

-- Vérifier les politiques RLS finales
SELECT 
    'POLITIQUES FINALES CLIENTS' as check_type,
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN '✅ Lecture'
        WHEN cmd = 'INSERT' THEN '✅ Insertion'
        WHEN cmd = 'UPDATE' THEN '✅ Modification'
        WHEN cmd = 'DELETE' THEN '✅ Suppression'
        WHEN cmd = 'ALL' THEN '✅ Toutes opérations'
        ELSE '⚠️ ' || cmd
    END as operation
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'clients'
ORDER BY cmd;

-- Compter les clients existants
SELECT 
    'COMPTE CLIENTS' as check_type,
    COUNT(*) as total_clients,
    COUNT(created_by) as clients_with_creator,
    COUNT(*) - COUNT(created_by) as clients_without_creator
FROM public.clients;

-- ========================================
-- 10. MESSAGES DE CONFIRMATION
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 CORRECTION CLIENTS TERMINÉE !';
    RAISE NOTICE '✅ Table clients vérifiée/créée';
    RAISE NOTICE '✅ RLS activé avec politiques flexibles';
    RAISE NOTICE '✅ Colonne created_by ajoutée si nécessaire';
    RAISE NOTICE '✅ Clients existants mis à jour';
    RAISE NOTICE '✅ Fonction add_client créée';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 POLITIQUES APPLIQUÉES:';
    RAISE NOTICE '- Utilisateurs peuvent voir leurs propres clients';
    RAISE NOTICE '- Admins peuvent voir tous les clients';
    RAISE NOTICE '- Service role a accès complet';
    RAISE NOTICE '';
    RAISE NOTICE '📋 TESTEZ MAINTENANT:';
    RAISE NOTICE '1. Rechargez votre page clients';
    RAISE NOTICE '2. Vos clients devraient maintenant s''afficher';
    RAISE NOTICE '3. Vous pouvez ajouter de nouveaux clients';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FONCTION DISPONIBLE:';
    RAISE NOTICE '- add_client(first_name, last_name, email, phone, address, city, postal_code, notes)';
END $$;
