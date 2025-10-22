# GUIDE DE VÉRIFICATION DE L'ISOLATION DES DONNÉES

## Vue d'ensemble

Ce guide vous aide à vérifier que l'atelier de gestion applique correctement la règle d'isolation des données par compte utilisateur. L'isolation garantit que chaque utilisateur ne peut voir et modifier que ses propres données.

## Scripts de vérification disponibles

### 1. `verifier_structure_tables.sql`
**Objectif** : Vérifier la structure exacte des tables avant les vérifications d'isolation.

**Utilisation** :
```sql
-- Exécuter dans Supabase SQL Editor
\i verifier_structure_tables.sql
```

**Ce qu'il vérifie** :
- Structure de toutes les tables principales
- Existence des colonnes `user_id`
- Types de données des colonnes

### 2. `verifier_isolation_robuste.sql`
**Objectif** : Vérification complète de l'isolation avec gestion d'erreurs.

**Utilisation** :
```sql
-- Exécuter dans Supabase SQL Editor
\i verifier_isolation_robuste.sql
```

**Ce qu'il vérifie** :
- Existence des tables et colonnes
- Isolation des données par utilisateur
- Résumé global de l'isolation

### 2bis. `verifier_isolation_ultra_robuste.sql`
**Objectif** : Vérification ultra-robuste avec vérification de chaque colonne avant utilisation.

**Utilisation** :
```sql
-- Exécuter dans Supabase SQL Editor
\i verifier_isolation_ultra_robuste.sql
```

**Ce qu'il vérifie** :
- Existence de chaque colonne avant utilisation
- Diagnostic détaillé par table
- Gestion complète des erreurs de colonnes manquantes

### 2ter. `verifier_isolation_simple.sql` ⭐ (Recommandé pour éviter les erreurs)
**Objectif** : Vérification simple qui évite les colonnes problématiques.

**Utilisation** :
```sql
-- Exécuter dans Supabase SQL Editor
\i verifier_isolation_simple.sql
```

**Ce qu'il vérifie** :
- Isolation de base sans colonnes problématiques
- Vérification des colonnes `user_id` uniquement
- Résumé simple et fiable

### 3. `verifier_politiques_rls.sql`
**Objectif** : Vérifier et corriger les politiques RLS (Row Level Security).

**Utilisation** :
```sql
-- Exécuter dans Supabase SQL Editor
\i verifier_politiques_rls.sql
```

**Ce qu'il fait** :
- Active RLS sur toutes les tables
- Crée les politiques d'isolation
- Vérifie que les politiques sont en place

### 4. `corriger_isolation_tables.sql`
**Objectif** : Corriger l'isolation en ajoutant les colonnes manquantes.

**Utilisation** :
```sql
-- Exécuter dans Supabase SQL Editor
\i corriger_isolation_tables.sql
```

**Ce qu'il fait** :
- Ajoute les colonnes `user_id` manquantes
- Assigne les données existantes à un utilisateur par défaut
- Crée les index pour optimiser les performances

## Ordre d'exécution recommandé

1. **Vérification initiale** :
   ```sql
   \i verifier_structure_tables.sql
   ```

2. **Correction si nécessaire** :
   ```sql
   \i corriger_isolation_tables.sql
   ```

3. **Vérification des politiques RLS** :
   ```sql
   \i verifier_politiques_rls.sql
   ```

4. **Vérification finale** :
   ```sql
   \i verifier_isolation_simple.sql
   ```

## Interprétation des résultats

### Statuts d'isolation

- **ISOLÉ** : Chaque utilisateur ne voit que ses propres données ✅
- **MULTI-UTILISATEUR** : Plusieurs utilisateurs partagent des données ❌
- **VIDE** : Aucune donnée dans la table ℹ️
- **NON ISOLÉ** : Données sans colonne `user_id` ❌

### Exemple de résultats attendus

```sql
check_type              | table_name    | unique_users | total_records | isolation_status
------------------------|---------------|--------------|---------------|------------------
Résumé isolation robuste | clients       | 1            | 25            | ISOLÉ
Résumé isolation robuste | devices       | 1            | 15            | ISOLÉ
Résumé isolation robuste | services      | 1            | 8             | ISOLÉ
Résumé isolation robuste | parts         | 1            | 45            | ISOLÉ
Résumé isolation robuste | products      | 1            | 12            | ISOLÉ
Résumé isolation robuste | repairs       | 1            | 30            | ISOLÉ
Résumé isolation robuste | appointments  | 1            | 18            | ISOLÉ
Résumé isolation robuste | sales         | 1            | 22            | ISOLÉ
Résumé isolation robuste | messages      | 1            | 5             | ISOLÉ
```

## Vérification dans l'application

### 1. Test avec plusieurs utilisateurs

1. Créez deux comptes utilisateurs différents
2. Connectez-vous avec le premier utilisateur
3. Créez des données (clients, réparations, etc.)
4. Déconnectez-vous et connectez-vous avec le second utilisateur
5. Vérifiez que vous ne voyez pas les données du premier utilisateur

### 2. Vérification des services

Dans `src/services/supabaseService.ts`, tous les services doivent :
- Récupérer l'utilisateur connecté : `const { data: { user } } = await supabase.auth.getUser()`
- Filtrer par `user_id` : `.eq('user_id', user.id)`

### 3. Vérification des politiques RLS

Les politiques RLS doivent être de la forme :
```sql
CREATE POLICY "Users can view own data" ON public.table_name
    FOR SELECT USING (auth.uid() = user_id);
```

## Problèmes courants et solutions

### Problème : Colonne `user_id` manquante
**Solution** : Exécuter `corriger_isolation_tables.sql`

### Problème : Données partagées entre utilisateurs
**Solution** : 
1. Vérifier les politiques RLS
2. S'assurer que les services filtrent par `user_id`
3. Corriger les données existantes

### Problème : Erreur "column does not exist"
**Solution** : 
1. Vérifier la structure avec `verifier_structure_tables.sql`
2. Corriger les scripts si nécessaire
3. Utiliser `verifier_isolation_robuste.sql` qui gère les erreurs

## Tables concernées par l'isolation

- ✅ `clients` - Clients de l'atelier
- ✅ `devices` - Appareils des clients
- ✅ `services` - Services proposés
- ✅ `parts` - Pièces détachées
- ✅ `products` - Produits en vente
- ✅ `repairs` - Réparations
- ✅ `appointments` - Rendez-vous
- ✅ `sales` - Ventes
- ✅ `messages` - Messages internes
- ✅ `system_settings` - Paramètres système

## Sécurité

L'isolation des données est cruciale pour :
- Protéger la confidentialité des données clients
- Éviter les fuites d'informations entre ateliers
- Respecter le RGPD et autres réglementations
- Maintenir l'intégrité des données

## Maintenance

Exécutez ces vérifications :
- Après chaque déploiement
- Lors de l'ajout de nouvelles tables
- En cas de modification des politiques RLS
- Régulièrement pour s'assurer de la conformité

## Support

En cas de problème :
1. Vérifiez les logs d'erreur
2. Exécutez les scripts de diagnostic
3. Consultez la documentation Supabase sur RLS
4. Contactez l'équipe de développement
