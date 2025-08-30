# 🏆 Guide du Système de Fidélité Automatique

## 🎯 Vue d'ensemble

Ce système de fidélité automatique attribue des points de fidélité à vos clients en fonction de leurs dépenses, avec des bonus progressifs et une gestion automatique des niveaux de fidélité.

## ✨ Fonctionnalités Principales

### 🎁 Attribution Automatique des Points
- **1€ dépensé = 1 point de base**
- **Bonus progressifs** selon le montant d'achat
- **Seuil minimum** de 5€ pour commencer à gagner des points
- **Calcul automatique** lors des ventes et réparations

### 🏅 Niveaux de Fidélité Automatiques
- **Bronze** (0-99 points) : Niveau de base
- **Argent** (100-499 points) : 5% de réduction
- **Or** (500-999 points) : 10% de réduction + service prioritaire
- **Platine** (1000-1999 points) : 15% de réduction + service VIP
- **Diamant** (2000+ points) : 20% de réduction + service Premium

### 💰 Système de Bonus
- **Achats ≥ 50€** : +10% de points bonus
- **Achats ≥ 100€** : +20% de points bonus  
- **Achats ≥ 200€** : +30% de points bonus

### ⚙️ **Paramétrage Complet**
- **Configuration en temps réel** de tous les paramètres
- **Personnalisation des niveaux** de fidélité
- **Aperçu en direct** des modifications
- **Sauvegarde automatique** des préférences

## 🚀 Installation

### Étape 1 : Exécuter le Script SQL
1. Ouvrez votre dashboard Supabase
2. Allez dans l'éditeur SQL
3. **EXÉCUTEZ** le script `tables/systeme_fidelite_automatique.sql`

### Étape 2 : Vérifier l'Installation
```sql
-- Vérifier que les tables sont créées
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_dashboard');

-- Vérifier la configuration par défaut
SELECT * FROM loyalty_config;

-- Vérifier les niveaux de fidélité
SELECT * FROM loyalty_tiers_advanced;
```

## ⚙️ Configuration

### 🎛️ **Onglet Paramètres - Personnalisation Complète**

Le nouvel onglet **"Paramètres"** permet au réparateur de personnaliser entièrement le système selon ses préférences :

#### **1. Configuration Générale**
- **Points par euro** : Modifiez le taux de conversion (défaut: 1 point/€)
- **Seuil minimum** : Définissez le montant minimum pour gagner des points (défaut: 5€)
- **Seuils de bonus** : Personnalisez les montants déclencheurs des bonus
- **Expiration des points** : Définissez la durée de validité des points

#### **2. Niveaux de Fidélité Personnalisables**
- **Points requis** : Ajustez les seuils de chaque niveau
- **Pourcentages de réduction** : Modifiez les avantages de chaque niveau
- **Descriptions** : Personnalisez les descriptions des niveaux
- **Activation/Désactivation** : Activez ou désactivez des niveaux

#### **3. Aperçu en Temps Réel**
- **Prévisualisation** : Voir l'impact des modifications avant sauvegarde
- **Exemples de calcul** : Testez avec différents montants d'achat
- **Validation** : Vérifiez la cohérence des paramètres

### Paramètres Configurables
Le système est entièrement configurable via la table `loyalty_config` :

| Paramètre | Valeur par défaut | Description | Personnalisable |
|-----------|-------------------|-------------|-----------------|
| `points_per_euro` | 1 | Points attribués par euro dépensé | ✅ Oui |
| `minimum_purchase_for_points` | 5 | Montant minimum en euros pour obtenir des points | ✅ Oui |
| `bonus_threshold_50` | 50 | Seuil en euros pour bonus de 10% de points | ✅ Oui |
| `bonus_threshold_100` | 100 | Seuil en euros pour bonus de 20% de points | ✅ Oui |
| `bonus_threshold_200` | 200 | Seuil en euros pour bonus de 30% de points | ✅ Oui |
| `points_expiry_months` | 24 | Durée de validité des points en mois | ✅ Oui |
| `auto_tier_upgrade` | true | Mise à jour automatique des niveaux de fidélité | ✅ Oui |

### Modifier la Configuration via l'Interface
```typescript
// Plus besoin de SQL ! Utilisez l'interface graphique :
1. Allez dans l'onglet "Paramètres"
2. Modifiez les valeurs dans les champs
3. Cliquez sur "Sauvegarder Configuration"
4. Les changements sont appliqués immédiatement
```

