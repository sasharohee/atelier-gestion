# 🚨 GUIDE CORRECTION URGENTE - Erreurs RLS et React

## Problèmes identifiés :
1. ❌ **Récursion infinie RLS** : `infinite recursion detected in policy for relation "users"`
2. ❌ **Erreur 406** : `subscription_status` - Not Acceptable
3. ❌ **React Hooks** : Ordre des hooks incorrect dans `SubscriptionBlocked.tsx`

## 🔧 SOLUTIONS IMMÉDIATES

### 1. CORRIGER LA RÉCURSION INFINIE RLS

**Exécuter le script SQL dans Supabase :**

1. Ouvrez votre dashboard Supabase
2. Allez dans **SQL Editor**
3. Copiez et collez le contenu du fichier `URGENT_FIX_RLS_RECURSION.sql`
4. Exécutez le script

**Ou via terminal :**
```bash
# Copier le contenu du script et l'exécuter dans Supabase
cat URGENT_FIX_RLS_RECURSION.sql
```

### 2. CORRIGER L'ERREUR 406 SUBSCRIPTION_STATUS

L'erreur 406 indique un problème de format de requête. Vérifiez que :

1. **La table `subscription_status` existe**
2. **Les colonnes sont correctement définies**
3. **Les politiques RLS permettent l'accès**

### 3. CORRIGER LES REACT HOOKS

✅ **DÉJÀ CORRIGÉ** : J'ai déplacé `useTheme()` avant les returns conditionnels dans `SubscriptionBlocked.tsx`

## 🎯 ACTIONS À EFFECTUER MAINTENANT

### Étape 1 : Appliquer la correction RLS
```sql
-- Copier et exécuter dans Supabase SQL Editor
-- Contenu du fichier : URGENT_FIX_RLS_RECURSION.sql
```

### Étape 2 : Redémarrer l'application
```bash
# Arrêter le serveur de développement
# Puis le redémarrer
npm run dev
```

### Étape 3 : Vérifier les résultats
- ✅ Plus d'erreur 500 sur `/rest/v1/users`
- ✅ Plus d'erreur de récursion infinie
- ✅ Plus d'erreur React Hooks
- ✅ L'application se charge correctement

## 🔍 VÉRIFICATIONS

### Vérifier que les politiques RLS sont correctes :
```sql
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public';
```

### Vérifier que subscription_status existe :
```sql
SELECT * FROM public.subscription_status 
WHERE user_id = '3f1ce915-f4ef-4169-b4db-5116b5fa2a5f';
```

## 📋 RÉSULTAT ATTENDU

Après ces corrections :
- ✅ L'application se charge sans erreur 500
- ✅ Les utilisateurs peuvent être récupérés
- ✅ Le statut d'abonnement fonctionne
- ✅ Plus d'erreurs React Hooks
- ✅ Interface utilisateur stable

## 🚀 PROCHAINES ÉTAPES

Une fois les erreurs corrigées :
1. Tester toutes les fonctionnalités
2. Vérifier que les données se chargent correctement
3. S'assurer que l'authentification fonctionne
4. Valider que l'interface utilisateur est stable
