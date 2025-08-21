# RÉSOLUTION DU PROBLÈME DE CRÉATION DANS LE CATALOGUE

## 🔍 DIAGNOSTIC DU PROBLÈME

### Erreur rencontrée
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/products?columns=%22name%2…s_active%22%2C%22user_id%22%2C%22created_at%22%2C%22updated_at%22&select=* 400 (Bad Request)

supabase.ts:43 Supabase error: 
{code: 'PGRST204', details: null, hint: null, message: "Could not find the 'is_active' column of 'products' in the schema cache"}
```

### Cause du problème
1. **Colonne `user_id` manquante** : La table `products` n'a pas de colonne `user_id` pour l'isolation des données
2. **Cache de schéma PostgREST** : PostgREST ne reconnaît pas la colonne `is_active` car son cache de schéma n'est pas à jour
3. **Structure de table incomplète** : Les tables du catalogue ne correspondent pas à ce que le code attend

## 🛠️ SOLUTION

### Étape 1 : Exécuter le script de correction
Exécutez le script `fix_catalog_tables_complete.sql` pour corriger toutes les tables du catalogue :

```sql
-- Ce script va :
-- 1. Ajouter la colonne user_id manquante à toutes les tables
-- 2. Ajouter la colonne is_active manquante
-- 3. Ajouter toutes les autres colonnes nécessaires
-- 4. Rafraîchir le cache PostgREST
-- 5. Tester les insertions
```

### Étape 2 : Vérifier la structure
Après exécution, vérifiez que toutes les colonnes sont présentes :

```sql
-- Vérifier la structure de la table products
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'products'
ORDER BY ordinal_position;
```

### Étape 3 : Tester la création
Testez la création d'un produit dans l'interface pour confirmer que le problème est résolu.

## 📋 TABLES CORRIGÉES

### Table `products`
- ✅ `user_id` (UUID, référence vers users.id)
- ✅ `is_active` (BOOLEAN, défaut true)
- ✅ `stock_quantity` (INTEGER, défaut 0)
- ✅ `category` (TEXT)
- ✅ `created_at` (TIMESTAMP WITH TIME ZONE)
- ✅ `updated_at` (TIMESTAMP WITH TIME ZONE)

### Table `parts`
- ✅ `user_id` (UUID, référence vers users.id)
- ✅ `is_active` (BOOLEAN, défaut true)
- ✅ `part_number` (TEXT)
- ✅ `brand` (TEXT)
- ✅ `compatible_devices` (TEXT[])
- ✅ `min_stock_level` (INTEGER, défaut 5)
- ✅ `supplier` (TEXT)

### Table `services`
- ✅ `user_id` (UUID, référence vers users.id)
- ✅ `is_active` (BOOLEAN, défaut true)
- ✅ `duration` (INTEGER, défaut 60)
- ✅ `category` (TEXT)
- ✅ `applicable_devices` (TEXT[])

### Table `devices`
- ✅ `user_id` (UUID, référence vers users.id)
- ✅ `brand` (TEXT)
- ✅ `model` (TEXT)
- ✅ `serial_number` (TEXT)
- ✅ `type` (TEXT, défaut 'other')
- ✅ `specifications` (JSONB)

### Table `clients`
- ✅ `user_id` (UUID, référence vers users.id)
- ✅ `first_name` (TEXT)
- ✅ `last_name` (TEXT)
- ✅ `phone` (TEXT)
- ✅ `address` (TEXT)

## 🔄 RAFRAÎCHISSEMENT DU CACHE

Le script inclut une commande pour rafraîchir le cache PostgREST :

```sql
NOTIFY pgrst, 'reload schema';
```

Cette commande force PostgREST à recharger son cache de schéma et à reconnaître les nouvelles colonnes.

## 🧪 TESTS D'INSERTION

Le script inclut des tests d'insertion pour chaque table pour vérifier que tout fonctionne correctement :

```sql
-- Test d'insertion d'un produit
INSERT INTO public.products (
    name, description, category, price, stock_quantity, is_active, user_id
) VALUES (
    'Test Product', 'Test', 'test', 10.00, 5, true, 
    (SELECT id FROM public.users LIMIT 1)
);
```

## 🚨 POINTS D'ATTENTION

1. **Isolation des données** : Toutes les tables ont maintenant une colonne `user_id` pour isoler les données par utilisateur
2. **Politiques RLS** : Assurez-vous que les politiques RLS sont configurées pour filtrer par `user_id`
3. **Cache PostgREST** : Si le problème persiste, le cache peut être rafraîchi manuellement

## 🔧 CORRECTION MANUELLE (si nécessaire)

Si le script automatique ne fonctionne pas, vous pouvez exécuter ces commandes manuellement :

```sql
-- Ajouter user_id à products
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);

-- Ajouter is_active à products
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
```

## ✅ VÉRIFICATION FINALE

Après correction, testez la création dans chaque section du catalogue :
- ✅ Produits
- ✅ Pièces
- ✅ Services
- ✅ Appareils
- ✅ Clients

Toutes les créations devraient maintenant fonctionner sans erreur.
