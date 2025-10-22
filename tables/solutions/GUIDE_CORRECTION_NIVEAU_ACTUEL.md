# Guide de Correction : Affichage du Niveau Actuel

## 🚨 Problème Identifié

**Symptôme :** La colonne "Niveau Actuel" dans la table des points de fidélité est vide, même si la progression montre "20% vers Argent".

**Cause :** Le champ `current_tier_id` dans la table `client_loyalty_points` n'est pas correctement mis à jour ou est manquant.

## 🔍 Diagnostic

### 1. Vérification de la Structure
```sql
-- Vérifier la structure de la table client_loyalty_points
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'client_loyalty_points';
```

### 2. Vérification des Données
```sql
-- Vérifier les clients avec points et leurs niveaux
SELECT 
    c.first_name,
    c.last_name,
    clp.total_points,
    clp.used_points,
    (clp.total_points - clp.used_points) as points_disponibles,
    clp.current_tier_id,
    lt.name as niveau_actuel
FROM client_loyalty_points clp
LEFT JOIN clients c ON clp.client_id = c.id
LEFT JOIN loyalty_tiers lt ON clp.current_tier_id = lt.id;
```

## ✅ Solution

### Option 1 : Correction Rapide
Exécuter le script `tables/correction_rapide_niveau_actuel.sql` :

```sql
-- Mettre à jour tous les niveaux actuels manquants
UPDATE client_loyalty_points 
SET current_tier_id = (
    SELECT id 
    FROM loyalty_tiers 
    WHERE min_points <= (client_loyalty_points.total_points - client_loyalty_points.used_points)
    ORDER BY min_points DESC 
    LIMIT 1
)
WHERE current_tier_id IS NULL;
```

### Option 2 : Correction Complète
Exécuter le script `tables/correction_niveau_actuel.sql` qui inclut :
- Diagnostic complet
- Correction des niveaux
- Amélioration de la fonction `add_loyalty_points`
- Vérifications

## 🔧 Amélioration de la Fonction

La fonction `add_loyalty_points` a été améliorée pour s'assurer que le `current_tier_id` est toujours mis à jour :

```sql
CREATE OR REPLACE FUNCTION add_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_description TEXT DEFAULT ''
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_points INTEGER;
    v_new_tier_id UUID;
    v_result JSON;
BEGIN
    -- Insérer ou mettre à jour les points
    INSERT INTO client_loyalty_points (client_id, total_points, used_points)
    VALUES (p_client_id, p_points, 0)
    ON CONFLICT (client_id) 
    DO UPDATE SET 
        total_points = client_loyalty_points.total_points + p_points,
        updated_at = NOW();
    
    -- Calculer les points disponibles
    SELECT total_points - used_points INTO v_current_points
    FROM client_loyalty_points
    WHERE client_id = p_client_id;
    
    -- Calculer le nouveau niveau
    v_new_tier_id := calculate_correct_tier(v_current_points);
    
    -- Mettre à jour le niveau actuel
    UPDATE client_loyalty_points
    SET current_tier_id = v_new_tier_id
    WHERE client_id = p_client_id;
    
    -- Retourner le résultat
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'client_id', p_client_id,
            'points_added', p_points,
            'total_points', v_current_points,
            'new_tier_id', v_new_tier_id
        ),
        'message', 'Points ajoutés avec succès'
    );
END;
$$;
```

## 📊 Vérification

Après la correction, vérifiez que :

1. **Tous les clients ont un niveau actuel :**
```sql
SELECT COUNT(*) as total_clients,
       COUNT(current_tier_id) as clients_avec_niveau
FROM client_loyalty_points;
```

2. **Les niveaux correspondent aux points :**
```sql
SELECT 
    c.first_name,
    c.last_name,
    (clp.total_points - clp.used_points) as points_disponibles,
    lt.name as niveau_actuel,
    lt.min_points as points_requis
FROM client_loyalty_points clp
LEFT JOIN clients c ON clp.client_id = c.id
LEFT JOIN loyalty_tiers lt ON clp.current_tier_id = lt.id;
```

## 🎯 Résultat Attendu

Après la correction :
- ✅ La colonne "Niveau Actuel" affiche le bon niveau (Bronze, Argent, Or, etc.)
- ✅ Le niveau correspond aux points disponibles du client
- ✅ Les nouveaux points ajoutés mettent automatiquement à jour le niveau
- ✅ L'interface affiche correctement les informations de fidélité

## 🚀 Instructions d'Exécution

1. **Ouvrir l'interface SQL de Supabase**
2. **Exécuter le script de correction :**
   - Pour une correction rapide : `tables/correction_rapide_niveau_actuel.sql`
   - Pour une correction complète : `tables/correction_niveau_actuel.sql`
3. **Vérifier les résultats dans l'interface**
4. **Actualiser la page des points de fidélité**

## 📝 Notes Techniques

- **Niveaux de fidélité :** Bronze (0), Argent (500), Or (1000), Platine (2500), Diamant (5000)
- **Calcul automatique :** Le niveau est calculé en fonction des points disponibles (total - utilisés)
- **Mise à jour en temps réel :** Chaque ajout de points met à jour automatiquement le niveau
- **Cohérence des données :** Le script vérifie et corrige les incohérences existantes
