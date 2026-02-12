import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Repair, Client, Device, User } from '../types';

export interface ThermalReceiptData {
  repair: Repair;
  client?: Client;
  device?: Device;
  technician?: User;
  workshopInfo: {
    name: string;
    address?: string;
    phone?: string;
    email?: string;
    siret?: string;
    vatNumber?: string;
  };
}

export type ThermalReceiptFormat = '58mm' | '80mm';

export interface ThermalReceiptOptions {
  format: ThermalReceiptFormat;
  showConditions?: boolean;
  showServices?: boolean;
  showParts?: boolean;
  depositValidated?: boolean; // Indique si l'acompte a été validé
}

class ThermalPrintService {
  /**
   * Génère le HTML pour un reçu thermique
   */
  generateReceiptHTML(data: ThermalReceiptData, options: ThermalReceiptOptions): string {
    const { repair, client, device, technician, workshopInfo } = data;
    const { format: receiptFormat, showConditions = true, showServices = true, showParts = true, depositValidated = false } = options;

    // Configuration selon le format
    const config = this.getFormatConfig(receiptFormat);
    
    // Formatage des dates
    const createdDate = format(new Date(repair.createdAt), 'dd/MM/yyyy HH:mm', { locale: fr });
    const dueDate = format(new Date(repair.dueDate), 'dd/MM/yyyy', { locale: fr });
    
    // Numéro de réparation
    const repairNumber = repair.repairNumber || `REP-${repair.id.slice(0, 8)}`;
    
    // Services et pièces
    const servicesList = showServices && repair.services?.length > 0 
      ? repair.services.map(service => 
          `- ${this.truncateText(`Service (x${service.quantity})`, config.maxLineLength - 10)} ${service.price.toFixed(2)} €`
        ).join('\n')
      : '';
    
    const partsList = showParts && repair.parts?.length > 0 
      ? repair.parts.map(part => 
          `- ${this.truncateText(`Pièce (x${part.quantity})`, config.maxLineLength - 10)} ${part.price.toFixed(2)} €`
        ).join('\n')
      : '';

    // Conditions
    const conditions = showConditions ? [
      'CONDITIONS:',
      '- Devis valable 30 jours',
      '- Garantie pièces et main d\'œuvre',
      '- Appareil non récupéré après',
      '  6 mois = abandonné'
    ].join('\n') : '';

    // HTML du reçu
    const html = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Reçu Réparation ${repairNumber}</title>
    <style>
        ${this.getThermalCSS(config)}
    </style>
</head>
<body>
    <div class="thermal-receipt ${receiptFormat}">
        <div class="header">
            <div class="workshop-name">${workshopInfo.name}</div>
            ${workshopInfo.address ? `<div class="workshop-address">${workshopInfo.address}</div>` : ''}
            <div class="workshop-contact">
                ${workshopInfo.phone ? `Tel: ${workshopInfo.phone}` : ''}
                ${workshopInfo.phone && workshopInfo.email ? ' | ' : ''}
                ${workshopInfo.email || ''}
                ${workshopInfo.siret ? `<br>SIRET: ${workshopInfo.siret}` : ''}
                ${workshopInfo.vatNumber ? ` | TVA: ${workshopInfo.vatNumber}` : ''}
            </div>
        </div>
        
        <div class="separator">================================</div>
        
        <div class="title">${repair.source === 'sav' || repair.source === 'kanban' ? 'REÇU DE RÉPARATION' : 'REÇU DE VENTE'}</div>
        
        <div class="repair-info">
            <div>N° ${repairNumber}</div>
            <div>Date: ${createdDate}</div>
        </div>
        
        <div class="section">
            <div class="section-title">CLIENT</div>
            <div class="section-content">
                ${client ? `
                    <div>${client.firstName} ${client.lastName}</div>
                    <div>Tel: ${client.phone || 'N/A'}</div>
                    <div>Email: ${client.email}</div>
                ` : `
                    <div>Client anonyme</div>
                `}
            </div>
        </div>
        
        ${device ? `
        <div class="section">
            <div class="section-title">APPAREIL</div>
            <div class="section-content">
                <div>${device.brand} ${device.model}</div>
                <div>Type: ${device.type}</div>
                ${device.serialNumber ? `<div>S/N: ${device.serialNumber}</div>` : ''}
            </div>
        </div>
        ` : ''}
        
        <div class="section">
            <div class="section-title">${repair.source === 'sav' || repair.source === 'kanban' ? 'RÉPARATION' : 'VENTE'}</div>
            <div class="section-content">
                <div>Description: ${this.truncateText(repair.description, config.maxLineLength - 12)}</div>
                ${repair.source === 'sav' || repair.source === 'kanban' ? `<div>Échéance: ${dueDate}</div>` : ''}
                ${repair.issue ? `<div>Problème: ${this.truncateText(repair.issue, config.maxLineLength - 9)}</div>` : ''}
            </div>
        </div>
        
        ${servicesList ? `
        <div class="section">
            <div class="section-title">SERVICES</div>
            <div class="section-content">
                <pre>${servicesList}</pre>
            </div>
        </div>
        ` : ''}
        
        ${partsList ? `
        <div class="section">
            <div class="section-title">${repair.source === 'sav' || repair.source === 'kanban' ? 'PIÈCES' : 'ARTICLES'}</div>
            <div class="section-content">
                <pre>${partsList}</pre>
            </div>
        </div>
        ` : ''}
        
        <div class="section">
            <div class="section-title">TOTAL</div>
            <div class="section-content">
                <div class="total">TOTAL TTC: ${repair.totalPrice.toFixed(2)} €</div>
                ${repair.deposit && repair.deposit > 0 ? `
                    <div style="margin-top: 8px; padding-top: 8px; border-top: 1px dashed #000;">
                        <div style="margin-bottom: 4px;">
                            Acompte payé: ${repair.deposit.toFixed(2)} € 
                            ${depositValidated 
                                ? '<span style="color: #10b981; font-weight: bold;">✓ PAYÉ</span>' 
                                : '<span style="color: #f59e0b; font-weight: bold;">⏳ EN ATTENTE</span>'}
                        </div>
                        <div style="font-weight: bold; color: #0066cc;">Reste à payer: ${(repair.totalPrice - repair.deposit).toFixed(2)} €</div>
                    </div>
                ` : ''}
                <div class="payment-status ${repair.isPaid ? 'paid' : 'unpaid'}">
                    ${repair.isPaid ? 'PAYÉ' : 'NON PAYÉ'}
                </div>
            </div>
        </div>
        
        ${conditions ? `
        <div class="section">
            <div class="section-content">
                <pre>${conditions}</pre>
            </div>
        </div>
        ` : ''}
        
        <div class="separator">================================</div>
        
        <div class="footer">
            <div>Merci de votre confiance!</div>
            <div class="print-date">Imprimé le ${format(new Date(), 'dd/MM/yyyy à HH:mm', { locale: fr })}</div>
        </div>
    </div>
</body>
</html>`;

    return html;
  }

  /**
   * Ouvre le reçu dans une nouvelle fenêtre et lance l'impression
   */
  printReceipt(data: ThermalReceiptData, options: ThermalReceiptOptions): void {
    const html = this.generateReceiptHTML(data, options);
    
    const printWindow = window.open('', '_blank', 'width=400,height=600');
    if (printWindow) {
      printWindow.document.write(html);
      printWindow.document.close();
      
      // Attendre que le contenu soit chargé puis lancer l'impression
      printWindow.onload = () => {
        printWindow.focus();
        printWindow.print();
        
        // Fermer la fenêtre après impression (avec un délai pour permettre l'impression)
        setTimeout(() => {
          printWindow.close();
        }, 1000);
      };
    }
  }

  /**
   * Configuration selon le format
   */
  private getFormatConfig(format: ThermalReceiptFormat) {
    switch (format) {
      case '58mm':
        return {
          width: '220px',
          fontSize: '10px',
          maxLineLength: 24,
          margin: '3mm'
        };
      case '80mm':
        return {
          width: '302px',
          fontSize: '12px',
          maxLineLength: 32,
          margin: '5mm'
        };
      default:
        return {
          width: '302px',
          fontSize: '12px',
          maxLineLength: 32,
          margin: '5mm'
        };
    }
  }

  /**
   * CSS optimisé pour l'impression thermique
   */
  private getThermalCSS(config: any): string {
    return `
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
      
      body {
        font-family: 'Courier New', monospace;
        font-size: ${config.fontSize};
        line-height: 1.2;
        color: black;
        background: white;
        margin: 0;
        padding: 0;
      }
      
      .thermal-receipt {
        width: ${config.width};
        margin: 0 auto;
        padding: ${config.margin};
        background: white;
        color: black;
      }
      
      .header {
        text-align: center;
        margin-bottom: 8px;
      }
      
      .workshop-name {
        font-weight: bold;
        font-size: ${parseInt(config.fontSize) + 2}px;
        margin-bottom: 4px;
      }
      
      .workshop-address {
        font-size: ${parseInt(config.fontSize) - 1}px;
        margin-bottom: 2px;
      }
      
      .workshop-contact {
        font-size: ${parseInt(config.fontSize) - 1}px;
      }
      
      .separator {
        text-align: center;
        margin: 6px 0;
        font-weight: bold;
      }
      
      .title {
        text-align: center;
        font-weight: bold;
        font-size: ${parseInt(config.fontSize) + 1}px;
        margin: 8px 0;
      }
      
      .repair-info {
        margin: 6px 0;
        font-weight: bold;
      }
      
      .section {
        margin: 6px 0;
      }
      
      .section-title {
        font-weight: bold;
        text-align: center;
        margin: 4px 0;
        border-top: 1px solid black;
        border-bottom: 1px solid black;
        padding: 2px 0;
      }
      
      .section-content {
        margin: 4px 0;
      }
      
      .section-content div {
        margin: 2px 0;
      }
      
      .total {
        font-weight: bold;
        font-size: ${parseInt(config.fontSize) + 1}px;
        text-align: center;
        margin: 4px 0;
      }
      
      .payment-status {
        text-align: center;
        font-weight: bold;
        margin: 4px 0;
      }
      
      .payment-status.paid {
        color: #00aa00;
      }
      
      .payment-status.unpaid {
        color: #aa0000;
      }
      
      .footer {
        text-align: center;
        margin-top: 8px;
      }
      
      .print-date {
        font-size: ${parseInt(config.fontSize) - 2}px;
        margin-top: 4px;
      }
      
      pre {
        font-family: 'Courier New', monospace;
        white-space: pre-wrap;
        word-wrap: break-word;
        margin: 0;
        padding: 0;
      }
      
      @media print {
        body {
          margin: 0;
          padding: 0;
        }
        
        .thermal-receipt {
          width: 100% !important;
          max-width: none !important;
          margin: 0 !important;
          padding: 2mm !important;
        }
        
        @page {
          margin: 0;
          size: auto;
        }
      }
    `;
  }

  /**
   * Tronque le texte pour s'adapter à la largeur
   */
  private truncateText(text: string, maxLength: number): string {
    if (text.length <= maxLength) {
      return text;
    }
    return text.substring(0, maxLength - 3) + '...';
  }
}

export const thermalPrintService = new ThermalPrintService();
export default thermalPrintService;
