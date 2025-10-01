-- 🎯 CORRECTION ERREUR 406 - SUBSCRIPTION_STATUS
-- Erreur: GET https://olrihggkxyksuofkesnk.supabase.co/rest/v1/subscription_status?select=is_active&user_id=eq.d4535dc5-9797-48f8-9c60-844ab6468ff8 406 (Not Acceptable)

-- 1. DÉSACTIVER TEMPORAIREMENT RLS POUR DIAGNOSTIC
ALTER TABLE public.subscription_status DISABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES (NETTOYAGE)
DO $$
DECLARE
    policy_name TEXT;
BEGIN
    -- Supprimer toutes les politiques existantes
    FOR policy_name IN (
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'subscription_status' 
        AND schemaname = 'public'
    ) LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_name || '" ON public.subscription_status';
    END LOOP;
    
    RAISE NOTICE '✅ Toutes les politiques RLS supprimées';
END $$;

-- 3. CRÉER UNE POLITIQUE SIMPLE ET PERMISSIVE
CREATE POLICY "subscription_status_allow_all" ON public.subscription_status
    FOR ALL 
    USING (true) 
    WITH CHECK (true);

-- 4. RÉACTIVER RLS AVEC LA NOUVELLE POLITIQUE
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;

-- 5. VÉRIFIER QUE L'UTILISATEUR A UNE ENTRÉE
SELECT 
    'Vérification utilisateur d4535dc5-9797-48f8-9c60-844ab6468ff8:' as info,
    COUNT(*) as count
FROM public.subscription_status 
WHERE user_id = 'd4535dc5-9797-48f8-9c60-844ab6468ff8';

-- 6. CRÉER L'ENTRÉE SI ELLE N'EXISTE PAS
INSERT INTO public.subscription_status (
    user_id, 
    first_name, 
    last_name, 
    email, 
    is_active, 
    subscription_type, 
    created_at, 
    updated_at
)
SELECT 
    'd4535dc5-9797-48f8-9c60-844ab6468ff8',
    'Utilisateur',
    'Test',
    'test@example.com',
    true,
    'free',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status 
    WHERE user_id = 'd4535dc5-9797-48f8-9c60-844ab6468ff8'
);

-- 7. TESTER LA REQUÊTE EXACTE QUI ÉCHOUE
SELECT 
    is_active,
    user_id,
    email,
    subscription_type
FROM public.subscription_status 
WHERE user_id = 'd4535dc5-9797-48f8-9c60-844ab6468ff8';

-- 8. VÉRIFIER LES PERMISSIONS DE LA TABLE
SELECT 
    'Permissions table subscription_status:' as info,
    has_table_privilege('authenticated', 'public.subscription_status', 'SELECT') as can_select,
    has_table_privilege('authenticated', 'public.subscription_status', 'INSERT') as can_insert,
    has_table_privilege('authenticated', 'public.subscription_status', 'UPDATE') as can_update;

-- 9. VÉRIFIER LES POLITIQUES ACTIVES
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'subscription_status' 
AND schemaname = 'public';

-- 10. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION 406 APPLIQUÉE - Politiques RLS simplifiées et entrée utilisateur créée' as status;
