-- FORCE CORRECTION RÉCURSION INFINIE - ULTRA SIMPLE
-- Ce script force la correction de manière agressive

-- 1. DÉSACTIVER RLS COMPLÈTEMENT
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER TOUTES LES POLITIQUES (FORCE)
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'users' 
        AND schemaname = 'public'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON public.users';
    END LOOP;
END $$;

-- 3. ATTENDRE
SELECT pg_sleep(2);

-- 4. RÉACTIVER RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 5. CRÉER UNE SEULE POLITIQUE SIMPLE
CREATE POLICY "simple_user_access" ON public.users 
FOR ALL USING (auth.uid() = id);

-- 6. VÉRIFICATION
SELECT 
    '✅ CORRECTION FORCÉE TERMINÉE' as status,
    COUNT(*) as policies_count
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';
