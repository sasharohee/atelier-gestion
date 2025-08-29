# Guide de la Fonctionnalité Devis

## 📋 Vue d'ensemble

La fonctionnalité Devis permet de créer, gérer et suivre les devis pour les clients. Elle est intégrée dans le module Transaction et offre une gestion complète du cycle de vie des devis.

## 🆕 Fonctionnalités principales

### 1. Création de devis
- **Sélection de client** : Choisir un client existant ou créer un devis anonyme
- **Ajout d'articles** : Produits, services et pièces détachées
- **Calcul automatique** : Sous-total, TVA (20%) et total
- **Validité** : Date de validité personnalisable
- **Notes et conditions** : Informations additionnelles

### 2. Gestion des statuts
- **Brouillon** : Devis en cours de création
- **Envoyé** : Devis transmis au client
- **Accepté** : Devis accepté par le client
- **Refusé** : Devis refusé par le client
- **Expiré** : Devis dépassé

### 3. Visualisation et impression
- **Vue détaillée** : Affichage complet du devis
- **Impression** : Génération de PDF pour impression
- **Historique** : Suivi des modifications

## 🚀 Utilisation

### Accès à la fonctionnalité

1. **Navigation** : Menu principal → Transaction → Devis
2. **URL directe** : `/app/transaction/quotes`

### Créer un nouveau devis

1. **Cliquer sur "Nouveau devis"**
2. **Sélectionner un client** (optionnel)
3. **Définir la validité** (par défaut 30 jours)
4. **Ajouter des articles** :
   - Choisir le type (Produits, Services, Pièces)
   - Filtrer par catégorie
   - Rechercher un article
   - Cliquer pour ajouter
5. **Ajuster les quantités** si nécessaire
6. **Ajouter des notes** et conditions
7. **Créer le devis**

### Gérer les devis existants

#### Actions disponibles
- **Voir** : Afficher le détail du devis
- **Modifier** : Éditer le devis (à implémenter)
- **Supprimer** : Supprimer définitivement
- **Changer le statut** : Envoyer, Accepter, Refuser

#### Workflow des statuts
```
Brouillon → Envoyé → Accepté/Refusé
    ↓
  Expiré (automatique)
```

## 📊 Interface utilisateur

### Page principale des devis

#### En-tête
- **Titre** : "Devis"
- **Bouton** : "Nouveau devis"
- **Statistiques** : Total, Envoyés, Acceptés, CA potentiel

#### Tableau des devis
- **N° Devis** : Identifiant unique
- **Client** : Nom et email
- **Date** : Date de création
- **Montant** : Total avec nombre d'articles
- **Validité** : Date d'expiration
- **Statut** : Chip coloré avec libellé
- **Actions** : Voir, Modifier, Supprimer

### Formulaire de création

#### Section gauche - Informations générales
- **Client** : Sélecteur avec liste des clients
- **Validité** : DatePicker pour la date d'expiration
- **Notes** : Zone de texte pour notes additionnelles
- **Conditions** : Zone de texte pour termes et conditions

#### Section droite - Sélection d'articles
- **Type d'article** : Produits, Services, Pièces
- **Catégorie** : Filtre par catégorie
- **Recherche** : Recherche textuelle
- **Liste des articles** : Affichage avec prix et actions

#### Section bas - Articles sélectionnés
- **Liste des articles** : Nom, quantité, prix unitaire, total
- **Modification des quantités** : Champ numérique
- **Suppression** : Bouton de suppression
- **Totaux** : Calcul automatique

### Vue détaillée du devis

#### En-tête
- **Titre** : Numéro du devis
- **Actions** : Imprimer, Fermer

#### Contenu
- **Alert d'expiration** : Si le devis a expiré
- **Informations client** : Détails du client
- **Détails du devis** : Numéro, dates, statut
- **Tableau des articles** : Détail complet
- **Totaux** : Calculs détaillés
- **Notes et conditions** : Si renseignées

#### Actions selon le statut
- **Brouillon** : Bouton "Envoyer"
- **Envoyé** : Boutons "Accepter" et "Refuser"
- **Autres** : Bouton "Fermer" uniquement

## 🗄️ Structure de données

### Table `quotes`
```sql
CREATE TABLE public.quotes (
  id UUID PRIMARY KEY,
  client_id UUID REFERENCES clients(id),
  items JSONB NOT NULL DEFAULT '[]',
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  tax DECIMAL(10,2) NOT NULL DEFAULT 0,
  total DECIMAL(10,2) NOT NULL DEFAULT 0,
  status quote_status_type DEFAULT 'draft',
  valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
  notes TEXT,
  terms TEXT,
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Type `Quote`
```typescript
export interface Quote {
  id: string;
  clientId?: string;
  items: QuoteItem[];
  subtotal: number;
  tax: number;
  total: number;
  status: 'draft' | 'sent' | 'accepted' | 'rejected' | 'expired';
  validUntil: Date;
  notes?: string;
  terms?: string;
  createdAt: Date;
  updatedAt: Date;
}
```

### Type `QuoteItem`
```typescript
export interface QuoteItem {
  id: string;
  type: 'product' | 'service' | 'part';
  itemId: string;
  name: string;
  description?: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}
```

## 🔧 Configuration

### Base de données
Exécuter le script SQL pour créer les tables :
```sql
-- Exécuter le fichier tables/create_quotes_table.sql
```

### Types TypeScript
Les types sont déjà ajoutés dans `src/types/index.ts`

### Navigation
La section Devis est automatiquement ajoutée au menu Transaction

## 📈 Évolutions futures

### Fonctionnalités prévues
- **Modification de devis** : Éditer un devis existant
- **Conversion en vente** : Transformer un devis accepté en vente
- **Templates** : Modèles de devis personnalisables
- **Email automatique** : Envoi automatique par email
- **Suivi des versions** : Historique des modifications
- **Signatures électroniques** : Validation électronique
- **Intégration CRM** : Synchronisation avec d'autres outils

### Améliorations techniques
- **Store Zustand** : Intégration complète avec le store
- **API Supabase** : Services pour la persistance
- **Validation** : Validation des données côté client
- **Tests** : Tests unitaires et d'intégration
- **Performance** : Optimisation des requêtes

## 🛠️ Support technique

### Problèmes courants

#### Devis non sauvegardé
- Vérifier la connexion à la base de données
- Contrôler les permissions RLS
- Vérifier les logs d'erreur

#### Calculs incorrects
- Vérifier les prix des articles
- Contrôler le taux de TVA (20%)
- Valider les quantités

#### Impression impossible
- Vérifier les permissions du navigateur
- Contrôler les bloqueurs de popup
- Tester avec un autre navigateur

### Logs et débogage
- **Console navigateur** : Erreurs JavaScript
- **Logs Supabase** : Erreurs de base de données
- **Network** : Requêtes API

## 📚 Ressources

### Documentation
- [Guide des types TypeScript](../src/types/index.ts)
- [Script SQL de création](../tables/create_quotes_table.sql)
- [Composant principal](../src/pages/Quotes/Quotes.tsx)

### Exemples
- [Formulaire de création](../src/pages/Quotes/QuoteForm.tsx)
- [Vue détaillée](../src/pages/Quotes/QuoteView.tsx)

### Intégration
- [Page Transaction](../src/pages/Transaction/Transaction.tsx)
- [Navigation Sidebar](../src/components/Layout/Sidebar.tsx)
