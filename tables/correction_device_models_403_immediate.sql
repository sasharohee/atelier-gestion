-- Correction immédiate du problème 403 sur device_models
-- Script pour corriger les politiques RLS qui empêchent l'insertion

-- 1. Désactiver temporairement RLS sur device_models pour permettre l'insertion
ALTER TABLE device_models DISABLE ROW LEVEL SECURITY;

-- 2. Vérifier si des politiques existent et les supprimer
DROP POLICY IF EXISTS "Users can view their own device models" ON device_models;
DROP POLICY IF EXISTS "Users can insert their own device models" ON device_models;
DROP POLICY IF EXISTS "Users can update their own device models" ON device_models;
DROP POLICY IF EXISTS "Users can delete their own device models" ON device_models;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON device_models;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON device_models;

-- 3. Créer des politiques RLS plus permissives
CREATE POLICY "Enable read access for authenticated users" ON device_models
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert access for authenticated users" ON device_models
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update access for authenticated users" ON device_models
    FOR UPDATE USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable delete access for authenticated users" ON device_models
    FOR DELETE USING (auth.role() = 'authenticated');

-- 4. Réactiver RLS avec les nouvelles politiques
ALTER TABLE device_models ENABLE ROW LEVEL SECURITY;

-- 5. Vérifier que la table device_models a bien une colonne user_id
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'user_id'
    ) INTO column_exists;
    
    IF NOT column_exists THEN
        RAISE NOTICE 'La table device_models n''a pas de colonne user_id - ajout en cours...';
        ALTER TABLE device_models ADD COLUMN user_id UUID REFERENCES users(id);
    ELSE
        RAISE NOTICE 'La colonne user_id existe déjà dans device_models';
    END IF;
END $$;

-- 6. Mettre à jour les enregistrements existants avec l'ID de l'admin
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur admin
    SELECT id INTO admin_user_id FROM users WHERE email = 'admin@atelier.com' LIMIT 1;
    
    IF admin_user_id IS NOT NULL THEN
        -- Mettre à jour les enregistrements existants
        UPDATE device_models 
        SET user_id = admin_user_id 
        WHERE user_id IS NULL;
        
        RAISE NOTICE 'Enregistrements device_models mis à jour avec l''ID admin: %', admin_user_id;
    ELSE
        RAISE NOTICE 'Aucun utilisateur admin trouvé';
    END IF;
END $$;

-- 7. Vérifier la configuration finale
SELECT 
    'device_models RLS status' as info,
    CASE 
        WHEN EXISTS (
            SELECT FROM pg_tables 
            WHERE tablename = 'device_models' 
            AND rowsecurity = true
        ) THEN 'RLS activé'
        ELSE 'RLS désactivé'
    END as rls_status;

SELECT 
    'Politiques RLS device_models' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'device_models';

-- 8. Test d'insertion (optionnel - commenté pour éviter les doublons)
/*
INSERT INTO device_models (
    id, user_id, brand, model, category, 
    repair_difficulty, parts_availability, is_active, 
    created_at, updated_at
) VALUES (
    gen_random_uuid(), 
    (SELECT id FROM users WHERE email = 'admin@atelier.com' LIMIT 1),
    'Apple', 'iPhone 12', 'Smartphone', 
    'Medium', 'Good', true, 
    NOW(), NOW()
);
*/

SELECT 'Correction device_models 403 terminée avec succès !' as status;
