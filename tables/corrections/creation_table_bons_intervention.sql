-- CRÉATION DE LA TABLE DES BONS D'INTERVENTION
-- Cette table stocke tous les formulaires de bon d'intervention pour dédouaner le réparateur

SELECT 'Début de la création de la table des bons d''intervention...' as status;

-- Créer la table intervention_forms
CREATE TABLE IF NOT EXISTS public.intervention_forms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Référence à la réparation
    repair_id UUID NOT NULL REFERENCES public.repairs(id) ON DELETE CASCADE,
    
    -- Informations générales
    intervention_date DATE NOT NULL DEFAULT CURRENT_DATE,
    technician_name VARCHAR(255) NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    client_phone VARCHAR(50),
    client_email VARCHAR(255),
    
    -- Informations appareil
    device_brand VARCHAR(100) NOT NULL,
    device_model VARCHAR(100) NOT NULL,
    device_serial_number VARCHAR(100),
    device_type VARCHAR(50),
    
    -- État initial de l'appareil
    device_condition TEXT,
    visible_damages TEXT,
    missing_parts TEXT,
    password_provided BOOLEAN DEFAULT FALSE,
    data_backup BOOLEAN DEFAULT FALSE,
    
    -- Diagnostic et réparation
    reported_issue TEXT NOT NULL,
    initial_diagnosis TEXT,
    proposed_solution TEXT,
    estimated_cost DECIMAL(10,2) DEFAULT 0,
    estimated_duration VARCHAR(100),
    
    -- Conditions et responsabilités
    data_loss_risk BOOLEAN DEFAULT FALSE,
    data_loss_risk_details TEXT,
    cosmetic_changes BOOLEAN DEFAULT FALSE,
    cosmetic_changes_details TEXT,
    warranty_void BOOLEAN DEFAULT FALSE,
    warranty_void_details TEXT,
    
    -- Autorisations
    client_authorizes_repair BOOLEAN DEFAULT FALSE,
    client_authorizes_data_access BOOLEAN DEFAULT FALSE,
    client_authorizes_replacement BOOLEAN DEFAULT FALSE,
    
    -- Notes et observations
    additional_notes TEXT,
    special_instructions TEXT,
    
    -- Informations légales
    terms_accepted BOOLEAN DEFAULT FALSE,
    liability_accepted BOOLEAN DEFAULT FALSE,
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer un index sur repair_id pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_intervention_forms_repair_id ON public.intervention_forms(repair_id);

-- Créer un index sur la date d'intervention
CREATE INDEX IF NOT EXISTS idx_intervention_forms_date ON public.intervention_forms(intervention_date);

-- Créer un index sur le technicien
CREATE INDEX IF NOT EXISTS idx_intervention_forms_technician ON public.intervention_forms(technician_name);

-- Ajouter des contraintes de validation
ALTER TABLE public.intervention_forms 
ADD CONSTRAINT intervention_forms_estimated_cost_check 
CHECK (estimated_cost >= 0);

-- Créer un trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_intervention_forms_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_intervention_forms_updated_at
    BEFORE UPDATE ON public.intervention_forms
    FOR EACH ROW
    EXECUTE FUNCTION update_intervention_forms_updated_at();

-- Activer RLS (Row Level Security)
ALTER TABLE public.intervention_forms ENABLE ROW LEVEL SECURITY;

-- Créer une politique RLS pour permettre l'accès aux utilisateurs authentifiés
CREATE POLICY "Users can view their own intervention forms" ON public.intervention_forms
    FOR SELECT USING (
        repair_id IN (
            SELECT id FROM public.repairs 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own intervention forms" ON public.intervention_forms
    FOR INSERT WITH CHECK (
        repair_id IN (
            SELECT id FROM public.repairs 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own intervention forms" ON public.intervention_forms
    FOR UPDATE USING (
        repair_id IN (
            SELECT id FROM public.repairs 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own intervention forms" ON public.intervention_forms
    FOR DELETE USING (
        repair_id IN (
            SELECT id FROM public.repairs 
            WHERE user_id = auth.uid()
        )
    );

-- Vérifier que la table a été créée correctement
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'intervention_forms'
ORDER BY ordinal_position;

-- Afficher les index créés
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'intervention_forms';

-- Afficher les politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'intervention_forms';

SELECT 'Table des bons d''intervention créée avec succès !' as status;
