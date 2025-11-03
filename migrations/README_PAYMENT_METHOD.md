# Ajout du mode de paiement aux réparations

## 📋 Résumé des modifications

Cette mise à jour ajoute la possibilité de sélectionner et enregistrer le mode de paiement lors de la création ou modification d'une réparation dans le Kanban.

## ✅ Modifications effectuées

### 1. Interface TypeScript (`src/types/index.ts`)
- ✅ Ajout du champ `paymentMethod?: 'cash' | 'card' | 'transfer' | 'check' | 'payment_link'` dans l'interface `Repair`

### 2. Formulaire Kanban (`src/pages/Kanban/Kanban.tsx`)
- ✅ Ajout du champ `paymentMethod` dans les états `newRepair` et `editRepair`
- ✅ Ajout d'un champ Select pour choisir le mode de paiement dans le formulaire de création
- ✅ Ajout d'un champ Select pour choisir le mode de paiement dans le formulaire d'édition
- ✅ Inclusion du champ `paymentMethod` dans les données envoyées lors de la création/modification
- ✅ Initialisation du champ `paymentMethod` dans `initializeEditForm`
- ✅ Réinitialisation du champ `paymentMethod` dans `resetNewRepairForm`

### 3. Composant Facture (`src/components/Invoice.tsx`)
- ✅ Affichage du mode de paiement dans la version imprimée (HTML string)
- ✅ Affichage du mode de paiement dans la version JSX de la facture
- ✅ Utilisation de la fonction `getPaymentMethodLabel` pour traduire les valeurs

### 4. Service Supabase (`src/services/supabaseService.ts`)
- ✅ Conversion `payment_method` ↔ `paymentMethod` dans la méthode `getAll`
- ✅ Conversion `payment_method` ↔ `paymentMethod` dans la méthode `getById`
- ✅ Conversion `paymentMethod` → `payment_method` dans la méthode `create`
- ✅ Conversion `paymentMethod` → `payment_method` dans la méthode `update`

### 5. Migration SQL (`migrations/add_payment_method_to_repairs.sql`)
- ✅ Script SQL pour ajouter la colonne `payment_method` à la table `repairs`
- ✅ Contrainte CHECK pour valider les valeurs possibles
- ✅ Valeur par défaut: `'cash'` (Espèces)

## 🎯 Modes de paiement disponibles

| Valeur (DB) | Label (Interface) | Description |
|-------------|-------------------|-------------|
| `cash` | Espèces | Paiement en espèces |
| `card` | Carte bancaire | Paiement par carte bancaire |
| `check` | Chèque | Paiement par chèque |
| `transfer` | Virement | Paiement par virement bancaire |
| `payment_link` | Lien de paiement | Paiement via un lien de paiement en ligne |

## 🚀 Instructions d'application

### Étape 1 : Appliquer la migration SQL

1. Connectez-vous à votre tableau de bord Supabase
2. Allez dans **SQL Editor**
3. Copiez et exécutez le contenu du fichier `migrations/add_payment_method_to_repairs.sql`

```sql
-- Ajouter la colonne payment_method avec une valeur par défaut de 'cash'
ALTER TABLE public.repairs 
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash';

-- Ajouter une contrainte CHECK pour s'assurer que seules les valeurs valides sont acceptées
ALTER TABLE public.repairs 
ADD CONSTRAINT repairs_payment_method_check 
CHECK (payment_method IN ('cash', 'card', 'transfer', 'check', 'payment_link'));

UPDATE public.repairs 
SET payment_method = 'cash' 
WHERE payment_method IS NULL;
```

### Étape 2 : Vérifier la migration

Vérifiez que la colonne a été ajoutée avec succès :

```sql
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'repairs' AND column_name = 'payment_method';
```

Résultat attendu :
```
column_name    | data_type | column_default
---------------|-----------|---------------
payment_method | text      | 'cash'::text
```

### Étape 3 : Redémarrer l'application

Si l'application est déjà en cours d'exécution, redémarrez-la pour charger les nouvelles modifications :

```bash
npm run dev
```

## 📝 Utilisation

### Dans le Kanban - Création de réparation

1. Cliquez sur **"+ Nouvelle réparation"**
2. Remplissez les informations de la réparation
3. Dans la section des paiements, vous verrez maintenant :
   - **Acompte payé** : Montant de l'acompte versé
   - **Mode de paiement** : Liste déroulante avec les options
   - **Date d'échéance** : Date limite de la réparation

### Dans le Kanban - Modification de réparation

1. Cliquez sur une carte de réparation pour l'éditer
2. Dans l'onglet **"Réparation"**, section paiements :
   - Modifiez l'acompte si nécessaire
   - Sélectionnez le mode de paiement
   - Modifiez la date d'échéance

### Sur la facture

Lorsque vous générez une facture pour une réparation :
- Le mode de paiement s'affiche dans les détails de la facture
- Format : **Mode de paiement : Carte bancaire** (exemple)

## 🧪 Test

Pour tester la fonctionnalité :

1. **Créer une nouvelle réparation** :
   - Sélectionnez un mode de paiement (ex: Carte bancaire)
   - Entrez un acompte si nécessaire
   - Sauvegardez

2. **Vérifier l'enregistrement** :
   - Rechargez la page
   - Ouvrez la réparation en mode édition
   - Vérifiez que le mode de paiement est bien sélectionné

3. **Générer une facture** :
   - Cliquez sur l'icône de facture de la réparation
   - Vérifiez que le mode de paiement s'affiche correctement

## ⚠️ Notes importantes

- La colonne `payment_method` accepte uniquement les valeurs définies dans la contrainte CHECK
- La valeur par défaut est `'cash'` (Espèces)
- Le champ est optionnel dans l'interface TypeScript (`paymentMethod?`)
- Les réparations existantes auront le mode de paiement "Espèces" par défaut
- Le mode de paiement est affiché sur la facture uniquement s'il est renseigné

## 🔄 Rollback (en cas de problème)

Si vous devez annuler la migration :

```sql
ALTER TABLE public.repairs DROP CONSTRAINT IF EXISTS repairs_payment_method_check;
ALTER TABLE public.repairs DROP COLUMN IF EXISTS payment_method;
```

**Attention** : Cette action supprimera toutes les données de mode de paiement existantes.

## 📊 Relation avec l'acompte

Le mode de paiement et l'acompte sont complémentaires :
- **Acompte** : Montant payé d'avance
- **Mode de paiement** : Comment le paiement a été effectué

Exemple d'utilisation :
```
Prix total: 150,00 €
Acompte payé: 50,00 €
Mode de paiement: Carte bancaire
Reste à payer: 100,00 €
```

