-- 🔧 CORRECTION - Table loyalty_tiers_advanced manquante
-- Script pour créer la table et les fonctions manquantes

-- Vérifier si la table existe
SELECT 
    'Vérification existence table loyalty_tiers_advanced' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'loyalty_tiers_advanced'
        ) THEN '✅ Table existe'
        ELSE '❌ Table manquante'
    END as status;

-- Créer la table loyalty_tiers_advanced si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_tiers_advanced (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    workshop_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    points_required INTEGER NOT NULL DEFAULT 0,
    discount_percentage NUMERIC(5,2) NOT NULL DEFAULT 0,
    color TEXT NOT NULL DEFAULT '#000000',
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(workshop_id, name)
);

-- Activer RLS sur la table
ALTER TABLE loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;

-- Créer les politiques RLS
DROP POLICY IF EXISTS "Users can view their own loyalty tiers" ON loyalty_tiers_advanced;
CREATE POLICY "Users can view their own loyalty tiers" ON loyalty_tiers_advanced
    FOR SELECT USING (auth.uid() = workshop_id);

DROP POLICY IF EXISTS "Users can insert their own loyalty tiers" ON loyalty_tiers_advanced;
CREATE POLICY "Users can insert their own loyalty tiers" ON loyalty_tiers_advanced
    FOR INSERT WITH CHECK (auth.uid() = workshop_id);

DROP POLICY IF EXISTS "Users can update their own loyalty tiers" ON loyalty_tiers_advanced;
CREATE POLICY "Users can update their own loyalty tiers" ON loyalty_tiers_advanced
    FOR UPDATE USING (auth.uid() = workshop_id);

DROP POLICY IF EXISTS "Users can delete their own loyalty tiers" ON loyalty_tiers_advanced;
CREATE POLICY "Users can delete their own loyalty tiers" ON loyalty_tiers_advanced
    FOR DELETE USING (auth.uid() = workshop_id);

-- Créer la fonction get_loyalty_tiers si elle n'existe pas
DROP FUNCTION IF EXISTS get_loyalty_tiers(UUID);
CREATE OR REPLACE FUNCTION get_loyalty_tiers(p_workshop_id UUID)
RETURNS TABLE(
    id UUID,
    name TEXT,
    points_required INTEGER,
    discount_percentage NUMERIC(5,2),
    color TEXT,
    description TEXT,
    is_active BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lta.id,
        lta.name,
        lta.points_required,
        lta.discount_percentage,
        lta.color,
        lta.description,
        lta.is_active
    FROM loyalty_tiers_advanced lta
    WHERE lta.workshop_id = p_workshop_id
    ORDER BY lta.points_required;
END;
$$;

-- Accorder les permissions
GRANT EXECUTE ON FUNCTION get_loyalty_tiers(UUID) TO authenticated;

-- Insérer des données par défaut si elles n'existent pas
INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
SELECT 
    u.id,
    tier.name,
    tier.points_required,
    tier.discount_percentage,
    tier.color,
    tier.description,
    tier.is_active
FROM auth.users u
CROSS JOIN (VALUES 
    ('Bronze', 0, 0.00, '#CD7F32', 'Niveau de base', true),
    ('Argent', 100, 5.00, '#C0C0C0', '5% de réduction', true),
    ('Or', 500, 10.00, '#FFD700', '10% de réduction', true),
    ('Platine', 1000, 15.00, '#E5E4E2', '15% de réduction', true),
    ('Diamant', 2000, 20.00, '#B9F2FF', '20% de réduction', true)
) AS tier(name, points_required, discount_percentage, color, description, is_active)
WHERE NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced lta WHERE lta.workshop_id = u.id AND lta.name = tier.name
);

-- Vérification finale
SELECT 
    'Vérification finale' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'loyalty_tiers_advanced'
        ) THEN '✅ Table loyalty_tiers_advanced disponible'
        ELSE '❌ Table loyalty_tiers_advanced manquante'
    END as status;

SELECT 
    'Vérification fonction' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'get_loyalty_tiers'
        ) THEN '✅ Fonction get_loyalty_tiers disponible'
        ELSE '❌ Fonction get_loyalty_tiers manquante'
    END as status;

-- Test de la fonction
SELECT 'Test de la fonction get_loyalty_tiers:' as test;
SELECT * FROM get_loyalty_tiers((SELECT id FROM auth.users LIMIT 1));

SELECT '🎉 Les tables et fonctions de fidélité sont maintenant disponibles !' as message;
