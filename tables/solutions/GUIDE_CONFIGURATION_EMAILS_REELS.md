# Guide de Configuration - Envoi d'Emails Réels

## Problème Identifié

Vous ne recevez pas les emails de confirmation car le système actuel ne fait que simuler l'envoi d'emails. Il n'y a pas de configuration SMTP ou de service d'email réel configuré.

## Solution : Configuration Supabase Auth

### Option 1 : Utiliser Supabase Auth (Recommandé)

Supabase propose un système d'envoi d'emails intégré via son service d'authentification.

#### Étape 1 : Accéder au Dashboard Supabase

1. Aller sur [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Sélectionner votre projet : `atelier-gestion`
3. Aller dans **Authentication** > **Email Templates**

#### Étape 2 : Configurer le Template de Confirmation

1. Cliquer sur **Confirmation**
2. Modifier le template avec le contenu suivant :

```html
<h2>Confirmation de votre inscription</h2>

<p>Bonjour !</p>

<p>Merci de vous être inscrit à notre application d'atelier.</p>

<p>Pour confirmer votre inscription, veuillez cliquer sur le bouton ci-dessous :</p>

<a href="{{ .ConfirmationURL }}" style="
    display: inline-block;
    padding: 12px 24px;
    background-color: #4CAF50;
    color: white;
    text-decoration: none;
    border-radius: 5px;
    margin: 20px 0;
">Confirmer mon inscription</a>

<p>Ou copiez-collez ce lien dans votre navigateur :</p>
<div style="
    background-color: #f0f0f0;
    padding: 10px;
    border-radius: 5px;
    font-family: monospace;
    margin: 10px 0;
">{{ .ConfirmationURL }}</div>

<p><strong>Token de confirmation :</strong></p>
<div style="
    background-color: #f0f0f0;
    padding: 10px;
    border-radius: 5px;
    font-family: monospace;
    margin: 10px 0;
">{{ .Token }}</div>

<p>Ce lien expirera dans 24 heures.</p>

<p>Si vous n'avez pas demandé cette inscription, vous pouvez ignorer cet email.</p>

<hr>
<p style="text-align: center; color: #666; font-size: 12px;">
    Cet email a été envoyé automatiquement. Merci de ne pas y répondre.<br>
    © 2024 App Atelier - Tous droits réservés
</p>
```

#### Étape 3 : Configurer les URLs de Redirection

1. Aller dans **Authentication** > **URL Configuration**
2. Configurer les URLs suivantes :

**Site URL :**
```
http://localhost:3002
```

**Redirect URLs :**
```
http://localhost:3002/auth/callback
http://localhost:3002/auth/confirm
http://localhost:3002/auth/reset-password
http://localhost:3002/auth/verify
http://localhost:3002/auth?tab=confirm&token=*
```

#### Étape 4 : Tester la Configuration

1. Exécuter le script SQL de configuration :
```sql
-- Exécuter dans l'éditeur SQL de Supabase
\i tables/configuration_emails_reels_supabase.sql
```

2. Tester la fonction :
```sql
SELECT * FROM test_email_configuration();
```

### Option 2 : Utiliser un Service d'Email Externe

Si vous préférez utiliser un service d'email externe (SendGrid, Mailgun, etc.), voici comment procéder :

#### Étape 1 : Créer un Compte

1. **SendGrid** : [https://sendgrid.com](https://sendgrid.com)
2. **Mailgun** : [https://mailgun.com](https://mailgun.com)
3. **Resend** : [https://resend.com](https://resend.com)

#### Étape 2 : Configurer les Variables d'Environnement

Ajouter dans votre fichier `.env` :

```env
# Pour SendGrid
VITE_SENDGRID_API_KEY=your_sendgrid_api_key
VITE_SENDGRID_FROM_EMAIL=noreply@votre-domaine.com

# Pour Mailgun
VITE_MAILGUN_API_KEY=your_mailgun_api_key
VITE_MAILGUN_DOMAIN=votre-domaine.com

# Pour Resend
VITE_RESEND_API_KEY=your_resend_api_key
VITE_RESEND_FROM_EMAIL=noreply@votre-domaine.com
```

#### Étape 3 : Modifier le Service

Créer un nouveau service d'email dans `src/services/emailService.ts` :

```typescript
// Exemple avec SendGrid
import { supabase } from '../lib/supabase';

export const emailService = {
  async sendConfirmationEmail(email: string, token: string, confirmationUrl: string) {
    try {
      // Utiliser l'API SendGrid
      const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${import.meta.env.VITE_SENDGRID_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          personalizations: [{
            to: [{ email }],
            subject: 'Confirmation de votre inscription - App Atelier'
          }],
          from: { email: import.meta.env.VITE_SENDGRID_FROM_EMAIL },
          content: [{
            type: 'text/html',
            value: generateEmailTemplate(token, confirmationUrl)
          }]
        })
      });

      if (response.ok) {
        return { success: true, message: 'Email envoyé avec succès' };
      } else {
        throw new Error('Échec de l\'envoi d\'email');
      }
    } catch (error) {
      console.error('Erreur lors de l\'envoi d\'email:', error);
      return { success: false, error: error.message };
    }
  }
};

function generateEmailTemplate(token: string, confirmationUrl: string): string {
  return `
    <h2>Confirmation de votre inscription</h2>
    <p>Cliquez sur ce lien pour confirmer : <a href="${confirmationUrl}">${confirmationUrl}</a></p>
    <p>Token : ${token}</p>
  `;
}
```

## Vérification de la Configuration

### Test 1 : Vérifier les Logs

Dans la console du navigateur, vous devriez voir :
```
✅ Token de confirmation généré
✅ Email de confirmation envoyé automatiquement
```

### Test 2 : Vérifier la Base de Données

```sql
-- Vérifier les emails en attente
SELECT * FROM confirmation_emails WHERE status = 'pending';

-- Vérifier les emails envoyés
SELECT * FROM confirmation_emails WHERE status = 'sent';
```

### Test 3 : Tester l'Envoi

1. Créer un nouveau compte avec votre email
2. Vérifier votre boîte de réception
3. Vérifier le dossier spam si nécessaire

## Dépannage

### Problème : Email non reçu

**Solutions :**
1. Vérifier le dossier spam
2. Vérifier la configuration des templates Supabase
3. Vérifier les URLs de redirection
4. Tester avec un autre email

### Problème : Erreur de configuration

**Solutions :**
1. Vérifier les permissions dans Supabase
2. Vérifier les variables d'environnement
3. Vérifier la connexion à l'API d'email

### Problème : Token invalide

**Solutions :**
1. Vérifier l'URL de confirmation
2. Vérifier l'expiration du token
3. Régénérer un nouveau token

## Configuration Alternative : Email de Test

Pour tester rapidement, vous pouvez utiliser un service comme Mailtrap :

1. Créer un compte sur [Mailtrap.io](https://mailtrap.io)
2. Configurer les paramètres SMTP
3. Utiliser les identifiants dans votre configuration

## Résolution Complète

Une fois la configuration terminée :

1. **Les emails seront envoyés automatiquement** lors de l'inscription
2. **Les tokens seront générés** et stockés en base
3. **Les liens de confirmation** fonctionneront correctement
4. **L'expérience utilisateur** sera complète

## Support

Si vous rencontrez des problèmes :

1. Vérifier les logs dans la console du navigateur
2. Vérifier les logs dans le dashboard Supabase
3. Tester avec la fonction `test_email_configuration()`
4. Consulter la documentation Supabase sur l'authentification

La configuration des emails est essentielle pour une expérience utilisateur complète. Une fois configurée, vos utilisateurs recevront automatiquement les emails de confirmation lors de leur inscription.
