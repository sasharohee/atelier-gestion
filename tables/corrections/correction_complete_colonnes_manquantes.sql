-- Correction complète de toutes les colonnes manquantes
-- Script pour résoudre tous les problèmes de colonnes

-- 1. CORRECTION SYSTEM_SETTINGS
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON system_settings(user_id);

-- 2. CORRECTION APPOINTMENTS
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS start_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITH TIME ZONE;
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_start_date ON appointments(start_date);
CREATE INDEX IF NOT EXISTS idx_appointments_end_date ON appointments(end_date);

-- 3. CORRECTION REPAIRS
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON repairs(user_id);

-- 4. CORRECTION PRODUCTS
ALTER TABLE products ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_products_user_id ON products(user_id);

-- 5. CORRECTION SALES
ALTER TABLE sales ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON sales(user_id);

-- 6. CORRECTION CLIENTS
ALTER TABLE clients ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_clients_user_id ON clients(user_id);

-- 7. CORRECTION DEVICES
ALTER TABLE devices ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);

-- 8. VÉRIFICATION
SELECT 'Toutes les colonnes user_id ont été ajoutées !' as message;
