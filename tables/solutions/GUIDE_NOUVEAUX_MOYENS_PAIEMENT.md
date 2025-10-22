# Guide des Nouveaux Moyens de Paiement

## 📋 Vue d'ensemble

Les moyens de paiement disponibles dans le module de vente ont été étendus pour inclure deux nouvelles options :
- **Chèque** 
- **Liens paiement**

## 🆕 Nouveaux moyens de paiement

### 1. Chèque (`check`)
- **Description** : Paiement par chèque bancaire
- **Utilisation** : Pour les clients qui préfèrent payer par chèque
- **Affichage** : "Chèque" dans l'interface utilisateur

### 2. Liens paiement (`payment_link`)
- **Description** : Paiement via un lien de paiement en ligne
- **Utilisation** : Pour les paiements à distance ou en ligne
- **Affichage** : "Liens paiement" dans l'interface utilisateur

## 📝 Moyens de paiement disponibles

| Code | Libellé | Description |
|------|---------|-------------|
| `cash` | Espèces | Paiement en espèces |
| `card` | Carte | Paiement par carte bancaire |
| `transfer` | Virement | Paiement par virement bancaire |
| `check` | Chèque | Paiement par chèque |
| `payment_link` | Liens paiement | Paiement via lien en ligne |

## 🔧 Modifications apportées

### Fichiers modifiés

1. **`src/pages/Sales/Sales.tsx`**
   - Mise à jour du type `paymentMethod` dans le state
   - Ajout des nouvelles options dans le sélecteur
   - Mise à jour de la fonction `getPaymentMethodLabel`

2. **`src/components/Invoice.tsx`**
   - Mise à jour de la fonction `getPaymentMethodLabel` pour inclure les nouveaux moyens

3. **`src/types/index.ts`**
   - Mise à jour du type `Sale.paymentMethod`

4. **`update_types_for_new_features.ts`**
   - Mise à jour du type `PaymentMethod`

5. **`tables/create_new_tables.sql`**
   - Mise à jour du type ENUM `payment_method_type`

### Nouveau fichier créé

- **`tables/update_payment_methods.sql`** : Script SQL pour mettre à jour la base de données

## 🚀 Déploiement

### 1. Mise à jour de la base de données

Exécutez le script SQL pour mettre à jour la base de données :

```sql
-- Exécuter le fichier tables/update_payment_methods.sql
```

### 2. Redéploiement de l'application

```bash
# Reconstruire l'application
npm run build

# Redéployer
npm run deploy
```

## ✅ Vérification

Après le déploiement, vérifiez que :

1. **Interface de vente** : Les nouveaux moyens de paiement apparaissent dans le sélecteur
2. **Historique des ventes** : Les nouveaux moyens s'affichent correctement
3. **Factures** : Les nouveaux moyens sont correctement libellés
4. **Base de données** : Les nouvelles valeurs sont acceptées

## 🔍 Test des nouvelles fonctionnalités

1. **Créer une nouvelle vente**
   - Sélectionner "Chèque" comme moyen de paiement
   - Vérifier l'affichage dans l'historique
   - Générer une facture et vérifier le libellé

2. **Créer une vente avec "Liens paiement"**
   - Sélectionner "Liens paiement" comme moyen de paiement
   - Vérifier l'affichage dans l'historique
   - Générer une facture et vérifier le libellé

## 📊 Impact sur les données existantes

- **Aucun impact** sur les ventes existantes
- Les anciennes valeurs (`cash`, `card`, `transfer`) restent inchangées
- Les nouvelles ventes peuvent utiliser tous les moyens de paiement

## 🛠️ Support technique

En cas de problème :

1. Vérifier que le script SQL a été exécuté avec succès
2. Contrôler les logs de l'application
3. Vérifier que tous les fichiers ont été correctement déployés
4. Tester avec une nouvelle vente pour valider le fonctionnement

## 📈 Évolutions futures

Ces nouveaux moyens de paiement permettent d'envisager :

- Intégration avec des systèmes de paiement en ligne
- Gestion des chèques (numérotation, suivi)
- Rapports de ventes par moyen de paiement
- Statistiques de conversion par type de paiement
