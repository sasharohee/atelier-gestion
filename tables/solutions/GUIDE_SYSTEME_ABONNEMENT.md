# Guide du Système d'Abonnement avec Gestion Manuelle

## Vue d'ensemble

Ce système permet de gérer manuellement l'accès des utilisateurs à l'atelier de gestion. Par défaut, tous les nouveaux utilisateurs ont leur accès verrouillé et doivent être activés manuellement par un administrateur.

## Fonctionnalités

### 1. Verrouillage automatique des nouveaux comptes
- Lorsqu'un utilisateur crée un compte, son accès est automatiquement verrouillé
- Un statut d'abonnement est créé avec `is_active = false`
- L'utilisateur voit la page de blocage au lieu de l'application

### 2. Page de blocage personnalisée
- Message informatif expliquant que l'accès nécessite une activation
- Instructions pour contacter l'administrateur
- Informations sur les tarifs et fonctionnalités
- Boutons pour contacter le support et vérifier le statut

### 3. Gestion manuelle par l'administrateur
- Interface d'administration dédiée
- Activation/désactivation des accès
- Modification des types d'abonnement
- Ajout de notes pour tracer les actions

## Installation et Configuration

### 1. Création de la table de base de données

Exécutez le script SQL `tables/creation_table_subscription_status.sql` dans votre base de données Supabase :

```sql
-- Le script crée :
-- - Table subscription_status
-- - Index pour les performances
-- - Contraintes et triggers
-- - Politiques RLS pour la sécurité
```

### 2. Vérification des composants

Assurez-vous que les fichiers suivants sont présents :
- `src/hooks/useSubscription.ts` - Hook pour vérifier le statut
- `src/services/supabaseService.ts` - Service pour gérer les abonnements
- `src/components/AuthGuard.tsx` - Garde d'authentification modifiée
- `src/pages/Auth/SubscriptionBlocked.tsx` - Page de blocage
- `src/pages/Administration/SubscriptionManagement.tsx` - Interface d'administration

## Utilisation

### Pour les utilisateurs

1. **Création de compte** : L'utilisateur crée son compte normalement
2. **Page de blocage** : Il est automatiquement redirigé vers la page de blocage
3. **Contact** : Il peut contacter l'administrateur via l'email fourni
4. **Activation** : Une fois activé, il accède normalement à l'application

### Pour les administrateurs

1. **Accès à la gestion** : Aller dans Administration > Gestion des Accès
2. **Voir les utilisateurs** : Liste de tous les utilisateurs avec leur statut
3. **Activer un accès** : Cliquer sur le bouton vert ✓
4. **Désactiver un accès** : Cliquer sur le bouton rouge ✗
5. **Ajouter des notes** : Expliquer la raison de l'action

## Structure de la base de données

### Table `subscription_status`

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Identifiant unique |
| `user_id` | UUID | Référence vers auth.users |
| `first_name` | TEXT | Prénom de l'utilisateur |
| `last_name` | TEXT | Nom de l'utilisateur |
| `email` | TEXT | Email de l'utilisateur |
| `is_active` | BOOLEAN | Statut d'activation (TRUE = actif) |
| `subscription_type` | TEXT | Type d'abonnement (free/premium/enterprise) |
| `created_at` | TIMESTAMP | Date de création |
| `updated_at` | TIMESTAMP | Date de dernière modification |
| `activated_at` | TIMESTAMP | Date d'activation (NULL si non activé) |
| `activated_by` | UUID | ID de l'administrateur qui a activé |
| `notes` | TEXT | Notes sur l'activation/désactivation |

## Sécurité

### Politiques RLS (Row Level Security)

- **Utilisateurs** : Peuvent voir et créer leur propre statut
- **Administrateurs** : Peuvent voir, modifier et supprimer tous les statuts
- **Isolation** : Chaque utilisateur ne voit que ses propres données

### Contrôles d'accès

- Seuls les administrateurs peuvent activer/désactiver les accès
- Vérification du rôle utilisateur avant toute action
- Logs des actions avec notes et timestamps

## Personnalisation

### Modification de l'email de contact

Dans `src/pages/Auth/SubscriptionBlocked.tsx`, modifiez :

```typescript
const handleContactSupport = () => {
  window.open('mailto:VOTRE_EMAIL@exemple.com?subject=Activation de mon abonnement', '_blank');
};
```

### Modification des tarifs

Dans la page de blocage, modifiez les prix et fonctionnalités affichés.

### Ajout de nouveaux types d'abonnement

1. Modifiez le type `SubscriptionStatus` dans `src/types/index.ts`
2. Mettez à jour la contrainte CHECK dans la base de données
3. Ajoutez les nouveaux types dans l'interface d'administration

## Dépannage

### Problème : Utilisateur ne peut pas accéder après activation

1. Vérifiez que `is_active = true` dans la base de données
2. Vérifiez que l'utilisateur a bien le rôle approprié
3. Videz le cache du navigateur

### Problème : Erreur lors de la création du statut

1. Vérifiez que la table `subscription_status` existe
2. Vérifiez les politiques RLS
3. Vérifiez que l'utilisateur est bien authentifié

### Problème : Administrateur ne peut pas gérer les accès

1. Vérifiez que l'utilisateur a le rôle 'admin'
2. Vérifiez les politiques RLS pour les administrateurs
3. Vérifiez les permissions dans Supabase

## Maintenance

### Sauvegarde

La table `subscription_status` contient des données critiques. Effectuez des sauvegardes régulières.

### Nettoyage

- Supprimez les statuts des utilisateurs supprimés (cascade automatique)
- Archivez les anciennes notes si nécessaire
- Surveillez la taille de la table

### Monitoring

- Surveillez les tentatives d'accès non autorisées
- Vérifiez les logs d'activation/désactivation
- Contrôlez les modifications de statut

## Support

Pour toute question ou problème :
1. Consultez les logs de l'application
2. Vérifiez les politiques RLS dans Supabase
3. Testez avec un compte administrateur
4. Contactez l'équipe de développement
