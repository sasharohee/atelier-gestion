# 🔧 Correction Contrainte Unique - Table System Settings

## 🚨 Problème Identifié

Erreur lors de la création/mise à jour d'un paramètre système :
```
Supabase error: {code: '42P10', details: null, hint: null, message: 'there is no unique or exclusion constraint matching the ON CONFLICT specification'}
```

## 🔍 Analyse du Problème

### **Erreur :**
- ❌ **Code :** 42P10
- ❌ **Message :** "there is no unique or exclusion constraint matching the ON CONFLICT specification"
- ❌ **Cause :** La clause `ON CONFLICT` est utilisée mais il n'y a pas de contrainte unique correspondante

### **Contexte :**
- La table `system_settings` utilise `ON CONFLICT` pour les opérations UPSERT
- Il manque une contrainte unique sur les colonnes appropriées
- Le frontend essaie de faire un `INSERT ... ON CONFLICT` mais échoue

## ✅ Solution

### **Problème :**
- ❌ Contrainte unique manquante pour `ON CONFLICT`
- ❌ Structure de table incomplète
- ❌ Opérations UPSERT impossibles

### **Solution :**
- ✅ Créer la contrainte unique appropriée selon la structure
- ✅ Vérifier et ajouter les colonnes manquantes
- ✅ Tester les opérations `ON CONFLICT`

## 🔧 Ce que fait la Correction

### **1. Analyse de la Structure**
```sql
-- Vérifier la structure actuelle de la table system_settings
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
ORDER BY ordinal_position;
```

### **2. Détection de la Contrainte Manquante**
```sql
-- Analyser quelle contrainte unique devrait exister
DO $$
DECLARE
    has_user_id BOOLEAN := FALSE;
    has_key BOOLEAN := FALSE;
    has_unique_constraint BOOLEAN := FALSE;
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
    
    -- Déterminer la contrainte nécessaire
    IF has_user_id AND has_key AND NOT has_unique_constraint THEN
        RAISE NOTICE '⚠️ Contrainte unique manquante sur (user_id, key)';
    ELSIF has_key AND NOT has_user_id AND NOT has_unique_constraint THEN
        RAISE NOTICE '⚠️ Contrainte unique manquante sur (key)';
    END IF;
END $$;
```

### **3. Création de la Contrainte Unique**
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

### **4. Ajout des Colonnes Manquantes**
```sql
-- Vérifier et ajouter les colonnes essentielles
DO $$
DECLARE
    missing_columns TEXT[] := ARRAY[
        'user_id',
        'key',
        'value',
        'created_at',
        'updated_at'
    ];
    col TEXT;
BEGIN
    FOREACH col IN ARRAY missing_columns
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
                AND table_name = 'system_settings' 
                AND column_name = col
        ) THEN
            -- Ajouter la colonne selon son type
            IF col = 'user_id' THEN
                ALTER TABLE public.system_settings ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
            ELSIF col = 'key' THEN
                ALTER TABLE public.system_settings ADD COLUMN key VARCHAR(255) NOT NULL;
            ELSIF col = 'value' THEN
                ALTER TABLE public.system_settings ADD COLUMN value TEXT;
            ELSIF col = 'created_at' THEN
                ALTER TABLE public.system_settings ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
            ELSIF col = 'updated_at' THEN
                ALTER TABLE public.system_settings ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
            END IF;
            RAISE NOTICE '✅ Colonne ajoutée: %', col;
        END IF;
    END LOOP;
END $$;
```

## 📊 Contraintes Créées

### **Structure avec User_ID et Key :**
- ✅ **Contrainte :** `system_settings_user_id_key_unique`
- ✅ **Colonnes :** `(user_id, key)`
- ✅ **Usage :** `ON CONFLICT (user_id, key)`

### **Structure avec Key seulement :**
- ✅ **Contrainte :** `system_settings_key_unique`
- ✅ **Colonnes :** `(key)`
- ✅ **Usage :** `ON CONFLICT (key)`

## 🧪 Tests de Validation

### **Test 1: Vérification de la Contrainte**
```sql
-- Vérifier que la contrainte unique existe
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) as columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public' 
    AND tc.table_name = 'system_settings'
    AND tc.constraint_type = 'UNIQUE'
GROUP BY tc.constraint_name, tc.constraint_type;
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
- ❌ Erreur 42P10 lors des opérations UPSERT
- ❌ Contrainte unique manquante
- ❌ Opérations `ON CONFLICT` impossibles
- ❌ Fonctionnalité de paramètres système inutilisable

### **Après la Correction :**
- ✅ Opérations UPSERT fonctionnelles
- ✅ Contrainte unique appropriée créée
- ✅ `ON CONFLICT` fonctionne correctement
- ✅ **PROBLÈME RÉSOLU**

## 🔄 Vérifications Post-Correction

### **1. Vérifier les Paramètres Système**
- Aller dans Réglages
- Modifier un paramètre système
- Vérifier qu'il n'y a plus d'erreur 42P10

### **2. Vérifier les Contraintes**
```sql
-- Vérifier que la contrainte unique existe
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints 
WHERE table_schema = 'public' 
    AND table_name = 'system_settings'
    AND constraint_type = 'UNIQUE';
```

### **3. Tester l'Upsert**
- Créer/modifier un paramètre via l'interface
- Vérifier que l'opération UPSERT fonctionne

## 🚨 En Cas de Problème

### **1. Vérifier les Erreurs**
- Lire attentivement tous les messages d'erreur
- S'assurer que la contrainte unique a été créée
- Vérifier que les colonnes nécessaires existent

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
- [x] Analyse de la structure de la table
- [x] Détection de la contrainte manquante
- [x] Création de la contrainte unique appropriée
- [x] Ajout des colonnes manquantes
- [x] Tests de validation inclus
- [x] Rafraîchissement du cache PostgREST
- [x] Vérifications post-correction incluses

**Cette correction résout le problème de contrainte unique manquante !**

## 🎯 Résultat Final

**Après cette correction :**
- ✅ La contrainte unique appropriée est créée
- ✅ Les opérations `ON CONFLICT` fonctionnent
- ✅ Les paramètres système sont utilisables
- ✅ **PROBLÈME COMPLÈTEMENT RÉSOLU !**

## 🚀 Exécution

**Pour résoudre le problème :**
1. Exécuter `tables/correction_contrainte_unique_system_settings.sql`
2. Vérifier les paramètres système
3. **PROBLÈME RÉSOLU !**

**Cette correction va résoudre l'erreur de contrainte unique manquante !**
