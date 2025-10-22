# 🔧 Guide de Réactivation des Politiques RLS Users

## ✅ **Script de Réactivation Créé !**

J'ai créé un script complet pour réactiver les 8 politiques RLS de la table `users` dans Supabase.

## 📋 **Les 8 Politiques RLS à Réactiver**

### **Politiques Administrateurs**
1. **`admins_can_manage_all_users`** - Les admins peuvent gérer tous les utilisateurs
2. **`admins_can_view_all_users`** - Les admins peuvent voir tous les utilisateurs

### **Politiques Service Role**
3. **`service_role_full_access_users`** - Accès complet pour le service role

### **Politiques Utilisateurs**
4. **`users_can_insert_own_profile`** - Les utilisateurs peuvent créer leur profil
5. **`users_can_update_own_profile`** - Les utilisateurs peuvent modifier leur profil
6. **`users_can_view_own_profile`** - Les utilisateurs peuvent voir leur profil

### **Politiques Générales**
7. **`users_select_policy`** - Politique de sélection pour utilisateurs et techniciens
8. **`users_update_policy`** - Politique de mise à jour pour utilisateurs et admins

## 🚀 **Méthodes d'Exécution**

### **Méthode 1: Script Automatique (Recommandé)**
```bash
# Exécuter le script de déploiement
./deploy_reactiver_rls_users.sh
```

### **Méthode 2: Dashboard Supabase (Manuel)**
1. **Ouvrir le dashboard Supabase**
2. **Aller dans SQL Editor**
3. **Copier le contenu de `reactiver_rls_users.sql`**
4. **Exécuter le script**

### **Méthode 3: Supabase CLI**
```bash
# Se connecter à Supabase
supabase login

# Exécuter le script
supabase db push --linked
```

## 📊 **Vérification des Politiques**

### **Vérification dans le Dashboard**
1. **Aller dans Authentication > Policies**
2. **Sélectionner la table `users`**
3. **Vérifier que les 8 politiques sont listées**
4. **Vérifier que RLS est activé (pas de bouton "Enable RLS")**

### **Vérification SQL**
```sql
-- Vérifier l'état RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- Vérifier les politiques
SELECT 
    policyname,
    cmd,
    roles
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public'
ORDER BY policyname;
```

## 🔍 **Détails des Politiques**

### **1. admins_can_manage_all_users**
```sql
CREATE POLICY "admins_can_manage_all_users" ON public.users
    FOR ALL
    TO public
    USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
```
**Fonction** : Les administrateurs peuvent effectuer toutes les opérations sur tous les utilisateurs.

### **2. admins_can_view_all_users**
```sql
CREATE POLICY "admins_can_view_all_users" ON public.users
    FOR SELECT
    TO public
    USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
```
**Fonction** : Les administrateurs peuvent voir tous les utilisateurs.

### **3. service_role_full_access_users**
```sql
CREATE POLICY "service_role_full_access_users" ON public.users
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);
```
**Fonction** : Le service role a un accès complet à la table users.

### **4. users_can_insert_own_profile**
```sql
CREATE POLICY "users_can_insert_own_profile" ON public.users
    FOR INSERT
    TO public
    WITH CHECK (auth.uid() = id);
```
**Fonction** : Les utilisateurs peuvent créer leur propre profil.

### **5. users_can_update_own_profile**
```sql
CREATE POLICY "users_can_update_own_profile" ON public.users
    FOR UPDATE
    TO public
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);
```
**Fonction** : Les utilisateurs peuvent modifier leur propre profil.

### **6. users_can_view_own_profile**
```sql
CREATE POLICY "users_can_view_own_profile" ON public.users
    FOR SELECT
    TO public
    USING (auth.uid() = id);
```
**Fonction** : Les utilisateurs peuvent voir leur propre profil.

### **7. users_select_policy**
```sql
CREATE POLICY "users_select_policy" ON public.users
    FOR SELECT
    TO public
    USING (
        auth.uid() = id OR
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'technician'))
    );
```
**Fonction** : Les utilisateurs peuvent voir leur profil, les techniciens et admins peuvent voir tous les utilisateurs.

### **8. users_update_policy**
```sql
CREATE POLICY "users_update_policy" ON public.users
    FOR UPDATE
    TO public
    USING (
        auth.uid() = id OR
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    )
    WITH CHECK (
        auth.uid() = id OR
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );
```
**Fonction** : Les utilisateurs peuvent modifier leur profil, les admins peuvent modifier tous les profils.

## 🧪 **Tests de Validation**

### **Test 1: Vérification RLS Activé**
```sql
-- Doit retourner rowsecurity = true
SELECT rowsecurity FROM pg_tables WHERE tablename = 'users';
```

### **Test 2: Vérification Politiques**
```sql
-- Doit retourner 8 politiques
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'users';
```

### **Test 3: Test d'Accès (avec utilisateur connecté)**
```sql
-- Test de lecture
SELECT COUNT(*) FROM public.users;

-- Test d'insertion (si autorisé)
INSERT INTO public.users (id, email, role) VALUES (auth.uid(), 'test@example.com', 'user');
```

## ⚠️ **Points d'Attention**

### **Sécurité**
- ✅ **RLS activé** : Protection au niveau des lignes
- ✅ **Politiques restrictives** : Chaque utilisateur ne voit que ses données
- ✅ **Admins privilégiés** : Accès complet pour les administrateurs
- ✅ **Service role** : Accès complet pour les opérations système

### **Performance**
- ✅ **Index sur auth.uid()** : Optimisation des requêtes
- ✅ **Politiques efficaces** : Conditions simples et rapides
- ✅ **Cache des politiques** : Mise en cache par Supabase

## 🎯 **Résultat Attendu**

Après exécution du script :

### **Dashboard Supabase**
- ✅ **8 politiques** listées dans Authentication > Policies
- ✅ **RLS activé** (pas de bouton "Enable RLS")
- ✅ **Politiques actives** avec statut "Enabled"

### **Fonctionnalités**
- ✅ **Utilisateurs** : Peuvent gérer leur propre profil
- ✅ **Techniciens** : Peuvent voir tous les utilisateurs
- ✅ **Admins** : Peuvent gérer tous les utilisateurs
- ✅ **Service role** : Accès complet pour les opérations système

## 🚨 **En Cas de Problème**

### **Erreur de Permissions**
```sql
-- Vérifier les permissions sur la table
SELECT * FROM information_schema.table_privileges 
WHERE table_name = 'users';
```

### **Politiques en Conflit**
```sql
-- Supprimer toutes les politiques et les recréer
DROP POLICY IF EXISTS "admins_can_manage_all_users" ON public.users;
-- ... (répéter pour toutes les politiques)
```

### **RLS Non Activé**
```sql
-- Forcer l'activation de RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
```

---

**Statut** : ✅ **SCRIPT PRÊT**  
**Fichiers** : 📁 `reactiver_rls_users.sql` + `deploy_reactiver_rls_users.sh`  
**Méthode** : 🚀 **AUTOMATIQUE OU MANUEL**  
**Vérification** : 🔍 **DASHBOARD SUPABASE**

