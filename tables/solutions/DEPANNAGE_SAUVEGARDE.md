# Dépannage des boutons de sauvegarde

## Problème : Les boutons de sauvegarde ne fonctionnent plus

### Causes possibles

1. **Table system_settings non créée** dans Supabase
2. **Paramètres système non chargés** depuis la base de données
3. **Erreur dans la logique de sauvegarde**
4. **Problème de permissions** dans Supabase

### Solutions étape par étape

#### 1. Vérifier la table system_settings

**Étape 1** : Aller dans Supabase Dashboard
- Ouvrir votre projet Supabase
- Aller dans l'éditeur SQL
- Exécuter : `SELECT * FROM system_settings;`

**Résultat attendu** : La table doit exister et contenir des données

**Si la table n'existe pas** :
```sql
-- Exécuter le script complet
-- Copier et coller le contenu de create_system_settings_table.sql
```

#### 2. Vérifier les paramètres système

**Étape 2** : Vérifier dans la console du navigateur
- Ouvrir les outils de développement (F12)
- Aller dans l'onglet Console
- Recharger la page Administration
- Vérifier les logs :
  ```
  Sauvegarde des paramètres pour la catégorie: general
  Paramètres système chargés: 12
  Modifications locales: {}
  Paramètres à mettre à jour: [...]
  ```

**Si les paramètres ne se chargent pas** :
- Vérifier la connexion Supabase
- Vérifier les variables d'environnement
- Vérifier les politiques RLS

#### 3. Vérifier les permissions

**Étape 3** : Vérifier les politiques RLS
```sql
-- Vérifier les politiques existantes
SELECT * FROM pg_policies WHERE tablename = 'system_settings';
```

**Politiques requises** :
- "Admins can view system settings"
- "Admins can update system settings"
- "Admins can create system settings"
- "Admins can delete system settings"

#### 4. Test manuel de sauvegarde

**Étape 4** : Test direct dans Supabase
```sql
-- Tester la mise à jour manuelle
UPDATE system_settings 
SET value = 'Test Atelier', updated_at = NOW() 
WHERE key = 'workshop_name';
```

**Si ça fonctionne** : Le problème vient de l'application
**Si ça ne fonctionne pas** : Le problème vient de Supabase

### Debug en temps réel

#### Ajouter des logs de debug

Dans la console du navigateur, vous devriez voir :

```javascript
// Au chargement de la page
loadSystemSettings() // Appelé
systemSettings: [...] // Données chargées

// Quand vous cliquez sur Sauvegarder
Sauvegarde des paramètres pour la catégorie: general
Paramètres système chargés: 12
Modifications locales: {workshop_name: "Nouveau nom"}
Paramètres à mettre à jour: [{key: "workshop_name", value: "Nouveau nom"}]
```

#### Vérifier les erreurs

Dans la console, cherchez :
- Erreurs JavaScript (en rouge)
- Erreurs de réseau (onglet Network)
- Erreurs Supabase

### Solutions rapides

#### Solution 1 : Recharger les paramètres
```javascript
// Dans la console du navigateur
window.location.reload();
```

#### Solution 2 : Vider le cache
```javascript
// Dans la console du navigateur
localStorage.clear();
sessionStorage.clear();
window.location.reload();
```

#### Solution 3 : Forcer le rechargement des paramètres
```javascript
// Dans la console du navigateur
// Accéder au store et forcer le rechargement
// (nécessite d'être dans le contexte de l'application)
```

### Test de fonctionnement

#### Test 1 : Modification simple
1. Modifier le nom de l'atelier
2. Cliquer sur "Sauvegarder" (Paramètres généraux)
3. Vérifier la notification
4. Recharger la page
5. Vérifier que la modification persiste

#### Test 2 : Modification multiple
1. Modifier plusieurs paramètres d'une catégorie
2. Cliquer sur "Sauvegarder"
3. Vérifier que tous les paramètres sont sauvegardés

#### Test 3 : Test d'erreur
1. Déconnecter internet
2. Essayer de sauvegarder
3. Vérifier l'affichage de l'erreur
4. Reconnecter et réessayer

### Messages d'erreur courants

#### "Chargement des paramètres en cours..."
- Les paramètres ne sont pas encore chargés
- Attendre quelques secondes
- Vérifier la connexion Supabase

#### "Aucun paramètre à sauvegarder"
- Aucune modification n'a été faite
- Modifier un paramètre avant de sauvegarder

#### "Erreur lors de la sauvegarde"
- Problème de connexion ou de permissions
- Vérifier les logs dans la console
- Vérifier les politiques RLS

#### "Permission denied"
- L'utilisateur n'a pas le rôle administrateur
- Vérifier le rôle dans la table users
- Vérifier les politiques RLS

### Configuration requise

1. **Table system_settings** créée avec le bon schéma
2. **Politiques RLS** configurées correctement
3. **Utilisateur administrateur** connecté
4. **Variables d'environnement** Supabase configurées
5. **Connexion internet** stable

### Contact support

Si le problème persiste :
1. Capturer les logs de la console
2. Noter les messages d'erreur exacts
3. Vérifier la configuration Supabase
4. Tester avec un utilisateur administrateur différent
