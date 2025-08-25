# Guide de Correction Immédiate - Table subscription_status

## 🚨 Problème Actuel

L'erreur 406 empêche l'accès à la table `subscription_status`, ce qui rend impossible l'activation des utilisateurs depuis la page d'administration.

## 🎯 Solution

Exécuter le script SQL pour corriger les permissions et permettre l'accès à la table.

## 📋 Étapes de Correction

### Étape 1 : Accéder à Supabase

1. **Ouvrir** [Supabase Dashboard](https://supabase.com/dashboard)
2. **Sélectionner** votre projet
3. **Aller** dans l'onglet "SQL Editor"

### Étape 2 : Exécuter le Script

1. **Créer** une nouvelle requête
2. **Copier-coller** le contenu du fichier `tables/correction_immediate_subscription_status.sql`
3. **Exécuter** le script

### Étape 3 : Vérifier les Résultats

Le script doit afficher :
```
🎉 CORRECTION TERMINÉE
✅ Table subscription_status accessible
✅ Permissions configurées
✅ RLS désactivé
✅ Données utilisateur insérées
✅ Prêt pour les tests d'activation
```

## 🔧 Ce que fait le Script

### 1. Vérification et Création
- ✅ Vérifie si la table existe
- ✅ Crée la table si nécessaire
- ✅ Configure la structure appropriée

### 2. Permissions
- ✅ Désactive RLS temporairement
- ✅ Configure les permissions pour tous les rôles
- ✅ Crée les index nécessaires

### 3. Données Initiales
- ✅ Insère l'utilisateur `repphonereparation@gmail.com`
- ✅ Configure l'accès restreint par défaut
- ✅ Prépare pour l'activation par l'admin

## 🧪 Test Après Correction

### Test 1 : Page d'Administration
1. **Se connecter** avec `srohee32@gmail.com`
2. **Aller** dans Administration > Gestion des Accès
3. **Vérifier** que la liste des utilisateurs s'affiche
4. **Cliquer** sur "Activer" pour l'utilisateur normal

### Test 2 : Activation Réelle
1. **Dans la console**, vérifier les logs :
   ```
   ✅ Tentative d'activation pour l'utilisateur 68432d4b-1747-448c-9908-483be4fdd8dd
   ✅ Activation réussie dans la table
   ```

### Test 3 : Connexion Utilisateur
1. **Se connecter** avec `repphonereparation@gmail.com`
2. **Vérifier** que l'accès est maintenant autorisé
3. **Naviguer** dans l'application

## 🚨 En Cas de Problème

### Si l'erreur 406 persiste
1. **Vérifier** que le script s'est bien exécuté
2. **Contrôler** les logs dans la console Supabase
3. **Réessayer** l'exécution du script

### Si l'activation ne fonctionne pas
1. **Vérifier** les logs dans la console du navigateur
2. **Contrôler** que la table contient les données
3. **Tester** avec une requête SQL directe

## 📊 Vérification des Données

### Requête de Vérification
```sql
SELECT 
    id,
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    created_at
FROM subscription_status
ORDER BY created_at DESC;
```

### Résultat Attendu
```
id | user_id | first_name | last_name | email | is_active | subscription_type | notes
---|---------|------------|-----------|-------|-----------|-------------------|------
...| 68432d4b| RepPhone   | Reparation| reppho| false     | free             | Compte créé - en attente d'activation
```

## 🎉 Résultat Final

Après correction, vous devriez pouvoir :
- ✅ **Voir** la liste des utilisateurs dans l'administration
- ✅ **Activer** les utilisateurs normalement
- ✅ **Persister** les changements dans la base de données
- ✅ **Donner l'accès** aux utilisateurs sans erreur 406

## 🔄 Prochaines Étapes

Une fois la correction effectuée :
1. **Tester** l'activation d'un utilisateur
2. **Vérifier** que l'utilisateur peut se connecter
3. **Réactiver RLS** si nécessaire (optionnel)
4. **Documenter** la solution pour l'avenir
