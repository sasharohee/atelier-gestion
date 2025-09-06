-- Création de la table subscription_status pour gérer les accès utilisateurs
CREATE TABLE IF NOT EXISTS subscription_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    subscription_type TEXT DEFAULT 'free' CHECK (subscription_type IN ('free', 'premium', 'enterprise')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    activated_at TIMESTAMP WITH TIME ZONE,
    activated_by UUID REFERENCES auth.users(id),
    notes TEXT
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_subscription_status_user_id ON subscription_status(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_status_email ON subscription_status(email);
CREATE INDEX IF NOT EXISTS idx_subscription_status_is_active ON subscription_status(is_active);

-- Contrainte unique sur user_id pour éviter les doublons
ALTER TABLE subscription_status ADD CONSTRAINT unique_subscription_status_user_id UNIQUE (user_id);

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_subscription_status_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour automatiquement updated_at
CREATE TRIGGER trigger_update_subscription_status_updated_at
    BEFORE UPDATE ON subscription_status
    FOR EACH ROW
    EXECUTE FUNCTION update_subscription_status_updated_at();

-- Politique RLS pour l'isolation des données
ALTER TABLE subscription_status ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre aux utilisateurs de voir leur propre statut
CREATE POLICY "Users can view their own subscription status" ON subscription_status
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour permettre aux administrateurs de voir tous les statuts
CREATE POLICY "Admins can view all subscription statuses" ON subscription_status
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Politique pour permettre aux utilisateurs de créer leur propre statut
CREATE POLICY "Users can create their own subscription status" ON subscription_status
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour permettre aux administrateurs de modifier tous les statuts
CREATE POLICY "Admins can update all subscription statuses" ON subscription_status
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Politique pour permettre aux administrateurs de supprimer tous les statuts
CREATE POLICY "Admins can delete all subscription statuses" ON subscription_status
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Commentaires sur la table
COMMENT ON TABLE subscription_status IS 'Table pour gérer les accès utilisateurs avec activation manuelle';
COMMENT ON COLUMN subscription_status.user_id IS 'ID de l''utilisateur (référence auth.users)';
COMMENT ON COLUMN subscription_status.is_active IS 'Indique si l''accès est activé (TRUE) ou verrouillé (FALSE)';
COMMENT ON COLUMN subscription_status.subscription_type IS 'Type d''abonnement (free, premium, enterprise)';
COMMENT ON COLUMN subscription_status.activated_at IS 'Date d''activation de l''accès';
COMMENT ON COLUMN subscription_status.activated_by IS 'ID de l''administrateur qui a activé l''accès';
COMMENT ON COLUMN subscription_status.notes IS 'Notes sur l''activation/désactivation';
