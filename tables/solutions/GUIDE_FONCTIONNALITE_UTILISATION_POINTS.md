# Guide : Fonctionnalité d'Utilisation des Points de Fidélité

## 🎯 Nouvelle Fonctionnalité

**Fonctionnalité ajoutée :** Possibilité d'utiliser les points de fidélité des clients dans la page "Points de Fidélité".

## ✅ Modifications Apportées

### 1. **Interface Utilisateur**

#### Fichier `src/pages/Loyalty/Loyalty.tsx`
- ✅ **Nouveau bouton** : "Utiliser des Points" à côté du bouton "Ajouter des Points"
- ✅ **Nouveau dialogue** : Modal pour sélectionner le client et le nombre de points à utiliser
- ✅ **Nouvelle fonction** : `usePoints()` pour gérer l'utilisation des points

### 2. **Base de Données**

#### Fichier `tables/creation_fonction_use_loyalty_points.sql`
- ✅ **Nouvelle fonction SQL** : `use_loyalty_points()` pour traiter l'utilisation des points
- ✅ **Vérifications** : Points suffisants, client existant, etc.
- ✅ **Mise à jour automatique** : Niveau de fidélité recalculé après utilisation

## 🔧 Détails Techniques

### **Fonction Frontend `usePoints()`**
```typescript
const usePoints = async () => {
  const { data, error } = await supabase.rpc('use_loyalty_points', {
    p_client_id: usePointsForm.client_id,
    p_points: usePointsForm.points,
    p_description: usePointsForm.description
  });
  // Gestion de la réponse...
};
```

### **Fonction SQL `use_loyalty_points()`**
```sql
CREATE OR REPLACE FUNCTION use_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_description TEXT DEFAULT ''
)
RETURNS JSON
```

**Vérifications effectuées :**
- ✅ Client existe
- ✅ Client a des points de fidélité
- ✅ Points suffisants disponibles
- ✅ Nombre de points positif

**Actions effectuées :**
- ✅ Mise à jour des points utilisés
- ✅ Recalcul du niveau de fidélité
- ✅ Ajout dans l'historique
- ✅ Retour du résultat

## 🚀 Instructions d'Utilisation

### 1. **Accéder à la Fonctionnalité**
1. Aller sur la page "Points de Fidélité"
2. Cliquer sur le bouton "Utiliser des Points" (orange)

### 2. **Utiliser des Points**
1. **Sélectionner le client** dans la liste déroulante
2. **Indiquer le nombre de points** à utiliser
3. **Ajouter une description** (optionnel)
4. **Cliquer sur "Utiliser les Points"**

### 3. **Vérifier le Résultat**
1. Vérifier que les points ont été déduits
2. Vérifier que le niveau de fidélité a été mis à jour
3. Vérifier l'historique des points

## 📊 Fonctionnalités

### **Vérifications Automatiques**
- ✅ **Points suffisants** : Impossible d'utiliser plus de points que disponibles
- ✅ **Client valide** : Vérification que le client existe
- ✅ **Points positifs** : Impossible d'utiliser un nombre négatif de points

### **Mise à Jour Automatique**
- ✅ **Points utilisés** : Incrémentation du compteur `used_points`
- ✅ **Niveau de fidélité** : Recalcul automatique du niveau
- ✅ **Historique** : Enregistrement de l'utilisation dans l'historique

### **Messages d'Erreur**
- ❌ "Client non trouvé"
- ❌ "Ce client n'a pas de points de fidélité"
- ❌ "Points insuffisants. Points disponibles: X, Points demandés: Y"
- ❌ "Le nombre de points à utiliser doit être positif"

## 🎯 Cas d'Usage

### **Exemple 1 : Utilisation pour une Réduction**
1. Client avec 500 points disponibles
2. Utiliser 100 points pour une réduction de 10€
3. Résultat : 400 points restants

### **Exemple 2 : Utilisation Partielle**
1. Client avec 50 points disponibles
2. Utiliser 30 points pour un service
3. Résultat : 20 points restants

### **Exemple 3 : Tentative d'Utilisation Excessive**
1. Client avec 25 points disponibles
2. Tentative d'utiliser 50 points
3. Résultat : Erreur "Points insuffisants"

## 📝 Notes Techniques

### **Impact sur les Données**
- **Table `client_loyalty_points`** : Mise à jour de `used_points`
- **Table `loyalty_points_history`** : Nouvel enregistrement avec `points_type = 'used'`
- **Niveau de fidélité** : Recalcul automatique

### **Sécurité**
- ✅ **Vérifications** : Multiples vérifications avant traitement
- ✅ **Transactions** : Gestion des erreurs avec rollback automatique
- ✅ **Audit** : Historique complet des utilisations

### **Performance**
- ✅ **Requêtes optimisées** : Utilisation d'index sur `client_id`
- ✅ **Mise à jour atomique** : Toutes les modifications en une transaction

## 🔄 Workflow Complet

1. **Sélection du client** → Vérification de l'existence
2. **Saisie des points** → Validation du nombre
3. **Vérification des points** → Contrôle de la disponibilité
4. **Mise à jour** → Points utilisés et niveau recalculé
5. **Historique** → Enregistrement de l'action
6. **Retour** → Confirmation ou erreur

## ✅ Résultat Attendu

Après l'implémentation :
- ✅ **Interface intuitive** : Bouton et dialogue clairs
- ✅ **Fonctionnalité complète** : Utilisation des points possible
- ✅ **Sécurité** : Vérifications et validations
- ✅ **Traçabilité** : Historique complet des utilisations
- ✅ **Cohérence** : Mise à jour automatique des niveaux
