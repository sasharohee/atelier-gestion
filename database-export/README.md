# Export Complet - Toutes les Tables

## Fichiers

- `complete-export.sql`: Script complet d'export avec toutes les tables et données de test
- `verification-complete.sql`: Script de vérification après import
- `README.md`: Ce fichier d'explication

## Utilisation

### 1. Import vers l'environnement de développement

1. Connectez-vous à votre instance Supabase de développement
2. Allez dans SQL Editor
3. Copiez le contenu de `complete-export.sql`
4. Exécutez le script

### 2. Vérification

Après l'import, exécutez `verification-complete.sql` pour vérifier que tout a été importé.

## Contenu de l'export

### Tables créées
- **clients**: Informations des clients (5 clients de test)
- **produits**: Catalogue des produits (6 produits de test)
- **reparations**: Réparations effectuées (2 réparations de test)
- **interventions**: Détail des interventions (2 interventions de test)
- **factures**: Facturation (1 facture de test)
- **utilisateurs**: Gestion des utilisateurs (4 utilisateurs de test)

### Fonctionnalités incluses
- ✅ Toutes les tables avec leurs relations
- ✅ Index pour optimiser les performances
- ✅ Triggers pour les timestamps automatiques
- ✅ Fonctions utilitaires
- ✅ Données de test complètes
- ✅ Politiques RLS (Row Level Security)
- ✅ Vérification automatique

## Données de test incluses

- **5 clients** avec informations complètes
- **6 produits** (smartphones, ordinateurs, tablettes)
- **4 utilisateurs** avec différents rôles
- **2 réparations** avec statuts différents
- **2 interventions** détaillées
- **1 facture** payée

## Sécurité

- RLS activé sur toutes les tables
- Politiques pour utilisateurs authentifiés
- Données de test séparées de la production

Généré le: 2025-09-06T16:40:15.283Z
