/**
 * Service pour la détection automatique des codes-barres scannés
 * Compatible avec les lecteurs de codes-barres externes (USB, Bluetooth, etc.)
 */

export interface ScannedProduct {
  id: string;
  name: string;
  description: string;
  category: string;
  price: number;
  stockQuantity: number;
  barcode: string;
  isActive: boolean;
}

export class BarcodeScannerService {
  private static instance: BarcodeScannerService;
  private listeners: ((barcode: string) => void)[] = [];
  private isListening = false;
  private scanBuffer = '';
  private scanTimeout: NodeJS.Timeout | null = null;
  private lastKeyTime = 0;
  private captureHistory: Array<{key: string, timestamp: number}> = [];
  private captureInput: HTMLInputElement | null = null;
  private lastDetectionTime: number = 0;

  private constructor() {
    this.setupKeyboardListener();
  }

  public static getInstance(): BarcodeScannerService {
    if (!BarcodeScannerService.instance) {
      BarcodeScannerService.instance = new BarcodeScannerService();
    }
    return BarcodeScannerService.instance;
  }

  /**
   * Configure l'écoute des événements clavier pour détecter les scans
   * Les lecteurs de codes-barres externes simulent une saisie clavier rapide
   */
  private setupKeyboardListener(): void {
    // Un seul listener pour éviter les doublons
    document.addEventListener('keydown', (event) => {
      // Ignorer si focus dans un input
      if (event.target && (event.target as HTMLElement).tagName === 'INPUT') {
        return;
      }
      
      // Ignorer les touches spéciales
      if (event.ctrlKey || event.altKey || event.metaKey) {
        return;
      }

      // Log détaillé de TOUS les événements
      console.log('🎹 Touche détectée:', {
        key: event.key,
        code: event.code,
        keyCode: event.keyCode,
        which: event.which,
        charCode: event.charCode,
        type: event.type
      });

      // Capturer les chiffres ET les touches spéciales des scanners
      if (event.key.length === 1 && /[0-9]/.test(event.key)) {
        event.preventDefault(); // Empêcher la saisie dans la page
        this.handleKeyPress(event.key);
      } else if (event.key === 'Enter' || event.key === 'Tab') {
        // Certains scanners envoient Enter ou Tab à la fin
        console.log('🔚 Touche de fin détectée:', event.key);
        if (this.scanBuffer.length > 0) {
          console.log('📋 Traitement du buffer avec touche de fin:', this.scanBuffer);
          this.processScannedBarcode(this.scanBuffer);
          this.scanBuffer = '';
        }
      }
    });

    // Écouter les événements paste (collage de texte)
    document.addEventListener('paste', (event) => {
      // Ignorer si focus dans un input de formulaire légitime
      const target = event.target as HTMLElement;
      if (target && target.tagName === 'INPUT' && target.id !== 'barcode-capture-input') {
        return;
      }

      const pasteData = event.clipboardData?.getData('text');
      console.log('📋 Événement paste détecté:', pasteData);
      
      if (pasteData && /^\d{8,13}$/.test(pasteData)) {
        console.log('✅ Code-barres détecté via paste:', pasteData);
        event.preventDefault();
        this.processScannedBarcode(pasteData);
      }
    });

    // Créer un input invisible pour capturer les données du scanner
    this.captureInput = document.createElement('input');
    this.captureInput.id = 'barcode-capture-input';
    this.captureInput.style.position = 'fixed';
    this.captureInput.style.top = '-1000px';
    this.captureInput.style.left = '-1000px';
    this.captureInput.style.opacity = '0';
    this.captureInput.style.pointerEvents = 'none';
    document.body.appendChild(this.captureInput);

    // Donner le focus à l'input invisible pour capturer les données
    this.captureInput.addEventListener('input', (event) => {
      const value = (event.target as HTMLInputElement).value;
      console.log('📝 Input capturé:', value);
      
      if (value && /^\d{8,13}$/.test(value)) {
        console.log('✅ Code-barres détecté via input:', value);
        this.processScannedBarcode(value);
        (event.target as HTMLInputElement).value = ''; // Réinitialiser
      }
    });

    // Garder le focus sur l'input invisible
    setInterval(() => {
      if (document.activeElement !== this.captureInput && 
          document.activeElement?.tagName !== 'INPUT' &&
          document.activeElement?.tagName !== 'TEXTAREA') {
        this.captureInput?.focus();
      }
    }, 500);

    // Écouter les changements de focus (alternative pour certains scanners)
    document.addEventListener('focusin', (event) => {
      const target = event.target as HTMLElement;
      
      // Si un élément qui n'est pas un input de formulaire reçoit le focus
      if (target && target.tagName !== 'INPUT' && target.tagName !== 'TEXTAREA') {
        setTimeout(() => {
          const text = (target as any).value || target.textContent || '';
          if (text && /^\d{8,13}$/.test(text)) {
            console.log('✅ Code-barres détecté via focus:', text);
            this.processScannedBarcode(text);
          }
        }, 100);
      }
    });

    // Détection spécifique pour le champ de test du scanner
    // Observer les événements input sur tous les éléments
    document.addEventListener('input', (event) => {
      const target = event.target as HTMLInputElement;
      const isDebugPanel = target?.closest('[data-debug-panel]') !== null;
      
      
      // Traiter seulement les codes-barres complets (8-13 chiffres)
      if (target && 
          target.id !== 'barcode-capture-input' && 
          target.value && 
          /^\d{8,13}$/.test(target.value)) {
        
        const timeSinceLastDetection = Date.now() - this.lastDetectionTime || 0;
        
        // Délai plus court pour les scans rapides (500ms au lieu de 2000ms)
        if (timeSinceLastDetection > 500) {
          this.lastDetectionTime = Date.now();
          this.processScannedBarcode(target.value);
          
          // Réinitialiser le champ après traitement
          setTimeout(() => {
            if (target && target.value === target.value) {
              target.value = '';
            }
          }, 200);
        }
      }
    });
  }

