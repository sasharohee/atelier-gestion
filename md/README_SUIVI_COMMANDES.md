# Suivi des Commandes - Documentation

## Vue d'ensemble

La page de suivi des commandes permet aux réparateurs de gérer et suivre leurs commandes passées auprès des fournisseurs. Cette fonctionnalité offre une interface complète pour la gestion du cycle de vie des commandes, de la création à la livraison.

## Fonctionnalités principales

### 1. Tableau de bord des commandes
- **Vue d'ensemble** : Affichage de toutes les commandes avec leurs statuts
- **Statistiques** : Compteurs par statut et montant total des commandes
- **Recherche et filtres** : Recherche par numéro de commande, fournisseur ou numéro de suivi
- **Filtrage par statut** : Filtrage rapide par statut de commande

### 2. Gestion des commandes
- **Création** : Création de nouvelles commandes avec informations complètes
- **Modification** : Mise à jour des informations de commande existante
- **Suppression** : Suppression de commandes avec confirmation
- **Visualisation** : Affichage détaillé des informations de commande

### 3. Gestion des articles
- **Ajout d'articles** : Ajout de produits à une commande
- **Modification** : Modification des quantités, prix et descriptions
- **Suppression** : Suppression d'articles individuels
- **Calcul automatique** : Calcul automatique des totaux par article et de la commande

### 4. Statuts de commande
- **En attente** : Commande créée, en attente de confirmation
- **Confirmée** : Commande confirmée par le fournisseur
- **Expédiée** : Commande expédiée avec numéro de suivi
- **Livrée** : Commande reçue et livrée
- **Annulée** : Commande annulée

## Structure des fichiers

```
src/pages/Transaction/OrderTracking/
├── OrderTracking.tsx          # Composant principal
├── OrderItemDialog.tsx        # Dialog de gestion des articles
├── OrderStats.tsx            # Composant des statistiques
└── index.ts                  # Export du composant principal

src/types/
└── order.ts                  # Types TypeScript pour les commandes

src/services/
└── orderService.ts           # Service de gestion des commandes
```

## Types de données

### Order
```typescript
interface Order {
  id: string;
  orderNumber: string;
  supplierName: string;
  supplierEmail: string;
  supplierPhone: string;
  orderDate: string;
  expectedDeliveryDate: string;
  status: 'pending' | 'confirmed' | 'shipped' | 'delivered' | 'cancelled';
  totalAmount: number;
  items: OrderItem[];
  notes: string;
  trackingNumber?: string;
  actualDeliveryDate?: string;
}
```

### OrderItem
```typescript
interface OrderItem {
  id: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  description: string;
}
```

## Utilisation

### Accès à la page
1. Naviguer vers la section "Transaction" dans le menu principal
2. Cliquer sur "Suivi Commandes"

### Créer une nouvelle commande
1. Cliquer sur le bouton "Nouvelle Commande"
2. Remplir les informations du fournisseur
3. Ajouter les articles nécessaires
4. Sauvegarder la commande

### Gérer les articles d'une commande
1. Cliquer sur l'icône "Gérer les articles" dans la liste
2. Ajouter, modifier ou supprimer des articles
3. Les totaux se calculent automatiquement

### Suivre le statut d'une commande
1. Utiliser les filtres pour voir les commandes par statut
2. Mettre à jour le statut via le formulaire de modification
3. Ajouter un numéro de suivi pour les commandes expédiées

## Service de données

Le `orderService` fournit les méthodes suivantes :

- `getAllOrders()` : Récupérer toutes les commandes
- `getOrderById(id)` : Récupérer une commande par ID
- `createOrder(order)` : Créer une nouvelle commande
- `updateOrder(id, updates)` : Mettre à jour une commande
- `deleteOrder(id)` : Supprimer une commande
- `updateOrderItems(orderId, items)` : Mettre à jour les articles
- `searchOrders(query, status)` : Rechercher des commandes
- `getOrderStats()` : Obtenir les statistiques

## Interface utilisateur

### Composants Material-UI utilisés
- **Table** : Affichage des commandes
- **Dialog** : Formulaires de création/modification
- **Card** : Statistiques et informations
- **Chip** : Affichage des statuts
- **TextField** : Saisie des données
- **Select** : Sélection des statuts
- **Button** : Actions utilisateur

### Responsive Design
- Interface adaptée aux écrans mobiles et desktop
- Grille responsive pour les statistiques
- Tableaux avec défilement horizontal sur mobile

## Données de démonstration

La fonctionnalité inclut des données de démonstration pour tester :
- 3 commandes avec différents statuts
- Articles variés (écrans, claviers, composants)
- Fournisseurs fictifs avec coordonnées

## Évolutions futures

### Fonctionnalités prévues
- **Notifications** : Alertes pour les retards de livraison
- **Export** : Export des commandes en PDF/Excel
- **Historique** : Historique des modifications
- **Intégration API** : Connexion à des APIs de fournisseurs
- **Suivi en temps réel** : Mise à jour automatique des statuts

### Améliorations techniques
- **Persistance** : Sauvegarde en base de données
- **Authentification** : Gestion des permissions utilisateur
- **Validation** : Validation avancée des formulaires
- **Tests** : Tests unitaires et d'intégration

## Support

Pour toute question ou problème concernant cette fonctionnalité, consulter :
- La documentation technique du code
- Les logs de la console pour les erreurs
- Le service de support de l'application

