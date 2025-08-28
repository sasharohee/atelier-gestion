# Guide d'Accès à l'Administration pour les Techniciens

## 🔧 Modifications apportées

### Objectif
Permettre aux utilisateurs ayant le rôle `technician` d'accéder aux fonctionnalités d'administration, en plus des utilisateurs ayant le rôle `admin`.

### Changements effectués

#### 1. Composant AdminGuard (Frontend)
**Fichier :** `src/components/AdminGuard.tsx`

**Avant :**
```typescript
const isAdmin = user && (user as any).user_metadata?.role === 'admin';
```

**Après :**
```typescript
const userRole = user && (user as any).user_metadata?.role;
const hasAdminAccess = userRole === 'admin' || userRole === 'technician';
```

**Impact :** Les techniciens peuvent maintenant accéder aux pages protégées par AdminGuard.

#### 2. Page UserAccessManagement (Frontend)
**Fichier :** `src/pages/Administration/UserAccessManagement.tsx`

**Avant :**
```typescript
const isAdmin = authUser && (authUser as any).user_metadata?.role === 'admin';
```

**Après :**
```typescript
const userRole = authUser && (authUser as any).user_metadata?.role;
const isAdmin = userRole === 'admin' || userRole === 'technician';
```

**Impact :** Les techniciens peuvent maintenant gérer l'accès des utilisateurs.

#### 3. Politiques RLS (Backend)
**Fichier :** `tables/update_admin_access_for_technicians.sql`

**Nouvelles politiques créées :**
- `"Admin and technicians can view all users"`
- `"Admin and technicians can update all users"`
- `"Admin and technicians can create users"`
- `"Admin and technicians can delete users"`
- `"Admin and technicians can manage system settings"`
- `"Admin and technicians can manage user profiles"`
- `"Admin and technicians can manage user preferences"`
- `"Admin and technicians can manage subscriptions"`

**Impact :** Les techniciens ont maintenant les mêmes permissions que les administrateurs au niveau de la base de données.

#### 4. Fonction utilitaire (Backend)
**Nouvelle fonction :** `has_admin_access(user_id UUID)`

```sql
CREATE OR REPLACE FUNCTION has_admin_access(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = user_id AND (role = 'admin' OR role = 'technician')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Impact :** Fonction réutilisable pour vérifier les droits d'administration.

#### 5. Fonction RPC mise à jour (Backend)
**Fichier :** `tables/update_admin_access_for_technicians.sql`

La fonction `create_user_with_auth` a été mise à jour pour accepter les techniciens :

```sql
-- Vérifier que l'utilisateur actuel est un administrateur ou technicien
IF NOT EXISTS (
  SELECT 1 FROM users 
  WHERE id = auth.uid() AND (role = 'admin' OR role = 'technician')
) THEN
  RETURN json_build_object(
    'success', false,
    'error', 'Accès non autorisé. Seuls les administrateurs et techniciens peuvent créer des utilisateurs.'
  );
END IF;
```

## 🚀 Application des modifications

### Étape 1 : Appliquer le script SQL
1. Aller dans le dashboard Supabase
2. Ouvrir l'éditeur SQL
3. Exécuter le script `tables/update_admin_access_for_technicians.sql`

### Étape 2 : Vérifier les modifications
Après l'exécution du script, vous devriez voir :
- Les nouvelles politiques RLS créées
- La fonction `has_admin_access` disponible
- Les tests de la fonction avec les résultats

### Étape 3 : Tester l'accès
1. Se connecter avec un compte technicien
2. Essayer d'accéder à la page Administration
3. Vérifier que toutes les fonctionnalités sont accessibles

## ✅ Vérifications

### Frontend
- [ ] Les techniciens peuvent accéder à `/administration`
- [ ] Les techniciens peuvent voir la liste des utilisateurs
- [ ] Les techniciens peuvent créer/modifier/supprimer des utilisateurs
- [ ] Les techniciens peuvent modifier les paramètres système

### Backend
- [ ] Les politiques RLS sont en place
- [ ] La fonction `has_admin_access` fonctionne
- [ ] Les fonctions RPC acceptent les techniciens
- [ ] Les permissions sont correctement appliquées

## 🔍 Dépannage

### Problème : Les techniciens ne peuvent toujours pas accéder
**Solution :**
1. Vérifier que le script SQL a été exécuté
2. Vérifier que l'utilisateur a bien le rôle `technician` dans la base de données
3. Vérifier les politiques RLS dans Supabase Dashboard

### Problème : Erreur de permission dans les fonctions RPC
**Solution :**
1. Vérifier que la fonction `create_user_with_auth` a été mise à jour
2. Vérifier que l'utilisateur est bien authentifié
3. Vérifier les logs d'erreur dans la console

### Problème : Les statistiques ne s'affichent pas correctement
**Solution :**
1. Vérifier que l'utilisateur connecté est bien compté dans les statistiques
2. Vérifier que les données sont bien chargées depuis la base de données

## 📝 Notes importantes

1. **Sécurité :** Les techniciens ont maintenant les mêmes permissions que les administrateurs. Assurez-vous que cela correspond à votre politique de sécurité.

2. **Compatibilité :** Les modifications sont rétrocompatibles. Les administrateurs conservent tous leurs droits.

3. **Audit :** Toutes les actions des techniciens sont loggées de la même manière que celles des administrateurs.

4. **Évolutivité :** La fonction `has_admin_access` peut être étendue pour inclure d'autres rôles si nécessaire.

## 🎯 Résultat final

Après l'application de ces modifications :
- ✅ Les techniciens peuvent accéder à l'administration
- ✅ Les techniciens peuvent gérer les utilisateurs
- ✅ Les techniciens peuvent modifier les paramètres système
- ✅ Les politiques de sécurité sont cohérentes
- ✅ L'interface utilisateur reflète les nouveaux droits
