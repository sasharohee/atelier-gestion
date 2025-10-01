# Guide du Système de Demandes de Devis

## 📋 Vue d'ensemble

Le système de demandes de devis permet aux réparateurs de créer des URLs personnalisées pour recevoir des demandes de devis directement de leurs clients. Chaque réparateur peut avoir une ou plusieurs URLs uniques (ex: `localhost:3002/repphone`).

## 🚀 Fonctionnalités

### Pour les Réparateurs
- **URLs personnalisées** : Créer des URLs uniques pour recevoir des demandes
- **Gestion des demandes** : Voir, traiter et répondre aux demandes reçues
- **Statistiques** : Suivre le nombre de demandes, taux de conversion, etc.
- **Upload de fichiers** : Les clients peuvent joindre des photos/vidéos de leurs appareils

### Pour les Clients
- **Formulaire simple** : Interface intuitive pour décrire leur problème
- **Upload de fichiers** : Possibilité d'ajouter des photos de l'appareil
- **Confirmation** : Recevoir une confirmation par email
- **Suivi** : Possibilité de suivre l'état de leur demande

## 🛠️ Installation et Configuration

### 1. Déploiement des Tables

```bash
# Exécuter le script de déploiement
./deploy_quote_requests.sh
```

### 2. Configuration Supabase

1. **Bucket de stockage** : Le bucket `attachments` est créé automatiquement
2. **Politiques RLS** : Configurées pour la sécurité
3. **Fonctions** : Fonctions utilitaires pour la génération de numéros uniques

### 3. Configuration du Domaine

Dans les paramètres Supabase, ajouter votre domaine pour les URLs personnalisées.

## 📁 Structure des Fichiers

```
src/
├── components/QuoteRequest/
│   └── QuoteRequestForm.tsx          # Formulaire de demande
├── pages/QuoteRequest/
│   └── QuoteRequestPage.tsx          # Page publique du formulaire
├── pages/QuoteRequests/
│   └── QuoteRequestsManagement.tsx   # Gestion des demandes
├── services/
│   └── quoteRequestService.ts        # Service API
├── utils/
│   └── quoteRequestValidation.ts     # Validation et sécurité
└── types/
    └── index.ts                      # Types TypeScript

tables/creation/
└── quote_requests_tables.sql         # Script de création des tables
```

## 🔗 URLs et Routage

### URLs Publiques
- **Formulaire de demande** : `/quote/:customUrl`
  - Exemple : `/quote/repphone`
  - Accessible sans authentification

### URLs Authentifiées
- **Gestion des demandes** : `/app/quote-requests`
- **Navigation** : Ajoutée dans la sidebar

## 🗄️ Base de Données

### Tables Principales

#### `technician_custom_urls`
```sql
- id (UUID, PK)
- technician_id (UUID, FK vers auth.users)
- custom_url (VARCHAR, UNIQUE)
- is_active (BOOLEAN)
- created_at, updated_at
```

#### `quote_requests`
```sql
- id (UUID, PK)
- request_number (VARCHAR, UNIQUE) -- Format: QR-YYYYMMDD-XXXX
- custom_url (VARCHAR)
- technician_id (UUID, FK)
- client_first_name, client_last_name
- client_email, client_phone
- description, issue_description
- device_type, device_brand, device_model
- urgency (low/medium/high)
- status (pending/in_review/quoted/accepted/rejected/cancelled)
- priority (low/medium/high)
- response, estimated_price, estimated_duration
- ip_address, user_agent, source
- created_at, updated_at
```

#### `quote_request_attachments`
```sql
- id (UUID, PK)
- quote_request_id (UUID, FK)
- file_name, original_name
- file_size, mime_type
- file_path (TEXT)
- uploaded_at
```

## 🔒 Sécurité

### Validation des Données
- **Formulaire** : Validation côté client et serveur
- **Fichiers** : Types autorisés, taille limitée (10MB max)
- **URLs** : Format validé, mots réservés bloqués
- **Rate Limiting** : Protection contre le spam

### Politiques RLS
- **Lecture** : Les réparateurs voient seulement leurs demandes
- **Écriture** : Insertion publique pour les formulaires
- **Fichiers** : Accès contrôlé par utilisateur

### Types de Fichiers Autorisés
- Images : JPG, PNG, GIF, WebP
- Documents : PDF
- Texte : TXT

## 📱 Interface Utilisateur

### Formulaire de Demande
- **Design responsive** : Mobile et desktop
- **Validation en temps réel** : Feedback immédiat
- **Upload de fichiers** : Drag & drop supporté
- **Confirmation visuelle** : Message de succès

### Gestion des Demandes
- **Tableau de bord** : Statistiques en temps réel
- **Liste des demandes** : Filtrage et tri
- **Détails** : Vue complète de chaque demande
- **Actions** : Changer le statut, répondre

