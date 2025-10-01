# 🔐 Guide d'Installation du Nouveau Système d'Authentification

## Vue d'ensemble

J'ai complètement recréé le système d'authentification pour résoudre les problèmes avec Supabase Auth. Le nouveau système est plus simple, plus robuste et plus maintenable.

## 🚀 Installation

### 1. Configuration de la Base de Données

Exécutez le script SQL dans votre console Supabase :

```bash
# Dans la console SQL de Supabase, exécutez :
CREATE_AUTH_SYSTEM_CLEAN.sql
```

Ce script va :
- Nettoyer les anciennes fonctions problématiques
- Créer la table `users` avec la bonne structure
- Configurer les politiques RLS (Row Level Security)
- Créer les triggers automatiques
- Créer les fonctions utilitaires

### 2. Configuration des Variables d'Environnement

Créez un fichier `.env` à la racine du projet :

```env
# Configuration Supabase
VITE_SUPABASE_URL=https://olrihggkxyksuofkesnk.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

### 3. Installation des Dépendances

```bash
npm install
```

### 4. Démarrage de l'Application

```bash
npm run dev
```

## 🏗️ Architecture du Nouveau Système

### Fichiers Créés/Modifiés

1. **`src/lib/supabase.ts`** - Configuration Supabase simplifiée
2. **`src/services/authService.ts`** - Service d'authentification principal
3. **`src/services/userService.ts`** - Service de gestion des utilisateurs
4. **`src/hooks/useAuth.ts`** - Hook React pour l'authentification
5. **`src/components/AuthGuard.tsx`** - Composant de protection des routes
6. **`src/pages/Auth/Auth.tsx`** - Page de connexion/inscription
7. **`src/pages/Auth/EmailConfirmation.tsx`** - Page de confirmation d'email
8. **`src/pages/Auth/ResetPassword.tsx`** - Page de réinitialisation de mot de passe

### Fonctionnalités

✅ **Inscription** avec validation d'email
✅ **Connexion** avec gestion d'erreurs
✅ **Déconnexion** sécurisée
✅ **Réinitialisation de mot de passe**
✅ **Confirmation d'email**
✅ **Gestion des rôles** (admin, technician)
✅ **Protection des routes**
✅ **Synchronisation automatique** entre auth.users et public.users

## 🧪 Tests

### Test 1 : Inscription d'un Nouvel Utilisateur

1. Allez sur `/auth`
2. Cliquez sur l'onglet "Inscription"
3. Remplissez le formulaire :
   - Prénom : Test
   - Nom : User
   - Email : test@example.com
   - Mot de passe : TestPass123!
4. Cliquez sur "S'inscrire"
5. Vérifiez que vous recevez un message de succès

### Test 2 : Connexion

1. Allez sur `/auth`
2. Cliquez sur l'onglet "Connexion"
3. Entrez vos identifiants
4. Cliquez sur "Se connecter"
5. Vérifiez que vous êtes redirigé vers le dashboard

### Test 3 : Protection des Routes

1. Essayez d'accéder à `/app/dashboard` sans être connecté
2. Vérifiez que vous êtes redirigé vers `/auth`
3. Connectez-vous
4. Vérifiez que vous pouvez accéder au dashboard

## 🔧 Configuration Supabase

### Paramètres d'Authentification

Dans la console Supabase, allez dans **Authentication > Settings** :

1. **Site URL** : `http://localhost:5173` (pour le développement)
2. **Redirect URLs** : 
   - `http://localhost:5173/auth/confirm`
   - `http://localhost:5173/auth/reset-password`
3. **Email Confirmation** : Activé
4. **Password Reset** : Activé

### Configuration SMTP (Optionnel)

Pour envoyer de vrais emails :
1. Allez dans **Authentication > Settings > SMTP Settings**
2. Configurez votre service SMTP (Gmail, SendGrid, etc.)

## 🐛 Dépannage

### Problème : "Email already exists"

**Cause** : L'utilisateur existe déjà dans Supabase Auth
**Solution** : Utilisez l'onglet "Connexion" au lieu de "Inscription"

### Problème : "Invalid login credentials"

**Cause** : Email ou mot de passe incorrect
**Solution** : Vérifiez vos identifiants ou réinitialisez votre mot de passe

### Problème : "Email not confirmed"

**Cause** : L'email n'a pas été confirmé
**Solution** : Vérifiez votre boîte email et cliquez sur le lien de confirmation

### Problème : Erreur 500 lors de l'inscription

**Cause** : Problème avec les fonctions SQL
**Solution** : Réexécutez le script `CREATE_AUTH_SYSTEM_CLEAN.sql`

## 📝 Logs de Débogage

Le système inclut des logs détaillés. Ouvrez la console du navigateur pour voir :

- 🔐 Tentatives d'authentification
- ✅ Succès des opérations
- ❌ Erreurs détaillées
- 🔄 État des changements d'authentification

## 🔄 Migration depuis l'Ancien Système

Si vous avez des utilisateurs existants :

1. Le trigger `on_auth_user_created` créera automatiquement les profils manquants
2. Les utilisateurs existants pourront se connecter normalement
3. Les données seront synchronisées automatiquement

## 📞 Support

En cas de problème :

1. Vérifiez les logs de la console
2. Vérifiez les logs Supabase dans la console
3. Exécutez les requêtes de diagnostic dans le script SQL
4. Contactez le support si nécessaire

## ✅ Vérification Finale

Pour vérifier que tout fonctionne :

```sql
-- Dans la console SQL Supabase
SELECT 'VÉRIFICATION FINALE: Système d''authentification' as info;
SELECT 
    'Table users' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') 
         THEN '✅ Créée' 
         ELSE '❌ Manquante' 
    END as status
UNION ALL
SELECT 
    'Trigger on_auth_user_created' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') 
         THEN '✅ Actif' 
         ELSE '❌ Inactif' 
    END as status;
```

Si tous les composants montrent "✅", le système est prêt !
