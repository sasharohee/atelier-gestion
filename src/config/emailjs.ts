// Configuration EmailJS pour Atelier Gestion
export const EMAILJS_CONFIG = {
  // Service ID fourni
  SERVICE_ID: import.meta.env.VITE_EMAILJS_SERVICE_ID || 'service_lisw5h9',
  
  // Template ID fourni
  TEMPLATE_ID: import.meta.env.VITE_EMAILJS_TEMPLATE_ID || 'template_dabl0od',
  
  // Clé publique EmailJS
  PUBLIC_KEY: import.meta.env.VITE_EMAILJS_PUBLIC_KEY || 'mh5fruIpuHfRxF7YC',
  
  // Paramètres par défaut du template
  DEFAULT_PARAMS: {
    to_name: 'Équipe Support Atelier Gestion',
    company_name: 'Atelier Gestion',
    support_email: 'contact.ateliergestion@gmail.com',
    support_phone: '+33 1 23 45 67 89'
  }
};

// Types pour les paramètres EmailJS
export interface EmailJSParams {
  from_name: string;
  from_email: string;
  subject: string;
  message: string;
  to_name?: string;
  date?: string;
  company_name?: string;
  support_email?: string;
  support_phone?: string;
}

// Fonction pour préparer les paramètres EmailJS
export const prepareEmailJSParams = (params: Partial<EmailJSParams>): EmailJSParams => {
  const now = new Date();
  const formattedDate = now.toLocaleString('fr-FR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });

  return {
    ...EMAILJS_CONFIG.DEFAULT_PARAMS,
    date: formattedDate,
    from_name: params.from_name || '',
    from_email: params.from_email || '',
    subject: params.subject || '',
    message: params.message || '',
    ...params
  };
};

// Fonction pour valider les paramètres EmailJS
export const validateEmailJSParams = (params: EmailJSParams): { isValid: boolean; errors: string[] } => {
  const errors: string[] = [];

  if (!params.from_name || params.from_name.trim().length === 0) {
    errors.push('Le nom est requis');
  }

  if (!params.from_email || !isValidEmail(params.from_email)) {
    errors.push('L\'email est requis et doit être valide');
  }

  if (!params.subject || params.subject.trim().length === 0) {
    errors.push('Le sujet est requis');
  }

  if (!params.message || params.message.trim().length === 0) {
    errors.push('Le message est requis');
  }

  return {
    isValid: errors.length === 0,
    errors
  };
};

// Fonction pour valider un email
const isValidEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

// Fonction pour obtenir la priorité du message basée sur le contenu
export const getMessagePriority = (subject: string, message: string): 'normal' | 'high' | 'urgent' => {
  const urgentKeywords = ['urgent', 'urgente', 'critique', 'bloqué', 'bloquée', 'erreur', 'bug', 'panne'];
  const highKeywords = ['important', 'problème', 'difficulté', 'aide', 'support'];
  
  const content = `${subject} ${message}`.toLowerCase();
  
  if (urgentKeywords.some(keyword => content.includes(keyword))) {
    return 'urgent';
  }
  
  if (highKeywords.some(keyword => content.includes(keyword))) {
    return 'high';
  }
  
  return 'normal';
};

// Fonction pour classer le type de support
export const getSupportType = (subject: string, message: string): 'technique' | 'comptable' | 'commercial' | 'rgpd' | 'general' => {
  const content = `${subject} ${message}`.toLowerCase();
  
  const technicalKeywords = ['bug', 'erreur', 'problème', 'fonctionnalité', 'interface', 'connexion', 'performance'];
  const accountingKeywords = ['facture', 'paiement', 'abonnement', 'tarif', 'prix', 'comptabilité', 'billing'];
  const commercialKeywords = ['devis', 'devis', 'fonctionnalité', 'amélioration', 'suggestion', 'demande'];
  const rgpdKeywords = ['données', 'confidentialité', 'rgpd', 'suppression', 'privacy', 'personnelles'];
  
  if (technicalKeywords.some(keyword => content.includes(keyword))) {
    return 'technique';
  }
  
  if (accountingKeywords.some(keyword => content.includes(keyword))) {
    return 'comptable';
  }
  
  if (commercialKeywords.some(keyword => content.includes(keyword))) {
    return 'commercial';
  }
  
  if (rgpdKeywords.some(keyword => content.includes(keyword))) {
    return 'rgpd';
  }
  
  return 'general';
};
