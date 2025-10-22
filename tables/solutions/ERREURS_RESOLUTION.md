# Guide de résolution des erreurs

## Erreurs rencontrées et solutions

### 1. Erreur de connexion Chrome Extension
```
Unchecked runtime.lastError: Could not establish connection. Receiving end does not exist.
```

**Cause :** Extension Chrome qui essaie de se connecter à une page qui n'existe plus.

**Solution :** Cette erreur est bénigne et n'affecte pas l'application. Vous pouvez l'ignorer ou désactiver les extensions Chrome pour le développement.

### 2. Erreur de base de données Supabase
```
Could not find the 'clientId' column of 'sales' in the schema cache
```

**Cause :** Incompatibilité entre le code TypeScript (camelCase) et la structure de la base de données (snake_case).

**Solution :** 

1. **Exécuter le script de mise à jour de la base de données :**
   ```sql
   -- Exécuter le contenu du fichier update_database.sql dans l'éditeur SQL de Supabase
   ```

2. **Les modifications apportées au code :**
   - `src/services/supabaseService.ts` : Ajout de conversion camelCase ↔ snake_case
   - `database_setup.sql` : Structure corrigée de la table sales
   - `update_database.sql` : Script de mise à jour

### 3. Erreur de validation DOM
```
Warning: validateDOMNesting(...): <div> cannot appear as a descendant of <p>.
```

**Cause :** Élément `<div>` à l'intérieur d'un élément `<p>`, ce qui n'est pas valide en HTML.

**Solution :** 
- Remplacer les éléments `<p>` par des `<div>` ou des `<span>` quand ils contiennent des éléments `<div>`
- Utiliser `component="div"` sur les composants Typography de Material-UI

### 4. Erreur react-beautiful-dnd avec React 18
```
Warning: Connect(Droppable): Support for defaultProps will be removed from memo components in a future major release.
```

**Cause :** `react-beautiful-dnd` utilise `defaultProps` qui est déprécié dans React 18.

**Solution :** 
- Remplacer `react-beautiful-dnd` par `@hello-pangea/dnd` (fork compatible React 18)
- Voir le guide détaillé dans `MISE_A_JOUR_REACT_BEAUTIFUL_DND.md`

### 5. Erreur lors de la création de réparations
```
Could not find the 'clientId' column of 'repairs' in the schema cache
```

**Cause :** Même problème que pour les ventes - incompatibilité camelCase/snake_case dans la table `repairs`.

**Solution :** 
- Correction du service `repairService` avec conversion automatique
- Mise à jour de la structure de la table `repairs` dans la base de données
- Voir les modifications dans `src/services/supabaseService.ts`

## Étapes de résolution

### Étape 1 : Mettre à jour la base de données
1. Aller dans votre projet Supabase
2. Ouvrir l'éditeur SQL
3. Exécuter le contenu du fichier `update_database.sql`

### Étape 2 : Vérifier la structure de la table sales
La table `sales` doit avoir les colonnes suivantes :
- `id` (UUID, PRIMARY KEY)
- `client_id` (UUID, FOREIGN KEY)
- `items` (JSONB)
- `subtotal` (DECIMAL)
- `tax` (DECIMAL)
- `total` (DECIMAL)
- `payment_method` (TEXT)
- `status` (TEXT)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### Étape 3 : Tester l'application
1. Redémarrer le serveur de développement
2. Tester la création d'une nouvelle vente
3. Vérifier que les erreurs ont disparu

## Vérification

Après avoir appliqué les corrections :

1. **Vérifier la connexion Supabase :**
   - Les messages "✅ Connexion Supabase réussie" doivent apparaître
   - Plus d'erreurs "Could not find the 'clientId' column"

2. **Tester les ventes :**
   - Créer une nouvelle vente
   - Vérifier qu'elle s'enregistre correctement
   - Vérifier qu'elle apparaît dans la liste

3. **Vérifier la console :**
   - Plus d'erreurs de validation DOM
   - Plus d'erreurs Supabase

## En cas de problème persistant

1. **Vider le cache du navigateur**
2. **Redémarrer le serveur de développement**
3. **Vérifier les logs Supabase** dans le dashboard
4. **Contacter le support** si nécessaire

## Notes importantes

- Les modifications apportées sont rétrocompatibles
- Les données existantes ne seront pas perdues
- Le script de mise à jour est sécurisé et vérifie l'existence des colonnes avant de les ajouter
