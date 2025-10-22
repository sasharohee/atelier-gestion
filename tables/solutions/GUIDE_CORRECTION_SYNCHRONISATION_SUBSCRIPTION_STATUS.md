# Guide - Correction Synchronisation Subscription_Status

## 🚨 Problème Identifié

**Erreur** : `GET .../subscription_status?... 406 (Not Acceptable)` et `PGRST116` (`The result contains 0 rows`)

### Cause
L'utilisateur `test15@yopmail.com` (et potentiellement d'autres) n'existe pas dans la table `subscription_status`, causant l'erreur `406` et `PGRST116` lors de la récupération du statut d'abonnement.

### Logs d'Erreur
```
GET https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/subscription_status?select=*&user_id=eq.71e0baac-dd6f-4b3a-890c-70907dc03d8a 406 (Not Acceptable)
❌ Erreur subscription_status: {code: 'PGRST116', details: 'The result contains 0 rows', hint: null, message: 'Cannot coerce the result to a single JSON object'}
⚠️ Utilisateur non trouvé dans subscription_status - Création d'un statut par défaut
```

## ✅ Solution Complète

### **Exécution du Script de Correction**

Exécuter le script de correction :

```sql
-- Copier et exécuter correction_synchronisation_subscription_status.sql
```

Ce script va :
- ✅ **Diagnostiquer** les utilisateurs manquants dans `subscription_status`
- ✅ **Ajouter** tous les utilisateurs manquants automatiquement
- ✅ **Corriger** spécifiquement `test15@yopmail.com`
- ✅ **Recréer** le trigger de synchronisation
- ✅ **Corriger** les politiques RLS
- ✅ **Tester** la récupération des données

## 🔧 Fonctionnalités du Script

### **1. Diagnostic des Utilisateurs Manquants**

```sql
-- Vérifier les utilisateurs dans auth.users qui ne sont pas dans subscription_status
SELECT 
  'UTILISATEURS MANQUANTS DANS SUBSCRIPTION_STATUS' as info,
  au.id as user_id,
  au.email,
  au.raw_user_meta_data->>'role' as role,
  au.created_at
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = au.id
)
ORDER BY au.created_at;
```

### **2. Ajout Automatique des Utilisateurs Manquants**

```sql
-- Insérer tous les utilisateurs manquants dans subscription_status
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
  au.id as user_id,
  COALESCE(au.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
  COALESCE(au.raw_user_meta_data->>'last_name', 'Test') as last_name,
  au.email,
  CASE 
    WHEN au.raw_user_meta_data->>'role' = 'admin' THEN true
    WHEN au.email = 'srohee32@gmail.com' THEN true
    WHEN au.email = 'repphonereparation@gmail.com' THEN true
    ELSE false
  END as is_active,
  CASE 
    WHEN au.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
    WHEN au.email = 'srohee32@gmail.com' THEN 'premium'
    WHEN au.email = 'repphonereparation@gmail.com' THEN 'premium'
    ELSE 'free'
  END as subscription_type,
  'Compte synchronisé automatiquement',
  COALESCE(au.created_at, NOW()) as created_at,
  NOW() as updated_at,
  CASE 
    WHEN au.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
    WHEN au.email = 'srohee32@gmail.com' THEN 'ACTIF'
    WHEN au.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
    ELSE 'INACTIF'
  END as status
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = au.id
);
```

### **3. Correction Spécifique pour Test15@Yopmail.com**

```sql
-- Vérifier spécifiquement l'utilisateur test15@yopmail.com
SELECT 
  'VÉRIFICATION TEST15@YOPMAIL.COM' as info,
  au.id as user_id,
  au.email,
  au.raw_user_meta_data->>'role' as role,
  au.created_at,
  CASE 
    WHEN ss.user_id IS NOT NULL THEN 'PRÉSENT'
    ELSE 'MANQUANT'
  END as statut_subscription
FROM auth.users au
LEFT JOIN subscription_status ss ON au.id = ss.user_id
WHERE au.email = 'test15@yopmail.com';
```

### **4. Recréation du Trigger**

```sql
-- Recréer le trigger avec une gestion d'erreurs améliorée
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
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
      WHEN NEW.email = 'srohee32@gmail.com' THEN 'premium'
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'premium'
      ELSE 'free'
    END as subscription_type,
    'Compte créé automatiquement par trigger',
    COALESCE(NEW.created_at, NOW()) as created_at,
    NOW() as updated_at,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
      WHEN NEW.email = 'srohee32@gmail.com' THEN 'ACTIF'
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
      ELSE 'INACTIF'
    END as status
  WHERE NOT EXISTS (
    SELECT 1 FROM subscription_status ss WHERE ss.user_id = NEW.id
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, log l'erreur mais ne pas faire échouer l'inscription
    RAISE WARNING 'Erreur lors de la synchronisation vers subscription_status: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### **5. Correction des Politiques RLS**

```sql
-- Créer des politiques simples pour subscription_status
CREATE POLICY "Users can view their own subscription_status" ON subscription_status
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can view all subscription_status" ON subscription_status
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

-- Politique spéciale pour permettre les insertions par trigger
CREATE POLICY "Allow trigger insert" ON subscription_status
  FOR INSERT WITH CHECK (true);