### Modifier la Configuration via SQL (Optionnel)
```sql
-- Exemple : Changer le taux de points à 2 points par euro
UPDATE loyalty_config 
SET value = '2' 
WHERE key = 'points_per_euro';

-- Exemple : Changer le seuil minimum à 10€
UPDATE loyalty_config 
SET value = '10' 
WHERE key = 'minimum_purchase_for_points';
```

## 🔄 Fonctionnement Automatique

### Attribution lors des Ventes
1. **Vente créée** → Statut "pending"
2. **Vente complétée** → Statut "completed"
3. **Trigger automatique** → Points calculés et attribués
4. **Niveau mis à jour** si nécessaire

### Attribution lors des Réparations
1. **Réparation créée** → `is_paid = false`
2. **Réparation payée** → `is_paid = true`
3. **Trigger automatique** → Points calculés et attribués
4. **Niveau mis à jour** si nécessaire

## 🧪 Test du Système

### Test Manuel
```sql
-- Tester l'attribution de points pour un achat de 75€
SELECT auto_add_loyalty_points_from_purchase(
  'client_id_ici', 
  75.00, 
  'test', 
  'Test manuel - Achat 75€'
);
```

### Test Automatique
1. **Créer une vente** avec un client existant
2. **Changer le statut** de "pending" à "completed"
3. **Vérifier** que les points sont attribués automatiquement

### Test via l'Interface
1. **Allez dans l'onglet "Paramètres"**
2. **Cliquez sur "Prévisualiser le Système"**
3. **Vérifiez** les exemples de calcul avec vos paramètres actuels

## 📊 Monitoring et Statistiques

### Tableau de Bord
```sql
-- Voir tous les clients avec leurs points
SELECT * FROM loyalty_dashboard;

-- Voir les statistiques générales
SELECT get_loyalty_statistics();
```

### Historique des Points
```sql
-- Voir l'historique d'un client spécifique
SELECT * FROM loyalty_points_history 
WHERE client_id = 'client_id_ici' 
ORDER BY created_at DESC;
```

## 🎨 Interface Utilisateur

### Composants Disponibles
- **`LoyaltyManagement`** : Gestion complète du système
- **`LoyaltyPage`** : Page principale avec onglets
- **`LoyaltySettings`** : **NOUVEAU** - Paramétrage complet du système
- **`LoyaltyHistory`** : Historique des points d'un client

### Structure des Onglets
1. **Gestion** : Tableau de bord et gestion des clients
2. **Tableau de Bord** : Vue d'ensemble des statistiques
3. **Paramètres** : **NOUVEAU** - Configuration complète du système
4. **Historique Client** : Détail des points par client
5. **Niveaux & Avantages** : Information sur les niveaux de fidélité

### Intégration dans l'Application
```tsx
// Ajouter la route dans votre routeur
import LoyaltyPage from './pages/Loyalty/LoyaltyPage';

// Ajouter dans la navigation
{
  path: '/loyalty',
  element: <LoyaltyPage />
}
```

## 🔧 Fonctions Disponibles

### Fonctions Principales
- `calculate_loyalty_points(amount, client_id)` : Calcule les points pour un montant
- `auto_add_loyalty_points_from_purchase(client_id, amount, source_type, description, reference_id)` : Attribue des points manuellement
- `auto_add_loyalty_points_from_sale(sale_id)` : Attribue des points depuis une vente
- `auto_add_loyalty_points_from_repair(repair_id)` : Attribue des points depuis une réparation
- `get_loyalty_statistics()` : Obtient les statistiques générales

### Triggers Automatiques
- `auto_loyalty_points_sale_trigger` : Déclenché lors de la mise à jour d'une vente
- `auto_loyalty_points_repair_trigger` : Déclenché lors de la mise à jour d'une réparation

## 📈 Exemples d'Utilisation

### Exemple 1 : Achat de 120€
- **Points de base** : 120 points (120€ × 1 point/€)
- **Bonus** : 24 points (120 × 20% car ≥ 100€)
- **Total** : 144 points
- **Niveau** : Argent (144 points ≥ 100 requis)

### Exemple 2 : Réparation de 250€
- **Points de base** : 250 points (250€ × 1 point/€)
- **Bonus** : 75 points (250 × 30% car ≥ 200€)
- **Total** : 325 points
- **Niveau** : Argent (325 points ≥ 100 requis)

### Exemple 3 : Achat de 30€
- **Points de base** : 30 points (30€ × 1 point/€)
- **Bonus** : 0 points (30€ < 50€)
- **Total** : 30 points
- **Niveau** : Bronze (30 points < 100 requis)

