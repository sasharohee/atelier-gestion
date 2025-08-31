-- =====================================================
-- FONCTION STATISTIQUES DES COMMANDES
-- =====================================================

-- Créer la fonction pour calculer les statistiques des commandes
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
    RETURN QUERY
    SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
        COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed,
        COUNT(CASE WHEN status = 'shipped' THEN 1 END) as shipped,
        COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled,
        COALESCE(SUM(total_amount), 0) as total_amount
    FROM orders;
END;
$$ LANGUAGE plpgsql;

-- Vérifier que la fonction a été créée
SELECT 'FONCTION STATISTIQUES CRÉÉE' as resultat;

-- Tester la fonction
SELECT * FROM get_order_stats();

