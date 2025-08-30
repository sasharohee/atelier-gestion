-- Script pour ajouter un numéro de réparation unique
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Ajouter la colonne repair_number à la table repairs
ALTER TABLE repairs 
ADD COLUMN IF NOT EXISTS repair_number VARCHAR(20) UNIQUE;

-- 2. Créer un index pour optimiser les recherches par numéro
CREATE INDEX IF NOT EXISTS idx_repairs_repair_number 
ON repairs(repair_number);

-- 3. Fonction pour générer un numéro de réparation unique
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
            -- Si on n'arrive pas à générer un numéro unique après 10 tentatives,
            -- on ajoute un timestamp pour garantir l'unicité
            new_number := 'REP-' || 
                         TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' ||
                         LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0') || '-' ||
                         EXTRACT(EPOCH FROM NOW())::INTEGER::TEXT;
            RETURN new_number;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger pour générer automatiquement un numéro de réparation
CREATE OR REPLACE FUNCTION set_repair_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Générer un numéro de réparation seulement si aucun n'est fourni
    IF NEW.repair_number IS NULL THEN
        NEW.repair_number := generate_repair_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Créer le trigger
DROP TRIGGER IF EXISTS trigger_set_repair_number ON repairs;
CREATE TRIGGER trigger_set_repair_number
    BEFORE INSERT ON repairs
    FOR EACH ROW
    EXECUTE FUNCTION set_repair_number();

-- 6. Mettre à jour les réparations existantes qui n'ont pas de numéro
UPDATE repairs 
SET repair_number = generate_repair_number()
WHERE repair_number IS NULL;

-- 7. Vérifier que tout fonctionne
SELECT '✅ Colonne repair_number ajoutée avec succès' as status;

-- 8. Test de la fonction (optionnel)
-- SELECT generate_repair_number() as test_number;
