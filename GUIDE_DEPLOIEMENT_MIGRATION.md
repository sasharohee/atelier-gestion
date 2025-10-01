# 🚀 Guide de Déploiement - Migration de Base de Données de Production

## 📋 Vue d'ensemble

Ce guide accompagne le script de migration `MIGRATION_PRODUCTION.sql` pour déployer le système d'authentification robuste en production.

## ⚠️ Prérequis et Sécurité

### Avant de commencer
1. **Sauvegarde complète** : Effectuez une sauvegarde complète de votre base de données
2. **Environnement de test** : Testez d'abord sur un environnement de staging
3. **Maintenance** : Planifiez une fenêtre de maintenance si nécessaire
4. **Équipe** : Informez votre équipe de développement

### Vérifications préalables
```sql
-- Vérifier l'environnement
SELECT current_database(), current_user, version();

-- Vérifier l'espace disque disponible
SELECT pg_size_pretty(pg_database_size(current_database()));
```

## 🔧 Étapes de Déploiement

### Phase 1: Préparation
1. **Connectez-vous à votre base de données Supabase**
2. **Ouvrez l'éditeur SQL dans le dashboard Supabase**
3. **Vérifiez que vous êtes sur l'environnement de production**

### Phase 2: Exécution de la Migration
1. **Copiez le contenu de `MIGRATION_PRODUCTION.sql`**
2. **Collez-le dans l'éditeur SQL**
3. **Exécutez le script complet**

### Phase 3: Vérification Post-Migration
```sql
-- Vérifier que tous les composants sont en place
SELECT 
    'Table users' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') 
         THEN '✅ Créée' 
         ELSE '❌ Manquante' 
    END as status;
```

## 🧪 Tests de Validation

### Test 1: Inscription d'un nouvel utilisateur
```sql
-- Test d'inscription
SELECT public.signup_user_complete(
    'test-production@example.com',
    'TestPass123!',
    'Test',
    'Production',
    'technician'
) as result;
```

### Test 2: Connexion
```sql
-- Test de connexion
SELECT public.login_user_complete(
    'test-production@example.com',
    'TestPass123!'
) as result;
```

### Test 3: Récupération du profil
```sql
-- Test de récupération du profil
SELECT public.get_user_profile() as result;
```

### Nettoyage des tests
```sql
-- Supprimer l'utilisateur de test
DELETE FROM auth.users WHERE email = 'test-production@example.com';
DELETE FROM public.users WHERE email = 'test-production@example.com';
```

## 🔍 Monitoring Post-Migration

### Vérifications à effectuer
1. **Logs d'erreur** : Surveillez les logs Supabase pour les erreurs
2. **Performance** : Vérifiez que les requêtes s'exécutent rapidement
3. **Utilisateurs** : Testez avec de vrais utilisateurs
4. **Emails** : Vérifiez que les emails de confirmation fonctionnent

### Requêtes de monitoring
```sql
-- Statistiques des utilisateurs
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_users,
    COUNT(CASE WHEN last_login_at > NOW() - INTERVAL '7 days' THEN 1 END) as recent_logins
FROM public.users;

-- Erreurs récentes (si disponibles)
SELECT * FROM pg_stat_user_functions 
WHERE funcname LIKE '%user%' 
ORDER BY calls DESC;
```

## 🛠️ Fonctions Disponibles

### Fonctions d'authentification
- `public.signup_user_complete()` - Inscription complète avec contournement
- `public.login_user_complete()` - Connexion complète avec contournement
- `public.sync_user_to_public_table()` - Synchronisation manuelle

### Fonctions utilitaires
- `public.get_user_profile()` - Récupération du profil utilisateur
- `public.get_all_users()` - Liste des utilisateurs (admins uniquement)
- `public.update_user_metadata()` - Mise à jour des métadonnées

## 🔒 Sécurité

### Politiques RLS activées
- Les utilisateurs ne peuvent voir que leurs propres données
- Les admins peuvent voir tous les utilisateurs
- Les techniciens ont des permissions étendues

### Fonctions sécurisées
- Toutes les fonctions utilisent `SECURITY DEFINER`
- Gestion d'erreur robuste
- Validation des permissions

## 🚨 Dépannage

### Problèmes courants

#### Erreur: "Table users already exists"
```sql
-- Solution: La table existe déjà, c'est normal
-- La migration utilisera CREATE TABLE IF NOT EXISTS
```

#### Erreur: "Function already exists"
```sql
-- Solution: Les fonctions sont remplacées avec CREATE OR REPLACE
-- C'est le comportement attendu
```

#### Erreur: "Permission denied"
```sql
-- Vérifiez que vous êtes connecté avec un utilisateur ayant les permissions
-- Utilisez le service role key si nécessaire
```

### Rollback (en cas de problème)
```sql
-- ATTENTION: Ceci supprimera toutes les données utilisateur
-- À utiliser uniquement en cas de problème majeur

-- Supprimer les fonctions
DROP FUNCTION IF EXISTS public.signup_user_complete;
DROP FUNCTION IF EXISTS public.login_user_complete;
DROP FUNCTION IF EXISTS public.sync_user_to_public_table;
DROP FUNCTION IF EXISTS public.get_user_profile;
DROP FUNCTION IF EXISTS public.get_all_users;
DROP FUNCTION IF EXISTS public.update_user_metadata;

-- Supprimer le trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Supprimer la fonction de trigger
DROP FUNCTION IF EXISTS public.handle_new_user;

-- Supprimer la table (ATTENTION: Supprime toutes les données)
-- DROP TABLE IF EXISTS public.users CASCADE;
```

## 📞 Support

### En cas de problème
1. **Vérifiez les logs** dans le dashboard Supabase
2. **Testez les fonctions** une par une
3. **Contactez l'équipe** de développement
4. **Consultez la documentation** Supabase

### Ressources utiles
- [Documentation Supabase Auth](https://supabase.com/docs/guides/auth)
- [Documentation RLS](https://supabase.com/docs/guides/auth/row-level-security)
- [Documentation PostgreSQL](https://www.postgresql.org/docs/)

## ✅ Checklist Post-Migration

- [ ] Migration exécutée sans erreur
- [ ] Tous les composants vérifiés (table, trigger, fonctions)
- [ ] Tests d'inscription et de connexion réussis
- [ ] Emails de confirmation fonctionnels
- [ ] Monitoring en place
- [ ] Équipe informée des changements
- [ ] Documentation mise à jour

## 🎉 Conclusion

Une fois la migration terminée avec succès, votre système d'authentification sera :
- ✅ Robuste et résistant aux erreurs
- ✅ Sécurisé avec RLS
- ✅ Optimisé pour les performances
- ✅ Prêt pour la production

**Félicitations ! Votre système d'authentification est maintenant opérationnel en production.**
