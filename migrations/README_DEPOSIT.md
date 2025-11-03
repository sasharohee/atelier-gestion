# Ajout du champ Acompte (Deposit) aux réparations

## 📋 Résumé des modifications

Cette mise à jour ajoute la possibilité de saisir et afficher l'acompte payé par le client lors de la création d'une réparation dans le Kanban.

## ✅ Modifications effectuées

### 1. Interface TypeScript (`src/types/index.ts`)
- ✅ Ajout du champ `deposit?: number` dans l'interface `Repair`

### 2. Formulaire Kanban (`src/pages/Kanban/Kanban.tsx`)
- ✅ Ajout du champ `deposit` dans l'état `newRepair`
- ✅ Ajout du champ de saisie pour l'acompte dans le formulaire de création
- ✅ Inclusion du champ `deposit` dans les données envoyées lors de la création
- ✅ Réinitialisation du champ `deposit` dans `resetNewRepairForm`

### 3. Composant Facture (`src/components/Invoice.tsx`)
- ✅ Affichage de l'acompte payé dans la version imprimée
- ✅ Affichage du reste à payer (Prix total - Acompte)
- ✅ Affichage de l'acompte dans la version JSX de la facture

### 4. Service Supabase (`src/services/supabaseService.ts`)
- ✅ Conversion `deposit` → `deposit` dans la méthode `getAll`
- ✅ Conversion `deposit` → `deposit` dans la méthode `create`
- ✅ Conversion `deposit` → `deposit` dans la méthode `update`

### 5. Migration SQL (`migrations/add_deposit_to_repairs.sql`)
- ✅ Script SQL pour ajouter la colonne `deposit` à la table `repairs`

## 🚀 Instructions d'application

### Étape 1 : Appliquer la migration SQL

1. Connectez-vous à votre tableau de bord Supabase
2. Allez dans **SQL Editor**
3. Copiez et exécutez le contenu du fichier `migrations/add_deposit_to_repairs.sql`

```sql
-- Migration: Ajout de la colonne deposit (acompte) à la table repairs
ALTER TABLE public.repairs 
ADD COLUMN IF NOT EXISTS deposit DECIMAL(10,2) DEFAULT 0;

UPDATE public.repairs 
SET deposit = 0 
WHERE deposit IS NULL;
```

### Étape 2 : Vérifier la migration

Vérifiez que la colonne a été ajoutée avec succès :

```sql
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'repairs' AND column_name = 'deposit';
```

Résultat attendu :
```
column_name | data_type | column_default
------------|-----------|---------------
deposit     | numeric   | 0
```

### Étape 3 : Redémarrer l'application

Si l'application est déjà en cours d'exécution, redémarrez-la pour charger les nouvelles modifications :

```bash
npm run dev
```

## 📝 Utilisation

### Dans le Kanban

1. Cliquez sur **"+ Nouvelle réparation"**
2. Remplissez les informations de la réparation
3. Dans la section des prix, vous verrez maintenant un nouveau champ **"Acompte payé"**
4. Saisissez le montant de l'acompte versé par le client
5. Le système calculera automatiquement le reste à payer

### Sur la facture

Lorsque vous générez une facture pour une réparation avec un acompte :
- Le prix total de la réparation s'affiche
- L'acompte payé s'affiche (si > 0)
- Le reste à payer s'affiche (Prix total - Acompte)

## 🧪 Test

Pour tester la fonctionnalité :

1. Créez une nouvelle réparation dans le Kanban
2. Entrez un acompte (par exemple : 50€)
3. Sauvegardez la réparation
4. Générez la facture de la réparation
5. Vérifiez que l'acompte et le reste à payer sont bien affichés

## ⚠️ Notes importantes

- La colonne `deposit` accepte des décimales (DECIMAL(10,2))
- La valeur par défaut est 0
- Le champ est optionnel (peut être NULL ou 0)
- Les réparations existantes auront un acompte de 0 par défaut
- L'acompte n'est affiché sur la facture que s'il est supérieur à 0

## 🔄 Rollback (en cas de problème)

Si vous devez annuler la migration :

```sql
ALTER TABLE public.repairs DROP COLUMN IF EXISTS deposit;
```

**Attention** : Cette action supprimera toutes les données d'acompte existantes.

