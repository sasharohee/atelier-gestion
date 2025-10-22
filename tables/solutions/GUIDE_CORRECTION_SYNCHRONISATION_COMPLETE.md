# 🔧 Guide de Correction : Synchronisation Automatique des Utilisateurs

## 📋 Problème Identifié

Les utilisateurs créés dans `auth.users` (lors de l'inscription) ne sont **pas automatiquement synchronisés** vers la table `subscription_status`. Cela cause plusieurs problèmes :

- ❌ Les nouveaux utilisateurs n'apparaissent pas dans la gestion des accès
- ❌ Le système ne peut pas vérifier leur statut d'abonnement
- ❌ Les administrateurs ne peuvent pas gérer les nouveaux comptes

## 🎯 Objectif de la Correction

Mettre en place une **synchronisation automatique et robuste** qui :

1. ✅ Synchronise automatiquement chaque nouvel utilisateur
2. ✅ Crée les entrées dans `users` ET `subscription_status`
3. ✅ Répare les utilisateurs existants non synchronisés
4. ✅ Fournit des outils de diagnostic et de réparation
5. ✅ Inclut un système de logging pour déboguer

## 🏗️ Architecture de la Solution

### 1. Double Trigger System

```
auth.users (Supabase Auth)
    ↓ [Trigger 1: AFTER INSERT]
public.users
    ↓ [Trigger 2: AFTER INSERT]
subscription_status
```

#### Trigger 1 : `sync_auth_user_complete()`
- Déclenché lors de la création d'un utilisateur dans `auth.users`
- Synchronise vers `users` ET `subscription_status`
- Gère les erreurs sans bloquer la création

#### Trigger 2 : `sync_user_to_subscription()`
- Déclenché lors de l'insertion dans `users`
- Backup au cas où Trigger 1 échoue
- Garantit que `subscription_status` est toujours créé

### 2. Fonctions de Gestion

#### `sync_all_existing_users_complete()`
Synchronise TOUS les utilisateurs existants qui ne sont pas encore dans les tables.

```sql
SELECT * FROM sync_all_existing_users_complete();
```

#### `check_sync_status_detailed()`
Vérifie l'état de synchronisation et identifie les problèmes.

```sql
SELECT * FROM check_sync_status_detailed();
```

#### `repair_missing_users()`
Répare automatiquement tous les utilisateurs manquants.

```sql
SELECT * FROM repair_missing_users();
```

### 3. Système de Logging

Fonction `log_sync_event()` qui enregistre :
- Les tentatives de synchronisation
- Les succès et échecs
- Les détails des erreurs

## 🚀 Installation

### Méthode 1 : Script Automatique (Recommandé)

```bash
# Rendre le script exécutable
chmod +x deploy_user_sync_fix.sh

# Exécuter le script
./deploy_user_sync_fix.sh
```

### Méthode 2 : Supabase CLI

```bash
# Se connecter à Supabase
supabase login

# Lier le projet
supabase link --project-ref votre-project-ref

# Appliquer le script
supabase db execute --file fix_user_sync_complete.sql
```

### Méthode 3 : Interface Web Supabase

1. Ouvrir le **SQL Editor** dans votre dashboard Supabase
2. Copier le contenu de `fix_user_sync_complete.sql`
3. Coller dans l'éditeur
4. Cliquer sur **Run**

## 📊 Vérification

### 1. Vérifier l'état de synchronisation

```sql
SELECT * FROM check_sync_status_detailed();
```

**Résultat attendu :**
```
metric                    | count_value | details
--------------------------+-------------+----------------------------------
auth.users                | 10          | Utilisateurs authentifiés
public.users              | 10          | Utilisateurs dans l'application
subscription_status       | 10          | Statuts d'abonnement
manquants_users           | 0           | Dans auth mais pas dans users
manquants_subscription    | 0           | Dans auth mais pas dans subscription
```

### 2. Vérifier les triggers actifs

```sql
SELECT 
    trigger_name,
    event_object_table,
    action_timing || ' ' || string_agg(event_manipulation, ', ') as trigger_event
FROM information_schema.triggers
WHERE trigger_name IN (
    'trigger_sync_auth_user_complete',
    'trigger_sync_user_to_subscription'
)
GROUP BY trigger_name, event_object_table, action_timing;
```

### 3. Tester avec un nouvel utilisateur

Créer un nouveau compte via l'interface d'inscription, puis vérifier :

```sql
-- Remplacer 'email@example.com' par l'email du nouvel utilisateur
SELECT 
    au.id,
    au.email as "Email (auth)",
    u.email as "Email (users)",
    ss.email as "Email (subscription)",
    ss.is_active as "Actif",
    ss.subscription_type as "Type"
FROM auth.users au
LEFT JOIN public.users u ON u.id = au.id
LEFT JOIN public.subscription_status ss ON ss.user_id = au.id
WHERE au.email = 'email@example.com';
```

## 🔧 Maintenance

### Réparer les utilisateurs manquants

Si des utilisateurs sont manquants, exécuter :

```sql
SELECT * FROM repair_missing_users();
```

### Resynchroniser un utilisateur spécifique

```sql
-- Pour un utilisateur spécifique par email
DO $$
DECLARE
    v_user RECORD;
BEGIN
    SELECT * INTO v_user FROM auth.users WHERE email = 'email@example.com';
    
    IF v_user.id IS NOT NULL THEN
        -- Insérer/Mettre à jour dans users
        INSERT INTO public.users (id, first_name, last_name, email, created_at, updated_at)
        VALUES (
            v_user.id,
            COALESCE(v_user.raw_user_meta_data->>'first_name', split_part(v_user.email, '@', 1)),
            COALESCE(v_user.raw_user_meta_data->>'last_name', ''),
            v_user.email,
            v_user.created_at,
            NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email,
            updated_at = NOW();
        
        -- Insérer/Mettre à jour dans subscription_status
        INSERT INTO public.subscription_status (
            user_id, first_name, last_name, email, is_active, 
            subscription_type, notes, created_at, updated_at
        )
        VALUES (
            v_user.id,
            COALESCE(v_user.raw_user_meta_data->>'first_name', split_part(v_user.email, '@', 1)),
            COALESCE(v_user.raw_user_meta_data->>'last_name', ''),
            v_user.email,
            true,
            'free',
            'Resynchronisation manuelle',
            v_user.created_at,
            NOW()
        )
        ON CONFLICT (user_id) DO UPDATE SET
            email = EXCLUDED.email,
            updated_at = NOW();
        
        RAISE NOTICE 'Utilisateur % resynchronisé avec succès', v_user.email;
    ELSE
        RAISE NOTICE 'Utilisateur non trouvé';
    END IF;
END $$;
```

## 🐛 Dépannage

### Problème : Les triggers ne se déclenchent pas

**Vérifier que les triggers existent :**
```sql
SELECT * FROM pg_trigger 
WHERE tgname IN ('trigger_sync_auth_user_complete', 'trigger_sync_user_to_subscription');
```

**Solution :** Réappliquer le script SQL

### Problème : Erreur de permissions

**Symptôme :** `permission denied for table subscription_status`

**Solution :**
```sql
-- Donner les permissions nécessaires
GRANT INSERT, UPDATE ON public.subscription_status TO authenticated;
GRANT INSERT, UPDATE ON public.users TO authenticated;
```

### Problème : Contrainte de clé étrangère

**Symptôme :** `violates foreign key constraint`

**Vérifier les contraintes :**
```sql
SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'subscription_status';
```

**Solution :** S'assurer que la clé étrangère `user_id` pointe vers `auth.users(id)` ou `public.users(id)`

### Problème : Utilisateurs toujours manquants

**Diagnostic :**
```sql
-- Voir les utilisateurs non synchronisés
SELECT 
    au.id,
    au.email,
    au.created_at,
    EXISTS(SELECT 1 FROM public.users WHERE id = au.id) as in_users,
    EXISTS(SELECT 1 FROM public.subscription_status WHERE user_id = au.id) as in_subscription
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE id = au.id)
   OR NOT EXISTS (SELECT 1 FROM public.subscription_status WHERE user_id = au.id);
```

**Solution :** Exécuter `repair_missing_users()`

## 📝 Logs et Monitoring

Les logs de synchronisation apparaissent dans les logs Supabase avec le préfixe `[SYNC]` :

```
[SYNC START] User abc123... (email@example.com) - Début de synchronisation
[SYNC USERS] User abc123... (email@example.com) - Synchronisé vers table users
[SYNC SUBSCRIPTION] User abc123... (email@example.com) - Synchronisé vers subscription_status
[SYNC END] User abc123... (email@example.com) - Synchronisation terminée
```

Pour voir les logs dans Supabase Dashboard :
1. Aller dans **Logs** → **Postgres Logs**
2. Filtrer par "SYNC"

## ✅ Checklist de Validation

- [ ] Script SQL exécuté sans erreur
- [ ] `check_sync_status_detailed()` montre 0 utilisateurs manquants
- [ ] Les triggers sont actifs dans `pg_trigger`
- [ ] Un test avec un nouvel utilisateur fonctionne
- [ ] Les utilisateurs existants sont tous synchronisés
- [ ] Les logs montrent les événements de synchronisation

## 🎉 Résultat Final

Après l'application de cette correction :

1. ✅ **Chaque nouvel utilisateur** est automatiquement créé dans :
   - `auth.users` (Supabase Auth)
   - `public.users` (Application)
   - `subscription_status` (Gestion des accès)

2. ✅ **Tous les utilisateurs existants** sont synchronisés

3. ✅ **Les administrateurs** peuvent maintenant :
   - Voir tous les utilisateurs
   - Gérer leur statut d'abonnement
   - Activer/Désactiver les accès

4. ✅ **Outils de diagnostic** disponibles pour :
   - Vérifier l'état de synchronisation
   - Réparer les problèmes
   - Monitorer les événements

## 📞 Support

Si le problème persiste après avoir appliqué cette correction :

1. Vérifier les logs Supabase pour les erreurs
2. Exécuter `check_sync_status_detailed()` pour diagnostiquer
3. Vérifier les permissions RLS sur les tables
4. Consulter la section Dépannage ci-dessus

---

**Date de création :** 2025-10-09  
**Version :** 1.0  
**Auteur :** Système de correction automatique

