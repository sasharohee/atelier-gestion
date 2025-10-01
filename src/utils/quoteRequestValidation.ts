// Utilitaires de validation et sécurité pour les demandes de devis

export interface ValidationResult {
  isValid: boolean;
  errors: Record<string, string>;
}

export interface SecurityConfig {
  maxFileSize: number; // en bytes
  allowedFileTypes: string[];
  maxFilesPerRequest: number;
  rateLimitWindow: number; // en minutes
  maxRequestsPerWindow: number;
}

// Configuration par défaut
export const DEFAULT_SECURITY_CONFIG: SecurityConfig = {
  maxFileSize: 10 * 1024 * 1024, // 10MB
  allowedFileTypes: [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/gif',
    'image/webp',
    'application/pdf',
    'text/plain',
  ],
  maxFilesPerRequest: 5,
  rateLimitWindow: 60, // 1 heure
  maxRequestsPerWindow: 3, // 3 demandes par heure par IP
};

export class QuoteRequestValidator {
  private config: SecurityConfig;

  constructor(config: SecurityConfig = DEFAULT_SECURITY_CONFIG) {
    this.config = config;
  }

  // Valider les données du formulaire
  validateFormData(data: {
    clientFirstName: string;
    clientLastName: string;
    clientEmail: string;
    clientPhone: string;
    description: string;
    issueDescription: string;
    urgency: string;
  }): ValidationResult {
    const errors: Record<string, string> = {};

    // Validation du prénom
    if (!data.clientFirstName?.trim()) {
      errors.clientFirstName = 'Le prénom est requis';
    } else if (data.clientFirstName.trim().length < 2) {
      errors.clientFirstName = 'Le prénom doit contenir au moins 2 caractères';
    } else if (data.clientFirstName.trim().length > 50) {
      errors.clientFirstName = 'Le prénom ne peut pas dépasser 50 caractères';
    } else if (!/^[a-zA-ZÀ-ÿ\s'-]+$/.test(data.clientFirstName.trim())) {
      errors.clientFirstName = 'Le prénom contient des caractères non autorisés';
    }

    // Validation du nom
    if (!data.clientLastName?.trim()) {
      errors.clientLastName = 'Le nom est requis';
    } else if (data.clientLastName.trim().length < 2) {
      errors.clientLastName = 'Le nom doit contenir au moins 2 caractères';
    } else if (data.clientLastName.trim().length > 50) {
      errors.clientLastName = 'Le nom ne peut pas dépasser 50 caractères';
    } else if (!/^[a-zA-ZÀ-ÿ\s'-]+$/.test(data.clientLastName.trim())) {
      errors.clientLastName = 'Le nom contient des caractères non autorisés';
    }

    // Validation de l'email
    if (!data.clientEmail?.trim()) {
      errors.clientEmail = 'L\'email est requis';
    } else {
      const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
      if (!emailRegex.test(data.clientEmail.trim())) {
        errors.clientEmail = 'Format d\'email invalide';
      } else if (data.clientEmail.trim().length > 255) {
        errors.clientEmail = 'L\'email ne peut pas dépasser 255 caractères';
      }
    }

    // Validation du téléphone
    if (!data.clientPhone?.trim()) {
      errors.clientPhone = 'Le téléphone est requis';
    } else {
      const phoneRegex = /^[+]?[0-9\s\-\(\)]{10,20}$/;
      if (!phoneRegex.test(data.clientPhone.trim())) {
        errors.clientPhone = 'Format de téléphone invalide';
      }
    }

    // Validation de la description
    if (!data.description?.trim()) {
      errors.description = 'La description est requise';
    } else if (data.description.trim().length < 10) {
      errors.description = 'La description doit contenir au moins 10 caractères';
    } else if (data.description.trim().length > 1000) {
      errors.description = 'La description ne peut pas dépasser 1000 caractères';
    }

    // Validation de la description du problème
    if (!data.issueDescription?.trim()) {
      errors.issueDescription = 'La description du problème est requise';
    } else if (data.issueDescription.trim().length < 20) {
      errors.issueDescription = 'La description du problème doit contenir au moins 20 caractères';
    } else if (data.issueDescription.trim().length > 2000) {
      errors.issueDescription = 'La description du problème ne peut pas dépasser 2000 caractères';
    }

    // Validation de l'urgence
    if (!data.urgency || !['low', 'medium', 'high'].includes(data.urgency)) {
      errors.urgency = 'Niveau d\'urgence invalide';
    }

    return {
      isValid: Object.keys(errors).length === 0,
      errors,
    };
  }

  // Valider les fichiers joints
  validateFiles(files: File[]): ValidationResult {
    const errors: Record<string, string> = {};

    if (files.length > this.config.maxFilesPerRequest) {
      errors.files = `Maximum ${this.config.maxFilesPerRequest} fichiers autorisés`;
      return { isValid: false, errors };
    }

    files.forEach((file, index) => {
      const fileKey = `file_${index}`;

      // Vérifier la taille
      if (file.size > this.config.maxFileSize) {
        errors[fileKey] = `Le fichier ${file.name} est trop volumineux (max ${this.formatFileSize(this.config.maxFileSize)})`;
        return;
      }

      // Vérifier le type
      if (!this.config.allowedFileTypes.includes(file.type)) {
        errors[fileKey] = `Le type de fichier ${file.type} n'est pas autorisé`;
        return;
      }

      // Vérifier le nom du fichier
      if (file.name.length > 255) {
        errors[fileKey] = `Le nom du fichier ${file.name} est trop long`;
        return;
      }

      // Vérifier les caractères dangereux dans le nom
      if (!/^[a-zA-Z0-9._\-\s()]+$/.test(file.name)) {
        errors[fileKey] = `Le nom du fichier ${file.name} contient des caractères non autorisés`;
        return;
      }
    });

    return {
      isValid: Object.keys(errors).length === 0,
      errors,
    };
  }

  // Valider une URL personnalisée
  validateCustomUrl(customUrl: string): ValidationResult {
    const errors: Record<string, string> = {};

    if (!customUrl?.trim()) {
      errors.customUrl = 'L\'URL personnalisée est requise';
    } else {
      const trimmedUrl = customUrl.trim();

      // Vérifier la longueur
      if (trimmedUrl.length < 3) {
        errors.customUrl = 'L\'URL doit contenir au moins 3 caractères';
      } else if (trimmedUrl.length > 50) {
        errors.customUrl = 'L\'URL ne peut pas dépasser 50 caractères';
      }

      // Vérifier le format
      if (!/^[a-zA-Z0-9-]+$/.test(trimmedUrl)) {
        errors.customUrl = 'L\'URL ne peut contenir que des lettres, chiffres et tirets';
      }

      // Vérifier qu'elle ne commence ou ne finit pas par un tiret
      if (trimmedUrl.startsWith('-') || trimmedUrl.endsWith('-')) {
        errors.customUrl = 'L\'URL ne peut pas commencer ou finir par un tiret';
      }

      // Vérifier qu'elle ne contient pas de mots réservés
      const reservedWords = [
        'admin', 'api', 'app', 'auth', 'dashboard', 'login', 'logout',
        'register', 'profile', 'settings', 'help', 'support', 'contact',
        'about', 'privacy', 'terms', 'legal', 'www', 'mail', 'ftp',
        'blog', 'news', 'shop', 'store', 'cart', 'checkout', 'payment'
      ];

      if (reservedWords.includes(trimmedUrl.toLowerCase())) {
        errors.customUrl = 'Cette URL est réservée et ne peut pas être utilisée';
      }
    }

    return {
      isValid: Object.keys(errors).length === 0,
      errors,
    };
  }

  // Nettoyer et sécuriser les données d'entrée
  sanitizeInput(input: string): string {
    if (!input) return '';

    return input
      .trim()
      .replace(/[<>]/g, '') // Supprimer les balises HTML
      .replace(/javascript:/gi, '') // Supprimer les scripts JavaScript
      .replace(/on\w+=/gi, '') // Supprimer les événements JavaScript
      .substring(0, 1000); // Limiter la longueur
  }

  // Vérifier si une chaîne contient du contenu suspect
  containsSuspiciousContent(text: string): boolean {
    const suspiciousPatterns = [
      /<script/i,
      /javascript:/i,
      /on\w+\s*=/i,
      /data:text\/html/i,
      /vbscript:/i,
      /<iframe/i,
      /<object/i,
      /<embed/i,
    ];

    return suspiciousPatterns.some(pattern => pattern.test(text));
  }

  // Valider une adresse IP
  isValidIP(ip: string): boolean {
    const ipv4Regex = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
    const ipv6Regex = /^(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$/;
    
    return ipv4Regex.test(ip) || ipv6Regex.test(ip);
  }

  // Valider un User-Agent
  isValidUserAgent(userAgent: string): boolean {
    if (!userAgent || userAgent.length > 500) {
      return false;
    }

    // Vérifier qu'il ne contient pas de contenu suspect
    return !this.containsSuspiciousContent(userAgent);
  }

  // Formater la taille d'un fichier
  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  // Générer un hash simple pour le rate limiting
  generateRateLimitKey(ip: string, customUrl: string): string {
    return `quote_request:${ip}:${customUrl}`;
  }

  // Vérifier le rate limiting (à implémenter avec Redis ou base de données)
  async checkRateLimit(ip: string, customUrl: string): Promise<{
    allowed: boolean;
    remaining: number;
    resetTime: number;
  }> {
    // Cette fonction devrait être implémentée avec un système de cache
    // Pour l'instant, on retourne toujours autorisé
    return {
      allowed: true,
      remaining: this.config.maxRequestsPerWindow,
      resetTime: Date.now() + (this.config.rateLimitWindow * 60 * 1000),
    };
  }

  // Valider les métadonnées de la requête
  validateRequestMetadata(metadata: {
    ipAddress?: string;
    userAgent?: string;
    referer?: string;
  }): ValidationResult {
    const errors: Record<string, string> = {};

    if (metadata.ipAddress && !this.isValidIP(metadata.ipAddress)) {
      errors.ipAddress = 'Adresse IP invalide';
    }

    if (metadata.userAgent && !this.isValidUserAgent(metadata.userAgent)) {
      errors.userAgent = 'User-Agent invalide';
    }

    if (metadata.referer && metadata.referer.length > 2000) {
      errors.referer = 'Referer trop long';
    }

    return {
      isValid: Object.keys(errors).length === 0,
      errors,
    };
  }

  // Valider l'ensemble d'une demande de devis
  validateQuoteRequest(requestData: {
    formData: any;
    files: File[];
    metadata: any;
    customUrl: string;
  }): ValidationResult {
    const allErrors: Record<string, string> = {};

    // Valider le formulaire
    const formValidation = this.validateFormData(requestData.formData);
    if (!formValidation.isValid) {
      Object.assign(allErrors, formValidation.errors);
    }

    // Valider les fichiers
    const filesValidation = this.validateFiles(requestData.files);
    if (!filesValidation.isValid) {
      Object.assign(allErrors, filesValidation.errors);
    }

    // Valider l'URL personnalisée
    const urlValidation = this.validateCustomUrl(requestData.customUrl);
    if (!urlValidation.isValid) {
      Object.assign(allErrors, urlValidation.errors);
    }

    // Valider les métadonnées
    const metadataValidation = this.validateRequestMetadata(requestData.metadata);
    if (!metadataValidation.isValid) {
      Object.assign(allErrors, metadataValidation.errors);
    }

    return {
      isValid: Object.keys(allErrors).length === 0,
      errors: allErrors,
    };
  }
}

// Instance par défaut
export const quoteRequestValidator = new QuoteRequestValidator();

// Fonctions utilitaires
export const sanitizeHtml = (input: string): string => {
  return input
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/\//g, '&#x2F;');
};

export const escapeRegex = (string: string): string => {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
};

export const generateSecureToken = (length: number = 32): string => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

