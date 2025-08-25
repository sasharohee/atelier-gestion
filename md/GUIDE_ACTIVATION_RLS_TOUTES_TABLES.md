# Guide - Activation RLS Toutes les Tables

## 🚨 Objectif

Activer Row Level Security (RLS) sur toutes les tables pour qu'elles ne soient plus "Unrestricted" et sécuriser l'accès aux données.

### État Actuel
- **Tables "Unrestricted"** : Plusieurs tables n'ont pas RLS activé
- **Sécurité** : Accès non contrôlé aux données
- **Objectif** : Activer RLS sur toutes les tables avec des politiques appropriées

## ✅ Solution

### Étape 1 : Activation RLS sur Toutes les Tables

Exécuter le script de correction :

```sql
-- Copier et exécuter activation_rls_toutes_tables.sql
```

Ce script va :
- ✅ **Diagnostiquer** les tables sans RLS
- ✅ **Activer** RLS sur toutes les tables publiques
- ✅ **Créer** des politiques RLS appropriées pour chaque table
- ✅ **Configurer** l'accès utilisateur et admin
- ✅ **Vérifier** que toutes les tables sont sécurisées

### Étape 2 : Politiques RLS par Table

Le script crée des politiques spécifiques pour chaque table :

#### **Politiques pour les Tables Principales**

**Clients, Devices, Repairs, Products, Sales, Appointments, Messages, Device_Models :**

```sql
-- Politique SELECT : Utilisateurs voient leurs propres données
CREATE POLICY "Users can view their own clients" ON clients
  FOR SELECT USING (created_by = auth.uid() OR workshop_id IN (
    SELECT workshop_id FROM users WHERE user_id = auth.uid()
  ));

-- Politique SELECT : Admins voient toutes les données
CREATE POLICY "Admins can view all clients" ON clients
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

-- Politiques INSERT, UPDATE, DELETE similaires
```

#### **Politiques Génériques pour Autres Tables**

Pour toutes les autres tables, le script crée automatiquement :

```sql
-- Politiques génériques pour chaque table
CREATE POLICY "Users can view their own [table]" ON [table]
  FOR SELECT USING (created_by = auth.uid());

CREATE POLICY "Admins can view all [table]" ON [table]
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

### **Diagnostic des Tables Sans RLS**
```sql
-- Vérifier les tables sans RLS
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_active
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename NOT LIKE 'pg_%'
  AND tablename NOT LIKE 'sql_%'
ORDER BY tablename;
```

### **Activation RLS Automatique**
```sql
-- Activer RLS sur toutes les tables publiques
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
      AND tablename NOT LIKE 'pg_%'
      AND tablename NOT LIKE 'sql_%'
      AND tablename NOT IN ('schema_migrations', 'ar_internal_metadata')
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_record.tablename);
    RAISE NOTICE '✅ RLS activé sur la table: %', table_record.tablename;
  END LOOP;
END $$;
```

### **Création Automatique des Politiques**
```sql
-- Politiques génériques pour les autres tables
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
      AND tablename NOT IN (/* tables principales */)
  LOOP
    -- Créer automatiquement les politiques SELECT, INSERT, UPDATE, DELETE
    EXECUTE format('CREATE POLICY "Users can view their own %I" ON %I FOR SELECT USING (created_by = auth.uid())', 
      table_record.tablename, table_record.tablename);
    -- ... autres politiques
  END LOOP;
END $$;
```

## 🧪 Tests

### Test Automatique
Le script inclut des vérifications automatiques qui :
1. Diagnostique les tables sans RLS
2. Active RLS sur toutes les tables
3. Crée les politiques appropriées
4. Vérifie que toutes les tables sont sécurisées
5. Compte les politiques créées

### Test Manuel
1. **Vérifier** dans le dashboard Supabase que les tables ne sont plus "Unrestricted"
2. **Tester** l'accès aux données en tant qu'utilisateur normal
3. **Tester** l'accès aux données en tant qu'admin
4. **Confirmer** que les politiques fonctionnent correctement

## 📊 Résultats Attendus

### Après Exécution du Script
```
DIAGNOSTIC TABLES SANS RLS | schemaname | tablename | rls_active
-------------------------|------------|-----------|-----------
DIAGNOSTIC TABLES SANS RLS | public     | clients   | false
DIAGNOSTIC TABLES SANS RLS | public     | devices   | false
DIAGNOSTIC TABLES SANS RLS | public     | repairs   | false
DIAGNOSTIC TABLES SANS RLS | public     | products  | false
DIAGNOSTIC TABLES SANS RLS | public     | sales     | false

