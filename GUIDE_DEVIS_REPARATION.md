# Guide - Devis pour Réparations

## 📋 Vue d'ensemble

La fonctionnalité de devis pour réparations permet de créer des devis directement pour des réparations, sans avoir besoin de passer par le module de réparations. Cette approche simplifie le processus de devis pour les réparations.

## 🆕 Fonctionnalités

### 1. Création de devis pour réparations
- **Sélection du type "Réparations"** dans le formulaire de devis
- **Création directe de réparation** depuis la page devis
- **Formulaire spécialisé** pour les réparations
- **Intégration automatique** dans le devis

### 2. Formulaire de réparation intégré
- **Client** : Sélection obligatoire
- **Appareil** : Sélection optionnelle parmi les appareils existants
- **Description** : Description détaillée de la réparation
- **Problème** : Problème technique identifié (optionnel)
- **Durée estimée** : En minutes
- **Prix estimé** : Montant de la réparation
- **Dates** : Début et fin estimées
- **Urgence** : Marquer comme réparation urgente

### 3. Gestion des données
- **Création dynamique** : La réparation est créée à la volée
- **Intégration dans le devis** : Ajout automatique comme article
- **Calcul automatique** : Prix intégré dans les totaux
- **Client automatique** : Synchronisation avec le client du devis

## 🚀 Utilisation

### Créer un devis pour réparation

1. **Accéder à la page Devis** : Transaction → Devis
2. **Cliquer sur "Nouveau devis"**
3. **Sélectionner le type "Réparations"** dans le sélecteur d'articles
4. **Cliquer sur "Créer une réparation"**
5. **Remplir le formulaire de réparation** :
   - Sélectionner le client
   - Choisir l'appareil (optionnel)
   - Décrire la réparation
   - Définir la durée et le prix
   - Ajuster les dates
   - Marquer comme urgent si nécessaire
6. **Cliquer sur "Créer la réparation"**
7. **La réparation apparaît** dans la liste des articles du devis
8. **Finaliser le devis** avec notes et conditions
9. **Créer le devis**

### Workflow complet

```
Page Devis → Nouveau devis → Type "Réparations" → 
Créer réparation → Formulaire réparation → 
Réparation ajoutée au devis → Finaliser devis
```

## 📊 Interface utilisateur

### Sélection du type "Réparations"

Dans le formulaire de devis, quand vous sélectionnez "Réparations" :

