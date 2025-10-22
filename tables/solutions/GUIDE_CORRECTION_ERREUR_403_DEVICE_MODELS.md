# Guide de Correction - Erreur 403 sur Device Models

## Problème Identifié

L'erreur suivante se produit lors de l'ajout de modèles d'appareils :

```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/device_models?columns=%22b…repair_difficulty%22%2C%22parts_availability%22%2C%22is_active%22&select=* 403 (Forbidden)

Supabase error: 
{code: '42501', details: null, hint: null, message: 'new row violates row-level security policy for table "device_models"'}
```

## Cause du Problème

Le problème vient des **politiques RLS (Row Level Security)** trop restrictives sur la table `device_models`. Ces politiques empêchent l'insertion de nouvelles données même pour les utilisateurs authentifiés.

## Solution Immédiate

### Étape 1 : Exécuter le Script de Correction

Exécutez le script `correction_device_models_403_immediate.sql` dans votre base de données Supabase :

1. Allez dans votre dashboard Supabase
2. Ouvrez l'éditeur SQL
3. Copiez-collez le contenu du fichier `correction_device_models_403_immediate.sql`
4. Exécutez le script

### Étape 2 : Vérification

Après l'exécution, vérifiez que :

1. **RLS est activé** sur la table `device_models`
2. **4 politiques sont créées** :
   - `Enable read access for authenticated users`
   - `Enable insert access for authenticated users`
   - `Enable update access for authenticated users`
   - `Enable delete access for authenticated users`

### Étape 3 : Test

Testez l'ajout d'un nouveau modèle d'appareil dans votre application.

## Détails Techniques

### Politiques RLS Appliquées

```sql
-- Lecture : Tous les utilisateurs authentifiés peuvent lire
CREATE POLICY "Enable read access for authenticated users" ON device_models
    FOR SELECT USING (auth.role() = 'authenticated');

-- Insertion : Tous les utilisateurs authentifiés peuvent insérer
CREATE POLICY "Enable insert access for authenticated users" ON device_models
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Modification : Tous les utilisateurs authentifiés peuvent modifier
CREATE POLICY "Enable update access for authenticated users" ON device_models
    FOR UPDATE USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Suppression : Tous les utilisateurs authentifiés peuvent supprimer
CREATE POLICY "Enable delete access for authenticated users" ON device_models
    FOR DELETE USING (auth.role() = 'authenticated');
```

### Modifications Apportées

1. **Suppression des anciennes politiques** trop restrictives
2. **Création de nouvelles politiques** permissives pour les utilisateurs authentifiés
3. **Vérification de la colonne `user_id`** et ajout si nécessaire
4. **Mise à jour des enregistrements existants** avec l'ID de l'admin

## Alternative Plus Sécurisée (Optionnel)

Si vous souhaitez une sécurité plus stricte, vous pouvez utiliser des politiques basées sur l'utilisateur :

```sql
-- Politiques basées sur l'utilisateur (plus sécurisées)
CREATE POLICY "Users can view their own device models" ON device_models
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own device models" ON device_models
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own device models" ON device_models
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own device models" ON device_models
    FOR DELETE USING (auth.uid() = user_id);
```

## Prévention

Pour éviter ce problème à l'avenir :

1. **Testez toujours les politiques RLS** après leur création
2. **Utilisez des politiques permissives** pendant le développement
3. **Vérifiez les permissions** avant de déployer en production
4. **Documentez les politiques RLS** pour chaque table

## Vérification Post-Correction

Après avoir appliqué la correction, vérifiez que :

- ✅ L'ajout de modèles d'appareils fonctionne
- ✅ La modification de modèles d'appareils fonctionne
- ✅ La suppression de modèles d'appareils fonctionne
- ✅ La lecture des modèles d'appareils fonctionne

## Support

Si le problème persiste après l'application de cette correction, vérifiez :

1. **Les logs Supabase** pour d'autres erreurs
2. **Les politiques RLS** sur les tables liées
3. **Les permissions utilisateur** dans votre application
4. **La configuration d'authentification** Supabase
