# Guide : Gestion des Paiements Séparés pour les Réparations

## 📋 Vue d'ensemble

Le système de gestion des réparations a été amélioré pour permettre la gestion séparée des modes de paiement pour l'acompte et le paiement final. Le reste à payer est calculé automatiquement et affiché en temps réel.

## ✨ Nouvelles fonctionnalités

### 1. Modes de paiement séparés
- **Acompte** : Mode de paiement indépendant pour l'acompte initial
- **Paiement final** : Mode de paiement distinct pour le solde restant
- Chaque paiement peut être effectué par : Espèces, Carte bancaire, Chèque, Virement ou Lien de paiement

### 2. Calcul automatique du reste à payer
- Le reste à payer est calculé automatiquement : **Total (avec réduction) - Acompte**
- Affichage en temps réel dans le formulaire d'édition
- Mise en évidence visuelle avec une couleur primaire

### 3. Historique des paiements
- Enregistrement de tous les paiements dans une table dédiée
- Affichage détaillé sur les factures et reçus
- Traçabilité complète des transactions

## 🗄️ Modifications de la base de données

### Nouvelle table : `repair_payments`
Stocke l'historique de tous les paiements :
```sql
- id : UUID (clé primaire)
- repair_id : UUID (référence à repairs)
- payment_type : TEXT ('deposit', 'final', 'partial')
- amount : DECIMAL(10,2)
- payment_method : TEXT
- payment_date : TIMESTAMP
- notes : TEXT (optionnel)
```

### Nouvelles colonnes dans `repairs`
```sql
- deposit_payment_method : TEXT
- final_payment_method : TEXT
```

### Scripts de migration
1. `migrations/create_repair_payments_table.sql` - Crée la table repair_payments
2. `migrations/add_separate_payment_methods.sql` - Ajoute les colonnes de modes de paiement

## 💻 Utilisation dans l'interface

### Dans le formulaire d'édition de réparation (Kanban)

1. **Section Acompte**
   - Champ : Montant de l'acompte
   - Menu déroulant : Mode de paiement de l'acompte
   - Le mode de paiement est désactivé si l'acompte est à 0

2. **Reste à payer (calculé automatiquement)**
   - Champ en lecture seule
   - Affiche : Total après réduction - Acompte
   - Mis en évidence en couleur primaire

3. **Section Paiement Final**
   - Menu déroulant : Mode de paiement final
   - Activé uniquement si la réparation est marquée comme payée (isPaid = true)
   - Options : Non payé, Espèces, Carte bancaire, Chèque, Virement, Lien de paiement

### Sur les documents imprimés

#### Facture (Invoice)
- Section "Historique des paiements"
- Affiche l'acompte avec son mode de paiement
- Affiche le solde avec son mode de paiement (si payé)
- Affiche le reste à payer en surbrillance (si non payé)

#### Reçu de dépôt (Deposit Receipt)
- Affiche l'acompte versé avec le mode de paiement
- Calcule et affiche le reste à payer

#### Facture simplifiée (Print Templates)
- Section détaillée de l'historique des paiements
- Tous les paiements sont listés avec leurs modes

## 📊 Exemple d'utilisation

### Scénario : Réparation à 100€ avec acompte de 50€

1. **Création de la réparation**
   - Prix total : 100€
   - Acompte : 50€
   - Mode paiement acompte : Espèces

2. **Affichage automatique**
   - Reste à payer : 50€ (calculé automatiquement)

3. **Paiement final**
   - Client paie les 50€ restants
   - Marquer isPaid = true
   - Sélectionner mode paiement final : Carte bancaire

4. **Sur la facture finale**
   ```
   Historique des paiements :
   - Acompte (Espèces) : 50,00 €
   - Solde (Carte bancaire) : 50,00 €
   Reste à payer : 0,00 €
   ```

## 🔧 API / Services

### Nouvelles fonctions dans `repairService`

#### `addPayment(repairId, payment)`
Ajoute un paiement à l'historique
```typescript
await repairService.addPayment(repairId, {
  paymentType: 'deposit', // ou 'final', 'partial'
  amount: 50.00,
  paymentMethod: 'cash',
  paymentDate: new Date(),
  notes: 'Acompte initial'
});
```

#### `getPaymentsByRepairId(repairId)`
Récupère l'historique des paiements d'une réparation
```typescript
const result = await repairService.getPaymentsByRepairId(repairId);
if (result.success) {
  const payments = result.data;
  // Utiliser les paiements...
}
```

## 📝 Types TypeScript

### `RepairPayment`
```typescript
interface RepairPayment {
  id: string;
  repairId: string;
  paymentType: 'deposit' | 'final' | 'partial';
  amount: number;
  paymentMethod: 'cash' | 'card' | 'transfer' | 'check' | 'payment_link';
  paymentDate: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}
```

### `Repair` (champs ajoutés)
```typescript
interface Repair {
  // ... champs existants ...
  depositPaymentMethod?: 'cash' | 'card' | 'transfer' | 'check' | 'payment_link';
  finalPaymentMethod?: 'cash' | 'card' | 'transfer' | 'check' | 'payment_link';
  payments?: RepairPayment[]; // Historique des paiements
}
```

## 🚀 Déploiement

### Étapes pour appliquer les modifications

1. **Exécuter les migrations SQL**
   ```bash
   # Sur votre base de données Supabase
   psql -h your-db-host -U postgres -d your-db-name -f migrations/create_repair_payments_table.sql
   psql -h your-db-host -U postgres -d your-db-name -f migrations/add_separate_payment_methods.sql
   ```

2. **Vérifier les migrations**
   - Connectez-vous à votre dashboard Supabase
   - Vérifiez que la table `repair_payments` existe
   - Vérifiez que les colonnes `deposit_payment_method` et `final_payment_method` ont été ajoutées à `repairs`

3. **Redémarrer l'application**
   ```bash
   npm run dev
   ```

## ⚠️ Notes importantes

- **Compatibilité** : Le champ `paymentMethod` existant est conservé pour la compatibilité avec les anciennes réparations
- **Migration des données** : Les migrations SQL copient automatiquement les modes de paiement existants vers les nouveaux champs
- **Validation** : Le mode de paiement de l'acompte est automatiquement désactivé si aucun acompte n'est saisi
- **Calcul** : Le reste à payer prend en compte les réductions appliquées : (Prix total × (100 - % réduction) / 100) - Acompte

## 🎯 Avantages

1. **Traçabilité** : Historique complet de tous les paiements
2. **Flexibilité** : Modes de paiement différents pour chaque transaction
3. **Automatisation** : Calcul automatique du reste à payer
4. **Clarté** : Affichage détaillé sur tous les documents
5. **Évolutivité** : Possibilité d'ajouter des paiements partiels ultérieurement

## 📞 Support

En cas de problème ou de question, vérifiez :
- Les logs de la console pour les erreurs JavaScript
- Les logs Supabase pour les erreurs de base de données
- Que les migrations SQL ont été correctement appliquées








