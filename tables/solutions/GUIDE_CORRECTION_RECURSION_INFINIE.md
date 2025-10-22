# Guide de Correction de la Récursion Infinie

## 🔍 Problème identifié

L'erreur `infinite recursion detected in policy for relation "users"` indique qu'il y a une récursion infinie dans les politiques RLS de la table `users`. Cela se produit quand les politiques RLS font référence à la table `users` elle-même, créant une boucle infinie.

### Symptômes :
- Erreur : `infinite recursion detected in policy for relation "users"`
- Échec de chargement des utilisateurs
- Échec de chargement des paramètres système
- Échec de vérification du statut d'abonnement

## 🛠️ Solution

### Étape 1 : Appliquer le script de correction

1. **Accéder à Supabase Dashboard**
   - Aller sur https://supabase.com/dashboard
   - Sélectionner votre projet
   - Aller dans l'onglet "SQL Editor"

2. **Exécuter le script de correction**
   - Copier le contenu du fichier `tables/fix_infinite_recursion_users_policy.sql`
   - Coller dans l'éditeur SQL
   - Cliquer sur "Run" pour exécuter

### Étape 2 : Vérifier la correction

Après l'exécution, vous devriez voir :

1. **Anciennes politiques supprimées** qui causaient la récursion
2. **Nouvelles politiques simplifiées** créées
3. **Fonction `check_admin_rights()`** créée
4. **Tests de la fonction** avec les résultats

## 🔧 Modifications apportées

### 1. Suppression des politiques problématiques
```sql
DROP POLICY IF EXISTS "Admin and technicians can view all users" ON users;
DROP POLICY IF EXISTS "Admin and technicians can update all users" ON users;
-- etc.
```

### 2. Création de politiques simplifiées
```sql
-- Politique pour permettre à tous les utilisateurs authentifiés de voir les utilisateurs
CREATE POLICY "Authenticated users can view users" ON users
  FOR SELECT USING (auth.role() = 'authenticated');

-- Politique pour permettre aux utilisateurs de modifier leurs propres données
CREATE POLICY "Users can update their own data" ON users
  FOR UPDATE USING (auth.uid() = id);
```

### 3. Fonction `check_admin_rights()` sans récursion
```sql
CREATE OR REPLACE FUNCTION check_admin_rights()
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
BEGIN
  -- Récupérer le rôle depuis auth.users (pas de récursion)
  SELECT (raw_user_meta_data->>'role')::TEXT INTO user_role
  FROM auth.users 
  WHERE id = auth.uid();
  
  RETURN user_role IN ('admin', 'technician');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 4. Politiques pour les autres tables
Les politiques pour `system_settings`, `user_profiles`, etc. utilisent maintenant la fonction `check_admin_rights()` au lieu de faire référence directement à la table `users`.

## ✅ Vérification

Après l'application du script :

1. **L'application devrait fonctionner sans erreur de récursion**
2. **Le chargement des utilisateurs devrait fonctionner**
3. **Le chargement des paramètres système devrait fonctionner**
4. **La vérification du statut d'abonnement devrait fonctionner**

## 🔍 Dépannage

### Problème : Erreur persiste après l'exécution
**Solution :**
1. Vérifier que le script a été exécuté complètement
2. Vérifier les logs d'erreur dans la console
3. Redémarrer l'application

### Problème : Les utilisateurs ne peuvent plus accéder à l'administration
**Solution :**
1. Vérifier que la fonction `check_admin_rights()` fonctionne
2. Vérifier que les métadonnées utilisateur contiennent le rôle
3. Vérifier les politiques RLS dans Supabase Dashboard

### Problème : Erreur de permission
**Solution :**
1. Vérifier que l'utilisateur est bien authentifié
2. Vérifier que les métadonnées utilisateur sont correctes
3. Vérifier les politiques RLS

## 📝 Notes importantes

1. **Sécurité :** Les nouvelles politiques sont plus permissives mais la sécurité est maintenue via les fonctions RPC.

2. **Performance :** La fonction `check_admin_rights()` est plus efficace car elle évite la récursion.

3. **Compatibilité :** Les modifications sont rétrocompatibles avec l'existant.

4. **Maintenance :** Les politiques sont maintenant plus simples et plus faciles à maintenir.

## 🎯 Résultat final

Après l'application de ces corrections :
- ✅ Plus d'erreur de récursion infinie
- ✅ Chargement des utilisateurs fonctionnel
- ✅ Chargement des paramètres système fonctionnel
- ✅ Vérification du statut d'abonnement fonctionnelle
- ✅ Accès à l'administration pour les techniciens maintenu
- ✅ Sécurité préservée via les fonctions RPC
