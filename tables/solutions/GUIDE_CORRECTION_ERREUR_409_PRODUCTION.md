# Guide de Correction de l'Erreur 409 en Production

## 🔍 Problème identifié

L'erreur 409 (Conflict) survient en production car les politiques RLS (Row Level Security) de Supabase empêchent la création automatique d'utilisateurs dans la table `users`.

### Symptômes :
- Erreur 409 lors de l'accès à l'application en production
- Messages "Rôle 'admin' non autorisé", "Rôle 'manager' non autorisé", etc.
- Échec de la création automatique d'utilisateurs

## 🛠️ Solution

### Étape 1 : Appliquer le script SQL de correction

1. **Accéder à Supabase Dashboard**
   - Aller sur https://supabase.com/dashboard
   - Sélectionner votre projet
   - Aller dans l'onglet "SQL Editor"

2. **Exécuter le script de correction**
   - Copier le contenu du fichier `correction_urgence_creation_utilisateur_simple.sql`
   - Coller dans l'éditeur SQL
   - Cliquer sur "Run" pour exécuter

### Étape 2 : Vérifier les politiques RLS

Après l'exécution du script, vérifiez que les nouvelles politiques sont en place :

```sql
SELECT 
  policyname,
  permissive,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'users';
```

### Étape 3 : Tester la fonction RPC

Testez la fonction RPC créée :

```sql
-- Test de la fonction (remplacez les valeurs par celles d'un utilisateur réel)
SELECT create_user_automatically(
  '00000000-0000-0000-0000-000000000000'::UUID,
  'Test',
  'User',
  'test@example.com',
  'technician'
);

-- Ou test avec des valeurs par défaut
SELECT create_user_automatically(
  '00000000-0000-0000-0000-000000000000'::UUID,
  NULL,
  NULL,
  NULL,
  NULL
);
```

## 🔧 Modifications apportées

### 1. Nouvelles politiques RLS
- `Allow user creation for authenticated users` : Permet la création d'utilisateurs
- `Allow users to view their own data` : Permet la consultation de ses propres données
- `Allow users to update their own data` : Permet la modification de ses propres données

### 2. Fonction RPC sécurisée
- `create_user_automatically()` : Fonction sécurisée pour créer des utilisateurs
- Vérifications de sécurité intégrées
- Gestion des erreurs et conflits

### 3. Trigger automatique
- Création automatique de profils utilisateur
- Création automatique de préférences par défaut

## 🚀 Déploiement

### Option 1 : Déploiement automatique (recommandé)
Le code a été modifié pour utiliser la fonction RPC. Redéployez simplement :

```bash
git add .
git commit -m "Correction erreur 409: utilisation fonction RPC pour création utilisateurs"
git push origin main
vercel --prod
```

### Option 2 : Déploiement manuel
Si vous préférez appliquer les changements manuellement :

1. **Modifier le fichier `src/services/supabaseService.ts`**
   - Remplacer la section de création automatique d'utilisateurs
   - Utiliser `supabase.rpc('create_user_automatically', ...)` au lieu de `supabase.from('users').insert(...)`

2. **Redéployer**
   ```bash
   vercel --prod
   ```

## ✅ Vérification

Après le déploiement, vérifiez que :

1. **L'application se charge sans erreur 409**
2. **La création automatique d'utilisateurs fonctionne**
3. **Les utilisateurs peuvent se connecter normalement**

## 🔒 Sécurité

Les modifications maintiennent la sécurité :
- Seuls les utilisateurs authentifiés peuvent créer des comptes
- Les utilisateurs ne peuvent voir/modifier que leurs propres données
- La fonction RPC inclut des vérifications de sécurité

## 🆘 En cas de problème

Si l'erreur persiste :

1. **Vérifier les logs Supabase**
   - Aller dans "Logs" > "Database"
   - Chercher les erreurs liées à la table `users`

2. **Vérifier les politiques RLS**
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'users';
   ```

3. **Tester la fonction RPC manuellement**
   ```sql
   SELECT create_user_automatically(
     auth.uid(),
     'Test',
     'User',
     auth.jwt() ->> 'email',
     'technician'
   );
   ```

4. **Contacter le support si nécessaire**

## 📝 Notes importantes

- Cette correction est temporaire et sécurisée
- Les politiques RLS restent actives pour la protection des données
- La fonction RPC utilise `SECURITY DEFINER` pour contourner les restrictions
- Les triggers automatiques créent les profils et préférences nécessaires
