# Guide de Résolution - Création d'Utilisateurs

## Problème
L'erreur `Could not find the 'password_hash' column of 'users' in the schema cache` indique que le code essaie d'insérer une colonne `password_hash` qui n'existe pas dans la table `users`.

## Solution

### 1. Exécuter le Script SQL
Exécutez le script `create_user_function.sql` dans votre base de données Supabase :

1. Allez dans votre dashboard Supabase
2. Cliquez sur "SQL Editor"
3. Copiez et collez le contenu du fichier `create_user_function.sql`
4. Cliquez sur "Run" pour exécuter le script

### 2. Vérification
Après l'exécution du script, vous devriez voir :
- Une nouvelle fonction RPC `create_user_with_auth`
- Les permissions appropriées configurées

### 3. Test de la Fonction
Vous pouvez tester la fonction directement dans l'éditeur SQL :

```sql
SELECT create_user_with_auth(
  'John',
  'Doe',
  'john.doe@example.com',
  'password123',
  'technician',
  NULL
);
```

## Modifications Apportées

### Code Modifié
1. **supabaseService.ts** : Remplacé l'insertion directe par un appel RPC
2. **Types** : Ajouté la propriété `password` au type de création d'utilisateur
3. **Store** : Mis à jour le type pour inclure le mot de passe

### Fonction RPC
La fonction `create_user_with_auth` :
- Vérifie que l'utilisateur actuel est un administrateur
- Crée l'utilisateur dans `auth.users` avec le mot de passe hashé
- Crée l'enregistrement correspondant dans la table `users`
- Gère les erreurs et les rollbacks automatiquement

## Sécurité
- Seuls les administrateurs peuvent créer des utilisateurs
- Les mots de passe sont hashés avec bcrypt
- Vérification des doublons d'email
- Gestion des erreurs avec rollback automatique

## Utilisation
Après avoir exécuté le script SQL, la création d'utilisateurs depuis l'interface d'administration devrait fonctionner correctement.

## Dépannage
Si vous rencontrez encore des erreurs :
1. Vérifiez que la fonction RPC a été créée avec succès
2. Vérifiez que l'utilisateur actuel a le rôle 'admin'
3. Vérifiez les logs dans la console du navigateur
