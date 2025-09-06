# Guide de Correction - Erreur 403 Services

## Problème
Lors de la création d'un service depuis l'application, vous obtenez une erreur 403 (Forbidden) :
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/services?columns=%22name%22%2C%22description%22%2C%22duration%22%2C%22price%22%2C%22category%22%2C%22applicable_devices%22%2C%22is_active%22%2C%22user_id%22%2C%22created_at%22%2C%22updated_at%22&select=* 403 (Forbidden)
```

Avec le message d'erreur :
```
Supabase error: {code: '42501', details: null, hint: null, message: 'new row violates row-level security policy for table "services"'}
```

## Cause du Problème
Le problème est identique aux précédents - une incohérence entre :
1. **La structure de la table `services`** - qui peut avoir différentes colonnes d'isolation (`user_id`, `created_by`, `workshop_id`)
2. **Les politiques RLS (Row Level Security)** - qui ne correspondent pas à la structure actuelle de la table
3. **Le code frontend** - qui envoie `user_id` mais les politiques RLS peuvent vérifier d'autres colonnes

## Solution

### 1. Exécuter le Script de Correction
Exécutez le script `correction_erreur_403_services.sql` dans l'éditeur SQL de Supabase.

Ce script va :
- ✅ Diagnostiquer la structure actuelle de la table `services`
- ✅ Supprimer toutes les politiques RLS conflictuelles
- ✅ S'assurer que toutes les colonnes nécessaires existent
- ✅ Mettre à jour les données existantes pour la cohérence
- ✅ Créer un trigger pour l'isolation automatique
- ✅ Recréer des politiques RLS permissives et cohérentes
- ✅ Tester l'insertion pour vérifier que ça fonctionne

### 2. Ce que fait le Script

#### A. Nettoyage des Politiques RLS
```sql
-- Supprime toutes les politiques existantes qui peuvent causer des conflits
DROP POLICY IF EXISTS services_select_policy ON services;
DROP POLICY IF EXISTS services_insert_policy ON services;
-- ... (et toutes les autres)
```

#### B. Standardisation de la Structure
```sql
-- Ajoute toutes les colonnes nécessaires pour les services
ALTER TABLE services ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE services ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);
ALTER TABLE services ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE services ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE services ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE services ADD COLUMN IF NOT EXISTS duration INTEGER DEFAULT 60;
ALTER TABLE services ADD COLUMN IF NOT EXISTS price DECIMAL(10,2) DEFAULT 0;
ALTER TABLE services ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'réparation';
ALTER TABLE services ADD COLUMN IF NOT EXISTS applicable_devices TEXT[] DEFAULT '{}';
ALTER TABLE services ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
-- ... (et toutes les autres colonnes de service)
```

#### C. Trigger d'Isolation Automatique
```sql
-- Crée un trigger qui définit automatiquement les valeurs d'isolation
CREATE OR REPLACE FUNCTION set_service_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_by := auth.uid();
    NEW.workshop_id := auth.uid();
    NEW.duration := COALESCE(NEW.duration, 60);
    NEW.price := COALESCE(NEW.price, 0);
    NEW.category := COALESCE(NEW.category, 'réparation');
    NEW.applicable_devices := COALESCE(NEW.applicable_devices, '{}');
    NEW.is_active := COALESCE(NEW.is_active, true);
    -- ... (définit toutes les valeurs par défaut)
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### D. Politiques RLS Permissives
```sql
-- Politique INSERT permissive (le trigger gère l'isolation)
CREATE POLICY services_insert_policy ON services
    FOR INSERT WITH CHECK (true);

-- Politiques SELECT/UPDATE/DELETE basées sur l'isolation
CREATE POLICY services_select_policy ON services
    FOR SELECT USING (
        user_id = auth.uid()
        OR created_by = auth.uid()
        OR workshop_id = auth.uid()
        -- ...
    );
```

### 3. Vérification

Après l'exécution du script, vous devriez voir :
- ✅ Toutes les colonnes nécessaires dans la table `services`
- ✅ 4 politiques RLS cohérentes (SELECT, INSERT, UPDATE, DELETE)
- ✅ Un trigger `set_service_context` actif
- ✅ Un test d'insertion réussi

### 4. Test de la Correction

1. **Rechargez votre application** dans le navigateur
2. **Allez sur la page des services** (ou où vous créez des services)
3. **Essayez de créer un nouveau service**
4. **Vérifiez que l'insertion fonctionne** sans erreur 403

### 5. Particularités des Services

#### A. Structure des Services
Les services ont les champs suivants :
- **Informations de base** : `name`, `description`, `category`
- **Tarification** : `price`, `duration`
- **Configuration** : `applicable_devices` (tableau de types d'appareils)
- **Statut** : `is_active`
- **Isolation** : `user_id`, `created_by`, `workshop_id`

#### B. Valeurs par Défaut
Le trigger définit automatiquement :
- `duration = 60` (minutes)
- `price = 0`
- `category = 'réparation'`
- `applicable_devices = '{}'` (tableau vide)
- `is_active = true`

#### C. Champs Optionnels
Les champs suivants sont optionnels et peuvent être NULL :
- `description`
- `applicable_devices`
- `assigned_technician_id`

### 6. Si le Problème Persiste

Si vous obtenez encore des erreurs, vérifiez :

#### A. Les Logs de la Console
```javascript
// Dans la console du navigateur, vérifiez les requêtes
console.log('Données de service envoyées:', serviceData);
```

#### B. La Structure de la Table
```sql
-- Vérifiez que la table a la bonne structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'services'
ORDER BY ordinal_position;
```

#### C. Les Politiques RLS
```sql
-- Vérifiez que les politiques sont correctes
SELECT policyname, cmd, qual
FROM pg_policies 
WHERE tablename = 'services'
ORDER BY policyname;
```

#### D. Les Données Existantes
```sql
-- Vérifiez qu'il y a des services existants
SELECT COUNT(*) as nb_services FROM services;
SELECT name, category, is_active FROM services LIMIT 5;
```

### 7. Prévention

Pour éviter ce problème à l'avenir :

1. **Toujours utiliser le même système d'isolation** dans toutes les tables
2. **Tester les politiques RLS** après chaque modification
3. **Utiliser des triggers** pour l'isolation automatique plutôt que de compter sur le frontend
4. **Documenter les changements** de structure de base de données
5. **Vérifier la cohérence** entre toutes les tables du catalogue (services, parts, products)

### 8. Script Combiné

Si vous voulez corriger tous les problèmes en même temps, vous pouvez exécuter :
1. `correction_erreur_403_devices.sql`
2. `correction_erreur_403_repairs.sql`
3. `correction_erreur_403_services.sql`

Ou utiliser un script combiné qui corrige toutes les tables du catalogue.

### 9. Tables du Catalogue

Les tables du catalogue qui peuvent avoir ce problème :
- ✅ `devices` - Appareils
- ✅ `repairs` - Réparations
- ✅ `services` - Services
- ⚠️ `parts` - Pièces détachées
- ⚠️ `products` - Produits

Si vous rencontrez des erreurs similaires avec `parts` ou `products`, appliquez la même approche.

## Résumé

L'erreur 403 sur la table `services` était causée par des politiques RLS incohérentes avec la structure de la table. Le script de correction standardise la structure, nettoie les politiques conflictuelles et met en place un système d'isolation automatique via un trigger.

Après l'exécution du script, la création de services depuis l'application devrait fonctionner correctement.





