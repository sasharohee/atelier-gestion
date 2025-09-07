# Schéma de Base de Données - Atelier Gestion

## Fichiers

- `schema-export.sql`: Script complet d'export du schéma
- `README.md`: Ce fichier d'explication

## Utilisation

### 1. Import vers l'environnement de développement

1. Connectez-vous à votre instance Supabase de développement
2. Allez dans SQL Editor
3. Copiez le contenu de `schema-export.sql`
4. Exécutez le script

### 2. Vérification

Après l'import, vérifiez que toutes les tables ont été créées :

```sql
-- Lister toutes les tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### 3. Données de test

Le script inclut des données de test commentées. Pour les activer :

1. Décommentez la section "Données de test" dans le script
2. Ré-exécutez le script

## Structure des tables

- **clients**: Informations des clients
- **produits**: Catalogue des produits
- **reparations**: Réparations effectuées
- **interventions**: Détail des interventions
- **factures**: Facturation
- **utilisateurs**: Gestion des utilisateurs

## Sécurité

- RLS (Row Level Security) activé sur toutes les tables
- Politiques de base pour les utilisateurs authentifiés
- À adapter selon vos besoins spécifiques

## Maintenance

- Triggers automatiques pour les timestamps
- Fonctions utilitaires pour la génération de numéros
- Index pour optimiser les performances

Généré le: 2025-09-06T16:31:59.437Z
