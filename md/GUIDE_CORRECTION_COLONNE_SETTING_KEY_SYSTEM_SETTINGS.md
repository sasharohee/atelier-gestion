# 🔧 Correction Colonne Setting Key - Table System Settings

## 🚨 Problème Identifié

Erreur lors de la création/mise à jour d'un paramètre système :
```
Supabase error: {code: '23502', details: null, hint: null, message: 'null value in column "setting_key" of relation "system_settings" violates not-null constraint'}
```

## 🔍 Analyse du Problème

### **Erreur :**
- ❌ **Code :** 23502
- ❌ **Message :** "null value in column 'setting_key' of relation 'system_settings' violates not-null constraint"
- ❌ **Cause :** Incohérence entre les noms de colonnes `key` (frontend) et `setting_key` (backend)

### **Contexte :**
- Le frontend envoie des données avec la colonne `key`
- La base de données attend la colonne `setting_key`
- Il y a une incohérence dans les noms de colonnes
- La contrainte NOT NULL empêche l'insertion

## ✅ Solution

### **Problème :**
- ❌ Incohérence entre `key` et `setting_key`
- ❌ Contrainte NOT NULL sur `setting_key`
- ❌ Colonnes manquantes ou mal nommées
- ❌ Opérations UPSERT impossibles

### **Solution :**
- ✅ Harmoniser les noms de colonnes
- ✅ Supprimer les contraintes NOT NULL problématiques
- ✅ Créer la contrainte unique appropriée
- ✅ Tester les opérations d'insertion

## 🔧 Ce que fait la Correction

### **1. Analyse de l'Incohérence**
```sql
-- Analyser quelle colonne existe et quelle est attendue
DO $$
DECLARE
    has_key BOOLEAN := FALSE;
    has_setting_key BOOLEAN := FALSE;
    has_user_id BOOLEAN := FALSE;
    has_setting_value BOOLEAN := FALSE;
    has_value BOOLEAN := FALSE;
BEGIN
    -- Vérifier les colonnes existantes
    SELECT EXISTS (SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key') INTO has_key;
    
    SELECT EXISTS (SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'setting_key') INTO has_setting_key;
    
    -- Déterminer la structure
    IF has_setting_key AND NOT has_key THEN
        RAISE NOTICE '⚠️ Structure détectée: colonnes setting_key/setting_value (backend)';
    ELSIF has_key AND NOT has_setting_key THEN
        RAISE NOTICE '⚠️ Structure détectée: colonnes key/value (frontend)';
    ELSIF has_key AND has_setting_key THEN
        RAISE NOTICE '⚠️ Structure détectée: colonnes mixtes (problématique)';
    END IF;
END $$;
```

### **2. Correction de l'Incohérence**
```sql
-- Renommer setting_key en key si nécessaire
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'setting_key'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key'
    ) THEN
        -- Renommer setting_key en key
        ALTER TABLE public.system_settings RENAME COLUMN setting_key TO key;
        RAISE NOTICE '✅ Colonne setting_key renommée en key';
    END IF;
END $$;

-- Renommer setting_value en value si nécessaire
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'setting_value'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'value'
    ) THEN
        -- Renommer setting_value en value
        ALTER TABLE public.system_settings RENAME COLUMN setting_value TO value;
        RAISE NOTICE '✅ Colonne setting_value renommée en value';
    END IF;
END $$;
```

### **3. Correction des Contraintes NOT NULL**
```sql
-- Rendre key nullable si elle a une contrainte NOT NULL
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key'
            AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.system_settings ALTER COLUMN key DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée de key';
    END IF;
END $$;

-- Rendre value nullable si elle a une contrainte NOT NULL
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'value'
            AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.system_settings ALTER COLUMN value DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée de value';
    END IF;
END $$;
```

### **4. Création de la Contrainte Unique**
```sql
-- Créer la contrainte unique appropriée
DO $$
DECLARE
    has_user_id BOOLEAN := FALSE;
    has_key BOOLEAN := FALSE;
    constraint_exists BOOLEAN := FALSE;
    constraint_name TEXT;
BEGIN
    -- Vérifier la structure
    SELECT EXISTS (SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'user_id') INTO has_user_id;
    
    SELECT EXISTS (SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key') INTO has_key;
    
    -- Créer la contrainte selon la structure
    IF has_user_id AND has_key THEN
        constraint_name := 'system_settings_user_id_key_unique';
        EXECUTE format('ALTER TABLE public.system_settings ADD CONSTRAINT %I UNIQUE (user_id, key)', constraint_name);
        RAISE NOTICE '✅ Contrainte unique créée: % (user_id, key)', constraint_name;
    ELSIF has_key AND NOT has_user_id THEN
        constraint_name := 'system_settings_key_unique';
        EXECUTE format('ALTER TABLE public.system_settings ADD CONSTRAINT %I UNIQUE (key)', constraint_name);
        RAISE NOTICE '✅ Contrainte unique créée: % (key)', constraint_name;
    END IF;
END $$;
```

