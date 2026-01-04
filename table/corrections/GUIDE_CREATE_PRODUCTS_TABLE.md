# 🚨 GUIDE URGENT - Création de la table Products

## ❌ Problème Identifié

L'erreur suivante se produit :
```
GET https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/products?select=*&user_id=eq.e454cc8c-3e40-4f72-bf26-4f6f43e78d0b&order=created_at.desc 404 (Not Found)

Supabase error: 
{code: 'PGRST205', details: null, hint: "Perhaps you meant the table 'public.product_categories'", message: "Could not find the table 'public.products' in the schema cache"}
```

**Cause :** La table `products` n'existe pas dans votre base de données Supabase.

## ✅ Solution

### Étape 1 : Ouvrir Supabase Dashboard

1. Allez sur https://supabase.com/dashboard
2. Connectez-vous à votre compte
3. Sélectionnez votre projet "App atelier"

### Étape 2 : Ouvrir l'éditeur SQL

1. Dans le menu de gauche, cliquez sur **"SQL Editor"**
2. Cliquez sur **"+ New query"** pour créer une nouvelle requête

### Étape 3 : Exécuter le script de création

1. **Ouvrez le fichier** `table/corrections/create_products_table.sql`
2. **Copiez TOUT le contenu** du fichier
3. **Collez-le** dans l'éditeur SQL de Supabase
4. **Cliquez sur "Run"** (ou appuyez sur Ctrl+Enter / Cmd+Enter)

### Étape 4 : Vérifier la création

Après l'exécution, vous devriez voir :
- ✅ Un message de confirmation dans les logs
- ✅ La structure de la table affichée avec toutes les colonnes
- ✅ Aucune erreur

### Étape 5 : Tester dans l'application

1. Rechargez votre application
2. Allez dans **Catalogue > Produits**
3. Essayez de créer un nouveau produit
4. Vérifiez que la page **Ventes > Nouvelle vente** affiche maintenant les produits

## 📋 Ce que fait le script

Le script `create_products_table.sql` :

1. ✅ **Crée la table `products`** si elle n'existe pas
2. ✅ **Ajoute toutes les colonnes nécessaires** :
   - `id` (UUID, clé primaire)
   - `name` (TEXT, obligatoire)
   - `description` (TEXT)
   - `category` (TEXT)
   - `subcategory` (TEXT)
   - `price` (DECIMAL)
   - `price_ht`, `price_ttc`, `price_is_ttc` (pour la gestion TVA)
   - `stock_quantity` (INTEGER, défaut 0)
   - `min_stock_level` (INTEGER, défaut 1)
   - `is_active` (BOOLEAN, défaut true)
   - `barcode` (TEXT)
   - `user_id` (UUID, référence vers auth.users)
   - `created_at`, `updated_at` (TIMESTAMP)

3. ✅ **Crée les index** pour améliorer les performances
4. ✅ **Active RLS (Row Level Security)** pour l'isolation des données
5. ✅ **Crée les politiques RLS** pour permettre aux utilisateurs de gérer leurs propres produits
6. ✅ **Rafraîchit le cache PostgREST** pour que les changements soient immédiatement visibles

## 🔍 Vérification manuelle

Si vous voulez vérifier manuellement que la table existe :

```sql
-- Vérifier que la table existe
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name = 'products';

-- Vérifier la structure de la table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'products'
ORDER BY ordinal_position;
```

## ⚠️ Important

- **Ne supprimez pas** la table `products` après sa création
- **Ne modifiez pas** les colonnes `id`, `user_id`, `created_at`, `updated_at` manuellement
- Si vous avez des **données existantes** dans d'autres tables, elles ne seront **pas affectées**

## 🆘 En cas de problème

Si vous rencontrez une erreur lors de l'exécution :

1. **Vérifiez les logs** dans Supabase pour voir l'erreur exacte
2. **Assurez-vous** que vous êtes connecté avec un compte administrateur
3. **Vérifiez** que la table `auth.users` existe (nécessaire pour la référence `user_id`)

Si le problème persiste, contactez le support ou consultez la documentation Supabase.


