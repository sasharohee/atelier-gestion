# Configuration de la Base de Données Supabase

## Problème Actuel

L'application fonctionne correctement mais affiche un message d'erreur indiquant que les tables de la base de données Supabase n'existent pas encore.

## Solution

### Étape 1 : Accéder au Dashboard Supabase

1. Allez sur [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Connectez-vous à votre compte
3. Sélectionnez votre projet "gggoqnxrspviuxadvkbh"

### Étape 2 : Exécuter le Script SQL

1. Dans le dashboard Supabase, cliquez sur **"SQL Editor"** dans le menu de gauche
2. Cliquez sur **"New query"** pour créer une nouvelle requête
3. Copiez tout le contenu du fichier `database_setup.sql` dans ce projet
4. Collez-le dans l'éditeur SQL
5. Cliquez sur **"Run"** pour exécuter le script

### Étape 3 : Vérifier l'Installation

1. Retournez sur votre application (localhost:3002)
2. Le message d'erreur devrait disparaître
3. Vous devriez voir "✅ Connexion Supabase réussie !"

## Contenu du Script

Le script `database_setup.sql` crée :

- **Tables principales :**
  - `users` - Utilisateurs de l'application
  - `clients` - Clients de l'atelier
  - `devices` - Appareils à réparer
  - `repairs` - Réparations
  - `parts` - Pièces détachées
  - `products` - Produits en vente
  - `sales` - Ventes
  - `appointments` - Rendez-vous

- **Sécurité :**
  - Row Level Security (RLS) activé
  - Politiques d'accès pour utilisateurs authentifiés

- **Données de test :**
  - 3 clients exemple
  - 3 appareils exemple
  - 3 pièces détachées exemple

## Alternative : Téléchargement via l'Interface

Vous pouvez aussi :
1. Cliquer sur le bouton **"Télécharger le script SQL"** dans l'application
2. Suivre les instructions affichées à l'écran

## Vérification

Après l'exécution du script, toutes les fonctionnalités de l'application devraient fonctionner :
- Gestion des clients
- Gestion des réparations
- Gestion du stock
- Calendrier des rendez-vous
- Statistiques

## Support

Si vous rencontrez des problèmes :
1. Vérifiez que vous êtes bien connecté au bon projet Supabase
2. Assurez-vous que les clés API dans `src/lib/supabase.ts` sont correctes
3. Vérifiez les logs dans la console du navigateur
