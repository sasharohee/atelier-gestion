# 🔧 CORRECTION RÉCURSION INFINIE - TABLE USERS

## 🚨 PROBLÈME IDENTIFIÉ
L'erreur `infinite recursion detected in policy for relation "users"` indique que les politiques RLS (Row Level Security) de la table `users` créent une boucle infinie.

## 🎯 SOLUTION IMMÉDIATE

### Étape 1 : Accéder à l'interface SQL de Supabase
1. Allez sur https://supabase.com/dashboard
2. Connectez-vous à votre compte
3. Sélectionnez votre projet `wlqyrmntfxwdvkzzsujv`
4. Cliquez sur "SQL Editor" dans le menu de gauche

### Étape 2 : Exécuter le script de correction
1. Créez un nouveau script SQL
2. Copiez-collez le contenu du fichier `fix_users_recursion_immediate.sql`
3. Cliquez sur "Run" pour exécuter le script

### Étape 3 : Vérification
Le script devrait afficher :
```
status              | policies_count
--------------------|----------------
Correction terminée | 1
```

## 🔍 CE QUE FAIT LE SCRIPT

1. **Désactive temporairement RLS** sur la table `users`
2. **Supprime toutes les politiques existantes** qui causent la récursion
3. **Réactive RLS** avec une politique simple et sécurisée
4. **Crée une seule politique** : `users_self_access` qui permet à chaque utilisateur d'accéder à son propre profil

## ✅ RÉSULTAT ATTENDU

Après l'exécution du script :
- ✅ La page Administration devrait se charger sans erreur
- ✅ Les utilisateurs pourront voir leur propre profil
- ✅ Plus de récursion infinie
- ✅ Sécurité maintenue (chaque utilisateur ne voit que ses données)

## 🧪 TEST DE VÉRIFICATION

Après avoir exécuté le script, testez la page Administration :
1. Rechargez la page Administration
2. Vérifiez qu'il n'y a plus d'erreur `infinite recursion`
3. Confirmez que les données utilisateur se chargent correctement

## 🚀 ALTERNATIVE RAPIDE

Si vous préférez, vous pouvez aussi utiliser le script existant `fix_users_recursion_aggressive.sql` qui fait la même chose mais avec plus de vérifications.

## 📞 EN CAS DE PROBLÈME

Si l'erreur persiste après l'exécution du script :
1. Vérifiez que le script s'est bien exécuté (pas d'erreur dans l'interface SQL)
2. Attendez quelques secondes et rechargez la page Administration
3. Vérifiez les logs de la console pour confirmer l'absence d'erreur de récursion
