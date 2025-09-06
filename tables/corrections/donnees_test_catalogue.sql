-- DONNÉES DE TEST POUR LE CATALOGUE
-- Ce script ajoute des données d'exemple dans le catalogue pour les tests

-- ============================================================================
-- 1. VÉRIFICATION PRÉALABLE
-- ============================================================================

-- Vérifier que l'utilisateur est connecté
DO $$
DECLARE
    current_user_id UUID;
    current_user_email TEXT;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION '❌ Aucun utilisateur connecté - Impossible d''ajouter des données de test';
    END IF;
    
    RAISE NOTICE '👤 Ajout de données de test pour l''utilisateur: %', current_user_email;
END $$;

-- ============================================================================
-- 2. DONNÉES DE TEST - APPAREILS (DEVICES)
-- ============================================================================

INSERT INTO public.devices (brand, model, serial_number, type, specifications, user_id) VALUES
('Apple', 'iPhone 14 Pro', 'IP14P001', 'smartphone', '{"ram": "6GB", "storage": "128GB", "color": "Deep Purple"}', auth.uid()),
('Samsung', 'Galaxy S23 Ultra', 'SS23U001', 'smartphone', '{"ram": "8GB", "storage": "256GB", "color": "Phantom Black"}', auth.uid()),
('Apple', 'iPad Air', 'IPA001', 'tablet', '{"ram": "8GB", "storage": "64GB", "color": "Space Gray"}', auth.uid()),
('Dell', 'XPS 13', 'DXPS001', 'laptop', '{"ram": "16GB", "storage": "512GB", "processor": "Intel i7"}', auth.uid()),
('HP', 'Pavilion', 'HPP001', 'laptop', '{"ram": "8GB", "storage": "256GB", "processor": "AMD Ryzen 5"}', auth.uid()),
('Sony', 'PlayStation 5', 'PS5001', 'console', '{"storage": "825GB", "type": "Digital Edition"}', auth.uid()),
('Microsoft', 'Xbox Series X', 'XBX001', 'console', '{"storage": "1TB", "type": "Standard"}', auth.uid()),
('Canon', 'EOS R6', 'CER6001', 'camera', '{"sensor": "20.1MP", "type": "Mirrorless"}', auth.uid());

-- ============================================================================
-- 3. DONNÉES DE TEST - SERVICES
-- ============================================================================

INSERT INTO public.services (name, description, duration, price, category, applicable_devices, is_active, user_id) VALUES
('Remplacement écran iPhone', 'Remplacement complet de l''écran avec garantie', 120, 89.99, 'réparation', ARRAY['smartphone'], true, auth.uid()),
('Remplacement batterie', 'Remplacement de la batterie avec test de santé', 60, 49.99, 'réparation', ARRAY['smartphone', 'tablet', 'laptop'], true, auth.uid()),
('Diagnostic complet', 'Diagnostic approfondi du matériel et logiciel', 30, 29.99, 'diagnostic', ARRAY['smartphone', 'tablet', 'laptop', 'console'], true, auth.uid()),
('Nettoyage complet', 'Nettoyage interne et externe de l''appareil', 45, 39.99, 'maintenance', ARRAY['smartphone', 'tablet', 'laptop', 'console', 'camera'], true, auth.uid()),
('Installation logiciel', 'Installation et configuration de logiciels', 30, 24.99, 'installation', ARRAY['laptop', 'desktop'], true, auth.uid()),
('Récupération données', 'Récupération de données depuis appareil endommagé', 180, 79.99, 'réparation', ARRAY['smartphone', 'tablet', 'laptop'], true, auth.uid()),
('Mise à jour système', 'Mise à jour du système d''exploitation', 45, 19.99, 'maintenance', ARRAY['smartphone', 'tablet', 'laptop'], true, auth.uid()),
('Optimisation performance', 'Optimisation des performances système', 60, 34.99, 'maintenance', ARRAY['laptop', 'desktop'], true, auth.uid());

-- ============================================================================
-- 4. DONNÉES DE TEST - PIÈCES DÉTACHÉES (PARTS)
-- ============================================================================

