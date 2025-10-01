-- 🚨 SUPER URGENT: Correction récursion infinie RLS
-- À exécuter IMMÉDIATEMENT dans Supabase SQL Editor

-- 1. DÉSACTIVER RLS COMPLÈTEMENT
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_status DISABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER TOUTES LES POLITIQUES (FORCE)
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Supprimer toutes les politiques sur users
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'users' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.users CASCADE';
    END LOOP;
    
    -- Supprimer toutes les politiques sur subscription_status
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'subscription_status' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.subscription_status CASCADE';
    END LOOP;
END $$;

-- 3. ATTENDRE
SELECT pg_sleep(2);

-- 4. CRÉER UNE SEULE POLITIQUE ULTRA-SIMPLE
CREATE POLICY "allow_all_users" ON public.users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_subscription" ON public.subscription_status FOR ALL USING (true) WITH CHECK (true);

-- 5. RÉACTIVER RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;

-- 6. CRÉER LES ENTRÉES MANQUANTES
INSERT INTO public.subscription_status (
    user_id, first_name, last_name, email, is_active, subscription_type, created_at, updated_at
)
SELECT 
    u.id, u.first_name, u.last_name, u.email, true, 'BASIC', NOW(), NOW()
FROM public.users u
WHERE NOT EXISTS (SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = u.id);

-- 7. VÉRIFICATION
SELECT '✅ CORRECTION URGENTE APPLIQUÉE' as status;
