-- Script de vérification et correction des numéros de réparation
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier si la colonne repair_number existe
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'repairs' 
AND column_name = 'repair_number';

-- 2. Vérifier si les fonctions existent
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_name IN ('generate_repair_number', 'get_repair_tracking_info', 'get_client_repair_history');

-- 3. Vérifier si les triggers existent
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'repairs'
AND trigger_name LIKE '%repair_number%';

-- 4. Vérifier les réparations sans numéro
SELECT 
    id,
    created_at,
    status,
    description
FROM repairs 
WHERE repair_number IS NULL
ORDER BY created_at DESC
LIMIT 10;

-- 5. Si la colonne n'existe pas, l'ajouter
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repairs' 
        AND column_name = 'repair_number'
    ) THEN
        ALTER TABLE repairs ADD COLUMN repair_number VARCHAR(20) UNIQUE;
        RAISE NOTICE 'Colonne repair_number ajoutée';
    ELSE
        RAISE NOTICE 'Colonne repair_number existe déjà';
    END IF;
END $$;

-- 6. Créer la fonction de génération de numéros si elle n'existe pas
CREATE OR REPLACE FUNCTION generate_repair_number()
RETURNS VARCHAR(20) AS $$
DECLARE
    new_number VARCHAR(20);
    counter INTEGER := 0;
    max_attempts INTEGER := 10;
BEGIN
    LOOP
        -- Générer un numéro au format REP-YYYYMMDD-XXXX
        new_number := 'REP-' || 
                     TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' ||
                     LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
        
        -- Vérifier si le numéro existe déjà
        IF NOT EXISTS (SELECT 1 FROM repairs WHERE repair_number = new_number) THEN
            RETURN new_number;
        END IF;
        
        counter := counter + 1;
        IF counter >= max_attempts THEN
            -- Si trop de tentatives, utiliser un timestamp
            new_number := 'REP-' || 
                         TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' ||
                         LPAD(EXTRACT(EPOCH FROM NOW())::INTEGER % 10000, 4, '0');
            RETURN new_number;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 7. Créer le trigger si il n'existe pas
CREATE OR REPLACE FUNCTION set_repair_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.repair_number IS NULL THEN
        NEW.repair_number := generate_repair_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS trigger_set_repair_number ON repairs;

-- Créer le trigger
CREATE TRIGGER trigger_set_repair_number
    BEFORE INSERT ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION set_repair_number();

-- 8. Mettre à jour les réparations existantes sans numéro
UPDATE repairs 
SET repair_number = generate_repair_number()
WHERE repair_number IS NULL;

-- 9. Vérifier le résultat
SELECT 
    COUNT(*) as total_repairs,
    COUNT(repair_number) as repairs_with_number,
    COUNT(*) - COUNT(repair_number) as repairs_without_number
FROM repairs;

-- 10. Afficher quelques exemples
SELECT 
    id,
    repair_number,
    status,
    created_at
FROM repairs 
ORDER BY created_at DESC
LIMIT 5;
