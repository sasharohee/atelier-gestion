-- =====================================================
-- SCRIPT DE CRÉATION DES TABLES CATÉGORIES, MARQUES ET MODÈLES
-- =====================================================
-- Crée les tables pour la gestion hiérarchique des appareils
-- Date: 2025-01-23
-- =====================================================

-- 1. CRÉER LA TABLE DES CATÉGORIES
CREATE TABLE IF NOT EXISTS public.device_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT 'smartphone',
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CRÉER LA TABLE DES MARQUES
CREATE TABLE IF NOT EXISTS public.device_brands (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    category_id UUID REFERENCES public.device_categories(id) ON DELETE CASCADE,
    description TEXT,
    logo TEXT,
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CRÉER LA TABLE DES MODÈLES
CREATE TABLE IF NOT EXISTS public.device_models (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    brand_id UUID REFERENCES public.device_brands(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.device_categories(id) ON DELETE CASCADE,
    year INTEGER DEFAULT EXTRACT(YEAR FROM NOW()),
    common_issues TEXT[] DEFAULT '{}',
    repair_difficulty TEXT DEFAULT 'medium' CHECK (repair_difficulty IN ('easy', 'medium', 'hard')),
    parts_availability TEXT DEFAULT 'medium' CHECK (parts_availability IN ('high', 'medium', 'low')),
    is_active BOOLEAN DEFAULT true,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. AJOUTER LES COLONNES MANQUANTES SI ELLES N'EXISTENT PAS
-- Device Categories
ALTER TABLE public.device_categories ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.device_categories ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.device_categories ADD COLUMN IF NOT EXISTS icon TEXT DEFAULT 'smartphone';
ALTER TABLE public.device_categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.device_categories ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_categories ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_categories ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.device_categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Device Brands
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.device_categories(id) ON DELETE CASCADE;
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS logo TEXT;
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Device Models
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS brand_id UUID REFERENCES public.device_brands(id) ON DELETE CASCADE;
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.device_categories(id) ON DELETE CASCADE;
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS year INTEGER DEFAULT EXTRACT(YEAR FROM NOW());
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS common_issues TEXT[] DEFAULT '{}';
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS repair_difficulty TEXT DEFAULT 'medium';
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS parts_availability TEXT DEFAULT 'medium';
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 5. CRÉER LES INDEX POUR LES PERFORMANCES
CREATE INDEX IF NOT EXISTS idx_device_categories_user_id ON public.device_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_device_categories_created_by ON public.device_categories(created_by);
CREATE INDEX IF NOT EXISTS idx_device_categories_name ON public.device_categories(name);

CREATE INDEX IF NOT EXISTS idx_device_brands_user_id ON public.device_brands(user_id);
CREATE INDEX IF NOT EXISTS idx_device_brands_created_by ON public.device_brands(created_by);
CREATE INDEX IF NOT EXISTS idx_device_brands_category_id ON public.device_brands(category_id);
CREATE INDEX IF NOT EXISTS idx_device_brands_name ON public.device_brands(name);

CREATE INDEX IF NOT EXISTS idx_device_models_user_id ON public.device_models(user_id);
CREATE INDEX IF NOT EXISTS idx_device_models_created_by ON public.device_models(created_by);
CREATE INDEX IF NOT EXISTS idx_device_models_brand_id ON public.device_models(brand_id);
CREATE INDEX IF NOT EXISTS idx_device_models_category_id ON public.device_models(category_id);
CREATE INDEX IF NOT EXISTS idx_device_models_name ON public.device_models(name);

-- 6. CRÉER LES TRIGGERS POUR METTRE À JOUR updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_device_categories_updated_at 
    BEFORE UPDATE ON public.device_categories 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_device_brands_updated_at 
    BEFORE UPDATE ON public.device_brands 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_device_models_updated_at 
    BEFORE UPDATE ON public.device_models 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. CRÉER LES TRIGGERS POUR DÉFINIR AUTOMATIQUEMENT user_id ET created_by
CREATE OR REPLACE FUNCTION set_device_category_context()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Définir les valeurs par défaut
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION set_device_brand_context()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Définir les valeurs par défaut
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION set_device_model_context()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Définir les valeurs par défaut
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_device_category_context_trigger
    BEFORE INSERT ON public.device_categories
    FOR EACH ROW EXECUTE FUNCTION set_device_category_context();

CREATE TRIGGER set_device_brand_context_trigger
    BEFORE INSERT ON public.device_brands
    FOR EACH ROW EXECUTE FUNCTION set_device_brand_context();

CREATE TRIGGER set_device_model_context_trigger
    BEFORE INSERT ON public.device_models
    FOR EACH ROW EXECUTE FUNCTION set_device_model_context();

-- 8. ACTIVER RLS (ROW LEVEL SECURITY)
ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models ENABLE ROW LEVEL SECURITY;

-- 9. CRÉER LES POLITIQUES RLS
-- Politiques pour device_categories
CREATE POLICY "Users can view their own device categories" ON public.device_categories
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own device categories" ON public.device_categories
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own device categories" ON public.device_categories
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own device categories" ON public.device_categories
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour device_brands
CREATE POLICY "Users can view their own device brands" ON public.device_brands
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own device brands" ON public.device_brands
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own device brands" ON public.device_brands
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own device brands" ON public.device_brands
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour device_models
CREATE POLICY "Users can view their own device models" ON public.device_models
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own device models" ON public.device_models
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own device models" ON public.device_models
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own device models" ON public.device_models
    FOR DELETE USING (user_id = auth.uid());

-- 10. INSÉRER LES DONNÉES DE TEST
DO $$
DECLARE
    v_user_id UUID;
    v_smartphone_category_id UUID;
    v_tablet_category_id UUID;
    v_laptop_category_id UUID;
    v_desktop_category_id UUID;
    v_apple_brand_id UUID;
    v_samsung_brand_id UUID;
    v_dell_brand_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel ou le premier utilisateur
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE 'Aucun utilisateur trouvé, impossible d''insérer les données de test';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Insertion des données de test pour l''utilisateur: %', v_user_id;
    
    -- Insérer les catégories
    INSERT INTO public.device_categories (name, description, icon, user_id, created_by)
    VALUES 
        ('Smartphones', 'Téléphones mobiles et smartphones', 'smartphone', v_user_id, v_user_id),
        ('Tablettes', 'Tablettes tactiles', 'tablet', v_user_id, v_user_id),
        ('Ordinateurs portables', 'Laptops et notebooks', 'laptop', v_user_id, v_user_id),
        ('Ordinateurs fixes', 'PC de bureau et stations de travail', 'desktop', v_user_id, v_user_id)
    RETURNING id INTO v_smartphone_category_id;
    
    -- Récupérer les IDs des catégories
    SELECT id INTO v_smartphone_category_id FROM public.device_categories WHERE name = 'Smartphones' AND user_id = v_user_id LIMIT 1;
    SELECT id INTO v_tablet_category_id FROM public.device_categories WHERE name = 'Tablettes' AND user_id = v_user_id LIMIT 1;
    SELECT id INTO v_laptop_category_id FROM public.device_categories WHERE name = 'Ordinateurs portables' AND user_id = v_user_id LIMIT 1;
    SELECT id INTO v_desktop_category_id FROM public.device_categories WHERE name = 'Ordinateurs fixes' AND user_id = v_user_id LIMIT 1;
    
    -- Insérer les marques
    INSERT INTO public.device_brands (name, category_id, description, user_id, created_by)
    VALUES 
        ('Apple', v_smartphone_category_id, 'Fabricant américain de produits électroniques', v_user_id, v_user_id),
        ('Samsung', v_smartphone_category_id, 'Fabricant coréen d''électronique', v_user_id, v_user_id),
        ('Dell', v_laptop_category_id, 'Fabricant américain d''ordinateurs', v_user_id, v_user_id);
    
    -- Récupérer les IDs des marques
    SELECT id INTO v_apple_brand_id FROM public.device_brands WHERE name = 'Apple' AND user_id = v_user_id LIMIT 1;
    SELECT id INTO v_samsung_brand_id FROM public.device_brands WHERE name = 'Samsung' AND user_id = v_user_id LIMIT 1;
    SELECT id INTO v_dell_brand_id FROM public.device_brands WHERE name = 'Dell' AND user_id = v_user_id LIMIT 1;
    
    -- Insérer quelques modèles de test
    INSERT INTO public.device_models (name, brand_id, category_id, year, common_issues, repair_difficulty, parts_availability, user_id, created_by)
    VALUES 
        ('iPhone 14', v_apple_brand_id, v_smartphone_category_id, 2022, ARRAY['Écran cassé', 'Batterie défaillante'], 'medium', 'high', v_user_id, v_user_id),
        ('Galaxy S23', v_samsung_brand_id, v_smartphone_category_id, 2023, ARRAY['Port de charge', 'Haut-parleur'], 'easy', 'high', v_user_id, v_user_id),
        ('XPS 13', v_dell_brand_id, v_laptop_category_id, 2023, ARRAY['Clavier défaillant', 'Ventilateur bruyant'], 'hard', 'medium', v_user_id, v_user_id);
    
    RAISE NOTICE '✅ Données de test insérées avec succès';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de l''insertion des données de test: %', SQLERRM;
END $$;

-- 11. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION DES TABLES CRÉÉES ===' as etape;

SELECT 
    'device_categories' as table_name,
    COUNT(*) as nombre_enregistrements
FROM public.device_categories
UNION ALL
SELECT 
    'device_brands' as table_name,
    COUNT(*) as nombre_enregistrements
FROM public.device_brands
UNION ALL
SELECT 
    'device_models' as table_name,
    COUNT(*) as nombre_enregistrements
FROM public.device_models;

SELECT '=== SCRIPT TERMINÉ AVEC SUCCÈS ===' as etape;