✅ RLS activé sur la table: clients
✅ RLS activé sur la table: devices
✅ RLS activé sur la table: repairs
✅ RLS activé sur la table: products
✅ RLS activé sur la table: sales
✅ RLS activé sur la table: appointments
✅ RLS activé sur la table: messages
✅ RLS activé sur la table: device_models

✅ Politiques créées pour la table: activity_logs
✅ Politiques créées pour la table: advanced_alerts
✅ Politiques créées pour la table: advanced_settings

VÉRIFICATION FINALE RLS | schemaname | tablename | rls_active
------------------------|------------|-----------|-----------
VÉRIFICATION FINALE RLS | public     | clients   | true
VÉRIFICATION FINALE RLS | public     | devices   | true
VÉRIFICATION FINALE RLS | public     | repairs   | true
VÉRIFICATION FINALE RLS | public     | products  | true
VÉRIFICATION FINALE RLS | public     | sales     | true

COMPTAGE POLITIQUES RLS | schemaname | tablename | nombre_politiques
----------------------|------------|-----------|------------------
COMPTAGE POLITIQUES RLS | public     | clients   | 8
COMPTAGE POLITIQUES RLS | public     | devices   | 8
COMPTAGE POLITIQUES RLS | public     | repairs   | 8
COMPTAGE POLITIQUES RLS | public     | products  | 8
COMPTAGE POLITIQUES RLS | public     | sales     | 8

ACTIVATION RLS TOUTES LES TABLES TERMINÉE | Toutes les tables ont maintenant RLS activé avec des politiques appropriées
```

### Dans le Dashboard Supabase
- ✅ **Plus de tables "Unrestricted"**
- ✅ **Toutes les tables ont RLS activé**
- ✅ **Politiques RLS configurées**
- ✅ **Sécurité des données renforcée**

## 🚀 Instructions d'Exécution

### Ordre d'Exécution
1. **Exécuter** `activation_rls_toutes_tables.sql`
2. **Vérifier** que toutes les tables ont RLS activé
3. **Confirmer** que les politiques sont créées
4. **Tester** l'accès aux données
5. **Vérifier** dans le dashboard Supabase

### Vérification
- ✅ **Plus de tables "Unrestricted"** dans le dashboard
- ✅ **Toutes les tables ont RLS activé**
- ✅ **Politiques RLS fonctionnelles**
- ✅ **Accès utilisateur contrôlé**
- ✅ **Accès admin maintenu**

## ✅ Checklist de Validation

- [ ] Script de correction exécuté
- [ ] RLS activé sur toutes les tables
- [ ] Politiques créées pour les tables principales
- [ ] Politiques génériques créées pour les autres tables
- [ ] Plus de tables "Unrestricted" dans le dashboard
- [ ] Accès utilisateur fonctionne correctement
- [ ] Accès admin fonctionne correctement
- [ ] Sécurité des données renforcée

## 🔄 Maintenance

### Vérification Régulière
```sql
-- Vérifier que toutes les tables ont RLS activé
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_active
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename NOT LIKE 'pg_%'
  AND tablename NOT LIKE 'sql_%'
ORDER BY tablename;
```

### Surveillance des Politiques
```sql
-- Vérifier les politiques RLS par table
SELECT 
  schemaname,
  tablename,
  COUNT(*) as nombre_politiques
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;
```

---

**Note** : Cette solution active RLS sur toutes les tables pour sécuriser l'accès aux données et éliminer les tables "Unrestricted".
