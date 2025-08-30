-- AJOUT DES NOUVELLES CATÉGORIES DE PRODUITS
-- Script pour ajouter les catégories : console, ordinateur portable et fixe, smartphone, montre, mannette de jeux, écouteur et casque

-- ============================================================================
-- 1. CRÉATION D'UNE TABLE DE RÉFÉRENCE POUR LES CATÉGORIES
-- ============================================================================

-- Créer une table de référence pour les catégories de produits
CREATE TABLE IF NOT EXISTS public.product_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    color TEXT DEFAULT '#1976d2',
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 2. INSERTION DES NOUVELLES CATÉGORIES
-- ============================================================================

-- Insérer les nouvelles catégories
INSERT INTO public.product_categories (name, description, icon, color, sort_order) VALUES
    ('console', 'Consoles de jeux (PlayStation, Xbox, Nintendo)', 'games', '#ff6b35', 1),
    ('ordinateur_portable', 'Ordinateurs portables et laptops', 'laptop', '#2196f3', 2),
    ('ordinateur_fixe', 'Ordinateurs de bureau et fixes', 'desktop_windows', '#4caf50', 3),
    ('smartphone', 'Téléphones mobiles et smartphones', 'smartphone', '#9c27b0', 4),
    ('montre', 'Montres connectées et smartwatches', 'watch', '#ff9800', 5),
    ('manette_jeux', 'Manettes de jeux et accessoires gaming', 'sports_esports', '#f44336', 6),
    ('ecouteur', 'Écouteurs et casques audio', 'headphones', '#795548', 7),
    ('casque', 'Casques audio et accessoires audio', 'headset', '#607d8b', 8)
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    color = EXCLUDED.color,
    sort_order = EXCLUDED.sort_order,
    updated_at = NOW();

-- ============================================================================
-- 3. MISE À JOUR DE LA TABLE PRODUCTS POUR SUPPORTER LES NOUVELLES CATÉGORIES
-- ============================================================================

-- Ajouter une contrainte de validation pour les catégories
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_category_check;

-- Créer une contrainte pour valider les catégories
ALTER TABLE public.products ADD CONSTRAINT products_category_check 
CHECK (category IN (
    'console', 'ordinateur_portable', 'ordinateur_fixe', 'smartphone', 
    'montre', 'manette_jeux', 'ecouteur', 'casque', 'accessoire', 
    'protection', 'connectique', 'logiciel', 'autre'
));

-- ============================================================================
-- 4. CRÉATION DE LA TABLE SALE_ITEMS SI ELLE N'EXISTE PAS
-- ============================================================================

-- Créer la table sale_items si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.sale_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_id UUID REFERENCES public.sales(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('product', 'service', 'part')),
    item_id UUID NOT NULL,
    name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ajouter une colonne category à la table sales pour le suivi par catégorie
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS category TEXT;

-- Ajouter une colonne category à la table sale_items pour le détail
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS category TEXT;

-- Activer RLS sur la table sale_items
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

-- Ajouter les politiques RLS pour sale_items
CREATE POLICY "Enable read access for authenticated users" ON public.sale_items 
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON public.sale_items 
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON public.sale_items 
FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON public.sale_items 
FOR DELETE USING (auth.role() = 'authenticated');

-- ============================================================================
-- 5. CRÉATION D'UNE FONCTION POUR METTRE À JOUR AUTOMATIQUEMENT LA CATÉGORIE
-- ============================================================================

-- Fonction pour mettre à jour automatiquement la catégorie dans sale_items
CREATE OR REPLACE FUNCTION update_sale_item_category()
RETURNS TRIGGER AS $$
BEGIN
    -- Si c'est un produit, récupérer sa catégorie
    IF NEW.type = 'product' THEN
        SELECT category INTO NEW.category
        FROM public.products
        WHERE id = NEW.item_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger pour mettre à jour automatiquement la catégorie
DROP TRIGGER IF EXISTS trigger_update_sale_item_category ON public.sale_items;
CREATE TRIGGER trigger_update_sale_item_category
    BEFORE INSERT OR UPDATE ON public.sale_items
    FOR EACH ROW
    EXECUTE FUNCTION update_sale_item_category();

-- ============================================================================
-- 6. CRÉATION D'UNE VUE POUR LES STATISTIQUES DE VENTES PAR CATÉGORIE
-- ============================================================================

-- Vue pour les statistiques de ventes par catégorie
CREATE OR REPLACE VIEW public.sales_by_category AS
SELECT 
    COALESCE(si.category, 'non_categorise') as category,
    COUNT(*) as nombre_ventes,
    SUM(si.quantity) as quantite_totale,
    SUM(si.total_price) as chiffre_affaires,
    AVG(si.unit_price) as prix_moyen
FROM public.sale_items si
JOIN public.sales s ON si.sale_id = s.id
WHERE si.type = 'product'
GROUP BY si.category
ORDER BY chiffre_affaires DESC;

-- ============================================================================
-- 7. CRÉATION D'INDEX POUR LES PERFORMANCES
-- ============================================================================

-- Index pour améliorer les performances des requêtes par catégorie
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_sale_items_category ON public.sale_items(category);
CREATE INDEX IF NOT EXISTS idx_sales_category ON public.sales(category);

-- ============================================================================
-- 8. VÉRIFICATION ET AFFICHAGE DES RÉSULTATS
-- ============================================================================

-- Afficher les catégories créées
SELECT 
    'CATÉGORIES CRÉÉES' as section,
    name,
    description,
    sort_order
FROM public.product_categories
ORDER BY sort_order;

-- Vérifier la structure de la table products
SELECT 
    'STRUCTURE PRODUCTS' as section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'products' 
    AND table_schema = 'public'
    AND column_name = 'category';

-- Afficher les contraintes de la table products
SELECT 
    'CONTRAINTES PRODUCTS' as section,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'products' 
    AND table_schema = 'public';

-- Vérifier les triggers créés
SELECT 
    'TRIGGERS CRÉÉS' as section,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'sale_items'
    AND trigger_schema = 'public';

-- ============================================================================
-- 9. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 
    '✅ SCRIPT TERMINÉ AVEC SUCCÈS' as status,
    'Les nouvelles catégories ont été ajoutées et intégrées dans le système de vente' as message;
