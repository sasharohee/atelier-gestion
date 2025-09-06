-- Script pour ajouter les colonnes de réduction aux tables sales et repairs
-- Ce script permet d'appliquer des réductions en pourcentage lors de la création de ventes et réparations
-- Ce script peut être exécuté plusieurs fois sans erreur (idempotent)

SELECT 'Début de l''ajout des colonnes de réduction...' as status;

-- Ajouter les colonnes de réduction à la table sales
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'discount_percentage') THEN
        ALTER TABLE public.sales ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'discount_amount') THEN
        ALTER TABLE public.sales ADD COLUMN discount_amount DECIMAL(10,2) DEFAULT 0;
    END IF;
END $$;

-- Ajouter les colonnes de réduction à la table repairs
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'discount_percentage') THEN
        ALTER TABLE public.repairs ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'discount_amount') THEN
        ALTER TABLE public.repairs ADD COLUMN discount_amount DECIMAL(10,2) DEFAULT 0;
    END IF;
END $$;

-- Mettre à jour les contraintes pour s'assurer que les pourcentages sont entre 0 et 100
-- Supprimer d'abord les contraintes existantes si elles existent
ALTER TABLE public.sales 
DROP CONSTRAINT IF EXISTS sales_discount_percentage_check;

ALTER TABLE public.repairs 
DROP CONSTRAINT IF EXISTS repairs_discount_percentage_check;

-- Ajouter les nouvelles contraintes
ALTER TABLE public.sales 
ADD CONSTRAINT sales_discount_percentage_check 
CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

ALTER TABLE public.repairs 
ADD CONSTRAINT repairs_discount_percentage_check 
CHECK (discount_percentage >= 0 AND discount_percentage <= 100);

-- Créer des triggers pour calculer automatiquement les montants de réduction
CREATE OR REPLACE FUNCTION calculate_discount_amount()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculer le montant de la réduction sur le total TTC
    NEW.discount_amount = (NEW.total * NEW.discount_percentage) / 100;
    
    -- Calculer le total final après réduction
    NEW.total = NEW.total - NEW.discount_amount;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger à la table sales
DROP TRIGGER IF EXISTS trigger_calculate_discount_sales ON public.sales;
CREATE TRIGGER trigger_calculate_discount_sales
    BEFORE INSERT OR UPDATE ON public.sales
    FOR EACH ROW
    EXECUTE FUNCTION calculate_discount_amount();

-- Créer une fonction spécifique pour les réparations (qui n'ont pas de TVA)
CREATE OR REPLACE FUNCTION calculate_repair_discount_amount()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculer le montant de la réduction sur le prix total
    NEW.discount_amount = (NEW.total_price * NEW.discount_percentage) / 100;
    
    -- Calculer le prix final après réduction
    NEW.total_price = NEW.total_price - NEW.discount_amount;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger à la table repairs
DROP TRIGGER IF EXISTS trigger_calculate_discount_repairs ON public.repairs;
CREATE TRIGGER trigger_calculate_discount_repairs
    BEFORE INSERT OR UPDATE ON public.repairs
    FOR EACH ROW
    EXECUTE FUNCTION calculate_repair_discount_amount();

-- Mettre à jour les politiques RLS pour inclure les nouvelles colonnes
-- (si RLS est activé)

-- Vérifier que les colonnes ont été ajoutées
SELECT 
    table_name, 
    column_name, 
    data_type, 
    column_default, 
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('sales', 'repairs') 
AND column_name LIKE '%discount%'
ORDER BY table_name, column_name;

-- Afficher un message de confirmation
SELECT 'Colonnes de réduction ajoutées avec succès aux tables sales et repairs' as status;
