/**
 * Utilitaires pour le formatage des devises
 */

// Taux de change par rapport à l'EUR (devise de référence)
const EXCHANGE_RATES: Record<string, number> = {
  EUR: 1.0,
  USD: 1.08,
  CHF: 0.95
};

// Symboles des devises
const CURRENCY_SYMBOLS: Record<string, string> = {
  EUR: '€',
  USD: '$',
  CHF: 'CHF'
};

/**
 * Convertit un montant d'une devise à une autre
 * @param amount - Montant à convertir
 * @param fromCurrency - Devise source
 * @param toCurrency - Devise cible
 * @returns Montant converti
 */
export const convertCurrency = (amount: number, fromCurrency: string, toCurrency: string): number => {
  if (fromCurrency === toCurrency) {
    return amount;
  }

  const rateFrom = EXCHANGE_RATES[fromCurrency];
  const rateTo = EXCHANGE_RATES[toCurrency];

  if (!rateFrom || !rateTo) {
    console.warn(`Taux de change manquant pour ${fromCurrency} ou ${toCurrency}. Retourne le montant original.`);
    return amount;
  }

  // Convertir d'abord en EUR, puis vers la devise cible
  const amountInEUR = amount / rateFrom;
  return amountInEUR * rateTo;
};

/**
 * Formate un montant en EUR vers la devise cible avec le symbole approprié.
 * @param amountInEUR - Montant en EUR
 * @param targetCurrency - Devise cible (ex: 'USD', 'CHF')
 * @param locale - Locale pour le formatage (par défaut 'fr-FR')
 * @returns Montant formaté avec le symbole de devise
 */
export const formatFromEUR = (amountInEUR: number, targetCurrency: string, locale: string = 'fr-FR'): string => {
  const convertedAmount = convertCurrency(amountInEUR, 'EUR', targetCurrency);
  const symbol = CURRENCY_SYMBOLS[targetCurrency] || targetCurrency; // Fallback au code si symbole non trouvé

  return `${convertedAmount.toLocaleString(locale, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${symbol}`;
};

/**
 * Obtient le symbole de devise basé sur le code de devise
 * @param currency - Code de la devise (EUR, USD, GBP, CHF)
 * @returns Le symbole de la devise
 */
export const getCurrencySymbol = (currency: string): string => {
  const symbols: { [key: string]: string } = {
    'EUR': '€',
    'USD': '$',
    'GBP': '£',
    'CHF': 'CHF'
  };
  
  return symbols[currency] || currency;
};

/**
 * Formate un montant avec la devise appropriée
 * @param amount - Le montant à formater
 * @param currency - Le code de la devise
 * @param locale - La locale pour le formatage (défaut: 'fr-FR')
 * @returns Le montant formaté avec la devise
 */
export const formatCurrency = (amount: number, currency: string, locale: string = 'fr-FR'): string => {
  const symbol = getCurrencySymbol(currency);
  
  // Pour CHF, on affiche "CHF" après le montant
  if (currency === 'CHF') {
    return `${amount.toLocaleString(locale)} ${symbol}`;
  }
  
  // Pour les autres devises, on utilise le symbole standard
  return `${symbol}${amount.toLocaleString(locale)}`;
};

/**
 * Formate un montant avec la devise pour les rapports HTML
 * @param amount - Le montant à formater
 * @param currency - Le code de la devise
 * @returns Le montant formaté pour l'affichage HTML
 */
export const formatCurrencyForHTML = (amount: number, currency: string): string => {
  const symbol = getCurrencySymbol(currency);
  
  // Pour CHF, on affiche "CHF" après le montant
  if (currency === 'CHF') {
    return `${amount.toLocaleString('fr-FR')} ${symbol}`;
  }
  
  // Pour les autres devises, on utilise le symbole standard
  return `${symbol}${amount.toLocaleString('fr-FR')}`;
};
