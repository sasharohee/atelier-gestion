-- Correction rapide du problème de type dans la fonction get_repair_tracking_info
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Supprimer la fonction existante
DROP FUNCTION IF EXISTS get_repair_tracking_info(TEXT, TEXT);

-- 2. Recréer la fonction avec les bons types
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
    estimated_start_date DATE,
    estimated_end_date DATE,
    start_date DATE,
    end_date DATE,
    due_date DATE,
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
        r.repair_number::VARCHAR(20),
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

-- 3. Vérifier que la fonction a été créée
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_name = 'get_repair_tracking_info';

-- 4. Tester la fonction
SELECT * FROM get_repair_tracking_info('REP-20250829-1296', 'test@gmail.com');

-- 5. Si aucune réparation n'existe, créer des données de test
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

-- 6. Tester à nouveau
SELECT * FROM get_repair_tracking_info('REP-20250829-1296', 'test@gmail.com');
