# 🚨 CORRECTION URGENTE : Erreur 403 System Settings

## Problème identifié
- **Erreur** : `403 (Forbidden)` sur `system_settings`
- **Cause** : Politiques RLS (Row Level Security) bloquent l'accès en production
- **Impact** : Page réglages inaccessible en production

## 🔧 Solution immédiate

### Option 1 : Via Supabase Dashboard (Recommandé)

1. **Connectez-vous à Supabase Dashboard**
   - Allez sur https://supabase.com/dashboard
   - Sélectionnez votre projet

2. **Ouvrez l'éditeur SQL**
   - Cliquez sur "SQL Editor" dans le menu de gauche

3. **Exécutez ce script de correction** :

```sql
-- Supprimer les politiques RLS problématiques
DROP POLICY IF EXISTS "Users can view their own settings" ON system_settings;
DROP POLICY IF EXISTS "Users can insert their own settings" ON system_settings;
DROP POLICY IF EXISTS "Users can update their own settings" ON system_settings;
DROP POLICY IF EXISTS "Users can delete their own settings" ON system_settings;

-- Créer une politique RLS permissive
CREATE POLICY "Enable all operations for authenticated users on system_settings"
ON system_settings
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);
```

### Option 2 : Via ligne de commande

```bash
# Exécuter le script de correction
./deploy_fix_system_settings.sh
```

## 🧪 Test de la correction

1. **Vérifiez que la correction fonctionne** :
   - Allez sur votre site Vercel : https://atelier-gestion-3ad1jtmfp-sasharohees-projects.vercel.app
   - Connectez-vous
   - Allez sur la page "Réglages"
   - Essayez de sauvegarder des paramètres

2. **Si ça ne fonctionne toujours pas** :
   - Vérifiez les logs Supabase
   - Vérifiez que l'utilisateur est bien authentifié
   - Vérifiez que la table `system_settings` existe

## 🔍 Diagnostic avancé

Si le problème persiste, exécutez ce script de diagnostic :

```sql
-- Vérifier les politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'system_settings';

-- Vérifier la structure de la table
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'system_settings';
```

## ✅ Vérification finale

Après avoir appliqué la correction :

1. ✅ Page réglages accessible
2. ✅ Sauvegarde des paramètres fonctionne
3. ✅ Pas d'erreur 403 dans la console
4. ✅ Application fonctionne en production

## 🆘 Si le problème persiste

1. **Vérifiez les variables d'environnement** :
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`

2. **Vérifiez l'authentification** :
   - L'utilisateur est-il bien connecté ?
   - Le token JWT est-il valide ?

3. **Contactez le support** avec :
   - Les logs d'erreur complets
   - L'URL de votre projet Vercel
   - L'ID de votre projet Supabase
