# 🔧 Dépannage - Isolation des Données par Utilisateur

## 🚨 **Problème : Les données se mélangent entre utilisateurs**

### **Symptômes**
- Compte A voit les réparations du compte B
- Compte B voit les réparations du compte A
- Les données ne sont pas isolées par utilisateur

## 🔍 **Diagnostic**

### **1. Vérifier l'état actuel**
Exécutez cette requête pour voir l'état des données :

```sql
-- Vérifier les données par utilisateur
SELECT 
    u.email,
    COUNT(r.id) as repairs_count,
    COUNT(c.id) as clients_count,
    COUNT(d.id) as devices_count
FROM public.users u
LEFT JOIN public.repairs r ON u.id = r.user_id
LEFT JOIN public.clients c ON u.id = c.user_id
LEFT JOIN public.devices d ON u.id = d.user_id
GROUP BY u.id, u.email
ORDER BY u.email;
```

### **2. Vérifier les politiques RLS**
```sql
-- Vérifier que les politiques sont actives
SELECT 
    tablename,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'devices', 'repairs', 'sales', 'appointments', 'parts', 'products', 'services')
ORDER BY tablename, policyname;
```

## 🛠️ **Solution Complète**

### **Étape 1 : Exécuter le Script de Force**
```sql
-- Copiez et exécutez le contenu de force_user_isolation.sql
-- Ce script force l'isolation complète
```

### **Étape 2 : Vérifier les Services Frontend**
Assurez-vous que tous les services incluent le `user_id` :

```typescript
// Exemple de service correct
async getAll() {
  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user) {
    return handleSupabaseError(new Error('Utilisateur non connecté'));
  }

  const { data, error } = await supabase
    .from('repairs')
    .select('*')
    .eq('user_id', user.id)  // ← IMPORTANT : Filtrage par user_id
    .order('created_at', { ascending: false });
  
  // ...
}
```

### **Étape 3 : Tester l'Isolation**
1. **Connectez-vous avec le compte A**
2. **Créez une réparation**
3. **Déconnectez-vous**
4. **Connectez-vous avec le compte B**
5. **Vérifiez que la réparation du compte A n'apparaît PAS**

## 🔧 **Corrections Manuelles**

### **Si le problème persiste, exécutez ces corrections :**

#### **1. Réassigner les données existantes**
```sql
-- Réassigner toutes les données au premier utilisateur admin
UPDATE public.repairs 
SET user_id = (
    SELECT id FROM public.users 
    WHERE role = 'admin' 
    LIMIT 1
)
WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM public.users);
```

#### **2. Forcer les politiques RLS**
```sql
-- Supprimer et recréer les politiques pour repairs
DROP POLICY IF EXISTS "Users can view own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can create own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can update own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can delete own repairs" ON public.repairs;

CREATE POLICY "Users can view own repairs" ON public.repairs
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own repairs" ON public.repairs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own repairs" ON public.repairs
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own repairs" ON public.repairs
    FOR DELETE USING (auth.uid() = user_id);
```

#### **3. Vérifier les contraintes**
```sql
-- S'assurer que user_id est NOT NULL
ALTER TABLE public.repairs ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.clients ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.devices ALTER COLUMN user_id SET NOT NULL;
```

## 🧪 **Tests de Validation**

### **Test 1 : Isolation des Réparations**
```sql
-- Connecté en tant qu'utilisateur A
-- Cette requête ne devrait retourner que les réparations de l'utilisateur A
SELECT * FROM public.repairs;
```

### **Test 2 : Création de Données**
```sql
-- Tester la création avec user_id automatique
INSERT INTO public.repairs (
    client_id, 
    device_id, 
    status, 
    description,
    user_id,  -- ← Doit être automatiquement rempli
    created_at,
    updated_at
) VALUES (
    'client-id',
    'device-id',
    'pending',
    'Test repair',
    auth.uid(),  -- ← Utilise l'utilisateur connecté
    NOW(),
    NOW()
);
```

### **Test 3 : Vérification des Politiques**
```sql
-- Vérifier que les politiques sont actives
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'repairs'
AND schemaname = 'public';
```

## 🚨 **Problèmes Courants**

### **1. Politiques RLS Désactivées**
```sql
-- Vérifier que RLS est activé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'repairs'
AND schemaname = 'public';
```

### **2. Données Sans user_id**
```sql
-- Trouver les données orphelines
SELECT COUNT(*) as orphaned_repairs
FROM public.repairs 
WHERE user_id IS NULL;
```

### **3. Services Frontend Incorrects**
Vérifiez que tous les services incluent le filtrage par `user_id` :
- `clientService.getAll()`
- `deviceService.getAll()`
- `repairService.getAll()`
- `saleService.getAll()`
- etc.

## 🔄 **Processus de Résolution**

### **1. Diagnostic Initial**
```sql
-- Exécuter le diagnostic
SELECT 'Diagnostic' as step, COUNT(*) as total_repairs FROM public.repairs;
SELECT 'Par utilisateur' as step, u.email, COUNT(r.id) as repairs 
FROM public.users u 
LEFT JOIN public.repairs r ON u.id = r.user_id 
GROUP BY u.id, u.email;
```

### **2. Application de la Solution**
```sql
-- Exécuter force_user_isolation.sql
-- Vérifier les résultats
```

### **3. Test Final**
- Testez avec deux comptes différents
- Vérifiez l'isolation complète
- Confirmez que les nouvelles données sont correctement assignées

## 📞 **Support Avancé**

Si le problème persiste après ces étapes :

1. **Vérifiez les logs Supabase** pour les erreurs RLS
2. **Testez avec des requêtes SQL directes** pour isoler le problème
3. **Vérifiez la configuration de l'authentification** dans Supabase
4. **Contactez le support** avec les logs d'erreur

---

**Objectif :** Chaque utilisateur ne doit voir QUE ses propres données ! 🎯
