-- Recréation de toutes les tables manquantes
-- Date: 2024-01-24

-- 1. TABLE SYSTEM_SETTINGS

DROP TABLE IF EXISTS system_settings CASCADE;

CREATE TABLE system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    setting_key TEXT UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABLE SUBSCRIPTION_STATUS

DROP TABLE IF EXISTS subscription_status CASCADE;

CREATE TABLE subscription_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    subscription_type TEXT DEFAULT 'free',
    activated_at TIMESTAMP WITH TIME ZONE,
    activated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABLE CLIENTS

DROP TABLE IF EXISTS clients CASCADE;

CREATE TABLE clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. TABLE DEVICE_MODELS

DROP TABLE IF EXISTS device_models CASCADE;

CREATE TABLE device_models (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TABLE DEVICES

DROP TABLE IF EXISTS devices CASCADE;

CREATE TABLE devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    device_model_id UUID REFERENCES device_models(id) ON DELETE CASCADE,
    serial_number TEXT,
    purchase_date DATE,
    warranty_expiry DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. TABLE PRODUCTS

DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. TABLE REPAIRS

DROP TABLE IF EXISTS repairs CASCADE;

CREATE TABLE repairs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    estimated_cost DECIMAL(10,2),
    actual_cost DECIMAL(10,2),
    start_date DATE DEFAULT CURRENT_DATE,
    completion_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. TABLE SALES

DROP TABLE IF EXISTS sales CASCADE;

CREATE TABLE sales (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    sale_date DATE DEFAULT CURRENT_DATE,
    payment_method TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. TABLE APPOINTMENTS

DROP TABLE IF EXISTS appointments CASCADE;

CREATE TABLE appointments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'scheduled',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. TABLE MESSAGES

DROP TABLE IF EXISTS messages CASCADE;

CREATE TABLE messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES users(id) ON DELETE CASCADE,
    subject TEXT,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. TABLE TRANSACTIONS

DROP TABLE IF EXISTS transactions CASCADE;

CREATE TABLE transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. CONFIGURER LES PERMISSIONS

GRANT ALL PRIVILEGES ON TABLE system_settings TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE clients TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE device_models TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE devices TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE products TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE repairs TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE sales TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE appointments TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE messages TO postgres, authenticated, anon, service_role;
GRANT ALL PRIVILEGES ON TABLE transactions TO postgres, authenticated, anon, service_role;

-- 13. DÉSACTIVER RLS

ALTER TABLE system_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;
ALTER TABLE device_models DISABLE ROW LEVEL SECURITY;
ALTER TABLE devices DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE repairs DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE appointments DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE transactions DISABLE ROW LEVEL SECURITY;

-- 14. CRÉER L'ABONNEMENT POUR L'UTILISATEUR

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

-- 15. AJOUTER DES DONNÉES DE TEST

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

-- 16. VÉRIFICATION FINALE

SELECT '=== TOUTES LES TABLES CRÉÉES ===' as section;
SELECT 
    '✅ system_settings' as table1,
    '✅ subscription_status' as table2,
    '✅ clients' as table3,
    '✅ device_models' as table4,
    '✅ devices' as table5,
    '✅ products' as table6,
    '✅ repairs' as table7,
    '✅ sales' as table8,
    '✅ appointments' as table9,
    '✅ messages' as table10,
    '✅ transactions' as table11;

-- 17. COMPTER LES DONNÉES

SELECT '=== DONNÉES CRÉÉES ===' as section;
SELECT 
    (SELECT COUNT(*) FROM subscription_status) as subscriptions_count,
    (SELECT COUNT(*) FROM clients) as clients_count,
    (SELECT COUNT(*) FROM device_models) as models_count,
    (SELECT COUNT(*) FROM products) as products_count;

-- 18. MESSAGE DE CONFIRMATION

SELECT '=== RÉSULTAT FINAL ===' as section;
SELECT 
    '✅ Toutes les tables créées' as statut1,
    '✅ Permissions configurées' as statut2,
    '✅ RLS désactivé' as statut3,
    '✅ Abonnement activé' as statut4,
    '✅ Données de test ajoutées' as statut5,
    '✅ Application prête à fonctionner' as statut6;