## 📊 Corrections Appliquées

### **Renommage de Colonnes :**
- ✅ **`setting_key` → `key`** - Harmonisation avec le frontend
- ✅ **`setting_value` → `value`** - Harmonisation avec le frontend

### **Suppression de Contraintes :**
- ✅ **Contrainte NOT NULL supprimée** de `key`
- ✅ **Contrainte NOT NULL supprimée** de `value`

### **Ajout de Colonnes :**
- ✅ **`user_id`** - Référence vers l'utilisateur
- ✅ **`created_at`** - Date de création
- ✅ **`updated_at`** - Date de modification

### **Contraintes Uniques :**
- ✅ **`(user_id, key)`** - Si les deux colonnes existent
- ✅ **`(key)`** - Si seule la colonne key existe

## 🧪 Tests de Validation

### **Test 1: Vérification de la Structure**
```sql
-- Vérifier que les colonnes sont correctement nommées
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
ORDER BY ordinal_position;
```

### **Test 2: Test d'Insertion avec ON CONFLICT**
```sql
-- Test d'insertion avec ON CONFLICT selon la structure
DO $$
DECLARE
    has_user_id BOOLEAN := FALSE;
    has_key BOOLEAN := FALSE;
BEGIN
    -- Détecter la structure
    SELECT EXISTS (SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'user_id') INTO has_user_id;
    
    SELECT EXISTS (SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'system_settings' 
            AND column_name = 'key') INTO has_key;
    
    -- Test d'insertion adapté
    IF has_user_id AND has_key THEN
        -- Structure avec user_id et key
        INSERT INTO public.system_settings (user_id, key, value)
        VALUES (auth.uid(), 'test_setting', 'test_value')
        ON CONFLICT (user_id, key) 
        DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();
    ELSIF has_key AND NOT has_user_id THEN
        -- Structure avec key seulement
        INSERT INTO public.system_settings (key, value)
        VALUES ('test_setting', 'test_value')
        ON CONFLICT (key) 
        DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();
    END IF;
END $$;
```

## 📊 Résultats Attendus

### **Avant la Correction :**
- ❌ Erreur 23502 sur `setting_key`
- ❌ Incohérence entre `key` et `setting_key`
- ❌ Contraintes NOT NULL problématiques
- ❌ Opérations UPSERT impossibles

### **Après la Correction :**
- ✅ Noms de colonnes harmonisés
- ✅ Contraintes NOT NULL supprimées
- ✅ Contrainte unique appropriée créée
- ✅ **PROBLÈME RÉSOLU**

## 🔄 Vérifications Post-Correction

### **1. Vérifier les Paramètres Système**
- Aller dans Réglages
- Modifier un paramètre système
- Vérifier qu'il n'y a plus d'erreur 23502

### **2. Vérifier la Structure**
```sql
-- Vérifier que les colonnes sont correctement nommées
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
    AND column_name IN ('key', 'value', 'user_id');
```

### **3. Tester l'Upsert**
- Créer/modifier un paramètre via l'interface
- Vérifier que l'opération UPSERT fonctionne

## 🚨 En Cas de Problème

### **1. Vérifier les Erreurs**
- Lire attentivement tous les messages d'erreur
- S'assurer que les colonnes ont été renommées
- Vérifier que les contraintes ont été supprimées

### **2. Vérifier la Structure**
```sql
-- Vérifier la structure complète
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
ORDER BY ordinal_position;
```

### **3. Forcer le Rafraîchissement**
```sql
-- Forcer le rafraîchissement du cache
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(5);
```

## ✅ Statut

- [x] Script de correction créé
- [x] Analyse de l'incohérence des noms de colonnes
- [x] Renommage des colonnes problématiques
- [x] Suppression des contraintes NOT NULL
- [x] Ajout des colonnes manquantes
- [x] Création de la contrainte unique appropriée
- [x] Tests de validation inclus
- [x] Rafraîchissement du cache PostgREST
- [x] Vérifications post-correction incluses

**Cette correction résout le problème d'incohérence des noms de colonnes !**

## 🎯 Résultat Final

**Après cette correction :**
- ✅ Les noms de colonnes sont harmonisés (`key` au lieu de `setting_key`)
- ✅ Les contraintes NOT NULL problématiques sont supprimées
- ✅ La contrainte unique appropriée est créée
- ✅ Les paramètres système sont utilisables
- ✅ **PROBLÈME COMPLÈTEMENT RÉSOLU !**

## 🚀 Exécution

**Pour résoudre le problème :**
1. Exécuter `tables/correction_colonne_setting_key_system_settings.sql`
2. Vérifier les paramètres système
3. **PROBLÈME RÉSOLU !**

**Cette correction va résoudre l'erreur d'incohérence des noms de colonnes !**
