# 🔧 GUIDE CORRECTION ISOLATION DEVICE_MODELS - SOLUTION FINALE

## 🎯 Problème
- ❌ Les modèles créés sur le compte A apparaissent aussi sur le compte B
- ❌ L'isolation des données ne fonctionne pas
- ❌ RLS est désactivé sur `device_models`

## 🚀 Solution
Le script `fix_device_models_isolation_final.sql` va :
1. **Réactiver RLS** sur la table `device_models`
2. **Créer des politiques strictes** qui isolent les données par `workshop_id`
3. **Permettre l'insertion** (le trigger définit automatiquement `workshop_id`)
4. **Isoler la sélection** (seuls les modèles du workshop actuel sont visibles)

## 📋 Étapes d'Exécution

### Option 1: Via l'Interface Web Supabase (Recommandé)

1. **Ouvrir Supabase Dashboard**
   - Aller sur https://supabase.com/dashboard
   - Sélectionner votre projet

2. **Accéder à l'éditeur SQL**
   - Cliquer sur "SQL Editor" dans le menu de gauche
   - Cliquer sur "New query"

3. **Exécuter le Script**
   - Copier le contenu de `fix_device_models_isolation_final.sql`
   - Coller dans l'éditeur SQL
   - Cliquer sur "Run"

### Option 2: Via Supabase CLI (si installé)

```bash
# Installer Supabase CLI si nécessaire
npm install -g supabase

# Se connecter à votre projet
supabase login
supabase link --project-ref YOUR_PROJECT_REF

# Exécuter le script
supabase db reset --linked
# Puis exécuter le script SQL via l'interface web
```

## 🔍 Vérification

### 1. Vérifier les Politiques RLS
```sql
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'device_models'
ORDER BY policyname;
```

**Résultat attendu :**
- `device_models_select_policy` : Filtre par `workshop_id`
- `device_models_insert_policy` : `WITH CHECK (true)`
- `device_models_update_policy` : Filtre par `workshop_id`
- `device_models_delete_policy` : Filtre par `workshop_id`

### 2. Tester l'Isolation
```sql
SELECT * FROM test_device_models_isolation();
```

**Résultats attendus :**
- ✅ RLS activé
- ✅ Isolation stricte
- ✅ Trigger actif

### 3. Test Manuel dans l'Application

1. **Créer un modèle sur le compte A**
   - Aller sur la page "Modèles"
   - Créer un nouveau modèle
   - Vérifier qu'il s'affiche

2. **Changer de compte (compte B)**
   - Se déconnecter
   - Se reconnecter avec un autre compte
   - Aller sur la page "Modèles"

3. **Vérifier l'isolation**
   - ❌ Le modèle créé sur le compte A ne doit PAS apparaître
   - ✅ Seuls les modèles du compte B doivent être visibles

## 🛠️ Politiques RLS Créées

### Politique SELECT (Isolation stricte)
```sql
CREATE POLICY device_models_select_policy ON device_models
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );
```

### Politique INSERT (Permissive)
```sql
CREATE POLICY device_models_insert_policy ON device_models
    FOR INSERT WITH CHECK (true);
```

### Politique UPDATE (Isolation stricte)
```sql
CREATE POLICY device_models_update_policy ON device_models
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );
```

### Politique DELETE (Isolation stricte)
```sql
CREATE POLICY device_models_delete_policy ON device_models
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );
```

## 🔧 Trigger Automatique

Le trigger `set_device_model_context` définit automatiquement :
- `workshop_id` : Depuis `system_settings`
- `created_by` : Utilisateur actuel
- `created_at` : Timestamp actuel
- `updated_at` : Timestamp actuel

## ⚠️ Points Importants

### 1. Workshop ID
- Assurez-vous qu'un `workshop_id` existe dans `system_settings`
- Le script vérifie et utilise le `workshop_id` actuel

### 2. Authentification
- L'utilisateur doit être authentifié pour que RLS fonctionne
- `auth.uid()` est utilisé pour `created_by`

### 3. Isolation
- Les politiques SELECT/UPDATE/DELETE filtrent strictement par `workshop_id`
- Seuls les modèles du workshop actuel sont visibles/modifiables

## 🚨 En Cas de Problème

### Erreur 403 (Forbidden)
```sql
-- Vérifier que RLS est activé
SELECT tablename, row_security 
FROM pg_tables 
WHERE tablename = 'device_models';
```

### Modèles non visibles
```sql
-- Vérifier le workshop_id actuel
SELECT value::UUID as workshop_id
FROM system_settings 
WHERE key = 'workshop_id';
```

### Isolation cassée
```sql
-- Vérifier les politiques
SELECT policyname, cmd, qual
FROM pg_policies 
WHERE tablename = 'device_models';
```

## ✅ Résultat Final

Après exécution du script :
- ✅ RLS activé sur `device_models`
- ✅ Politiques d'isolation strictes en place
- ✅ Trigger automatique pour définir `workshop_id`
- ✅ Insertion possible sans erreur 403
- ✅ Isolation des données par workshop
- ✅ Modèles créés sur le compte A ne sont PAS visibles sur le compte B

## 📞 Support

Si le problème persiste après exécution du script :
1. Vérifier les logs d'erreur dans la console du navigateur
2. Vérifier les politiques RLS dans Supabase Dashboard
3. Tester avec la fonction `test_device_models_isolation()`
