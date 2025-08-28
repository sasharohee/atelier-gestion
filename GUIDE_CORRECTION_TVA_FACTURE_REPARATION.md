# Guide : Correction de la TVA sur les Factures de Réparation

## 🎯 Problème identifié

**La TVA ne s'appliquait pas sur les factures de réparation dans la page de suivi des réparations.**

### 🔍 Cause du problème

1. **Dans le Kanban** : La facture de réparation était créée avec `tax: 0` au lieu de calculer la TVA
2. **Dans le composant Invoice** : La section des totaux (sous-total, TVA, total TTC) n'était affichée que pour les ventes, pas pour les réparations

## 🔧 Correction appliquée

### 1. Correction dans le Kanban (`src/pages/Kanban/Kanban.tsx`)

#### A. Ajout de la gestion des paramètres système

**Import des paramètres système :**
```typescript
const {
  // ... autres imports
  systemSettings,
  loadSystemSettings,
} = useAppStore();
```

**Chargement des paramètres au montage :**
```typescript
// Charger les paramètres système au montage du composant
useEffect(() => {
  if (systemSettings.length === 0) {
    loadSystemSettings();
  }
}, [systemSettings.length, loadSystemSettings]);
```

**Fonction pour obtenir le taux de TVA configuré :**
```typescript
// Fonction pour obtenir le taux de TVA configuré
const getVatRate = () => {
  const vatSetting = systemSettings.find(s => s.key === 'vat_rate');
  return vatSetting ? parseFloat(vatSetting.value) / 100 : 0.20; // 20% par défaut
};
```

#### B. Correction du calcul de la TVA dans la facture

**Avant :**
```typescript
sale={{
  // ... autres propriétés
  subtotal: selectedRepairForInvoice.totalPrice,
  tax: 0, // ❌ TVA à 0
  total: selectedRepairForInvoice.totalPrice, // ❌ Pas de TVA
  // ... autres propriétés
}}
```

**Après :**
```typescript
sale={{
  // ... autres propriétés
  subtotal: selectedRepairForInvoice.totalPrice,
  tax: (selectedRepairForInvoice.totalPrice * getVatRate()), // ✅ TVA configurée
  total: selectedRepairForInvoice.totalPrice * (1 + getVatRate()), // ✅ Prix TTC
  // ... autres propriétés
}}
```

### 2. Correction dans le composant Invoice (`src/components/Invoice.tsx`)

#### A. Ajout de l'affichage des totaux pour les réparations

**Ajout de la section des totaux pour les réparations :**
```typescript
{isRepair ? (
  // Affichage pour les réparations
  <Box sx={{ mb: 5 }}>
    {/* Détails de la réparation existants */}
    
    {/* Totaux pour les réparations - NOUVEAU */}
    <Box sx={{ 
      display: 'flex', 
      flexDirection: 'column', 
      alignItems: 'flex-end', 
      mb: 5 
    }}>
      <Box sx={{ 
        width: '300px',
        p: 2,
        backgroundColor: '#f8f9fa',
        borderRadius: 1,
        border: '1px solid #e0e0e0'
      }}>
        <Box sx={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          mb: 1 
        }}>
          <Typography sx={{ fontWeight: 600, fontSize: '16px' }}>
            Sous-total HT :
          </Typography>
          <Typography sx={{ fontWeight: 600, fontSize: '16px' }}>
            {(data as Repair).totalPrice.toLocaleString('fr-FR')} €
          </Typography>
        </Box>
        <Box sx={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          mb: 1 
        }}>
          <Typography sx={{ fontSize: '16px' }}>
            TVA ({workshopSettings.vatRate}%) :
          </Typography>
          <Typography sx={{ fontSize: '16px' }}>
            {((data as Repair).totalPrice * (parseFloat(workshopSettings.vatRate) / 100)).toLocaleString('fr-FR')} €
          </Typography>
        </Box>
        <Divider sx={{ my: 1.5, borderColor: '#eee' }} />
        <Box sx={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center' 
        }}>
          <Typography sx={{ 
            fontWeight: 600, 
            fontSize: '16px',
            color: '#1976d2'
          }}>
            TOTAL TTC :
          </Typography>
          <Typography sx={{ 
            fontWeight: 600, 
            fontSize: '16px',
            color: '#1976d2'
          }}>
            {((data as Repair).totalPrice * (1 + parseFloat(workshopSettings.vatRate) / 100)).toLocaleString('fr-FR')} €
          </Typography>
        </Box>
      </Box>
    </Box>
  </Box>
) : (
  // Affichage pour les ventes (inchangé)
)}
```

