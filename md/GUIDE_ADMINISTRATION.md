# Guide d'utilisation de la page Administration

## Vue d'ensemble

La page d'administration est maintenant entièrement fonctionnelle et permet de gérer les utilisateurs et les paramètres système de l'atelier de réparation.

## Fonctionnalités principales

### 1. Gestion des utilisateurs

#### Statistiques en temps réel
- **Total utilisateurs** : Nombre total d'utilisateurs dans le système
- **Administrateurs** : Nombre d'utilisateurs avec le rôle administrateur
- **Techniciens** : Nombre d'utilisateurs avec le rôle technicien
- **Gérants** : Nombre d'utilisateurs avec le rôle gérant

#### Actions disponibles
- **Nouvel utilisateur** : Créer un nouvel utilisateur
- **Actualiser** : Recharger la liste des utilisateurs
- **Modifier** : Modifier les informations d'un utilisateur existant
- **Supprimer** : Supprimer un utilisateur (impossible de se supprimer soi-même)

#### Rôles utilisateur
- **Administrateur** : Accès complet à toutes les fonctionnalités
- **Gérant** : Accès aux fonctionnalités de gestion
- **Technicien** : Accès limité aux fonctionnalités techniques

### 2. Paramètres système

#### Paramètres généraux
- **Nom de l'atelier** : Nom affiché dans l'application
- **Adresse** : Adresse de l'atelier
- **Téléphone** : Numéro de téléphone de contact
- **Email** : Adresse email de contact

#### Paramètres de facturation
- **TVA (%)** : Taux de TVA appliqué
- **Devise** : Devise utilisée (EUR, USD, etc.)
- **Préfixe facture** : Préfixe pour les numéros de facture
- **Format de date** : Format d'affichage des dates

#### Paramètres système
- **Sauvegarde automatique** : Activer/désactiver la sauvegarde automatique
- **Notifications** : Activer/désactiver les notifications

## Utilisation

### Créer un nouvel utilisateur

1. Cliquer sur le bouton **"Nouvel utilisateur"**
2. Remplir le formulaire :
   - **Prénom** : Prénom de l'utilisateur (obligatoire)
   - **Nom** : Nom de l'utilisateur (obligatoire)
   - **Email** : Adresse email valide (obligatoire)
   - **Mot de passe** : Mot de passe d'au moins 6 caractères (obligatoire)
   - **Rôle** : Sélectionner le rôle approprié
3. Cliquer sur **"Créer"**

### Modifier un utilisateur

1. Cliquer sur l'icône **"Modifier"** (crayon) à côté de l'utilisateur
2. Modifier les champs souhaités
3. Cliquer sur **"Modifier"**

### Supprimer un utilisateur

1. Cliquer sur l'icône **"Supprimer"** (poubelle) à côté de l'utilisateur
2. Confirmer la suppression dans la boîte de dialogue
3. Cliquer sur **"Supprimer"**

### Sauvegarder les paramètres

1. Modifier les paramètres dans les différentes sections
2. Cliquer sur **"Sauvegarder"** dans chaque section
3. Une notification confirme la sauvegarde

## Validation des formulaires

### Validation des utilisateurs
- **Prénom et nom** : Champs obligatoires
- **Email** : Format email valide requis
- **Mot de passe** : Minimum 6 caractères pour les nouveaux utilisateurs
- **Rôle** : Doit être sélectionné

### Messages d'erreur
- Les erreurs de validation s'affichent sous les champs concernés
- Les erreurs de base de données s'affichent en haut de la page
- Les notifications de succès s'affichent en bas à droite

## Sécurité

### Contrôles d'accès
- Seuls les administrateurs peuvent créer, modifier et supprimer des utilisateurs
- Un utilisateur ne peut pas se supprimer lui-même
- Les utilisateurs peuvent voir et modifier leur propre profil

### Politiques de sécurité
- Les mots de passe sont stockés de manière sécurisée via Supabase Auth
- Les rôles sont vérifiés côté serveur
- Les politiques RLS (Row Level Security) protègent les données

## Configuration de la base de données

### Table users
La table `users` doit être créée dans Supabase avec les colonnes suivantes :
- `id` : UUID (référence vers auth.users)
- `first_name` : TEXT (prénom)
- `last_name` : TEXT (nom)
- `email` : TEXT (email unique)
- `role` : TEXT (admin, manager, technician)
- `avatar` : TEXT (URL de l'avatar, optionnel)
- `created_at` : TIMESTAMP
- `updated_at` : TIMESTAMP

### Script SQL
Exécuter le script `create_users_table.sql` dans l'éditeur SQL de Supabase pour créer la table et les politiques de sécurité.

## Dépannage

### Problèmes courants

#### Erreur "Permission denied"
- Vérifier que l'utilisateur connecté a le rôle administrateur
- Vérifier que les politiques RLS sont correctement configurées

#### Erreur "User not found"
- Vérifier que l'utilisateur existe dans la table `users`
- Vérifier que l'ID correspond à un utilisateur dans `auth.users`

#### Erreur de validation
- Vérifier que tous les champs obligatoires sont remplis
- Vérifier le format de l'email
- Vérifier la longueur du mot de passe

### Logs et débogage
- Les erreurs sont affichées dans la console du navigateur
- Les erreurs de base de données sont loggées dans Supabase
- Utiliser les outils de développement pour inspecter les requêtes

## Maintenance

### Sauvegarde
- Les paramètres système peuvent être sauvegardés manuellement
- La sauvegarde automatique peut être activée dans les paramètres

### Mise à jour
- Les utilisateurs peuvent être mis à jour individuellement
- Les rôles peuvent être modifiés selon les besoins
- Les paramètres système peuvent être ajustés

## Support

Pour toute question ou problème :
1. Vérifier ce guide
2. Consulter les logs d'erreur
3. Contacter l'administrateur système
4. Consulter la documentation Supabase
