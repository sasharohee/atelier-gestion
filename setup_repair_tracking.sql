-- Script de configuration pour le suivi des réparations
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier que les tables existent
DO $$ 
BEGIN
    -- Vérifier la table repairs
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'repairs') THEN
        RAISE EXCEPTION 'La table repairs n''existe pas. Veuillez d''abord créer les tables de base.';
    END IF;
    
    -- Vérifier la table clients
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients') THEN
        RAISE EXCEPTION 'La table clients n''existe pas. Veuillez d''abord créer les tables de base.';
    END IF;
    
    -- Vérifier la table devices
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'devices') THEN
        RAISE EXCEPTION 'La table devices n''existe pas. Veuillez d''abord créer les tables de base.';
    END IF;
    
    -- Vérifier la table users
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE EXCEPTION 'La table users n''existe pas. Veuillez d''abord créer les tables de base.';
    END IF;
    
    RAISE NOTICE '✅ Toutes les tables requises existent';
END $$;

-- 2. Créer les fonctions de suivi
CREATE OR REPLACE FUNCTION get_repair_tracking_info(
    p_repair_id UUID,
    p_client_email TEXT
)
RETURNS TABLE (
    repair_id UUID,
    repair_status TEXT,
    repair_description TEXT,
    repair_issue TEXT,
    estimated_start_date TIMESTAMP WITH TIME ZONE,
    estimated_end_date TIMESTAMP WITH TIME ZONE,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE,
    is_urgent BOOLEAN,
    notes TEXT,
    total_price DECIMAL(10,2),
    is_paid BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    client_first_name TEXT,
    client_last_name TEXT,
    client_email TEXT,
    client_phone TEXT,
    device_brand TEXT,
    device_model TEXT,
    device_serial_number TEXT,
    device_type TEXT,
    technician_first_name TEXT,
    technician_last_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id as repair_id,
        r.status as repair_status,
        r.description as repair_description,
        r.issue as repair_issue,
        r.estimated_start_date,
        r.estimated_end_date,
        r.start_date,
        r.end_date,
        r.due_date,
        r.is_urgent,
        r.notes,
        r.total_price,
        r.is_paid,
        r.created_at,
        r.updated_at,
        c.first_name as client_first_name,
        c.last_name as client_last_name,
        c.email as client_email,
        c.phone as client_phone,
        d.brand as device_brand,
        d.model as device_model,
        d.serial_number as device_serial_number,
        d.type as device_type,
        u.first_name as technician_first_name,
        u.last_name as technician_last_name
    FROM repairs r
    INNER JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    LEFT JOIN users u ON r.assigned_technician_id = u.id
    WHERE r.id = p_repair_id 
    AND c.email = p_client_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Créer la fonction d'historique
CREATE OR REPLACE FUNCTION get_client_repair_history(
    p_client_email TEXT
)
RETURNS TABLE (
    repair_id UUID,
    repair_status TEXT,
    repair_description TEXT,
    total_price DECIMAL(10,2),
    is_paid BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    device_brand TEXT,
    device_model TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id as repair_id,
        r.status as repair_status,
        r.description as repair_description,
        r.total_price,
        r.is_paid,
        r.created_at,
        d.brand as device_brand,
        d.model as device_model
    FROM repairs r
    INNER JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    WHERE c.email = p_client_email
    ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Créer la fonction de mise à jour de statut
CREATE OR REPLACE FUNCTION update_repair_status(
    p_repair_id UUID,
    p_new_status TEXT,
    p_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_client_email TEXT;
    v_client_name TEXT;
BEGIN
    -- Récupérer les informations du client pour les notifications
    SELECT 
        c.email,
        CONCAT(c.first_name, ' ', c.last_name)
    INTO v_client_email, v_client_name
    FROM repairs r
    INNER JOIN clients c ON r.client_id = c.id
    WHERE r.id = p_repair_id;
    
    -- Mettre à jour le statut
    UPDATE repairs 
    SET 
        status = p_new_status,
        notes = COALESCE(p_notes, notes),
        updated_at = NOW()
    WHERE id = p_repair_id;
    
    -- Ici on pourrait ajouter l'envoi d'email/SMS de notification
    -- Pour l'instant, on retourne juste true
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Créer des index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_repairs_client_email 
ON repairs(client_id) 
INCLUDE (status, created_at);

CREATE INDEX IF NOT EXISTS idx_clients_email 
ON clients(email) 
INCLUDE (first_name, last_name, phone);

-- 6. Vérifier que les fonctions ont été créées
SELECT '✅ Fonctions de suivi des réparations créées avec succès' as status;

-- 7. Test des fonctions (optionnel - à décommenter pour tester)
/*
-- Test avec des données existantes
DO $$ 
DECLARE
    v_repair_id UUID;
    v_client_email TEXT;
BEGIN
    -- Récupérer une réparation existante pour le test
    SELECT r.id, c.email 
    INTO v_repair_id, v_client_email
    FROM repairs r
    INNER JOIN clients c ON r.client_id = c.id
    LIMIT 1;
    
    IF v_repair_id IS NOT NULL THEN
        RAISE NOTICE 'Test avec réparation: % et email: %', v_repair_id, v_client_email;
        
        -- Test de la fonction de suivi
        PERFORM * FROM get_repair_tracking_info(v_repair_id, v_client_email);
        RAISE NOTICE '✅ Fonction de suivi testée';
        
        -- Test de la fonction d'historique
        PERFORM * FROM get_client_repair_history(v_client_email);
        RAISE NOTICE '✅ Fonction d''historique testée';
    ELSE
        RAISE NOTICE '⚠️ Aucune réparation trouvée pour le test';
    END IF;
END $$;
*/
