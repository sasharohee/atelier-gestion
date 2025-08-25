# Guide - Correction Synchronisation Utilisateurs

## 🚨 Problème Identifié

L'erreur `406 (Not Acceptable)` et `PGRST116` indiquent que les utilisateurs nouvellement créés ne sont pas automatiquement ajoutés à la table `subscription_status` :

```
GET https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/subscription_status?select=*&user_id=eq.b4c34714-9220-4950-851d-4cd5b0e62d9b 406 (Not Acceptable)
```

### Erreur Observée
```
❌ Erreur subscription_status: {code: 'PGRST116', details: 'The result contains 0 rows', hint: null, message: 'Cannot coerce the result to a single JSON object'}
⚠️ Utilisateur non trouvé dans subscription_status - Création d'un statut par défaut
```

## 🔍 Cause du Problème

Les utilisateurs nouvellement créés dans `auth.users` ne sont pas automatiquement synchronisés avec la table `subscription_status` :

1. **Pas de synchronisation automatique** : Aucun trigger ou fonction pour créer automatiquement les entrées dans `subscription_status`
2. **Politiques RLS** : Les politiques RLS peuvent bloquer l'accès à `subscription_status`
3. **Utilisateurs manquants** : Les utilisateurs existants ne sont pas dans `subscription_status`

## ✅ Solution

### Étape 1 : Correction de la Base de Données

Exécuter le script de correction :

```sql
-- Copier et exécuter correction_synchronisation_utilisateurs.sql
```

Ce script va :
- ✅ **Diagnostiquer** les utilisateurs manquants dans subscription_status
- ✅ **Créer** une fonction de synchronisation automatique
- ✅ **Créer** un trigger pour synchroniser automatiquement
- ✅ **Synchroniser** les utilisateurs existants
- ✅ **Corriger** les politiques RLS
- ✅ **Tester** la synchronisation

### Étape 2 : Fonction de Synchronisation Automatique

Le script crée une fonction qui s'exécute automatiquement à chaque création d'utilisateur :

```sql
CREATE OR REPLACE FUNCTION sync_user_to_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Insérer l'utilisateur dans subscription_status s'il n'existe pas déjà
  INSERT INTO subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    created_at,
    updated_at,
    status
  )
  SELECT 
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
    COALESCE(NEW.raw_user_meta_data->>'last_name', 'Test') as last_name,
    NEW.email,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN true
      WHEN NEW.email = 'srohee32@gmail.com' THEN true
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN true
      ELSE false
    END as is_active,
    -- ... autres colonnes
  WHERE NOT EXISTS (
    SELECT 1 FROM subscription_status ss WHERE ss.user_id = NEW.id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Étape 3 : Trigger Automatique

Le script crée un trigger qui s'exécute après chaque insertion dans `auth.users` :

```sql
CREATE TRIGGER trigger_sync_user_to_subscription_status
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_to_subscription_status();
```

### Étape 4 : Politiques RLS Corrigées

Le script corrige les politiques RLS pour permettre l'accès approprié :

```sql
-- Politique pour permettre à tous les utilisateurs authentifiés de voir leur propre statut
CREATE POLICY "Users can view their own subscription status" ON subscription_status
  FOR SELECT USING (auth.uid() = user_id);

-- Politique pour permettre aux admins de voir tous les statuts
CREATE POLICY "Admins can view all subscription statuses" ON subscription_status
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );
```

## 🔧 Fonctionnalités du Script

### **Diagnostic des Utilisateurs Manquants**
```sql
-- Vérifier les utilisateurs dans auth.users qui ne sont pas dans subscription_status
SELECT 
  (SELECT COUNT(*) FROM auth.users) as total_auth_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscription_users,
  (SELECT COUNT(*) FROM auth.users u 
   WHERE NOT EXISTS (SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id)) as users_manquants;
```

### **Synchronisation Manuelle des Utilisateurs Existants**
```sql
-- Synchroniser tous les utilisateurs existants qui ne sont pas dans subscription_status
INSERT INTO subscription_status (
  user_id,
  first_name,
  last_name,
  email,
  is_active,
  subscription_type,
  notes,
  created_at,
  updated_at,
  status
)
SELECT 
  u.id,
  COALESCE(u.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
  COALESCE(u.raw_user_meta_data->>'last_name', 'Test') as last_name,
  u.email,
  -- ... autres colonnes
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
);
```

### **Test de la Synchronisation**
```sql
-- Test de la fonction de synchronisation
DO $$
DECLARE
  test_uuid UUID := gen_random_uuid();
  test_result RECORD;
