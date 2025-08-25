# Guide de Correction - Doublons dans subscription_status

## 🚨 Problème Identifié

L'erreur `23505` indique qu'il y a des doublons dans la table `subscription_status` avec le même `user_id`, ce qui empêche l'ajout de la contrainte unique.

## 🎯 Solution

Nettoyer les doublons avant d'ajouter la contrainte unique.

## 📋 Étapes de Correction

### Étape 1 : Exécuter le Script de Nettoyage

1. **Aller** dans Supabase Dashboard > SQL Editor
2. **Créer** une nouvelle requête
3. **Copier-coller** le contenu de `tables/nettoyage_doublons_subscription_status.sql`
4. **Exécuter** le script

### Étape 2 : Vérifier les Résultats

Le script doit afficher :
```
🧹 Début du nettoyage des doublons...
✅ User 68432d4b-1747-448c-9908-483be4fdd8dd: X enregistrements supprimés, gardé ID ...
🎉 Nettoyage des doublons terminé
✅ Contrainte unique ajoutée avec succès
✅ Test d'insertion avec ON CONFLICT réussi
🎉 NETTOYAGE ET CORRECTION TERMINÉS
```

## 🔧 Ce que fait le Script

### 1. Diagnostic des Doublons
- ✅ Identifie tous les `user_id` avec des doublons
- ✅ Affiche le nombre de doublons par utilisateur
- ✅ Montre tous les enregistrements concernés

### 2. Nettoyage Intelligent
- ✅ Garde l'enregistrement le plus récent pour chaque `user_id`
- ✅ Supprime tous les autres enregistrements
- ✅ Affiche un rapport détaillé des suppressions

### 3. Ajout de la Contrainte
- ✅ Vérifie qu'il n'y a plus de doublons
- ✅ Ajoute la contrainte unique sur `user_id`
- ✅ Teste l'insertion avec `ON CONFLICT`

## 🧪 Test Après Correction

### Test 1 : Vérification des Données
```sql
-- Vérifier qu'il n'y a plus de doublons
SELECT user_id, COUNT(*) 
FROM subscription_status 
GROUP BY user_id 
HAVING COUNT(*) > 1;
```
**Résultat attendu** : Aucune ligne retournée

### Test 2 : Test d'Insertion
```sql
-- Tester l'insertion avec ON CONFLICT
INSERT INTO subscription_status (user_id, first_name, last_name, email, is_active, subscription_type, notes)
VALUES ('68432d4b-1747-448c-9908-483be4fdd8dd', 'RepPhone', 'Reparation', 'repphonereparation@gmail.com', FALSE, 'free', 'Test')
ON CONFLICT (user_id) DO UPDATE SET notes = EXCLUDED.notes, updated_at = NOW();
```
**Résultat attendu** : Succès sans erreur

### Test 3 : Application
1. **Se connecter** avec `srohee32@gmail.com` (admin)
2. **Aller** dans Administration > Gestion des Accès
3. **Tenter** d'activer un utilisateur
4. **Vérifier** les logs dans la console

## 🚨 En Cas de Problème

### Si le script échoue
1. **Vérifier** les permissions dans Supabase
2. **Contrôler** que la table existe
3. **Réessayer** l'exécution

### Si l'application ne fonctionne toujours pas
1. **Vérifier** les logs dans la console du navigateur
2. **Contrôler** que la contrainte a été ajoutée
3. **Tester** une requête SQL directe

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
...| 68432d4b| RepPhone   | Reparation| reppho| false     | free             | Test après nettoyage des doublons
```

## 🎉 Résultat Final

Après correction, vous devriez pouvoir :
- ✅ **Voir** la liste des utilisateurs dans l'administration
- ✅ **Activer** les utilisateurs sans erreur
- ✅ **Persister** les changements dans la base de données
- ✅ **Utiliser** ON CONFLICT pour les mises à jour

## 🔄 Prochaines Étapes

Une fois la correction effectuée :
1. **Tester** l'activation d'un utilisateur
2. **Vérifier** que l'utilisateur peut se connecter
3. **Documenter** la solution pour l'avenir
4. **Surveiller** les logs pour détecter d'autres problèmes

## 📝 Notes Importantes

- **Sauvegarde** : Le script garde l'enregistrement le plus récent
- **Sécurité** : Aucune donnée n'est perdue définitivement
- **Performance** : La contrainte unique améliore les performances
- **Maintenance** : Surveiller les doublons à l'avenir