## 🎛️ **Personnalisation Avancée**

### **Scénarios de Personnalisation**

#### **1. Atelier Premium (Taux élevé)**
- **Points par euro** : 2 ou 3
- **Seuils de bonus** : Plus bas (25€, 50€, 100€)
- **Niveaux** : Plus de niveaux avec avantages progressifs

#### **2. Atelier Économique (Taux modéré)**
- **Points par euro** : 0.5 ou 0.75
- **Seuils de bonus** : Plus hauts (75€, 150€, 300€)
- **Niveaux** : Moins de niveaux, focus sur la fidélité

#### **3. Atelier Spécialisé (Bonus sur services)**
- **Points par euro** : 1 (standard)
- **Seuils de bonus** : Adaptés aux services (100€, 200€, 500€)
- **Niveaux** : Avantages techniques et garanties étendues

### **Modification des Niveaux**
```typescript
// Via l'interface Paramètres :
1. Dépliez le niveau à modifier
2. Changez les points requis
3. Ajustez le pourcentage de réduction
4. Modifiez la description
5. Activez/désactivez le niveau
6. Sauvegardez les modifications
```

## 🚨 Dépannage

### Problèmes Courants

#### 1. Points non attribués
**Vérifier :**
- Le montant est-il ≥ au seuil minimum ?
- La vente/réparation est-elle bien complétée/payée ?
- Les triggers sont-ils actifs ?

#### 2. Erreur de fonction
**Vérifier :**
- Toutes les tables sont-elles créées ?
- Les permissions sont-elles accordées ?
- La syntaxe SQL est-elle correcte ?

#### 3. Niveaux non mis à jour
**Vérifier :**
- La table `loyalty_tiers_advanced` contient-elle les niveaux ?
- Les `points_required` sont-ils corrects ?
- La fonction `auto_tier_upgrade` est-elle activée ?

#### 4. **Paramètres non sauvegardés**
**Vérifier :**
- Avez-vous cliqué sur "Sauvegarder Configuration" ?
- Les modifications sont-elles dans les champs d'édition ?
- Y a-t-il des erreurs dans la console ?

### Logs et Debug
```sql
-- Vérifier les triggers
SELECT * FROM information_schema.triggers 
WHERE trigger_name LIKE '%loyalty%';

-- Vérifier les fonctions
SELECT * FROM information_schema.routines 
WHERE routine_name LIKE '%loyalty%';

-- Vérifier les permissions
SELECT * FROM information_schema.role_routine_grants 
WHERE routine_name LIKE '%loyalty%';

-- Vérifier la configuration actuelle
SELECT * FROM loyalty_config ORDER BY key;
```

## 🔮 Améliorations Futures

### Fonctionnalités Suggérées
- **Expiration des points** automatique
- **Campagnes de bonus** temporaires
- **Notifications** lors des changements de niveau
- **Rapports avancés** et analytics
- **Intégration email** pour les notifications
- **API REST** pour les applications tierces

### Personnalisations Possibles
- **Taux de points** différents par catégorie de produit
- **Bonus saisonniers** ou événementiels
- **Parrainage** et points de recommandation
- **Échange de points** contre des avantages
- **Gamification** avec badges et achievements

## 📞 Support

### En Cas de Problème
1. **Vérifiez** que tous les scripts SQL ont été exécutés
2. **Consultez** les logs d'erreur dans Supabase
3. **Testez** avec des données simples d'abord
4. **Vérifiez** que les permissions sont correctes
5. **Utilisez l'onglet Paramètres** pour tester la configuration

### Ressources Utiles
- **Documentation Supabase** : https://supabase.com/docs
- **Guide des politiques RLS** : https://supabase.com/docs/guides/auth/row-level-security
- **Documentation PostgreSQL** : https://www.postgresql.org/docs/

---

## 🎉 Félicitations !

Votre système de fidélité automatique est maintenant opérationnel avec un **paramétrage complet** ! Vos clients gagneront automatiquement des points à chaque achat, et vous pourrez personnaliser entièrement le système selon vos préférences commerciales.

**Prochaine étape :** 
1. **Testez le système** avec quelques clients
2. **Personnalisez la configuration** via l'onglet Paramètres
3. **Adaptez les niveaux** selon votre stratégie commerciale
4. **Formez votre équipe** à l'utilisation du système

**💡 Conseil :** Commencez par tester avec les paramètres par défaut, puis ajustez progressivement selon les retours de vos clients et vos objectifs commerciaux !
