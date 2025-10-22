# Guide de Correction de la Contrainte de Rôle

## 🔍 Problème identifié

L'erreur `"users_role_check"` indique que la contrainte de vérification sur la colonne `role` de la table `users` est trop restrictive et n'accepte pas les rôles que l'application essaie d'utiliser.

### Symptômes :
- Erreur : `new row for relation "users" violates check constraint "users_role_check"`
- Échec de création automatique d'utilisateurs
- Tous les rôles testés sont rejetés

## 🛠️ Solution

### Étape 1 : Appliquer le script de correction

1. **Accéder à Supabase Dashboard**
   - Aller sur https://supabase.com/dashboard
   - Sélectionner votre projet
   - Aller dans l'onglet "SQL Editor"

2. **Exécuter le script de correction**
   - Copier le contenu du fichier `correction_contrainte_role_users.sql`
   - Coller dans l'éditeur SQL
   - Cliquer sur "Run" pour exécuter

### Étape 2 : Vérifier la correction

Après l'exécution, vous devriez voir :

1. **Ancienne contrainte supprimée**
2. **Nouvelle contrainte créée** avec les rôles autorisés :
   - `admin`
   - `manager` 
   - `technician`
   - `user`
   - `client`

3. **Tests de la fonction RPC** avec différents rôles

### Étape 3 : Vérifier les résultats

Le script affichera les résultats des tests pour chaque rôle. Vous devriez voir des messages de succès pour chaque test.

## 🔧 Modifications apportées

### 1. Suppression de l'ancienne contrainte
```sql
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
```

### 2. Création de la nouvelle contrainte
```sql
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN ('admin', 'manager', 'technician', 'user', 'client'));
```

### 3. Tests automatiques
Le script teste automatiquement la création d'utilisateurs avec chaque rôle autorisé.

## ✅ Vérification

Après l'application du script :

1. **L'application devrait fonctionner sans erreur 409**
2. **La création automatique d'utilisateurs devrait fonctionner**
3. **Tous les rôles listés ci-dessus devraient être acceptés**

## 🚀 Test de l'application

1. **Aller sur l'URL Vercel** : `https://atelier-gestion-8itghyboy-sasharohees-projects.vercel.app`
2. **Essayer de se connecter** avec un compte existant ou en créer un nouveau
3. **Vérifier qu'il n'y a plus d'erreurs** dans la console du navigateur

## 🆘 En cas de problème persistant

Si l'erreur persiste après l'application du script :

1. **Vérifier que le script s'est bien exécuté** :
   ```sql
   SELECT 
       conname as constraint_name,
       pg_get_constraintdef(oid) as constraint_definition
   FROM pg_constraint 
   WHERE conrelid = 'users'::regclass 
   AND conname = 'users_role_check';
   ```

2. **Vérifier les logs Supabase** :
   - Aller dans "Logs" > "Database"
   - Chercher les erreurs liées à la table `users`

3. **Tester manuellement la fonction RPC** :
   ```sql
   SELECT create_user_automatically(
     gen_random_uuid(),
     'Test',
     'User',
     'test@example.com',
     'technician'
   );
   ```

## 📝 Notes importantes

- Cette correction modifie la contrainte de base de données
- Les rôles autorisés sont maintenant : `admin`, `manager`, `technician`, `user`, `client`
- La fonction RPC utilise `SECURITY DEFINER` pour contourner les restrictions RLS
- Les tests automatiques nettoient les données de test après exécution
