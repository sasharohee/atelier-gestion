# Guide : Logique Prix TTC - Calcul du Prix HT

## 🎯 Nouvelle logique appliquée

**Le prix affiché/saisi est maintenant le prix TTC, et le prix HT est calculé en retirant la TVA du prix TTC.**

### 🔄 Changement de logique

**Avant :**
- Prix saisi = Prix HT
- TVA = Prix HT × Taux TVA
- Prix TTC = Prix HT + TVA

**Après :**
- Prix saisi = Prix TTC
- Prix HT = Prix TTC ÷ (1 + Taux TVA)
- TVA = Prix TTC - Prix HT

## 🔧 Corrections appliquées

### 1. Correction dans le Kanban (`src/pages/Kanban/Kanban.tsx`)

#### A. Calcul de la facture de réparation

**Nouvelle logique de calcul :**
```typescript
sale={{
  // ... autres propriétés
  items: [
    {
      id: '1',
      type: 'service',
      itemId: selectedRepairForInvoice.id,
      name: `Réparation - ${selectedRepairForInvoice.description}`,
      quantity: 1,
      unitPrice: selectedRepairForInvoice.totalPrice / (1 + getVatRate()), // Prix HT
      totalPrice: selectedRepairForInvoice.totalPrice / (1 + getVatRate()), // Prix HT
    }
  ],
  subtotal: selectedRepairForInvoice.totalPrice / (1 + getVatRate()), // Prix HT calculé depuis le prix TTC
  tax: selectedRepairForInvoice.totalPrice - (selectedRepairForInvoice.totalPrice / (1 + getVatRate())), // TVA calculée
  total: selectedRepairForInvoice.totalPrice, // Prix TTC (prix affiché)
  // ... autres propriétés
}}
```

#### B. Affichage des prix

**Correction des labels :**
```typescript
// Dans les cartes de réparation
<Typography variant="h6" color="primary">
  {repair.totalPrice} € TTC
</Typography>

// Dans le dialog de suppression
<Typography variant="body2" color="text.secondary">
  <strong>Prix TTC :</strong> {repairToDelete.totalPrice} €
</Typography>
```

### 2. Correction dans le composant Invoice (`src/components/Invoice.tsx`)

#### A. Affichage pour les réparations

**Label du prix principal :**
```typescript
<Typography sx={{ fontSize: '16px', mb: 1 }}>
  <strong>Prix de la réparation (TTC) :</strong> {(data as Repair).totalPrice.toLocaleString('fr-FR')} €
</Typography>
```

**Calcul des totaux :**
```typescript
// Sous-total HT
{((data as Repair).totalPrice / (1 + parseFloat(workshopSettings.vatRate) / 100)).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} €

// TVA
{((data as Repair).totalPrice - ((data as Repair).totalPrice / (1 + parseFloat(workshopSettings.vatRate) / 100))).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} €

// TOTAL TTC
{(data as Repair).totalPrice.toLocaleString('fr-FR')} €
```

#### B. Contenu HTML de la facture

**Correction du label dans le HTML :**
```html
<p><strong>Prix de la réparation (TTC) :</strong> ${(data as Repair).totalPrice.toLocaleString('fr-FR')} €</p>
```

### 3. Corrections dans les autres composants

#### A. Dashboard (`src/pages/Dashboard/Dashboard.tsx`)

**Affichage des prix :**
```typescript
<Typography variant="h6" color="primary">
  {repair.totalPrice} € TTC
</Typography>
```

#### B. Archives (`src/pages/Archive/Archive.tsx`)

**Affichage des prix :**
```typescript
<Typography variant="body2" fontWeight="medium">
  {repair.totalPrice ? `${repair.totalPrice.toFixed(2)} € TTC` : '0.00 € TTC'}
</Typography>
```

## 🧮 Formules de calcul

### Calcul du prix HT depuis le prix TTC
```
Prix HT = Prix TTC ÷ (1 + Taux TVA)
```