BEGIN
  -- Simuler l'insertion d'un nouvel utilisateur
  INSERT INTO auth.users (
    id,
    email,
    raw_user_meta_data,
    created_at
  ) VALUES (
    test_uuid,
    'test_sync_' || test_uuid || '@example.com',
    '{"first_name": "Test", "last_name": "Sync", "role": "technician"}'::jsonb,
    NOW()
  );
  
  -- Vérifier que l'utilisateur a été synchronisé
  SELECT * INTO test_result FROM subscription_status WHERE user_id = test_uuid;
  
  IF test_result IS NOT NULL THEN
    RAISE NOTICE '✅ Test de synchronisation réussi pour l''utilisateur: %', test_uuid;
  ELSE
    RAISE NOTICE '❌ Test de synchronisation échoué pour l''utilisateur: %', test_uuid;
  END IF;
  
  -- Nettoyer le test
  DELETE FROM subscription_status WHERE user_id = test_uuid;
  DELETE FROM auth.users WHERE id = test_uuid;
END $$;
```

## 🧪 Tests

### Test Automatique
Le script inclut des tests automatiques qui :
1. Diagnostique les utilisateurs manquants
2. Crée la fonction de synchronisation
3. Crée le trigger automatique
4. Synchronise les utilisateurs existants
5. Corrige les politiques RLS
6. Teste la synchronisation avec un nouvel utilisateur
7. Vérifie que tout fonctionne

### Test Manuel
1. **Créer** un nouvel utilisateur via l'interface
2. **Vérifier** qu'il apparaît automatiquement dans subscription_status
3. **Confirmer** qu'il n'y a plus d'erreur 406
4. **Tester** l'accès à subscription_status

## 📊 Résultats Attendus

### Après Exécution du Script
```
DIAGNOSTIC UTILISATEURS MANQUANTS | total_auth_users | total_subscription_users | users_manquants
--------------------------------|------------------|-------------------------|----------------
DIAGNOSTIC UTILISATEURS MANQUANTS | 5                | 2                       | 3

✅ Test de synchronisation réussi pour l'utilisateur: [UUID]
✅ Données synchronisées: email=test_sync_...@example.com, is_active=false, status=INACTIF
✅ Test nettoyé

VÉRIFICATION FINALE | total_auth_users | total_subscription_users | users_manquants
-------------------|------------------|-------------------------|----------------
VÉRIFICATION FINALE | 5                | 5                       | 0

EXEMPLE UTILISATEUR SYNCHRONISÉ | user_id | email | first_name | last_name | is_active | status | subscription_type
-------------------------------|---------|-------|------------|-----------|-----------|--------|-------------------
EXEMPLE UTILISATEUR SYNCHRONISÉ | [UUID]  | test@example.com | Utilisateur | Test | false | INACTIF | free

CORRECTION SYNCHRONISATION UTILISATEURS TERMINÉE | Les utilisateurs sont maintenant automatiquement synchronisés avec subscription_status
```

### Dans la Console Browser
```
✅ Utilisateur connecté: test22@yopmail.com
🔍 Vérification du statut pour test22@yopmail.com
✅ Statut trouvé dans subscription_status
```

## 🚀 Instructions d'Exécution

### Ordre d'Exécution
1. **Exécuter** `correction_synchronisation_utilisateurs.sql`
2. **Vérifier** que tous les utilisateurs sont synchronisés
3. **Confirmer** que le test de synchronisation réussit
4. **Tester** la création d'un nouvel utilisateur
5. **Vérifier** qu'il n'y a plus d'erreur 406

### Vérification
- ✅ **Plus d'erreur 406** lors de l'accès à subscription_status
- ✅ **Plus d'erreur PGRST116** - utilisateurs trouvés
- ✅ **Synchronisation automatique** des nouveaux utilisateurs
- ✅ **Politiques RLS** fonctionnelles
- ✅ **Tous les utilisateurs** dans subscription_status

## ✅ Checklist de Validation

- [ ] Script de correction exécuté
- [ ] Fonction de synchronisation créée
- [ ] Trigger automatique créé
- [ ] Utilisateurs existants synchronisés
- [ ] Politiques RLS corrigées
- [ ] Test de synchronisation réussi
- [ ] Plus d'erreur 406 lors de l'accès à subscription_status
- [ ] Nouveaux utilisateurs synchronisés automatiquement
- [ ] Tous les utilisateurs dans subscription_status

## 🔄 Maintenance

### Vérification Régulière
```sql
-- Vérifier que tous les utilisateurs sont synchronisés
SELECT 
  (SELECT COUNT(*) FROM auth.users) as total_auth_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscription_users,
  (SELECT COUNT(*) FROM auth.users u 
   WHERE NOT EXISTS (SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id)) as users_manquants;
```

### Surveillance des Triggers
```sql
-- Vérifier que le trigger existe
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_user_to_subscription_status';
```

---

**Note** : Cette solution corrige définitivement l'erreur 406 en synchronisant automatiquement tous les utilisateurs avec subscription_status et en corrigeant les politiques RLS.