INSERT INTO public.parts (name, description, part_number, brand, compatible_devices, stock_quantity, min_stock_level, price, supplier, is_active, user_id) VALUES
('Écran iPhone 14 Pro', 'Écran OLED 6.1" pour iPhone 14 Pro', 'IP14P-SCR001', 'Apple', ARRAY['smartphone'], 5, 3, 89.99, 'Fournisseur Apple', true, auth.uid()),
('Batterie iPhone 14', 'Batterie Li-Ion 3240mAh pour iPhone 14', 'IP14-BAT001', 'Apple', ARRAY['smartphone'], 12, 5, 29.99, 'BatteryPlus', true, auth.uid()),
('Écran Samsung S23', 'Écran AMOLED 6.8" pour Galaxy S23 Ultra', 'SS23-SCR001', 'Samsung', ARRAY['smartphone'], 3, 2, 79.99, 'Samsung Parts', true, auth.uid()),
('Clavier MacBook', 'Clavier rétroéclairé pour MacBook Pro', 'MBP-KBD001', 'Apple', ARRAY['laptop'], 8, 4, 45.99, 'MacParts', true, auth.uid()),
('Disque dur 1TB', 'Disque dur interne 1TB 7200RPM', 'HDD-1TB001', 'Seagate', ARRAY['laptop', 'desktop'], 15, 8, 39.99, 'StoragePro', true, auth.uid()),
('RAM DDR4 8GB', 'Module RAM DDR4 8GB 2666MHz', 'RAM-8GB001', 'Corsair', ARRAY['laptop', 'desktop'], 20, 10, 24.99, 'MemoryMax', true, auth.uid()),
('Chargeur USB-C', 'Chargeur USB-C 65W universel', 'CHG-65W001', 'Anker', ARRAY['smartphone', 'tablet', 'laptop'], 25, 12, 19.99, 'PowerSupply', true, auth.uid()),
('Câble Lightning', 'Câble Lightning vers USB-C 1m', 'CBL-LT001', 'Apple', ARRAY['smartphone', 'tablet'], 30, 15, 9.99, 'CablePro', true, auth.uid());

-- ============================================================================
-- 5. DONNÉES DE TEST - PRODUITS
-- ============================================================================

INSERT INTO public.products (name, description, category, price, stock_quantity, is_active, user_id) VALUES
('Coque iPhone 14 Pro', 'Coque de protection en silicone pour iPhone 14 Pro', 'protection', 19.99, 25, true, auth.uid()),
('Film de protection écran', 'Film de protection 9H pour smartphones', 'protection', 12.99, 50, true, auth.uid()),
('Chargeur sans fil', 'Chargeur sans fil 15W compatible Qi', 'connectique', 34.99, 15, true, auth.uid()),
('Câble USB-C', 'Câble USB-C vers USB-C 2m haute vitesse', 'connectique', 8.99, 40, true, auth.uid()),
('Souris sans fil', 'Souris sans fil ergonomique pour ordinateur', 'accessoire', 24.99, 20, true, auth.uid()),
('Clavier mécanique', 'Clavier mécanique RGB pour gaming', 'accessoire', 89.99, 8, true, auth.uid()),
('Webcam HD', 'Webcam 1080p avec micro intégré', 'accessoire', 49.99, 12, true, auth.uid()),
('Disque externe 2TB', 'Disque dur externe portable 2TB USB 3.0', 'accessoire', 79.99, 10, true, auth.uid());

-- ============================================================================
-- 6. DONNÉES DE TEST - CLIENTS
-- ============================================================================

