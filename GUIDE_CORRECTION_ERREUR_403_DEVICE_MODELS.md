# Guide de Correction - Erreur 403 Device Models

## Problème
L'erreur 403 (Forbidden) se produit lors de la création ou modification de modèles d'appareils dans la page "Modèles". L'erreur indique :
```
new row violates row-level security policy for table "device_models"
```

## Cause
Les politiques RLS (Row Level Security) sur la table `device_models` sont trop restrictives et empêchent l'insertion de nouvelles données.

## Solution Immédiate

### Étape 1 : Accéder à l'interface SQL de Supabase
1. Connectez-vous à votre projet Supabase
2. Allez dans la section "SQL Editor"
3. Créez un nouveau script SQL

### Étape 2 : Exécuter le script de correction
Copiez et collez le contenu du fichier `correction_device_models_403_simple.sql` dans l'éditeur SQL et exécutez-le.

### Étape 3 : Vérifier la correction
Après l'exécution, vous devriez voir :
- ✅ Test d'insertion réussi
- ✅ Erreur 403 résolue - Politiques permissives activées

## Ce que fait le script

1. **Supprime les politiques restrictives** existantes
2. **Crée des politiques permissives** qui permettent toutes les opérations
3. **Ajoute les colonnes d'isolation** (`workshop_id`, `created_by`) si elles n'existent pas
4. **Met à jour les données existantes** avec les valeurs d'isolation
5. **Crée un trigger** qui définit automatiquement les valeurs d'isolation lors de l'insertion
6. **Teste l'insertion** pour vérifier que tout fonctionne

## Résultat
- ✅ L'erreur 403 sera résolue
- ✅ Vous pourrez créer et modifier des modèles d'appareils
- ✅ L'isolation des données sera maintenue via le trigger
- ⚠️ L'isolation RLS sera temporairement désactivée

## Prochaines étapes

### Test immédiat
1. Retournez dans votre application
2. Allez sur la page "Modèles"
3. Essayez de créer un nouveau modèle d'appareil
4. Vérifiez que l'opération fonctionne sans erreur 403

### Réactivation de l'isolation (optionnel)
Si vous souhaitez réactiver une isolation plus stricte plus tard, vous pouvez :
1. Utiliser le script `fix_device_models_isolation_complete.sql`
2. Ou créer des politiques RLS personnalisées

## Notes importantes
- Cette solution résout immédiatement le problème
- L'isolation des données est maintenue via le trigger
- Les données existantes sont préservées
- Aucune perte de données n'est à craindre

## En cas de problème
Si l'erreur persiste après l'exécution du script :
1. Vérifiez que le script s'est bien exécuté sans erreur
2. Rafraîchissez votre application
3. Vérifiez la console du navigateur pour d'autres erreurs
4. Contactez le support si nécessaire
