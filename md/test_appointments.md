# Guide de test pour les rendez-vous

## Test 1 : Création d'un rendez-vous simple

### Étapes :
1. Allez dans la page **Calendrier**
2. Cliquez sur **"Nouveau rendez-vous"**
3. Remplissez uniquement :
   - **Titre** : "Test rendez-vous"
   - **Description** : "Test de création"
   - **Date de début** : Aujourd'hui à 14h00
   - **Date de fin** : Aujourd'hui à 15h00
4. Laissez les autres champs vides
5. Cliquez sur **"Créer"**

### Résultat attendu :
- ✅ Le rendez-vous est créé sans erreur
- ✅ Il apparaît dans le calendrier
- ✅ Pas d'erreurs dans la console

## Test 2 : Création d'un rendez-vous avec assignation

### Étapes :
1. Créez un nouveau rendez-vous
2. Remplissez :
   - **Titre** : "Rendez-vous avec technicien"
   - **Client** : Sélectionnez un client existant
   - **Assigné à** : Sélectionnez un technicien
   - **Réparation** : Sélectionnez une réparation existante
3. Cliquez sur **"Créer"**

### Résultat attendu :
- ✅ Le rendez-vous est créé avec toutes les relations
- ✅ Les informations s'affichent correctement dans le calendrier

## Test 3 : Modification d'un rendez-vous

### Étapes :
1. Cliquez sur un rendez-vous existant dans le calendrier
2. Modifiez le titre
3. Cliquez sur **"Modifier"**

### Résultat attendu :
- ✅ Les modifications sont sauvegardées
- ✅ Le rendez-vous mis à jour s'affiche correctement

## Test 4 : Suppression d'un rendez-vous

### Étapes :
1. Cliquez sur un rendez-vous existant
2. Cliquez sur **"Supprimer"**
3. Confirmez la suppression

### Résultat attendu :
- ✅ Le rendez-vous est supprimé
- ✅ Il disparaît du calendrier

## Test 5 : Vérification des avertissements

### Étapes :
1. Ouvrez la console du navigateur (F12)
2. Créez/modifiez des rendez-vous
3. Observez les messages dans la console

### Résultat attendu :
- ✅ Pas d'avertissements MUI sur les composants Select
- ✅ Pas d'erreurs Supabase
- ✅ Connexion Supabase réussie

## Test 6 : Test des valeurs vides

### Étapes :
1. Créez un rendez-vous avec des champs optionnels vides
2. Modifiez-le pour ajouter des valeurs
3. Modifiez-le pour retirer des valeurs

### Résultat attendu :
- ✅ Les champs vides sont gérés correctement
- ✅ Pas d'erreurs de validation
- ✅ Les modifications sont sauvegardées

## Vérification de la base de données

### Dans Supabase :
1. Allez dans l'éditeur SQL
2. Exécutez : `SELECT * FROM appointments ORDER BY created_at DESC LIMIT 5;`

### Résultat attendu :
- ✅ Les rendez-vous sont bien enregistrés
- ✅ Les champs optionnels sont `NULL` quand non remplis
- ✅ Les relations avec clients, réparations et utilisateurs sont correctes

## Dépannage

### Si vous voyez encore des erreurs :

1. **Erreur UUID** : Vérifiez que le script SQL a été exécuté
2. **Avertissements MUI** : Vérifiez que l'application a été redémarrée
3. **Problèmes de connexion** : Vérifiez les paramètres Supabase

### Messages de succès :
- ✅ "Table appointments corrigée avec succès !"
- ✅ "✅ Connexion Supabase réussie"
- ✅ Pas d'erreurs dans la console
