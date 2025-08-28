# Guide de Dépannage - Isolation Appointments

## 🚨 Problème Persistant

**Isolation ne fonctionne pas** : Les rendez-vous créés par un utilisateur sont toujours visibles par d'autres utilisateurs.

## 🔍 Diagnostic Complet

### 1. **Exécuter le Script de Diagnostic**
```sql
-- Exécuter : tables/diagnostic_isolation_appointments.sql
```

Ce script va :
- ✅ Vérifier la structure de la table
- ✅ Diagnostiquer les politiques RLS
- ✅ Tester l'isolation manuellement
- ✅ Corriger les données problématiques
- ✅ Réactiver RLS avec des politiques simplifiées

### 2. **Vérifications Manuelles**

#### **Vérifier RLS :**
```sql
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'appointments';
```

**Résultat attendu :**
```
schemaname: public
tablename: appointments
rowsecurity: true
```

#### **Vérifier les Politiques :**
```sql
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'appointments'
ORDER BY policyname;
```

**Résultat attendu :**
```
appointments_select_simple | SELECT | (user_id = auth.uid())
appointments_insert_simple | INSERT | (user_id = auth.uid())
appointments_update_simple | UPDATE | (user_id = auth.uid())
appointments_delete_simple | DELETE | (user_id = auth.uid())
```

#### **Tester l'Isolation :**
```sql
-- Compter tous les rendez-vous (avec RLS)
SELECT COUNT(*) FROM public.appointments;

-- Compter les rendez-vous de l'utilisateur actuel
SELECT COUNT(*) FROM public.appointments WHERE user_id = auth.uid();
```

**Les deux nombres doivent être identiques si l'isolation fonctionne.**

## 🔧 Corrections Appliquées

### 1. **Service Supabase Corrigé**
- ✅ **Authentification** : Utilise `auth.users` au lieu de `public.users`
- ✅ **Cohérence** : `auth.uid()` dans les politiques = `user.id` dans le service
- ✅ **Validation** : Vérification de l'authentification avant création/modification

### 2. **Politiques RLS Simplifiées**
```sql
-- Politique SELECT simplifiée
CREATE POLICY "appointments_select_simple" ON public.appointments
    FOR SELECT
    USING (user_id = auth.uid());
```

### 3. **Correction des Données**
- ✅ **user_id manquant** : Mise à jour automatique
- ✅ **Cohérence** : Tous les rendez-vous ont un user_id valide

## 🎯 Tests de Validation

### **Test 1 : Création de Rendez-vous**
1. **Compte A** se connecte
2. **Compte A** crée un rendez-vous
3. **Vérifier** : Le rendez-vous apparaît dans la liste

### **Test 2 : Isolation**
1. **Compte B** se connecte
2. **Vérifier** : Le rendez-vous du Compte A n'apparaît PAS
3. **Compte B** crée son propre rendez-vous
4. **Vérifier** : Seulement le rendez-vous du Compte B est visible

### **Test 3 : Changement de Compte**
1. **Compte A** se reconnecte
2. **Vérifier** : Seulement le rendez-vous du Compte A est visible

## 🚨 Si le Problème Persiste

### **Solution 1 : Vérifier l'Authentification**
```sql
-- Vérifier l'utilisateur actuel
SELECT auth.uid() as current_user;

-- Vérifier les rendez-vous de cet utilisateur
SELECT COUNT(*) FROM public.appointments WHERE user_id = auth.uid();
```

### **Solution 2 : Forcer l'Isolation**
```sql
-- Désactiver temporairement RLS pour debug
ALTER TABLE public.appointments DISABLE ROW LEVEL SECURITY;

-- Vérifier les données
SELECT user_id, COUNT(*) FROM public.appointments GROUP BY user_id;

-- Réactiver RLS
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
```

### **Solution 3 : Politiques Plus Strictes**
```sql
-- Politique ultra-stricte
DROP POLICY IF EXISTS "appointments_select_simple" ON public.appointments;
CREATE POLICY "appointments_select_strict" ON public.appointments
    FOR SELECT
    USING (
        user_id = auth.uid() AND 
        auth.uid() IS NOT NULL
    );
```

## 📋 Checklist de Vérification

### **Base de Données :**
- [ ] RLS activé sur `appointments`
- [ ] Politiques créées et actives
- [ ] Tous les rendez-vous ont un `user_id`
- [ ] `user_id` correspond à `auth.uid()`

### **Frontend :**
- [ ] Utilisateur authentifié via Supabase Auth
- [ ] Service utilise `auth.users` pour l'ID
- [ ] Pas de cache côté client
- [ ] Rechargement des données après connexion

### **Test :**
- [ ] Création de rendez-vous fonctionne
- [ ] Isolation entre comptes fonctionne
- [ ] Changement de compte fonctionne
- [ ] Pas de fuite de données

## 🔄 Actions Immédiates

1. **Exécuter le script de diagnostic** : `tables/diagnostic_isolation_appointments.sql`
2. **Vérifier les résultats** dans la console SQL
3. **Tester l'isolation** en changeant de compte
4. **Signaler les problèmes** persistants

---

**Priorité :** 🔴 URGENT  
**Impact :** Sécurité des données utilisateur  
**Solution :** Script de diagnostic + corrections automatiques


