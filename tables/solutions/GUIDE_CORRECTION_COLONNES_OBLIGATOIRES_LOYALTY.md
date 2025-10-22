# Guide de Correction - Colonnes Obligatoires Manquantes

## Problème Identifié

L'erreur suivante se produisait lors de l'ajout de points de fidélité :

```
❌ Erreur dans la réponse: null value in column "source_type" of relation "loyalty_points_history" violates not-null constraint
```

## Cause du Problème

La table `loyalty_points_history` contient plusieurs colonnes avec des contraintes `NOT NULL` qui n'étaient pas incluses dans les requêtes `INSERT` des fonctions :

- `points_type` : Type de points (manual, usage, etc.)
- `source_type` : Source des points (manual, purchase, etc.)

## Solution Appliquée

### 1. Script de Correction Principal

Le fichier `tables/correction_rapide_points_type.sql` a été créé pour :

- **Ajouter** les colonnes manquantes si elles n'existent pas
- **Mettre à jour** les enregistrements existants avec des valeurs par défaut
- **Recréer** les fonctions avec les bonnes requêtes INSERT
- **Inclure** toutes les colonnes obligatoires

### 2. Colonnes Ajoutées

```sql
-- Ajouter points_type si elle n'existe pas
ALTER TABLE loyalty_points_history ADD COLUMN points_type TEXT NOT NULL DEFAULT 'manual';

-- Ajouter source_type si elle n'existe pas
ALTER TABLE loyalty_points_history ADD COLUMN source_type TEXT NOT NULL DEFAULT 'manual';
```

### 3. Requêtes INSERT Corrigées

#### Pour add_loyalty_points :
```sql
INSERT INTO loyalty_points_history (
    client_id,
    points_change,
    points_before,
    points_after,
    description,
    points_type,
    source_type,
    created_at
) VALUES (
    p_client_id,
    p_points,
    v_current_points,
    v_new_points,
    p_description,
    'manual',
    'manual',
    NOW()
);
```

#### Pour use_loyalty_points :
```sql
INSERT INTO loyalty_points_history (
    client_id,
    points_change,
    points_before,
    points_after,
    description,
    points_type,
    source_type,
    created_at
) VALUES (
    p_client_id,
    -p_points,
    v_current_points,
    v_new_points,
    p_description,
    'usage',
    'manual',
    NOW()
);
```

### 4. Script de Diagnostic

Le fichier `tables/diagnostic_colonnes_obligatoires_loyalty.sql` permet de :

- **Identifier** toutes les colonnes obligatoires
- **Vérifier** les contraintes de la table
- **Générer** automatiquement les requêtes INSERT correctes
- **Fournir** des recommandations

## Instructions d'Application

### Étape 1 : Exécuter le Script de Correction

```sql
-- Exécuter dans Supabase SQL Editor
\i tables/correction_rapide_points_type.sql
```

### Étape 2 : Diagnostic (Optionnel)

```sql
-- Pour vérifier la structure
\i tables/diagnostic_colonnes_obligatoires_loyalty.sql
```

### Étape 3 : Test de Fonctionnement

```sql
-- Test d'ajout de points (remplacer client_id_ici par un vrai ID)
SELECT add_loyalty_points('client_id_ici', 10, 'Test de correction');

-- Test d'utilisation de points
SELECT use_loyalty_points('client_id_ici', 5, 'Test d''utilisation');
```

## Valeurs des Colonnes

### points_type
- `'manual'` : Points ajoutés manuellement
- `'usage'` : Points utilisés
- `'purchase'` : Points gagnés par achat
- `'referral'` : Points gagnés par parrainage

### source_type
- `'manual'` : Ajout manuel par l'administrateur
- `'system'` : Ajout automatique par le système
- `'purchase'` : Gagnés lors d'un achat
- `'referral'` : Gagnés par parrainage

## Résultat Attendu

Après application de la correction :

- ✅ **Plus d'erreur de contrainte NOT NULL**
- ✅ **Toutes les colonnes obligatoires incluses**
- ✅ **Fonctions add_loyalty_points et use_loyalty_points fonctionnelles**
- ✅ **Historisation complète des changements de points**
- ✅ **Valeurs appropriées pour chaque type d'opération**

## Prévention Future

Pour éviter ce problème à l'avenir :

1. **Vérifier** toutes les colonnes NOT NULL avant d'écrire des requêtes INSERT
2. **Utiliser** le script de diagnostic pour identifier les colonnes manquantes
3. **Tester** les fonctions avec des données réelles
4. **Documenter** les nouvelles colonnes ajoutées aux tables

## Fichiers de Correction

- `tables/correction_rapide_points_type.sql`
- `tables/diagnostic_colonnes_obligatoires_loyalty.sql`
- `md/GUIDE_CORRECTION_COLONNES_OBLIGATOIRES_LOYALTY.md` (ce fichier)

## Ordre d'Exécution des Scripts

Pour une correction complète, exécuter les scripts dans cet ordre :

1. **Ajout des colonnes** : `ajout_colonnes_loyalty_points_clients.sql`
2. **Correction des colonnes obligatoires** : `correction_rapide_points_type.sql`
3. **Diagnostic** : `diagnostic_colonnes_obligatoires_loyalty.sql` (optionnel)

## Statut

- ✅ **Problème identifié**
- ✅ **Solution développée**
- ✅ **Scripts de correction créés**
- ✅ **Documentation complète**
- 🔄 **En attente d'application en production**
