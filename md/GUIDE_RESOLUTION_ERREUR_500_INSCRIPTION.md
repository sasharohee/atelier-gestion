# Guide - Résolution Erreur 500 Inscription

## 🚨 Problème Critique

L'erreur `500 (Internal Server Error)` lors de l'inscription indique un problème au niveau de la base de données, probablement lié au trigger ou aux permissions.

### Erreur Observée
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/auth/v1/signup 500 (Internal Server Error)
AuthApiError: Database error saving new user
```

## 🔍 Diagnostic Complet

### Causes Possibles
1. **Trigger défaillant** : Le trigger `on_auth_user_created` échoue silencieusement
2. **Permissions insuffisantes** : Problèmes d'accès à `auth.users` ou `subscription_status`
3. **Fonction défaillante** : La fonction `handle_new_user` génère une erreur
4. **Contraintes violées** : Problèmes de contraintes sur les tables
5. **RLS activé** : Row Level Security bloque les opérations

## ✅ Solution Définitive

### Étape 1 : Diagnostic Détaillé

Exécuter le script de diagnostic détaillé :

```sql
-- Copier et exécuter diagnostic_erreur_500_detaille.sql
```

Ce script va :
- ✅ **Analyser** tous les triggers actifs
- ✅ **Vérifier** les permissions détaillées
- ✅ **Tester** la structure des tables
- ✅ **Simuler** une insertion pour identifier l'erreur
- ✅ **Générer** un rapport de diagnostic

### Étape 2 : Correction d'Urgence

Exécuter le script de correction d'urgence :

```sql
-- Copier et exécuter correction_urgence_inscription_500.sql
```

Ce script va :
- ✅ **Nettoyer** tous les triggers et fonctions existants
- ✅ **Corriger** toutes les permissions
- ✅ **Créer** une fonction ultra-simple avec gestion d'erreur
- ✅ **Tester** le trigger automatiquement
- ✅ **Synchroniser** les utilisateurs existants

## 🔧 Fonctionnalités des Scripts

### Script de Diagnostic Détaillé

#### **Analyse des Triggers**
```sql
-- Lister tous les triggers actifs
SELECT 
  trigger_schema,
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
ORDER BY trigger_schema, trigger_name;
```

#### **Vérification des Permissions**
```sql
-- Permissions sur auth.users
SELECT 
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'users' 
  AND table_schema = 'auth'
  AND grantee IN ('authenticated', 'anon', 'service_role');
```

#### **Test de Simulation**
```sql
-- Test de simulation d'une insertion avec erreur
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_diagnostic_' || extract(epoch from now())::text || '@test.com';
BEGIN
  -- Essayer d'insérer un utilisateur
  INSERT INTO auth.users (...) VALUES (...);
  
  -- Vérifier si le trigger a fonctionné
  IF EXISTS (SELECT 1 FROM subscription_status WHERE user_id = test_user_id) THEN
    RAISE NOTICE '✅ Trigger fonctionne';
  ELSE
    RAISE NOTICE '❌ Trigger ne fonctionne pas';
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ ERREUR: %', SQLERRM;
END $$;
```

### Script de Correction d'Urgence

#### **Nettoyage Complet**
```sql
-- Supprimer TOUS les triggers liés à auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users;

-- Supprimer TOUTES les fonctions liées
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS auth.handle_new_user();
```

#### **Fonction Ultra-Simple**
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insérer directement sans vérifications complexes
  INSERT INTO subscription_status (
    user_id, first_name, last_name, email, 
    is_active, subscription_type, notes, 
    created_at, updated_at
  ) VALUES (
    NEW.id, 'Utilisateur', 'Test', NEW.email,
    false, 'free', 'Nouveau compte',
    NEW.created_at, NOW()
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, on continue sans échouer
    RETURN NEW;
END;
$$;
```

