# 💰 Saisie Manuelle du Montant - Commandes

## ✅ **NOUVELLE FONCTIONNALITÉ AJOUTÉE**

### **Fonctionnalité : Saisie Manuelle du Montant**
- ✅ **Avant** : Le montant était calculé automatiquement à partir des articles
- ✅ **Maintenant** : Possibilité de saisir manuellement le montant de la commande
- ✅ **Flexibilité** : Choix entre calcul automatique et saisie manuelle

### **Fonctionnalités Ajoutées**

#### **1. Sélecteur de Mode de Calcul**
```typescript
<FormControl fullWidth>
  <InputLabel>Mode de calcul du montant</InputLabel>
  <Select
    value={manualAmount ? 'manual' : 'auto'}
    onChange={(e) => setManualAmount(e.target.value === 'manual')}
    label="Mode de calcul du montant"
    disabled={!editMode}
  >
    <MenuItem value="auto">Calcul automatique (articles)</MenuItem>
    <MenuItem value="manual">Saisie manuelle</MenuItem>
  </Select>
</FormControl>
```

#### **2. Champ de Saisie du Montant**
```typescript
<TextField
  fullWidth
  label="Montant total (€)"
  type="number"
  value={manualAmount ? (formData.totalAmount || 0) : totalAmount}
  onChange={(e) => setFormData({ ...formData, totalAmount: parseFloat(e.target.value) || 0 })}
  disabled={!editMode || !manualAmount}
  inputProps={{ 
    min: 0, 
    step: 0.01,
    placeholder: "0.00"
  }}
  InputProps={{
    startAdornment: <InputAdornment position="start">€</InputAdornment>,
  }}
  helperText={!manualAmount ? `Calculé automatiquement: ${totalAmount.toLocaleString('fr-FR', { style: 'currency', currency: 'EUR' })}` : ''}
/>
```

#### **3. Logique de Sauvegarde Intelligente**
```typescript
// Déterminer le montant final
const finalAmount = manualAmount ? (formData.totalAmount || 0) : totalAmount;

// Sauvegarder avec le bon montant
const newOrder: Order = {
  // ... autres champs
  totalAmount: finalAmount,
  // ... autres champs
};
```

## ⚡ **UTILISATION**

### **Mode Calcul Automatique (Par Défaut)**
1. **Sélectionner** "Calcul automatique (articles)"
2. **Le montant** est calculé automatiquement à partir des articles
3. **Le champ** est désactivé et affiche le montant calculé
4. **Message d'aide** : "Calculé automatiquement: 150,00 €"

### **Mode Saisie Manuelle**
1. **Sélectionner** "Saisie manuelle"
2. **Le champ** devient actif et modifiable
3. **Saisir** le montant souhaité (ex: 125.50)
4. **Le montant** saisi remplace le calcul automatique

### **Cas d'Usage Pratiques**

#### **1. Commande Simple**
- **Mode** : Calcul automatique
- **Avantage** : Pas de calcul manuel nécessaire

#### **2. Commande avec Remises**
- **Mode** : Saisie manuelle
- **Exemple** : Articles = 200€, Remise = 20€, Total = 180€

#### **3. Commande avec Frais**
- **Mode** : Saisie manuelle
- **Exemple** : Articles = 150€, Frais de port = 15€, Total = 165€

#### **4. Commande Approximative**
- **Mode** : Saisie manuelle
- **Exemple** : Estimation avant devis définitif

## 🔍 **Fonctionnalités Techniques**

### **1. Validation des Données**
- ✅ **Type numérique** : Seuls les nombres acceptés
- ✅ **Valeur minimale** : 0€ minimum
- ✅ **Précision** : 2 décimales (centimes)
- ✅ **Format** : Affichage en euros avec symbole €

### **2. Interface Utilisateur**
- ✅ **Sélecteur intuitif** : Choix clair entre les modes
- ✅ **Champ adaptatif** : Actif/inactif selon le mode
- ✅ **Message d'aide** : Indication du montant calculé
- ✅ **Formatage** : Affichage en euros français

### **3. Sauvegarde Intelligente**
- ✅ **Mode automatique** : Utilise le calcul des articles
- ✅ **Mode manuel** : Utilise la saisie utilisateur
- ✅ **Validation** : Vérification avant sauvegarde

## 📋 **Checklist de Validation**

- [ ] **Mode automatique** fonctionne correctement
- [ ] **Mode manuel** permet la saisie
- [ ] **Changement de mode** fonctionne
- [ ] **Sauvegarde** avec le bon montant
- [ ] **Affichage** correct dans la liste
- [ ] **Modification** de commande existante
- [ ] **Validation** des montants négatifs

## 🎯 **Résultat Attendu**

Après utilisation de la fonctionnalité :
- ✅ **Flexibilité** : Choix entre calcul auto et manuel
- ✅ **Précision** : Montants exacts selon les besoins
- ✅ **Simplicité** : Interface intuitive et claire
- ✅ **Fiabilité** : Sauvegarde correcte des montants
- ✅ **Complétude** : Gestion de tous les cas d'usage

## 🔧 **Détails Techniques**

### **Structure des Données**
```typescript
interface Order {
  id: string;
  orderNumber: string;
  supplierName: string;
  totalAmount: number; // ✅ Maintenant modifiable
  items: OrderItem[];
  // ... autres champs
}
```

### **États du Composant**
```typescript
const [manualAmount, setManualAmount] = useState(false);
const [formData, setFormData] = useState<Partial<Order>>({});
```

### **Calcul du Montant Final**
```typescript
const finalAmount = manualAmount ? (formData.totalAmount || 0) : totalAmount;
```

## 📞 **Support**

Si vous rencontrez des problèmes :
1. **Décrire** le mode utilisé (auto/manuel)
2. **Copier** le montant saisi et le montant attendu
3. **Screenshot** de l'interface
4. **Message d'erreur** si applicable

---

**⏱️ Temps estimé : 2 minutes**

**🎯 Fonctionnalité ajoutée : Saisie manuelle du montant**

**✅ Application plus flexible et complète**

