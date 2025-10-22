# Guide de la Page de Gestion des Accès Utilisateurs

## Vue d'ensemble

La page de gestion des accès utilisateurs est une interface d'administration sécurisée qui permet aux administrateurs de gérer manuellement l'accès des utilisateurs à l'atelier de gestion.

## Accès à la page

### URL
```
/app/administration/user-access
```

### Sécurité
- **Accès restreint** : Seuls les utilisateurs avec le rôle 'admin' peuvent accéder
- **Protection automatique** : Si un utilisateur non-admin tente d'accéder, il voit une page d'accès refusé
- **Redirection** : Les utilisateurs non connectés sont redirigés vers la page d'authentification

## Fonctionnalités principales

### 1. Tableau de bord avec statistiques
- **Total utilisateurs** : Nombre total d'utilisateurs enregistrés
- **Accès actifs** : Nombre d'utilisateurs avec accès activé
- **Accès verrouillés** : Nombre d'utilisateurs avec accès désactivé
- **En attente** : Nombre d'utilisateurs jamais activés

### 2. Recherche et filtres
- **Recherche textuelle** : Par nom, prénom ou email
- **Filtre par statut** : Tous, Actifs, Verrouillés
- **Filtres avancés** : Options supplémentaires avec switches

### 3. Liste des utilisateurs
Chaque utilisateur affiche :
- **Avatar et nom** : Avec ID utilisateur tronqué
- **Email** : Adresse email complète
- **Statut** : Chip coloré (Vert = Actif, Rouge = Verrouillé)
- **Type d'abonnement** : Free, Premium, Enterprise
- **Date de création** : Quand le compte a été créé
- **Dernière action** : Date d'activation et notes
- **Actions** : Boutons pour gérer l'utilisateur

## Actions disponibles

### Activer un accès
1. Cliquer sur le bouton vert ✓ (CheckIcon)
2. Remplir les notes (optionnel)
3. Confirmer l'action
4. L'utilisateur peut maintenant accéder à l'application

### Désactiver un accès
1. Cliquer sur le bouton rouge ✗ (CancelIcon)
2. Remplir les notes (optionnel)
3. Confirmer l'action
4. L'utilisateur est redirigé vers la page de blocage

### Modifier un utilisateur
1. Cliquer sur le bouton bleu ✏️ (EditIcon)
2. Changer le type d'abonnement si nécessaire
3. Ajouter/modifier les notes
4. Confirmer les modifications

### Voir les détails
1. Cliquer sur le bouton info 👁️ (VisibilityIcon)
2. Consulter les informations complètes
3. Voir les notes existantes
4. Fermer sans modification

## Interface utilisateur

### Couleurs et icônes
- **Vert** : Accès actif, actions d'activation
- **Rouge** : Accès verrouillé, actions de désactivation
- **Bleu** : Actions de modification
- **Orange** : Type Premium
- **Rouge foncé** : Type Enterprise

### Responsive design
- **Desktop** : Affichage complet avec toutes les colonnes
- **Tablet** : Adaptation automatique des colonnes
- **Mobile** : Interface optimisée pour petits écrans

## Workflow typique

### 1. Nouvel utilisateur s'inscrit
- L'utilisateur crée son compte
- Son accès est automatiquement verrouillé
- Il voit la page de blocage

### 2. Administrateur vérifie
- Se connecte à la page de gestion
- Voir le nouvel utilisateur dans la liste
- Statut : "Accès Verrouillé"

### 3. Administrateur active l'accès
- Clique sur le bouton d'activation
- Ajoute des notes si nécessaire
- Confirme l'action

### 4. Utilisateur accède à l'application
- L'utilisateur peut maintenant se connecter
- Accès complet à toutes les fonctionnalités
- Statut mis à jour : "Accès Actif"

## Gestion des erreurs

### Erreurs courantes
- **Accès refusé** : Utilisateur non-admin
- **Erreur de chargement** : Problème de connexion à la base de données
- **Erreur d'action** : Problème lors de l'activation/désactivation

### Solutions
- Vérifier les permissions utilisateur
- Actualiser la page
- Vérifier la connexion internet
- Contacter l'équipe technique si persistant

## Bonnes pratiques

### Sécurité
- Ne partagez jamais vos identifiants administrateur
- Déconnectez-vous après utilisation
- Vérifiez l'identité des utilisateurs avant activation

### Gestion
- Ajoutez toujours des notes pour tracer les actions
- Vérifiez régulièrement la liste des utilisateurs
- Désactivez les comptes inactifs

### Communication
- Informez les utilisateurs de l'activation de leur compte
- Expliquez les raisons en cas de désactivation
- Maintenez une documentation des actions

## Personnalisation

### Modification des couleurs
Les couleurs sont définies dans le thème Material-UI et peuvent être modifiées dans `src/theme/index.ts`.

### Ajout de nouveaux types d'abonnement
1. Modifier le type `SubscriptionStatus` dans `src/types/index.ts`
2. Mettre à jour la base de données
3. Ajouter les nouvelles options dans l'interface

### Modification des messages
Tous les textes sont dans le composant `UserAccessManagement.tsx` et peuvent être personnalisés.

## Support technique

### Logs
- Vérifiez la console du navigateur pour les erreurs
- Consultez les logs Supabase pour les actions de base de données

### Débogage
- Utilisez les outils de développement du navigateur
- Vérifiez les requêtes réseau
- Testez avec différents comptes utilisateur

### Contact
Pour toute question technique, contactez l'équipe de développement avec :
- Description du problème
- Étapes pour reproduire
- Captures d'écran si nécessaire
- Informations sur l'environnement (navigateur, OS)
