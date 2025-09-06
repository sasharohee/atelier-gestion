-- Correction immédiate des colonnes appointments
-- Script simple et direct

-- 1. AJOUTER LA COLONNE START_DATE
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS start_date TIMESTAMP WITH TIME ZONE;

-- 2. AJOUTER LA COLONNE END_DATE
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITH TIME ZONE;

-- 3. AJOUTER LA COLONNE USER_ID
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 4. CRÉER LES INDEX
CREATE INDEX IF NOT EXISTS idx_appointments_start_date ON appointments(start_date);
CREATE INDEX IF NOT EXISTS idx_appointments_end_date ON appointments(end_date);
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON appointments(user_id);

-- 5. VÉRIFIER
SELECT 'Colonnes ajoutées avec succès !' as message;
