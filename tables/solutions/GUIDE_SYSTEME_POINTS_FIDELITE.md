# GUIDE SYSTÈME DE POINTS DE FIDÉLITÉ POUR PARRAINAGES

## 📋 Vue d'ensemble

Ce système permet de gérer les points de fidélité basés sur les parrainages de clients. Les clients qui parrainent d'autres clients reçoivent des points de fidélité qui leur donnent droit à des réductions sur leurs réparations.

## 🏗️ Structure du système

### Tables créées

1. **`loyalty_tiers`** - Niveaux de fidélité (Bronze, Argent, Or, etc.)
2. **`referrals`** - Parrainages entre clients
3. **`client_loyalty_points`** - Points de fidélité des clients
4. **`loyalty_points_history`** - Historique des points
5. **`loyalty_rules`** - Règles de points configurables

### Colonnes ajoutées à la table `repairs`

- `loyalty_discount_percentage` - Pourcentage de réduction appliqué
- `loyalty_points_used` - Points utilisés pour cette réparation
- `final_price` - Prix final après réduction

## 🎯 Fonctionnalités principales

### 1. Gestion des parrainages

#### Créer un parrainage
```sql
SELECT create_referral(
    'client_parrain_id'::UUID,
    'client_parrainé_id'::UUID,
    'Notes optionnelles'
);
```

#### Confirmer un parrainage
```sql
SELECT confirm_referral(
    'referral_id'::UUID,
    100, -- Points à attribuer (optionnel, utilise les règles par défaut)
    'Notes de confirmation'
);
```

#### Rejeter un parrainage
```sql
SELECT reject_referral(
    'referral_id'::UUID,
    'Raison du rejet'
);
```

#### Voir les parrainages en attente
```sql
SELECT get_pending_referrals();
```

### 2. Gestion des points de fidélité

#### Ajouter des points manuellement
```sql
SELECT add_loyalty_points(
    'client_id'::UUID,
    100, -- Points à ajouter
    'earned', -- Type: earned, used, expired, bonus
    'manual', -- Source: referral, purchase, manual, bonus
    NULL, -- Source ID (optionnel)
    'Points bonus pour fidélité', -- Description
    auth.uid() -- Créé par
);
```

#### Voir les informations de fidélité d'un client
```sql
SELECT get_client_loyalty_info('client_id'::UUID);
```

#### Voir l'historique des points d'un client
```sql
SELECT get_client_loyalty_history(
    'client_id'::UUID,
    50, -- Limite
    0   -- Offset
);
```

### 3. Gestion des réductions sur réparations

#### Calculer automatiquement la réduction
```sql
SELECT calculate_loyalty_discount('repair_id'::UUID);
```

#### Appliquer une réduction manuelle avec points
```sql
SELECT apply_manual_loyalty_discount(
    'repair_id'::UUID,
    50, -- Points à utiliser
    10.0 -- Pourcentage de réduction (optionnel)
);
```

### 4. Statistiques et rapports

#### Statistiques générales
```sql
SELECT get_loyalty_statistics();
```

## 📊 Niveaux de fidélité par défaut

| Niveau | Points requis | Réduction | Couleur |
|--------|---------------|-----------|---------|
| Bronze | 0 | 0% | #CD7F32 |
| Argent | 500 | 5% | #C0C0C0 |
| Or | 1000 | 10% | #FFD700 |
| Platine | 2500 | 15% | #E5E4E2 |
| Diamant | 5000 | 20% | #B9F2FF |

## ⚙️ Configuration des règles

### Règles par défaut
- **Points par parrainage** : 100 points
- **Points par euro dépensé** : 1 point
- **Expiration des points** : 12 mois
- **Achat minimum pour points** : 0€

### Modifier les règles
```sql
UPDATE loyalty_rules 
SET 
    points_per_referral = 150,
    points_per_euro_spent = 1.5,
    points_expiry_months = 18
WHERE rule_name = 'Règles par défaut';
```

## 🔄 Workflow typique

### 1. Création d'un parrainage
1. Un client parraine un autre client
2. Le parrainage est créé avec le statut "pending"
3. L'entreprise vérifie la validité du parrainage

### 2. Confirmation du parrainage
1. L'entreprise confirme le parrainage
2. Les points sont automatiquement attribués au parrain
3. Le niveau de fidélité est recalculé

### 3. Utilisation des points
1. Le client fait une réparation
2. La réduction est automatiquement calculée selon son niveau
3. Ou une réduction manuelle est appliquée avec des points spécifiques

## 🎨 Interface utilisateur recommandée

### Page de gestion des parrainages
- Liste des parrainages en attente
- Boutons pour confirmer/rejeter
- Formulaire pour créer de nouveaux parrainages

### Page de fidélité client
- Affichage du niveau actuel
- Points disponibles
- Historique des points
- Progression vers le niveau suivant

### Page de réparations
- Affichage de la réduction automatique
- Option pour appliquer une réduction manuelle
- Calcul en temps réel du prix final

## 🔧 Maintenance

### Nettoyage des points expirés
```sql
-- Supprimer les points expirés (à exécuter périodiquement)
DELETE FROM loyalty_points_history 
WHERE created_at < NOW() - INTERVAL '12 months'
AND points_type = 'earned';
```

### Mise à jour des niveaux
```sql
-- Recalculer tous les niveaux de fidélité
UPDATE client_loyalty_points 
SET current_tier_id = calculate_client_tier(client_id);
```

## 🚨 Sécurité

- Toutes les fonctions vérifient les permissions utilisateur
- Les politiques RLS protègent les données
- Les transactions garantissent la cohérence des données

## 📈 Avantages du système

1. **Fidélisation** : Encourage les clients à revenir
2. **Parrainage** : Augmente la clientèle par recommandation
3. **Flexibilité** : Règles configurables selon les besoins
4. **Transparence** : Historique complet des points
5. **Automatisation** : Calculs automatiques des réductions

## 🎯 Exemples d'utilisation

### Exemple 1 : Parrainage simple
```sql
-- Client A parraine Client B
SELECT create_referral('client_a_id', 'client_b_id', 'Recommandation');

-- Confirmer le parrainage
SELECT confirm_referral('referral_id');

-- Client A reçoit 100 points et passe au niveau Argent
```

### Exemple 2 : Réduction automatique
```sql
-- Créer une réparation pour un client avec points
INSERT INTO repairs (client_id, total_price) VALUES ('client_id', 200.00);

-- La réduction est automatiquement calculée selon le niveau
-- Si le client est niveau Or (10%), le prix final sera 180.00€
```

### Exemple 3 : Réduction manuelle
```sql
-- Appliquer une réduction de 50 points sur une réparation
SELECT apply_manual_loyalty_discount('repair_id', 50);
```

## 📞 Support

Pour toute question ou problème avec le système de points de fidélité, consultez les logs de la base de données ou contactez l'équipe technique.
