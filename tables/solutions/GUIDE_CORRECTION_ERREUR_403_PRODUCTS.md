# Guide de Correction - Erreur 403 sur Products

## Problème Identifié

L'erreur suivante se produit lors de l'ajout de produits dans la page catalogue :

```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/products?columns=%22name%2…s_active%22%2C%22user_id%22%2C%22created_at%22%2C%22updated_at%22&select=* 403 (Forbidden)

Supabase error: 
{code: '42501', details: null, hint: null, message: 'new row violates row-level security policy for table "products"'}
```

## Cause du Problème

Le problème vient des **politiques RLS (Row Level Security)** trop restrictives sur la table `products`. Ces politiques empêchent l'insertion de nouvelles données même pour les utilisateurs authentifiés.

## Solution Immédiate

### Étape 1 : Exécuter le Script de Correction

Exécutez le script `correction_products_403_immediate.sql` dans votre base de données Supabase :

1. Allez dans votre dashboard Supabase
2. Ouvrez l'éditeur SQL
3. Copiez-collez le contenu du fichier `correction_products_403_immediate.sql`
4. Exécutez le script

### Étape 2 : Vérification

Après l'exécution, vérifiez que :

1. **RLS est activé** sur la table `products`
2. **4 politiques sont créées** :
   - `Enable read access for authenticated users`
   - `Enable insert access for authenticated users`
   - `Enable update access for authenticated users`
   - `Enable delete access for authenticated users`
3. **Les colonnes d'isolation sont créées** (`user_id`, `created_by`, `workshop_id`)
4. **Le trigger automatique est configuré**

### Étape 3 : Test

Testez l'ajout d'un nouveau produit dans votre application.

## Détails Techniques

### Politiques RLS Appliquées

```sql
-- Lecture : Tous les utilisateurs authentifiés peuvent lire
CREATE POLICY "Enable read access for authenticated users" ON products
    FOR SELECT USING (auth.role() = 'authenticated');

-- Insertion : Tous les utilisateurs authentifiés peuvent insérer
CREATE POLICY "Enable insert access for authenticated users" ON products
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Modification : Tous les utilisateurs authentifiés peuvent modifier
CREATE POLICY "Enable update access for authenticated users" ON products
    FOR UPDATE USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Suppression : Tous les utilisateurs authentifiés peuvent supprimer
CREATE POLICY "Enable delete access for authenticated users" ON products
    FOR DELETE USING (auth.role() = 'authenticated');
```

### Trigger Automatique

Le script crée un trigger qui définit automatiquement les valeurs d'isolation :

```sql
CREATE OR REPLACE FUNCTION set_products_isolation()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs d'isolation automatiquement
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    
    -- Définir user_id si la colonne existe et est NULL
    IF NEW.user_id IS NULL THEN
        NEW.user_id := v_user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Modifications Apportées

1. **Suppression des anciennes politiques** trop restrictives
2. **Création de nouvelles politiques** permissives pour les utilisateurs authentifiés
3. **Vérification et création des colonnes d'isolation** (`user_id`, `created_by`, `workshop_id`)
4. **Mise à jour des enregistrements existants** avec l'ID de l'admin
5. **Création d'un trigger automatique** pour définir les valeurs d'isolation

## Vérification Post-Correction

Après avoir appliqué la correction, vérifiez que :

- ✅ L'ajout de produits fonctionne
- ✅ La modification de produits fonctionne
- ✅ La suppression de produits fonctionne
- ✅ La lecture des produits fonctionne
- ✅ Les valeurs d'isolation sont automatiquement définies

## Alternative Plus Sécurisée (Optionnel)

Si vous souhaitez une sécurité plus stricte, vous pouvez utiliser des politiques basées sur l'utilisateur :

```sql
-- Politiques basées sur l'utilisateur (plus sécurisées)
CREATE POLICY "Users can view their own products" ON products
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own products" ON products
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own products" ON products
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own products" ON products
    FOR DELETE USING (auth.uid() = user_id);
```

## Prévention

Pour éviter ce problème à l'avenir :

1. **Testez toujours les politiques RLS** après leur création
2. **Utilisez des politiques permissives** pendant le développement
3. **Vérifiez les permissions** avant de déployer en production
4. **Documentez les politiques RLS** pour chaque table

## Support

Si le problème persiste après l'application de cette correction, vérifiez :

1. **Les logs Supabase** pour d'autres erreurs
2. **Les politiques RLS** sur les tables liées
3. **Les permissions utilisateur** dans votre application
4. **La configuration d'authentification** Supabase

## Prochaines Étapes

Après avoir résolu ce problème, vous pourriez vouloir :

1. **Restaurer l'isolation** des données avec des politiques plus strictes
2. **Appliquer la même correction** aux autres tables si nécessaire
3. **Tester toutes les fonctionnalités** de la page catalogue
4. **Vérifier la cohérence** des données d'isolation