### Calcul de la TVA
```
TVA = Prix TTC - Prix HT
```

### Exemple avec TVA 20%
- **Prix TTC saisi** : 120,00 €
- **Prix HT calculé** : 120,00 ÷ 1,20 = 100,00 €
- **TVA calculée** : 120,00 - 100,00 = 20,00 €

## 🧪 Tests de validation

### Test 1 : Vérification du calcul
1. **Créer** une réparation avec un prix de 120,00 €
2. **Générer** la facture
3. **Vérifier** que :
   - Prix TTC : 120,00 €
   - Prix HT : 100,00 €
   - TVA (20%) : 20,00 €

### Test 2 : Vérification de l'affichage
1. **Vérifier** que tous les prix affichés sont marqués "TTC"
2. **Confirmer** que les factures affichent correctement les totaux
3. **Tester** avec différents taux de TVA

### Test 3 : Vérification de la cohérence
1. **Comparer** les prix affichés dans tous les composants
2. **Vérifier** que la logique est identique partout
3. **Confirmer** que les calculs sont corrects

## 📊 Exemples de factures

### Exemple 1 : Réparation à 150,00 € TTC (TVA 20%)
```
Prix de la réparation (TTC) : 150,00 €

Sous-total HT : 125,00 €
TVA (20%) : 25,00 €
TOTAL TTC : 150,00 €
```

### Exemple 2 : Réparation à 200,00 € TTC (TVA 10%)
```
Prix de la réparation (TTC) : 200,00 €

Sous-total HT : 181,82 €
TVA (10%) : 18,18 €
TOTAL TTC : 200,00 €
```

## ✅ Comportement attendu après correction

### Calcul automatique :
- ✅ **Prix HT calculé** : Automatiquement depuis le prix TTC
- ✅ **TVA calculée** : Différence entre prix TTC et prix HT
- ✅ **Précision** : 2 décimales pour tous les montants
- ✅ **Configuration** : Respect du taux de TVA configuré

### Interface utilisateur :
- ✅ **Labels clairs** : Tous les prix affichés sont marqués "TTC"
- ✅ **Factures complètes** : Affichage des totaux détaillés
- ✅ **Cohérence** : Même logique dans toute l'application
- ✅ **Formatage** : Montants formatés en euros français

## 🔍 Diagnostic en cas de problème

### Si les calculs sont incorrects :

1. **Vérifier** le taux de TVA dans les paramètres système
2. **Contrôler** que la formule utilise le bon taux
3. **Tester** avec des montants simples (ex: 120€ avec TVA 20%)
4. **Vérifier** que les arrondis sont corrects

### Si l'affichage est incohérent :

1. **Vérifier** que tous les labels indiquent "TTC"
2. **Contrôler** que les factures affichent les bons totaux
3. **Comparer** les affichages entre les différents composants
4. **Analyser** les logs de la console pour les erreurs

## 📝 Notes importantes

### Principe de fonctionnement
- **Prix saisi = Prix TTC** : L'utilisateur saisit le prix final
- **Calcul automatique** : Le prix HT et la TVA sont calculés automatiquement
- **Affichage clair** : Tous les prix sont marqués "TTC"
- **Cohérence globale** : Même logique dans toute l'application

### Points de vérification
1. **Saisie utilisateur** : Le prix saisi est le prix TTC
2. **Calcul automatique** : Prix HT et TVA calculés automatiquement
3. **Affichage clair** : Labels indiquent "TTC" partout
4. **Précision** : Montants arrondis à 2 décimales

## 🎯 Résultat final

Après la correction :
- ✅ **Prix TTC saisi** : L'utilisateur saisit le prix final
- ✅ **Calcul automatique** : Prix HT et TVA calculés automatiquement
- ✅ **Affichage clair** : Tous les prix marqués "TTC"
- ✅ **Factures complètes** : Totaux détaillés et corrects
- ✅ **Cohérence globale** : Même logique dans toute l'application
