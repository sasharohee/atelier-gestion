-- Solution simple pour le suivi des réparations
-- Évite les problèmes de types en utilisant des requêtes directes

-- 1. Supprimer les fonctions problématiques
DROP FUNCTION IF EXISTS get_repair_tracking_info(TEXT, TEXT);
DROP FUNCTION IF EXISTS get_client_repair_history(TEXT);

-- 2. Créer une fonction simple pour le suivi
CREATE OR REPLACE FUNCTION get_repair_tracking_info(
    p_repair_id_or_number TEXT,
    p_client_email TEXT
)
RETURNS JSON AS $$
DECLARE
    result JSON;
    is_uuid BOOLEAN;
BEGIN
    -- Vérifier si c'est un UUID
    is_uuid := p_repair_id_or_number ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
    
    -- Requête avec gestion automatique des types
    SELECT json_build_object(
        'repair_id', r.id,
        'repair_number', r.repair_number,
        'repair_status', r.status,
        'repair_description', r.description,
        'repair_issue', r.issue,
        'estimated_start_date', r.estimated_start_date,
        'estimated_end_date', r.estimated_end_date,
        'start_date', r.start_date,
        'end_date', r.end_date,
        'due_date', r.due_date,
        'is_urgent', r.is_urgent,
        'notes', r.notes,
        'total_price', r.total_price,
        'is_paid', r.is_paid,
        'created_at', r.created_at,
        'updated_at', r.updated_at,
        'client', json_build_object(
            'firstName', c.first_name,
            'lastName', c.last_name,
            'email', c.email,
            'phone', c.phone
        ),
        'device', CASE 
            WHEN d.id IS NOT NULL THEN json_build_object(
                'brand', d.brand,
                'model', d.model,
                'serialNumber', d.serial_number,
                'type', d.type
            )
            ELSE NULL
        END,
        'technician', CASE 
            WHEN u.id IS NOT NULL THEN json_build_object(
                'firstName', u.first_name,
                'lastName', u.last_name
            )
            ELSE NULL
        END
    ) INTO result
    FROM repairs r
    INNER JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    LEFT JOIN users u ON r.assigned_technician_id = u.id
    WHERE (is_uuid AND r.id = p_repair_id_or_number::UUID) 
       OR (NOT is_uuid AND r.repair_number = p_repair_id_or_number)
    AND c.email = p_client_email;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Créer une fonction simple pour l'historique
CREATE OR REPLACE FUNCTION get_client_repair_history(
    p_client_email TEXT
)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_agg(json_build_object(
        'repair_id', r.id,
        'repair_number', r.repair_number,
        'repair_status', r.status,
        'repair_description', r.description,
        'total_price', r.total_price,
        'is_paid', r.is_paid,
        'created_at', r.created_at,
        'device', CASE 
            WHEN d.id IS NOT NULL THEN json_build_object(
                'brand', d.brand,
                'model', d.model
            )
            ELSE NULL
        END
    )) INTO result
    FROM repairs r
    INNER JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    WHERE c.email = p_client_email
    ORDER BY r.created_at DESC;
    
    RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Créer des données de test
INSERT INTO clients (first_name, last_name, email, phone) 
VALUES ('Test', 'User', 'test@gmail.com', '0123456789')
ON CONFLICT (email) DO NOTHING;

INSERT INTO devices (brand, model, serial_number, type) 
VALUES ('Test', 'Device', 'TEST123', 'smartphone')
ON CONFLICT (serial_number) DO NOTHING;

INSERT INTO repairs (
    client_id, 
    device_id, 
    status, 
    description, 
    issue, 
    repair_number,
    total_price, 
    is_paid
) 
SELECT 
    c.id,
    d.id,
    'in_progress',
    'Test de réparation',
    'Problème de test',
    'REP-20250829-1296',
    50.00,
    false
FROM clients c, devices d 
WHERE c.email = 'test@gmail.com' 
AND d.serial_number = 'TEST123'
ON CONFLICT (repair_number) DO NOTHING;

-- 5. Tester les fonctions
SELECT 'Test get_repair_tracking_info:' as test_name;
SELECT get_repair_tracking_info('REP-20250829-1296', 'test@gmail.com');

SELECT 'Test get_client_repair_history:' as test_name;
SELECT get_client_repair_history('test@gmail.com');