```

## 🧪 Tests

### Test Automatique
Le script inclut des vérifications automatiques qui :
1. Diagnostique les utilisateurs manquants
2. Ajoute tous les utilisateurs manquants
3. Vérifie spécifiquement `test15@yopmail.com`
4. Recrée le trigger de synchronisation
5. Corrige les politiques RLS
6. Teste la récupération des données

### Test Manuel
1. **Vérifier** que `test15@yopmail.com` existe dans `subscription_status`
2. **Confirmer** que l'erreur `406` ne se reproduit plus
3. **Tester** la récupération du statut d'abonnement
4. **Vérifier** que tous les utilisateurs sont synchronisés

## 📊 Résultats Attendus

### Après Exécution du Script
```
UTILISATEURS MANQUANTS DANS SUBSCRIPTION_STATUS | user_id | email | role | created_at
------------------------------------------------|---------|-------|------|-----------
UTILISATEURS MANQUANTS DANS SUBSCRIPTION_STATUS | 71e0baac-dd6f-4b3a-890c-70907dc03d8a | test15@yopmail.com | technician | 2025-08-25 15:30:00

COMPTAGE UTILISATEURS MANQUANTS | nombre_utilisateurs_manquants
--------------------------------|------------------------------
COMPTAGE UTILISATEURS MANQUANTS | 1

VÉRIFICATION SYNCHRONISATION COMPLÈTE | nombre_utilisateurs_auth | nombre_utilisateurs_subscription | difference
--------------------------------------|---------------------------|----------------------------------|------------
VÉRIFICATION SYNCHRONISATION COMPLÈTE | 5 | 5 | 0

VÉRIFICATION TEST15@YOPMAIL.COM | user_id | email | role | created_at | statut_subscription
--------------------------------|---------|-------|------|------------|-------------------
VÉRIFICATION TEST15@YOPMAIL.COM | 71e0baac-dd6f-4b3a-890c-70907dc03d8a | test15@yopmail.com | technician | 2025-08-25 15:30:00 | PRÉSENT

TEST RÉCUPÉRATION TEST15@YOPMAIL.COM | user_id | email | first_name | last_name | is_active | subscription_type | status | created_at
-------------------------------------|---------|-------|------------|-----------|-----------|------------------|--------|------------
TEST RÉCUPÉRATION TEST15@YOPMAIL.COM | 71e0baac-dd6f-4b3a-890c-70907dc03d8a | test15@yopmail.com | Utilisateur | Test | false | free | INACTIF | 2025-08-25 15:30:00

TEST RÉCUPÉRATION TOUS UTILISATEURS | nombre_utilisateurs_subscription
-----------------------------------|----------------------------------
TEST RÉCUPÉRATION TOUS UTILISATEURS | 5

CORRECTION SYNCHRONISATION SUBSCRIPTION_STATUS TERMINÉE | Tous les utilisateurs sont maintenant synchronisés avec subscription_status
```

### Dans l'Application
- ✅ **Plus d'erreur `406 (Not Acceptable)`**
- ✅ **Plus d'erreur `PGRST116`**
- ✅ **Récupération du statut d'abonnement réussie**
- ✅ **Tous les utilisateurs synchronisés**
- ✅ **Trigger de synchronisation fonctionnel**

## 🚀 Instructions d'Exécution

### Ordre d'Exécution
1. **Exécuter** `correction_synchronisation_subscription_status.sql`
2. **Vérifier** que tous les utilisateurs sont synchronisés
3. **Confirmer** que `test15@yopmail.com` existe dans `subscription_status`
4. **Tester** la récupération du statut d'abonnement
5. **Vérifier** que l'erreur `406` ne se reproduit plus

### Vérification
- ✅ **Tous les utilisateurs dans `auth.users` sont dans `subscription_status`**
- ✅ **Plus d'erreur `406 (Not Acceptable)`**
- ✅ **Plus d'erreur `PGRST116`**
- ✅ **Récupération du statut d'abonnement réussie**
- ✅ **Trigger de synchronisation fonctionnel**
- ✅ **Politiques RLS correctes**

## ✅ Checklist de Validation

- [ ] Script de correction exécuté
- [ ] Tous les utilisateurs manquants ajoutés
- [ ] `test15@yopmail.com` présent dans `subscription_status`
- [ ] Plus d'erreur `406 (Not Acceptable)`
- [ ] Plus d'erreur `PGRST116`
- [ ] Récupération du statut d'abonnement réussie
- [ ] Trigger de synchronisation recréé
- [ ] Politiques RLS corrigées
- [ ] Synchronisation complète entre `auth.users` et `subscription_status`

## 🔄 Maintenance

### Vérification de la Synchronisation
```sql
-- Vérifier que tous les utilisateurs sont synchronisés
SELECT 
  COUNT(*) as nombre_utilisateurs_auth,
  (SELECT COUNT(*) FROM subscription_status) as nombre_utilisateurs_subscription,
  COUNT(*) - (SELECT COUNT(*) FROM subscription_status) as difference
FROM auth.users;
```

### Surveillance des Erreurs
```sql
-- Vérifier les utilisateurs manquants
SELECT 
  au.id as user_id,
  au.email,
  au.raw_user_meta_data->>'role' as role
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = au.id
);
```

---

**Note** : Cette solution corrige définitivement l'erreur `406` et `PGRST116` en synchronisant tous les utilisateurs avec la table `subscription_status`.
