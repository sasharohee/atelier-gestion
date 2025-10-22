# Guide des Données de Démonstration

## Vue d'ensemble

L'application Atelier dispose d'un système de données de démonstration automatique qui s'assure que toutes les pages ont des données fonctionnelles dès le premier lancement.

## Fonctionnement

### Chargement automatique

1. **Au démarrage de l'application** : Le système vérifie automatiquement si des données existent dans la base de données
2. **Si aucune donnée** : Les données de démonstration sont automatiquement chargées
3. **Si des données existent** : Aucun chargement n'est effectué pour préserver les données existantes

### Données incluses

Le système de démonstration inclut :

#### 👥 Clients (5 clients)
- Jean Dupont - Client fidèle
- Marie Martin - Cliente régulière
- Pierre Durand - Technicien informatique
- Sophie Leroy - Étudiante
- Lucas Moreau - Entrepreneur

#### 📱 Appareils (3 appareils)
- iPhone 13 Pro (Apple)
- MacBook Pro 14" (Apple)
- Galaxy S21 (Samsung)

#### 🔧 Services (10 services)
- Remplacement écran
- Remplacement batterie
- Nettoyage logiciel
- Récupération données
- Diagnostic complet
- Remplacement connecteur de charge
- Remplacement haut-parleur
- Remplacement caméra
- Déverrouillage iCloud
- Installation logiciel

#### 🔩 Pièces détachées (11 pièces)
- Écrans (iPhone, MacBook)
- Batteries
- Claviers
- Câbles (USB-C, Lightning)
- Accessoires (coques, chargeurs, etc.)

#### 🛍️ Produits (5 produits)
- Coque iPhone Premium
- Chargeur sans fil
- Écouteurs Bluetooth
- Support téléphone
- Câble Lightning

#### 🔨 Réparations (4 réparations)
- Réparation en cours (iPhone)
- Réparation terminée (MacBook)
- Réparation en attente de pièces (Samsung)
- Nouvelle réparation (iPhone)

#### 💰 Ventes (3 ventes)
- Vente complète avec plusieurs articles
- Vente simple d'écouteurs
- Vente avec support et câble

#### 📅 Rendez-vous (3 rendez-vous)
- Réparation iPhone
- Diagnostic MacBook
- Récupération données

#### 💬 Messages (3 messages)
- Question client
- Confirmation rendez-vous
- Notification réparation terminée

## Pages avec données fonctionnelles

Toutes les pages suivantes ont maintenant des données de démonstration :

### ✅ Dashboard
- Statistiques complètes
- Réparations récentes
- Rendez-vous du jour
- Alertes et notifications

### ✅ Catalogue
- **Clients** : 5 clients avec informations complètes
- **Appareils** : 3 appareils avec spécifications
- **Services** : 10 services de réparation
- **Pièces détachées** : 11 pièces avec stock
- **Produits** : 5 produits en vente
- **Ruptures de stock** : Alertes automatiques

### ✅ Kanban
- Réparations réparties par statut
- Drag & drop fonctionnel
- Informations détaillées sur chaque carte

### ✅ Ventes
- Historique des ventes
- Statistiques (jour/mois)
- Détails des transactions

### ✅ Calendrier
- Rendez-vous programmés
- Gestion des créneaux

### ✅ Messagerie
- Messages échangés
- Statut de lecture

## Comment tester

### 1. Vérification automatique
Le composant `AppStatus` sur le Dashboard affiche l'état de toutes les données :
- ✅ Vert : Données présentes
- ⚠️ Orange : Page vide (normal pour certaines sections)
- ❌ Rouge : Données manquantes

### 2. Bouton de test
Sur le Dashboard, un bouton "Charger les données de démonstration" permet de forcer le rechargement.

### 3. Console de test
Exécutez dans la console du navigateur :
```javascript
// Test automatique
import('./src/services/demoDataService.ts').then(({ demoDataService }) => {
  demoDataService.ensureDemoData();
});

// Ou utilisez la fonction globale
window.reloadDemoData();
```

## Personnalisation

### Ajouter de nouvelles données
Pour ajouter de nouvelles données de démonstration :

1. Modifiez `src/services/demoDataService.ts`
2. Ajoutez vos données dans la méthode `getDemoData()`
3. Mettez à jour la méthode `addDemoDataToSupabase()`

### Réinitialiser les données
Pour réinitialiser complètement les données :

```javascript
// Dans la console
localStorage.clear();
window.location.reload();
```

## Dépannage

### Problème : Pas de données affichées
1. Vérifiez la connexion Supabase
2. Cliquez sur "Charger les données de démonstration"
3. Vérifiez les logs dans la console

### Problème : Erreur de chargement
1. Vérifiez que Supabase est configuré
2. Vérifiez les permissions de la base de données
3. Consultez les logs d'erreur

### Problème : Données dupliquées
Les données ne sont chargées qu'une seule fois. Si vous voyez des doublons, c'est normal car le système vérifie l'existence avant de charger.

## Avantages

✅ **Expérience utilisateur immédiate** : Pas d'atelier vide
✅ **Démonstration complète** : Toutes les fonctionnalités visibles
✅ **Données réalistes** : Exemples concrets d'utilisation
✅ **Performance** : Chargement automatique et intelligent
✅ **Sécurité** : Pas d'écrasement des données existantes

## Support

Pour toute question sur les données de démonstration, consultez :
- Le composant `AppStatus` sur le Dashboard
- Les logs dans la console du navigateur
- Le fichier `src/services/demoDataService.ts`
