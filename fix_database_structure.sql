-- SCRIPT POUR CORRIGER LA STRUCTURE DE LA BASE DE DONNÉES
-- Ce script ajoute les tables et colonnes manquantes

-- 1. CRÉER LA TABLE system_settings SI ELLE N'EXISTE PAS
CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'general',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. AJOUTER LA COLONNE items À LA TABLE sales SI ELLE N'EXISTE PAS
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS items JSONB DEFAULT '[]'::jsonb;

-- 3. AJOUTER LA COLONNE user_id À LA TABLE sales SI ELLE N'EXISTE PAS
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 4. AJOUTER LA COLONNE user_id À LA TABLE system_settings SI ELLE N'EXISTE PAS
ALTER TABLE public.system_settings ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 5. CRÉER LA TABLE sale_items SI ELLE N'EXISTE PAS
CREATE TABLE IF NOT EXISTS public.sale_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_id UUID REFERENCES public.sales(id) ON DELETE CASCADE,
    item_type TEXT NOT NULL CHECK (item_type IN ('product', 'service', 'part')),
    item_id UUID NOT NULL,
    name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. AJOUTER LA COLONNE user_id À LA TABLE sale_items SI ELLE N'EXISTE PAS
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 7. CRÉER DES INDEX POUR LES PERFORMANCES
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON public.sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON public.sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_user_id ON public.sale_items(user_id);
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON public.system_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON public.system_settings(key);

-- 8. ACTIVER RLS SUR LES NOUVELLES TABLES
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

-- 9. CRÉER DES POLITIQUES RLS POUR system_settings
DROP POLICY IF EXISTS "Users can view own system settings" ON public.system_settings;
DROP POLICY IF EXISTS "Users can create own system settings" ON public.system_settings;
DROP POLICY IF EXISTS "Users can update own system settings" ON public.system_settings;
DROP POLICY IF EXISTS "Users can delete own system settings" ON public.system_settings;

CREATE POLICY "Users can view own system settings" ON public.system_settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own system settings" ON public.system_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own system settings" ON public.system_settings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own system settings" ON public.system_settings FOR DELETE USING (auth.uid() = user_id);

-- 10. CRÉER DES POLITIQUES RLS POUR sale_items
DROP POLICY IF EXISTS "Users can view own sale items" ON public.sale_items;
DROP POLICY IF EXISTS "Users can create own sale items" ON public.sale_items;
DROP POLICY IF EXISTS "Users can update own sale items" ON public.sale_items;
DROP POLICY IF EXISTS "Users can delete own sale items" ON public.sale_items;

CREATE POLICY "Users can view own sale items" ON public.sale_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own sale items" ON public.sale_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own sale items" ON public.sale_items FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own sale items" ON public.sale_items FOR DELETE USING (auth.uid() = user_id);

-- 11. INSÉRER DES PARAMÈTRES SYSTÈME PAR DÉFAUT
INSERT INTO public.system_settings (key, value, description, category) VALUES
('workshop_name', 'Mon Atelier', 'Nom de l''atelier', 'general'),
('workshop_address', '123 Rue de la Réparation', 'Adresse de l''atelier', 'general'),
('workshop_phone', '+33 1 23 45 67 89', 'Téléphone de l''atelier', 'general'),
('workshop_email', 'contact@monatelier.fr', 'Email de l''atelier', 'general'),
('tax_rate', '20', 'Taux de TVA (%)', 'billing'),
('currency', 'EUR', 'Devise utilisée', 'billing'),
('invoice_prefix', 'FACT-', 'Préfixe des factures', 'billing'),
('repair_status_pending', 'En attente', 'Statut par défaut des réparations', 'workflow'),
('repair_status_in_progress', 'En cours', 'Statut des réparations en cours', 'workflow'),
('repair_status_completed', 'Terminé', 'Statut des réparations terminées', 'workflow'),
('repair_status_cancelled', 'Annulé', 'Statut des réparations annulées', 'workflow'),
('default_payment_method', 'card', 'Méthode de paiement par défaut', 'billing')
ON CONFLICT (key) DO NOTHING;

-- 12. VÉRIFICATION FINALE
SELECT 
    'system_settings' as table_name, COUNT(*) as count FROM public.system_settings
UNION ALL
SELECT 'sales', COUNT(*) FROM public.sales
UNION ALL
SELECT 'sale_items', COUNT(*) FROM public.sale_items;

-- 13. AFFICHER LA STRUCTURE DES TABLES
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('sales', 'sale_items', 'system_settings')
ORDER BY table_name, ordinal_position;

-- 14. MESSAGE DE CONFIRMATION
SELECT 
    'STRUCTURE DE BASE DE DONNÉES CORRIGÉE' as status,
    'Toutes les tables et colonnes manquantes ont été ajoutées.' as message;
