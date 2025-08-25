# Correction complète des erreurs de cache de schéma PostgREST

## 🐛 Problèmes identifiés

L'application rencontrait des erreurs systématiques lors de la création de données dans plusieurs tables :

### 1. Erreur clients
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/clients?columns=%22first_n…%22notes%22%2C%22user_id%22%2C%22created_at%22%2C%22updated_at%22&select=* 400 (Bad Request)

Supabase error: 
{code: 'PGRST204', details: null, hint: null, message: "Could not find the 'notes' column of 'clients' in the schema cache"}
```

### 2. Erreur devices
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/devices?columns=%22brand%2…ifications%22%2C%22user_id%22%2C%22created_at%22%2C%22updated_at%22&select=* 400 (Bad Request)

Supabase error: 
{code: 'PGRST204', details: null, hint: null, message: "Could not find the 'brand' column of 'devices' in the schema cache"}
```

### 3. Erreur repairs
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/repairs?columns=%22client_id%22%2C%22device_id%22%2C%22status%22%2C%22assigned_technician_id%22%2C%22description%22%2C%22issue%22%2C%22estimated_duration%22%2C%22actual_duration%22%2C%22estimated_start_date%22%2C%22estimated_end_date%22%2C%22start_date%22%2C%22end_date%22%2C%22due_date%22%2C%22is_urgent%22%2C%22notes%22%2C%22total_price%22%2C%22is_paid%22%2C%22user_id%22%2C%22created_at%22%2C%22updated_at%22&select=* 400 (Bad Request)

Supabase error: 
{code: 'PGRST204', details: null, hint: null, message: "Could not find the 'actual_duration' column of 'repairs' in the schema cache"}
```

## 🔍 Cause du problème

Le problème était causé par une **désynchronisation entre la structure de la base de données et le cache de schéma de PostgREST** :

1. **Colonnes manquantes** : Certaines colonnes n'existaient pas dans les tables
2. **Cache obsolète** : Le cache de schéma de PostgREST n'était pas synchronisé avec la structure réelle de la base de données
3. **Incompatibilité de structure** : L'application tentait d'insérer des données avec des colonnes qui n'existaient pas

### Structure attendue par l'application vs structure réelle :

#### Table `clients`
```typescript
// TypeScript (camelCase)
interface Client {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address?: string;
  notes?: string;  // ❌ Cette colonne était manquante
  createdAt: Date;
  updatedAt: Date;
}
```

#### Table `devices`
```typescript
// TypeScript (camelCase)
interface Device {
  brand: string;        // ❌ Cette colonne était manquante
  model: string;
  serialNumber?: string;
  type: DeviceType;
  specifications?: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}
```

#### Table `repairs`
```typescript
// TypeScript (camelCase)
interface Repair {
  clientId: string;
  deviceId: string;
  status: string;
  assignedTechnicianId?: string;
  description: string;
  issue: string;
  estimatedDuration: number;
  actualDuration?: number;  // ❌ Cette colonne était manquante
  estimatedStartDate?: Date;
  estimatedEndDate?: Date;
  startDate?: Date;
  endDate?: Date;
  dueDate: Date;
  isUrgent: boolean;
  notes?: string;
  totalPrice: number;
  isPaid: boolean;
  createdAt: Date;
  updatedAt: Date;
}
```

## ✅ Solution appliquée

### Script de correction complet

**Fichier créé :** `tables/fix_all_tables_complete.sql`

Ce script corrige toutes les tables en une seule fois :

#### 1. Vérification de la structure actuelle
- ✅ Affiche la structure actuelle de toutes les tables
- ✅ Identifie les colonnes manquantes

#### 2. Correction de la table `clients`
- ✅ Ajoute toutes les colonnes manquantes (`user_id`, `first_name`, `last_name`, `email`, `phone`, `address`, `notes`, `created_at`, `updated_at`)
- ✅ Crée les index nécessaires
- ✅ Active RLS (Row Level Security)
- ✅ Crée les politiques RLS appropriées

#### 3. Correction de la table `devices`
- ✅ Ajoute toutes les colonnes manquantes (`user_id`, `brand`, `model`, `serial_number`, `type`, `specifications`, `created_at`, `updated_at`)
- ✅ Crée les index nécessaires
- ✅ Active RLS
- ✅ Crée les politiques RLS appropriées

#### 4. Correction de la table `repairs`
- ✅ Ajoute toutes les colonnes manquantes (`user_id`, `client_id`, `device_id`, `status`, `assigned_technician_id`, `description`, `issue`, `estimated_duration`, `actual_duration`, `estimated_start_date`, `estimated_end_date`, `start_date`, `end_date`, `due_date`, `is_urgent`, `notes`, `total_price`, `is_paid`, `created_at`, `updated_at`)
- ✅ Crée les index nécessaires
- ✅ Active RLS
- ✅ Crée les politiques RLS appropriées

#### 5. Rafraîchissement du cache PostgREST
- ✅ Exécute `NOTIFY pgrst, 'reload schema'` pour synchroniser le cache
- ✅ Attend la synchronisation complète

#### 6. Tests de validation
- ✅ Teste l'insertion dans chaque table
- ✅ Vérifie que toutes les colonnes sont accessibles

### Structure finale des tables

#### Table `clients`
```sql
CREATE TABLE public.clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    notes TEXT,  -- ✅ Colonne ajoutée
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Table `devices`
```sql
CREATE TABLE public.devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand TEXT NOT NULL,  -- ✅ Colonne ajoutée
    model TEXT NOT NULL,
    serial_number TEXT,
    type TEXT NOT NULL DEFAULT 'other',
    specifications JSONB,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Table `repairs`
```sql
CREATE TABLE public.repairs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES public.clients(id),
    device_id UUID REFERENCES public.devices(id),
    status TEXT DEFAULT 'new',
    assigned_technician_id UUID REFERENCES public.users(id),
    description TEXT,
    issue TEXT,
    estimated_duration INTEGER,
    actual_duration INTEGER,  -- ✅ Colonne ajoutée
    estimated_start_date TIMESTAMP WITH TIME ZONE,
    estimated_end_date TIMESTAMP WITH TIME ZONE,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_urgent BOOLEAN DEFAULT false,
    notes TEXT,
    total_price DECIMAL(10,2) DEFAULT 0,
    is_paid BOOLEAN DEFAULT false,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🚀 Instructions de résolution

