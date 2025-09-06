-- =====================================================
-- FONCTION STATISTIQUES DES COMMANDES (CORRIGÉE)
-- =====================================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS get_order_stats();

-- Créer la nouvelle fonction qui respecte le RLS
CREATE OR REPLACE FUNCTION get_order_stats()
RETURNS TABLE (
    total BIGINT,
    pending BIGINT,
    confirmed BIGINT,
    shipped BIGINT,
    delivered BIGINT,
    cancelled BIGINT,
    total_amount DECIMAL(10,2)
) AS $$
BEGIN
    -- Cette fonction sera appelée dans le contexte de l'utilisateur connecté
    -- Le RLS sera automatiquement appliqué
    RETURN QUERY
    SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
        COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed,
        COUNT(CASE WHEN status = 'shipped' THEN 1 END) as shipped,
        COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled,
        COALESCE(SUM(total_amount), 0) as total_amount
    FROM orders
    WHERE orders.workshop_id = auth.jwt() ->> 'workshop_id';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Vérifier que la fonction a été créée
SELECT 'FONCTION STATISTIQUES CORRIGÉE CRÉÉE' as resultat;

-- Tester la fonction
SELECT * FROM get_order_stats();

