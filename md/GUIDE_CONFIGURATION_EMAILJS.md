# Guide de Configuration EmailJS pour le Formulaire de Contact

## 📧 Vue d'ensemble

Ce guide explique comment configurer EmailJS pour le formulaire de contact de la page Support d'Atelier Gestion.

## 🔧 Configuration EmailJS

### 1. Créer un compte EmailJS

1. Allez sur [EmailJS.com](https://www.emailjs.com/)
2. Créez un compte gratuit
3. Vérifiez votre email

### 2. Configurer le Service Email

1. Dans votre dashboard EmailJS, allez dans "Email Services"
2. Cliquez sur "Add New Service"
3. Choisissez votre fournisseur d'email (Gmail, Outlook, etc.)
4. Connectez votre compte email
5. Notez le **Service ID** généré

### 3. Créer le Template Email

1. Allez dans "Email Templates"
2. Cliquez sur "Create New Template"
3. Utilisez le template HTML fourni dans `email_confirmation_template.html`
4. Configurez les variables du template :
   - `{{from_name}}` - Nom de l'expéditeur
   - `{{from_email}}` - Email de l'expéditeur
   - `{{subject}}` - Sujet du message
   - `{{message}}` - Contenu du message
   - `{{date}}` - Date de réception
   - `{{to_name}}` - Nom du destinataire
   - `{{company_name}}` - Nom de l'entreprise
   - `{{support_email}}` - Email de support
   - `{{support_phone}}` - Téléphone de support

5. Notez le **Template ID** généré

### 4. Obtenir la Clé Publique

1. Allez dans "Account" > "API Keys"
2. Copiez votre **Public Key**

## ⚙️ Configuration dans l'Application

### 1. Mettre à jour la Configuration

Modifiez le fichier `src/config/emailjs.ts` :

```typescript
export const EMAILJS_CONFIG = {
  // Remplacez par votre Service ID
  SERVICE_ID: 'service_lisw5h9',
  
  // Remplacez par votre Template ID
  TEMPLATE_ID: 'template_dabl0od',
  
  // Remplacez par votre Public Key
  PUBLIC_KEY: 'VOTRE_CLE_PUBLIQUE_ICI',
  
  // ... reste de la configuration
};
```

### 2. Variables d'Environnement (Recommandé)

Pour plus de sécurité, utilisez des variables d'environnement :

1. Créez un fichier `.env.local` à la racine du projet :

```env
VITE_EMAILJS_SERVICE_ID=service_lisw5h9
VITE_EMAILJS_TEMPLATE_ID=template_dabl0od
VITE_EMAILJS_PUBLIC_KEY=votre_cle_publique_ici
```

2. Modifiez `src/config/emailjs.ts` :

```typescript
export const EMAILJS_CONFIG = {
  SERVICE_ID: import.meta.env.VITE_EMAILJS_SERVICE_ID || 'service_lisw5h9',
  TEMPLATE_ID: import.meta.env.VITE_EMAILJS_TEMPLATE_ID || 'template_dabl0od',
  PUBLIC_KEY: import.meta.env.VITE_EMAILJS_PUBLIC_KEY || 'YOUR_PUBLIC_KEY',
  // ... reste de la configuration
};
```

## 🧪 Test de la Configuration

### 1. Test Local

1. Démarrez l'application : `npm run dev`
2. Allez sur la page Support (`/support`)
3. Remplissez le formulaire de contact
4. Soumettez le formulaire
5. Vérifiez que l'email est reçu

### 2. Vérification des Logs

Ouvrez la console du navigateur pour voir :
- Les paramètres envoyés
- La priorité du message
- Le type de support détecté
- La confirmation d'envoi

## 📋 Fonctionnalités Implémentées

### 1. Validation des Données

- Validation du nom (requis)
- Validation de l'email (format valide)
- Validation du sujet (requis)
- Validation du message (requis)

### 2. Analyse Automatique

- **Priorité du message** : Normal, Élevée, Urgente
- **Type de support** : Technique, Comptable, Commercial, RGPD, Général

### 3. Interface Utilisateur

- Indicateur de chargement
- Messages d'erreur/succès
- Validation en temps réel
- Design responsive

### 4. Template Email Professionnel

- Design moderne et responsive
- Informations structurées
- Actions recommandées
- Informations de contact

## 🔒 Sécurité

### 1. Protection des Clés

- Utilisez des variables d'environnement
- Ne committez jamais les clés dans Git
- Limitez les permissions du service email

### 2. Validation Côté Client

- Validation des champs obligatoires
- Validation du format email
- Protection contre les soumissions multiples

### 3. Rate Limiting

EmailJS propose des limites par défaut :
- Compte gratuit : 200 emails/mois
- Compte payant : Limites plus élevées

## 🚨 Dépannage

### Problème : Email non reçu

1. Vérifiez la configuration EmailJS
2. Vérifiez les logs dans la console
3. Vérifiez le dossier spam
4. Testez avec un email différent

### Problème : Erreur 400/500

1. Vérifiez les IDs de service et template
2. Vérifiez la clé publique
3. Vérifiez le format des paramètres
4. Consultez la documentation EmailJS

### Problème : Template non affiché

1. Vérifiez le HTML du template
2. Vérifiez les variables du template
3. Testez le template dans EmailJS
4. Vérifiez les permissions du service

## 📞 Support

Pour toute question ou problème :

1. Consultez la [documentation EmailJS](https://www.emailjs.com/docs/)
2. Vérifiez les logs de l'application
3. Testez avec un compte EmailJS différent
4. Contactez l'équipe de développement

## 🔄 Mise à Jour

Pour mettre à jour la configuration :

1. Modifiez `src/config/emailjs.ts`
2. Redémarrez l'application
3. Testez le formulaire
4. Vérifiez la réception des emails

---

**Note** : Ce guide suppose que vous avez déjà configuré EmailJS avec les identifiants fournis (`service_lisw5h9` et `template_dabl0od`). Si ce n'est pas le cas, suivez d'abord les étapes de configuration EmailJS.
