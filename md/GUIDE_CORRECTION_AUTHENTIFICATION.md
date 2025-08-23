# 🔐 Guide de Correction : Erreur d'Authentification

## 🚨 Problème Identifié

L'erreur "Invalid login credentials" indique que vous essayez de vous connecter avec des identifiants qui n'existent pas dans votre base de données Supabase.

```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/auth/v1/token?grant_type=password 400 (Bad Request)
Supabase error: AuthApiError: Invalid login credentials
```

### Cause du Problème

1. **Aucun utilisateur créé** : Aucun compte utilisateur n'existe dans Supabase Auth
2. **Identifiants incorrects** : L'email/mot de passe saisi ne correspond à aucun utilisateur
3. **Configuration manquante** : L'authentification n'est pas correctement configurée

## 🛠️ Solutions Disponibles

### Solution 1 : Créer un Utilisateur de Démonstration (Recommandée)

**Fichier** : `create_demo_user.sql`

Cette solution vous guide pour créer un utilisateur de test dans Supabase.

#### Étapes Manuelles dans Supabase :

1. **Accéder à l'interface Supabase** :
   - Allez sur https://supabase.com
   - Connectez-vous à votre projet
   - Allez dans **Authentication > Users**

2. **Créer un nouvel utilisateur** :
   - Cliquez sur **"Add User"**
   - Remplissez les informations :
     - **Email** : `demo@atelier.fr`
     - **Password** : `Demo123!`
     - **User Metadata** (JSON) :
     ```json
     {
       "firstName": "Demo",
       "lastName": "Utilisateur",
       "role": "admin"
     }
     ```
   - Cliquez sur **"Create User"**

3. **Exécuter le script SQL** :
   - Allez dans **SQL Editor**
   - Exécutez le script `create_demo_user.sql`
   - Remplacez `USER_ID_FROM_AUTH` par l'ID réel de l'utilisateur créé

4. **Se connecter à l'application** :
   - Email : `demo@atelier.fr`
   - Mot de passe : `Demo123!`

### Solution 2 : Utiliser l'Inscription (Alternative)

Si vous préférez créer votre propre compte :

1. **Dans l'application** :
   - Allez sur la page de connexion
   - Cliquez sur **"Créer un compte"**
   - Remplissez le formulaire d'inscription
   - Confirmez votre email

2. **Vérifier l'email** :
   - Vérifiez votre boîte email
   - Cliquez sur le lien de confirmation
   - Retournez à l'application

3. **Se connecter** :
   - Utilisez vos identifiants d'inscription

## 📋 Étapes de Diagnostic

### 1. Vérifier l'État de l'Authentification

```sql
-- Vérifier les utilisateurs dans auth.users
SELECT 
    id,
    email,
    raw_user_meta_data,
    created_at
FROM auth.users
ORDER BY created_at DESC;
```

### 2. Vérifier la Table Users

```sql
-- Vérifier les utilisateurs dans la table users
SELECT 
    id,
    first_name,
    last_name,
    email,
    role
FROM users
ORDER BY created_at DESC;
```

### 3. Vérifier la Configuration Supabase

```sql
-- Vérifier les politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public';
```

## 🔧 Configuration Supplémentaire

### 1. Activer l'Authentification par Email

Dans Supabase > Authentication > Settings :

- ✅ **Enable email confirmations** : Désactivé pour le développement
- ✅ **Enable email change confirmations** : Désactivé pour le développement
- ✅ **Enable phone confirmations** : Désactivé pour le développement

### 2. Configurer les Redirections

Dans Supabase > Authentication > URL Configuration :

- **Site URL** : `http://localhost:3001` (développement)
- **Redirect URLs** : 
  - `http://localhost:3001/auth`
  - `http://localhost:3001/app/*`

### 3. Vérifier les Variables d'Environnement

Assurez-vous que votre fichier `.env` contient :

```env
VITE_SUPABASE_URL=https://wlqyrmntfxwdvkzzsujv.supabase.co
VITE_SUPABASE_ANON_KEY=votre_clé_anon
```

## 🚀 Après la Création de l'Utilisateur

### 1. Tester la Connexion

- Recharger la page de connexion
- Saisir les identifiants créés
- Vérifier que la connexion fonctionne

### 2. Vérifier les Fonctionnalités

- ✅ Connexion réussie
- ✅ Redirection vers le dashboard
- ✅ Accès aux paramètres
- ✅ Sauvegarde des paramètres

### 3. Créer des Paramètres Système

Une fois connecté, vous pouvez créer des paramètres système :

```sql
-- Insérer des paramètres système pour l'utilisateur connecté
INSERT INTO system_settings (user_id, key, value, category, description)
VALUES 
    (auth.uid(), 'workshop_name', 'Mon Atelier', 'general', 'Nom de l''atelier'),
    (auth.uid(), 'workshop_address', '123 Rue de la Paix', 'general', 'Adresse de l''atelier'),
    (auth.uid(), 'vat_rate', '20', 'billing', 'Taux de TVA'),
    (auth.uid(), 'currency', 'EUR', 'billing', 'Devise')
ON CONFLICT (user_id, key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();
```

## 🔍 Dépannage

### Problème : "User not found in users table"

**Solution** : Exécuter le script de synchronisation des utilisateurs

```sql
-- Synchroniser les utilisateurs
INSERT INTO users (id, first_name, last_name, email, role)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'firstName', 'Utilisateur') as first_name,
    COALESCE(au.raw_user_meta_data->>'lastName', 'Test') as last_name,
    au.email,
    COALESCE(au.raw_user_meta_data->>'role', 'technician') as role
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = au.id)
ON CONFLICT (id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role;
```

### Problème : "Email not confirmed"

**Solution** : Désactiver la confirmation d'email en développement

Dans Supabase > Authentication > Settings > Disable "Enable email confirmations"

### Problème : "Invalid redirect URL"

**Solution** : Configurer les URLs de redirection

Dans Supabase > Authentication > URL Configuration, ajouter :
- `http://localhost:3001/auth`
- `http://localhost:3001/app/*`

## 📞 Support

Si vous rencontrez encore des problèmes :

1. **Vérifier les logs** de l'application
2. **Vérifier les logs** Supabase (Logs > Auth)
3. **Tester avec un nouvel utilisateur**
4. **Vérifier la configuration** des variables d'environnement

## 🎯 Recommandation

**Pour le développement** : Utilisez la **Solution 1** avec un utilisateur de démonstration
**Pour la production** : Utilisez la **Solution 2** avec l'inscription d'utilisateurs

La création d'un utilisateur de démonstration vous permettra de tester rapidement toutes les fonctionnalités de l'application.
