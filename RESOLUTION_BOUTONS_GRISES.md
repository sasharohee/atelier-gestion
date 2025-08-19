# Résolution : Boutons de sauvegarde grisés

## Problème identifié
- ✅ Table `system_settings` existe avec 12 paramètres
- ❌ Boutons de sauvegarde grisés avec indicateur de chargement
- ❌ Paramètres ne se chargent pas depuis Supabase

## Cause probable
Les politiques RLS (Row Level Security) bloquent l'accès aux paramètres système.

## Solution immédiate

### Option 1 : Corriger les politiques RLS (Recommandé)

1. **Aller dans Supabase Dashboard**
2. **Ouvrir l'éditeur SQL**
3. **Exécuter le script** `fix_rls_policies.sql`
4. **Recharger la page** Administration

### Option 2 : Politique temporaire (Solution rapide)

Si l'option 1 ne fonctionne pas, exécuter cette requête :

```sql
-- Créer une politique temporaire pour tous les utilisateurs
CREATE POLICY "Temporary allow all" ON system_settings FOR ALL USING (true);
```

### Option 3 : Solution automatique (Déjà implémentée)

Le code a été modifié pour utiliser des paramètres par défaut si le chargement échoue.

## Test de la solution

### Après avoir exécuté le script SQL :

1. **Recharger la page** Administration
2. **Vérifier la console** (F12) pour les logs :
   ```
   🔄 Chargement des paramètres système...
   📊 Résultat du chargement: {success: true, data: [...]}
   ✅ Paramètres système chargés: [...]
   ```

3. **Vérifier que les boutons** ne sont plus grisés
4. **Tester la sauvegarde** en modifiant un paramètre

### Si les paramètres par défaut sont utilisés :

Vous verrez dans la console :
```
⚠️ Aucun paramètre système trouvé, utilisation des valeurs par défaut
📋 Utilisation des paramètres par défaut: [...]
```

## Vérification des politiques RLS

### Vérifier les politiques actuelles :
```sql
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'system_settings';
```

### Politiques attendues :
- "Allow read for authenticated users" (SELECT)
- "Allow update for admins" (UPDATE)
- "Allow insert for admins" (INSERT)
- "Allow delete for admins" (DELETE)

## Test de connexion

### Dans la page Administration :
1. **Cliquer sur "Test connexion"**
2. **Vérifier la notification** :
   - ✅ "Connexion OK: 12 paramètres"
   - ❌ "Erreur: Permission denied"

### Dans la console du navigateur :
```javascript
// Test direct
supabase.from('system_settings').select('*').then(console.log);
```

## Résolution des erreurs courantes

### Erreur "Permission denied"
- Exécuter le script `fix_rls_policies.sql`
- Ou créer la politique temporaire

### Erreur "Table does not exist"
- La table existe, vérifier le nom exact
- Vérifier le schéma (public)

### Erreur de connexion
- Vérifier les variables d'environnement
- Vérifier la connexion internet

## Solution d'urgence

Si rien ne fonctionne, les paramètres par défaut sont automatiquement chargés et les boutons devraient être actifs.

## Vérification finale

### Checklist de validation :
- [ ] Script SQL exécuté sans erreur
- [ ] Politiques RLS créées
- [ ] Page Administration rechargée
- [ ] Logs de chargement visibles dans la console
- [ ] Boutons de sauvegarde actifs (plus grisés)
- [ ] Modification d'un paramètre possible
- [ ] Sauvegarde fonctionne
- [ ] Notification de succès affichée

## Contact support

Si le problème persiste après avoir essayé toutes les solutions :
1. Capturer les logs de la console
2. Noter les erreurs exactes
3. Vérifier la configuration Supabase
4. Tester avec un autre navigateur
