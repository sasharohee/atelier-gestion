-- Création des tables pour la gestion des dépenses
-- Ce fichier doit être exécuté dans Supabase pour créer les tables nécessaires

-- Table des catégories de dépenses
CREATE TABLE IF NOT EXISTS expense_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    color VARCHAR(7) NOT NULL DEFAULT '#2196f3',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des dépenses
CREATE TABLE IF NOT EXISTS expenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    amount DECIMAL(10,2) NOT NULL,
    category_id UUID NOT NULL REFERENCES expense_categories(id) ON DELETE RESTRICT,
    supplier VARCHAR(255),
    invoice_number VARCHAR(255),
    payment_method VARCHAR(20) NOT NULL DEFAULT 'card' CHECK (payment_method IN ('cash', 'card', 'transfer', 'check')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'cancelled')),
    expense_date DATE NOT NULL,
    due_date DATE,
    receipt_path TEXT,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_expense_categories_user_id ON expense_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_expense_categories_active ON expense_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON expenses(status);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_due_date ON expenses(due_date);

-- RLS (Row Level Security) pour les catégories de dépenses
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own expense categories" ON expense_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own expense categories" ON expense_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own expense categories" ON expense_categories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own expense categories" ON expense_categories
    FOR DELETE USING (auth.uid() = user_id);

-- RLS (Row Level Security) pour les dépenses
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own expenses" ON expenses
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own expenses" ON expenses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own expenses" ON expenses
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own expenses" ON expenses
    FOR DELETE USING (auth.uid() = user_id);

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pour mettre à jour automatiquement updated_at
CREATE TRIGGER update_expense_categories_updated_at 
    BEFORE UPDATE ON expense_categories 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at 
    BEFORE UPDATE ON expenses 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour créer les catégories par défaut pour un nouvel utilisateur
CREATE OR REPLACE FUNCTION create_default_expense_categories()
RETURNS TRIGGER AS $$
BEGIN
    -- Créer les catégories par défaut pour le nouvel utilisateur
    INSERT INTO expense_categories (user_id, name, description, color) VALUES
        (NEW.id, 'Fournitures', 'Fournitures de bureau et materiel', '#2196f3'),
        (NEW.id, 'Equipement', 'Achat d''equipement technique', '#4caf50'),
        (NEW.id, 'Formation', 'Formations et certifications', '#ff9800'),
        (NEW.id, 'Marketing', 'Publicite et marketing', '#9c27b0'),
        (NEW.id, 'Transport', 'Frais de transport et deplacement', '#f44336'),
        (NEW.id, 'Loyer', 'Loyer et charges', '#607d8b'),
        (NEW.id, 'Assurance', 'Assurances diverses', '#795548'),
        (NEW.id, 'Autres', 'Autres depenses', '#9e9e9e');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour créer automatiquement les catégories par défaut lors de l'inscription d'un nouvel utilisateur
CREATE TRIGGER create_default_categories_on_signup
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_expense_categories();

-- Fonction pour créer les catégories par défaut pour un utilisateur existant
CREATE OR REPLACE FUNCTION create_default_categories_for_user(user_uuid UUID)
RETURNS VOID AS $$
BEGIN
    -- Vérifier si l'utilisateur existe
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_uuid) THEN
        RAISE EXCEPTION 'Utilisateur avec l''ID % n''existe pas', user_uuid;
    END IF;
    
    -- Créer les catégories par défaut seulement si elles n'existent pas déjà
    INSERT INTO expense_categories (user_id, name, description, color) 
    SELECT user_uuid, name, description, color FROM (VALUES
        ('Fournitures', 'Fournitures de bureau et materiel', '#2196f3'),
        ('Equipement', 'Achat d''equipement technique', '#4caf50'),
        ('Formation', 'Formations et certifications', '#ff9800'),
        ('Marketing', 'Publicite et marketing', '#9c27b0'),
        ('Transport', 'Frais de transport et deplacement', '#f44336'),
        ('Loyer', 'Loyer et charges', '#607d8b'),
        ('Assurance', 'Assurances diverses', '#795548'),
        ('Autres', 'Autres depenses', '#9e9e9e')
    ) AS default_categories(name, description, color)
    WHERE NOT EXISTS (
        SELECT 1 FROM expense_categories 
        WHERE user_id = user_uuid AND expense_categories.name = default_categories.name
    );
END;
$$ LANGUAGE plpgsql;

-- Créer les catégories par défaut pour tous les utilisateurs existants
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN SELECT id FROM auth.users LOOP
        PERFORM create_default_categories_for_user(user_record.id);
    END LOOP;
END $$;

-- Commentaires sur les tables
COMMENT ON TABLE expense_categories IS 'Categories de depenses pour organiser les frais';
COMMENT ON TABLE expenses IS 'Depenses de l''entreprise avec details complets';

COMMENT ON COLUMN expense_categories.name IS 'Nom de la categorie';
COMMENT ON COLUMN expense_categories.description IS 'Description optionnelle de la categorie';
COMMENT ON COLUMN expense_categories.color IS 'Couleur hexadecimale pour l''affichage';
COMMENT ON COLUMN expense_categories.is_active IS 'Indique si la categorie est active';

COMMENT ON COLUMN expenses.title IS 'Titre de la depense';
COMMENT ON COLUMN expenses.description IS 'Description detaillee de la depense';
COMMENT ON COLUMN expenses.amount IS 'Montant de la depense en euros';
COMMENT ON COLUMN expenses.category_id IS 'Reference vers la categorie';
COMMENT ON COLUMN expenses.supplier IS 'Nom du fournisseur';
COMMENT ON COLUMN expenses.invoice_number IS 'Numero de facture';
COMMENT ON COLUMN expenses.payment_method IS 'Methode de paiement utilisee';
COMMENT ON COLUMN expenses.status IS 'Statut de la depense (pending, paid, cancelled)';
COMMENT ON COLUMN expenses.expense_date IS 'Date de la depense';
COMMENT ON COLUMN expenses.due_date IS 'Date d''echeance pour le paiement';
COMMENT ON COLUMN expenses.receipt_path IS 'Chemin vers le justificatif';
COMMENT ON COLUMN expenses.tags IS 'Tags pour categoriser la depense';
