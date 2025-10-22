# Guide de Correction - Erreur 403 Devices

## Problème
Lors de la création d'un modèle depuis la page kanban, vous obtenez une erreur 403 (Forbidden) :
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/devices?columns=%22brand%22%2C%22model%22%2C%22serial_number%22%2C%22type%22%2C%22specifications%22%2C%22user_id%22%2C%22created_at%22%2C%22updated_at%22&select=* 403 (Forbidden)
```

Avec le message d'erreur :
```
Supabase error: {code: '42501', details: null, hint: null, message: 'new row violates row-level security policy for table "devices"'}
```

## Cause du Problème
Le problème vient d'une incohérence entre :
1. **La structure de la table `devices`** - qui peut avoir différentes colonnes d'isolation (`user_id`, `created_by`, `workshop_id`)
2. **Les politiques RLS (Row Level Security)** - qui ne correspondent pas à la structure actuelle de la table
3. **Le code frontend** - qui envoie `user_id` mais les politiques RLS peuvent vérifier d'autres colonnes

## Solution

### 1. Exécuter le Script de Correction
Exécutez le script `correction_erreur_403_devices.sql` dans l'éditeur SQL de Supabase.

Ce script va :
- ✅ Diagnostiquer la structure actuelle de la table `devices`
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
DROP POLICY IF EXISTS devices_select_policy ON devices;
DROP POLICY IF EXISTS devices_insert_policy ON devices;
-- ... (et toutes les autres)
```

#### B. Standardisation de la Structure
```sql
-- Ajoute toutes les colonnes nécessaires
ALTER TABLE devices ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS workshop_id UUID;
-- ... (et les autres colonnes)
```

#### C. Trigger d'Isolation Automatique
```sql
-- Crée un trigger qui définit automatiquement les valeurs d'isolation
CREATE OR REPLACE FUNCTION set_device_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_by := auth.uid();
    NEW.workshop_id := auth.uid();
    -- ...
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### D. Politiques RLS Permissives
```sql
-- Politique INSERT permissive (le trigger gère l'isolation)
CREATE POLICY devices_insert_policy ON devices
    FOR INSERT WITH CHECK (true);

-- Politiques SELECT/UPDATE/DELETE basées sur l'isolation
CREATE POLICY devices_select_policy ON devices
    FOR SELECT USING (
        user_id = auth.uid()
        OR created_by = auth.uid()
        OR workshop_id = auth.uid()
        -- ...
    );
```

### 3. Vérification

Après l'exécution du script, vous devriez voir :
- ✅ Toutes les colonnes nécessaires dans la table `devices`
- ✅ 4 politiques RLS cohérentes (SELECT, INSERT, UPDATE, DELETE)
- ✅ Un trigger `set_device_context` actif
- ✅ Un test d'insertion réussi

### 4. Test de la Correction

1. **Rechargez votre application** dans le navigateur
2. **Allez sur la page kanban**
3. **Essayez de créer un nouveau modèle d'appareil**
4. **Vérifiez que l'insertion fonctionne** sans erreur 403

### 5. Si le Problème Persiste

Si vous obtenez encore des erreurs, vérifiez :

#### A. Les Logs de la Console
```javascript
// Dans la console du navigateur, vérifiez les requêtes
console.log('Données envoyées:', deviceData);
```

#### B. La Structure de la Table
```sql
-- Vérifiez que la table a la bonne structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'devices'
ORDER BY ordinal_position;
```

#### C. Les Politiques RLS
```sql
-- Vérifiez que les politiques sont correctes
SELECT policyname, cmd, qual
FROM pg_policies 
WHERE tablename = 'devices'
ORDER BY policyname;
```

### 6. Prévention

Pour éviter ce problème à l'avenir :

1. **Toujours utiliser le même système d'isolation** dans toutes les tables
2. **Tester les politiques RLS** après chaque modification
3. **Utiliser des triggers** pour l'isolation automatique plutôt que de compter sur le frontend
4. **Documenter les changements** de structure de base de données

## Résumé

L'erreur 403 sur la table `devices` était causée par des politiques RLS incohérentes avec la structure de la table. Le script de correction standardise la structure, nettoie les politiques conflictuelles et met en place un système d'isolation automatique via un trigger.

Après l'exécution du script, la création de devices depuis la page kanban devrait fonctionner correctement.





