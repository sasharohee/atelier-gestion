# Guide de Dépannage Rapide - Erreur 409 Appointments

## 🚨 Problème Urgent

**Erreur persistante :** `409 (Conflict)` lors de la création de rendez-vous
```
insert or update on table "appointments" violates foreign key constraint "appointments_assigned_user_id_fkey"
Key is not present in table "users".
```

## ⚡ Solution Immédiate

### Étape 1 : Exécuter le Script SQL de Correction

**Exécutez immédiatement ce script dans votre console Supabase :**

```sql
-- SUPPRESSION D'URGENCE DE LA CONTRAINTE PROBLÉMATIQUE
DO $$
DECLARE
    constraint_name text;
BEGIN
    -- Trouver et supprimer la contrainte problématique
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_name = 'appointments'
        AND kcu.column_name = 'assigned_user_id';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE public.appointments DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE '✅ Contrainte supprimée: %', constraint_name;
    ELSE
        RAISE NOTICE '✅ Aucune contrainte trouvée';
    END IF;
END $$;

-- MODIFICATION DE LA COLONNE POUR ACCEPTER NULL
ALTER TABLE public.appointments ALTER COLUMN assigned_user_id DROP NOT NULL;

-- RAFRAÎCHISSEMENT DU CACHE
NOTIFY pgrst, 'reload schema';
```

### Étape 2 : Vérifier la Correction

```sql
-- Vérifier que la contrainte a été supprimée
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'appointments'
    AND kcu.column_name = 'assigned_user_id';

-- Vérifier que la colonne accepte NULL
SELECT 
    column_name,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'appointments'
    AND column_name = 'assigned_user_id';
```

### Étape 3 : Test Immédiat

```sql
-- Test d'insertion sans assigned_user_id
INSERT INTO public.appointments (
    user_id,
    title,
    description,
    start_date,
    end_date,
    status
) VALUES (
    auth.uid(),
    'Test Rendez-vous',
    'Test Description',
    NOW(),
    NOW() + INTERVAL '1 hour',
    'scheduled'
);
```

## 🔧 Corrections Frontend Appliquées

### 1. **Service Supabase Amélioré**
- ✅ **Création** : N'envoie `assigned_user_id` que s'il a une valeur valide
- ✅ **Mise à jour** : Gère correctement les valeurs vides
- ✅ **Gestion d'erreurs** : Try-catch avec messages d'erreur

### 2. **Calendar.tsx Amélioré**
- ✅ **Conversion des valeurs** : Chaînes vides → `null`
- ✅ **Gestion d'erreurs** : Messages d'erreur clairs
- ✅ **Validation** : Vérification des données avant envoi

## 🎯 Résultat Attendu

Après exécution du script SQL :

✅ **Création de rendez-vous sans assignation** : Fonctionne  
✅ **Création de rendez-vous avec assignation** : Fonctionne  
✅ **Mise à jour de rendez-vous** : Fonctionne  
✅ **Plus d'erreur 409** : Problème résolu  

## 🚨 Si le Problème Persiste

### Solution Alternative : Suppression Complète de la Colonne

```sql
-- SUPPRESSION COMPLÈTE DE LA COLONNE PROBLÉMATIQUE
ALTER TABLE public.appointments DROP COLUMN IF EXISTS assigned_user_id;

-- RECRÉATION SANS CONTRAINTE
ALTER TABLE public.appointments ADD COLUMN assigned_user_id UUID;

-- RAFRAÎCHISSEMENT
NOTIFY pgrst, 'reload schema';
```

### Vérification Post-Suppression

```sql
-- Vérifier la structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'appointments'
    AND column_name = 'assigned_user_id';
```

## 📞 Support

Si le problème persiste après ces étapes :

1. **Vérifiez les logs Supabase** pour plus de détails
2. **Testez avec un utilisateur différent** pour isoler le problème
3. **Vérifiez les permissions RLS** sur la table appointments

---

**Priorité :** 🔴 URGENT  
**Impact :** Fonctionnalité calendrier bloquée  
**Solution :** Script SQL + Corrections frontend
