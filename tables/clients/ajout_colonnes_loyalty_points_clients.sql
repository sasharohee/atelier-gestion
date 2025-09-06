-- Ajout des colonnes manquantes pour les points de fidélité dans la table clients
-- Ce script ajoute les colonnes nécessaires pour le système de points de fidélité

-- 1. VÉRIFIER LA STRUCTURE ACTUELLE DE LA TABLE CLIENTS
SELECT '🔍 STRUCTURE ACTUELLE DE LA TABLE CLIENTS:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. AJOUTER LES COLONNES MANQUANTES
SELECT '✅ AJOUT DES COLONNES MANQUANTES...' as info;

-- Ajouter la colonne loyalty_points si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'loyalty_points'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE clients ADD COLUMN loyalty_points INTEGER DEFAULT 0;
        RAISE NOTICE 'Colonne loyalty_points ajoutée';
    ELSE
        RAISE NOTICE 'Colonne loyalty_points existe déjà';
    END IF;
END $$;

-- Ajouter la colonne current_tier_id si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'current_tier_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE clients ADD COLUMN current_tier_id UUID;
        RAISE NOTICE 'Colonne current_tier_id ajoutée';
    ELSE
        RAISE NOTICE 'Colonne current_tier_id existe déjà';
    END IF;
END $$;

-- Ajouter la colonne created_by si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'created_by'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE clients ADD COLUMN created_by UUID;
        RAISE NOTICE 'Colonne created_by ajoutée';
    ELSE
        RAISE NOTICE 'Colonne created_by existe déjà';
    END IF;
END $$;

-- 3. VÉRIFIER ET CRÉER LA TABLE loyalty_tiers
SELECT '🏆 VÉRIFICATION DE LA TABLE LOYALTY_TIERS...' as info;

-- Vérifier si la table existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'loyalty_tiers' 
        AND table_schema = 'public'
    ) THEN
        -- Créer la table si elle n'existe pas
        CREATE TABLE loyalty_tiers (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name TEXT NOT NULL,
            description TEXT,
            points_required INTEGER NOT NULL DEFAULT 0,
            discount_percentage DECIMAL(5,2) DEFAULT 0,
            color TEXT DEFAULT '#000000',
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        RAISE NOTICE 'Table loyalty_tiers créée';
    ELSE
        -- Vérifier la structure existante et ajouter les colonnes manquantes
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'loyalty_tiers' 
            AND column_name = 'points_required'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE loyalty_tiers ADD COLUMN points_required INTEGER NOT NULL DEFAULT 0;
            RAISE NOTICE 'Colonne points_required ajoutée à loyalty_tiers';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'loyalty_tiers' 
            AND column_name = 'discount_percentage'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE loyalty_tiers ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0;
            RAISE NOTICE 'Colonne discount_percentage ajoutée à loyalty_tiers';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'loyalty_tiers' 
            AND column_name = 'color'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE loyalty_tiers ADD COLUMN color TEXT DEFAULT '#000000';
            RAISE NOTICE 'Colonne color ajoutée à loyalty_tiers';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'loyalty_tiers' 
            AND column_name = 'is_active'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE loyalty_tiers ADD COLUMN is_active BOOLEAN DEFAULT true;
            RAISE NOTICE 'Colonne is_active ajoutée à loyalty_tiers';
        END IF;
        
        RAISE NOTICE 'Table loyalty_tiers existe déjà, colonnes manquantes ajoutées si nécessaire';
    END IF;
END $$;

-- 4. VÉRIFIER ET CRÉER LA TABLE loyalty_points_history
SELECT '📊 VÉRIFICATION DE LA TABLE LOYALTY_POINTS_HISTORY...' as info;

-- Vérifier si la table existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'loyalty_points_history' 
        AND table_schema = 'public'
    ) THEN
        -- Créer la table si elle n'existe pas
        CREATE TABLE loyalty_points_history (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
            points_change INTEGER NOT NULL,
            points_before INTEGER NOT NULL,
            points_after INTEGER NOT NULL,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        RAISE NOTICE 'Table loyalty_points_history créée';
    ELSE
        -- Vérifier la structure existante et ajouter les colonnes manquantes
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'loyalty_points_history' 
            AND column_name = 'points_change'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE loyalty_points_history ADD COLUMN points_change INTEGER NOT NULL DEFAULT 0;
            RAISE NOTICE 'Colonne points_change ajoutée à loyalty_points_history';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'loyalty_points_history' 
            AND column_name = 'points_before'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE loyalty_points_history ADD COLUMN points_before INTEGER NOT NULL DEFAULT 0;
            RAISE NOTICE 'Colonne points_before ajoutée à loyalty_points_history';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'loyalty_points_history' 
            AND column_name = 'points_after'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE loyalty_points_history ADD COLUMN points_after INTEGER NOT NULL DEFAULT 0;
            RAISE NOTICE 'Colonne points_after ajoutée à loyalty_points_history';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'loyalty_points_history' 
            AND column_name = 'description'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE loyalty_points_history ADD COLUMN description TEXT;
            RAISE NOTICE 'Colonne description ajoutée à loyalty_points_history';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'loyalty_points_history' 
            AND column_name = 'points_type'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE loyalty_points_history ADD COLUMN points_type TEXT NOT NULL DEFAULT 'manual';
            RAISE NOTICE 'Colonne points_type ajoutée à loyalty_points_history';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'loyalty_points_history' 
            AND column_name = 'created_at'
            AND table_schema = 'public'
        ) THEN
            ALTER TABLE loyalty_points_history ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
            RAISE NOTICE 'Colonne created_at ajoutée à loyalty_points_history';
        END IF;
        
        RAISE NOTICE 'Table loyalty_points_history existe déjà, colonnes manquantes ajoutées si nécessaire';
    END IF;
