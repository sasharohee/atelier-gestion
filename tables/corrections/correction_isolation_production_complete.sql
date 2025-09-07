-- =====================================================
-- CORRECTION ISOLATION PRODUCTION COMPLÈTE
-- =====================================================
-- Script pour corriger définitivement l'isolation en production
-- Applique toutes les corrections nécessaires
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état initial
SELECT '=== ÉTAT INITIAL ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN (
    'clients', 'repairs', 'product_categories', 'device_categories', 
    'device_brands', 'device_models', 'parts', 'products', 'services'
)
ORDER BY tablename;

-- 2. Activer RLS sur toutes les tables critiques
SELECT '=== ACTIVATION RLS ===' as etape;

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- 3. Supprimer toutes les politiques existantes
SELECT '=== NETTOYAGE POLITIQUES ===' as etape;

-- Clients
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.clients;
DROP POLICY IF EXISTS "Users can view their own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can insert their own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update their own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete their own clients" ON public.clients;
DROP POLICY IF EXISTS "clients_select_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_update_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_policy" ON public.clients;

-- Réparations
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.repairs;
DROP POLICY IF EXISTS "Users can view their own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can insert their own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can update their own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can delete their own repairs" ON public.repairs;
DROP POLICY IF EXISTS "repairs_select_policy" ON public.repairs;
DROP POLICY IF EXISTS "repairs_insert_policy" ON public.repairs;
DROP POLICY IF EXISTS "repairs_update_policy" ON public.repairs;
DROP POLICY IF EXISTS "repairs_delete_policy" ON public.repairs;

-- Catégories de produits
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.product_categories;
DROP POLICY IF EXISTS "Users can view their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "Users can insert their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "Users can update their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "Users can delete their own product categories" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_select_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_insert_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_update_policy" ON public.product_categories;
DROP POLICY IF EXISTS "product_categories_delete_policy" ON public.product_categories;

-- Catégories d'appareils
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.device_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.device_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.device_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.device_categories;
DROP POLICY IF EXISTS "Users can view their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can insert their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can update their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "Users can delete their own device categories" ON public.device_categories;
DROP POLICY IF EXISTS "device_categories_select_policy" ON public.device_categories;
DROP POLICY IF EXISTS "device_categories_insert_policy" ON public.device_categories;
DROP POLICY IF EXISTS "device_categories_update_policy" ON public.device_categories;
DROP POLICY IF EXISTS "device_categories_delete_policy" ON public.device_categories;

-- Marques d'appareils
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.device_brands;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.device_brands;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.device_brands;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.device_brands;
DROP POLICY IF EXISTS "Users can view their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can insert their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can update their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "Users can delete their own device brands" ON public.device_brands;
DROP POLICY IF EXISTS "device_brands_select_policy" ON public.device_brands;
DROP POLICY IF EXISTS "device_brands_insert_policy" ON public.device_brands;
DROP POLICY IF EXISTS "device_brands_update_policy" ON public.device_brands;
DROP POLICY IF EXISTS "device_brands_delete_policy" ON public.device_brands;

-- Modèles d'appareils
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.device_models;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.device_models;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.device_models;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.device_models;
DROP POLICY IF EXISTS "Users can view their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can insert their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can update their own device models" ON public.device_models;
DROP POLICY IF EXISTS "Users can delete their own device models" ON public.device_models;
DROP POLICY IF EXISTS "device_models_select_policy" ON public.device_models;
DROP POLICY IF EXISTS "device_models_insert_policy" ON public.device_models;
DROP POLICY IF EXISTS "device_models_update_policy" ON public.device_models;
DROP POLICY IF EXISTS "device_models_delete_policy" ON public.device_models;

-- Pièces
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.parts;
DROP POLICY IF EXISTS "Users can view their own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can insert their own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can update their own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can delete their own parts" ON public.parts;
DROP POLICY IF EXISTS "parts_select_policy" ON public.parts;
DROP POLICY IF EXISTS "parts_insert_policy" ON public.parts;
DROP POLICY IF EXISTS "parts_update_policy" ON public.parts;
DROP POLICY IF EXISTS "parts_delete_policy" ON public.parts;

-- Produits
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.products;
DROP POLICY IF EXISTS "Users can view their own products" ON public.products;
DROP POLICY IF EXISTS "Users can insert their own products" ON public.products;
DROP POLICY IF EXISTS "Users can update their own products" ON public.products;
DROP POLICY IF EXISTS "Users can delete their own products" ON public.products;
DROP POLICY IF EXISTS "products_select_policy" ON public.products;
DROP POLICY IF EXISTS "products_insert_policy" ON public.products;
DROP POLICY IF EXISTS "products_update_policy" ON public.products;
DROP POLICY IF EXISTS "products_delete_policy" ON public.products;

-- Services
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Users can view their own services" ON public.services;
DROP POLICY IF EXISTS "Users can insert their own services" ON public.services;
DROP POLICY IF EXISTS "Users can update their own services" ON public.services;
DROP POLICY IF EXISTS "Users can delete their own services" ON public.services;
DROP POLICY IF EXISTS "services_select_policy" ON public.services;
DROP POLICY IF EXISTS "services_insert_policy" ON public.services;
DROP POLICY IF EXISTS "services_update_policy" ON public.services;
DROP POLICY IF EXISTS "services_delete_policy" ON public.services;

