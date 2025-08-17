# Configuration Supabase pour l'Application de Gestion d'Atelier

## 🚀 Vue d'ensemble

Ce guide vous explique comment configurer Supabase pour votre application de gestion d'atelier de réparation d'appareils électroniques.

## 📋 Prérequis

- Un compte Supabase (gratuit)
- Les clés d'API Supabase (déjà configurées dans le projet)

## 🔧 Configuration

### 1. Accès au Dashboard Supabase

1. Allez sur [https://supabase.com/dashboard/project/wlqyrmntfxwdvkzzsujv/editor](https://supabase.com/dashboard/project/wlqyrmntfxwdvkzzsujv/editor)
2. Connectez-vous à votre compte Supabase

### 2. Création des Tables

1. Dans le dashboard Supabase, cliquez sur **"SQL Editor"** dans le menu de gauche
2. Cliquez sur **"New query"**
3. Copiez le contenu du fichier `database/schema.sql` et collez-le dans l'éditeur
4. Cliquez sur **"Run"** pour exécuter le script

### 3. Vérification des Tables

Après l'exécution du script, vous devriez voir les tables suivantes créées :

- ✅ `clients` - Gestion des clients
- ✅ `produits` - Catalogue des produits
- ✅ `services` - Services proposés
- ✅ `reparations` - Suivi des réparations
- ✅ `pieces` - Pièces détachées
- ✅ `commandes` - Commandes clients
- ✅ `commande_produits` - Détails des commandes
- ✅ `users` - Utilisateurs de l'application
- ✅ `rendez_vous` - Gestion des rendez-vous

## 🔐 Configuration de la Sécurité

### Row Level Security (RLS)

Le script SQL configure automatiquement :
- RLS activé sur toutes les tables
- Politiques d'accès permettant les opérations CRUD complètes
- Triggers pour mettre à jour automatiquement `updated_at`

### Variables d'Environnement

Les variables d'environnement sont déjà configurées dans `src/lib/supabase.ts` :

```typescript
const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

## 🧪 Test de la Connexion

### 1. Démarrage de l'Application

```bash
npm run dev
```

### 2. Accès au Test

1. Ouvrez votre navigateur sur `http://localhost:3000`
2. Allez sur la page Dashboard
3. Faites défiler jusqu'à la section "Test de Connexion Supabase"

### 3. Vérification

Le composant de test affichera :
- ✅ **Statut de connexion** : Succès ou erreur
- 📊 **Données des tables** : Clients, produits, services
- ➕ **Formulaires d'ajout** : Pour tester les opérations CRUD

## 📊 Structure des Données

### Table `clients`
```sql
- id (UUID, Primary Key)
- nom (VARCHAR)
- email (VARCHAR, Unique)
- telephone (VARCHAR)
- adresse (TEXT)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### Table `produits`
```sql
- id (UUID, Primary Key)
- nom (VARCHAR)
- description (TEXT)
- prix (DECIMAL)
- stock (INTEGER)
- categorie (VARCHAR)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### Table `reparations`
```sql
- id (UUID, Primary Key)
- client_id (UUID, Foreign Key)
- appareil (VARCHAR)
- probleme (TEXT)
- statut (ENUM: en_attente, en_cours, terminee, annulee)
- date_creation (TIMESTAMP)
- date_fin_estimee (TIMESTAMP)
- date_fin_reelle (TIMESTAMP)
- prix_estime (DECIMAL)
- prix_final (DECIMAL)
- notes (TEXT)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

## 🔄 Services et Hooks

### Services Supabase

Le projet inclut des services complets pour chaque table :

- `clientService` - Gestion des clients
- `produitService` - Gestion des produits
- `serviceService` - Gestion des services
- `reparationService` - Gestion des réparations
- `pieceService` - Gestion des pièces
- `commandeService` - Gestion des commandes

### Hooks React

Des hooks personnalisés sont disponibles :

- `useClients()` - État et opérations clients
- `useProduits()` - État et opérations produits
- `useServices()` - État et opérations services
- `useReparations()` - État et opérations réparations
- `usePieces()` - État et opérations pièces
- `useCommandes()` - État et opérations commandes

## 🚨 Dépannage

### Erreur "Table does not exist"

1. Vérifiez que le script SQL a été exécuté correctement
2. Allez dans **"Table Editor"** dans Supabase
3. Vérifiez que toutes les tables sont présentes

### Erreur de connexion

1. Vérifiez les clés d'API dans `src/lib/supabase.ts`
2. Assurez-vous que l'URL Supabase est correcte
3. Vérifiez que le projet Supabase est actif

### Erreur RLS

1. Allez dans **"Authentication" > "Policies"**
2. Vérifiez que les politiques RLS sont configurées
3. Si nécessaire, exécutez à nouveau la partie RLS du script SQL

## 📈 Prochaines Étapes

1. **Authentification** : Configurer l'authentification Supabase
2. **Stockage** : Configurer le stockage de fichiers pour les images
3. **Notifications** : Configurer les notifications en temps réel
4. **Backup** : Configurer les sauvegardes automatiques

## 🔗 Liens Utiles

- [Documentation Supabase](https://supabase.com/docs)
- [Dashboard du Projet](https://supabase.com/dashboard/project/wlqyrmntfxwdvkzzsujv)
- [API Reference](https://supabase.com/docs/reference/javascript)

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez les logs dans la console du navigateur
2. Consultez les logs Supabase dans le dashboard
3. Vérifiez la documentation Supabase
4. Contactez l'équipe de développement

---

**Note** : Ce projet utilise Supabase comme backend-as-a-service pour simplifier le développement et le déploiement. Toutes les données sont stockées de manière sécurisée dans la base de données PostgreSQL de Supabase.