  /**
   * Gère la saisie de caractères pour détecter les codes-barres
   * Les lecteurs de codes-barres envoient les caractères très rapidement
   */
  private handleKeyPress(key: string): void {
    const currentTime = Date.now();
    const timeSinceLastKey = currentTime - this.lastKeyTime;
    
    console.log('⏱️ Délai depuis dernière touche:', timeSinceLastKey, 'ms');
    
    // Si plus de 100ms, nouvelle saisie
    if (timeSinceLastKey > 100 && this.scanBuffer.length > 0) {
      console.log('🔄 RESET - Nouvelle saisie détectée (délai > 100ms)');
      this.scanBuffer = '';
    }
    
    this.lastKeyTime = currentTime;
    this.scanBuffer += key;
    
    // Enregistrer dans l'historique
    this.captureHistory.push({key, timestamp: currentTime});
    if (this.captureHistory.length > 100) {
      this.captureHistory.shift(); // Garder seulement les 100 derniers
    }
    
    console.log('📊 ÉTAT BUFFER:', {
      caractèreAjouté: key,
      bufferComplet: this.scanBuffer,
      longueur: this.scanBuffer.length,
      timestamp: currentTime
    });

    // Réinitialiser le timeout
    if (this.scanTimeout) {
      clearTimeout(this.scanTimeout);
    }

    // Vérifier code-barres complet
    if (this.isCompleteBarcode(this.scanBuffer)) {
      console.log('✅ CODE-BARRES COMPLET DÉTECTÉ:', this.scanBuffer);
      this.processScannedBarcode(this.scanBuffer);
      this.scanBuffer = '';
      return;
    }

    // Timeout de 500ms (augmenté pour laisser le temps au scanner)
    this.scanTimeout = setTimeout(() => {
      console.log('⏰ TIMEOUT - Buffer final:', this.scanBuffer, 'Longueur:', this.scanBuffer.length);
      
      if (this.scanBuffer.length >= 8 && /^\d+$/.test(this.scanBuffer)) {
        console.log('🔧 Traitement forcé du buffer partiel');
        this.processScannedBarcode(this.scanBuffer);
      } else {
        console.log('❌ Buffer ignoré (trop court ou non numérique)');
      }
      
      this.scanBuffer = '';
    }, 500);
  }