- **Icône** : 🔧 Réparations
- **Badge** : "Créer" (au lieu d'un nombre)
- **Interface** : Bouton de création au lieu d'une liste

### Formulaire de réparation

#### Champs obligatoires
- **Client** : Sélecteur avec liste des clients
- **Description** : Zone de texte multiligne
- **Durée estimée** : Champ numérique en minutes
- **Prix estimé** : Champ numérique en euros
- **Date de début** : DatePicker

#### Champs optionnels
- **Appareil** : Autocomplete avec liste des appareils
- **Problème** : Zone de texte pour le problème technique
- **Urgence** : Switch pour marquer comme urgent

#### Calculs automatiques
- **Date de fin** : Calculée selon la durée
- **Résumé** : Affichage du temps et du prix

### Affichage dans le devis

#### Dans la liste des articles
- **Nom** : "Réparation - [Description tronquée]"
- **Badge** : Chip "Réparation" en bleu
- **Prix** : Prix estimé de la réparation
- **Quantité** : Toujours 1

#### Dans la vue détaillée
- **Mise en forme** : Chip "Réparation" à côté du nom
- **Description** : Description complète de la réparation
- **Impression** : Marqué comme réparation dans le PDF

## 🗄️ Structure technique

### Types TypeScript mis à jour

```typescript
// Type QuoteItem étendu
export interface QuoteItem {
  type: 'product' | 'service' | 'part' | 'repair'; // Ajout de 'repair'
  // ... autres champs
}

// Type Quote étendu
export interface Quote {
  // ... champs existants
  isRepairQuote?: boolean;
  repairDetails?: {
    deviceId?: string;
    description: string;
    issue?: string;
    estimatedDuration?: number;
    estimatedStartDate?: Date;
    estimatedEndDate?: Date;
    isUrgent?: boolean;
  };
}
```

### Base de données

```sql
-- Table quotes mise à jour
ALTER TABLE public.quotes ADD COLUMN is_repair_quote BOOLEAN DEFAULT false;
ALTER TABLE public.quotes ADD COLUMN repair_details JSONB DEFAULT '{}'::jsonb;

-- Table quote_items mise à jour
ALTER TABLE public.quote_items 
  DROP CONSTRAINT IF EXISTS quote_items_type_check;
ALTER TABLE public.quote_items 
  ADD CONSTRAINT quote_items_type_check 
  CHECK (type IN ('product', 'service', 'part', 'repair'));
```

### Composants créés

1. **RepairForm.tsx** : Formulaire de création de réparation
2. **QuoteForm.tsx** : Mis à jour pour intégrer RepairForm
3. **Quotes.tsx** : Mis à jour pour gérer les réparations
4. **QuoteView.tsx** : Mis à jour pour afficher les réparations

## 🔧 Configuration

### Script SQL à exécuter

```sql
-- Exécuter le fichier tables/create_quotes_table.sql
-- (déjà mis à jour avec les nouveaux champs)
```

### Types TypeScript

Les types sont déjà mis à jour dans `src/types/index.ts`

### Composants

Tous les composants nécessaires sont créés et intégrés

## 📈 Avantages

### Pour l'utilisateur
- **Processus simplifié** : Création de devis et réparation en une seule fois
- **Interface unifiée** : Tout dans la page devis
- **Flexibilité** : Possibilité de créer des réparations sans passer par le module réparations
- **Rapidité** : Workflow optimisé

### Pour l'atelier
- **Devis plus précis** : Réparations détaillées dans les devis
- **Suivi amélioré** : Traçabilité des réparations dans les devis
- **Conversion facilitée** : Devis accepté → Réparation créée
- **Gestion centralisée** : Tout dans le module Transaction

## 🔄 Intégration future

### Conversion devis → réparation
- **Devis accepté** : Création automatique de la réparation
- **Synchronisation** : Données du devis → réparation
- **Suivi** : Lien entre devis et réparation

### Améliorations prévues
- **Templates de réparation** : Modèles prédéfinis
- **Services automatiques** : Ajout automatique de services selon le type de réparation
- **Pièces automatiques** : Suggestion de pièces selon l'appareil
- **Prix automatiques** : Calcul basé sur les services et pièces

## 🛠️ Support technique

### Problèmes courants

#### Réparation non créée
- Vérifier que tous les champs obligatoires sont remplis
- Contrôler les erreurs de validation
- Vérifier la connexion à la base de données

#### Prix incorrect
- Vérifier le champ "Prix estimé"
- Contrôler que le montant est positif
- Valider le format numérique

#### Client non synchronisé
- Vérifier que le client est sélectionné dans le formulaire de réparation
- Contrôler que le client existe dans la base de données

### Logs et débogage
- **Console navigateur** : Erreurs JavaScript
- **Validation** : Messages d'erreur dans le formulaire
- **État** : Vérifier les données dans le state React

## 📚 Ressources

### Documentation
- [Guide des devis](../GUIDE_FONCTIONNALITE_DEVIS.md)
- [Types TypeScript](../src/types/index.ts)
- [Script SQL](../tables/create_quotes_table.sql)

### Composants
- [RepairForm](../src/pages/Quotes/RepairForm.tsx)
- [QuoteForm](../src/pages/Quotes/QuoteForm.tsx)
- [Quotes](../src/pages/Quotes/Quotes.tsx)
- [QuoteView](../src/pages/Quotes/QuoteView.tsx)

### Intégration
- [Page Transaction](../src/pages/Transaction/Transaction.tsx)
- [Navigation](../src/components/Layout/Sidebar.tsx)
