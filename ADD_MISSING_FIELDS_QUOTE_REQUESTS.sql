-- Ajouter les champs manquants à la table quote_requests
-- Ce script ajoute tous les champs du formulaire qui ne sont pas encore dans la table

-- 1. Vérifier la structure actuelle de la table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'quote_requests'
ORDER BY ordinal_position;

-- 2. Ajouter les champs manquants pour les informations client
ALTER TABLE quote_requests 
ADD COLUMN IF NOT EXISTS company VARCHAR(255),
ADD COLUMN IF NOT EXISTS vat_number VARCHAR(50),
ADD COLUMN IF NOT EXISTS siren_number VARCHAR(50);

-- 3. Ajouter les champs manquants pour l'adresse
ALTER TABLE quote_requests 
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS address_complement TEXT,
ADD COLUMN IF NOT EXISTS city VARCHAR(100),
ADD COLUMN IF NOT EXISTS postal_code VARCHAR(20),
ADD COLUMN IF NOT EXISTS region VARCHAR(100);

-- 4. Ajouter les champs manquants pour l'appareil
ALTER TABLE quote_requests 
ADD COLUMN IF NOT EXISTS device_id VARCHAR(100),
ADD COLUMN IF NOT EXISTS color VARCHAR(50),
ADD COLUMN IF NOT EXISTS accessories TEXT,
ADD COLUMN IF NOT EXISTS device_remarks TEXT;

-- 5. Ajouter les champs manquants pour les préférences
ALTER TABLE quote_requests 
ADD COLUMN IF NOT EXISTS sms_notification BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS email_notification BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS sms_marketing BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_marketing BOOLEAN DEFAULT false;

-- 6. Vérifier la nouvelle structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'quote_requests'
ORDER BY ordinal_position;

-- 7. Test d'insertion avec tous les champs
DO $$
DECLARE
    test_request_id UUID;
    current_user_id UUID;
    error_message TEXT;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE 'ERREUR: Aucun utilisateur authentifié. Connectez-vous d''abord.';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Test avec utilisateur: %', current_user_id;
    
    -- Test d'insertion avec tous les nouveaux champs
    BEGIN
        INSERT INTO quote_requests (
            request_number,
            custom_url,
            technician_id,
            client_first_name,
            client_last_name,
            client_email,
            client_phone,
            description,
            device_type,
            device_brand,
            device_model,
            issue_description,
            urgency,
            status,
            priority,
            source,
            ip_address,
            user_agent,
            -- Nouveaux champs client
            company,
            vat_number,
            siren_number,
            -- Nouveaux champs adresse
            address,
            address_complement,
            city,
            postal_code,
            region,
            -- Nouveaux champs appareil
            device_id,
            color,
            accessories,
            device_remarks,
            -- Nouveaux champs préférences
            sms_notification,
            email_notification,
            sms_marketing,
            email_marketing
        ) VALUES (
            'QR-TEST-FIELDS-' || extract(epoch from now()),
            'test-fields',
            current_user_id,
            'Test',
            'Fields',
            'test-fields@example.com',
            '0123456789',
            'Test avec tous les champs',
            'smartphone',
            'Apple',
            'iPhone 14',
            'Test de tous les champs',
            'medium',
            'pending',
            'medium',
            'website',
            NULL,
            'Test User Agent',
            -- Nouveaux champs client
            'Test Company',
            'FR12345678901',
            '123456789',
            -- Nouveaux champs adresse
            '123 Rue de Test',
            'Appartement 4B',
            'Paris',
            '75001',
            'Île-de-France',
            -- Nouveaux champs appareil
            'IMEI123456789',
            'Noir',
            'Chargeur, coque',
            'Appareil en bon état',
            -- Nouveaux champs préférences
            true,
            true,
            false,
            false
        ) RETURNING id INTO test_request_id;
        
        RAISE NOTICE 'SUCCÈS: Demande de test créée avec tous les champs: %', test_request_id;
        
        -- Nettoyer
        DELETE FROM quote_requests WHERE id = test_request_id;
        RAISE NOTICE 'Demande de test supprimée';
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        RAISE NOTICE 'ERREUR lors du test: %', error_message;
    END;
END $$;

-- 8. Message de fin
DO $$
BEGIN
    RAISE NOTICE 'Champs manquants ajoutés avec succès.';
    RAISE NOTICE 'La table quote_requests contient maintenant tous les champs du formulaire.';
    RAISE NOTICE 'Testez maintenant la création de demandes via le formulaire.';
END $$;
