# 🔍 GUIDE DE DIAGNOSTIC - ISOLATION DU CATALOGUE

## 🚨 PROBLÈME IDENTIFIÉ
Il y a un problème d'isolation pour le catalogue. Les utilisateurs peuvent voir les données d'autres utilisateurs.

## 📋 ÉTAPES DE DIAGNOSTIC

### 1. Vérifier l'état actuel des tables du catalogue

```sql
-- Diagnostic initial
SELECT 
    table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as records_without_user_id,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as records_with_user_id
FROM (
    SELECT 'devices' as table_name, user_id FROM public.devices
    UNION ALL
    SELECT 'services', user_id FROM public.services  
    UNION ALL
    SELECT 'parts', user_id FROM public.parts
    UNION ALL
    SELECT 'products', user_id FROM public.products
    UNION ALL
    SELECT 'clients', user_id FROM public.clients
) t
GROUP BY table_name;
```

### 2. Vérifier les politiques RLS actuelles

```sql
-- Vérifier les politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('devices', 'services', 'parts', 'products', 'clients')
ORDER BY tablename, policyname;
```

### 3. Vérifier la structure des tables

```sql
-- Vérifier la structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('devices', 'services', 'parts', 'products', 'clients')
ORDER BY table_name, ordinal_position;
```

### 4. Tester l'isolation actuelle

```sql
-- Test d'isolation
DO $$
DECLARE
    current_user_id UUID;
    other_user_data_count INTEGER;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE 'Aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Compter les données d'autres utilisateurs
    SELECT COUNT(*) INTO other_user_data_count
    FROM (
        SELECT user_id FROM public.devices WHERE user_id != current_user_id
        UNION ALL
        SELECT user_id FROM public.services WHERE user_id != current_user_id
        UNION ALL
        SELECT user_id FROM public.parts WHERE user_id != current_user_id
        UNION ALL
        SELECT user_id FROM public.products WHERE user_id != current_user_id
        UNION ALL
        SELECT user_id FROM public.clients WHERE user_id != current_user_id
    ) t;
    
    IF other_user_data_count > 0 THEN
        RAISE NOTICE '❌ PROBLÈME: % enregistrements d''autres utilisateurs visibles', other_user_data_count;
    ELSE
        RAISE NOTICE '✅ Isolation correcte - Aucune donnée d''autre utilisateur visible';
    END IF;
END $$;
```

## 🔧 SOLUTIONS APPLIQUÉES

### Script de correction d'urgence
Le fichier `correction_isolation_catalogue_urgence.sql` contient une correction complète qui :

1. **Diagnostique** l'état actuel des tables
2. **Corrige** les données orphelines (sans user_id)
3. **Ajoute** les colonnes manquantes si nécessaire
4. **Recrée** toutes les politiques RLS avec isolation stricte
5. **Teste** l'isolation après correction

### Exécution du script de correction

```bash
# Dans l'interface SQL de Supabase
# Copier et exécuter le contenu de correction_isolation_catalogue_urgence.sql
```

## 🎯 RÉSULTATS ATTENDUS

Après l'exécution du script de correction :

- ✅ Toutes les données ont un `user_id` valide
- ✅ Les politiques RLS isolent strictement les données par utilisateur
- ✅ Aucun utilisateur ne peut voir les données d'autres utilisateurs
- ✅ Les performances sont optimisées avec des index appropriés

## 🚨 SIGNAUX D'ALERTE

### Problèmes détectés :
- Données sans `user_id` (orphelines)
- Politiques RLS manquantes ou incorrectes
- Colonnes manquantes dans les tables
- Données d'autres utilisateurs visibles

### Solutions appliquées :
- Attribution automatique des données orphelines à l'utilisateur connecté
- Recréation complète des politiques RLS
- Ajout des colonnes manquantes
- Tests d'isolation automatiques

## 📊 VÉRIFICATION POST-CORRECTION

Après avoir exécuté le script, vérifiez que :

1. **Aucune donnée orpheline** : Tous les enregistrements ont un `user_id`
2. **Politiques RLS actives** : 4 politiques par table (SELECT, INSERT, UPDATE, DELETE)
3. **Isolation fonctionnelle** : Chaque utilisateur ne voit que ses propres données
4. **Performance optimale** : Index créés sur `user_id`

## 🔄 MAINTENANCE PRÉVENTIVE

Pour éviter les problèmes futurs :

1. **Vérifications régulières** : Exécuter le diagnostic mensuellement
2. **Tests d'isolation** : Tester après chaque modification de politique RLS
3. **Monitoring** : Surveiller les erreurs d'accès aux données
4. **Documentation** : Maintenir à jour les politiques de sécurité

---

**⚠️ IMPORTANT** : Ce script doit être exécuté par un utilisateur connecté pour que l'isolation fonctionne correctement.