## 🔧 API et Services

### QuoteRequestService

#### Méthodes Principales
```typescript
// Récupérer un réparateur par URL
getTechnicianByCustomUrl(customUrl: string)

// Créer une demande
createQuoteRequest(requestData: QuoteRequest)

// Récupérer les demandes d'un réparateur
getQuoteRequestsByTechnician(technicianId: string)

// Mettre à jour le statut
updateQuoteRequestStatus(requestId: string, status: string)

// Gérer les URLs personnalisées
getCustomUrls(technicianId: string)
createCustomUrl(technicianId: string, customUrl: string)

// Upload de fichiers
uploadAttachment(file: File, quoteRequestId: string)
```

### Validation
```typescript
// Instance de validation
const validator = new QuoteRequestValidator()

// Valider le formulaire
validator.validateFormData(formData)

// Valider les fichiers
validator.validateFiles(files)

// Valider l'URL personnalisée
validator.validateCustomUrl(customUrl)
```

## 📊 Statistiques

### Métriques Disponibles
- **Total des demandes** : Nombre total reçu
- **Par statut** : Pending, in_review, quoted, accepted, rejected
- **Par urgence** : Low, medium, high
- **Temporelles** : Daily, weekly, monthly
- **Taux de conversion** : Demandes acceptées / total

### Fonction SQL
```sql
SELECT get_quote_request_stats('technician-uuid');
```

## 🚀 Utilisation

### Pour un Réparateur

1. **Créer une URL personnalisée**
   - Aller dans "Demandes de Devis"
   - Cliquer sur "Ajouter une URL"
   - Choisir un nom unique (ex: "repphone")

2. **Partager l'URL**
   - L'URL sera : `localhost:3002/quote/repphone`
   - Partager sur site web, réseaux sociaux, cartes de visite

3. **Gérer les demandes**
   - Recevoir des notifications
   - Consulter les détails
   - Changer le statut
   - Répondre avec un devis

### Pour un Client

1. **Accéder au formulaire**
   - Cliquer sur le lien partagé
   - Remplir les informations personnelles

2. **Décrire le problème**
   - Type d'appareil, marque, modèle
   - Description détaillée du problème
   - Niveau d'urgence

3. **Ajouter des fichiers**
   - Photos de l'appareil
   - Vidéos du problème
   - Documents PDF

4. **Envoyer la demande**
   - Recevoir une confirmation
   - Attendre la réponse du réparateur

## 🔧 Personnalisation

### Modifier les Types de Fichiers
```typescript
// Dans quoteRequestValidation.ts
const config = {
  allowedFileTypes: [
    'image/jpeg',
    'image/png',
    'application/pdf',
    // Ajouter d'autres types
  ]
}
```

### Modifier la Taille Max des Fichiers
```typescript
const config = {
  maxFileSize: 20 * 1024 * 1024, // 20MB
}
```

### Ajouter des Champs Personnalisés
1. Modifier les types dans `types/index.ts`
2. Mettre à jour le formulaire dans `QuoteRequestForm.tsx`
3. Ajouter les colonnes en base de données
4. Mettre à jour le service

## 🐛 Dépannage

### Problèmes Courants

#### L'URL personnalisée ne fonctionne pas
- Vérifier que l'URL est active
- Vérifier le format de l'URL
- Vérifier les politiques RLS

#### Les fichiers ne s'uploadent pas
- Vérifier la taille des fichiers
- Vérifier les types autorisés
- Vérifier les permissions du bucket

#### Les demandes n'apparaissent pas
- Vérifier l'authentification
- Vérifier les politiques RLS
- Vérifier les logs Supabase

### Logs et Debug
```typescript
// Activer les logs détaillés
console.log('Quote request data:', requestData);
console.log('Validation result:', validationResult);
```

## 📈 Améliorations Futures

### Fonctionnalités Suggérées
- **Notifications email** : Alertes automatiques
- **Chat intégré** : Communication directe
- **Devis automatiques** : IA pour estimer les prix
- **Intégration calendrier** : Prise de rendez-vous
- **Paiement en ligne** : Acomptes et règlements
- **Suivi en temps réel** : Statut live des réparations

### Optimisations Techniques
- **Cache Redis** : Pour le rate limiting
- **CDN** : Pour les fichiers uploadés
- **Compression** : Optimisation des images
- **PWA** : Application mobile native

## 📞 Support

Pour toute question ou problème :
1. Consulter ce guide
2. Vérifier les logs Supabase
3. Tester avec des données de démonstration
4. Contacter l'équipe de développement

---

**Version** : 1.0.0  
**Dernière mise à jour** : Décembre 2024  
**Auteur** : Équipe Atelier Gestion

