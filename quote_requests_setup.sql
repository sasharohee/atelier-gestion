-- Script de création des tables et fonctions pour les demandes de devis
-- À exécuter dans l'éditeur SQL de Supabase

-- Table des profils utilisateurs (extension de auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  avatar TEXT,
  bio TEXT,
  website TEXT,
  address TEXT,
  city TEXT,
  postal_code TEXT,
  country TEXT DEFAULT 'France',
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Table des URLs personnalisées des techniciens
CREATE TABLE IF NOT EXISTS public.technician_custom_urls (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  technician_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  custom_url TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des demandes de devis
CREATE TABLE IF NOT EXISTS public.quote_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  request_number TEXT NOT NULL,
  custom_url TEXT,
  technician_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  client_first_name TEXT NOT NULL,
  client_last_name TEXT NOT NULL,
  client_email TEXT NOT NULL,
  client_phone TEXT,
  description TEXT,
  device_type TEXT,
  device_brand TEXT,
  device_model TEXT,
  issue_description TEXT,
  urgency TEXT DEFAULT 'medium' CHECK (urgency IN ('low', 'medium', 'high')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_review', 'quoted', 'accepted', 'rejected', 'completed', 'cancelled')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  source TEXT DEFAULT 'website' CHECK (source IN ('website', 'mobile', 'api')),
  response TEXT,
  estimated_price DECIMAL(10,2),
  estimated_duration INTEGER,
  response_date TIMESTAMP WITH TIME ZONE,
  ip_address INET,
  user_agent TEXT,
  -- Nouveaux champs client
  company TEXT,
  vat_number TEXT,
  siren_number TEXT,
  -- Nouveaux champs adresse
  address TEXT,
  address_complement TEXT,
  city TEXT,
  postal_code TEXT,
  region TEXT,
  -- Nouveaux champs appareil
  device_id UUID,
  color TEXT,
  accessories TEXT,
  device_remarks TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ajouter la contrainte unique sur request_number après la création de la table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'unique_request_number' 
        AND conrelid = 'public.quote_requests'::regclass
    ) THEN
        ALTER TABLE public.quote_requests ADD CONSTRAINT unique_request_number UNIQUE (request_number);
    END IF;
END $$;

-- Table des pièces jointes des demandes de devis
CREATE TABLE IF NOT EXISTS public.quote_request_attachments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  quote_request_id UUID REFERENCES public.quote_requests(id) ON DELETE CASCADE,
  filename TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fonction pour générer un numéro de demande unique
CREATE OR REPLACE FUNCTION public.generate_quote_request_number()
RETURNS TEXT AS $$
DECLARE
  new_number TEXT;
  counter INTEGER := 1;
BEGIN
  LOOP
    new_number := 'QR-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(counter::TEXT, 4, '0');
    
    -- Vérifier si ce numéro existe déjà
    IF NOT EXISTS (SELECT 1 FROM public.quote_requests WHERE request_number = new_number) THEN
      RETURN new_number;
    END IF;
    
    counter := counter + 1;
    
    -- Éviter une boucle infinie (limite de sécurité)
    IF counter > 9999 THEN
      RAISE EXCEPTION 'Impossible de générer un numéro de demande unique';
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour récupérer les statistiques des demandes de devis
CREATE OR REPLACE FUNCTION public.get_quote_request_stats(technician_uuid UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total', COUNT(*),
    'pending', COUNT(*) FILTER (WHERE status = 'pending'),
    'inReview', COUNT(*) FILTER (WHERE status = 'in_review'),
    'quoted', COUNT(*) FILTER (WHERE status = 'quoted'),
    'accepted', COUNT(*) FILTER (WHERE status = 'accepted'),
    'rejected', COUNT(*) FILTER (WHERE status = 'rejected'),
    'byUrgency', json_build_object(
      'low', COUNT(*) FILTER (WHERE urgency = 'low'),
      'medium', COUNT(*) FILTER (WHERE urgency = 'medium'),
      'high', COUNT(*) FILTER (WHERE urgency = 'high')
    ),
    'byStatus', json_build_object(
      'pending', COUNT(*) FILTER (WHERE status = 'pending'),
      'in_review', COUNT(*) FILTER (WHERE status = 'in_review'),
      'quoted', COUNT(*) FILTER (WHERE status = 'quoted'),
      'accepted', COUNT(*) FILTER (WHERE status = 'accepted'),
      'rejected', COUNT(*) FILTER (WHERE status = 'rejected'),
      'completed', COUNT(*) FILTER (WHERE status = 'completed'),
      'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled')
    ),
    'monthly', COUNT(*) FILTER (WHERE created_at >= date_trunc('month', CURRENT_DATE)),
    'weekly', COUNT(*) FILTER (WHERE created_at >= date_trunc('week', CURRENT_DATE)),
    'daily', COUNT(*) FILTER (WHERE created_at >= date_trunc('day', CURRENT_DATE))
  ) INTO result
  FROM public.quote_requests
  WHERE technician_id = technician_uuid;
  
  RETURN COALESCE(result, json_build_object(
    'total', 0,
    'pending', 0,
    'inReview', 0,
    'quoted', 0,
    'accepted', 0,
    'rejected', 0,
    'byUrgency', json_build_object('low', 0, 'medium', 0, 'high', 0),
    'byStatus', json_build_object('pending', 0, 'in_review', 0, 'quoted', 0, 'accepted', 0, 'rejected', 0, 'completed', 0, 'cancelled', 0),
    'monthly', 0,
    'weekly', 0,
    'daily', 0
  ));
END;
$$ LANGUAGE plpgsql;

-- Activer RLS (Row Level Security) pour toutes les tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technician_custom_urls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quote_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quote_request_attachments ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour user_profiles
CREATE POLICY "Enable read access for authenticated users" ON public.user_profiles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.user_profiles FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update for own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Enable delete for own profile" ON public.user_profiles FOR DELETE USING (auth.uid() = user_id);

-- Politiques RLS pour technician_custom_urls
CREATE POLICY "Enable read access for authenticated users" ON public.technician_custom_urls FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.technician_custom_urls FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update for own URLs" ON public.technician_custom_urls FOR UPDATE USING (auth.uid() = technician_id);
CREATE POLICY "Enable delete for own URLs" ON public.technician_custom_urls FOR DELETE USING (auth.uid() = technician_id);

-- Politiques RLS pour quote_requests
CREATE POLICY "Enable read access for authenticated users" ON public.quote_requests FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.quote_requests FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update for own requests" ON public.quote_requests FOR UPDATE USING (auth.uid() = technician_id);
CREATE POLICY "Enable delete for own requests" ON public.quote_requests FOR DELETE USING (auth.uid() = technician_id);

-- Politiques RLS pour quote_request_attachments
CREATE POLICY "Enable read access for authenticated users" ON public.quote_request_attachments FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.quote_request_attachments FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.quote_request_attachments FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.quote_request_attachments FOR DELETE USING (auth.role() = 'authenticated');

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_quote_requests_technician_id ON public.quote_requests(technician_id);
CREATE INDEX IF NOT EXISTS idx_quote_requests_status ON public.quote_requests(status);
CREATE INDEX IF NOT EXISTS idx_quote_requests_created_at ON public.quote_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_quote_requests_custom_url ON public.quote_requests(custom_url);
CREATE INDEX IF NOT EXISTS idx_technician_custom_urls_technician_id ON public.technician_custom_urls(technician_id);
CREATE INDEX IF NOT EXISTS idx_technician_custom_urls_custom_url ON public.technician_custom_urls(custom_url);
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);

-- Triggers pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_technician_custom_urls_updated_at BEFORE UPDATE ON public.technician_custom_urls FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_quote_requests_updated_at BEFORE UPDATE ON public.quote_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insérer quelques données de test (optionnel)
-- Vous pouvez décommenter ces lignes pour ajouter des données de test

/*
-- Créer un profil utilisateur de test
INSERT INTO public.user_profiles (user_id, first_name, last_name, email) VALUES
('e454cc8c-3e40-4f72-bf26-4f6f43e78d0b', 'Jean', 'Dupont', 'jean.dupont@atelier.com')
ON CONFLICT (user_id) DO NOTHING;

-- Créer une URL personnalisée de test
INSERT INTO public.technician_custom_urls (technician_id, custom_url, is_active) VALUES
('e454cc8c-3e40-4f72-bf26-4f6f43e78d0b', 'jean-dupont-reparation', true)
ON CONFLICT (custom_url) DO NOTHING;
*/

COMMIT;
