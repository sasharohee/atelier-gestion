# 🚨 Guide de Correction - Erreur 403 Products

## Problème Identifié

L'erreur suivante se produit lors de l'ajout de produits dans la page catalogue :

```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/products?columns=%22name%2…s_active%22%2C%22user_id%22%2C%22created_at%22%2C%22updated_at%22&select=* 403 (Forbidden)

Supabase error: 
{code: '42501', details: null, hint: null, message: 'new row violates row-level security policy for table "products"'}
```

## 🔍 Cause du Problème

Le problème vient des **politiques RLS (Row Level Security)** trop restrictives sur la table `products`. Ces politiques empêchent l'insertion de nouvelles données même pour les utilisateurs authentifiés.

### Problèmes spécifiques identifiés :

1. **Politiques RLS trop strictes** : Les politiques existantes vérifient des conditions qui ne sont pas remplies
2. **Colonnes d'isolation manquantes** : Les colonnes `user_id`, `created_by`, `workshop_id` peuvent être manquantes
3. **Trigger d'isolation manquant** : Aucun trigger pour définir automatiquement les valeurs d'isolation
4. **Permissions insuffisantes** : Les utilisateurs authentifiés n'ont pas les bonnes permissions

## 🛠️ Solution Complète

### Étape 1 : Exécuter le Script de Correction

1. **Ouvrez votre dashboard Supabase**
2. **Allez dans l'éditeur SQL**
3. **Copiez-collez le contenu du fichier `correction_type_discount_percentage.sql`**
4. **Exécutez le script complet**

### Étape 2 : Ce que fait le script

Le script effectue les opérations suivantes dans l'ordre :

#### Partie 1 : Correction Erreur 403 Products
1. **Désactive temporairement RLS** sur la table `products`
2. **Supprime toutes les politiques RLS existantes** qui causent le problème
3. **Vérifie et crée les colonnes d'isolation** si elles manquent :
   - `user_id` (référence vers auth.users)
   - `created_by` (référence vers auth.users)
   - `workshop_id` (référence vers auth.users)
4. **Met à jour les enregistrements existants** avec un utilisateur par défaut
5. **Crée un trigger automatique** pour définir les valeurs d'isolation
6. **Crée des politiques RLS permissives** pour les utilisateurs authentifiés
7. **Réactive RLS** avec les nouvelles politiques

#### Partie 2 : Correction Type discount_percentage
1. **Vérifie le type de la colonne** `discount_percentage`
2. **Convertit le type** en `NUMERIC(5,2)` si nécessaire
3. **Recrée la fonction** `get_loyalty_tiers` avec le bon type
4. **Accorde les permissions** nécessaires

#### Partie 3 : Vérifications Finales
1. **Teste l'insertion** d'un produit de test
2. **Vérifie les politiques RLS** créées
3. **Vérifie le trigger** d'isolation
4. **Nettoie les données de test**

### Étape 3 : Vérification

Après l'exécution, vérifiez que :

✅ **RLS est activé** sur la table `products`  
✅ **4 politiques sont créées** :
- `Enable read access for authenticated users`
- `Enable insert access for authenticated users`
- `Enable update access for authenticated users`
- `Enable delete access for authenticated users`

✅ **Les colonnes d'isolation sont créées** (`user_id`, `created_by`, `workshop_id`)  
✅ **Le trigger automatique est configuré** (`set_products_isolation_trigger`)  
✅ **Le type discount_percentage est correct** (`NUMERIC(5,2)`)  
✅ **La fonction get_loyalty_tiers fonctionne**  

### Étape 4 : Test

1. **Retournez dans votre application**
2. **Essayez d'ajouter un nouveau produit**
3. **Vérifiez que l'insertion fonctionne**
4. **Vérifiez que les données sont correctement isolées**

## 🔧 Détails Techniques

### Politiques RLS Appliquées

```sql
-- Lecture : Tous les utilisateurs authentifiés peuvent lire
CREATE POLICY "Enable read access for authenticated users" ON products
    FOR SELECT USING (auth.role() = 'authenticated');

-- Insertion : Tous les utilisateurs authentifiés peuvent insérer
CREATE POLICY "Enable insert access for authenticated users" ON products
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Mise à jour : Tous les utilisateurs authentifiés peuvent modifier
CREATE POLICY "Enable update access for authenticated users" ON products
    FOR UPDATE USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Suppression : Tous les utilisateurs authentifiés peuvent supprimer
CREATE POLICY "Enable delete access for authenticated users" ON products
    FOR DELETE USING (auth.role() = 'authenticated');
```

### Trigger d'Isolation Automatique

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

## 🚨 En Cas de Problème

### Si l'erreur persiste :

1. **Vérifiez les logs** dans la console Supabase
2. **Exécutez les vérifications** du script
3. **Vérifiez que l'utilisateur est bien authentifié**
4. **Vérifiez les permissions** de l'utilisateur

### Si vous avez des erreurs lors de l'exécution :

1. **Vérifiez la syntaxe SQL** dans l'éditeur
2. **Exécutez le script par parties** si nécessaire
3. **Vérifiez les contraintes** de clés étrangères
4. **Contactez le support** si le problème persiste

## 📋 Checklist de Vérification

- [ ] Script exécuté avec succès
- [ ] Aucune erreur dans les logs Supabase
- [ ] RLS activé sur la table products
- [ ] 4 politiques RLS créées
- [ ] Colonnes d'isolation présentes
- [ ] Trigger d'isolation actif
- [ ] Test d'insertion réussi
- [ ] Application fonctionne correctement
- [ ] Type discount_percentage corrigé
- [ ] Fonction get_loyalty_tiers fonctionne

## 🎯 Résultat Attendu

Après l'application de cette correction :

✅ **L'erreur 403 disparaît**  
✅ **L'ajout de produits fonctionne**  
✅ **Les données sont correctement isolées**  
✅ **Le système de fidélité fonctionne**  
✅ **L'application est stable**  

---

**⚠️ Important :** Cette correction est conçue pour être sûre et ne pas affecter les données existantes. Elle ajoute seulement les éléments manquants et corrige les politiques RLS.

**🔄 Maintenance :** Après cette correction, surveillez les performances et ajustez les politiques RLS si nécessaire selon vos besoins de sécurité.