### Étape 1 : Exécuter le script de correction

1. **Ouvrir l'éditeur SQL de Supabase**
2. **Copier et exécuter** le contenu de `tables/fix_all_tables_complete.sql`
3. **Vérifier** que tous les messages de succès s'affichent

### Étape 2 : Vérifier la correction

Le script affichera :
- La structure actuelle de chaque table
- Les colonnes ajoutées
- Le résultat des tests d'insertion
- La structure finale

### Étape 3 : Tester l'application

1. **Recharger l'application**
2. **Essayer de créer** :
   - Un nouveau client
   - Un nouvel appareil
   - Une nouvelle réparation
3. **Vérifier** que toutes les erreurs ont disparu

## 🔧 Points techniques importants

### Rafraîchissement du cache PostgREST

Le cache de schéma de PostgREST doit être rafraîchi après modification de la structure :

```sql
NOTIFY pgrst, 'reload schema';
```

### Politiques RLS

Les politiques RLS assurent l'isolation des données entre utilisateurs :

```sql
CREATE POLICY "Users can view own clients" ON public.clients 
    FOR SELECT USING (auth.uid() = user_id);
```

### Conversion camelCase ↔ snake_case

L'application utilise camelCase (TypeScript) tandis que la base de données utilise snake_case (SQL) :

```typescript
// TypeScript (camelCase)
client.firstName → first_name (SQL)
device.brand → brand (SQL)
repair.actualDuration → actual_duration (SQL)
```

## 📋 Vérification post-correction

Après exécution du script, vérifier que :

1. ✅ Toutes les colonnes manquantes existent dans les tables
2. ✅ Le cache PostgREST est synchronisé
3. ✅ Les politiques RLS sont en place
4. ✅ L'insertion fonctionne dans toutes les tables
5. ✅ L'application peut créer des clients, appareils et réparations

## 🛡️ Prévention

Pour éviter ce type de problème à l'avenir :

1. **Synchronisation des schémas** : Toujours rafraîchir le cache PostgREST après modification de structure
2. **Tests de structure** : Vérifier la présence de toutes les colonnes nécessaires
3. **Documentation** : Maintenir une documentation à jour de la structure de la base de données
4. **Scripts de migration** : Utiliser des scripts de migration pour les changements de structure
5. **Tests automatisés** : Mettre en place des tests pour vérifier la cohérence des schémas

## 📞 Support

Si le problème persiste après exécution du script :

1. Vérifier les logs de l'éditeur SQL Supabase
2. Contrôler que toutes les colonnes sont présentes
3. S'assurer que le cache PostgREST a été rafraîchi
4. Tester avec un utilisateur authentifié
5. Vérifier les politiques RLS

## 📁 Fichiers créés

- `tables/fix_all_tables_complete.sql` - Script de correction complet
- `tables/fix_clients_table_complete.sql` - Correction spécifique clients
- `tables/fix_devices_table_complete.sql` - Correction spécifique devices
- `tables/fix_clients_and_devices_tables.sql` - Correction clients et devices
- `md/CORRECTION_SCHEMA_CACHE_COMPLETE.md` - Documentation complète
