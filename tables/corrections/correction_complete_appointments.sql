-- Correction complète de la table appointments
-- Problème: Colonne user_id manquante et contrainte NOT NULL violée

-- 1. Vérifier la structure actuelle de la table appointments
SELECT 
    'Structure actuelle' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'appointments' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes sur la table appointments
SELECT 
    'Contraintes' as info,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'appointments' 
AND table_schema = 'public';

-- 3. Créer l'utilisateur système s'il n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = '00000000-0000-0000-0000-000000000000') THEN
        INSERT INTO public.users (id, email, created_at, updated_at)
        VALUES ('00000000-0000-0000-0000-000000000000', 'system@atelier.com', NOW(), NOW());
        RAISE NOTICE '✅ Utilisateur système créé';
    ELSE
        RAISE NOTICE 'ℹ️ Utilisateur système existe déjà';
    END IF;
END $$;

-- 4. Ajouter la colonne user_id si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'user_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN user_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES public.users(id);
        
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne user_id existe déjà';
    END IF;
END $$;

-- 5. Mettre à jour les enregistrements existants avec user_id null
UPDATE public.appointments 
SET user_id = '00000000-0000-0000-0000-000000000000' 
WHERE user_id IS NULL;

-- 6. Ajouter la colonne assigned_user_id si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'assigned_user_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN assigned_user_id UUID REFERENCES public.users(id);
        
        RAISE NOTICE '✅ Colonne assigned_user_id ajoutée à la table appointments';
    ELSE
        RAISE NOTICE 'ℹ️ Colonne assigned_user_id existe déjà';
    END IF;
END $$;

-- 7. Vérifier que toutes les colonnes nécessaires existent
DO $$
BEGIN
    -- Vérifier client_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'client_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN client_id UUID REFERENCES public.clients(id);
        RAISE NOTICE '✅ Colonne client_id ajoutée';
    END IF;
    
    -- Vérifier repair_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'repair_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN repair_id UUID REFERENCES public.repairs(id);
        RAISE NOTICE '✅ Colonne repair_id ajoutée';
    END IF;
    
    -- Vérifier title
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'title'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN title TEXT NOT NULL DEFAULT 'Rendez-vous';
        RAISE NOTICE '✅ Colonne title ajoutée';
    END IF;
    
    -- Vérifier description
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'description'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN description TEXT;
        RAISE NOTICE '✅ Colonne description ajoutée';
    END IF;
    
    -- Vérifier start_date
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'start_date'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN start_date TIMESTAMP WITH TIME ZONE NOT NULL;
        RAISE NOTICE '✅ Colonne start_date ajoutée';
    END IF;
    
    -- Vérifier end_date
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'end_date'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN end_date TIMESTAMP WITH TIME ZONE NOT NULL;
        RAISE NOTICE '✅ Colonne end_date ajoutée';
    END IF;
    
    -- Vérifier status
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'status'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN status TEXT NOT NULL DEFAULT 'scheduled';
        RAISE NOTICE '✅ Colonne status ajoutée';
    END IF;
    
    -- Vérifier created_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'created_at'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne created_at ajoutée';
    END IF;
    
    -- Vérifier updated_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'updated_at'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.appointments 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne updated_at ajoutée';
    END IF;
END $$;

-- 8. Créer les politiques RLS pour appointments
DROP POLICY IF EXISTS "Users can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can delete own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can create appointments" ON public.appointments;

CREATE POLICY "Users can view own appointments" ON public.appointments
    FOR SELECT USING (true); -- Tous les utilisateurs peuvent voir tous les rendez-vous

CREATE POLICY "Users can update own appointments" ON public.appointments
    FOR UPDATE USING (true); -- Tous les utilisateurs peuvent modifier tous les rendez-vous

CREATE POLICY "Users can delete own appointments" ON public.appointments
    FOR DELETE USING (true); -- Tous les utilisateurs peuvent supprimer tous les rendez-vous

CREATE POLICY "Users can create appointments" ON public.appointments
    FOR INSERT WITH CHECK (true); -- Tous les utilisateurs peuvent créer des rendez-vous

-- 9. Vérification finale
SELECT 
    'Structure finale table appointments' as type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'appointments' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 10. Vérifier les politiques RLS
SELECT 
    'Politiques appointments' as type,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'appointments'
AND schemaname = 'public'
ORDER BY policyname;

-- 11. Vérifier les données existantes
SELECT 
    'Données existantes' as info,
    COUNT(*) as total_appointments,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as appointments_sans_user_id
FROM public.appointments;
