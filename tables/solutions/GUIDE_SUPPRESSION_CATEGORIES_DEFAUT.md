# Guide de Suppression des Catégories par Défaut

## 🎯 Objectif

Ce guide vous explique comment supprimer les catégories d'appareils par défaut de votre application Atelier de Gestion :
- **Smartphones**
- **Tablettes**
- **Ordinateurs portables**
- **Ordinateurs fixes**

## 📋 Prérequis

- ✅ Application en cours d'exécution sur `localhost:3000`
- ✅ Connexion à votre base de données Supabase
- ✅ Droits d'administration sur la base de données

## 🚀 Méthodes de Suppression

### Méthode 1 : Script SQL Direct (Recommandée)

#### Étape 1 : Accéder à Supabase
1. Allez sur [supabase.com](https://supabase.com)
2. Connectez-vous à votre projet
3. Allez dans **SQL Editor**

#### Étape 2 : Exécuter le Script
1. Copiez le contenu du fichier `suppression_categories_defaut.sql`
2. Collez-le dans l'éditeur SQL de Supabase
3. Cliquez sur **Run** pour exécuter le script

#### Étape 3 : Vérification
Le script affichera :
- Les catégories actuelles
- Le processus de suppression
- Les catégories restantes
- Les statistiques finales

### Méthode 2 : Script JavaScript (Alternative)

#### Étape 1 : Configuration
1. Ouvrez le fichier `suppression_categories_defaut.js`
2. Remplacez les variables d'environnement :
   ```javascript
   const supabaseUrl = 'VOTRE_URL_SUPABASE';
   const supabaseKey = 'VOTRE_CLE_ANONYME';
   ```

#### Étape 2 : Exécution
1. Dans la console du navigateur (F12)
2. Copiez-collez le contenu du script
3. Appelez : `supprimerCategoriesDefaut()`

## 🔍 Vérification de la Suppression

### Dans l'Application
1. Rafraîchissez la page de gestion des appareils
2. Vérifiez que les 4 catégories par défaut ont disparu
3. La page devrait afficher "0 catégorie" ou être vide

### Dans la Base de Données
```sql
-- Vérifier que les catégories ont été supprimées
SELECT COUNT(*) FROM product_categories 
WHERE name IN ('Smartphones', 'Tablettes', 'Ordinateurs portables', 'Ordinateurs fixes');

-- Résultat attendu : 0
```

## ⚠️ Points d'Attention

### Dépendances
- Assurez-vous qu'aucun appareil n'utilise ces catégories
- Vérifiez qu'aucun service n'est lié à ces catégories
- Contrôlez qu'aucune pièce détachée n'en dépend

### Sauvegarde
- Faites une sauvegarde de votre base avant la suppression
- Exportez les données importantes si nécessaire

## 🆘 En Cas de Problème

### Erreur de Permissions
```sql
-- Vérifier les politiques RLS
SELECT * FROM pg_policies WHERE tablename = 'product_categories';
```

### Erreur de Contrainte
```sql
-- Vérifier les contraintes de clé étrangère
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'product_categories';
```

## 📊 Après la Suppression

### Créer de Nouvelles Catégories
Vous pouvez maintenant créer vos propres catégories personnalisées via l'interface de l'application.

### Vérifier l'Isolation
Assurez-vous que les nouvelles catégories respectent l'isolation par utilisateur (RLS).

## 🎉 Résultat Attendu

Après la suppression, votre application devrait :
- ✅ Ne plus afficher les 4 catégories par défaut
- ✅ Permettre la création de nouvelles catégories personnalisées
- ✅ Maintenir l'isolation des données entre utilisateurs
- ✅ Fonctionner normalement sans erreurs

## 📞 Support

Si vous rencontrez des difficultés :
1. Vérifiez les logs de la console
2. Contrôlez les erreurs dans Supabase
3. Consultez la documentation de votre projet

---

**Note** : Cette suppression est irréversible. Assurez-vous de bien comprendre les implications avant de procéder.