INSERT INTO public.clients (first_name, last_name, email, phone, address, user_id) VALUES
('Jean', 'Dupont', 'jean.dupont@email.com', '0123456789', '123 Rue de la Paix, 75001 Paris', auth.uid()),
('Marie', 'Martin', 'marie.martin@email.com', '0987654321', '456 Avenue des Champs, 69001 Lyon', auth.uid()),
('Pierre', 'Bernard', 'pierre.bernard@email.com', '0555666777', '789 Boulevard Central, 13001 Marseille', auth.uid()),
('Sophie', 'Petit', 'sophie.petit@email.com', '0444333222', '321 Rue du Commerce, 31000 Toulouse', auth.uid()),
('Lucas', 'Robert', 'lucas.robert@email.com', '0333222111', '654 Place de la République, 44000 Nantes', auth.uid()),
('Emma', 'Richard', 'emma.richard@email.com', '0222111000', '987 Chemin des Fleurs, 59000 Lille', auth.uid()),
('Thomas', 'Durand', 'thomas.durand@email.com', '0111000999', '147 Avenue Victor Hugo, 67000 Strasbourg', auth.uid()),
('Julie', 'Moreau', 'julie.moreau@email.com', '0999888777', '258 Rue de Rivoli, 21000 Dijon', auth.uid());

-- ============================================================================
-- 7. VÉRIFICATION DES DONNÉES INSÉRÉES
-- ============================================================================

-- Compter les données insérées
SELECT 
    'DONNÉES INSÉRÉES' as verification,
    table_name,
    COUNT(*) as nombre_enregistrements
FROM (
    SELECT 'devices' as table_name, id FROM public.devices
    UNION ALL
    SELECT 'services', id FROM public.services  
    UNION ALL
    SELECT 'parts', id FROM public.parts
    UNION ALL
    SELECT 'products', id FROM public.products
    UNION ALL
    SELECT 'clients', id FROM public.clients
) t
GROUP BY table_name
ORDER BY table_name;

-- ============================================================================
-- 8. VÉRIFICATION DE L'ISOLATION
-- ============================================================================

-- Vérifier que toutes les données appartiennent à l'utilisateur connecté
DO $$
DECLARE
    current_user_id UUID;
    isolation_check BOOLEAN := TRUE;
    total_records INTEGER;
    user_records INTEGER;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    -- Vérifier chaque table
    SELECT COUNT(*) INTO total_records FROM public.devices;
    SELECT COUNT(*) INTO user_records FROM public.devices WHERE user_id = current_user_id;
    IF total_records != user_records THEN
        RAISE NOTICE '❌ Problème d''isolation dans devices: %/%', user_records, total_records;
        isolation_check := FALSE;
    END IF;
    
    SELECT COUNT(*) INTO total_records FROM public.services;
    SELECT COUNT(*) INTO user_records FROM public.services WHERE user_id = current_user_id;
    IF total_records != user_records THEN
        RAISE NOTICE '❌ Problème d''isolation dans services: %/%', user_records, total_records;
        isolation_check := FALSE;
    END IF;
    
    SELECT COUNT(*) INTO total_records FROM public.parts;
    SELECT COUNT(*) INTO user_records FROM public.parts WHERE user_id = current_user_id;
    IF total_records != user_records THEN
        RAISE NOTICE '❌ Problème d''isolation dans parts: %/%', user_records, total_records;
        isolation_check := FALSE;
    END IF;
    
    SELECT COUNT(*) INTO total_records FROM public.products;
    SELECT COUNT(*) INTO user_records FROM public.products WHERE user_id = current_user_id;
    IF total_records != user_records THEN
        RAISE NOTICE '❌ Problème d''isolation dans products: %/%', user_records, total_records;
        isolation_check := FALSE;
    END IF;
    
    SELECT COUNT(*) INTO total_records FROM public.clients;
    SELECT COUNT(*) INTO user_records FROM public.clients WHERE user_id = current_user_id;
    IF total_records != user_records THEN
        RAISE NOTICE '❌ Problème d''isolation dans clients: %/%', user_records, total_records;
        isolation_check := FALSE;
    END IF;
    
    IF isolation_check THEN
        RAISE NOTICE '✅ Isolation parfaite - Toutes les données appartiennent à l''utilisateur connecté';
    ELSE
        RAISE NOTICE '⚠️ Problèmes d''isolation détectés';
    END IF;
END $$;

-- ============================================================================
-- 9. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 
    '🎉 DONNÉES DE TEST AJOUTÉES' as status,
    'Le catalogue a été rempli avec des données de test variées.' as message,
    'Vous pouvez maintenant tester toutes les fonctionnalités du catalogue.' as details,
    'Toutes les données sont isolées par utilisateur.' as isolation_status;
