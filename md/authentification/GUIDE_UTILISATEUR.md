# Guide d'Intégration - Atelier de Gestion

## 🎯 Vue d'ensemble

Le guide d'intégration est un système interactif conçu pour aider les nouveaux utilisateurs à découvrir et comprendre toutes les fonctionnalités de l'atelier de gestion. Il fournit un environnement de démonstration complet avec des données réalistes.

## 🚀 Fonctionnalités

### Guide Automatique
- **Affichage automatique** : Le guide se lance automatiquement lors de la première utilisation
- **Une seule fois** : Le guide ne s'affiche qu'une seule fois par défaut
- **Persistance** : L'état du guide est sauvegardé dans le localStorage

### Données de Démonstration
Le guide ajoute automatiquement les éléments suivants :

#### 👤 Client de démonstration
- **Jean Dupont** - Client fidèle avec coordonnées complètes
- Email : jean.dupont@email.com
- Téléphone : 06 12 34 56 78
- Adresse : 123 Rue de la Paix, 75001 Paris

#### 📱 Appareils de démonstration
1. **iPhone 13 Pro** (Apple)
   - Numéro de série : IP13P001
   - Spécifications : 256GB, Sierra Blue, iOS 17

2. **MacBook Pro 14"** (Apple)
   - Numéro de série : MBP14001
   - Spécifications : M2 Pro, 16GB, 512GB SSD

3. **Samsung Galaxy S21** (Samsung)
   - Numéro de série : SGS21001
   - Spécifications : 128GB, Phantom Black, Android 14

#### 🔧 Services de réparation
1. **Remplacement écran** - 89€ (60 min)
2. **Remplacement batterie** - 49€ (45 min)
3. **Nettoyage logiciel** - 29€ (30 min)
4. **Récupération données** - 79€ (120 min)
5. **Diagnostic complet** - 19€ (20 min)

#### 📦 Pièces détachées (10 pièces)
- Écran iPhone 13 - 89€ (Stock: 5)
- Batterie iPhone - 29€ (Stock: 12)
- Écran MacBook Pro 14" - 299€ (Stock: 3)
- Clavier MacBook Pro - 89€ (Stock: 8)
- Câble USB-C - 9€ (Stock: 25)
- Coque iPhone Premium - 19€ (Stock: 15)
- Chargeur sans fil - 25€ (Stock: 10)
- Écouteurs Bluetooth - 35€ (Stock: 8)
- Support téléphone - 12€ (Stock: 20)
- Câble Lightning - 15€ (Stock: 30)

#### 🛍️ Produits en vente (5 produits)
1. **Coque iPhone Premium** - 29€ (Stock: 20)
2. **Chargeur sans fil** - 39€ (Stock: 15)
3. **Écouteurs Bluetooth** - 49€ (Stock: 12)
4. **Support téléphone** - 19€ (Stock: 25)
5. **Câble Lightning** - 15€ (Stock: 30)

#### 🔧 Réparations d'exemple (2 réparations)
1. **Remplacement écran iPhone 13 Pro**
   - Statut : En cours
   - Client : Jean Dupont
   - Prix : 178€ (service + pièce)

2. **Remplacement batterie MacBook Pro**
   - Statut : Terminée
   - Client : Jean Dupont
   - Prix : 78€ (service + pièce)

#### 💰 Vente de démonstration (1 vente)
- **Client** : Jean Dupont
- **Produits** : Coque iPhone Premium + Chargeur sans fil
- **Total** : 81.60€ (68€ + 13.60€ TVA)
- **Statut** : Terminée

## 🎮 Utilisation

### Premier lancement
1. L'application se charge
2. Le guide d'intégration s'affiche automatiquement
3. Suivez les étapes du guide pour découvrir les fonctionnalités
4. Cliquez sur "Terminer la configuration" pour ajouter les données de démonstration

### Relancer le guide
1. Cliquez sur le bouton **"Guide"** dans la barre latérale
2. Une confirmation s'affiche pour vous avertir que de nouvelles données seront ajoutées
3. Confirmez pour relancer le guide

