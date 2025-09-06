-- Supprimer les fonctions existantes si elles existent
DROP FUNCTION IF EXISTS get_repair_tracking_info(TEXT, TEXT);
DROP FUNCTION IF EXISTS get_client_repair_history(TEXT);

-- Fonction pour récupérer les informations de réparation pour le suivi client
-- Cette fonction permet aux clients de consulter l'état de leurs réparations

CREATE OR REPLACE FUNCTION get_repair_tracking_info(
    p_repair_id_or_number TEXT,
    p_client_email TEXT
)
RETURNS TABLE (
    repair_id UUID,
    repair_number VARCHAR(20),
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
DECLARE
    is_uuid BOOLEAN;
BEGIN
    -- Vérifier si c'est un UUID
    is_uuid := p_repair_id_or_number ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
    
    RETURN QUERY
    SELECT 
        r.id as repair_id,
        r.repair_number,
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
    WHERE (is_uuid AND r.id = p_repair_id_or_number::UUID) 
       OR (NOT is_uuid AND r.repair_number = p_repair_id_or_number)
    AND c.email = p_client_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer la fonction existante si elle existe
DROP FUNCTION IF EXISTS get_client_repair_history(TEXT);

-- Fonction pour récupérer l'historique des réparations d'un client
CREATE OR REPLACE FUNCTION get_client_repair_history(
    p_client_email TEXT
)
RETURNS TABLE (
    repair_id UUID,
    repair_number TEXT,
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
        r.repair_number,
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

-- Fonction pour mettre à jour le statut d'une réparation (pour les notifications)
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

-- Créer des index pour optimiser les requêtes de suivi
CREATE INDEX IF NOT EXISTS idx_repairs_client_email 
ON repairs(client_id) 
INCLUDE (status, created_at);

CREATE INDEX IF NOT EXISTS idx_clients_email 
ON clients(email) 
INCLUDE (first_name, last_name, phone);

-- Vérifier que les fonctions ont été créées
SELECT '✅ Fonctions de suivi des réparations créées avec succès' as status;

-- Test de la fonction (optionnel)
-- SELECT * FROM get_repair_tracking_info('uuid-de-test', 'email-de-test');
