# Guide de Correction - Erreur PGRST203 Points de Fidélité

## Problème Identifié

L'erreur suivante se produisait lors de l'ajout de points de fidélité :

```
❌ Erreur Supabase: 
{code: 'PGRST203', details: null, hint: 'Try renaming the parameters or the function itself… database so function overloading can be resolved', message: 'Could not choose the best candidate function betwe… text, p_source_id => uuid, p_created_by => uuid)'}
```

## Cause du Problème

Le problème était causé par un **conflit de surcharge de fonction** (function overloading) dans PostgreSQL. Plusieurs versions de la fonction `add_loyalty_points` existaient dans la base de données avec des signatures différentes :

- `add_loyalty_points(UUID, INTEGER, TEXT)`
- `add_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID, TEXT, UUID)`
- `add_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID, TEXT)`
- Et d'autres variations...

PostgreSQL ne pouvait pas déterminer quelle version de la fonction utiliser, d'où l'erreur PGRST203.

## Solution Appliquée

### 1. Script de Correction Principal

Le fichier `tables/correction_fonction_overloading_loyalty_points.sql` a été créé pour :

- **Identifier** toutes les versions existantes de la fonction
- **Supprimer** toutes les versions conflictuelles
- **Créer** une seule version unifiée avec la signature : `add_loyalty_points(UUID, INTEGER, TEXT)`

### 2. Fonction Unifiée

La nouvelle fonction `add_loyalty_points` :

```sql
CREATE OR REPLACE FUNCTION add_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_description TEXT DEFAULT 'Points ajoutés manuellement'
)
RETURNS JSON
```

**Fonctionnalités :**
- ✅ Vérification de l'existence du client
- ✅ Validation des points positifs
- ✅ Calcul automatique du nouveau niveau de fidélité
- ✅ Mise à jour des points et du niveau
- ✅ Historisation des changements
- ✅ Gestion d'erreurs complète

### 3. Correction Similaire pour use_loyalty_points

Le fichier `tables/correction_fonction_overloading_use_loyalty_points.sql` corrige également :

- **Suppression** de toutes les versions conflictuelles
- **Création** d'une version unifiée : `use_loyalty_points(UUID, INTEGER, TEXT)`

## Instructions d'Application

### Étape 1 : Exécuter le Script de Correction

```sql
-- Exécuter dans Supabase SQL Editor
\i tables/correction_fonction_overloading_loyalty_points.sql
\i tables/correction_fonction_overloading_use_loyalty_points.sql
```

### Étape 2 : Vérification

Après exécution, vérifier que :

1. **Une seule version** de chaque fonction existe
2. **Les permissions** sont correctement accordées
3. **Les tests** fonctionnent correctement

### Étape 3 : Test de Fonctionnement

```sql
-- Test d'ajout de points (remplacer client_id_ici par un vrai ID)
SELECT add_loyalty_points('client_id_ici', 10, 'Test de correction');

-- Test d'utilisation de points
SELECT use_loyalty_points('client_id_ici', 5, 'Test d''utilisation');
```

## Résultat Attendu

Après application de la correction :

- ✅ **Plus d'erreur PGRST203**
- ✅ **Ajout de points fonctionnel**
- ✅ **Utilisation de points fonctionnelle**
- ✅ **Mise à jour automatique des niveaux**
- ✅ **Historisation correcte**

## Prévention Future

Pour éviter ce problème à l'avenir :

1. **Toujours supprimer** les anciennes versions de fonctions avant d'en créer de nouvelles
2. **Utiliser des noms uniques** pour les fonctions avec des signatures différentes
3. **Documenter** les changements de signature de fonctions
4. **Tester** les fonctions après modification

## Fichiers de Correction

- `tables/correction_fonction_overloading_loyalty_points.sql`
- `tables/correction_fonction_overloading_use_loyalty_points.sql`
- `md/GUIDE_CORRECTION_ERREUR_409_LOYALTY_POINTS.md` (ce fichier)

## Statut

- ✅ **Problème identifié**
- ✅ **Solution développée**
- ✅ **Scripts de correction créés**
- ✅ **Documentation complète**
- 🔄 **En attente d'application en production**
