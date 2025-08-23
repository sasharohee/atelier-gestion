# Résolution rapide : Problème de chargement des paramètres

## Problème : "ça charge toujours"

Les paramètres système ne se chargent pas depuis Supabase, ce qui empêche les boutons de sauvegarde de fonctionner.

## Solution étape par étape

### Étape 1 : Vérifier la table system_settings

1. **Aller dans Supabase Dashboard**
2. **Ouvrir l'éditeur SQL**
3. **Exécuter cette requête** :
   ```sql
   SELECT EXISTS (
     SELECT FROM information_schema.tables 
     WHERE table_schema = 'public' 
     AND table_name = 'system_settings'
   ) as table_exists;
   ```

**Si le résultat est `false`** → La table n'existe pas
**Si le résultat est `true`** → La table existe

### Étape 2 : Créer la table si elle n'existe pas

**Si la table n'existe pas**, exécuter le script complet :
```sql
-- Copier et exécuter le contenu de verifier_system_settings.sql
```

### Étape 3 : Vérifier le contenu de la table

Exécuter cette requête pour voir les paramètres :
```sql
SELECT * FROM system_settings ORDER BY category, key;
```

**Résultat attendu** : 12 paramètres (4 général, 4 facturation, 4 système)

### Étape 4 : Tester dans l'application

1. **Recharger la page** Administration
2. **Ouvrir la console** (F12)
3. **Cliquer sur "Recharger paramètres"**
4. **Vérifier les logs** dans la console :
   ```
   🔄 Chargement des paramètres système...
   📊 Résultat du chargement: {success: true, data: [...]}
   ✅ Paramètres système chargés: [...]
   ```

### Étape 5 : Tester la sauvegarde

1. **Modifier un paramètre** (ex: nom de l'atelier)
2. **Cliquer sur "Sauvegarder"**
3. **Vérifier la notification** de succès
4. **Recharger la page** pour confirmer la persistance

## Messages d'erreur courants

### "Aucun paramètre système trouvé"
- La table `system_settings` est vide
- Exécuter la partie INSERT du script SQL

### "Permission denied"
- L'utilisateur n'a pas le rôle administrateur
- Vérifier le rôle dans la table `users`

### "Table does not exist"
- La table n'a pas été créée
- Exécuter le script de création complet

## Debug en temps réel

### Dans la console du navigateur

Vous devriez voir ces messages :
```
🔄 Chargement des paramètres système...
📊 Résultat du chargement: {success: true, data: [...]}
✅ Paramètres système chargés: [...]
```

### Si vous ne voyez pas ces messages

1. **Vérifier la connexion Supabase**
2. **Vérifier les variables d'environnement**
3. **Vérifier les politiques RLS**

## Test rapide

### Test 1 : Vérification de base
```sql
-- Dans Supabase SQL Editor
SELECT COUNT(*) FROM system_settings;
-- Doit retourner 12
```

### Test 2 : Test de permissions
```sql
-- Dans Supabase SQL Editor
SELECT * FROM system_settings LIMIT 1;
-- Doit retourner des données
```

### Test 3 : Test de mise à jour
```sql
-- Dans Supabase SQL Editor
UPDATE system_settings 
SET value = 'Test' 
WHERE key = 'workshop_name';
-- Doit fonctionner sans erreur
```

## Solution d'urgence

Si rien ne fonctionne, voici une solution temporaire :

1. **Créer des paramètres par défaut** dans le code
2. **Désactiver temporairement** la sauvegarde
3. **Utiliser les valeurs par défaut** jusqu'à ce que Supabase soit configuré

## Contact support

Si le problème persiste :
1. **Capturer les logs** de la console
2. **Noter les erreurs** exactes
3. **Vérifier la configuration** Supabase
4. **Tester avec un autre utilisateur** administrateur

## Checklist de validation

- [ ] Table `system_settings` existe dans Supabase
- [ ] Table contient 12 paramètres par défaut
- [ ] Politiques RLS sont configurées
- [ ] Utilisateur a le rôle administrateur
- [ ] Connexion Supabase fonctionne
- [ ] Logs de chargement apparaissent dans la console
- [ ] Boutons de sauvegarde sont activés
- [ ] Sauvegarde fonctionne et persiste
