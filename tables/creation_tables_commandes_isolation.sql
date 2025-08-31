-- =====================================================
-- CRÉATION DES TABLES POUR LE SUIVI DES COMMANDES
-- =====================================================
-- Tables avec isolation des données par workshop_id
-- Date: 2025-01-23
-- =====================================================

-- 1. TABLE DES COMMANDES PRINCIPALES
-- =====================================================

CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Informations de base de la commande
    order_number VARCHAR(50) NOT NULL,
    supplier_name VARCHAR(255) NOT NULL,
    supplier_email VARCHAR(255),
    supplier_phone VARCHAR(50),
    
    -- Dates importantes
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    
    -- Statut et suivi
    status VARCHAR(20) NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
    tracking_number VARCHAR(100),
    
    -- Montants
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    
    -- Notes et description
    notes TEXT,
    
    -- Colonnes d'isolation des données
    workshop_id UUID NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contraintes
    UNIQUE(workshop_id, order_number)
);

-- 2. TABLE DES ARTICLES DE COMMANDE
-- =====================================================

CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Référence vers la commande
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    
    -- Informations du produit
    product_name VARCHAR(255) NOT NULL,
    description TEXT,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    
    -- Colonnes d'isolation des données
    workshop_id UUID NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contraintes
    CHECK (quantity > 0),
    CHECK (unit_price >= 0),
    CHECK (total_price >= 0)
);

-- 3. TABLE DES FOURNISSEURS (OPTIONNELLE POUR RÉUTILISATION)
-- =====================================================

CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Informations du fournisseur
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    website VARCHAR(255),
    
    -- Informations de contact
    contact_person VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    
    -- Notes et évaluation
    notes TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    
    -- Statut
    is_active BOOLEAN DEFAULT true,
    
    -- Colonnes d'isolation des données
    workshop_id UUID NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contraintes
    UNIQUE(workshop_id, name)
);

-- 4. INDEX POUR LES PERFORMANCES
-- =====================================================

-- Index sur les colonnes d'isolation
CREATE INDEX IF NOT EXISTS idx_orders_workshop_id ON orders(workshop_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_by ON orders(created_by);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);