## 🧪 Tests de validation

### Test 1 : Vérification du calcul de la TVA
1. **Aller** dans la page "Suivi des Réparations"
2. **Cliquer** sur l'icône de facture d'une réparation
3. **Vérifier** que la facture affiche :
   - Sous-total HT : Prix de la réparation
   - TVA (20%) : Montant calculé
   - TOTAL TTC : Prix + TVA

### Test 2 : Vérification de la configuration
1. **Aller** dans "Administration" > "Paramètres"
2. **Modifier** le taux de TVA (ex: 10%)
3. **Générer** une nouvelle facture de réparation
4. **Vérifier** que le nouveau taux est appliqué

### Test 3 : Vérification de la cohérence
1. **Comparer** les factures de réparation et de vente
2. **Vérifier** que le calcul de TVA est identique
3. **Confirmer** que l'affichage est cohérent

## 📊 Exemple de facture corrigée

### Avant la correction :
```
Prix de la réparation : 150,00 €
```

### Après la correction :
```
Sous-total HT : 150,00 €
TVA (20%) : 30,00 €
TOTAL TTC : 180,00 €
```

## ✅ Comportement attendu après correction

### Calcul de la TVA :
- ✅ **TVA configurable** : Utilise le taux défini dans les paramètres système
- ✅ **Calcul automatique** : TVA = Prix HT × Taux TVA
- ✅ **Prix TTC** : Prix HT + TVA
- ✅ **Affichage complet** : Sous-total, TVA, et Total TTC

### Interface utilisateur :
- ✅ **Facture complète** : Affichage des totaux pour les réparations
- ✅ **Cohérence** : Même format que les factures de vente
- ✅ **Configuration** : Respect du taux de TVA configuré
- ✅ **Formatage** : Montants formatés en euros français

## 🔍 Diagnostic en cas de problème

### Si la TVA ne s'affiche pas :

1. **Vérifier** que les paramètres système sont chargés
2. **Contrôler** que le paramètre `vat_rate` existe
3. **Vérifier** que la fonction `getVatRate()` retourne une valeur
4. **Analyser** les logs de la console pour les erreurs

### Si le calcul est incorrect :

1. **Vérifier** le taux de TVA dans les paramètres système
2. **Contrôler** que le calcul utilise le bon taux
3. **Tester** avec différents montants
4. **Comparer** avec les factures de vente

## 📝 Notes importantes

### Principe de fonctionnement
- **TVA configurable** : Le taux est défini dans les paramètres système
- **Calcul automatique** : Pas de saisie manuelle de la TVA
- **Cohérence** : Même logique pour réparations et ventes
- **Affichage complet** : Tous les montants sont visibles

### Points de vérification
1. **Paramètres système** : Le taux de TVA doit être configuré
2. **Calcul automatique** : La TVA est calculée automatiquement
3. **Affichage complet** : Sous-total, TVA, et Total TTC sont affichés
4. **Formatage** : Les montants sont correctement formatés

## 🎯 Résultat final

Après la correction :
- ✅ **TVA appliquée** : La TVA est correctement calculée et affichée
- ✅ **Configuration respectée** : Le taux configuré est utilisé
- ✅ **Interface complète** : Affichage des totaux pour les réparations
- ✅ **Cohérence** : Même comportement que les factures de vente
- ✅ **Calcul automatique** : Plus de saisie manuelle de la TVA