  /**
   * Vérifie si le buffer contient un code-barres complet
   */
  private isCompleteBarcode(buffer: string): boolean {
    // EAN-13 (13 chiffres)
    if (buffer.length === 13 && /^\d{13}$/.test(buffer)) {
      console.log('✅ EAN-13 détecté:', buffer);
      return true;
    }

    // EAN-8 (8 chiffres)
    if (buffer.length === 8 && /^\d{8}$/.test(buffer)) {
      console.log('✅ EAN-8 détecté:', buffer);
      return true;
    }

    // UPC-A (12 chiffres)
    if (buffer.length === 12 && /^\d{12}$/.test(buffer)) {
      console.log('✅ UPC-A détecté:', buffer);
      return true;
    }

    // Si le buffer devient trop long, c'est probablement une saisie manuelle
    if (buffer.length > 13) {
      console.log('⚠️ Buffer trop long, probable saisie manuelle:', buffer);
      return false;
    }

    return false;
  }


  /**
   * Active le mode de traitement automatique pour les scanners problématiques
   * Traite automatiquement le buffer après 1 seconde d'inactivité
   */
  public enableAutoProcessMode(): void {
    console.log('🔄 Mode traitement automatique activé');
    
    // Traitement automatique toutes les 1 seconde si le buffer contient des chiffres
    const autoProcessInterval = setInterval(() => {
      if (this.scanBuffer.length >= 8 && /^\d+$/.test(this.scanBuffer)) {
        console.log('🤖 Traitement automatique du buffer:', this.scanBuffer);
        this.processScannedBarcode(this.scanBuffer);
        this.scanBuffer = '';
      }
    }, 1000);
    
    // Nettoyer l'intervalle après 30 secondes
    setTimeout(() => {
      clearInterval(autoProcessInterval);
      console.log('⏹️ Mode traitement automatique désactivé');
    }, 30000);
  }


  /**
   * Traite un code-barres scanné
   */
  private processScannedBarcode(barcode: string): void {
    // Vérifier si l'écoute est active
    if (!this.isListening) {
      this.isListening = true;
    }
    
    // Notifier tous les listeners
    this.listeners.forEach((listener, index) => {
      try {
        listener(barcode);
      } catch (error) {
        console.error(`Erreur dans le listener ${index + 1}:`, error);
      }
    });
  }

  /**
   * Ajoute un listener pour les codes-barres scannés
   */
  public addScanListener(listener: (barcode: string) => void): void {
    this.listeners.push(listener);
  }

  /**
   * Supprime un listener
   */
  public removeScanListener(listener: (barcode: string) => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * Démarre l'écoute des scans
   */
  public startListening(): void {
    if (!this.isListening) {
      this.isListening = true;
    }
  }

  /**
   * Arrête l'écoute des scans
   */
  public stopListening(): void {
    this.isListening = false;
    this.scanBuffer = '';
    if (this.scanTimeout) {
      clearTimeout(this.scanTimeout);
      this.scanTimeout = null;
    }
    
    // Supprimer l'input invisible
    if (this.captureInput && this.captureInput.parentNode) {
      this.captureInput.parentNode.removeChild(this.captureInput);
      this.captureInput = null;
    }
    
  }

  /**
   * Vérifie si l'écoute est active
   */
  public isActive(): boolean {
    return this.isListening;
  }


  /**
   * Obtient l'état actuel du buffer (pour debug)
   */
  public getBufferState(): { buffer: string; isListening: boolean } {
    return {
      buffer: this.scanBuffer,
      isListening: this.isListening
    };
  }

  /**
   * Obtient l'historique des captures pour diagnostic
   */
  public getCaptureHistory(): string[] {
    return this.captureHistory.map((item, index) => {
      const delay = index > 0 ? item.timestamp - this.captureHistory[index - 1].timestamp : 0;
      return `${index + 1}. "${item.key}" (+${delay}ms)`;
    });
  }
}

export default BarcodeScannerService;
