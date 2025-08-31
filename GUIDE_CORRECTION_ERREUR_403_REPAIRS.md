# Guide de Correction - Erreur 403 Repairs

## Problème
Lors de la création d'une réparation depuis la page kanban, vous obtenez une erreur 403 (Forbidden) :
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/repairs?columns=%22client_id%22%2C%22status%22%2C%22description%22%2C%22issue%22%2C%22estimated_duration%22%2C%22due_date%22%2C%22is_urgent%22%2C%22total_price%22%2C%22discount_percentage%22%2C%22discount_amount%22%2C%22original_price%22%2C%22is_paid%22%2C%22user_id%22%2C%22created_at%22%2C%22updated_at%22%2C%22device_id%22%2C%22assigned_technician_id%22&select=* 403 (Forbidden)
```

Avec le message d'erreur :
```
Supabase error: {code: '42501', details: null, hint: null, message: 'new row violates row-level security policy for table "repairs"'}
```

## Cause du Problème
Le problème est identique à celui des `devices` - une incohérence entre :
1. **La structure de la table `repairs`** - qui peut avoir différentes colonnes d'isolation (`user_id`, `created_by`, `workshop_id`)
2. **Les politiques RLS (Row Level Security)** - qui ne correspondent pas à la structure actuelle de la table
3. **Le code frontend** - qui envoie `user_id` mais les politiques RLS peuvent vérifier d'autres colonnes

## Solution

### 1. Exécuter le Script de Correction
Exécutez le script `correction_erreur_403_repairs.sql` dans l'éditeur SQL de Supabase.

Ce script va :
- ✅ Diagnostiquer la structure actuelle de la table `repairs`
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
DROP POLICY IF EXISTS repairs_select_policy ON repairs;
DROP POLICY IF EXISTS repairs_insert_policy ON repairs;
-- ... (et toutes les autres)
```

#### B. Standardisation de la Structure
```sql
-- Ajoute toutes les colonnes nécessaires pour les réparations
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS workshop_id UUID;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS client_id UUID;
ALTER TABLE repairs ADD COLUMN IF NOT EXISTS device_id UUID;
-- ... (et toutes les autres colonnes de réparation)
```

#### C. Trigger d'Isolation Automatique
```sql
-- Crée un trigger qui définit automatiquement les valeurs d'isolation
CREATE OR REPLACE FUNCTION set_repair_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_by := auth.uid();
    NEW.workshop_id := auth.uid();
    NEW.status := COALESCE(NEW.status, 'new');
    NEW.is_urgent := COALESCE(NEW.is_urgent, false);
    -- ... (définit toutes les valeurs par défaut)
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### D. Politiques RLS Permissives
```sql
-- Politique INSERT permissive (le trigger gère l'isolation)
CREATE POLICY repairs_insert_policy ON repairs
    FOR INSERT WITH CHECK (true);

-- Politiques SELECT/UPDATE/DELETE basées sur l'isolation
CREATE POLICY repairs_select_policy ON repairs
    FOR SELECT USING (
        user_id = auth.uid()
        OR created_by = auth.uid()
        OR workshop_id = auth.uid()
        -- ...
    );
```

### 3. Vérification

Après l'exécution du script, vous devriez voir :
- ✅ Toutes les colonnes nécessaires dans la table `repairs`
- ✅ 4 politiques RLS cohérentes (SELECT, INSERT, UPDATE, DELETE)
- ✅ Un trigger `set_repair_context` actif
- ✅ Un test d'insertion réussi avec création automatique de client/device de test

### 4. Test de la Correction

1. **Rechargez votre application** dans le navigateur
2. **Allez sur la page kanban**
3. **Essayez de créer une nouvelle réparation**
4. **Vérifiez que l'insertion fonctionne** sans erreur 403

### 5. Particularités des Réparations

#### A. Dépendances
Les réparations ont des dépendances vers :
- **Clients** (`client_id`)
- **Devices** (`device_id`)
- **Utilisateurs** (`user_id`, `assigned_technician_id`)

Le script gère automatiquement ces dépendances en créant des données de test si nécessaire.

#### B. Valeurs par Défaut
Le trigger définit automatiquement :
- `status = 'new'`
- `is_urgent = false`
- `total_price = 0`
- `discount_percentage = 0`
- `discount_amount = 0`
- `is_paid = false`

#### C. Champs Optionnels
Les champs suivants sont optionnels et peuvent être NULL :
- `device_id`
- `assigned_technician_id`
- `estimated_duration`
- `actual_duration`
- `notes`

### 6. Si le Problème Persiste

Si vous obtenez encore des erreurs, vérifiez :

#### A. Les Logs de la Console
```javascript
// Dans la console du navigateur, vérifiez les requêtes
console.log('Données de réparation envoyées:', repairData);
```

#### B. La Structure de la Table
```sql
-- Vérifiez que la table a la bonne structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'repairs'
ORDER BY ordinal_position;
```

#### C. Les Politiques RLS
```sql
-- Vérifiez que les politiques sont correctes
SELECT policyname, cmd, qual
FROM pg_policies 
WHERE tablename = 'repairs'
ORDER BY policyname;
```

#### D. Les Données de Test
```sql
-- Vérifiez qu'il y a des clients et devices disponibles
SELECT COUNT(*) as nb_clients FROM clients;
SELECT COUNT(*) as nb_devices FROM devices;
```

### 7. Prévention

Pour éviter ce problème à l'avenir :

1. **Toujours utiliser le même système d'isolation** dans toutes les tables
2. **Tester les politiques RLS** après chaque modification
3. **Utiliser des triggers** pour l'isolation automatique plutôt que de compter sur le frontend
4. **Documenter les changements** de structure de base de données
5. **Vérifier les dépendances** entre tables (clients, devices, repairs)

### 8. Script Combiné

Si vous voulez corriger les deux problèmes en même temps, vous pouvez exécuter :
1. `correction_erreur_403_devices.sql`
2. `correction_erreur_403_repairs.sql`

Dans cet ordre pour s'assurer que les tables `devices` et `clients` sont correctement configurées avant de corriger `repairs`.

## Résumé

L'erreur 403 sur la table `repairs` était causée par des politiques RLS incohérentes avec la structure de la table. Le script de correction standardise la structure, nettoie les politiques conflictuelles et met en place un système d'isolation automatique via un trigger.

Après l'exécution du script, la création de réparations depuis la page kanban devrait fonctionner correctement, même si des clients ou devices de test doivent être créés automatiquement.


