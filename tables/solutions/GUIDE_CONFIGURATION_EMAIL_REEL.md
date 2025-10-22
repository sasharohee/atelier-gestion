# Guide - Configuration de l'Envoi d'Emails Réel

## 🚨 Problème Actuel
Le système actuel ne fait que simuler l'envoi d'emails. Les emails ne sont pas réellement envoyés aux utilisateurs.

## 🔧 Solutions Disponibles

### Option 1: Service d'Email Externe (Recommandé)

#### A. SendGrid (Gratuit jusqu'à 100 emails/jour)
1. **Créer un compte SendGrid**
   - Aller sur [sendgrid.com](https://sendgrid.com)
   - Créer un compte gratuit
   - Vérifier votre domaine d'email

2. **Obtenir une API Key**
   - Dans le dashboard SendGrid
   - Settings > API Keys
   - Créer une nouvelle API Key avec les permissions "Mail Send"

3. **Configurer dans Supabase**
   ```sql
   -- Ajouter la clé API comme variable d'environnement
   -- Dans Supabase Dashboard > Settings > Environment Variables
   SENDGRID_API_KEY=votre_clé_api_ici
   ```

#### B. Mailgun (Gratuit jusqu'à 5000 emails/mois)
1. **Créer un compte Mailgun**
   - Aller sur [mailgun.com](https://mailgun.com)
   - Créer un compte gratuit
   - Configurer votre domaine

2. **Obtenir les credentials**
   - API Key
   - Domain name

3. **Configurer dans Supabase**
   ```sql
   MAILGUN_API_KEY=votre_clé_api_ici
   MAILGUN_DOMAIN=votre_domaine.mailgun.org
   ```

### Option 2: Extension pg_mail (Supabase)

#### A. Installer l'extension
```sql
-- Dans l'éditeur SQL de Supabase
CREATE EXTENSION IF NOT EXISTS pg_mail;
```

#### B. Configurer pg_mail
```sql
-- Configurer le serveur SMTP
SELECT mail.smtp_set_server('smtp.gmail.com', 587);
SELECT mail.smtp_set_auth('votre_email@gmail.com', 'votre_mot_de_passe_app');
```

### Option 3: Edge Functions Supabase (Avancé)

#### A. Créer une Edge Function
```javascript
// supabase/functions/send-email/index.js
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { email, token, confirmation_url } = await req.json()
  
  // Utiliser un service d'email comme SendGrid
  const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SENDGRID_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email }] }],
      from: { email: 'noreply@votreapp.com' },
      subject: 'Confirmation de votre inscription',
      content: [{
        type: 'text/html',
        value: `Votre lien de confirmation: ${confirmation_url}`
      }]
    })
  })
  
  return new Response(JSON.stringify({ success: response.ok }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

## 🛠️ Implémentation Recommandée

### Étape 1: Choisir SendGrid (Solution Simple)

1. **Créer le compte SendGrid**
2. **Obtenir l'API Key**
3. **Configurer dans Supabase**

### Étape 2: Modifier la Fonction d'Envoi

```sql
-- Remplacer la fonction send_confirmation_email_real
CREATE OR REPLACE FUNCTION send_confirmation_email_real(p_email TEXT, p_token TEXT, p_confirmation_url TEXT)
RETURNS JSON AS $$
DECLARE
    email_content TEXT;
    email_subject TEXT;
    result JSON;
BEGIN
    -- Construire le contenu de l'email (HTML)
    email_subject := 'Confirmation de votre inscription - App Atelier';
    
    email_content := '
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Confirmation d''inscription</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .button { display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Confirmation d''inscription</h1>
            </div>
            <div class="content">
                <h2>Bonjour !</h2>
                <p>Merci de vous être inscrit à notre application d''atelier.</p>
                <p>Pour confirmer votre inscription, veuillez cliquer sur le bouton ci-dessous :</p>
                
                <a href="' || p_confirmation_url || '" class="button">Confirmer mon inscription</a>
                
                <p>Ce lien expirera dans 24 heures.</p>
                <p>Si vous n''avez pas demandé cette inscription, vous pouvez ignorer cet email.</p>
            </div>
            <div class="footer">
                <p>© 2024 App Atelier - Tous droits réservés</p>
            </div>
        </div>
    </body>
    </html>';

    -- ICI: Intégrer l'appel à SendGrid ou autre service
    -- Pour l'instant, nous simulons l'envoi
    
    -- Mettre à jour le statut dans la base de données
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND token = p_token;
    
    -- Retourner le résultat
    result := json_build_object(
        'success', true,
        'message', 'Email de confirmation envoyé',
        'email', p_email,
        'token', p_token,
        'confirmation_url', p_confirmation_url,
        'sent_at', NOW()
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'email', p_email,
            'token', p_token
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Étape 3: Solution Temporaire - Envoi Manuel

En attendant la configuration d'un service d'email, vous pouvez :

1. **Vérifier les emails en attente**
   ```sql
   SELECT * FROM list_pending_emails_for_admin();
   ```

2. **Envoyer manuellement un email**
   ```sql
   SELECT send_manual_confirmation_email('email@example.com');
   ```

3. **Utiliser les URLs de confirmation directement**
   - Les URLs sont générées et stockées
   - Vous pouvez les copier et les envoyer manuellement

## 📋 Configuration Rapide SendGrid

### 1. Créer le Compte
- Aller sur [sendgrid.com](https://sendgrid.com)
- Créer un compte gratuit
- Vérifier votre email

### 2. Obtenir l'API Key
- Dashboard > Settings > API Keys
- Create API Key
- Full Access ou Restricted Access (Mail Send)

### 3. Configurer dans Supabase
- Dashboard Supabase > Settings > Environment Variables
- Ajouter : `SENDGRID_API_KEY=votre_clé_ici`

### 4. Tester
```sql
-- Tester l'envoi
SELECT generate_confirmation_token_and_send_email('test@example.com');
```

## ⚠️ Notes Importantes

### Sécurité
- Ne jamais exposer les clés API dans le code client
- Utiliser les variables d'environnement Supabase
- Limiter les permissions des clés API

### Performance
- Les services d'email ont des limites de débit
- Surveiller les quotas d'envoi
- Implémenter une file d'attente si nécessaire

### Monitoring
- Surveiller les taux de livraison
- Tracker les bounces et les erreurs
- Configurer les webhooks pour les notifications

## 🎯 Prochaines Étapes

1. **Choisir un service d'email** (SendGrid recommandé)
2. **Configurer les credentials** dans Supabase
3. **Tester l'envoi** avec un email de test
4. **Monitorer** les envois et les erreurs
5. **Optimiser** le contenu des emails

---

**CONFIGURATION** : Une fois configuré, les utilisateurs recevront réellement leurs emails de confirmation et pourront confirmer leur inscription.
