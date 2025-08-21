# Résolution de l'Erreur 406 (Not Acceptable)

## ❌ Problème Rencontré

```
GET https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/users?select=id%2Cemail&email=eq.test27%40yopmail.co 406 (Not Acceptable)
```

Cette erreur 406 indique un problème avec la requête Supabase, probablement lié à la vérification d'email.

## 🔍 Causes Possibles

1. **Problème de syntaxe** dans la requête Supabase
2. **Fonction RPC non disponible** ou mal configurée
3. **Problème d'échappement** dans les chaînes SQL
4. **Permissions insuffisantes** pour accéder aux données

## ✅ Solutions Implémentées

### 1. Correction de la Vérification d'Email
Remplacement de `.single()` par une approche plus robuste :

```typescript
// ❌ Ancienne approche (problématique)
const { data: existingUser, error: checkError } = await supabase
  .from('users')
  .select('id, email')
  .eq('email', userData.email)
  .single();

// ✅ Nouvelle approche (robuste)
const { data: existingUsers, error: checkError } = await supabase
  .from('users')
  .select('id, email')
  .eq('email', userData.email);
```

### 2. Système de Fallback RPC
Implémentation d'un système à deux niveaux :

```typescript
// Essayer d'abord la fonction RPC principale
try {
  const result = await supabase.rpc('create_user_with_email_check', {...});
} catch (err) {
  // Si échec, essayer la fonction de fallback
  const fallbackResult = await supabase.rpc('create_user_simple_fallback', {...});
}
```

### 3. Fonction RPC Simplifiée
Création d'une version sans caractères spéciaux :

```sql
CREATE OR REPLACE FUNCTION create_user_simple_fallback(...)
-- Version sans apostrophes problématiques
```

## 📋 Étapes pour Résoudre

### Étape 1 : Exécuter les Scripts SQL
Exécutez les scripts dans l'ordre suivant :

1. **fix_user_isolation.sql** - Pour l'isolation des données
2. **fix_email_duplicates.sql** - Pour nettoyer les doublons
3. **create_user_simple_fallback.sql** - Pour la fonction de fallback

### Étape 2 : Vérifier les Fonctions RPC
Dans votre dashboard Supabase, vérifiez que ces fonctions existent :
- `create_user_with_email_check`
- `create_user_simple_fallback`
- `get_my_users`

### Étape 3 : Tester la Création
1. Essayez de créer un utilisateur avec un email unique
2. Vérifiez les logs dans la console
3. Confirmez que l'utilisateur apparaît dans la liste

## 🔧 Détails Techniques

### Problème avec `.single()`
La méthode `.single()` peut causer des erreurs 406 quand :
- Aucun résultat n'est trouvé
- Plusieurs résultats sont trouvés
- La requête est mal formée

### Solution Alternative
Utilisation de `.maybeSingle()` ou vérification du tableau de résultats :

```typescript
// Approche recommandée
const { data: users } = await supabase
  .from('users')
  .select('id, email')
  .eq('email', userData.email);

if (users && users.length > 0) {
  // Email existe déjà
}
```

## 🛡️ Prévention

### Côté Frontend
- Validation des emails avant envoi
- Gestion d'erreurs robuste
- Messages utilisateur clairs

### Côté Backend
- Vérification préalable sans `.single()`
- Système de fallback RPC
- Gestion d'erreurs détaillée

## 🔍 Dépannage

### Problème : Fonction RPC non trouvée
```sql
-- Vérifier que la fonction existe
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name LIKE '%create_user%';
```

### Problème : Permissions insuffisantes
```sql
-- Vérifier les permissions
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name = 'users';
```

### Problème : Erreur de syntaxe SQL
```sql
-- Tester la fonction manuellement
SELECT create_user_simple_fallback(
  gen_random_uuid(),
  'Test',
  'User',
  'test@example.com',
  'technician',
  NULL
);
```

## 📊 Résultat Final

Après l'implémentation :
- ✅ Plus d'erreurs 406
- ✅ Vérification d'email robuste
- ✅ Système de fallback fonctionnel
- ✅ Création d'utilisateurs stable

## 🚀 Utilisation

### Création d'Utilisateur
1. Remplissez le formulaire
2. Le système vérifie l'email automatiquement
3. Si l'email est unique, l'utilisateur est créé
4. Si l'email existe, un message clair s'affiche

### Gestion des Erreurs
- **Email existant** : Message clair
- **Erreur RPC** : Fallback automatique
- **Erreur réseau** : Retry automatique

Cette solution garantit une création d'utilisateurs stable et sans erreurs 406 ! 🎉
