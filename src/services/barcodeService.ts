import bwipjs from 'bwip-js';

/**
 * Service de génération et validation de codes-barres EAN-13
 */
export class BarcodeService {
  /**
   * Génère un code EAN-13 unique avec checksum valide
   * Utilise le préfixe 200-299 pour les codes internes
   */
  static generateEAN13(): string {
    // Préfixe pour usage interne (200-299)
    const prefix = '200';
    
    // Générer 9 chiffres aléatoires pour la partie entreprise + produit
    // (3 préfixe + 9 aléatoire = 12 chiffres total)
    const randomPart = Math.floor(Math.random() * 1000000000).toString().padStart(9, '0');
    
    // Combiner préfixe + partie aléatoire (12 chiffres)
    const baseCode = prefix + randomPart;
    
    // Calculer le checksum EAN-13
    const checksum = this.calculateEAN13Checksum(baseCode);
    
    return baseCode + checksum;
  }

  /**
   * Calcule le checksum pour un code EAN-13
   */
  private static calculateEAN13Checksum(code: string): string {
    if (code.length !== 12) {
      throw new Error('Le code doit contenir exactement 12 chiffres pour calculer le checksum EAN-13');
    }

    let sum = 0;
    for (let i = 0; i < 12; i++) {
      const digit = parseInt(code[i]);
      // Multiplier par 1 pour les positions impaires, par 3 pour les positions paires
      const multiplier = (i % 2 === 0) ? 1 : 3;
      sum += digit * multiplier;
    }

    // Le checksum est le chiffre qui, ajouté à la somme, donne un multiple de 10
    const checksum = (10 - (sum % 10)) % 10;
    return checksum.toString();
  }

  /**
   * Valide un code EAN-13 (format et checksum)
   */
  static validateEAN13(barcode: string): boolean {
    // Vérifier la longueur
    if (!barcode || barcode.length !== 13) {
      return false;
    }

    // Vérifier que tous les caractères sont des chiffres
    if (!/^\d{13}$/.test(barcode)) {
      return false;
    }

    // Vérifier le checksum
    const baseCode = barcode.substring(0, 12);
    const providedChecksum = barcode.substring(12);
    const calculatedChecksum = this.calculateEAN13Checksum(baseCode);

    return providedChecksum === calculatedChecksum;
  }

  /**
   * Génère une image du code-barres
   */
  static generateBarcodeImage(barcode: string, options: {
    width?: number;
    height?: number;
    scale?: number;
  } = {}): string {
    const {
      width = 200,
      height = 50,
      scale = 2
    } = options;

    try {
      // Vérifier si bwip-js est disponible
      if (typeof bwipjs === 'undefined') {
        console.warn('bwip-js non disponible, utilisation du fallback');
        return this.generateFallbackBarcode(barcode, width, height);
      }

      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      
      // Utiliser toCanvas avec des paramètres optimisés
      bwipjs.toCanvas(canvas, {
        bcid: 'ean13',        // Type de code-barres
        text: barcode,        // Le code à encoder
        scale: Math.max(1, Math.min(scale, 3)), // Limiter le scale entre 1 et 3
        width: Math.max(100, width),  // Largeur minimum
        height: Math.max(30, height), // Hauteur minimum
        includetext: false,   // Pas de texte pour les miniatures
        textxalign: 'center', // Alignement du texte
      });

      // Convertir le canvas en data URL
      const dataUrl = canvas.toDataURL('image/png');
      
      // Créer un élément img avec le data URL et styles optimisés
      return `<img src="${dataUrl}" alt="Code-barres ${barcode}" style="max-width: 100%; height: auto; object-fit: contain; display: block;" />`;
    } catch (error) {
      console.error('Erreur lors de la génération du code-barres:', error);
      // Fallback en cas d'erreur
      return this.generateFallbackBarcode(barcode, width, height);
    }
  }

  /**
   * Génère un code-barres de fallback simple
   */
  private static generateFallbackBarcode(barcode: string, width: number, height: number): string {
    // Créer un code-barres simple avec des barres CSS
    const bars = this.generateSimpleBars(barcode);
    
    return `
      <div style="
        width: ${width}px; 
        height: ${height}px; 
        border: 1px solid #ccc; 
        display: flex; 
        align-items: center; 
        justify-content: center;
        background: white;
        font-family: monospace;
        font-size: 10px;
        text-align: center;
        flex-direction: column;
        gap: 2px;
      ">
        <div style="font-size: 8px; color: #666;">EAN-13</div>
        <div style="font-size: 12px; font-weight: bold;">${barcode}</div>
        <div style="font-size: 8px; color: #666;">Code-barres</div>
      </div>
    `;
  }

  /**
   * Génère des barres simples pour le fallback
   */
  private static generateSimpleBars(barcode: string): string {
    // Générer des barres simples basées sur les chiffres
    let bars = '';
    for (let i = 0; i < barcode.length; i++) {
      const digit = parseInt(barcode[i]);
      const barWidth = (digit % 3) + 1; // Largeur variable selon le chiffre
      bars += `<div style="display: inline-block; width: ${barWidth}px; height: 20px; background: black; margin-right: 1px;"></div>`;
    }
    return bars;
  }

  /**
   * Génère une image PNG du code-barres (base64)
   */
  static generateBarcodePNG(barcode: string, options: {
    width?: number;
    height?: number;
    scale?: number;
  } = {}): string {
    const {
      width = 200,
      height = 50,
      scale = 2
    } = options;

    try {
      const canvas = document.createElement('canvas');
      const png = bwipjs.toCanvas(canvas, {
        bcid: 'ean13',        // Type de code-barres
        text: barcode,        // Le code à encoder
        scale: scale,         // Facteur d'échelle
        width: width,         // Largeur de l'image
        height: height,       // Hauteur de l'image
        includetext: true,    // Inclure le texte sous le code-barres
        textxalign: 'center', // Alignement du texte
      });

      return canvas.toDataURL('image/png');
    } catch (error) {
      console.error('Erreur lors de la génération du code-barres PNG:', error);
      throw new Error('Impossible de générer le code-barres PNG');
    }
  }

  /**
   * Génère un code EAN-13 unique et valide
   * Vérifie l'unicité en comparant avec une liste de codes existants
   */
  static generateUniqueEAN13(existingBarcodes: string[] = []): string {
    let attempts = 0;
    const maxAttempts = 100;

    while (attempts < maxAttempts) {
      const barcode = this.generateEAN13();
      
      // Vérifier l'unicité
      if (!existingBarcodes.includes(barcode)) {
        return barcode;
      }
      
      attempts++;
    }

    // Si on n'a pas trouvé de code unique après 100 tentatives,
    // ajouter un timestamp pour garantir l'unicité
    const timestamp = Date.now().toString().slice(-3); // 3 chiffres du timestamp
    const prefix = '200';
    const randomPart = Math.floor(Math.random() * 1000000).toString().padStart(6, '0'); // 6 chiffres aléatoires
    const baseCode = prefix + randomPart + timestamp; // 3 + 6 + 3 = 12 chiffres
    const checksum = this.calculateEAN13Checksum(baseCode);
    
    return baseCode + checksum;
  }

  /**
   * Formate un code EAN-13 pour l'affichage (avec espaces)
   */
  static formatBarcode(barcode: string): string {
    if (!barcode || barcode.length !== 13) {
      return barcode;
    }

    // Format: XXX XXXX XXXX X
    return `${barcode.substring(0, 3)} ${barcode.substring(3, 7)} ${barcode.substring(7, 11)} ${barcode.substring(11)}`;
  }
}

export default BarcodeService;
