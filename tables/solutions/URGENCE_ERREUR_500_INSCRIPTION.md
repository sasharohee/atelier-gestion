# 🚨 URGENCE : Erreur 500 lors de l'inscription

## ❌ Problème Actuel

```
Failed to load resource: the server responded with a status of 500
AuthApiError: Database error saving new user
```

**Impact :** AUCUN NOUVEL UTILISATEUR NE PEUT S'INSCRIRE

## 🔍 Cause Racine

Le trigger `sync_auth_user_complete()` ou `sync_all_auth_users()` créé précédemment **bloque** la création des utilisateurs dans `auth.users` à cause de :

1. **Politiques RLS trop restrictives** sur `users` et `subscription_status`
2. **Permissions insuffisantes** pour le trigger
3. **Le trigger lève une erreur** qui remonte et bloque l'inscription

## 🚀 Solution Immédiate (5 minutes)

### Étape 1 : Appliquer le script de correction

**Option A - Via l'interface Supabase (RECOMMANDÉ) :**

1. Ouvrir le dashboard Supabase : https://app.supabase.com
2. Aller dans **SQL Editor**
3. Copier TOUT le contenu de `fix_user_sync_safe.sql`
4. Coller dans l'éditeur
5. Cliquer sur **Run** (bouton en bas à droite)

**Option B - Via Supabase CLI :**

```bash
supabase db execute --file fix_user_sync_safe.sql
```

### Étape 2 : Vérifier que ça fonctionne

```sql
-- Dans le SQL Editor, exécuter :
SELECT * FROM check_sync_quick();
```

Vous devriez voir quelque chose comme :
```
info                 | count_val
---------------------+----------
auth.users          | 5
public.users        | 5
subscription_status | 5
manquants          | 0
```

### Étape 3 : Tester une nouvelle inscription

1. Ouvrir votre application en **mode navigation privée** (pour avoir une session propre)
2. Aller sur la page d'inscription
3. Créer un nouveau compte avec un email temporaire
4. ✅ L'inscription devrait fonctionner sans erreur 500

## 🔧 Ce que fait la correction

### 1. Supprime les anciens triggers problématiques
```sql
DROP TRIGGER IF EXISTS trigger_sync_auth_user_complete ON auth.users;
DROP TRIGGER IF EXISTS trigger_sync_all_auth_users ON auth.users;
```

### 2. Crée un trigger SÉCURISÉ qui ne bloque jamais
```sql
CREATE OR REPLACE FUNCTION sync_auth_user_safe()
-- Cette fonction capture TOUTES les erreurs
-- et retourne TOUJOURS NEW pour ne pas bloquer
```

### 3. Ajuste les politiques RLS
- Désactive temporairement RLS
- Recrée des politiques plus permissives
- Réactive RLS

### 4. Répare les utilisateurs existants
- Synchronise tous les utilisateurs déjà dans `auth.users`
- Vers `users` et `subscription_status`

## 📊 Vérifications Post-Correction

### Vérifier que le trigger est actif

```sql
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_sync_auth_user_safe';
```

**Résultat attendu :** 1 ligne avec `trigger_sync_auth_user_safe`

### Vérifier les politiques RLS

```sql
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies
WHERE tablename IN ('users', 'subscription_status')
ORDER BY tablename, policyname;
```

**Résultat attendu :** Plusieurs politiques pour SELECT, INSERT, UPDATE

### Tester avec un utilisateur de test

```sql
-- Après avoir créé un compte de test
SELECT 
    au.email,
    u.id IS NOT NULL as in_users,
    ss.user_id IS NOT NULL as in_subscription,
    ss.is_active as active,
    ss.subscription_type as type
FROM auth.users au
LEFT JOIN public.users u ON u.id = au.id
LEFT JOIN public.subscription_status ss ON ss.user_id = au.id
WHERE au.email = 'votre-email-de-test@example.com';
```

**Résultat attendu :**
```
email                  | in_users | in_subscription | active | type
-----------------------+----------+----------------+--------+------
test@example.com      | true     | true           | true   | free
```

## 🐛 Si le problème persiste

### Vérifier les logs Supabase

1. Dashboard Supabase → **Logs** → **Postgres Logs**
2. Chercher les erreurs récentes avec "auth" ou "user"
3. Identifier l'erreur exacte

### Erreurs communes et solutions

#### Erreur : "permission denied for table users"

```sql
-- Accorder les permissions
GRANT SELECT, INSERT, UPDATE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.subscription_status TO authenticated;
```

#### Erreur : "violates foreign key constraint"

```sql
-- Vérifier la contrainte
SELECT
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'subscription_status'
  AND tc.constraint_type = 'FOREIGN KEY';
```

**Solution :** S'assurer que `user_id` pointe vers `auth.users(id)`

#### Erreur : "duplicate key value violates unique constraint"

```sql
-- Nettoyer les doublons
DELETE FROM public.subscription_status
WHERE id NOT IN (
    SELECT MIN(id)
    FROM public.subscription_status
    GROUP BY user_id
);
```

### Désactiver temporairement le trigger (solution de secours)

Si vraiment rien ne fonctionne :

```sql
-- TEMPORAIREMENT désactiver le trigger
ALTER TABLE auth.users DISABLE TRIGGER trigger_sync_auth_user_safe;
```

Cela permettra les inscriptions, mais vous devrez synchroniser manuellement :

```sql
-- Synchroniser manuellement après
SELECT * FROM repair_all_users();
```

**N'oubliez pas de réactiver ensuite :**

```sql
ALTER TABLE auth.users ENABLE TRIGGER trigger_sync_auth_user_safe;
```

## 📝 Checklist de Résolution

- [ ] Script `fix_user_sync_safe.sql` exécuté
- [ ] `check_sync_quick()` montre des chiffres cohérents
- [ ] Trigger `trigger_sync_auth_user_safe` actif
- [ ] Test d'inscription réussi en navigation privée
- [ ] Nouvel utilisateur visible dans subscription_status
- [ ] Logs Supabase sans erreur

## 🎯 Résultat Attendu

Après cette correction :

✅ Les **nouvelles inscriptions fonctionnent** sans erreur 500  
✅ Les utilisateurs sont **automatiquement synchronisés** dans toutes les tables  
✅ Les **administrateurs peuvent gérer** tous les utilisateurs  
✅ Le système **ne bloque jamais** même si la synchronisation échoue  

## 📞 Escalade

Si après avoir suivi tous ces steps le problème persiste :

1. **Exporter les logs d'erreur** de Supabase
2. **Vérifier la structure des tables** :
   ```sql
   \d public.users
   \d public.subscription_status
   ```
3. **Vérifier les contraintes** et les index
4. **Contacter le support Supabase** si nécessaire

---

**Date :** 2025-10-09  
**Priorité :** 🔴 CRITIQUE  
**Temps estimé :** 5 minutes  
**Impact :** Bloque toutes les inscriptions