END $$;

-- 5. INSÉRER LES NIVEAUX DE FIDÉLITÉ PAR DÉFAUT
SELECT '🎯 AJOUT DES NIVEAUX DE FIDÉLITÉ PAR DÉFAUT...' as info;

-- Insérer les niveaux de fidélité avec gestion d'erreur
DO $$ 
BEGIN
    -- Vérifier si les colonnes existent avant d'insérer
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'loyalty_tiers' 
        AND column_name = 'points_required'
        AND table_schema = 'public'
    ) THEN
        -- Insérer avec toutes les colonnes
        INSERT INTO loyalty_tiers (name, description, points_required, discount_percentage, color) 
        VALUES 
            ('Bronze', 'Niveau de base', 0, 0, '#CD7F32'),
            ('Argent', 'Client régulier', 100, 5, '#C0C0C0'),
            ('Or', 'Client fidèle', 500, 10, '#FFD700'),
            ('Platine', 'Client VIP', 1000, 15, '#E5E4E2'),
            ('Diamant', 'Client premium', 2000, 20, '#B9F2FF')
        ON CONFLICT (name) DO NOTHING;
        RAISE NOTICE 'Niveaux de fidélité insérés avec toutes les colonnes';
    ELSE
        -- Insérer avec seulement les colonnes de base
        INSERT INTO loyalty_tiers (name, description) 
        VALUES 
            ('Bronze', 'Niveau de base'),
            ('Argent', 'Client régulier'),
            ('Or', 'Client fidèle'),
            ('Platine', 'Client VIP'),
            ('Diamant', 'Client premium')
        ON CONFLICT (name) DO NOTHING;
        RAISE NOTICE 'Niveaux de fidélité insérés avec colonnes de base';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors de l''insertion des niveaux: %', SQLERRM;
END $$;

-- 6. METTRE À JOUR LES CLIENTS EXISTANTS AVEC LE NIVEAU BRONZE
SELECT '🔄 MISE À JOUR DES CLIENTS EXISTANTS...' as info;

-- Mettre à jour les clients existants avec gestion d'erreur
DO $$ 
DECLARE
    bronze_tier_id UUID;
BEGIN
    -- Récupérer l'ID du niveau Bronze
    SELECT id INTO bronze_tier_id FROM loyalty_tiers WHERE name = 'Bronze' LIMIT 1;
    
    -- Mettre à jour les points de fidélité
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'loyalty_points'
        AND table_schema = 'public'
    ) THEN
        UPDATE clients 
        SET loyalty_points = COALESCE(loyalty_points, 0)
        WHERE loyalty_points IS NULL;
        RAISE NOTICE 'Points de fidélité mis à jour pour les clients existants';
    END IF;
    
    -- Mettre à jour le niveau de fidélité
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'current_tier_id'
        AND table_schema = 'public'
    ) AND bronze_tier_id IS NOT NULL THEN
        UPDATE clients 
        SET current_tier_id = COALESCE(current_tier_id, bronze_tier_id)
        WHERE current_tier_id IS NULL;
        RAISE NOTICE 'Niveau de fidélité mis à jour pour les clients existants';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors de la mise à jour des clients: %', SQLERRM;
END $$;

-- 7. VÉRIFIER LA STRUCTURE FINALE
SELECT '🔍 VÉRIFICATION DE LA STRUCTURE FINALE:' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
AND column_name IN ('loyalty_points', 'current_tier_id', 'created_by')
ORDER BY column_name;

-- 8. VÉRIFIER LES TABLES CRÉÉES
SELECT '📋 TABLES CRÉÉES:' as info;

SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as colonnes
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name IN ('loyalty_tiers', 'loyalty_points_history')
ORDER BY table_name;

-- 9. VÉRIFIER LES NIVEAUX DE FIDÉLITÉ
SELECT '🏆 NIVEAUX DE FIDÉLITÉ DISPONIBLES:' as info;

SELECT 
    name,
    description,
    points_required,
    discount_percentage,
    color,
    is_active
FROM loyalty_tiers
ORDER BY points_required;

-- 10. TEST DE LA STRUCTURE
SELECT '🧪 TEST DE LA STRUCTURE...' as info;

SELECT 
    COUNT(*) as total_clients,
    COUNT(loyalty_points) as clients_avec_points,
    COUNT(current_tier_id) as clients_avec_niveau,
    AVG(COALESCE(loyalty_points, 0)) as moyenne_points
FROM clients;

SELECT '✅ Configuration des points de fidélité terminée !' as result;
