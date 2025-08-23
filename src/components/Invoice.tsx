import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Divider,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
} from '@mui/material';
import {
  Print as PrintIcon,
  Close as CloseIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Sale, Client } from '../types';
import { useAppStore } from '../store';

interface InvoiceProps {
  sale: Sale;
  client?: Client;
  open: boolean;
  onClose: () => void;
}

const Invoice: React.FC<InvoiceProps> = ({ sale, client, open, onClose }) => {
  const { systemSettings, loadSystemSettings } = useAppStore();

  // Charger les paramètres système si nécessaire
  useEffect(() => {
    if (systemSettings.length === 0) {
      loadSystemSettings();
    }
  }, [systemSettings.length, loadSystemSettings]);

  // Fonction utilitaire pour normaliser les données de vente
  const normalizeSaleData = (saleData: Sale): Sale => {
    // S'assurer que items est toujours un tableau
    let normalizedItems = saleData.items;
    
    // Si items n'est pas un tableau, essayer de le convertir
    if (!Array.isArray(normalizedItems)) {
      try {
        // Si c'est une chaîne JSON, la parser
        if (typeof normalizedItems === 'string') {
          normalizedItems = JSON.parse(normalizedItems);
        }
        // Si c'est un objet, essayer de l'extraire
        else if (typeof normalizedItems === 'object' && normalizedItems !== null) {
          // Vérifier si c'est un objet avec des propriétés d'articles
          const itemsObj = normalizedItems as any;
          if (itemsObj && typeof itemsObj === 'object' && 'items' in itemsObj) {
            normalizedItems = itemsObj.items;
          } else {
            // Essayer de convertir l'objet en tableau
            normalizedItems = Object.values(itemsObj);
          }
        }
        // Si ce n'est toujours pas un tableau, créer un tableau vide
        if (!Array.isArray(normalizedItems)) {
          console.warn('Impossible de normaliser les items de vente:', saleData.items);
          normalizedItems = [];
        }
      } catch (error) {
        console.error('Erreur lors de la normalisation des items de vente:', error);
        normalizedItems = [];
      }
    }

    return {
      ...saleData,
      items: normalizedItems
    };
  };

  // Normaliser les données de vente
  const normalizedSale = normalizeSaleData(sale);

  // Extraire les paramètres de l'atelier depuis les paramètres système
  const getSettingValue = (key: string, defaultValue: string = '') => {
    const setting = systemSettings.find(s => s.key === key);
    return setting ? setting.value : defaultValue;
  };

  const workshopSettings = {
    name: getSettingValue('workshop_name', 'Atelier de réparation'),
    address: getSettingValue('workshop_address', '123 Rue de la Paix, 75001 Paris'),
    phone: getSettingValue('workshop_phone', '01 23 45 67 89'),
    email: getSettingValue('workshop_email', 'contact@atelier.fr'),
    vatRate: getSettingValue('vat_rate', '20'),
    currency: getSettingValue('currency', 'EUR')
  };

  const handlePrint = () => {
    const printContent = document.getElementById('invoice-content');
    if (printContent) {
      const printWindow = window.open('', '_blank');
      if (printWindow) {
        printWindow.document.write(`
          <!DOCTYPE html>
          <html>
            <head>
              <title>Facture ${sale.id.slice(0, 8)}</title>
              <style>
                * { 
                  margin: 0; 
                  padding: 0; 
                  box-sizing: border-box; 
                }
                
                body { 
                  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
                  margin: 0;
                  padding: 24px;
                  background: white;
                  color: #333;
                  line-height: 1.6;
                  -webkit-print-color-adjust: exact;
                  print-color-adjust: exact;
                }
                
                .invoice-container {
                  max-width: 800px;
                  margin: 0 auto;
                  background: white;
                }
                
                .header {
                  text-align: center;
                  margin-bottom: 40px;
                  padding-bottom: 20px;
                  border-bottom: 1px solid #eee;
                }
                
                .header h1 {
                  font-size: 24px;
                  font-weight: 600;
                  margin: 0 0 8px 0;
                  color: #333;
                }
                
                .header .subtitle {
                  font-size: 14px;
                  color: #666;
                  margin-bottom: 16px;
                }
                
                .header .contact-info {
                  font-size: 12px;
                  color: #666;
                  line-height: 1.8;
                }
                
                .header .contact-info div {
                  margin-bottom: 4px;
                }
                
                .invoice-details {
                  display: flex;
                  justify-content: space-between;
                  margin-bottom: 40px;
                  gap: 40px;
                }
                
                .client-section, .invoice-section {
                  flex: 1;
                }
                
                .section-title {
                  font-size: 16px;
                  font-weight: 600;
                  color: #333;
                  margin-bottom: 12px;
                  padding-bottom: 4px;
                  border-bottom: 1px solid #eee;
                }
                
                .client-info, .invoice-info {
                  font-size: 14px;
                  line-height: 1.8;
                  color: #666;
                }
                
                .client-info div, .invoice-info div {
                  margin-bottom: 4px;
                }
                
                .client-name {
                  font-weight: 600;
                  font-size: 14px;
                  margin-bottom: 8px;
                  color: #333;
                }
                
                .invoice-number {
                  font-size: 18px;
                  font-weight: 600;
                  color: #1976d2;
                  margin-bottom: 8px;
                }
                
                table {
                  width: 100%;
                  border-collapse: collapse;
                  margin: 20px 0;
                }
                
                th {
                  background: #f8f9fa !important;
                  padding: 12px 8px;
                  text-align: left;
                  font-weight: 600;
                  font-size: 14px;
                  color: #333;
                  border-bottom: 1px solid #eee;
                }
                
                td {
                  padding: 12px 8px;
                  border-bottom: 1px solid #f1f1f1;
                  font-size: 14px;
                }
                
                .item-name {
                  font-weight: 600;
                  color: #333;
                }
                
                .item-type {
                  color: #666;
                  font-size: 13px;
                }
                
                .price {
                  font-weight: 600;
                  color: #333;
                }
                
                .totals-section {
                  margin: 30px 0;
                  text-align: right;
                }
                
                .total-row {
                  display: flex;
                  justify-content: space-between;
                  align-items: center;
                  margin-bottom: 8px;
                  max-width: 300px;
                  margin-left: auto;
                }
                
                .total-row:last-child {
                  margin-bottom: 0;
                  padding-top: 12px;
                  border-top: 1px solid #eee;
                  font-size: 16px;
                  font-weight: 600;
                  color: #1976d2;
                }
                
                .conditions {
                  margin: 30px 0;
                  padding: 20px;
                  background: #f8f9fa !important;
                  border-radius: 4px;
                }
                
                .conditions h3 {
                  color: #333;
                  font-size: 14px;
                  font-weight: 600;
                  margin-bottom: 12px;
                }
                
                .conditions ul {
                  list-style: none;
                  padding: 0;
                  margin: 0;
                }
                
                .conditions li {
                  color: #666;
                  font-size: 13px;
                  margin-bottom: 6px;
                  padding-left: 16px;
                  position: relative;
                }
                
                .conditions li:before {
                  content: "•";
                  position: absolute;
                  left: 0;
                  color: #666;
                }
                
                .footer {
                  margin-top: 40px;
                  padding-top: 20px;
                  border-top: 1px solid #eee;
                  text-align: center;
                }
                
                .footer h3 {
                  font-size: 16px;
                  font-weight: 600;
                  margin-bottom: 8px;
                  color: #333;
                }
                
                .footer p {
                  font-size: 12px;
                  color: #666;
                  margin-bottom: 4px;
                }
                
                .footer .thank-you {
                  font-size: 14px;
                  font-weight: 600;
                  color: #1976d2;
                  margin-top: 12px;
                }
                
                @media print {
                  body { 
                    margin: 0; 
                    padding: 24px;
                    background: white !important;
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                  }
                  .invoice-container { 
                    margin: 0 auto;
                    background: white !important;
                  }
                  .header { 
                    border-bottom: 1px solid #eee !important;
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                  }
                  .section-title {
                    border-bottom: 1px solid #eee !important;
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                  }
                  th { 
                    background: #f8f9fa !important; 
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                  }
                  .conditions { 
                    background: #f8f9fa !important; 
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                  }
                  .footer { 
                    border-top: 1px solid #eee !important;
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                  }
                  .total-row:last-child {
                    border-top: 1px solid #eee !important;
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                  }
                }
              </style>
            </head>
            <body>
              <div class="invoice-container">
                <!-- En-tête -->
                <div class="header">
                  <h1>${workshopSettings.name}</h1>
                  <div class="contact-info">
                    <div>Tél: ${workshopSettings.phone} • Email: ${workshopSettings.email}</div>
                    <div>SIRET: 123 456 789 00012 • TVA: FR12345678901</div>
                  </div>
                </div>

                <!-- Détails client et facture -->
                <div class="invoice-details">
                  <div class="client-section">
                    <div class="section-title">FACTURÉ À</div>
                    <div class="client-info">
                      ${client ? `
                        <div class="client-name">${client.firstName} ${client.lastName}</div>
                        <div>${client.email}</div>
                        <div>${client.phone}</div>
                        ${client.address ? `<div>${client.address}</div>` : ''}
                      ` : '<div>Client anonyme</div>'}
                    </div>
                  </div>
                  
                  <div class="invoice-section">
                    <div class="section-title">DÉTAILS DE LA FACTURE</div>
                    <div class="invoice-info">
                      <div class="invoice-number">#${sale.id.slice(0, 8)}</div>
                      <div><strong>Date :</strong> ${format(new Date(sale.createdAt), 'dd/MM/yyyy', { locale: fr })}</div>
                      <div><strong>Statut :</strong> ${getStatusLabel(sale.status)}</div>
                      <div><strong>Paiement :</strong> ${getPaymentMethodLabel(sale.paymentMethod)}</div>
                    </div>
                  </div>
                </div>

                <!-- Tableau des articles -->
                <table>
                  <thead>
                    <tr>
                      <th>Article</th>
                      <th>Type</th>
                      <th style="text-align: right;">Prix unitaire</th>
                      <th style="text-align: center;">Quantité</th>
                      <th style="text-align: right;">Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${Array.isArray(normalizedSale.items) ? normalizedSale.items.map(item => `
                      <tr>
                        <td><span class="item-name">${item.name}</span></td>
                        <td><span class="item-type">${item.type === 'product' ? 'Produit' : item.type === 'service' ? 'Service' : 'Pièce'}</span></td>
                        <td style="text-align: right;"><span class="price">${item.unitPrice.toLocaleString('fr-FR')} €</span></td>
                        <td style="text-align: center;">${item.quantity}</td>
                        <td style="text-align: right;"><span class="price">${item.totalPrice.toLocaleString('fr-FR')} €</span></td>
                      </tr>
                    `).join('') : '<tr><td colspan="5" style="text-align: center; color: #666; font-style: italic;">Aucun article disponible</td></tr>'}
                  </tbody>
                </table>

                <!-- Totaux -->
                <div class="totals-section">
                  <div class="total-row">
                    <span>Sous-total HT :</span>
                    <span>${sale.subtotal.toLocaleString('fr-FR')} €</span>
                  </div>
                  <div class="total-row">
                    <span>TVA (${workshopSettings.vatRate}%) :</span>
                    <span>${sale.tax.toLocaleString('fr-FR')} €</span>
                  </div>
                  <div class="total-row">
                    <span>TOTAL TTC :</span>
                    <span>${sale.total.toLocaleString('fr-FR')} €</span>
                  </div>
                </div>

                <!-- Conditions de paiement -->
                <div class="conditions">
                  <h3>CONDITIONS DE PAIEMENT</h3>
                  <ul>
                    <li>Paiement immédiat par ${getPaymentMethodLabel(sale.paymentMethod).toLowerCase()}</li>
                    <li>Facture valable 30 jours à compter de la date d'émission</li>
                    <li>Aucun escompte en cas de paiement anticipé</li>
                    <li>Pour toute question, contactez-nous au ${workshopSettings.phone} ou par email à ${workshopSettings.email}</li>
                  </ul>
                </div>

                <!-- Pied de page -->
                <div class="footer">
                  <h3>${workshopSettings.name}</h3>
                  <p>Tél: ${workshopSettings.phone} • Email: ${workshopSettings.email}</p>
                  <p>SIRET: 123 456 789 00012 • TVA: FR12345678901</p>
                  <div class="thank-you">Merci de votre confiance !</div>
                </div>
              </div>
            </body>
          </html>
        `);
        printWindow.document.close();
        printWindow.focus();
        printWindow.print();
        printWindow.close();
      }
    }
  };

  const handleDownload = () => {
      const htmlContent = `
        <!DOCTYPE html>
        <html>
          <head>
            <title>Facture ${sale.id.slice(0, 8)}</title>
            <style>
            * { 
              margin: 0; 
              padding: 0; 
              box-sizing: border-box; 
            }
            
            body { 
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
              margin: 0;
              padding: 24px;
              background: white;
              color: #333;
              line-height: 1.6;
              -webkit-print-color-adjust: exact;
              print-color-adjust: exact;
            }
            
            .invoice-container {
              max-width: 800px;
              margin: 0 auto;
              background: white;
            }
            
            .header {
              text-align: center;
              margin-bottom: 40px;
              padding-bottom: 20px;
              border-bottom: 1px solid #eee;
            }
            
            .header h1 {
              font-size: 24px;
              font-weight: 600;
              margin: 0 0 8px 0;
              color: #333;
            }
            
            .header .subtitle {
              font-size: 14px;
              color: #666;
              margin-bottom: 16px;
            }
            
            .header .contact-info {
              font-size: 12px;
              color: #666;
              line-height: 1.8;
            }
            
            .header .contact-info div {
              margin-bottom: 4px;
            }
            
            .invoice-details {
              display: flex;
              justify-content: space-between;
              margin-bottom: 40px;
              gap: 40px;
            }
            
            .client-section, .invoice-section {
              flex: 1;
            }
            
            .section-title {
              font-size: 16px;
              font-weight: 600;
              color: #333;
              margin-bottom: 12px;
              padding-bottom: 4px;
              border-bottom: 1px solid #eee;
            }
            
            .client-info, .invoice-info {
              font-size: 14px;
              line-height: 1.8;
              color: #666;
            }
            
            .client-info div, .invoice-info div {
              margin-bottom: 4px;
            }
            
            .client-name {
              font-weight: 600;
              font-size: 14px;
              margin-bottom: 8px;
              color: #333;
            }
            
            .invoice-number {
              font-size: 18px;
              font-weight: 600;
              color: #1976d2;
              margin-bottom: 8px;
            }
            
            table {
              width: 100%;
              border-collapse: collapse;
              margin: 20px 0;
            }
            
            th {
              background: #f8f9fa !important;
              padding: 12px 8px;
              text-align: left;
              font-weight: 600;
              font-size: 14px;
              color: #333;
              border-bottom: 1px solid #eee;
            }
            
            td {
              padding: 12px 8px;
              border-bottom: 1px solid #f1f1f1;
              font-size: 14px;
            }
            
            .item-name {
              font-weight: 600;
              color: #333;
            }
            
            .item-type {
              color: #666;
              font-size: 13px;
            }
            
            .price {
              font-weight: 600;
              color: #333;
            }
            
            .totals-section {
              margin: 30px 0;
              text-align: right;
            }
            
            .total-row {
              display: flex;
              justify-content: space-between;
              align-items: center;
              margin-bottom: 8px;
              max-width: 300px;
              margin-left: auto;
            }
            
            .total-row:last-child {
              margin-bottom: 0;
              padding-top: 12px;
              border-top: 1px solid #eee;
              font-size: 16px;
              font-weight: 600;
              color: #1976d2;
            }
            
            .conditions {
              margin: 30px 0;
              padding: 20px;
              background: #f8f9fa !important;
              border-radius: 4px;
            }
            
            .conditions h3 {
              color: #333;
              font-size: 14px;
              font-weight: 600;
              margin-bottom: 12px;
            }
            
            .conditions ul {
              list-style: none;
              padding: 0;
              margin: 0;
            }
            
            .conditions li {
              color: #666;
              font-size: 13px;
              margin-bottom: 6px;
              padding-left: 16px;
              position: relative;
            }
            
            .conditions li:before {
              content: "•";
              position: absolute;
              left: 0;
              color: #666;
            }
            
            .footer {
              margin-top: 40px;
              padding-top: 20px;
              border-top: 1px solid #eee;
              text-align: center;
            }
            
            .footer h3 {
              font-size: 16px;
              font-weight: 600;
              margin-bottom: 8px;
              color: #333;
            }
            
            .footer p {
              font-size: 12px;
              color: #666;
              margin-bottom: 4px;
            }
            
            .footer .thank-you {
              font-size: 14px;
              font-weight: 600;
              color: #1976d2;
              margin-top: 12px;
            }
            
            @media print {
              body { 
                margin: 0; 
                padding: 24px;
                background: white !important;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
              }
              .invoice-container { 
                margin: 0 auto;
                background: white !important;
              }
              .header { 
                border-bottom: 1px solid #eee !important;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
              }
              .section-title {
                border-bottom: 1px solid #eee !important;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
              }
              th { 
                background: #f8f9fa !important; 
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
              }
              .conditions { 
                background: #f8f9fa !important; 
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
              }
              .footer { 
                border-top: 1px solid #eee !important;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
              }
              .total-row:last-child {
                border-top: 1px solid #eee !important;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
              }
            }
            </style>
          </head>
          <body>
          <div class="invoice-container">
            <!-- En-tête -->
            <div class="header">
              <h1>${workshopSettings.name}</h1>
              <div class="contact-info">
                <div>Tél: ${workshopSettings.phone} • Email: ${workshopSettings.email}</div>
                <div>SIRET: 123 456 789 00012 • TVA: FR12345678901</div>
              </div>
            </div>

            <!-- Détails client et facture -->
            <div class="invoice-details">
              <div class="client-section">
                <div class="section-title">FACTURÉ À</div>
                <div class="client-info">
                  ${client ? `
                    <div class="client-name">${client.firstName} ${client.lastName}</div>
                    <div>${client.email}</div>
                    <div>${client.phone}</div>
                    ${client.address ? `<div>${client.address}</div>` : ''}
                  ` : '<div>Client anonyme</div>'}
                </div>
              </div>
              
              <div class="invoice-section">
                <div class="section-title">DÉTAILS DE LA FACTURE</div>
                <div class="invoice-info">
                  <div class="invoice-number">#${sale.id.slice(0, 8)}</div>
                  <div><strong>Date :</strong> ${format(new Date(sale.createdAt), 'dd/MM/yyyy', { locale: fr })}</div>
                  <div><strong>Statut :</strong> ${getStatusLabel(sale.status)}</div>
                  <div><strong>Paiement :</strong> ${getPaymentMethodLabel(sale.paymentMethod)}</div>
                </div>
              </div>
            </div>

            <!-- Tableau des articles -->
            <table>
              <thead>
                <tr>
                  <th>Article</th>
                  <th>Type</th>
                  <th style="text-align: right;">Prix unitaire</th>
                  <th style="text-align: center;">Quantité</th>
                  <th style="text-align: right;">Total</th>
                </tr>
              </thead>
              <tbody>
                ${Array.isArray(normalizedSale.items) ? normalizedSale.items.map(item => `
                  <tr>
                    <td><span class="item-name">${item.name}</span></td>
                    <td><span class="item-type">${item.type === 'product' ? 'Produit' : item.type === 'service' ? 'Service' : 'Pièce'}</span></td>
                    <td style="text-align: right;"><span class="price">${item.unitPrice.toLocaleString('fr-FR')} €</span></td>
                    <td style="text-align: center;">${item.quantity}</td>
                    <td style="text-align: right;"><span class="price">${item.totalPrice.toLocaleString('fr-FR')} €</span></td>
                  </tr>
                `).join('') : '<tr><td colspan="5" style="text-align: center; color: #666; font-style: italic;">Aucun article disponible</td></tr>'}
              </tbody>
            </table>

            <!-- Totaux -->
            <div class="totals-section">
              <div class="total-row">
                <span>Sous-total HT :</span>
                <span>${sale.subtotal.toLocaleString('fr-FR')} €</span>
              </div>
              <div class="total-row">
                <span>TVA (${workshopSettings.vatRate}%) :</span>
                <span>${sale.tax.toLocaleString('fr-FR')} €</span>
              </div>
              <div class="total-row">
                <span>TOTAL TTC :</span>
                <span>${sale.total.toLocaleString('fr-FR')} €</span>
              </div>
            </div>

            <!-- Conditions de paiement -->
            <div class="conditions">
              <h3>CONDITIONS DE PAIEMENT</h3>
              <ul>
                <li>Paiement immédiat par ${getPaymentMethodLabel(sale.paymentMethod).toLowerCase()}</li>
                <li>Facture valable 30 jours à compter de la date d'émission</li>
                <li>Aucun escompte en cas de paiement anticipé</li>
                <li>Pour toute question, contactez-nous au ${workshopSettings.phone} ou par email à ${workshopSettings.email}</li>
              </ul>
            </div>

            <!-- Pied de page -->
            <div class="footer">
              <h3>${workshopSettings.name}</h3>
              <p>Tél: ${workshopSettings.phone} • Email: ${workshopSettings.email}</p>
              <p>SIRET: 123 456 789 00012 • TVA: FR12345678901</p>
              <div class="thank-you">Merci de votre confiance !</div>
            </div>
          </div>
          </body>
        </html>
      `;
      
      const blob = new Blob([htmlContent], { type: 'text/html' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `facture-${sale.id.slice(0, 8)}.html`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
  };

  const getPaymentMethodLabel = (method: string) => {
    const labels = {
      cash: 'Espèces',
      card: 'Carte bancaire',
      transfer: 'Virement bancaire',
    };
    return labels[method as keyof typeof labels] || method;
  };

  const getStatusLabel = (status: string) => {
    const labels = {
      pending: 'En attente',
      completed: 'Payée',
              cancelled: 'Restitué',
    };
    return labels[status as keyof typeof labels] || status;
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6">Facture #{sale.id.slice(0, 8)}</Typography>
          <Box>
            <IconButton onClick={handleDownload} title="Télécharger">
              <DownloadIcon />
            </IconButton>
            <IconButton onClick={handlePrint} title="Imprimer">
              <PrintIcon />
            </IconButton>
            <IconButton onClick={onClose} title="Fermer">
              <CloseIcon />
            </IconButton>
          </Box>
        </Box>
      </DialogTitle>
      <DialogContent>
        <Box 
          id="invoice-content" 
          sx={{ 
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
            backgroundColor: 'white',
            p: 3
          }}
        >
          <Box sx={{ maxWidth: '800px', mx: 'auto' }}>
            
            {/* En-tête simple */}
            <Box sx={{ 
              textAlign: 'center', 
              mb: 5, 
              pb: 2.5, 
              borderBottom: '1px solid #eee' 
            }}>
              <Typography variant="h4" sx={{ 
                fontWeight: 600, 
                mb: 1, 
                color: '#333',
                fontSize: '24px'
              }}>
                {workshopSettings.name}
              </Typography>
              <Box sx={{ fontSize: '12px', color: '#666', lineHeight: 1.8 }}>
                <Typography sx={{ mb: 0.5 }}>
                  Tél: {workshopSettings.phone} • Email: {workshopSettings.email}
              </Typography>
                <Typography>
                SIRET: 123 456 789 00012 • TVA: FR12345678901
              </Typography>
              </Box>
            </Box>
            
            {/* Détails client et facture */}
            <Box sx={{ 
              display: 'flex', 
              justifyContent: 'space-between', 
              mb: 5, 
              gap: 5 
            }}>
              
              {/* Informations client */}
              <Box sx={{ flex: 1 }}>
                <Typography variant="h6" sx={{ 
                  fontWeight: 600, 
                  color: '#333', 
                  mb: 1.5, 
                  pb: 0.5, 
                  borderBottom: '1px solid #eee',
                  fontSize: '16px'
                }}>
                  FACTURÉ À
                </Typography>
                {client ? (
                  <Box>
                    <Typography sx={{ 
                      fontWeight: 600, 
                      fontSize: '14px', 
                      mb: 1, 
                      color: '#333' 
                    }}>
                      {client.firstName} {client.lastName}
                    </Typography>
                    <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                      {client.email}
                    </Typography>
                    <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                      {client.phone}
                    </Typography>
                    {client.address && (
                      <Typography sx={{ fontSize: '14px', color: '#666' }}>
                        {client.address}
                      </Typography>
                    )}
                  </Box>
                ) : (
                  <Typography sx={{ fontSize: '14px', color: '#666' }}>
                    Client anonyme
                  </Typography>
                )}
              </Box>
              
              {/* Détails de la facture */}
              <Box sx={{ flex: 1 }}>
                <Typography variant="h6" sx={{ 
                  fontWeight: 600, 
                  color: '#333', 
                  mb: 1.5, 
                  pb: 0.5, 
                  borderBottom: '1px solid #eee',
                  fontSize: '16px'
                }}>
                  DÉTAILS DE LA FACTURE
                </Typography>
                <Typography sx={{ 
                  fontSize: '18px', 
                  fontWeight: 600, 
                  color: '#1976d2', 
                  mb: 1 
                }}>
                  #{sale.id.slice(0, 8)}
                </Typography>
                <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                  <strong>Date :</strong> {format(new Date(sale.createdAt), 'dd/MM/yyyy', { locale: fr })}
                </Typography>
                <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                  <strong>Statut :</strong> {getStatusLabel(sale.status)}
                </Typography>
                <Typography sx={{ fontSize: '14px', color: '#666' }}>
                  <strong>Paiement :</strong> {getPaymentMethodLabel(sale.paymentMethod)}
                </Typography>
            </Box>
          </Box>

          {/* Tableau des articles */}
            <Box sx={{ mb: 5 }}>
              <Table>
                <TableHead>
                  <TableRow sx={{ backgroundColor: '#f8f9fa' }}>
                    <TableCell sx={{ 
                      fontWeight: 600, 
                      fontSize: '14px', 
                      color: '#333',
                      borderBottom: '1px solid #eee',
                      py: 1.5
                    }}>
                      Article
                    </TableCell>
                    <TableCell sx={{ 
                      fontWeight: 600, 
                      fontSize: '14px', 
                      color: '#333',
                      borderBottom: '1px solid #eee',
                      py: 1.5
                    }}>
                      Type
                    </TableCell>
                    <TableCell sx={{ 
                      fontWeight: 600, 
                      fontSize: '14px', 
                      color: '#333',
                      borderBottom: '1px solid #eee',
                      py: 1.5,
                      textAlign: 'right'
                    }}>
                      Prix unitaire
                    </TableCell>
                    <TableCell sx={{ 
                      fontWeight: 600, 
                      fontSize: '14px', 
                      color: '#333',
                      borderBottom: '1px solid #eee',
                      py: 1.5,
                      textAlign: 'center'
                    }}>
                      Quantité
                    </TableCell>
                    <TableCell sx={{ 
                      fontWeight: 600, 
                      fontSize: '14px', 
                      color: '#333',
                      borderBottom: '1px solid #eee',
                      py: 1.5,
                      textAlign: 'right'
                    }}>
                      Total
                    </TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {Array.isArray(normalizedSale.items) ? normalizedSale.items.map((item, index) => (
                    <TableRow key={index}>
                      <TableCell sx={{ 
                        borderBottom: '1px solid #f1f1f1', 
                        py: 1.5 
                      }}>
                        <Typography sx={{ 
                          fontWeight: 600, 
                          color: '#333',
                          fontSize: '14px'
                        }}>
                          {item.name}
                        </Typography>
                      </TableCell>
                      <TableCell sx={{ 
                        borderBottom: '1px solid #f1f1f1', 
                        py: 1.5 
                      }}>
                        <Typography sx={{ 
                          color: '#666', 
                          fontSize: '13px' 
                        }}>
                          {item.type === 'product' ? 'Produit' : 
                           item.type === 'service' ? 'Service' : 'Pièce'}
                        </Typography>
                      </TableCell>
                      <TableCell sx={{ 
                        borderBottom: '1px solid #f1f1f1', 
                        py: 1.5, 
                        textAlign: 'right' 
                      }}>
                        <Typography sx={{ 
                          fontWeight: 600, 
                          color: '#333',
                          fontSize: '14px'
                        }}>
                          {item.unitPrice.toLocaleString('fr-FR')} €
                        </Typography>
                      </TableCell>
                      <TableCell sx={{ 
                        borderBottom: '1px solid #f1f1f1', 
                        py: 1.5, 
                        textAlign: 'center' 
                      }}>
                        <Typography sx={{ fontSize: '14px' }}>
                          {item.quantity}
                        </Typography>
                      </TableCell>
                      <TableCell sx={{ 
                        borderBottom: '1px solid #f1f1f1', 
                        py: 1.5, 
                        textAlign: 'right' 
                      }}>
                        <Typography sx={{ 
                          fontWeight: 600, 
                          color: '#333',
                          fontSize: '14px'
                        }}>
                          {item.totalPrice.toLocaleString('fr-FR')} €
                        </Typography>
                      </TableCell>
                    </TableRow>
                  )) : (
                    <TableRow>
                      <TableCell colSpan={5} sx={{ 
                        textAlign: 'center', 
                        py: 3,
                        color: '#666',
                        fontStyle: 'italic'
                      }}>
                        Aucun article disponible dans cette vente
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
          </Box>

          {/* Totaux */}
            <Box sx={{ mb: 5, textAlign: 'right' }}>
              <Box sx={{ maxWidth: '300px', ml: 'auto' }}>
            <Box sx={{ 
              display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center', 
                  mb: 1 
                }}>
                  <Typography sx={{ fontWeight: 600, fontSize: '16px' }}>
                    Sous-total HT :
                  </Typography>
                  <Typography sx={{ fontWeight: 600, fontSize: '16px' }}>
                    {sale.subtotal.toLocaleString('fr-FR')} €
                  </Typography>
                </Box>
                <Box sx={{ 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center', 
                  mb: 1 
                }}>
                  <Typography sx={{ fontSize: '16px' }}>
                    TVA ({workshopSettings.vatRate}%) :
                  </Typography>
                  <Typography sx={{ fontSize: '16px' }}>
                    {sale.tax.toLocaleString('fr-FR')} €
                  </Typography>
                </Box>
                <Divider sx={{ my: 1.5, borderColor: '#eee' }} />
                <Box sx={{ 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center' 
                }}>
                  <Typography sx={{ 
                    fontWeight: 600, 
                    fontSize: '16px',
                    color: '#1976d2'
                  }}>
                    TOTAL TTC :
                  </Typography>
                  <Typography sx={{ 
                    fontWeight: 600, 
                    fontSize: '16px',
                    color: '#1976d2'
                  }}>
                    {sale.total.toLocaleString('fr-FR')} €
                  </Typography>
              </Box>
            </Box>
          </Box>

            {/* Conditions de paiement */}
            <Box sx={{ 
              mb: 5, 
              p: 2.5, 
              backgroundColor: '#f8f9fa', 
              borderRadius: 1 
            }}>
              <Typography variant="h6" sx={{ 
                fontWeight: 600, 
                mb: 1.5, 
                color: '#333',
                fontSize: '14px'
              }}>
                CONDITIONS DE PAIEMENT
              </Typography>
              <Box component="ul" sx={{ 
                listStyle: 'none', 
                p: 0, 
                m: 0 
              }}>
                <Box component="li" sx={{ 
                  color: '#666', 
                  fontSize: '13px', 
                  mb: 0.75, 
                  pl: 2, 
                  position: 'relative',
                  '&:before': {
                    content: '"•"',
                    position: 'absolute',
                    left: 0,
                    color: '#666'
                  }
                }}>
                  Paiement immédiat par {getPaymentMethodLabel(sale.paymentMethod).toLowerCase()}
                </Box>
                <Box component="li" sx={{ 
                  color: '#666', 
                  fontSize: '13px', 
                  mb: 0.75, 
                  pl: 2, 
                  position: 'relative',
                  '&:before': {
                    content: '"•"',
                    position: 'absolute',
                    left: 0,
                    color: '#666'
                  }
                }}>
                  Facture valable 30 jours à compter de la date d'émission
                </Box>
                <Box component="li" sx={{ 
                  color: '#666', 
                  fontSize: '13px', 
                  mb: 0.75, 
                  pl: 2, 
                  position: 'relative',
                  '&:before': {
                    content: '"•"',
                    position: 'absolute',
                    left: 0,
                    color: '#666'
                  }
                }}>
                  Aucun escompte en cas de paiement anticipé
                </Box>
                <Box component="li" sx={{ 
                  color: '#666', 
                  fontSize: '13px', 
                  pl: 2, 
                  position: 'relative',
                  '&:before': {
                    content: '"•"',
                    position: 'absolute',
                    left: 0,
                    color: '#666'
                  }
                }}>
                  Pour toute question, contactez-nous au {workshopSettings.phone} ou par email à {workshopSettings.email}
                </Box>
            </Box>
          </Box>

          {/* Pied de page */}
            <Box sx={{ 
              mt: 5, 
              pt: 2.5, 
              borderTop: '1px solid #eee', 
              textAlign: 'center' 
            }}>
              <Typography variant="h6" sx={{ 
                fontWeight: 600, 
                mb: 1,
                fontSize: '16px',
                color: '#333'
              }}>
                {workshopSettings.name}
            </Typography>
              <Typography sx={{ 
                fontSize: '12px', 
                color: '#666', 
                mb: 0.5 
              }}>
                Tél: {workshopSettings.phone} • Email: {workshopSettings.email}
            </Typography>
              <Typography sx={{ 
                fontSize: '12px', 
                color: '#666', 
                mb: 2 
              }}>
              SIRET: 123 456 789 00012 • TVA: FR12345678901
            </Typography>
              <Typography sx={{ 
                fontWeight: 600, 
                color: '#1976d2',
                fontSize: '14px'
              }}>
              Merci de votre confiance !
            </Typography>
          </Box>
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleDownload} startIcon={<DownloadIcon />}>
          Télécharger
        </Button>
        <Button onClick={handlePrint} variant="contained" startIcon={<PrintIcon />}>
          Imprimer
        </Button>
        <Button onClick={onClose}>Fermer</Button>
      </DialogActions>
    </Dialog>
  );
};

export default Invoice;
