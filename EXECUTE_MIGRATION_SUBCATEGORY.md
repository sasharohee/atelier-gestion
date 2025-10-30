# 🚀 EXÉCUTER LA MIGRATION SOUS-CATÉGORIE

## ⚠️ IMPORTANT : Vous devez exécuter cette migration SQL dans Supabase

### Étapes à suivre :

1. **Ouvrez Supabase Dashboard**
   - Allez sur https://supabase.com/dashboard
   - Sélectionnez votre projet "App atelier"

2. **Ouvrez l'éditeur SQL**
   - Dans le menu de gauche, cliquez sur "SQL Editor"
   - Cliquez sur "+ New query"

3. **Copiez et exécutez ce SQL :**

```sql
-- Ajouter la colonne subcategory à la table products
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS subcategory TEXT;

-- Ajouter un commentaire descriptif
COMMENT ON COLUMN public.products.subcategory IS 'Optional subcategory for organizing products within a category';
```

4. **Cliquez sur "Run"** pour exécuter la migration

5. **Vérifiez que la colonne a été ajoutée :**

```sql
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'products' 
AND column_name = 'subcategory';
```

Vous devriez voir :
```
column_name  | data_type | is_nullable
subcategory  | text      | YES
```

---

## ✅ Après la migration

Une fois la migration exécutée :

1. **Rechargez votre application** (F5 ou Cmd+R)
2. **Modifiez un produit** → Le champ "Sous-catégorie" devrait maintenant apparaître
3. **Créez un produit** → Vous pouvez ajouter une sous-catégorie
4. **Vente simplifiée** → Les produits seront organisés par sous-catégories

---

## 🔍 Si vous ne voyez toujours pas le champ

1. Videz le cache du navigateur (Ctrl+Shift+R ou Cmd+Shift+R)
2. Vérifiez dans la console du navigateur (F12) s'il y a des erreurs
3. Vérifiez que la migration SQL a bien été exécutée

