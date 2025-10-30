# 🚀 EXÉCUTER TOUTES LES MIGRATIONS SOUS-CATÉGORIE

## ⚠️ IMPORTANT : Vous devez exécuter ces 3 migrations SQL dans Supabase

### Étapes à suivre :

1. **Ouvrez Supabase Dashboard**
   - Allez sur https://supabase.com/dashboard
   - Sélectionnez votre projet "App atelier"

2. **Ouvrez l'éditeur SQL**
   - Dans le menu de gauche, cliquez sur "SQL Editor"
   - Cliquez sur "+ New query"

3. **Copiez et exécutez ce SQL (copier TOUT le bloc d'un coup) :**

```sql
-- =====================================================
-- MIGRATIONS SOUS-CATÉGORIES - TOUTES LES TABLES
-- =====================================================

-- 1. Migration pour les PRODUITS
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS subcategory TEXT;
COMMENT ON COLUMN public.products.subcategory IS 'Optional subcategory for organizing products within a category';

-- 2. Migration pour les SERVICES
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS subcategory TEXT;
COMMENT ON COLUMN public.services.subcategory IS 'Optional subcategory for organizing services within a category';

-- 3. Migration pour les PIÈCES DÉTACHÉES
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS subcategory TEXT;
COMMENT ON COLUMN public.parts.subcategory IS 'Optional subcategory for organizing parts within a brand';

-- Vérifier que les colonnes ont été ajoutées
SELECT 
    'products' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'products' 
AND column_name = 'subcategory'
UNION ALL
SELECT 
    'services' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'services' 
AND column_name = 'subcategory'
UNION ALL
SELECT 
    'parts' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'parts' 
AND column_name = 'subcategory';
```

4. **Cliquez sur "Run"** pour exécuter les migrations

5. **Vérifiez les résultats :**
Vous devriez voir 3 lignes avec :
```
table_name  | column_name  | data_type  | is_nullable
products    | subcategory  | text       | YES
services    | subcategory  | text       | YES
parts       | subcategory  | text       | YES
```

---

## ✅ Après les migrations

Une fois les migrations exécutées :

1. **Videz le cache du navigateur** (Ctrl+Shift+R ou Cmd+Shift+R)
2. **Rechargez votre application** (F5)
3. **Créez/modifiez un produit, service ou pièce** → Le champ "Sous-catégorie" devrait maintenant apparaître
4. **Dans les ventes simplifiées** → Les produits seront organisés par sous-catégories

---

## 🎯 Fonctionnalités disponibles après migration

### Produits
- Création/édition : champ sous-catégorie avec autocomplete
- Ventes simplifiées : navigation Produits → Sous-catégories → Produits
- Catalogue : affichage et filtrage par sous-catégorie

### Services
- Création/édition : champ sous-catégorie avec autocomplete
- Catalogue : affichage et filtrage par sous-catégorie

### Pièces détachées
- Création/édition : champ sous-catégorie avec autocomplete
- Catalogue : affichage et filtrage par sous-catégorie

---

## 🔍 Si vous rencontrez des problèmes

1. Vérifiez que les 3 colonnes existent dans Supabase Table Editor
2. Videz le cache du navigateur (Ctrl+Shift+R ou Cmd+Shift+R)
3. Vérifiez la console du navigateur (F12) pour les erreurs
4. Redémarrez votre serveur de développement si nécessaire

