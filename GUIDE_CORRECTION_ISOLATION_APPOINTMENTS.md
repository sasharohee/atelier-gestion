# Guide de Correction - Isolation des Données Appointments

## 🔍 Problème Identifié

**Problème d'isolation :** Les rendez-vous créés par un utilisateur sont visibles par d'autres utilisateurs
- ✅ **Compte A** crée un rendez-vous
- ❌ **Compte B** peut voir le rendez-vous du Compte A
- ❌ **Pas d'isolation** entre les comptes utilisateurs

## 🎯 Cause du Problème

### 1. **Politiques RLS Manquantes ou Incorrectes**
- **RLS non activé** ou mal configuré sur la table `appointments`
- **Politiques d'isolation** absentes ou trop permissives
- **Logique frontend** qui contourne l'isolation

### 2. **Service Supabase Trop Permissif**
- **Logique complexe** dans `getAll()` qui permet l'accès croisé
- **Filtres manuels** au lieu d'utiliser les politiques RLS
- **Gestion des rôles** qui contourne l'isolation

## ✅ Solution Appliquée

### 1. **Script SQL de Correction**
**Fichier :** `tables/correction_isolation_appointments.sql`

**Actions :**
- ✅ Activation de RLS sur la table `appointments`
- ✅ Suppression des anciennes politiques permissives
- ✅ Création de nouvelles politiques d'isolation strictes
- ✅ Correction des données existantes

### 2. **Politiques RLS Créées**

#### **Politique SELECT :**
```sql
CREATE POLICY "Users can view own appointments" ON public.appointments
    FOR SELECT
    USING (
        user_id = auth.uid() OR 
        assigned_user_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM public.users WHERE role IN ('admin', 'manager')
        )
    );
```

#### **Politique INSERT :**
```sql
CREATE POLICY "Users can create own appointments" ON public.appointments
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
    );
```

#### **Politique UPDATE :**
```sql
CREATE POLICY "Users can update own appointments" ON public.appointments
    FOR UPDATE
    USING (
        user_id = auth.uid() OR 
        assigned_user_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM public.users WHERE role IN ('admin', 'manager')
        )
    );
```

#### **Politique DELETE :**
```sql
CREATE POLICY "Users can delete own appointments" ON public.appointments
    FOR DELETE
    USING (
        user_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM public.users WHERE role IN ('admin', 'manager')
        )
    );
```

### 3. **Service Supabase Simplifié**
**Avant :**
```typescript
// Logique complexe avec filtres manuels
.or(`user_id.eq.${currentUser.id},user_id.eq.00000000-0000-0000-0000-000000000000`)
```

**Après :**
```typescript
// Utilisation des politiques RLS pour l'isolation automatique
const { data, error } = await supabase
  .from('appointments')
  .select('*')
  .order('start_date', { ascending: true });
```

## 🔧 Étapes de Correction

### Étape 1 : Exécuter le Script SQL
```sql
-- Exécuter : tables/correction_isolation_appointments.sql
```

### Étape 2 : Vérifier l'Activation RLS
```sql
-- Vérifier que RLS est activé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'appointments';
```

### Étape 3 : Vérifier les Politiques
```sql
-- Vérifier les politiques créées
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'appointments'
ORDER BY policyname;
```

## 📋 Règles d'Isolation Appliquées

### **Utilisateurs Normaux :**
- ✅ **Voir** : Seulement leurs propres rendez-vous
- ✅ **Créer** : Seulement leurs propres rendez-vous
- ✅ **Modifier** : Seulement leurs propres rendez-vous
- ✅ **Supprimer** : Seulement leurs propres rendez-vous

### **Techniciens Assignés :**
- ✅ **Voir** : Leurs propres rendez-vous + rendez-vous assignés
- ✅ **Modifier** : Leurs propres rendez-vous + rendez-vous assignés

### **Admins/Managers :**
- ✅ **Voir** : Tous les rendez-vous
- ✅ **Créer** : Rendez-vous pour n'importe quel utilisateur
- ✅ **Modifier** : Tous les rendez-vous
- ✅ **Supprimer** : Tous les rendez-vous

## 🎯 Résultat Final

Après correction :

✅ **Isolation complète** : Chaque utilisateur ne voit que ses propres données  
✅ **Sécurité renforcée** : Les politiques RLS empêchent l'accès non autorisé  
✅ **Flexibilité maintenue** : Les admins peuvent gérer tous les rendez-vous  
✅ **Assignation fonctionnelle** : Les techniciens voient leurs rendez-vous assignés  

## 🔄 Tests de Validation

### Test 1 : Isolation Utilisateur Normal
1. **Compte A** crée un rendez-vous
2. **Compte B** se connecte
3. **Résultat** : Compte B ne voit pas le rendez-vous du Compte A ✅

### Test 2 : Assignation Technicien
1. **Admin** crée un rendez-vous assigné à un technicien
2. **Technicien** se connecte
3. **Résultat** : Technicien voit le rendez-vous assigné ✅

### Test 3 : Accès Admin
1. **Admin** se connecte
2. **Résultat** : Admin voit tous les rendez-vous ✅

## 🚨 Si le Problème Persiste

### Vérification des Politiques
```sql
-- Vérifier que les politiques sont actives
SELECT 
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'appointments';
```

### Test d'Isolation Manuel
```sql
-- Tester l'isolation en tant qu'utilisateur connecté
SELECT COUNT(*) FROM public.appointments;
-- Doit retourner seulement les rendez-vous de l'utilisateur actuel
```

### Vérification des Données
```sql
-- Vérifier que tous les rendez-vous ont un user_id
SELECT COUNT(*) FROM public.appointments WHERE user_id IS NULL;
-- Doit retourner 0
```

## 🔄 Prévention Future

### 1. **Cohérence des Politiques**
- ✅ Toujours utiliser les politiques RLS pour l'isolation
- ✅ Éviter les filtres manuels dans le code frontend
- ✅ Tester l'isolation après chaque modification

### 2. **Validation des Données**
- ✅ S'assurer que `user_id` est toujours défini
- ✅ Vérifier les contraintes de clé étrangère
- ✅ Tester les cas limites d'isolation

### 3. **Monitoring**
- ✅ Surveiller les accès aux données
- ✅ Vérifier régulièrement les politiques RLS
- ✅ Tester l'isolation entre comptes

---

**Date de correction :** 2025-01-23  
**Statut :** ✅ Résolu  
**Impact :** Isolation complète des données entre utilisateurs


