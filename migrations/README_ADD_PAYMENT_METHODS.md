# Migration : Ajout des colonnes de modes de paiement

## 🚨 Problème

L'erreur suivante apparaît lors de la modification d'une réparation :
```
Could not find the 'deposit_payment_method' column of 'repairs' in the schema cache
```

## ✅ Solution

Les colonnes `deposit_payment_method` et `final_payment_method` n'existent pas encore dans votre base de données. Il faut les ajouter.

## 📝 Instructions

### Étape 1 : Ouvrir l'éditeur SQL de Supabase

1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet
3. Cliquez sur **SQL Editor** dans le menu de gauche
4. Cliquez sur **New Query**

### Étape 2 : Exécuter la migration

1. Ouvrez le fichier `migrations/add_payment_methods_columns.sql`
2. Copiez tout son contenu
3. Collez-le dans l'éditeur SQL de Supabase
4. Cliquez sur **Run** (ou appuyez sur `Ctrl+Enter` / `Cmd+Enter`)

### Étape 3 : Vérifier

Vous devriez voir :
- Des messages de confirmation pour chaque colonne ajoutée
- Un tableau avec les colonnes `deposit_payment_method`, `final_payment_method`, et `payment_method`

### Étape 4 : Rafraîchir l'application

1. Rechargez votre application dans le navigateur
2. Essayez de modifier une réparation et changer le mode de paiement
3. Le problème devrait être résolu !

## 🔍 Vérification manuelle

Si vous voulez vérifier que les colonnes existent, exécutez cette requête dans Supabase :

```sql
SELECT 
  column_name, 
  data_type, 
  column_default,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'repairs' 
  AND column_name IN ('deposit_payment_method', 'final_payment_method', 'payment_method')
ORDER BY column_name;
```

Vous devriez voir les 3 colonnes listées.

## ⚠️ Note importante

Après avoir exécuté la migration, le cache du schéma PostgREST sera automatiquement rafraîchi grâce à la commande `NOTIFY pgrst, 'reload schema';` dans le script.

Si vous avez encore des erreurs après avoir exécuté la migration :
1. Attendez quelques secondes (le cache peut prendre un moment à se rafraîchir)
2. Rechargez complètement votre application
3. Videz le cache du navigateur si nécessaire