### Notification d'intégration
- Une notification apparaît en haut à droite si le guide n'a pas été complété
- Cliquez sur "Commencer le guide" pour lancer le guide
- Cliquez sur "Plus tard" pour fermer la notification

## 🔧 Configuration

### Réinitialiser le guide
Pour réinitialiser le guide (utile pour les tests) :

```javascript
// Dans la console du navigateur
localStorage.removeItem('onboarding-completed');
// Puis rechargez la page
```

### Personnaliser les données
Les données de démonstration sont définies dans `src/services/demoDataService.ts`. Vous pouvez modifier :
- Les informations des clients
- Les types d'appareils
- Les services proposés
- Les pièces détachées
- Les produits en vente

## 📁 Structure des fichiers

```
src/
├── components/
│   ├── OnboardingGuide.tsx          # Guide interactif principal
│   ├── OnboardingNotification.tsx   # Notification d'intégration
│   └── GuideButton.tsx              # Bouton pour relancer le guide
├── services/
│   └── demoDataService.ts           # Service de données de démonstration
└── App.tsx                          # Intégration du système
```

## 🎨 Interface utilisateur

### Guide interactif
- **Stepper** : Navigation par étapes
- **Cartes** : Présentation des données
- **Barre de progression** : Indication du processus d'ajout
- **Boutons** : Navigation et actions

### Notification
- **Position** : Coin supérieur droit
- **Style** : Alert Material-UI avec icônes
- **Actions** : Commencer le guide ou fermer

### Bouton Guide
- **Emplacement** : Barre latérale, section du bas
- **Style** : Bouton outlined avec icône d'aide
- **Fonction** : Relancer le guide avec confirmation

## 🔒 Sécurité et données

### Persistance
- Le statut du guide est sauvegardé dans `localStorage`
- Clé : `onboarding-completed`
- Valeur : `"true"` si complété

### Données de démonstration
- Les données sont générées avec des IDs uniques (UUID)
- Les dates sont calculées dynamiquement
- Les relations entre entités sont maintenues
- Les données existantes ne sont pas supprimées

## 🚀 Déploiement

Le système de guide est entièrement intégré dans l'application et ne nécessite aucune configuration supplémentaire pour le déploiement.

### Variables d'environnement
Aucune variable d'environnement spécifique n'est requise.

### Dépendances
Le système utilise uniquement les dépendances existantes :
- Material-UI pour l'interface
- UUID pour la génération d'IDs
- React hooks pour la gestion d'état

## 🐛 Dépannage

### Le guide ne s'affiche pas
1. Vérifiez que `localStorage.getItem('onboarding-completed')` n'est pas `"true"`
2. Rechargez la page
3. Vérifiez la console pour les erreurs

### Erreur lors de l'ajout des données
1. Vérifiez que le store Zustand est correctement configuré
2. Vérifiez les types TypeScript
3. Consultez la console pour les erreurs détaillées

### Le bouton Guide ne fonctionne pas
1. Vérifiez que le composant `GuideButton` est importé
2. Vérifiez que le composant `OnboardingGuide` est disponible
3. Vérifiez les props passées au composant

## 📝 Notes de développement

### Ajout de nouvelles données
Pour ajouter de nouveaux types de données de démonstration :

1. Modifiez l'interface `DemoData` dans `demoDataService.ts`
2. Ajoutez les données dans la méthode `getDemoData()`
3. Mettez à jour le guide dans `OnboardingGuide.tsx`
4. Ajoutez les actions correspondantes dans le store

### Personnalisation du guide
Le guide est entièrement personnalisable :
- Modifiez les étapes dans le tableau `steps`
- Ajoutez de nouvelles étapes
- Personnalisez le contenu de chaque étape
- Modifiez les icônes et couleurs

### Tests
Pour tester le système :
1. Réinitialisez le guide : `localStorage.removeItem('onboarding-completed')`
2. Rechargez la page
3. Suivez le guide
4. Vérifiez que les données sont ajoutées
5. Testez le bouton de relance
