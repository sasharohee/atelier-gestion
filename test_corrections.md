# Guide de test des corrections

## Test des produits

### 1. Test d'ajout de produit
1. Aller dans **Catalogue > Produits**
2. Cliquer sur **"Nouveau produit"**
3. Remplir le formulaire :
   - Nom : "Test Produit"
   - Description : "Produit de test"
   - Catégorie : "Accessoire"
   - Prix : 25.00
   - Stock : 10
   - Actif : ✓
4. Cliquer sur **"Créer"**
5. **Vérifier** : Le produit doit apparaître immédiatement dans la liste

### 2. Test de modification de produit
1. Cliquer sur l'icône **"Modifier"** du produit créé
2. Modifier le prix à 30.00
3. Cliquer sur **"Modifier"**
4. **Vérifier** : Le prix doit être mis à jour immédiatement dans la liste

### 3. Test de suppression de produit
1. Cliquer sur l'icône **"Supprimer"** du produit
2. Confirmer la suppression
3. **Vérifier** : Le produit doit disparaître immédiatement de la liste

## Test des services

### 1. Test d'ajout de service
1. Aller dans **Catalogue > Services**
2. Cliquer sur **"Nouveau service"**
3. Remplir le formulaire
4. Sauvegarder
5. **Vérifier** : Le service doit apparaître immédiatement

### 2. Test de modification de service
1. Modifier un service existant
2. **Vérifier** : Les modifications doivent être visibles immédiatement

## Test des pièces détachées

### 1. Test d'ajout de pièce
1. Aller dans **Catalogue > Pièces détachées**
2. Cliquer sur **"Nouvelle pièce"**
3. Remplir le formulaire
4. Sauvegarder
5. **Vérifier** : La pièce doit apparaître immédiatement

### 2. Test de modification de pièce
1. Modifier une pièce existante
2. **Vérifier** : Les modifications doivent être visibles immédiatement

## Test des modèles d'appareils

### 1. Test d'ajout de modèle
1. Aller dans **Catalogue > Modèles**
2. Cliquer sur **"Nouveau modèle"**
3. Remplir le formulaire
4. Sauvegarder
5. **Vérifier** : Le modèle doit apparaître immédiatement

### 2. Test de modification de modèle
1. Modifier un modèle existant
2. **Vérifier** : Les modifications doivent être visibles immédiatement

## Vérifications générales

### 1. Pas de rechargement nécessaire
- Aucune des opérations ne doit nécessiter un rechargement de page
- Les données doivent être mises à jour en temps réel

### 2. Gestion des erreurs
- En cas d'erreur réseau ou de base de données, un message d'erreur doit s'afficher
- L'interface ne doit pas se bloquer

### 3. Cohérence des données
- Les IDs générés doivent être corrects
- Les dates de création/modification doivent être cohérentes
- Les champs booléens (isActive) doivent être correctement gérés

## Cas d'erreur à tester

### 1. Erreur de connexion
1. Déconnecter l'internet
2. Essayer d'ajouter un produit
3. **Vérifier** : Un message d'erreur approprié doit s'afficher

### 2. Données invalides
1. Essayer d'ajouter un produit avec un prix négatif
2. **Vérifier** : La validation doit empêcher la sauvegarde

### 3. Champs obligatoires
1. Essayer d'ajouter un produit sans nom
2. **Vérifier** : La validation doit empêcher la sauvegarde

## Résultats attendus

Après ces tests, toutes les opérations CRUD doivent :
- ✅ Fonctionner sans rechargement de page
- ✅ Afficher les données en temps réel
- ✅ Gérer correctement les erreurs
- ✅ Maintenir la cohérence des données
- ✅ Respecter les validations de formulaire