-- 4. Créer les nouvelles politiques RLS strictes
SELECT '=== CRÉATION POLITIQUES RLS STRICTES ===' as etape;

-- Politiques pour clients
CREATE POLICY "clients_select_policy" ON public.clients
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "clients_insert_policy" ON public.clients
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "clients_update_policy" ON public.clients
    FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "clients_delete_policy" ON public.clients
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour réparations
CREATE POLICY "repairs_select_policy" ON public.repairs
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "repairs_insert_policy" ON public.repairs
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "repairs_update_policy" ON public.repairs
    FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "repairs_delete_policy" ON public.repairs
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour catégories de produits
CREATE POLICY "product_categories_select_policy" ON public.product_categories
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "product_categories_insert_policy" ON public.product_categories
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "product_categories_update_policy" ON public.product_categories
    FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "product_categories_delete_policy" ON public.product_categories
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour catégories d'appareils
CREATE POLICY "device_categories_select_policy" ON public.device_categories
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "device_categories_insert_policy" ON public.device_categories
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "device_categories_update_policy" ON public.device_categories
    FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "device_categories_delete_policy" ON public.device_categories
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour marques d'appareils
CREATE POLICY "device_brands_select_policy" ON public.device_brands
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "device_brands_insert_policy" ON public.device_brands
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "device_brands_update_policy" ON public.device_brands
    FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "device_brands_delete_policy" ON public.device_brands
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour modèles d'appareils
CREATE POLICY "device_models_select_policy" ON public.device_models
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "device_models_insert_policy" ON public.device_models
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "device_models_update_policy" ON public.device_models
    FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "device_models_delete_policy" ON public.device_models
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour pièces
CREATE POLICY "parts_select_policy" ON public.parts
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "parts_insert_policy" ON public.parts
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "parts_update_policy" ON public.parts
    FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "parts_delete_policy" ON public.parts
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour produits
CREATE POLICY "products_select_policy" ON public.products
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "products_insert_policy" ON public.products
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "products_update_policy" ON public.products
    FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "products_delete_policy" ON public.products
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour services
CREATE POLICY "services_select_policy" ON public.services
    FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "services_insert_policy" ON public.services
    FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "services_update_policy" ON public.services
    FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "services_delete_policy" ON public.services
    FOR DELETE USING (user_id = auth.uid());

-- 5. S'assurer que les colonnes user_id existent
SELECT '=== VÉRIFICATION COLONNES user_id ===' as etape;

ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.repairs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.product_categories ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_categories ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_brands ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.device_models ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 6. Mettre à jour les données existantes sans user_id
SELECT '=== MISE À JOUR DONNÉES EXISTANTES ===' as etape;

-- Utiliser un UUID par défaut pour les données sans user_id
UPDATE public.clients SET user_id = '00000000-0000-0000-0000-000000000000'::UUID WHERE user_id IS NULL;
UPDATE public.repairs SET user_id = '00000000-0000-0000-0000-000000000000'::UUID WHERE user_id IS NULL;
UPDATE public.product_categories SET user_id = '00000000-0000-0000-0000-000000000000'::UUID WHERE user_id IS NULL;
UPDATE public.device_categories SET user_id = '00000000-0000-0000-0000-000000000000'::UUID WHERE user_id IS NULL;
UPDATE public.device_brands SET user_id = '00000000-0000-0000-0000-000000000000'::UUID WHERE user_id IS NULL;
UPDATE public.device_models SET user_id = '00000000-0000-0000-0000-000000000000'::UUID WHERE user_id IS NULL;
UPDATE public.parts SET user_id = '00000000-0000-0000-0000-000000000000'::UUID WHERE user_id IS NULL;
UPDATE public.products SET user_id = '00000000-0000-0000-0000-000000000000'::UUID WHERE user_id IS NULL;
UPDATE public.services SET user_id = '00000000-0000-0000-0000-000000000000'::UUID WHERE user_id IS NULL;

-- 7. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier le statut RLS
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN (
    'clients', 'repairs', 'product_categories', 'device_categories', 
    'device_brands', 'device_models', 'parts', 'products', 'services'
)
ORDER BY tablename;

-- Vérifier les politiques créées
SELECT 
    tablename,
    COUNT(*) as nombre_politiques
FROM pg_policies 
WHERE tablename IN (
    'clients', 'repairs', 'product_categories', 'device_categories', 
    'device_brands', 'device_models', 'parts', 'products', 'services'
)
GROUP BY tablename
ORDER BY tablename;

-- 8. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ RLS activé sur toutes les tables critiques' as message;
SELECT '✅ Politiques RLS strictes créées' as politiques;
SELECT '✅ Colonnes user_id ajoutées' as colonnes;
SELECT '✅ Données existantes mises à jour' as donnees;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION SUR VERCEL' as deploy;
SELECT 'ℹ️ Chaque utilisateur ne voit que ses propres données' as note;
