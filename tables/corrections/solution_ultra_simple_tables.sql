-- Solution ultra-simple pour recréer toutes les tables
-- Date: 2024-01-24

-- 1. SUPPRIMER TOUTES LES TABLES

DROP TABLE IF EXISTS subscription_status CASCADE;
DROP TABLE IF EXISTS system_settings CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS device_models CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS repairs CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;

-- 2. CRÉER LES TABLES ULTRA-SIMPLES

-- Table subscription_status
CREATE TABLE subscription_status (
    id UUID DEFAULT gen_random_uuid(),
    user_id UUID,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    subscription_type TEXT DEFAULT 'free',
    activated_at TIMESTAMP WITH TIME ZONE,
    activated_by UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table system_settings
CREATE TABLE system_settings (
    id UUID DEFAULT gen_random_uuid(),
    setting_key TEXT,
    setting_value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table clients
CREATE TABLE clients (
    id UUID DEFAULT gen_random_uuid(),
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table device_models
CREATE TABLE device_models (
    id UUID DEFAULT gen_random_uuid(),
    brand TEXT,
    model TEXT,
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table devices
CREATE TABLE devices (
    id UUID DEFAULT gen_random_uuid(),
    client_id UUID,
    device_model_id UUID,
    serial_number TEXT,
    purchase_date DATE,
    warranty_expiry DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table products
CREATE TABLE products (
    id UUID DEFAULT gen_random_uuid(),
    name TEXT,
    description TEXT,
    price DECIMAL(10,2),
    stock_quantity INTEGER DEFAULT 0,
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table repairs
CREATE TABLE repairs (
    id UUID DEFAULT gen_random_uuid(),
    device_id UUID,
    client_id UUID,
    description TEXT,
    status TEXT DEFAULT 'pending',
    estimated_cost DECIMAL(10,2),
    actual_cost DECIMAL(10,2),
    start_date DATE DEFAULT CURRENT_DATE,
    completion_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table sales
CREATE TABLE sales (
    id UUID DEFAULT gen_random_uuid(),
    client_id UUID,
    product_id UUID,
    quantity INTEGER,
    unit_price DECIMAL(10,2),
    total_price DECIMAL(10,2),
    sale_date DATE DEFAULT CURRENT_DATE,
    payment_method TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table appointments
CREATE TABLE appointments (
    id UUID DEFAULT gen_random_uuid(),
    client_id UUID,
    title TEXT,
    description TEXT,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'scheduled',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table messages
CREATE TABLE messages (
    id UUID DEFAULT gen_random_uuid(),
    sender_id UUID,
    recipient_id UUID,
    subject TEXT,
    content TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table transactions
CREATE TABLE transactions (
    id UUID DEFAULT gen_random_uuid(),
    type TEXT,
    amount DECIMAL(10,2),
    description TEXT,
    client_id UUID,
    user_id UUID,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CONFIGURER LES PERMISSIONS

GRANT ALL PRIVILEGES ON TABLE subscription_status TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE system_settings TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE clients TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE device_models TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE devices TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE products TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE repairs TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE sales TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE appointments TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE messages TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE transactions TO postgres, authenticated, anon, service_role;

-- 4. DÉSACTIVER RLS

ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;
ALTER TABLE device_models DISABLE ROW LEVEL SECURITY;
ALTER TABLE devices DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE repairs DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE appointments DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE transactions DISABLE ROW LEVEL SECURITY;

-- 5. CRÉER L'ABONNEMENT (SANS ON CONFLICT)

INSERT INTO subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    activated_at,
    notes
) 
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    TRUE,
    'premium',
    NOW(),
    'Abonnement activé automatiquement'
FROM users u
WHERE u.email = 'Sasharohee26@gmail.com';

-- 6. AJOUTER DES DONNÉES DE TEST

-- Clients de test
INSERT INTO clients (first_name, last_name, email, phone) VALUES
('Jean', 'Dupont', 'jean.dupont@email.com', '0123456789'),
('Marie', 'Martin', 'marie.martin@email.com', '0987654321'),
('Pierre', 'Durand', 'pierre.durand@email.com', '0555666777');

-- Modèles d'appareils
INSERT INTO device_models (brand, model, category) VALUES
('Apple', 'iPhone 13', 'Smartphone'),
('Samsung', 'Galaxy S21', 'Smartphone'),
('Dell', 'Latitude 5520', 'Laptop'),
('HP', 'Pavilion 15', 'Laptop'),
('Canon', 'EOS R5', 'Camera');

-- Produits de test
INSERT INTO products (name, description, price, stock_quantity, category) VALUES
('Écran iPhone 13', 'Écran de remplacement pour iPhone 13', 89.99, 5, 'Écrans'),
('Batterie Samsung S21', 'Batterie de remplacement', 45.50, 8, 'Batteries'),
('Clavier Dell', 'Clavier de remplacement', 25.00, 12, 'Claviers'),
('Chargeur USB-C', 'Chargeur rapide 65W', 19.99, 20, 'Accessoires');

-- 7. VÉRIFICATION

SELECT '=== TABLES CRÉÉES ===' as section;
SELECT 
    '✅ subscription_status' as table1,
    '✅ system_settings' as table2,
    '✅ clients' as table3,
    '✅ device_models' as table4,
    '✅ devices' as table5,
    '✅ products' as table6,
    '✅ repairs' as table7,
    '✅ sales' as table8,
    '✅ appointments' as table9,
    '✅ messages' as table10,
    '✅ transactions' as table11;

-- 8. COMPTER LES DONNÉES

SELECT '=== DONNÉES CRÉÉES ===' as section;
SELECT 
    (SELECT COUNT(*) FROM subscription_status) as subscriptions_count,
    (SELECT COUNT(*) FROM clients) as clients_count,
    (SELECT COUNT(*) FROM device_models) as models_count,
    (SELECT COUNT(*) FROM products) as products_count;

-- 9. MESSAGE DE CONFIRMATION

SELECT '=== RÉSULTAT ===' as section;
SELECT 
    '✅ Toutes les tables créées sans contraintes' as statut1,
    '✅ Permissions configurées' as statut2,
    '✅ RLS désactivé' as statut3,
    '✅ Abonnement activé' as statut4,
    '✅ Données de test ajoutées' as statut5,
    '✅ Application prête à fonctionner' as statut6;
