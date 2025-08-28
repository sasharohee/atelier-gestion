-- Script pour étendre la table clients avec les nouveaux champs du formulaire ClientForm
-- Exécutez ce script pour ajouter les colonnes manquantes à la table clients existante

-- Ajout des nouveaux champs pour les informations personnelles et entreprise
ALTER TABLE public.clients 
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'particulier',
ADD COLUMN IF NOT EXISTS title TEXT DEFAULT 'mr',
ADD COLUMN IF NOT EXISTS company_name TEXT,
ADD COLUMN IF NOT EXISTS vat_number TEXT,
ADD COLUMN IF NOT EXISTS siren_number TEXT,
ADD COLUMN IF NOT EXISTS country_code TEXT DEFAULT '33';

-- Ajout des champs pour l'adresse détaillée
ALTER TABLE public.clients 
ADD COLUMN IF NOT EXISTS address_complement TEXT,
ADD COLUMN IF NOT EXISTS region TEXT,
ADD COLUMN IF NOT EXISTS postal_code TEXT,
ADD COLUMN IF NOT EXISTS city TEXT;

-- Ajout des champs pour l'adresse de facturation
ALTER TABLE public.clients 
ADD COLUMN IF NOT EXISTS billing_address_same BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS billing_address TEXT,
ADD COLUMN IF NOT EXISTS billing_address_complement TEXT,
ADD COLUMN IF NOT EXISTS billing_region TEXT,
ADD COLUMN IF NOT EXISTS billing_postal_code TEXT,
ADD COLUMN IF NOT EXISTS billing_city TEXT;

-- Ajout des champs pour les informations complémentaires
ALTER TABLE public.clients 
ADD COLUMN IF NOT EXISTS accounting_code TEXT,
ADD COLUMN IF NOT EXISTS cni_identifier TEXT,
ADD COLUMN IF NOT EXISTS attached_file_path TEXT,
ADD COLUMN IF NOT EXISTS internal_note TEXT;

-- Ajout des champs pour les préférences
ALTER TABLE public.clients 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'displayed',
ADD COLUMN IF NOT EXISTS sms_notification BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS email_notification BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS sms_marketing BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS email_marketing BOOLEAN DEFAULT true;

-- Ajout d'index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_clients_category ON public.clients(category);
CREATE INDEX IF NOT EXISTS idx_clients_status ON public.clients(status);
CREATE INDEX IF NOT EXISTS idx_clients_company_name ON public.clients(company_name);
CREATE INDEX IF NOT EXISTS idx_clients_vat_number ON public.clients(vat_number);
CREATE INDEX IF NOT EXISTS idx_clients_siren_number ON public.clients(siren_number);

-- Mise à jour de la fonction de mise à jour automatique du timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Création du trigger pour mettre à jour automatiquement updated_at
DROP TRIGGER IF EXISTS update_clients_updated_at ON public.clients;
CREATE TRIGGER update_clients_updated_at
    BEFORE UPDATE ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Commentaires pour documenter les nouveaux champs
COMMENT ON COLUMN public.clients.category IS 'Catégorie du client: particulier, professionnel, entreprise, association';
COMMENT ON COLUMN public.clients.title IS 'Titre de civilité: mr, mrs, ms, dr';
COMMENT ON COLUMN public.clients.company_name IS 'Nom de l''entreprise (pour les clients professionnels)';
COMMENT ON COLUMN public.clients.vat_number IS 'Numéro de TVA de l''entreprise';
COMMENT ON COLUMN public.clients.siren_number IS 'Numéro SIREN de l''entreprise';
COMMENT ON COLUMN public.clients.country_code IS 'Code pays pour le téléphone (défaut: 33 pour la France)';
COMMENT ON COLUMN public.clients.address_complement IS 'Complément d''adresse';
COMMENT ON COLUMN public.clients.region IS 'Région/Département';
COMMENT ON COLUMN public.clients.postal_code IS 'Code postal';
COMMENT ON COLUMN public.clients.city IS 'Ville';
COMMENT ON COLUMN public.clients.billing_address_same IS 'L''adresse de facturation est-elle identique à l''adresse de résidence?';
COMMENT ON COLUMN public.clients.billing_address IS 'Adresse de facturation';
COMMENT ON COLUMN public.clients.billing_address_complement IS 'Complément d''adresse de facturation';
COMMENT ON COLUMN public.clients.billing_region IS 'Région/Département de facturation';
COMMENT ON COLUMN public.clients.billing_postal_code IS 'Code postal de facturation';
COMMENT ON COLUMN public.clients.billing_city IS 'Ville de facturation';
COMMENT ON COLUMN public.clients.accounting_code IS 'Code comptable du client';
COMMENT ON COLUMN public.clients.cni_identifier IS 'Identifiant CNI (Carte Nationale d''Identité)';
COMMENT ON COLUMN public.clients.attached_file_path IS 'Chemin vers le fichier joint';
COMMENT ON COLUMN public.clients.internal_note IS 'Note interne sur le client';
COMMENT ON COLUMN public.clients.status IS 'Statut du client: displayed, hidden';
COMMENT ON COLUMN public.clients.sms_notification IS 'Autorise les notifications SMS';
COMMENT ON COLUMN public.clients.email_notification IS 'Autorise les notifications email';
COMMENT ON COLUMN public.clients.sms_marketing IS 'Autorise le marketing SMS';
COMMENT ON COLUMN public.clients.email_marketing IS 'Autorise le marketing email';

-- Affichage de la nouvelle structure de la table
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    col_description((table_schema||'.'||table_name)::regclass, ordinal_position) as comment
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients' 
ORDER BY ordinal_position;
