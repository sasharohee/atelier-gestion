-- SCRIPT IMMÉDIAT POUR CORRIGER LES ERREURS
-- Exécutez ce script EN PREMIER pour résoudre les erreurs actuelles

-- 1. AJOUTER LA COLONNE items À LA TABLE sales
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS items JSONB DEFAULT '[]'::jsonb;

-- 2. CRÉER LA TABLE system_settings
CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'general',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. AJOUTER LA COLONNE user_id À LA TABLE sales
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 4. INSÉRER LES PARAMÈTRES SYSTÈME PAR DÉFAUT
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

-- 5. VÉRIFICATION IMMÉDIATE
SELECT 'VÉRIFICATION' as test;

-- Vérifier la colonne items
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'sales' AND column_name = 'items';

-- Vérifier la table system_settings
SELECT COUNT(*) as system_settings_count FROM public.system_settings;

-- Vérifier les ventes existantes
SELECT COUNT(*) as sales_count FROM public.sales;

-- 6. MESSAGE DE CONFIRMATION
SELECT 
    'ERREURS CORRIGÉES IMMÉDIATEMENT' as status,
    'Colonne items ajoutée à sales, table system_settings créée' as message;
