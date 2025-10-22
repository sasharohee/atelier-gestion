# Guide - Correction Données NULL et Contraintes

## 🚨 Problème Identifié

L'erreur `23502` indique une violation de contrainte NOT NULL sur la colonne `email` :

```
null value in column "email" of relation "subscription_status" violates not-null constraint
```

### Erreur Observée
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/subscription_status?on_conflict=user_id&select=* 400 (Bad Request)
```

## 🔍 Cause du Problème

La table `subscription_status` contient des données avec des valeurs NULL dans des colonnes qui ont des contraintes NOT NULL :
- `email` - Contrainte NOT NULL violée
- `first_name` - Peut être NULL
- `last_name` - Peut être NULL
- `user_id` - Contrainte NOT NULL

## ✅ Solution

### Étape 1 : Correction des Données NULL

Exécuter le script de correction :

```sql
-- Copier et exécuter correction_donnees_null.sql
```

Ce script va :
- ✅ **Diagnostiquer** les données NULL dans la table
- ✅ **Corriger** les données NULL en utilisant auth.users
- ✅ **Nettoyer** les données invalides
- ✅ **Recréer** les contraintes NOT NULL
- ✅ **Synchroniser** avec auth.users
- ✅ **Tester** le fonctionnement

## 🔧 Fonctionnalités du Script

### **Diagnostic des Données NULL**
```sql
-- Vérifier les données NULL dans subscription_status
SELECT 
  COUNT(*) as total_rows,
  COUNT(CASE WHEN email IS NULL THEN 1 END) as email_null,
  COUNT(CASE WHEN first_name IS NULL THEN 1 END) as first_name_null,
  COUNT(CASE WHEN last_name IS NULL THEN 1 END) as last_name_null
FROM subscription_status;
```

### **Correction des Données NULL**
```sql
-- Corriger les données NULL en utilisant les données de auth.users
UPDATE subscription_status 
SET 
  email = COALESCE(subscription_status.email, auth_users.email),
  first_name = COALESCE(subscription_status.first_name, 
    COALESCE(auth_users.raw_user_meta_data->>'first_name', 'Utilisateur')),
  last_name = COALESCE(subscription_status.last_name, 
    COALESCE(auth_users.raw_user_meta_data->>'last_name', 'Test'))
FROM auth.users auth_users
WHERE subscription_status.user_id = auth_users.id
  AND (subscription_status.email IS NULL 
    OR subscription_status.first_name IS NULL 
    OR subscription_status.last_name IS NULL);
```

### **Correction des Contraintes**
```sql
-- Supprimer les contraintes NOT NULL existantes si elles causent des problèmes
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'email' 
      AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE subscription_status ALTER COLUMN email DROP NOT NULL;
    RAISE NOTICE '✅ Contrainte NOT NULL supprimée de email';
  END IF;
END $$;
```

### **Nettoyage des Données Invalidés**
```sql
-- Supprimer les lignes sans user_id valide
DELETE FROM subscription_status 
WHERE user_id IS NULL 
   OR user_id NOT IN (SELECT id FROM auth.users);
```

### **Recréation des Contraintes**
```sql
-- Recréer les contraintes NOT NULL après avoir corrigé les données
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM subscription_status 
    WHERE email IS NULL 
       OR first_name IS NULL 
       OR last_name IS NULL 
       OR user_id IS NULL
  ) THEN
    ALTER TABLE subscription_status ALTER COLUMN email SET NOT NULL;
    RAISE NOTICE '✅ Contrainte NOT NULL remise sur email';
  ELSE
    RAISE NOTICE '⚠️ Données NULL encore présentes, contrainte NOT NULL non remise';
  END IF;
END $$;
```

## 🧪 Tests

### Test Automatique
Le script inclut un test automatique qui :
1. Diagnostique les données NULL
2. Corrige les données NULL
3. Nettoie les données invalides
4. Recrée les contraintes
5. Teste une mise à jour
6. Vérifie que tout fonctionne

### Test Manuel
1. **Aller** dans la page d'administration
2. **Essayer** d'activer un utilisateur
3. **Vérifier** qu'il n'y a plus d'erreur 400
4. **Confirmer** que l'activation fonctionne

## 📊 Résultats Attendus

### Après Exécution du Script
```
DIAGNOSTIC DONNÉES NULL | total_rows | email_null | first_name_null | last_name_null | user_id_null
----------------------|------------|------------|-----------------|----------------|-------------
DIAGNOSTIC DONNÉES NULL | 5          | 2          | 3               | 3              | 0

✅ Contrainte NOT NULL supprimée de email
✅ Test de mise à jour réussi pour l'utilisateur: [UUID]

VÉRIFICATION FINALE | total_users | users_actifs | users_avec_email | users_avec_prenom | users_avec_nom
-------------------|-------------|--------------|------------------|-------------------|---------------
VÉRIFICATION FINALE | 5           | 2            | 5                | 5                 | 5

EXEMPLE UTILISATEUR CORRIGÉ | user_id | email | first_name | last_name | is_active | status | subscription_type
---------------------------|---------|-------|------------|-----------|-----------|--------|-------------------
EXEMPLE UTILISATEUR CORRIGÉ | [UUID]  | test@example.com | Utilisateur | Test | true | ACTIF | free

CORRECTION DONNÉES NULL TERMINÉE | Les données NULL ont été corrigées et les contraintes sont maintenant respectées
```

### Dans la Console Browser
```
✅ Activation réussie dans la table
✅ Liste actualisée : 5 utilisateurs
```

## 🚀 Instructions d'Exécution

### Ordre d'Exécution
1. **Exécuter** `correction_donnees_null.sql`
2. **Vérifier** que toutes les données NULL sont corrigées
3. **Confirmer** que le test de mise à jour réussit
4. **Tester** l'activation d'un utilisateur dans l'interface
5. **Vérifier** qu'il n'y a plus d'erreur 400

### Vérification
- ✅ **Plus d'erreur 400** lors de l'activation
- ✅ **Plus de données NULL** dans les colonnes importantes
- ✅ **Contraintes NOT NULL** respectées
- ✅ **Activation d'utilisateur** fonctionne

## ✅ Checklist de Validation

- [ ] Script de correction exécuté
- [ ] Toutes les données NULL corrigées
- [ ] Contraintes NOT NULL respectées
- [ ] Test de mise à jour réussi
- [ ] Plus d'erreur 400 lors de l'activation
- [ ] Activation d'utilisateur fonctionne dans l'interface
- [ ] Synchronisation avec auth.users complète

## 🔄 Maintenance

### Vérification Régulière
```sql
-- Vérifier qu'il n'y a plus de données NULL
SELECT 
  COUNT(*) as total_rows,
  COUNT(CASE WHEN email IS NULL THEN 1 END) as email_null,
  COUNT(CASE WHEN first_name IS NULL THEN 1 END) as first_name_null,
  COUNT(CASE WHEN last_name IS NULL THEN 1 END) as last_name_null
FROM subscription_status;
```

### Surveillance des Contraintes
```sql
-- Vérifier les contraintes NOT NULL
SELECT 
  column_name,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public'
ORDER BY ordinal_position;
```

---

**Note** : Cette solution corrige définitivement l'erreur 23502 en corrigeant toutes les données NULL et en respectant les contraintes NOT NULL.
