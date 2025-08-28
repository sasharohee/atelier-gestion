# Guide de Correction - Problème d'Isolation des Données dans Administration

## 🔍 **Problème identifié**

L'erreur suivante se produit dans la page Administration :
```
GET https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/users?select=*&id=eq.73bbdd45-8b3c-42c2-9ba2-78dbdad8bb11 406 (Not Acceptable)
```

**Message d'erreur :**
```
Cannot coerce the result to a single JSON object
The result contains 0 rows
```

## 🎯 **Cause du problème**

1. **Politiques RLS défaillantes** : Les politiques Row Level Security de la table `users` empêchent l'utilisateur actuel d'accéder à ses propres données
2. **Utilisation de `.single()`** : La fonction `getAllUsers()` utilise `.single()` qui échoue si aucun résultat n'est trouvé
3. **Isolation trop restrictive** : Les politiques RLS ne permettent pas l'accès aux données utilisateur nécessaires

## ✅ **Solutions appliquées**

### **1. Correction des politiques RLS**

**Fichier :** `tables/correction_rls_users_administration.sql`

**Actions :**
- Suppression des anciennes politiques RLS problématiques
- Création d'une fonction d'autorisation `can_access_user_data()`
- Mise en place de nouvelles politiques RLS plus permissives

**Fonction d'autorisation :**
```sql
CREATE OR REPLACE FUNCTION can_access_user_data(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- L'utilisateur peut toujours accéder à ses propres données
  IF user_id = auth.uid() THEN
    RETURN TRUE;
  END IF;
  
  -- L'utilisateur peut accéder aux données des utilisateurs qu'il a créés
  IF EXISTS (
    SELECT 1 FROM users 
    WHERE id = user_id 
    AND created_by = auth.uid()
  ) THEN
    RETURN TRUE;
  END IF;
  
  -- L'utilisateur peut voir tous les utilisateurs s'il est admin
  IF EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  ) THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### **2. Amélioration de la fonction getAllUsers**

**Fichier :** `src/services/supabaseService.ts`

**Changements :**
- Remplacement de `.single()` par `.maybeSingle()` pour éviter les erreurs
- Gestion plus robuste des cas où aucun utilisateur n'est trouvé
- Continuation avec un tableau vide au lieu d'échouer

**Code modifié :**
```typescript
// Avant
const { data: currentUserData, error: currentUserError } = await supabase
  .from('users')
  .select('*')
  .eq('id', currentUser.id)
  .single();

// Après
const { data: currentUserData, error: currentUserError } = await supabase
  .from('users')
  .select('*')
  .eq('id', currentUser.id)
  .maybeSingle();
```

## 🚀 **Instructions d'installation**

### **Étape 1 : Exécuter le script SQL**

```bash
# Se connecter à votre base de données Supabase
psql "postgresql://postgres:[YOUR_PASSWORD]@db.[YOUR_PROJECT_REF].supabase.co:5432/postgres"

# Exécuter le script de correction
\i tables/correction_rls_users_administration.sql
```

### **Étape 2 : Vérifier les politiques**

Le script affichera les politiques RLS actuelles pour confirmation.

### **Étape 3 : Tester la correction**

1. Aller dans la page Administration
2. Vérifier que la liste des utilisateurs se charge correctement
3. Tester les fonctionnalités de création/modification d'utilisateurs

## 🔧 **Nouvelles politiques RLS**

### **Politique de lecture (SELECT)**
```sql
CREATE POLICY "Users can view accessible data" ON users
FOR SELECT USING (
  can_access_user_data(id)
);
```

### **Politique de création (INSERT)**
```sql
CREATE POLICY "Users can create new users" ON users
FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
);
```

### **Politique de modification (UPDATE)**
```sql
CREATE POLICY "Users can update accessible data" ON users
FOR UPDATE USING (
  can_access_user_data(id)
) WITH CHECK (
  can_access_user_data(id)
);
```

### **Politique de suppression (DELETE)**
```sql
CREATE POLICY "Users can delete accessible data" ON users
FOR DELETE USING (
  can_access_user_data(id)
);
```

## 🛡️ **Sécurité maintenue**

Les nouvelles politiques RLS garantissent :
- ✅ **Isolation des données** : Chaque utilisateur ne voit que ses données et celles qu'il a créées
- ✅ **Accès aux données personnelles** : L'utilisateur peut toujours accéder à ses propres informations
- ✅ **Privilèges admin** : Les administrateurs peuvent voir tous les utilisateurs
- ✅ **Création d'utilisateurs** : Seuls les utilisateurs connectés peuvent créer de nouveaux utilisateurs

## 🧪 **Tests recommandés**

1. **Test utilisateur normal** :
   - Se connecter avec un compte technicien
   - Vérifier l'accès à ses propres données
   - Vérifier l'accès aux utilisateurs qu'il a créés

2. **Test administrateur** :
   - Se connecter avec un compte admin
   - Vérifier l'accès à tous les utilisateurs
   - Tester les fonctionnalités de gestion

3. **Test de création** :
   - Créer un nouvel utilisateur
   - Vérifier que l'isolation fonctionne correctement

## 📝 **Notes importantes**

- Les politiques RLS sont appliquées au niveau de la base de données
- La fonction `can_access_user_data()` est sécurisée avec `SECURITY DEFINER`
- Les modifications sont rétrocompatibles avec le code existant
- Aucune modification du code frontend n'est nécessaire après l'application du script SQL

## 🔄 **En cas de problème**

Si l'erreur persiste après l'application du script :

1. Vérifier que le script s'est exécuté sans erreur
2. Contrôler les logs de la console pour d'autres erreurs
3. Vérifier que l'utilisateur est bien connecté
4. Contrôler les politiques RLS dans l'interface Supabase

---

**Date de création :** $(date)
**Version :** 1.0
**Statut :** ✅ Prêt à déployer
