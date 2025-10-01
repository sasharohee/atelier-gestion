# Guide de Correction - Noms dans subscription_status

## 🚨 Problème Identifié

Dans la table `subscription_status`, tous les utilisateurs ont :
- `first_name`: "Utilisateur" (au lieu du vrai prénom)
- `last_name`: "Test" ou "" (au lieu du vrai nom de famille)

**Cause :** La fonction `create_user_default_data_permissive` utilise des valeurs hardcodées au lieu de récupérer les vraies données utilisateur.

## ✅ Solution Appliquée

### 1. Nouvelle Fonction Corrigée
Création de `create_user_default_data_corrected()` qui :
- Récupère les vraies données depuis la table `users`
- Utilise les vrais prénom, nom et email
- Met à jour les données existantes

### 2. Modifications du Code
- **Fichier modifié :** `src/services/supabaseService.ts`
- **Changement :** Utilisation de `create_user_default_data_corrected` au lieu de `create_user_default_data_permissive`

## 🚀 Déploiement

### Option 1: Script Automatique
```bash
./deploy_correction_noms_subscription.sh
```

### Option 2: Manuel (Dashboard Supabase)
1. Allez dans votre dashboard Supabase
2. Ouvrez l'éditeur SQL
3. Copiez et exécutez le contenu de `correction_subscription_status_noms.sql`

## 🧪 Test de la Correction

### 1. Vérifier les Données Existantes
```sql
-- Vérifier que les données ont été corrigées
SELECT 
    ss.first_name,
    ss.last_name,
    ss.email,
    u.first_name as real_first_name,
    u.last_name as real_last_name,
    u.email as real_email
FROM subscription_status ss
JOIN users u ON ss.user_id = u.id
WHERE ss.first_name != u.first_name OR ss.last_name != u.last_name;
```

### 2. Tester un Nouveau Compte
1. Créez un nouveau compte via l'interface
2. Vérifiez dans `subscription_status` que les noms sont corrects
3. Les colonnes `first_name` et `last_name` doivent contenir les vrais noms

## 📋 Vérifications Post-Déploiement

### Dans Supabase Dashboard
1. **Table Editor > subscription_status**
   - Vérifiez que `first_name` contient les vrais prénoms
   - Vérifiez que `last_name` contient les vrais noms de famille
   - Plus de "Utilisateur" ou "Test" hardcodés

2. **Table Editor > users**
   - Vérifiez que les données utilisateur sont correctes
   - Les noms doivent correspondre à ceux saisis lors de l'inscription

### Dans l'Application
1. **Création de compte**
   - Saisissez un prénom et nom de famille
   - Vérifiez que l'inscription fonctionne
   - Les données doivent apparaître correctement

## 🔧 Fonctions Disponibles

### `create_user_default_data_corrected(user_id)`
- **Usage :** Création automatique des données par défaut
- **Paramètres :** `user_id` (UUID)
- **Retour :** JSON avec succès/erreur
- **Fonctionnalité :** Utilise les vraies données utilisateur

### `test_corrected_function()`
- **Usage :** Test de la fonction corrigée
- **Retour :** Tableau de résultats de test
- **Fonctionnalité :** Vérifie que tout fonctionne correctement

## 🚨 Points d'Attention

1. **Données Existantes :** Le script corrige automatiquement les données existantes
2. **Nouveaux Comptes :** Les futurs comptes auront automatiquement les bons noms
3. **Rollback :** Si problème, vous pouvez revenir à l'ancienne fonction

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs dans la console du navigateur
2. Vérifiez les logs Supabase
3. Exécutez `test_corrected_function()` pour diagnostiquer

## ✅ Résultat Attendu

Après la correction :
- ✅ Les noms dans `subscription_status` correspondent aux vrais noms
- ✅ Plus de valeurs "Utilisateur" ou "Test" hardcodées
- ✅ Les nouveaux comptes fonctionnent correctement
- ✅ Les données existantes sont corrigées

