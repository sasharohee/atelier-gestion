# 📋 Guide des Statuts de Réparations

## 🎯 Distinction entre "Annulée" et "Restituée"

### ❌ Statut "cancelled" (Annulée)
- **Signification** : La réparation a été annulée avant d'être commencée ou pendant le processus
- **Cas d'usage** :
  - Le client a changé d'avis avant le début des travaux
  - L'appareil est irréparable (coût trop élevé, pièces indisponibles)
  - Le client a trouvé une solution alternative
  - Problème de communication ou de rendez-vous manqué
- **Action** : Aucun travail effectué ou travail interrompu
- **Facturation** : Généralement pas de facturation

### ✅ Statut "returned" (Restituée)
- **Signification** : L'appareil a été réparé et restitué au client
- **Cas d'usage** :
  - Réparation terminée avec succès
  - Appareil fonctionnel remis au client
  - Travail effectué et validé
- **Action** : Réparation complète ou partielle effectuée
- **Facturation** : Facturation normale selon les travaux effectués

## 🔧 Utilisation dans l'Application

### Dans le Kanban
- **Colonne "Restitué"** : Appareils réparés et remis au client
- **Colonne "Annulé"** : Réparations annulées (à supprimer ou archiver)

### Dans les Statistiques
- **Réparations restituées** : Comptées dans les succès
- **Réparations annulées** : Comptées séparément pour l'analyse

### Dans la Facturation
- **Restituées** : Génèrent une facture
- **Annulées** : Pas de facture (sauf frais de diagnostic si applicable)

## 🛠️ Correction Appliquée

### Changements Effectués

1. **Store (Zustand)**
   - Ajout du statut `returned` avec le nom "Restitué"
   - Conservation du statut `cancelled` avec le nom "Annulée"

2. **Types TypeScript**
   - Ajout de `'returned'` dans les types de statut des ventes
   - Conservation de `'cancelled'` pour les rendez-vous

3. **Thème**
   - Ajout de la couleur pour le statut `returned`
   - Même couleur que `cancelled` (#757575) pour la cohérence

4. **Composants**
   - Mise à jour des labels dans Sales.tsx et Invoice.tsx
   - Distinction claire entre les deux statuts

### Script SQL de Correction

Le fichier `correction_statut_restitue.sql` contient :
- Ajout du nouveau statut dans la base de données
- Mise à jour des vues et triggers
- Fonction utilitaire pour convertir les statuts
- Contraintes de validation

## 📊 Impact sur les Données

### Avant la Correction
- Toutes les réparations terminées utilisaient le statut "cancelled"
- Confusion entre réparations annulées et restituées

### Après la Correction
- **"cancelled"** = Réparations réellement annulées
- **"returned"** = Réparations terminées et restituées
- Distinction claire pour les statistiques et la facturation

## 🎯 Recommandations d'Utilisation

### Pour les Techniciens
1. **Réparation terminée** → Statut "Restitué"
2. **Réparation annulée** → Statut "Annulée"
3. **En cours de réparation** → Statuts intermédiaires

### Pour les Administrateurs
1. **Suivi des performances** : Distinguer les vrais échecs des succès
2. **Facturation** : Facturer uniquement les réparations restituées
3. **Statistiques** : Analyser les taux de réussite réels

### Pour les Clients
1. **Clarté** : Comprendre si leur appareil a été réparé ou non
2. **Facturation** : Payer uniquement pour les travaux effectués
3. **Suivi** : Savoir si l'appareil est prêt à être récupéré

## 🔄 Migration des Données Existantes

Si vous avez des données existantes avec le statut "cancelled" qui devraient être "returned" :

```sql
-- Convertir une réparation spécifique
SELECT convert_cancelled_to_returned('uuid-de-la-reparation');

-- Ou mettre à jour en masse (à utiliser avec précaution)
UPDATE repairs 
SET status = 'returned', updated_at = NOW()
WHERE status = 'cancelled' 
AND [conditions-pour-identifier-les-reparations-terminees];
```

## ✅ Validation

Après application des corrections, vérifiez :
1. [ ] Le nouveau statut "Restitué" apparaît dans le Kanban
2. [ ] Les statistiques distinguent bien les deux statuts
3. [ ] La facturation fonctionne correctement
4. [ ] Les rapports sont cohérents

---

**Note** : Cette correction améliore la précision du suivi des réparations et permet une meilleure analyse des performances de l'atelier.
