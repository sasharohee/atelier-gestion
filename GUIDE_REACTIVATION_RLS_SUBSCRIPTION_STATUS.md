# 🔧 Guide de Réactivation des Politiques RLS Subscription Status

## ✅ **Script de Réactivation Créé !**

J'ai créé un script complet pour réactiver les 7 politiques RLS de la table `subscription_status` dans Supabase.

## 📋 **Les 7 Politiques RLS à Réactiver**

### **Politiques Administrateurs**
1. **`admins_can_manage_subscriptions`** - Les admins peuvent gérer toutes les souscriptions

### **Politiques Service Role**
2. **`service_role_full_access_subscription`** - Accès complet pour le service role

### **Politiques Générales**
3. **`subscription_status_select_policy`** - Politique de sélection pour utilisateurs et techniciens
4. **`subscription_status_update_policy`** - Politique de mise à jour pour utilisateurs et admins

### **Politiques Utilisateurs**
5. **`users_can_insert_own_subscription`** - Les utilisateurs peuvent créer leur souscription
6. **`users_can_update_own_subscription`** - Les utilisateurs peuvent modifier leur souscription
7. **`users_can_view_own_subscription`** - Les utilisateurs peuvent voir leur souscription

## 🚀 **Méthodes d'Exécution**

### **Méthode 1: Dashboard Supabase (Recommandé)**
1. **Ouvrir le dashboard Supabase**
2. **Aller dans SQL Editor**
3. **Copier le contenu de `reactiver_rls_subscription_status.sql`**
4. **Exécuter le script**

### **Méthode 2: Script Automatique**
```bash
# Exécuter le script de déploiement
./deploy_rls_subscription_status.sh
```

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
2. **Sélectionner la table `subscription_status`**
3. **Vérifier que les 7 politiques sont listées**
4. **Vérifier que RLS est activé (pas de bouton "Enable RLS")**

### **Vérification SQL**
```sql
-- Vérifier l'état RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'subscription_status' AND schemaname = 'public';

-- Vérifier les politiques
SELECT 
    policyname,
    cmd,
    roles
FROM pg_policies 
WHERE tablename = 'subscription_status' AND schemaname = 'public'
ORDER BY policyname;
```

## 🔍 **Détails des Politiques**

### **1. admins_can_manage_subscriptions**
```sql
CREATE POLICY "admins_can_manage_subscriptions" ON public.subscription_status
    FOR ALL
    TO public
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );
```
**Fonction** : Les administrateurs peuvent effectuer toutes les opérations sur toutes les souscriptions.

### **2. service_role_full_access_subscription**
```sql
CREATE POLICY "service_role_full_access_subscription" ON public.subscription_status
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);
```
**Fonction** : Le service role a un accès complet à la table subscription_status.

### **3. subscription_status_select_policy**
```sql
CREATE POLICY "subscription_status_select_policy" ON public.subscription_status
    FOR SELECT
    TO public
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'technician')
        )
    );
```
**Fonction** : Les utilisateurs peuvent voir leur souscription, les techniciens et admins peuvent voir toutes les souscriptions.

### **4. subscription_status_update_policy**
```sql
CREATE POLICY "subscription_status_update_policy" ON public.subscription_status
    FOR UPDATE
    TO public
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );
```
**Fonction** : Les utilisateurs peuvent modifier leur souscription, les admins peuvent modifier toutes les souscriptions.

### **5. users_can_insert_own_subscription**
```sql
CREATE POLICY "users_can_insert_own_subscription" ON public.subscription_status
    FOR INSERT
    TO public
    WITH CHECK (auth.uid() = user_id);
```
**Fonction** : Les utilisateurs peuvent créer leur propre souscription.

### **6. users_can_update_own_subscription**
```sql
CREATE POLICY "users_can_update_own_subscription" ON public.subscription_status
    FOR UPDATE
    TO public
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```
**Fonction** : Les utilisateurs peuvent modifier leur propre souscription.

