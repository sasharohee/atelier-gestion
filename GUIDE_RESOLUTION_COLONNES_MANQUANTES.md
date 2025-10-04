# Guide de résolution - Colonnes manquantes dans la table expenses

## 🔍 Problème identifié

Les erreurs suivantes indiquent que des colonnes essentielles manquent dans la table `expenses` :

- `column expenses.expense_date does not exist`
- `column expenses.status does not exist`

### Cause du problème
La structure de la table `expenses` ne correspond pas à ce que le code de service attend. Il manque plusieurs colonnes importantes.

## 🛠️ Solution

### Étape 1 : Diagnostic des colonnes manquantes
Exécutez d'abord le diagnostic pour voir quelles colonnes manquent :

```sql
-- Exécuter dans Supabase SQL Editor
\i diagnose_expenses_columns.sql
```

### Étape 2 : Correction complète de la structure
Exécutez le script de correction complet qui ajoute toutes les colonnes manquantes :

```sql
-- Exécuter dans Supabase SQL Editor
\i fix_expenses_complete_structure.sql
```

### Étape 3 : Vérification
Testez que toutes les colonnes existent maintenant :

```sql
-- Vérifier la structure finale
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'expenses' 
AND table_schema = 'public'
ORDER BY ordinal_position;
```

## 📋 Ce que fait le script de correction

### Colonnes ajoutées :
- ✅ `title` - Titre de la dépense
- ✅ `description` - Description détaillée
- ✅ `category_id` - Référence vers expense_categories
- ✅ `supplier` - Nom du fournisseur
- ✅ `invoice_number` - Numéro de facture
- ✅ `payment_method` - Méthode de paiement
- ✅ `status` - Statut de la dépense (pending, paid, cancelled)
- ✅ `expense_date` - Date de la dépense
- ✅ `due_date` - Date d'échéance
- ✅ `receipt_path` - Chemin vers le justificatif
- ✅ `tags` - Tags pour catégoriser

### Relations établies :
- ✅ Contrainte de clé étrangère entre `expenses.category_id` et `expense_categories.id`
- ✅ Catégories par défaut créées pour les utilisateurs existants
- ✅ Contraintes de validation pour `payment_method` et `status`

### Sécurité et performances :
- ✅ Politiques RLS configurées
- ✅ Index créés pour les performances
- ✅ Contraintes de validation ajoutées

## ⚠️ Points d'attention

- **Sauvegarde** : Faites une sauvegarde avant d'exécuter le script
- **Données existantes** : Le script préserve toutes les données existantes
- **Catégories par défaut** : Des catégories "Général" seront créées automatiquement
- **Migration des données** : Les `category_id` seront automatiquement assignés

## 🧪 Test après correction

Une fois le script exécuté, testez votre application :

1. **Rechargez la page** des dépenses
2. **Vérifiez** que les dépenses s'affichent correctement
3. **Testez la création** d'une nouvelle dépense
4. **Vérifiez** que les statistiques fonctionnent
5. **Testez les filtres** par statut et date

## 🔧 Vérifications supplémentaires

### Test de la relation :
```sql
SELECT 
    e.title,
    e.amount,
    e.status,
    e.expense_date,
    ec.name as category_name
FROM public.expenses e
JOIN public.expense_categories ec ON e.category_id = ec.id
LIMIT 5;
```

### Test des colonnes critiques :
```sql
SELECT 
    COUNT(*) as total,
    COUNT(expense_date) as with_date,
    COUNT(status) as with_status,
    COUNT(category_id) as with_category
FROM public.expenses;
```

## 🚨 Si le problème persiste

Si vous obtenez encore des erreurs après l'exécution du script :

1. **Vérifiez les logs** du script pour voir s'il y a eu des erreurs
2. **Exécutez le diagnostic** pour voir l'état actuel
3. **Vérifiez les politiques RLS** dans l'interface Supabase
4. **Testez avec une requête simple** :

```sql
SELECT * FROM public.expenses LIMIT 1;
```

## 📞 Support

Si vous rencontrez des difficultés :
1. Copiez les résultats du script de diagnostic
2. Vérifiez que toutes les étapes ont été exécutées sans erreur
3. Testez avec les requêtes de vérification
4. Vérifiez que les politiques RLS sont correctement configurées