CREATE INDEX IF NOT EXISTS idx_order_items_workshop_id ON order_items(workshop_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_created_by ON order_items(created_by);

CREATE INDEX IF NOT EXISTS idx_suppliers_workshop_id ON suppliers(workshop_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_created_by ON suppliers(created_by);
CREATE INDEX IF NOT EXISTS idx_suppliers_name ON suppliers(name);

-- Index composites pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_orders_workshop_status ON orders(workshop_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_workshop_date ON orders(workshop_id, order_date);

-- 5. TRIGGERS POUR L'ISOLATION AUTOMATIQUE
-- =====================================================

-- Fonction pour définir automatiquement workshop_id et created_by
CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Obtenir le workshop_id depuis les paramètres système
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Si pas de workshop_id configuré, utiliser l'user_id comme fallback
    IF v_workshop_id IS NULL THEN
        v_workshop_id := v_user_id;
    END IF;
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour les commandes
CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- Trigger pour les articles de commande
CREATE TRIGGER set_order_item_isolation_trigger
    BEFORE INSERT ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- Trigger pour les fournisseurs
CREATE TRIGGER set_supplier_isolation_trigger
    BEFORE INSERT ON suppliers
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- 6. TRIGGER POUR CALCULER LE TOTAL DE LA COMMANDE
-- =====================================================

-- Fonction pour recalculer le total d'une commande
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    -- Mettre à jour le total de la commande
    UPDATE orders 
    SET 
        total_amount = (
            SELECT COALESCE(SUM(total_price), 0)
            FROM order_items 
            WHERE order_id = COALESCE(NEW.order_id, OLD.order_id)
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.order_id, OLD.order_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger pour recalculer le total quand un article est ajouté/modifié/supprimé
CREATE TRIGGER update_order_total_trigger
    AFTER INSERT OR UPDATE OR DELETE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION update_order_total();

-- 7. ACTIVATION RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Activer RLS sur toutes les tables
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

-- 8. POLITIQUES RLS POUR L'ISOLATION
-- =====================================================

-- Politiques pour les commandes
CREATE POLICY orders_select_policy ON orders
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings
            WHERE key = 'workshop_type'
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY orders_insert_policy ON orders
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY orders_update_policy ON orders
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY orders_delete_policy ON orders
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politiques pour les articles de commande
CREATE POLICY order_items_select_policy ON order_items
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings
            WHERE key = 'workshop_type'
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY order_items_insert_policy ON order_items
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY order_items_update_policy ON order_items
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY order_items_delete_policy ON order_items
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politiques pour les fournisseurs
CREATE POLICY suppliers_select_policy ON suppliers
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings
            WHERE key = 'workshop_type'
            AND value = 'gestion'
            LIMIT 1
        )
    );

CREATE POLICY suppliers_insert_policy ON suppliers
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY suppliers_update_policy ON suppliers
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY suppliers_delete_policy ON suppliers
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- 9. FONCTIONS UTILITAIRES
-- =====================================================

-- Fonction pour obtenir les statistiques des commandes
CREATE OR REPLACE FUNCTION get_order_stats()
RETURNS TABLE (
    total_orders INTEGER,
    pending_orders INTEGER,
    confirmed_orders INTEGER,
    shipped_orders INTEGER,
    delivered_orders INTEGER,
    cancelled_orders INTEGER,
    total_amount DECIMAL(10,2)
) AS $$
DECLARE
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_orders,
        COUNT(*) FILTER (WHERE status = 'pending')::INTEGER as pending_orders,
        COUNT(*) FILTER (WHERE status = 'confirmed')::INTEGER as confirmed_orders,
        COUNT(*) FILTER (WHERE status = 'shipped')::INTEGER as shipped_orders,
        COUNT(*) FILTER (WHERE status = 'delivered')::INTEGER as delivered_orders,
        COUNT(*) FILTER (WHERE status = 'cancelled')::INTEGER as cancelled_orders,
        COALESCE(SUM(total_amount), 0) as total_amount
    FROM orders 
    WHERE workshop_id = v_workshop_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour rechercher des commandes
CREATE OR REPLACE FUNCTION search_orders(
    search_term TEXT DEFAULT '',
    status_filter TEXT DEFAULT 'all'
)
RETURNS TABLE (
    id UUID,
    order_number VARCHAR(50),
    supplier_name VARCHAR(255),
    order_date DATE,
    expected_delivery_date DATE,
    status VARCHAR(20),
    total_amount DECIMAL(10,2),
    tracking_number VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    RETURN QUERY
    SELECT 
        o.id,
        o.order_number,
        o.supplier_name,
        o.order_date,
        o.expected_delivery_date,
        o.status,
        o.total_amount,
        o.tracking_number,
        o.created_at
    FROM orders o
    WHERE o.workshop_id = v_workshop_id
    AND (
        search_term = '' OR
        o.order_number ILIKE '%' || search_term || '%' OR
        o.supplier_name ILIKE '%' || search_term || '%' OR
        o.tracking_number ILIKE '%' || search_term || '%'
    )
    AND (
        status_filter = 'all' OR
        o.status = status_filter
    )
    ORDER BY o.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. VÉRIFICATION DE LA CRÉATION
-- =====================================================

-- Vérifier que les tables ont été créées
SELECT 'Tables créées avec succès' as status;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('orders', 'order_items', 'suppliers')
ORDER BY table_name, ordinal_position;

-- Vérifier les politiques RLS
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE tablename IN ('orders', 'order_items', 'suppliers')
ORDER BY tablename, policyname;

-- Vérifier les index
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('orders', 'order_items', 'suppliers')
ORDER BY tablename, indexname;

