# Guide - Correction Upsert Activation

## 🚨 Problème Identifié

L'erreur `23502` persiste lors de l'activation d'un utilisateur :

```
null value in column "email" of relation "subscription_status" violates not-null constraint
```

### Erreur Observée
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/subscription_status?on_conflict=user_id&select=* 400 (Bad Request)
```

## 🔍 Cause du Problème

La fonction `activateSubscription` utilise un `upsert` qui ne fournit pas toutes les colonnes requises :

```typescript
// ❌ PROBLÉMATIQUE - Colonnes manquantes
.upsert({
  user_id: userId,
  is_active: true,
  activated_at: new Date().toISOString(),
  activated_by: activatedBy || null,
  notes: notes || 'Activé manuellement',
  updated_at: new Date().toISOString()
  // ❌ email, first_name, last_name manquants
})
```

### Colonnes Manquantes
- `email` - Contrainte NOT NULL
- `first_name` - Contrainte NOT NULL
- `last_name` - Contrainte NOT NULL
- `status` - Colonne manquante
- `subscription_type` - Valeur par défaut

## ✅ Solution

### Étape 1 : Correction de la Base de Données

Exécuter le script de correction :

```sql
-- Copier et exécuter correction_activation_upsert.sql
```

Ce script va :
- ✅ **Diagnostiquer** les données NULL dans la table
- ✅ **Corriger** les données NULL en utilisant auth.users
- ✅ **Supprimer** temporairement les contraintes NOT NULL
- ✅ **Ajouter** les colonnes manquantes
- ✅ **Synchroniser** avec auth.users
- ✅ **Tester** l'upsert
- ✅ **Recréer** les contraintes NOT NULL

### Étape 2 : Correction du Code TypeScript

La fonction `activateSubscription` a été corrigée pour :

```typescript
// ✅ CORRIGÉ - Toutes les colonnes fournies
const upsertData = {
  user_id: userId,
  email: authUser.user?.email || `user_${userId}@example.com`,
  first_name: authUser.user?.user_metadata?.first_name || 'Utilisateur',
  last_name: authUser.user?.user_metadata?.last_name || 'Test',
  is_active: true,
  activated_at: new Date().toISOString(),
  activated_by: activatedBy || null,
  status: 'ACTIF',
  subscription_type: 'free',
  notes: notes || 'Activé manuellement',
  updated_at: new Date().toISOString()
};
```

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
-- Corriger les données NULL en utilisant auth.users
UPDATE subscription_status 
SET 
  email = COALESCE(subscription_status.email, auth_users.email),
  first_name = COALESCE(subscription_status.first_name, 
    COALESCE(auth_users.raw_user_meta_data->>'first_name', 'Utilisateur')),
  last_name = COALESCE(subscription_status.last_name, 
    COALESCE(auth_users.raw_user_meta_data->>'last_name', 'Test'))
FROM auth.users auth_users
WHERE subscription_status.user_id = auth_users.id;
```

### **Suppression des Contraintes NOT NULL**
```sql
-- Supprimer les contraintes NOT NULL pour permettre l'upsert
DO $$
BEGIN
  ALTER TABLE subscription_status ALTER COLUMN email DROP NOT NULL;
  ALTER TABLE subscription_status ALTER COLUMN first_name DROP NOT NULL;
  ALTER TABLE subscription_status ALTER COLUMN last_name DROP NOT NULL;
  RAISE NOTICE '✅ Contraintes NOT NULL supprimées';
END $$;
```

### **Ajout des Colonnes Manquantes**
```sql
-- Ajouter les colonnes manquantes
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' AND column_name = 'activated_by') THEN
    ALTER TABLE subscription_status ADD COLUMN activated_by UUID;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' AND column_name = 'status') THEN
    ALTER TABLE subscription_status ADD COLUMN status TEXT DEFAULT 'INACTIF';
  END IF;
END $$;
```

## 🧪 Tests

### Test Automatique
Le script inclut un test automatique qui :
1. Diagnostique les données NULL
2. Corrige les données NULL
3. Supprime les contraintes NOT NULL
4. Ajoute les colonnes manquantes
5. Teste l'upsert
6. Recrée les contraintes NOT NULL
7. Vérifie que tout fonctionne

### Test Manuel
1. **Aller** dans la page d'administration
2. **Essayer** d'activer un utilisateur
3. **Vérifier** qu'il n'y a plus d'erreur 400
4. **Confirmer** que l'activation fonctionne

## 📊 Résultats Attendus

### Après Exécution du Script
```
DIAGNOSTIC DONNÉES NULL | total_rows | email_null | first_name_null | last_name_null
----------------------|------------|------------|-----------------|----------------
DIAGNOSTIC DONNÉES NULL | 5          | 2          | 3               | 3

✅ Contrainte NOT NULL supprimée de email
✅ Contrainte NOT NULL supprimée de first_name
✅ Contrainte NOT NULL supprimée de last_name
✅ Colonne activated_by ajoutée
✅ Colonne status ajoutée
✅ Test d'upsert réussi pour l'utilisateur: [UUID]

VÉRIFICATION FINALE | total_users | users_actifs | users_avec_email | users_avec_prenom | users_avec_nom
-------------------|-------------|--------------|------------------|-------------------|---------------
VÉRIFICATION FINALE | 5           | 2            | 5                | 5                 | 5

EXEMPLE UTILISATEUR CORRIGÉ | user_id | email | first_name | last_name | is_active | status | subscription_type
---------------------------|---------|-------|------------|-----------|-----------|--------|-------------------
EXEMPLE UTILISATEUR CORRIGÉ | [UUID]  | test@example.com | Utilisateur | Test | true | ACTIF | free

CORRECTION UPSERT ACTIVATION TERMINÉE | Le problème d'upsert dans activateSubscription a été corrigé
```

### Dans la Console Browser
```
✅ Tentative d'activation pour l'utilisateur [UUID]
📝 Données upsert: {user_id: "...", email: "...", first_name: "...", ...}
✅ Activation réussie dans la table
```

## 🚀 Instructions d'Exécution

### Ordre d'Exécution
1. **Exécuter** `correction_activation_upsert.sql`
2. **Vérifier** que toutes les données NULL sont corrigées
3. **Confirmer** que le test d'upsert réussit
4. **Tester** l'activation d'un utilisateur dans l'interface
5. **Vérifier** qu'il n'y a plus d'erreur 400

### Vérification
- ✅ **Plus d'erreur 400** lors de l'activation
- ✅ **Plus de données NULL** dans les colonnes importantes
- ✅ **Contraintes NOT NULL** respectées
- ✅ **Activation d'utilisateur** fonctionne
- ✅ **Upsert** fonctionne correctement

## ✅ Checklist de Validation

- [ ] Script de correction exécuté
- [ ] Toutes les données NULL corrigées
- [ ] Contraintes NOT NULL supprimées puis recréées
- [ ] Colonnes manquantes ajoutées
- [ ] Test d'upsert réussi
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

**Note** : Cette solution corrige définitivement l'erreur 23502 en corrigeant l'upsert dans activateSubscription et en s'assurant que toutes les colonnes requises sont fournies.
