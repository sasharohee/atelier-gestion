-- CORRECTION DES TRIGGERS DE RÉDUCTION
-- Problème : Les triggers appliquent la réduction plusieurs fois et modifient le prix de base

SELECT 'Début de la correction des triggers de réduction...' as status;

-- ÉTAPE 1: SUPPRIMER LES TRIGGERS PROBLÉMATIQUES
DROP TRIGGER IF EXISTS trigger_calculate_discount_sales ON public.sales;
DROP TRIGGER IF EXISTS trigger_calculate_discount_repairs ON public.repairs;

-- ÉTAPE 2: SUPPRIMER LES FONCTIONS PROBLÉMATIQUES
DROP FUNCTION IF EXISTS calculate_discount_amount();
DROP FUNCTION IF EXISTS calculate_repair_discount_amount();

-- ÉTAPE 3: AJOUTER UNE COLONNE POUR STOCKER LE PRIX ORIGINAL
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'original_price') THEN
        ALTER TABLE public.repairs ADD COLUMN original_price DECIMAL(10,2);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'original_total') THEN
        ALTER TABLE public.sales ADD COLUMN original_total DECIMAL(10,2);
    END IF;
END $$;

-- ÉTAPE 4: METTRE À JOUR LES DONNÉES EXISTANTES
-- Pour les réparations, sauvegarder le prix original
UPDATE public.repairs 
SET original_price = total_price + COALESCE(discount_amount, 0)
WHERE discount_percentage > 0 AND original_price IS NULL;

-- Pour les ventes, sauvegarder le total original
UPDATE public.sales 
SET original_total = total + COALESCE(discount_amount, 0)
WHERE discount_percentage > 0 AND original_total IS NULL;

-- ÉTAPE 5: CRÉER UNE NOUVELLE FONCTION POUR LES RÉPARATIONS
CREATE OR REPLACE FUNCTION calculate_repair_discount_amount_safe()
RETURNS TRIGGER AS $$
BEGIN
    -- Si c'est une nouvelle réparation ou si le pourcentage de réduction change
    IF TG_OP = 'INSERT' OR OLD.discount_percentage IS DISTINCT FROM NEW.discount_percentage THEN
        -- Sauvegarder le prix original si pas encore fait
        IF NEW.original_price IS NULL THEN
            NEW.original_price = NEW.total_price;
        END IF;
        
        -- Calculer le montant de la réduction sur le prix original
        NEW.discount_amount = (NEW.original_price * NEW.discount_percentage) / 100;
        
        -- Calculer le prix final après réduction
        NEW.total_price = NEW.original_price - NEW.discount_amount;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ÉTAPE 6: CRÉER UNE NOUVELLE FONCTION POUR LES VENTES
CREATE OR REPLACE FUNCTION calculate_sale_discount_amount_safe()
RETURNS TRIGGER AS $$
BEGIN
    -- Si c'est une nouvelle vente ou si le pourcentage de réduction change
    IF TG_OP = 'INSERT' OR OLD.discount_percentage IS DISTINCT FROM NEW.discount_percentage THEN
        -- Calculer le total TTC original (sous-total + TVA)
        IF NEW.original_total IS NULL THEN
            NEW.original_total = NEW.subtotal + NEW.tax;
        END IF;
        
        -- Calculer le montant de la réduction sur le total TTC original
        NEW.discount_amount = (NEW.original_total * NEW.discount_percentage) / 100;
        
        -- Calculer le total final après réduction
        NEW.total = NEW.original_total - NEW.discount_amount;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ÉTAPE 7: CRÉER LES NOUVEAUX TRIGGERS
CREATE TRIGGER trigger_calculate_repair_discount_safe
    BEFORE INSERT OR UPDATE ON public.repairs
    FOR EACH ROW
    EXECUTE FUNCTION calculate_repair_discount_amount_safe();

CREATE TRIGGER trigger_calculate_sale_discount_safe
    BEFORE INSERT OR UPDATE ON public.sales
    FOR EACH ROW
    EXECUTE FUNCTION calculate_sale_discount_amount_safe();

-- ÉTAPE 8: VÉRIFICATION
SELECT 'Triggers corrigés avec succès' as status;

-- Afficher quelques exemples de réparations avec réduction
SELECT 
    id,
    total_price as prix_final,
    original_price as prix_original,
    discount_percentage as pourcentage_reduction,
    discount_amount as montant_reduction
FROM public.repairs 
WHERE discount_percentage > 0 
LIMIT 5;

-- Afficher quelques exemples de ventes avec réduction
SELECT 
    id,
    total as total_final,
    original_total as total_original,
    discount_percentage as pourcentage_reduction,
    discount_amount as montant_reduction
FROM public.sales 
WHERE discount_percentage > 0 
LIMIT 5;
