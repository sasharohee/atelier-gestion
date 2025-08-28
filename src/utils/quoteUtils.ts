/**
 * Utilitaires pour la gestion des devis
 */

/**
 * Génère un numéro de devis unique au format DEV-YYYYMMDD-XXXX
 * @returns {string} Numéro de devis unique
 */
export const generateQuoteNumber = (): string => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const datePart = `${year}${month}${day}`;
  
  // Générer 4 chiffres aléatoires
  const randomPart = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  
  return `DEV-${datePart}-${randomPart}`;
};

/**
 * Valide un numéro de devis
 * @param {string} quoteNumber - Le numéro de devis à valider
 * @returns {boolean} True si le format est valide
 */
export const isValidQuoteNumber = (quoteNumber: string): boolean => {
  const pattern = /^DEV-\d{8}-\d{4}$/;
  return pattern.test(quoteNumber);
};

/**
 * Extrait la date de création à partir du numéro de devis
 * @param {string} quoteNumber - Le numéro de devis
 * @returns {Date | null} La date de création ou null si invalide
 */
export const extractDateFromQuoteNumber = (quoteNumber: string): Date | null => {
  if (!isValidQuoteNumber(quoteNumber)) {
    return null;
  }
  
  const datePart = quoteNumber.split('-')[1];
  const year = parseInt(datePart.substring(0, 4));
  const month = parseInt(datePart.substring(4, 6)) - 1; // Les mois commencent à 0
  const day = parseInt(datePart.substring(6, 8));
  
  return new Date(year, month, day);
};

/**
 * Formate un numéro de devis pour l'affichage
 * @param {string} quoteNumber - Le numéro de devis
 * @returns {string} Le numéro formaté
 */
export const formatQuoteNumber = (quoteNumber: string): string => {
  if (!isValidQuoteNumber(quoteNumber)) {
    return quoteNumber; // Retourner tel quel si invalide
  }
  
  const parts = quoteNumber.split('-');
  const datePart = parts[1];
  const year = datePart.substring(0, 4);
  const month = datePart.substring(4, 6);
  const day = datePart.substring(6, 8);
  const randomPart = parts[2];
  
  return `${parts[0]}-${day}/${month}/${year}-${randomPart}`;
};
