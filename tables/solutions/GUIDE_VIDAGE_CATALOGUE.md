# 🧹 GUIDE DE VIDAGE ET RÉINITIALISATION DU CATALOGUE

## 🎯 OBJECTIF
Vider complètement le catalogue de toutes ses données pour faire des tests propres et repartir sur une base vierge.

## 📋 ÉTAPES À SUIVRE

### 1. VIDAGE COMPLET DU CATALOGUE

**Fichier à utiliser :** `vider_catalogue_complet.sql`

**Actions du script :**
- ✅ Compte les données existantes avant suppression
- ✅ Supprime toutes les données des tables du catalogue
- ✅ Vérifie que les tables sont bien vides
- ✅ Teste que l'insertion fonctionne toujours
- ✅ Conserve la structure et les politiques RLS

**Exécution :**
```sql
-- Dans l'interface SQL de Supabase
-- Copier et exécuter le contenu de vider_catalogue_complet.sql
```

### 2. AJOUT DE DONNÉES DE TEST (OPTIONNEL)

**Fichier à utiliser :** `donnees_test_catalogue.sql`

**Actions du script :**
- ✅ Ajoute 8 appareils variés (smartphones, tablettes, ordinateurs, consoles, caméras)
- ✅ Ajoute 8 services de réparation différents
- ✅ Ajoute 8 pièces détachées avec stock
- ✅ Ajoute 8 produits d'accessoires
- ✅ Ajoute 8 clients fictifs
- ✅ Vérifie l'isolation des données

**Exécution :**
```sql
-- Dans l'interface SQL de Supabase
-- Copier et exécuter le contenu de donnees_test_catalogue.sql
```

## 🔄 ORDRE D'EXÉCUTION RECOMMANDÉ

### Option 1 : Catalogue complètement vide
1. Exécuter `vider_catalogue_complet.sql`
2. Le catalogue est maintenant vide et prêt pour vos propres données

### Option 2 : Catalogue avec données de test
1. Exécuter `vider_catalogue_complet.sql`
2. Exécuter `donnees_test_catalogue.sql`
3. Le catalogue contient maintenant des données de test variées

## 🎯 DONNÉES DE TEST INCLUSES

### 📱 Appareils (8 enregistrements)
- iPhone 14 Pro, Galaxy S23 Ultra, iPad Air
- Dell XPS 13, HP Pavilion
- PlayStation 5, Xbox Series X
- Canon EOS R6

### 🔧 Services (8 enregistrements)
- Remplacement écran, batterie, diagnostic
- Nettoyage, installation logiciel
- Récupération données, mise à jour système
- Optimisation performance

### 🔩 Pièces détachées (8 enregistrements)
- Écrans, batteries, claviers
- Disques durs, RAM, chargeurs
- Câbles avec gestion de stock

### 🛍️ Produits (8 enregistrements)
- Coques, films de protection
- Chargeurs sans fil, câbles
- Souris, claviers, webcams
- Disques externes

### 👥 Clients (8 enregistrements)
- Clients fictifs avec coordonnées complètes
- Répartis dans différentes villes françaises

## ✅ VÉRIFICATIONS POST-EXÉCUTION

Après avoir exécuté les scripts, vérifiez que :

1. **Tables vides** (si vous n'avez exécuté que le vidage)
2. **Données de test présentes** (si vous avez ajouté les données de test)
3. **Isolation fonctionnelle** - Chaque utilisateur ne voit que ses données
4. **Politiques RLS actives** - 4 politiques par table
5. **Structure intacte** - Toutes les colonnes sont présentes

## 🚨 POINTS D'ATTENTION

### ⚠️ Données supprimées définitivement
- Le vidage supprime **TOUTES** les données du catalogue
- Cette action est **irréversible**
- Assurez-vous de sauvegarder si nécessaire

### 🔒 Isolation maintenue
- Les politiques RLS restent actives
- L'isolation par utilisateur est préservée
- Chaque utilisateur ne verra que ses propres données

### 🧪 Tests d'insertion
- Le script teste automatiquement l'insertion
- Si les tests échouent, vérifiez les permissions
- Assurez-vous d'être connecté en tant qu'utilisateur

## 🔧 DÉPANNAGE

### Erreur de permission
Si vous obtenez une erreur de permission :
- Vérifiez que vous êtes connecté
- Assurez-vous d'avoir les droits sur les tables
- Contactez l'administrateur si nécessaire

### Données non supprimées
Si certaines données persistent :
- Vérifiez les contraintes de clés étrangères
- Exécutez le script de correction d'isolation si nécessaire
- Vérifiez les politiques RLS

### Problèmes d'insertion
Si l'insertion de données de test échoue :
- Vérifiez que l'utilisateur est connecté
- Vérifiez les contraintes NOT NULL
- Vérifiez les politiques RLS

## 📊 RÉSULTATS ATTENDUS

### Après vidage seul :
- Toutes les tables du catalogue sont vides
- Structure et politiques RLS préservées
- Prêt pour ajout de nouvelles données

### Après vidage + données de test :
- 40 enregistrements au total (8 par table)
- Données variées et réalistes
- Isolation parfaite par utilisateur
- Prêt pour tests complets

---

**💡 CONSEIL** : Exécutez d'abord le script de vidage seul pour vérifier qu'il fonctionne, puis ajoutez les données de test si nécessaire.
