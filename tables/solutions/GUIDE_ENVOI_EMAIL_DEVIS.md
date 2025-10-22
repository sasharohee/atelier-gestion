# 📧 Guide - Envoi d'Email des Devis

## 🎯 Fonctionnalité

La fonctionnalité d'envoi d'email permet d'envoyer automatiquement un devis par email au client avec un message pré-configuré et professionnel.

## 🚀 Comment utiliser

### 1. **Accéder au devis**
- Aller dans **Transaction > Devis**
- Cliquer sur l'icône "Voir" (👁️) d'un devis

### 2. **Envoyer le devis par email**
- Dans la vue du devis, cliquer sur **"Envoyer par email"** (📧)
- Le client email par défaut s'ouvre automatiquement
- Le message est pré-rempli avec :
  - ✅ Destinataire : Email du client
  - ✅ Sujet : "Devis #[numéro] - Mon Atelier"
  - ✅ Contenu : Message professionnel avec tous les détails

### 3. **Renvoyer un devis**
- Pour les devis déjà envoyés, utiliser **"Renvoyer par email"**
- Permet de renvoyer le devis sans changer le statut

## 📋 Contenu du message

### **Template automatique inclus :**

```
Bonjour [Prénom Nom],

Nous avons le plaisir de vous transmettre notre devis pour les services demandés.

📋 DÉTAILS DU DEVIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Numéro de devis : #[numéro]
• Date de création : [date]
• Validité : jusqu'au [date]
• Montant total : [montant] €

📦 ARTICLES INCLUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• [Article 1] - [quantité]x [prix]€ = [total]€
• [Article 2] - [quantité]x [prix]€ = [total]€

📝 NOTES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Notes du devis]

📋 CONDITIONS ET TERMES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Conditions du devis]

💡 PROCHAINES ÉTAPES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pour accepter ce devis, vous pouvez :
• Répondre à cet email avec "J'accepte"
• Nous appeler au 01 23 45 67 89
• Nous contacter via notre site web

❓ QUESTIONS ?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pour toute question concernant ce devis, n'hésitez pas à nous contacter.

Cordialement,
L'équipe Mon Atelier
📧 contact@monatelier.fr
📞 01 23 45 67 89
🌐 www.monatelier.fr
```

## ⚙️ Fonctionnalités techniques

### **Gestion automatique :**
- ✅ **Vérification email** : Le bouton est désactivé si le client n'a pas d'email
- ✅ **Encodage URL** : Les caractères spéciaux sont automatiquement encodés
- ✅ **Statut automatique** : Le devis passe en statut "Envoyé" après envoi
- ✅ **Client par défaut** : Utilise le client email configuré sur l'ordinateur

### **Sécurité :**
- ✅ **Validation email** : Vérification que le client a une adresse email
- ✅ **Message d'erreur** : Alert si aucun email disponible
- ✅ **Ouverture sécurisée** : Nouvel onglet pour l'email

## 🎨 Interface utilisateur

### **Boutons disponibles :**

| Statut du devis | Bouton affiché | Action |
|----------------|----------------|---------|
| **Brouillon** | "Envoyer par email" | Envoie et change le statut |
| **Envoyé** | "Renvoyer par email" | Renvoie sans changer le statut |
| **Accepté/Refusé** | Aucun bouton email | - |

### **Icônes utilisées :**
- 📧 **EmailIcon** : Pour les boutons d'envoi d'email
- ✅ **CheckCircleIcon** : Pour accepter le devis
- ❌ **CancelIcon** : Pour refuser le devis

## 🔧 Personnalisation

### **Modifier le template :**
Le template est défini dans `src/pages/Quotes/QuoteView.tsx` dans la fonction `handleSendEmail()`.

### **Changer les informations de contact :**
Modifier les lignes suivantes dans le template :
```typescript
📧 contact@monatelier.fr
📞 01 23 45 67 89
🌐 www.monatelier.fr
```

### **Ajouter des champs personnalisés :**
Le template inclut automatiquement :
- ✅ Nom et prénom du client
- ✅ Numéro de devis
- ✅ Dates de création et validité
- ✅ Montant total
- ✅ Liste des articles
- ✅ Notes et conditions

## 🚨 Gestion des erreurs

### **Cas d'erreur :**
1. **Client sans email** : Bouton désactivé + message d'erreur
2. **Client email non configuré** : L'utilisateur doit configurer son client email

### **Messages d'erreur :**
```
❌ Aucune adresse email disponible pour ce client.
```

## 📱 Compatibilité

### **Clients email supportés :**
- ✅ **Outlook** (Windows/Mac)
- ✅ **Apple Mail** (Mac)
- ✅ **Thunderbird** (Multi-plateforme)
- ✅ **Gmail** (via navigateur)
- ✅ **Tous les clients mailto** standards

### **Navigateurs supportés :**
- ✅ **Chrome**
- ✅ **Firefox**
- ✅ **Safari**
- ✅ **Edge**

## 🔄 Workflow complet

1. **Créer un devis** → Statut : Brouillon
2. **Envoyer par email** → Statut : Envoyé
3. **Client reçoit l'email** avec tous les détails
4. **Client peut accepter/refuser** via l'interface
5. **Renvoyer si nécessaire** sans changer le statut

## 💡 Conseils d'utilisation

### **Avant l'envoi :**
- ✅ Vérifier que le client a une adresse email
- ✅ Relire le contenu du devis
- ✅ Vérifier les notes et conditions

### **Après l'envoi :**
- ✅ Suivre le statut du devis
- ✅ Répondre aux questions du client
- ✅ Renvoyer si nécessaire

### **Personnalisation :**
- ✅ Adapter le template selon vos besoins
- ✅ Modifier les informations de contact
- ✅ Ajouter votre logo ou signature

## 🎯 Avantages

- ✅ **Professionnel** : Template soigné et structuré
- ✅ **Automatique** : Pré-remplissage complet
- ✅ **Flexible** : Possibilité de modifier avant envoi
- ✅ **Traçable** : Statut automatiquement mis à jour
- ✅ **Sécurisé** : Validation des données
