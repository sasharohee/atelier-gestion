-- =====================================================
-- CORRECTION DOUBLONS NUMÉROS DE COMMANDE
-- =====================================================

SELECT 'CORRECTION DOUBLONS NUMÉROS DE COMMANDE' as section;

-- 1. IDENTIFIER LES DOUBLONS
-- =====================================================

SELECT 
    'DOUBLONS IDENTIFIÉS' as probleme,
    workshop_id,
    order_number,
    COUNT(*) as nombre_doublons,
    STRING_AGG(id::text, ', ') as ids_commandes
FROM orders 
GROUP BY workshop_id, order_number
HAVING COUNT(*) > 1
ORDER BY nombre_doublons DESC;

-- 2. AFFICHER TOUS LES NUMÉROS DE COMMANDE
-- =====================================================

SELECT 
    'TOUS LES NUMÉROS' as verification,
    id,
    order_number,
    workshop_id,
    created_at
FROM orders 
ORDER BY order_number, created_at;

-- 3. CRÉER UNE FONCTION POUR GÉNÉRER DES NUMÉROS UNIQUES
-- =====================================================

CREATE OR REPLACE FUNCTION generate_unique_order_number()
RETURNS TEXT AS $$
DECLARE
    new_order_number TEXT;
    counter INTEGER := 0;
    max_attempts INTEGER := 10;
BEGIN
    LOOP
        -- Générer un numéro de commande avec timestamp + random + compteur
        new_order_number := 'CMD-' || 
                           EXTRACT(EPOCH FROM NOW())::BIGINT || '-' ||
                           LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0') || '-' ||
                           LPAD(counter::TEXT, 2, '0');
        
        -- Vérifier si ce numéro existe déjà
        IF NOT EXISTS (
            SELECT 1 FROM orders 
            WHERE order_number = new_order_number
        ) THEN
            RETURN new_order_number;
        END IF;
        
        counter := counter + 1;
        
        -- Éviter une boucle infinie
        IF counter >= max_attempts THEN
            RAISE EXCEPTION 'Impossible de générer un numéro de commande unique après % tentatives', max_attempts;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 4. VÉRIFIER LA FONCTION
-- =====================================================

SELECT 
    'FONCTION CRÉÉE' as verification,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'generate_unique_order_number'
ORDER BY routine_name;

-- 5. TESTER LA FONCTION
-- =====================================================

SELECT 
    'TEST FONCTION' as test,
    generate_unique_order_number() as numero_test_1,
    generate_unique_order_number() as numero_test_2,
    generate_unique_order_number() as numero_test_3;

-- 6. CORRIGER LES DOUBLONS EXISTANTS
-- =====================================================

-- Créer une table temporaire pour stocker les corrections
CREATE TEMP TABLE order_number_corrections AS
SELECT 
    id,
    order_number,
    workshop_id,
    ROW_NUMBER() OVER (PARTITION BY workshop_id, order_number ORDER BY created_at) as row_num
FROM orders 
WHERE (workshop_id, order_number) IN (
    SELECT workshop_id, order_number
    FROM orders 
    GROUP BY workshop_id, order_number
    HAVING COUNT(*) > 1
);

-- Mettre à jour les doublons avec de nouveaux numéros
UPDATE orders 
SET order_number = generate_unique_order_number()
WHERE id IN (
    SELECT id 
    FROM order_number_corrections 
    WHERE row_num > 1
);

-- 7. VÉRIFIER LA CORRECTION
-- =====================================================

SELECT 
    'VÉRIFICATION APRÈS CORRECTION' as verification,
    workshop_id,
    order_number,
    COUNT(*) as nombre_occurrences
FROM orders 
GROUP BY workshop_id, order_number
HAVING COUNT(*) > 1
ORDER BY nombre_occurrences DESC;

-- 8. AFFICHER LES COMMANDES CORRIGÉES
-- =====================================================

SELECT 
    'COMMANDES CORRIGÉES' as resultat,
    id,
    order_number,
    workshop_id,
    supplier_name,
    created_at
FROM orders 
ORDER BY order_number, created_at;

-- 9. CRÉER UN INDEX UNIQUE POUR ÉVITER LES DOUBLONS FUTURS
-- =====================================================

-- Vérifier si l'index unique existe déjà
SELECT 
    'INDEX EXISTANT' as verification,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'orders' 
  AND indexname LIKE '%order_number%';

-- Créer un index unique si nécessaire
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_workshop_order_number_unique 
ON orders(workshop_id, order_number);

-- 10. VÉRIFIER L'INDEX
-- =====================================================

SELECT 
    'INDEX CRÉÉ' as verification,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'orders' 
  AND indexname = 'idx_orders_workshop_order_number_unique';

-- 11. RÉSULTAT
-- =====================================================

SELECT 
    'DOUBLONS CORRIGÉS' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Numéros de commande uniques générés' as description;