### **7. users_can_view_own_subscription**
```sql
CREATE POLICY "users_can_view_own_subscription" ON public.subscription_status
    FOR SELECT
    TO public
    USING (auth.uid() = user_id);
```
**Fonction** : Les utilisateurs peuvent voir leur propre souscription.

## 🧪 **Tests de Validation**

### **Test 1: Vérification RLS Activé**
```sql
-- Doit retourner rowsecurity = true
SELECT rowsecurity FROM pg_tables WHERE tablename = 'subscription_status';
```

### **Test 2: Vérification Politiques**
```sql
-- Doit retourner 7 politiques
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'subscription_status';
```

### **Test 3: Test d'Accès (avec utilisateur connecté)**
```sql
-- Test de lecture (doit fonctionner pour l'utilisateur connecté)
SELECT * FROM public.subscription_status WHERE user_id = auth.uid();

-- Test d'insertion (doit fonctionner pour l'utilisateur connecté)
INSERT INTO public.subscription_status (user_id, status, plan) 
VALUES (auth.uid(), 'active', 'premium');

-- Test de mise à jour (doit fonctionner pour l'utilisateur connecté)
UPDATE public.subscription_status 
SET status = 'inactive' 
WHERE user_id = auth.uid();
```

## ⚠️ **Points d'Attention**

### **Sécurité**
- ✅ **RLS activé** : Protection au niveau des lignes
- ✅ **Politiques restrictives** : Chaque utilisateur ne voit que ses souscriptions
- ✅ **Admins privilégiés** : Accès complet pour les administrateurs
- ✅ **Service role** : Accès complet pour les opérations système

### **Performance**
- ✅ **Index sur user_id** : Optimisation des requêtes
- ✅ **Politiques efficaces** : Conditions simples et rapides
- ✅ **Cache des politiques** : Mise en cache par Supabase

## 🎯 **Résultat Attendu**

Après exécution du script :

### **Dashboard Supabase**
- ✅ **7 politiques** listées dans Authentication > Policies
- ✅ **RLS activé** (pas de bouton "Enable RLS")
- ✅ **Politiques actives** avec statut "Enabled"

### **Fonctionnalités**
- ✅ **Utilisateurs** : Peuvent gérer leur propre souscription
- ✅ **Techniciens** : Peuvent voir toutes les souscriptions
- ✅ **Admins** : Peuvent gérer toutes les souscriptions
- ✅ **Service role** : Accès complet pour les opérations système

## 🚨 **En Cas de Problème**

### **Erreur de Permissions**
```sql
-- Vérifier les permissions sur la table
SELECT * FROM information_schema.table_privileges 
WHERE table_name = 'subscription_status';
```

### **Politiques en Conflit**
```sql
-- Supprimer toutes les politiques et les recréer
DROP POLICY IF EXISTS "admins_can_manage_subscriptions" ON public.subscription_status;
-- ... (répéter pour toutes les politiques)
```

### **RLS Non Activé**
```sql
-- Forcer l'activation de RLS
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;
```

## 📝 **Utilisation des Souscriptions**

### **Lecture des Souscriptions**
```javascript
// Dans votre application
const { data, error } = await supabase
  .from('subscription_status')
  .select('*')
  .eq('user_id', user.id);
```

### **Création d'une Souscription**
```javascript
// Dans votre application
const { data, error } = await supabase
  .from('subscription_status')
  .insert({
    user_id: user.id,
    status: 'active',
    plan: 'premium'
  });
```

### **Mise à Jour d'une Souscription**
```javascript
// Dans votre application
const { data, error } = await supabase
  .from('subscription_status')
  .update({ status: 'inactive' })
  .eq('user_id', user.id);
```

---

**Statut** : ✅ **SCRIPT PRÊT**  
**Fichiers** : 📁 `reactiver_rls_subscription_status.sql` + `deploy_rls_subscription_status.sh`  
**Méthode** : 🚀 **AUTOMATIQUE OU MANUEL**  
**Vérification** : 🔍 **DASHBOARD SUPABASE**

