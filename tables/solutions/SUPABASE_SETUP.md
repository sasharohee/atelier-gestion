# Configuration Supabase

## Étape 1: Récupérer les clés Supabase

1. Connectez-vous à votre dashboard Supabase : https://supabase.com/dashboard
2. Sélectionnez votre projet
3. Allez dans Settings > API
4. Copiez l'URL et la clé anon (anon key)

## Étape 2: Configuration des variables d'environnement

Créez un fichier `.env` à la racine du projet avec le contenu suivant :

```env
# Configuration Supabase
VITE_SUPABASE_URL=https://gggoqnxrspviuxadvkbh.supabase.co
VITE_SUPABASE_ANON_KEY=votre-clé-anon-ici

# Configuration PostgreSQL (optionnel)
VITE_POSTGRES_HOST=db.gggoqnxrspviuxadvkbh.supabase.co
VITE_POSTGRES_PORT=5432
VITE_POSTGRES_DB=postgres
VITE_POSTGRES_USER=postgres
VITE_POSTGRES_PASSWORD=EGQUN6paP21OlNUu
```

## Étape 3: Création des tables dans Supabase

Exécutez le script SQL suivant dans l'éditeur SQL de Supabase :

```sql
-- Table des utilisateurs (extension de auth.users)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  first_name TEXT,
  last_name TEXT,
  role TEXT DEFAULT 'technician',
  avatar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des clients
CREATE TABLE public.clients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  address TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des appareils
CREATE TABLE public.devices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  serial_number TEXT,
  type TEXT NOT NULL,
  specifications JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des services
CREATE TABLE public.services (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  duration INTEGER NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  category TEXT,
  applicable_devices TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des pièces
CREATE TABLE public.parts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  part_number TEXT,
  brand TEXT,
  compatible_devices TEXT[],
  stock_quantity INTEGER DEFAULT 0,
  min_stock_level INTEGER DEFAULT 5,
  price DECIMAL(10,2) NOT NULL,
  supplier TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des produits
CREATE TABLE public.products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  price DECIMAL(10,2) NOT NULL,
  stock_quantity INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des réparations
CREATE TABLE public.repairs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID REFERENCES public.clients(id),
  device_id UUID REFERENCES public.devices(id),
  status TEXT DEFAULT 'new',
  assigned_technician_id UUID REFERENCES public.users(id),
  description TEXT,
  issue TEXT,
  estimated_duration INTEGER,
  actual_duration INTEGER,
  estimated_start_date TIMESTAMP WITH TIME ZONE,
  estimated_end_date TIMESTAMP WITH TIME ZONE,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_urgent BOOLEAN DEFAULT false,
  notes TEXT,
  total_price DECIMAL(10,2) DEFAULT 0,
  is_paid BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des services de réparation
CREATE TABLE public.repair_services (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  repair_id UUID REFERENCES public.repairs(id) ON DELETE CASCADE,
  service_id UUID REFERENCES public.services(id),
  quantity INTEGER DEFAULT 1,
  price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des pièces de réparation
CREATE TABLE public.repair_parts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  repair_id UUID REFERENCES public.repairs(id) ON DELETE CASCADE,
  part_id UUID REFERENCES public.parts(id),
  quantity INTEGER DEFAULT 1,
  price DECIMAL(10,2) NOT NULL,
  is_used BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des ventes
CREATE TABLE public.sales (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID REFERENCES public.clients(id),
  subtotal DECIMAL(10,2) NOT NULL,
  tax DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  payment_method TEXT DEFAULT 'cash',
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des éléments de vente
CREATE TABLE public.sale_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sale_id UUID REFERENCES public.sales(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  item_id UUID,
  name TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des rendez-vous
CREATE TABLE public.appointments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  client_id UUID REFERENCES public.clients(id),
  repair_id UUID REFERENCES public.repairs(id),
  title TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  assigned_user_id UUID REFERENCES public.users(id),
  status TEXT DEFAULT 'scheduled',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des messages
CREATE TABLE public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES public.users(id),
  recipient_id UUID REFERENCES public.users(id),
  repair_id UUID REFERENCES public.repairs(id),
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des alertes de stock
CREATE TABLE public.stock_alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  part_id UUID REFERENCES public.parts(id),
  type TEXT NOT NULL,
  message TEXT NOT NULL,
  is_resolved BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des notifications
CREATE TABLE public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id),
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  related_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS (Row Level Security)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repair_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repair_parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Politiques RLS (à adapter selon vos besoins)
CREATE POLICY "Enable read access for authenticated users" ON public.users FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.clients FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.devices FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.services FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.parts FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.products FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.repairs FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.repair_services FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.repair_parts FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.sales FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.sale_items FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.appointments FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.messages FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.stock_alerts FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON public.notifications FOR SELECT USING (auth.role() = 'authenticated');

-- Politiques d'écriture (à adapter selon vos besoins)
CREATE POLICY "Enable insert for authenticated users" ON public.users FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.clients FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.devices FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.services FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.parts FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.products FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.repairs FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.repair_services FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.repair_parts FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.sales FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.sale_items FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.appointments FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.messages FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.stock_alerts FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable insert for authenticated users" ON public.notifications FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Politiques de mise à jour (à adapter selon vos besoins)
CREATE POLICY "Enable update for authenticated users" ON public.users FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.clients FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.devices FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.services FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.parts FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.products FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.repairs FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.repair_services FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.repair_parts FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.sales FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.sale_items FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.appointments FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.messages FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.stock_alerts FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.notifications FOR UPDATE USING (auth.role() = 'authenticated');

-- Politiques de suppression (à adapter selon vos besoins)
CREATE POLICY "Enable delete for authenticated users" ON public.users FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.clients FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.devices FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.services FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.parts FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.products FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.repairs FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.repair_services FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.repair_parts FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.sales FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.sale_items FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.appointments FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.messages FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.stock_alerts FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "Enable delete for authenticated users" ON public.notifications FOR DELETE USING (auth.role() = 'authenticated');
```

## Étape 4: Test de la connexion

1. Démarrez l'application : `npm run dev`
2. Ouvrez la console du navigateur
3. La connexion Supabase devrait être testée automatiquement

## Étape 5: Utilisation

L'application est maintenant connectée à Supabase ! Toutes les opérations CRUD sont gérées par les services dans `src/services/supabaseService.ts`.

### Fonctionnalités disponibles :

- **Authentification** : Connexion/déconnexion avec Supabase Auth
- **Gestion des clients** : CRUD complet
- **Gestion des appareils** : CRUD complet
- **Gestion des réparations** : CRUD complet avec relations
- **Gestion des pièces** : CRUD complet avec alertes de stock
- **Gestion des produits** : CRUD complet
- **Gestion des ventes** : CRUD complet
- **Gestion des rendez-vous** : CRUD complet
- **Statistiques du tableau de bord** : Calculs automatiques

### Notes importantes :

1. **Sécurité** : Les politiques RLS sont configurées pour les utilisateurs authentifiés
2. **Performance** : Utilisez les requêtes avec relations pour optimiser les performances
3. **Backup** : Configurez des sauvegardes automatiques dans Supabase
4. **Monitoring** : Surveillez les logs dans le dashboard Supabase
