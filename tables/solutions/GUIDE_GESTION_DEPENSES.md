# Guide de Gestion des Dépenses

## Vue d'ensemble

La page de gestion des dépenses permet de suivre et organiser toutes les dépenses de votre atelier de réparation. Cette fonctionnalité inclut :

- **Gestion des dépenses** : Création, modification et suppression des dépenses
- **Catégorisation** : Organisation des dépenses par catégories personnalisables
- **Statistiques** : Tableaux de bord avec métriques financières
- **Filtrage et recherche** : Outils pour trouver rapidement les dépenses
- **Suivi des paiements** : Statuts et méthodes de paiement

## Installation

### 1. Création des tables de base de données

Exécutez le fichier SQL suivant dans votre base de données Supabase :

```sql
-- Voir le fichier : tables/creation/expenses_tables.sql
```

Ce fichier crée :
- Table `expense_categories` : Catégories de dépenses
- Table `expenses` : Dépenses avec tous les détails
- Politiques RLS (Row Level Security) pour la sécurité
- Index pour optimiser les performances
- Catégories par défaut

### 2. Vérification de l'installation

1. Connectez-vous à votre application
2. Naviguez vers **Dépenses** dans le menu de gauche
3. Vérifiez que la page se charge correctement

## Utilisation

### Accès à la page

1. Dans le menu de navigation, cliquez sur **Dépenses**
2. La page s'ouvre avec deux onglets :
   - **Dépenses** : Liste et gestion des dépenses
   - **Catégories** : Gestion des catégories

### Gestion des Catégories

#### Créer une nouvelle catégorie

1. Cliquez sur l'onglet **Catégories**
2. Cliquez sur **Nouvelle Catégorie**
3. Remplissez les informations :
   - **Nom** : Nom de la catégorie (obligatoire)
   - **Description** : Description optionnelle
   - **Couleur** : Couleur pour l'affichage
4. Cliquez sur **Créer**

#### Modifier une catégorie

1. Dans la liste des catégories, cliquez sur **Modifier**
2. Modifiez les informations souhaitées
3. Cliquez sur **Mettre à jour**

#### Supprimer une catégorie

1. Dans la liste des catégories, cliquez sur **Supprimer**
2. Confirmez la suppression

> ⚠️ **Attention** : La suppression d'une catégorie peut affecter les dépenses existantes.

### Gestion des Dépenses

#### Créer une nouvelle dépense

1. Cliquez sur l'onglet **Dépenses**
2. Cliquez sur **Nouvelle Dépense**
3. Remplissez le formulaire :

**Champs obligatoires :**
- **Titre** : Nom de la dépense
- **Montant** : Montant en euros
- **Catégorie** : Sélectionnez une catégorie

**Champs optionnels :**
- **Description** : Détails de la dépense
- **Fournisseur** : Nom du fournisseur
- **Numéro de facture** : Référence de la facture
- **Méthode de paiement** : Espèces, Carte, Virement, Chèque
- **Statut** : En attente, Payé, Annulé
- **Date de dépense** : Date de la dépense
- **Date d'échéance** : Date limite de paiement

4. Cliquez sur **Créer**

#### Modifier une dépense

1. Dans la liste des dépenses, cliquez sur l'icône **Modifier** (crayon)
2. Modifiez les informations souhaitées
3. Cliquez sur **Mettre à jour**

#### Supprimer une dépense

1. Dans la liste des dépenses, cliquez sur l'icône **Supprimer** (poubelle)
2. Confirmez la suppression

### Filtrage et Recherche

#### Recherche textuelle

Utilisez le champ de recherche pour trouver des dépenses par :
- Titre
- Description
- Nom du fournisseur

#### Filtres

- **Statut** : Filtrer par statut (En attente, Payé, Annulé)
- **Catégorie** : Filtrer par catégorie
- **Période** : Filtrer par période (Aujourd'hui, Cette semaine, Ce mois, Cette année)

### Statistiques

Le tableau de bord affiche :

- **Total Dépenses** : Somme de toutes les dépenses
- **Ce Mois** : Dépenses du mois en cours
- **En Attente** : Montant des dépenses non payées
- **Payé** : Montant des dépenses payées

## Catégories par Défaut

Les catégories suivantes sont créées automatiquement :

1. **Fournitures** - Fournitures de bureau et matériel
2. **Équipement** - Achat d'équipement technique
3. **Formation** - Formations et certifications
4. **Marketing** - Publicité et marketing
5. **Transport** - Frais de transport et déplacement
6. **Loyer** - Loyer et charges
7. **Assurance** - Assurances diverses
8. **Autres** - Autres dépenses

## Fonctionnalités Avancées

### Méthodes de Paiement

- **Espèces** : Paiement en liquide
- **Carte bancaire** : Paiement par carte
- **Virement** : Virement bancaire
- **Chèque** : Paiement par chèque

### Statuts des Dépenses

- **En attente** : Dépense enregistrée mais non payée
- **Payé** : Dépense réglée
- **Annulé** : Dépense annulée

### Tags

Les dépenses peuvent être étiquetées pour une meilleure organisation (fonctionnalité à venir).

## Sécurité

- **Isolation des données** : Chaque utilisateur ne voit que ses propres dépenses
- **Politiques RLS** : Sécurité au niveau de la base de données
- **Validation** : Contrôles de saisie côté client et serveur

## Dépannage

### Problèmes courants

1. **Page ne se charge pas**
   - Vérifiez que les tables sont créées dans Supabase
   - Vérifiez les politiques RLS

2. **Erreur lors de la création d'une dépense**
   - Vérifiez que tous les champs obligatoires sont remplis
   - Vérifiez que la catégorie existe

3. **Statistiques incorrectes**
   - Actualisez la page
   - Vérifiez les données dans la base

### Logs et débogage

Les erreurs sont affichées dans la console du navigateur et via des notifications toast.

## Support

Pour toute question ou problème :

1. Vérifiez ce guide
2. Consultez les logs de la console
3. Contactez le support technique

---

**Version** : 1.0  
**Dernière mise à jour** : Décembre 2024