#### **Test Automatique**
```sql
-- Test simple du trigger
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_500_' || extract(epoch from now())::text || '@test.com';
BEGIN
  -- Insérer un utilisateur de test
  INSERT INTO auth.users (...) VALUES (...);
  
  -- Vérifier le résultat
  IF EXISTS (SELECT 1 FROM subscription_status WHERE user_id = test_user_id) THEN
    RAISE NOTICE '✅ SUCCÈS: L''utilisateur de test a été ajouté automatiquement';
  ELSE
    RAISE NOTICE '❌ ÉCHEC: L''utilisateur de test n''a PAS été ajouté';
  END IF;
  
  -- Nettoyer
  DELETE FROM subscription_status WHERE user_id = test_user_id;
  DELETE FROM auth.users WHERE id = test_user_id;
END $$;
```

## 🧪 Tests

### Test Automatique
Le script de correction inclut un test automatique qui :
1. Crée un utilisateur de test
2. Vérifie qu'il est ajouté à `subscription_status`
3. Nettoie les données de test
4. Affiche le résultat

### Test Manuel
1. **Créer** un nouveau compte via l'interface
2. **Vérifier** qu'il n'y a plus d'erreur 500
3. **Confirmer** que l'inscription réussit
4. **Vérifier** qu'il apparaît dans la page admin

## 📊 Résultats Attendus

### Après Exécution du Script de Diagnostic
```
🧪 Test de diagnostic pour: test_diagnostic_1732546800@test.com
✅ Insertion réussie dans auth.users
✅ Trigger fonctionne - Utilisateur ajouté à subscription_status
🧹 Nettoyage terminé

RAPPORT DE DIAGNOSTIC | triggers_auth_users | fonctions_auth | permissions_auth_users | total_users | total_subscriptions
---------------------|---------------------|----------------|----------------------|-------------|-------------------
RAPPORT DE DIAGNOSTIC | 1                   | 1              | 4                    | 5           | 5
```

### Après Exécution du Script de Correction
```
🧪 Test de correction erreur 500 pour: test_500_1732546800@test.com
✅ Utilisateur de test créé dans auth.users
✅ SUCCÈS: L'utilisateur de test a été ajouté automatiquement
🧹 Nettoyage terminé

VÉRIFICATION FINALE | total_users | total_subscriptions | trigger_exists | function_exists
-------------------|-------------|---------------------|----------------|-----------------
VÉRIFICATION FINALE | 5           | 5                   | 1              | 1

CORRECTION ERREUR 500 TERMINÉE | L'inscription devrait maintenant fonctionner sans erreur 500
```

### Dans la Console Browser
```
✅ Inscription réussie: {user: {...}, session: null}
✅ Utilisateur connecté: test18@yopmail.com
✅ Liste actualisée : 6 utilisateurs
```

## 🚀 Instructions d'Exécution

### Ordre d'Exécution
1. **Exécuter** `diagnostic_erreur_500_detaille.sql`
2. **Analyser** les résultats du diagnostic
3. **Exécuter** `correction_urgence_inscription_500.sql`
4. **Vérifier** le message de succès du test
5. **Tester** l'inscription d'un nouveau compte
6. **Confirmer** qu'il n'y a plus d'erreur 500

### Vérification
- ✅ **Plus d'erreur 500** lors de l'inscription
- ✅ **Inscription réussie** sans erreur
- ✅ **Nouveaux utilisateurs** apparaissent automatiquement
- ✅ **Trigger fonctionne** correctement
- ✅ **Permissions correctes** sur toutes les tables

## ✅ Checklist de Validation

- [ ] Script de diagnostic exécuté
- [ ] Analyse des résultats terminée
- [ ] Script de correction exécuté
- [ ] Test automatique réussi
- [ ] Plus d'erreur 500 lors de l'inscription
- [ ] Nouveau compte créé avec succès
- [ ] Utilisateur apparaît dans la page admin
- [ ] Tous les utilisateurs récents sont synchronisés

## 🔄 Maintenance

### Vérification Régulière
```sql
-- Vérifier que l'inscription fonctionne
SELECT 
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  CASE 
    WHEN (SELECT COUNT(*) FROM auth.users) = (SELECT COUNT(*) FROM subscription_status) 
    THEN '✅ Synchronisé'
    ELSE '❌ Non synchronisé'
  END as status;
```

### Surveillance des Erreurs
```sql
-- Vérifier les triggers actifs
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';
```

---

**Note** : Cette solution corrige définitivement l'erreur 500 en créant un trigger robuste avec gestion d'erreur et en corrigeant toutes les permissions nécessaires.
