# Test de la page Administration

## Prérequis

1. Avoir un compte Supabase configuré
2. Avoir exécuté le script `create_users_table.sql`
3. Avoir au moins un utilisateur administrateur dans le système

## Tests à effectuer

### 1. Test de chargement de la page

**Objectif** : Vérifier que la page se charge correctement

**Étapes** :
1. Naviguer vers la page Administration
2. Vérifier que l'en-tête s'affiche correctement
3. Vérifier que les statistiques se chargent
4. Vérifier que la liste des utilisateurs s'affiche

**Résultat attendu** :
- Page chargée sans erreur
- Statistiques affichées avec des valeurs
- Liste des utilisateurs visible

### 2. Test de création d'utilisateur

**Objectif** : Vérifier la création d'un nouvel utilisateur

**Étapes** :
1. Cliquer sur "Nouvel utilisateur"
2. Remplir le formulaire avec des données valides :
   - Prénom : "Test"
   - Nom : "User"
   - Email : "test@example.com"
   - Mot de passe : "password123"
   - Rôle : "Technicien"
3. Cliquer sur "Créer"
4. Vérifier que l'utilisateur apparaît dans la liste

**Résultat attendu** :
- Formulaire s'ouvre correctement
- Validation des champs fonctionne
- Utilisateur créé avec succès
- Notification de succès affichée
- Nouvel utilisateur visible dans la liste

### 3. Test de validation des formulaires

**Objectif** : Vérifier la validation des champs

**Étapes** :
1. Ouvrir le formulaire de création d'utilisateur
2. Tester les cas suivants :
   - Prénom vide
   - Nom vide
   - Email invalide
   - Mot de passe trop court
   - Aucun rôle sélectionné
3. Vérifier les messages d'erreur

**Résultat attendu** :
- Messages d'erreur appropriés pour chaque cas
- Bouton "Créer" désactivé si validation échoue

### 4. Test de modification d'utilisateur

**Objectif** : Vérifier la modification d'un utilisateur existant

**Étapes** :
1. Cliquer sur l'icône "Modifier" d'un utilisateur
2. Modifier le prénom
3. Cliquer sur "Modifier"
4. Vérifier que les changements sont sauvegardés

**Résultat attendu** :
- Formulaire de modification s'ouvre avec les données actuelles
- Modification sauvegardée avec succès
- Changements visibles dans la liste

### 5. Test de suppression d'utilisateur

**Objectif** : Vérifier la suppression d'un utilisateur

**Étapes** :
1. Cliquer sur l'icône "Supprimer" d'un utilisateur
2. Confirmer la suppression
3. Vérifier que l'utilisateur disparaît de la liste

**Résultat attendu** :
- Boîte de dialogue de confirmation s'affiche
- Utilisateur supprimé après confirmation
- Notification de succès affichée

### 6. Test de protection contre l'auto-suppression

**Objectif** : Vérifier qu'un utilisateur ne peut pas se supprimer

**Étapes** :
1. Se connecter avec un compte administrateur
2. Vérifier que l'icône "Supprimer" n'apparaît pas pour son propre compte
3. Vérifier que l'icône "Modifier" est désactivée

**Résultat attendu** :
- Pas d'icône de suppression pour l'utilisateur connecté
- Icône de modification désactivée

### 7. Test des paramètres système

**Objectif** : Vérifier la sauvegarde des paramètres

**Étapes** :
1. Modifier le nom de l'atelier
2. Cliquer sur "Sauvegarder"
3. Vérifier la notification de succès
4. Recharger la page et vérifier que le changement persiste

**Résultat attendu** :
- Paramètres modifiables
- Sauvegarde fonctionnelle
- Notification de succès
- Changements persistants

### 8. Test de gestion des erreurs

**Objectif** : Vérifier la gestion des erreurs

**Étapes** :
1. Simuler une erreur de réseau (déconnecter internet)
2. Essayer de créer un utilisateur
3. Vérifier l'affichage de l'erreur
4. Reconnecter internet et réessayer

**Résultat attendu** :
- Erreur affichée clairement
- Possibilité de réessayer après correction

### 9. Test de performance

**Objectif** : Vérifier les performances avec beaucoup d'utilisateurs

**Étapes** :
1. Créer plusieurs utilisateurs (10-20)
2. Vérifier le temps de chargement de la liste
3. Tester la pagination si implémentée

**Résultat attendu** :
- Chargement rapide de la liste
- Interface responsive

### 10. Test de sécurité

**Objectif** : Vérifier les contrôles d'accès

**Étapes** :
1. Se connecter avec un compte non-administrateur
2. Essayer d'accéder à la page d'administration
3. Vérifier les restrictions d'accès

**Résultat attendu** :
- Accès restreint pour les non-administrateurs
- Messages d'erreur appropriés

## Checklist de validation

- [ ] Page se charge correctement
- [ ] Statistiques s'affichent
- [ ] Liste des utilisateurs se charge
- [ ] Création d'utilisateur fonctionne
- [ ] Validation des formulaires fonctionne
- [ ] Modification d'utilisateur fonctionne
- [ ] Suppression d'utilisateur fonctionne
- [ ] Protection contre l'auto-suppression
- [ ] Paramètres système sauvegardables
- [ ] Gestion des erreurs appropriée
- [ ] Performance acceptable
- [ ] Contrôles de sécurité en place

## Problèmes connus

1. **Dépendance à Supabase** : La page nécessite une connexion Supabase fonctionnelle
2. **Permissions** : Les utilisateurs doivent avoir les bonnes permissions dans Supabase
3. **Table users** : La table doit être créée avec le bon schéma

## Solutions de dépannage

### Erreur "Table users does not exist"
- Exécuter le script `create_users_table.sql` dans Supabase

### Erreur "Permission denied"
- Vérifier que l'utilisateur a le rôle administrateur
- Vérifier les politiques RLS dans Supabase

### Erreur de connexion
- Vérifier les variables d'environnement Supabase
- Vérifier la connexion internet

## Notes

- Les tests doivent être effectués dans un environnement de développement
- Sauvegarder les données importantes avant les tests
- Documenter tout problème rencontré
