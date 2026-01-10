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
  Chip,
  Grid,
} from '@mui/material';
import {
  Print as PrintIcon,
  Close as CloseIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Sale, Client, Repair } from '../types';
import { useAppStore } from '../store';
import { useWorkshopSettings } from '../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../utils/currencyUtils';

interface InvoiceProps {
  sale?: Sale;
  repair?: Repair;
  client?: Client;
  open: boolean;
  onClose: () => void;
  depositValidated?: boolean; // Indique si l'acompte a été validé
  fromKanban?: boolean; // Indique si la facture vient de la page kanban
}

// Fonction pour calculer le vrai sous-total HT basé sur les price_ht des articles
const calculateRealSubtotalHT = (sale: Sale, products: any[], services: any[], parts: any[]): number => {
  // Vérifier que sale.items existe et est un tableau
  if (!sale || !sale.items) {
    return 0;
  }
  
  // Parser les items si c'est une chaîne JSON
  let items = sale.items;
  if (typeof items === 'string') {
    try {
      items = JSON.parse(items);
    } catch (error) {
      console.error('Error parsing items in calculateRealSubtotalHT:', error);
      return 0;
    }
  }
  
  // Vérifier que c'est maintenant un tableau
  if (!Array.isArray(items)) {
    return 0;
  }
  
  return items.reduce((total, item) => {
    let itemHT = 0;
    
    // Trouver l'article source pour obtenir son price_ht
    let sourceItem = null;
    switch (item.type) {
      case 'product':
        sourceItem = products.find(p => p.id === item.itemId);
        break;
      case 'service':
        sourceItem = services.find(s => s.id === item.itemId);
        break;
      case 'part':
        sourceItem = parts.find(p => p.id === item.itemId);
        break;
    }
    
    // Si on trouve l'article source et qu'il a un price_ht défini, l'utiliser
    if (sourceItem && sourceItem.price_ht !== undefined && sourceItem.price_ht !== null) {
      itemHT = sourceItem.price_ht;
    } else {
      // Sinon, calculer le prix HT en divisant par 1.20 (TVA 20%)
      itemHT = item.unitPrice / 1.20;
    }
    
    return total + (itemHT * item.quantity);
  }, 0);
};

const Invoice: React.FC<InvoiceProps> = ({ sale, repair, client, open, onClose, depositValidated = false, fromKanban = false }) => {
  const { systemSettings, loadSystemSettings, products, services, parts, devices, getDeviceById } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';

  // Charger les paramètres système si nécessaire
  useEffect(() => {
    if (systemSettings.length === 0 || open) {
      loadSystemSettings();
    }
  }, [systemSettings.length, loadSystemSettings, open]);

  // Déterminer si on a une vente ou une réparation
  const isRepair = !!repair;
  const data = repair || sale;

  // Debug pour vérifier les données de réduction
  if (isRepair && data) {
    console.log('🔍 Données de réparation pour facture:', {
      id: data.id,
      totalPrice: (data as Repair).totalPrice,
      discountPercentage: (data as Repair).discountPercentage,
      discountAmount: (data as Repair).discountAmount,
      originalPrice: (data as Repair).originalPrice
    });
  }

  if (!data) {
    return null;
  }

  // Extraire les paramètres de l'atelier depuis les paramètres système
  const getSettingValue = (key: string, defaultValue: string = '') => {
    const setting = systemSettings.find(s => s.key === key);
    return setting ? setting.value : defaultValue;
  };

  // Utilisation des paramètres depuis le hook WorkshopSettingsContext
  const workshopSettingsData = {
    name: getSettingValue('workshop_name', 'Atelier de réparation'),
    address: getSettingValue('workshop_address', '123 Rue de la Paix, 75001 Paris'),
    phone: getSettingValue('workshop_phone', '07 59 23 91 70'),
    email: getSettingValue('workshop_email', 'contact.ateliergestion@gmail.com'),
    siret: getSettingValue('workshop_siret', ''),
    vatNumber: getSettingValue('workshop_vat_number', ''),
    vatRate: getSettingValue('vat_rate', '20'),
    currency: getSettingValue('currency', 'EUR'),
    invoiceQuoteConditions: getSettingValue('invoice_quote_conditions', ''),
    vatExempt: getSettingValue('vat_exempt', 'false') === 'true',
    vatNotApplicableArticle293B: getSettingValue('vat_not_applicable_article_293b', 'false') === 'true'
  };

  // Debug pour vérifier les paramètres
  useEffect(() => {
    console.log('🔍 Paramètres Facture & Devis:', {
      invoiceQuoteConditions: workshopSettingsData.invoiceQuoteConditions,
      vatExempt: workshopSettingsData.vatExempt,
      systemSettingsLength: systemSettings.length
    });
  }, [workshopSettingsData.invoiceQuoteConditions, workshopSettingsData.vatExempt, systemSettings.length]);

  const getStatusLabel = (status: string) => {
    const labels: { [key: string]: string } = {
      'pending': 'En attente',
      'in_progress': 'En cours',
      'completed': 'Terminée',
      'returned': 'Restituée',
      'cancelled': 'Annulée',
      'paid': 'Payée',
      'unpaid': 'Non payée'
    };
    return labels[status] || status;
  };

  const getPaymentMethodLabel = (method: string) => {
    const labels: { [key: string]: string } = {
      'cash': 'Espèces',
      'card': 'Carte bancaire',
      'transfer': 'Virement',
      'check': 'Chèque',
      'payment_link': 'Liens paiement'
    };
    return labels[method] || method;
  };

  // Fonctions de mapping pour les services et pièces
  const getMappedServices = () => {
    if (!repair || !repair.services || repair.services.length === 0) {
      return [];
    }
    
    return repair.services.map(repairService => {
      const service = services.find(s => s.id === repairService.serviceId);
      return {
        id: repairService.id,
        name: service?.name || `Service #${repairService.serviceId.slice(0, 8)}`,
        description: service?.description || '',
        quantity: repairService.quantity,
        unitPrice: repairService.price,
        totalPrice: repairService.price * repairService.quantity
      };
    });
  };

  const getMappedParts = () => {
    if (!repair || !repair.parts || repair.parts.length === 0) {
      return [];
    }
    
    return repair.parts.map(repairPart => {
      const part = parts.find(p => p.id === repairPart.partId);
      return {
        id: repairPart.id,
        name: part?.name || `Pièce #${repairPart.partId.slice(0, 8)}`,
        description: part?.description || '',
        partNumber: part?.partNumber || '',
        quantity: repairPart.quantity,
        unitPrice: repairPart.price,
        totalPrice: repairPart.price * repairPart.quantity,
        isUsed: repairPart.isUsed
      };
    });
  };

  // Récupérer les informations de l'appareil
  const getDeviceInfo = () => {
    if (!repair || !repair.deviceId) {
      return null;
    }
    return getDeviceById(repair.deviceId);
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
              <title>Facture ${data.id.slice(0, 8)}</title>
              <style>
                @page { size: A4; margin: 10mm; }
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
                  font-size: 11px;
                  margin: 0; 
                  padding: 12px; 
                  background: white; 
                  color: #333; 
                  line-height: 1.4;
                  max-height: 100vh;
                }
                .invoice-container { max-width: 100%; margin: 0 auto; background: white; }
                
                /* Header compact */
                .header { 
                  display: flex; 
                  justify-content: space-between; 
                  align-items: flex-start;
                  margin-bottom: 12px; 
                  padding-bottom: 10px; 
                  border-bottom: 2px solid #1976d2; 
                }
                .header-left h1 { font-size: 18px; font-weight: 700; color: #1976d2; margin-bottom: 2px; }
                .header-left .subtitle { font-size: 10px; color: #666; }
                .header-left .contact-info { font-size: 9px; color: #888; margin-top: 4px; }
                .header-right { text-align: right; }
                .header-right .invoice-title { font-size: 20px; font-weight: 700; color: #333; }
                .header-right .invoice-number { font-size: 12px; color: #1976d2; font-weight: 600; }
                .header-right .invoice-date { font-size: 10px; color: #666; margin-top: 2px; }
                
                /* Info sections side by side */
                .info-row { 
                  display: flex; 
                  gap: 20px; 
                  margin-bottom: 12px; 
                }
                .info-box { 
                  flex: 1; 
                  background: #f8f9fa; 
                  padding: 8px 10px; 
                  border-radius: 4px;
                  border-left: 3px solid #1976d2;
                }
                .info-box.client { border-left-color: #10b981; }
                .info-box h4 { 
                  font-size: 9px; 
                  text-transform: uppercase; 
                  color: #888; 
                  margin-bottom: 4px;
                  letter-spacing: 0.5px;
                }
                .info-box .name { font-weight: 600; color: #333; font-size: 12px; margin-bottom: 2px; }
                .info-box .detail { font-size: 10px; color: #666; line-height: 1.3; }
                
                /* Tables compact */
                table { width: 100%; border-collapse: collapse; margin-bottom: 10px; font-size: 10px; }
                th { 
                  background: linear-gradient(135deg, #1976d2 0%, #1565c0 100%); 
                  color: white;
                  padding: 6px 8px; 
                  text-align: left; 
                  font-weight: 600; 
                  font-size: 9px;
                  text-transform: uppercase;
                }
                td { padding: 5px 8px; border-bottom: 1px solid #eee; }
                tr:nth-child(even) { background: #fafafa; }
                
                /* Totals compact */
                .totals-section { 
                  display: flex;
                  justify-content: flex-end;
                  margin-bottom: 10px;
                }
                .totals-box {
                  width: 220px;
                  background: #f8f9fa;
                  border-radius: 4px;
                  padding: 8px;
                  border: 1px solid #e0e0e0;
                }
                .total-row { 
                  display: flex; 
                  justify-content: space-between; 
                  padding: 3px 0;
                  font-size: 10px; 
                }
                .total-row.final { 
                  font-weight: 700; 
                  font-size: 12px; 
                  color: #1976d2; 
                  border-top: 1px solid #ddd; 
                  margin-top: 4px;
                  padding-top: 6px;
                }
                
                /* Device & repair info compact */
                .compact-info { 
                  display: flex; 
                  gap: 10px; 
                  margin-bottom: 10px; 
                }
                .compact-box {
                  flex: 1;
                  background: #f8f9fa;
                  padding: 8px;
                  border-radius: 4px;
                  font-size: 10px;
                }
                .compact-box h5 { 
                  font-size: 9px; 
                  text-transform: uppercase; 
                  color: #1976d2; 
                  margin-bottom: 4px;
                  font-weight: 600;
                }
                .compact-box p { margin: 2px 0; color: #555; }
                .compact-box strong { color: #333; }
                
                /* VAT notice */
                .vat-notice {
                  background: #fff9e6;
                  border: 1px solid #ffd700;
                  border-radius: 4px;
                  padding: 6px;
                  text-align: center;
                  margin: 8px 0;
                }
                .vat-notice p {
                  color: #856404;
                  font-size: 10px;
                  font-style: italic;
                  margin: 0;
                }
                
                /* Conditions compact */
                .conditions { 
                  background: #f8f9fa; 
                  padding: 8px 10px; 
                  border-radius: 4px; 
                  margin-bottom: 10px;
                  font-size: 9px;
                }
                .conditions h3 { 
                  font-size: 9px; 
                  text-transform: uppercase;
                  color: #888; 
                  margin-bottom: 4px;
                  letter-spacing: 0.5px;
                }
                .conditions ul { list-style: none; padding: 0; }
                .conditions li { margin-bottom: 2px; color: #666; }
                .conditions li:before { content: "•"; color: #1976d2; margin-right: 6px; }
                
                /* Footer compact */
                .footer { 
                  text-align: center; 
                  padding-top: 8px; 
                  border-top: 1px solid #eee;
                  font-size: 9px;
                  color: #888;
                }
                .footer .company { font-weight: 600; color: #333; font-size: 11px; margin-bottom: 2px; }
                .footer .thank-you { 
                  color: #1976d2; 
                  font-weight: 600; 
                  margin-top: 4px;
                  font-size: 10px;
                }
                
                /* Status badges */
                .badge { 
                  display: inline-block;
                  padding: 2px 6px;
                  border-radius: 10px;
                  font-size: 8px;
                  font-weight: 600;
                }
                .badge-paid { background: #d4edda; color: #155724; }
                .badge-pending { background: #fff3cd; color: #856404; }
                
                @media print {
                  body { padding: 0; }
                  .invoice-container { page-break-inside: avoid; }
                }
              </style>
            </head>
            <body>
              <div class="invoice-container">
                <!-- Header compact avec logo à gauche et numéro facture à droite -->
                <div class="header">
                  <div class="header-left">
                    <h1>${workshopSettingsData.name}</h1>
                    <div class="subtitle">${workshopSettingsData.address}</div>
                    <div class="contact-info">
                      ${workshopSettingsData.phone} • ${workshopSettingsData.email}
                      ${workshopSettingsData.siret ? ` • SIRET: ${workshopSettingsData.siret}` : ''}
                      ${workshopSettingsData.vatNumber ? ` • TVA: ${workshopSettingsData.vatNumber}` : ''}
                    </div>
                  </div>
                  <div class="header-right">
                    <div class="invoice-title">FACTURE</div>
                    <div class="invoice-number">#${data.id.slice(0, 8)}</div>
                    <div class="invoice-date">${format(new Date(data.createdAt), 'dd MMMM yyyy', { locale: fr })}</div>
                  </div>
                </div>

                <!-- Info client et facture côte à côte -->
                <div class="info-row">
                  <div class="info-box client">
                    <h4>Facturé à</h4>
                    ${client ? `
                      <div class="name">${client.firstName} ${client.lastName}</div>
                      <div class="detail">${client.email}<br>${client.phone}${client.address ? `<br>${client.address}` : ''}</div>
                    ` : '<div class="name">Client anonyme</div>'}
                  </div>
                  <div class="info-box">
                    <h4>Détails</h4>
                    <div class="detail">
                      <strong>Statut :</strong> ${getStatusLabel(isRepair ? (data as Repair).status : (data as Sale).status)}<br>
                      ${isRepair ? `<strong>Paiement :</strong> <span class="badge ${(data as Repair).isPaid ? 'badge-paid' : 'badge-pending'}">${(data as Repair).isPaid ? 'Payé' : 'Non payé'}</span>` : ''}
                      ${!isRepair ? `<strong>Paiement :</strong> ${getPaymentMethodLabel((data as Sale).paymentMethod)}` : ''}
                      ${isRepair && (data as Repair).isPaid && (data as Repair).finalPaymentMethod ? `<br><strong>Mode :</strong> ${getPaymentMethodLabel((data as Repair).finalPaymentMethod!)}` : ''}
                    </div>
                  </div>
                </div>

                ${isRepair ? (() => {
                  const repair = data as Repair;
                  const device = getDeviceInfo();
                  const mappedServices = getMappedServices();
                  const mappedParts = getMappedParts();
                  const hasDeposit = repair.deposit !== null && repair.deposit !== undefined && Number(repair.deposit) > 0;
                  const remainingAmount = hasDeposit ? repair.totalPrice - repair.deposit! : repair.totalPrice;
                  
                  return `
                  <!-- Appareil et paiements côte à côte -->
                  <div class="compact-info">
                    ${device ? `
                      <div class="compact-box">
                        <h5>Appareil</h5>
                        <p><strong>${device.brand}</strong> ${device.model}</p>
                        <p>Type: ${device.type}</p>
                      </div>
                    ` : ''}
                    <div class="compact-box">
                      <h5>Paiements</h5>
                      ${hasDeposit ? `<p>Acompte: <strong>${formatFromEUR(repair.deposit!, currency)}</strong> ${depositValidated ? '✓' : '⏳'}</p>` : ''}
                      ${repair.isPaid && repair.finalPaymentMethod ? `<p>${hasDeposit ? 'Solde' : 'Payé'}: <strong>${formatFromEUR(remainingAmount, currency)}</strong> ✓</p>` : ''}
                      ${!repair.isPaid ? `<p style="color: #1976d2;"><strong>Reste: ${formatFromEUR(remainingAmount, currency)}</strong></p>` : ''}
                    </div>
                  </div>
                  
                  ${mappedServices.length > 0 || mappedParts.length > 0 ? `
                    <table>
                      <thead>
                        <tr>
                          <th>Désignation</th>
                          <th style="text-align: right; width: 70px;">P.U.</th>
                          <th style="text-align: center; width: 40px;">Qté</th>
                          <th style="text-align: right; width: 80px;">Total</th>
                        </tr>
                      </thead>
                      <tbody>
                        ${mappedServices.map(service => `
                          <tr>
                            <td><strong>${service.name}</strong>${service.description ? ` <span style="color: #888;">- ${service.description}</span>` : ''}</td>
                            <td style="text-align: right;">${formatFromEUR(service.unitPrice, currency)}</td>
                            <td style="text-align: center;">${service.quantity}</td>
                            <td style="text-align: right;"><strong>${formatFromEUR(service.totalPrice, currency)}</strong></td>
                          </tr>
                        `).join('')}
                        ${mappedParts.map(part => `
                          <tr>
                            <td><strong>${part.name}</strong>${part.partNumber ? ` <span style="color: #888;">(${part.partNumber})</span>` : ''} ${part.isUsed ? '<span style="color: #10b981;">✓</span>' : ''}</td>
                            <td style="text-align: right;">${formatFromEUR(part.unitPrice, currency)}</td>
                            <td style="text-align: center;">${part.quantity}</td>
                            <td style="text-align: right;"><strong>${formatFromEUR(part.totalPrice, currency)}</strong></td>
                          </tr>
                        `).join('')}
                      </tbody>
                    </table>
                  ` : ''}
                  
                  <div class="totals-section">
                    <div class="totals-box">
                      <div class="total-row">
                        <span>Sous-total HT</span>
                        <span>${workshopSettingsData.vatExempt ? formatFromEUR(repair.totalPrice, currency) : formatFromEUR(repair.totalPrice / (1 + parseFloat(workshopSettingsData.vatRate) / 100), currency)}</span>
                      </div>
                      ${workshopSettingsData.vatExempt ? `
                        <div class="total-row"><span>TVA</span><span>Exonéré</span></div>
                      ` : `
                        <div class="total-row">
                          <span>TVA (${workshopSettingsData.vatRate}%)</span>
                          <span>${formatFromEUR(repair.totalPrice - (repair.totalPrice / (1 + parseFloat(workshopSettingsData.vatRate) / 100)), currency)}</span>
                        </div>
                      `}
                      ${repair.discountPercentage && repair.discountPercentage > 0 ? `
                        <div class="total-row" style="color: #10b981;">
                          <span>Réduction (${repair.discountPercentage}%)</span>
                          <span>-${formatFromEUR(repair.discountAmount || 0, currency)}</span>
                        </div>
                      ` : ''}
                      <div class="total-row final">
                        <span>TOTAL TTC</span>
                        <span>${formatFromEUR(repair.totalPrice, currency)}</span>
                      </div>
                    </div>
                  </div>
                  ${workshopSettingsData.vatNotApplicableArticle293B ? `
                    <div class="vat-notice">
                      <p>TVA non applicable, article 293 B du CGI</p>
                    </div>
                  ` : ''}
                `;
                })() : (() => {
                  const sale = data as Sale;
                  let items = sale.items;
                  
                  if (typeof items === 'string') {
                    try { items = JSON.parse(items); } catch (error) { items = []; }
                  }
                  const itemsArray = Array.isArray(items) ? items : (items && typeof items === 'object' ? Object.values(items) : []);
                  
                  return `
                  <table>
                    <thead>
                      <tr>
                        <th>Article</th>
                        <th style="width: 60px;">Type</th>
                        <th style="text-align: right; width: 70px;">P.U.</th>
                        <th style="text-align: center; width: 40px;">Qté</th>
                        <th style="text-align: right; width: 80px;">Total</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${itemsArray.length > 0 ? itemsArray.map(item => `
                        <tr>
                          <td><strong>${item.name || 'Article'}</strong></td>
                          <td>${item.type === 'product' ? 'Produit' : item.type === 'service' ? 'Service' : 'Pièce'}</td>
                          <td style="text-align: right;">${formatFromEUR(item.unitPrice || 0, currency)}</td>
                          <td style="text-align: center;">${item.quantity || 1}</td>
                          <td style="text-align: right;"><strong>${formatFromEUR(item.totalPrice || 0, currency)}</strong></td>
                        </tr>
                      `).join('') : '<tr><td colspan="5" style="text-align: center; color: #888;">Aucun article</td></tr>'}
                    </tbody>
                  </table>

                  <div class="totals-section">
                    <div class="totals-box">
                      <div class="total-row">
                        <span>Sous-total HT</span>
                        <span>${formatFromEUR((data as Sale).subtotal, currency)}</span>
                      </div>
                      ${workshopSettingsData.vatExempt ? `
                        <div class="total-row"><span>TVA</span><span>Exonéré</span></div>
                      ` : `
                        <div class="total-row">
                          <span>TVA (${workshopSettingsData.vatRate}%)</span>
                          <span>${formatFromEUR((data as Sale).tax, currency)}</span>
                        </div>
                      `}
                      <div class="total-row final">
                        <span>TOTAL TTC</span>
                        <span>${formatFromEUR(workshopSettingsData.vatExempt ? sale.subtotal - (sale.discountAmount || 0) : sale.total, currency)}</span>
                      </div>
                    </div>
                  </div>
                  ${workshopSettingsData.vatNotApplicableArticle293B ? `
                    <div class="vat-notice">
                      <p>TVA non applicable, article 293 B du CGI</p>
                    </div>
                  ` : ''}
                    `;
                })()}

                <div class="conditions">
                  <h3>Conditions</h3>
                  ${workshopSettingsData.invoiceQuoteConditions ? `
                    <div style="white-space: pre-line; color: #666;">${workshopSettingsData.invoiceQuoteConditions}</div>
                  ` : `
                    <ul>
                      ${!isRepair ? `<li>Paiement par ${getPaymentMethodLabel((data as Sale).paymentMethod).toLowerCase()}</li>` : ''}
                      <li>Facture valable 30 jours</li>
                      <li>Aucun escompte en cas de paiement anticipé</li>
                    </ul>
                  `}
                </div>

                <div class="footer">
                  <div class="company">${workshopSettingsData.name}</div>
                  ${workshopSettingsData.phone} • ${workshopSettingsData.email}
                  ${workshopSettingsData.siret ? ` • SIRET: ${workshopSettingsData.siret}` : ''}
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

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6">
            {isRepair ? 'Facture Réparation' : 'Facture'} #{data.id.slice(0, 8)}
          </Typography>
          <Box>
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
                {workshopSettingsData.name}
              </Typography>
              <Box sx={{ fontSize: '12px', color: '#666', lineHeight: 1.8 }}>
                <Typography sx={{ mb: 0.5 }}>
                  Tél: {workshopSettingsData.phone} • Email: {workshopSettingsData.email}
                </Typography>
                {workshopSettingsData.siret && (
                  <Typography>
                    SIRET: {workshopSettingsData.siret}
                  </Typography>
                )}
                {workshopSettingsData.vatNumber && (
                  <Typography>
                    TVA: {workshopSettingsData.vatNumber}
                  </Typography>
                )}
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
                  <Typography sx={{ 
                    fontSize: '14px', 
                    color: '#666', 
                    fontStyle: 'italic' 
                  }}>
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
                  #{data.id.slice(0, 8)}
                </Typography>
                <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                  <strong>Date :</strong> {format(new Date(data.createdAt), 'dd/MM/yyyy', { locale: fr })}
                </Typography>
                <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                  <strong>Statut :</strong> {getStatusLabel(isRepair ? (data as Repair).status : (data as Sale).status)}
                </Typography>
                {isRepair && (
                  <>
                    <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                      <strong>Paiement :</strong> {(data as Repair).isPaid ? 'Payé' : 'Non payé'}
                    </Typography>
                    {!fromKanban && (
                      <>
                        {(data as Repair).isPaid && (data as Repair).finalPaymentMethod && (
                          <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                            <strong>Mode de paiement :</strong> {getPaymentMethodLabel((data as Repair).finalPaymentMethod!)}
                          </Typography>
                        )}
                        {!(data as Repair).isPaid && (data as Repair).paymentMethod && (
                          <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                            <strong>Mode de paiement :</strong> {getPaymentMethodLabel((data as Repair).paymentMethod!)}
                          </Typography>
                        )}
                      </>
                    )}
                  </>
                )}
                {!isRepair && (
                  <Typography sx={{ fontSize: '14px', color: '#666' }}>
                    <strong>Paiement :</strong> {getPaymentMethodLabel((data as Sale).paymentMethod)}
                  </Typography>
                )}
              </Box>
            </Box>

            {/* Contenu spécifique selon le type */}
            {isRepair ? (
              // Affichage pour les réparations
              <Box sx={{ mb: 5 }}>
                {/* Informations appareil */}
                {(() => {
                  const device = getDeviceInfo();
                  if (device) {
                    return (
                      <Box sx={{ mb: 4 }}>
                        <Typography variant="h6" sx={{ 
                          fontWeight: 600, 
                          color: '#333', 
                          mb: 2, 
                          pb: 0.5, 
                          borderBottom: '1px solid #eee',
                          fontSize: '16px'
                        }}>
                          Informations appareil
                        </Typography>
                        <Box sx={{ 
                          p: 2, 
                          backgroundColor: '#f8f9fa', 
                          borderRadius: 1,
                          border: '1px solid #e0e0e0'
                        }}>
                          <Grid container spacing={2}>
                            <Grid item xs={12} sm={6}>
                              <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                                <strong>Marque :</strong> {device.brand}
                              </Typography>
                            </Grid>
                            <Grid item xs={12} sm={6}>
                              <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                                <strong>Modèle :</strong> {device.model}
                              </Typography>
                            </Grid>
                            <Grid item xs={12} sm={6}>
                              <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                                <strong>Type :</strong> {device.type}
                              </Typography>
                            </Grid>
                          </Grid>
                        </Box>
                      </Box>
                    );
                  }
                  return null;
                })()}

                <Typography variant="h6" sx={{ 
                  fontWeight: 600, 
                  color: '#333', 
                  mb: 2, 
                  pb: 0.5, 
                  borderBottom: '1px solid #eee',
                  fontSize: '16px'
                }}>
                  Détails de la réparation
                </Typography>
                <Box sx={{ 
                  p: 2, 
                  backgroundColor: '#f8f9fa', 
                  borderRadius: 1,
                  border: '1px solid #e0e0e0'
                }}>
                  <Typography sx={{ fontSize: '16px', mb: 1 }}>
                    <strong>Prix de la réparation (TTC) :</strong> {formatFromEUR((data as Repair).totalPrice, currency)}
                    {(() => {
                      const repair = data as Repair;
                      return repair.discountPercentage && repair.discountPercentage > 0 ? (
                        <span style={{ color: 'success.main', marginLeft: '8px' }}>
                          (Prix original: {formatFromEUR(repair.totalPrice + (repair.discountAmount || 0), currency)})
                        </span>
                      ) : null;
                    })()}
                  </Typography>
                  {(() => {
                    const repair = data as Repair;
                    const hasDeposit = repair.deposit !== null && repair.deposit !== undefined && Number(repair.deposit) > 0;
                    const remainingAmount = hasDeposit ? repair.totalPrice - repair.deposit! : repair.totalPrice;
                    
                    return (
                     <Box sx={{ mt: 2, mb: 1 }}>
                       <Typography sx={{ fontSize: '16px', fontWeight: 600, mb: 1 }}>
                         Historique des paiements :
                       </Typography>
                       {hasDeposit && (
                         <Typography sx={{ fontSize: '14px', mb: 0.5, display: 'flex', alignItems: 'center', gap: 1 }}>
                           <strong>Acompte ({getPaymentMethodLabel(repair.depositPaymentMethod || repair.paymentMethod || 'cash')}) :</strong> 
                           <span>{formatFromEUR(repair.deposit!, currency)}</span>
                           {depositValidated ? (
                             <span style={{ color: '#10b981', fontWeight: 'bold' }}>✓ PAYÉ</span>
                           ) : (
                             <span style={{ color: '#f59e0b', fontWeight: 'bold' }}>⏳ EN ATTENTE</span>
                           )}
                         </Typography>
                       )}
                       {repair.isPaid && repair.finalPaymentMethod && (
                         <Typography sx={{ fontSize: '14px', mb: 0.5, display: 'flex', alignItems: 'center', gap: 1 }}>
                           <strong>{hasDeposit ? 'Solde' : 'Paiement'} ({getPaymentMethodLabel(repair.finalPaymentMethod!)}) :</strong> 
                           <span>{formatFromEUR(remainingAmount, currency)}</span>
                           <span style={{ color: '#10b981', fontWeight: 'bold' }}>✓ PAYÉ</span>
                         </Typography>
                       )}
                       {!repair.isPaid && (
                         <Typography sx={{ fontSize: '16px', mt: 1, color: 'primary.main', fontWeight: 600 }}>
                           <strong>Reste à payer :</strong> {formatFromEUR(remainingAmount, currency)}
                         </Typography>
                       )}
                     </Box>
                    );
                  })()}
                  {(data as Repair).notes && (
                    <Typography sx={{ fontSize: '14px', color: '#666' }}>
                      <strong>Notes :</strong> {(data as Repair).notes}
                    </Typography>
                  )}
                </Box>

                {/* Tableau des services */}
                {(() => {
                  const mappedServices = getMappedServices();
                  if (mappedServices.length > 0) {
                    return (
                      <Box sx={{ mb: 4 }}>
                        <Typography variant="h6" sx={{ 
                          fontWeight: 600, 
                          color: '#333', 
                          mb: 2, 
                          pb: 0.5, 
                          borderBottom: '1px solid #eee',
                          fontSize: '16px'
                        }}>
                          Services effectués
                        </Typography>
                        <TableContainer component={Paper} variant="outlined">
                          <Table>
                            <TableHead>
                              <TableRow sx={{ backgroundColor: '#f8f9fa' }}>
                                <TableCell sx={{ fontWeight: 600, fontSize: '14px', color: '#333', borderBottom: '1px solid #eee', py: 1.5 }}>
                                  Service
                                </TableCell>
                                <TableCell sx={{ fontWeight: 600, fontSize: '14px', color: '#333', borderBottom: '1px solid #eee', py: 1.5, textAlign: 'right' }}>
                                  Prix unitaire
                                </TableCell>
                                <TableCell sx={{ fontWeight: 600, fontSize: '14px', color: '#333', borderBottom: '1px solid #eee', py: 1.5, textAlign: 'center' }}>
                                  Quantité
                                </TableCell>
                                <TableCell sx={{ fontWeight: 600, fontSize: '14px', color: '#333', borderBottom: '1px solid #eee', py: 1.5, textAlign: 'right' }}>
                                  Total
                                </TableCell>
                              </TableRow>
                            </TableHead>
                            <TableBody>
                              {mappedServices.map((service) => (
                                <TableRow key={service.id}>
                                  <TableCell sx={{ borderBottom: '1px solid #f1f1f1', py: 1.5 }}>
                                    <Typography sx={{ fontWeight: 600, color: '#333', fontSize: '14px' }}>
                                      {service.name}
                                    </Typography>
                                    {service.description && (
                                      <Typography sx={{ fontSize: '12px', color: '#666', mt: 0.5 }}>
                                        {service.description}
                                      </Typography>
                                    )}
                                  </TableCell>
                                  <TableCell sx={{ borderBottom: '1px solid #f1f1f1', py: 1.5, textAlign: 'right' }}>
                                    <Typography sx={{ fontSize: '14px' }}>
                                      {formatFromEUR(service.unitPrice, currency)}
                                    </Typography>
                                  </TableCell>
                                  <TableCell sx={{ borderBottom: '1px solid #f1f1f1', py: 1.5, textAlign: 'center' }}>
                                    <Typography sx={{ fontSize: '14px' }}>
                                      {service.quantity}
                                    </Typography>
                                  </TableCell>
                                  <TableCell sx={{ borderBottom: '1px solid #f1f1f1', py: 1.5, textAlign: 'right' }}>
                                    <Typography sx={{ fontWeight: 600, fontSize: '14px', color: '#333' }}>
                                      {formatFromEUR(service.totalPrice, currency)}
                                    </Typography>
                                  </TableCell>
                                </TableRow>
                              ))}
                            </TableBody>
                          </Table>
                        </TableContainer>
                      </Box>
                    );
                  }
                  return null;
                })()}

                {/* Tableau des pièces */}
                {(() => {
                  const mappedParts = getMappedParts();
                  if (mappedParts.length > 0) {
                    return (
                      <Box sx={{ mb: 4 }}>
                        <Typography variant="h6" sx={{ 
                          fontWeight: 600, 
                          color: '#333', 
                          mb: 2, 
                          pb: 0.5, 
                          borderBottom: '1px solid #eee',
                          fontSize: '16px'
                        }}>
                          Pièces utilisées
                        </Typography>
                        <TableContainer component={Paper} variant="outlined">
                          <Table>
                            <TableHead>
                              <TableRow sx={{ backgroundColor: '#f8f9fa' }}>
                                <TableCell sx={{ fontWeight: 600, fontSize: '14px', color: '#333', borderBottom: '1px solid #eee', py: 1.5 }}>
                                  Pièce
                                </TableCell>
                                <TableCell sx={{ fontWeight: 600, fontSize: '14px', color: '#333', borderBottom: '1px solid #eee', py: 1.5, textAlign: 'right' }}>
                                  Prix unitaire
                                </TableCell>
                                <TableCell sx={{ fontWeight: 600, fontSize: '14px', color: '#333', borderBottom: '1px solid #eee', py: 1.5, textAlign: 'center' }}>
                                  Quantité
                                </TableCell>
                                <TableCell sx={{ fontWeight: 600, fontSize: '14px', color: '#333', borderBottom: '1px solid #eee', py: 1.5, textAlign: 'center' }}>
                                  Statut
                                </TableCell>
                                <TableCell sx={{ fontWeight: 600, fontSize: '14px', color: '#333', borderBottom: '1px solid #eee', py: 1.5, textAlign: 'right' }}>
                                  Total
                                </TableCell>
                              </TableRow>
                            </TableHead>
                            <TableBody>
                              {mappedParts.map((part) => (
                                <TableRow key={part.id}>
                                  <TableCell sx={{ borderBottom: '1px solid #f1f1f1', py: 1.5 }}>
                                    <Typography sx={{ fontWeight: 600, color: '#333', fontSize: '14px' }}>
                                      {part.name}
                                    </Typography>
                                    {part.partNumber && (
                                      <Typography sx={{ fontSize: '12px', color: '#666', mt: 0.5 }}>
                                        Réf: {part.partNumber}
                                      </Typography>
                                    )}
                                    {part.description && (
                                      <Typography sx={{ fontSize: '12px', color: '#666', mt: 0.5 }}>
                                        {part.description}
                                      </Typography>
                                    )}
                                  </TableCell>
                                  <TableCell sx={{ borderBottom: '1px solid #f1f1f1', py: 1.5, textAlign: 'right' }}>
                                    <Typography sx={{ fontSize: '14px' }}>
                                      {formatFromEUR(part.unitPrice, currency)}
                                    </Typography>
                                  </TableCell>
                                  <TableCell sx={{ borderBottom: '1px solid #f1f1f1', py: 1.5, textAlign: 'center' }}>
                                    <Typography sx={{ fontSize: '14px' }}>
                                      {part.quantity}
                                    </Typography>
                                  </TableCell>
                                  <TableCell sx={{ borderBottom: '1px solid #f1f1f1', py: 1.5, textAlign: 'center' }}>
                                    <Chip
                                      label={part.isUsed ? 'Utilisée' : 'Non utilisée'}
                                      size="small"
                                      color={part.isUsed ? 'success' : 'default'}
                                      variant="outlined"
                                    />
                                  </TableCell>
                                  <TableCell sx={{ borderBottom: '1px solid #f1f1f1', py: 1.5, textAlign: 'right' }}>
                                    <Typography sx={{ fontWeight: 600, fontSize: '14px', color: '#333' }}>
                                      {formatFromEUR(part.totalPrice, currency)}
                                    </Typography>
                                  </TableCell>
                                </TableRow>
                              ))}
                            </TableBody>
                          </Table>
                        </TableContainer>
                      </Box>
                    );
                  }
                  return null;
                })()}
                
                {/* Totaux pour les réparations */}
                <Box sx={{ 
                  display: 'flex', 
                  flexDirection: 'column', 
                  alignItems: 'flex-end', 
                  mb: 5 
                }}>
                  <Box sx={{ 
                    width: '300px',
                    p: 2,
                    backgroundColor: '#f8f9fa',
                    borderRadius: 1,
                    border: '1px solid #e0e0e0'
                  }}>
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
                        {formatFromEUR((data as Repair).totalPrice / (1 + parseFloat(workshopSettingsData.vatRate) / 100), currency)}
                      </Typography>
                    </Box>
                    {workshopSettingsData.vatExempt ? (
                      <Box sx={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center', 
                        mb: 1 
                      }}>
                        <Typography sx={{ fontSize: '16px' }}>
                          Exonéré de TVA
                        </Typography>
                        <Typography sx={{ fontSize: '16px' }}>
                          -
                        </Typography>
                      </Box>
                    ) : (
                      <Box sx={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center', 
                        mb: 1 
                      }}>
                        <Typography sx={{ fontSize: '16px' }}>
                          TVA ({workshopSettingsData.vatRate}%) :
                        </Typography>
                        <Typography sx={{ fontSize: '16px' }}>
                          {formatFromEUR((data as Repair).totalPrice - ((data as Repair).totalPrice / (1 + parseFloat(workshopSettingsData.vatRate) / 100)), currency)}
                        </Typography>
                      </Box>
                    )}
                    {(() => {
                      const repair = data as Repair;
                      return repair.discountPercentage && repair.discountPercentage > 0 ? (
                        <Box sx={{ 
                          display: 'flex', 
                          justifyContent: 'space-between', 
                          alignItems: 'center', 
                          mb: 1 
                        }}>
                          <Typography sx={{ fontSize: '16px', color: 'success.main' }}>
                            Réduction fidélité ({repair.discountPercentage}%) :
                          </Typography>
                          <Typography sx={{ fontSize: '16px', color: 'success.main', fontWeight: 600 }}>
                            -{formatFromEUR(repair.discountAmount || 0, currency)}
                          </Typography>
                        </Box>
                      ) : null;
                    })()}
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
                        {formatFromEUR((data as Repair).totalPrice, currency)}
                      </Typography>
                    </Box>
                  </Box>
                </Box>
              </Box>
            ) : (
              // Affichage pour les ventes
              <>
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
                      {(() => {
                        const sale = data as Sale;
                        console.log('🔍 Debug Invoice - Sale data:', sale);
                        console.log('🔍 Debug Invoice - Sale items:', sale.items);
                        console.log('🔍 Debug Invoice - Is array:', Array.isArray(sale.items));
                        console.log('🔍 Debug Invoice - Items length:', sale.items?.length);
                        
                        // Parser les items si c'est une chaîne JSON
                        let items = sale.items;
                        if (typeof items === 'string') {
                          try {
                            items = JSON.parse(items);
                            console.log('🔍 Debug Invoice - Parsed items:', items);
                          } catch (error) {
                            console.error('🔍 Debug Invoice - Error parsing items:', error);
                            return false;
                          }
                        }
                        
                        // Vérification plus robuste
                        if (!items) return false;
                        if (Array.isArray(items)) return items.length > 0;
                        if (typeof items === 'object') return Object.keys(items).length > 0;
                        return false;
                      })() ? (() => {
                        const sale = data as Sale;
                        let items = sale.items;
                        
                        // Parser les items si c'est une chaîne JSON
                        if (typeof items === 'string') {
                          try {
                            items = JSON.parse(items);
                          } catch (error) {
                            console.error('Error parsing items:', error);
                            return [];
                          }
                        }
                        
                        // Convertir en tableau si nécessaire
                        const itemsArray = Array.isArray(items) ? items : Object.values(items || {});
                        return itemsArray.map((item, index) => (
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
                            <Chip 
                              label={item.type === 'product' ? 'Produit' : item.type === 'service' ? 'Service' : 'Pièce'} 
                              size="small" 
                              color="primary" 
                              variant="outlined"
                            />
                          </TableCell>
                          <TableCell sx={{ 
                            borderBottom: '1px solid #f1f1f1', 
                            py: 1.5,
                            textAlign: 'right'
                          }}>
                            <Typography sx={{ fontSize: '14px' }}>
                              {formatFromEUR(item.unitPrice, currency)}
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
                              fontSize: '14px',
                              color: '#333'
                            }}>
                              {formatFromEUR(item.totalPrice, currency)}
                            </Typography>
                          </TableCell>
                        </TableRow>
                        ));
                      })() : (
                        <TableRow>
                          <TableCell colSpan={5} sx={{ 
                            textAlign: 'center', 
                            color: '#666', 
                            fontStyle: 'italic',
                            py: 2
                          }}>
                            Aucun article disponible
                          </TableCell>
                        </TableRow>
                      )}
                    </TableBody>
                  </Table>
                </Box>

                {/* Totaux */}
                <Box sx={{ 
                  display: 'flex', 
                  flexDirection: 'column', 
                  alignItems: 'flex-end', 
                  mb: 5 
                }}>
                  <Box sx={{ 
                    width: '300px',
                    p: 2,
                    backgroundColor: '#f8f9fa',
                    borderRadius: 1,
                    border: '1px solid #e0e0e0'
                  }}>
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
                        {formatFromEUR((data as Sale).subtotal, currency)}
                      </Typography>
                    </Box>
                    {workshopSettingsData.vatExempt ? (
                      <Box sx={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center', 
                        mb: 1 
                      }}>
                        <Typography sx={{ fontSize: '16px' }}>
                          Exonéré de TVA
                        </Typography>
                        <Typography sx={{ fontSize: '16px' }}>
                          -
                        </Typography>
                      </Box>
                    ) : (
                      <Box sx={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center', 
                        mb: 1 
                      }}>
                        <Typography sx={{ fontSize: '16px' }}>
                          TVA ({workshopSettingsData.vatRate}%) :
                        </Typography>
                        <Typography sx={{ fontSize: '16px' }}>
                          {formatFromEUR((data as Sale).tax || 0, currency)}
                        </Typography>
                      </Box>
                    )}
                    {!workshopSettingsData.vatExempt && (
                      <Box sx={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center', 
                        mb: 1 
                      }}>
                        <Typography sx={{ fontSize: '16px' }}>
                          Sous-total TTC :
                        </Typography>
                        <Typography sx={{ fontSize: '16px' }}>
                          {formatFromEUR((data as Sale).subtotal + ((data as Sale).tax || 0), currency)}
                        </Typography>
                      </Box>
                    )}
                    {(() => {
                      const sale = data as Sale;
                      return sale.discountPercentage && sale.discountPercentage > 0 ? (
                        <Box sx={{ 
                          display: 'flex', 
                          justifyContent: 'space-between', 
                          alignItems: 'center', 
                          mb: 1 
                        }}>
                          <Typography sx={{ fontSize: '16px', color: 'success.main' }}>
                            Réduction fidélité ({sale.discountPercentage}%) :
                          </Typography>
                          <Typography sx={{ fontSize: '16px', color: 'success.main', fontWeight: 600 }}>
                            -{formatFromEUR(sale.discountAmount || 0, currency)}
                          </Typography>
                        </Box>
                      ) : null;
                    })()}
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
                        {workshopSettingsData.vatExempt 
                          ? formatFromEUR((data as Sale).subtotal - ((data as Sale).discountAmount || 0), currency)
                          : formatFromEUR((data as Sale).total, currency)}
                      </Typography>
                    </Box>
                  </Box>
                </Box>
              </>
            )}

            {/* Message TVA non applicable article 293 B du CGI - pour toutes les factures */}
            {workshopSettingsData.vatNotApplicableArticle293B && (
              <Box sx={{ 
                mb: 3, 
                p: 2, 
                backgroundColor: '#fff9e6', 
                border: '1px solid #ffd700',
                borderRadius: 1,
                textAlign: 'center'
              }}>
                <Typography sx={{ 
                  color: '#856404', 
                  fontSize: '14px', 
                  fontWeight: 500,
                  fontStyle: 'italic'
                }}>
                  TVA non applicable, article 293 B du CGI
                </Typography>
              </Box>
            )}

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
              {workshopSettingsData.invoiceQuoteConditions ? (
                <Typography sx={{ 
                  color: '#666', 
                  fontSize: '13px', 
                  whiteSpace: 'pre-line',
                  lineHeight: 1.6
                }}>
                  {workshopSettingsData.invoiceQuoteConditions}
                </Typography>
              ) : (
                <Box component="ul" sx={{ 
                  listStyle: 'none', 
                  p: 0, 
                  m: 0 
                }}>
                  {!isRepair && (
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
                      Paiement immédiat par {getPaymentMethodLabel((data as Sale).paymentMethod).toLowerCase()}
                    </Box>
                  )}
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
                    Pour toute question, contactez-nous au {workshopSettingsData.phone} ou par email à {workshopSettingsData.email}
                  </Box>
                </Box>
              )}
            </Box>

            {/* Pied de page */}
            <Box sx={{ 
              textAlign: 'center', 
              mt: 5, 
              pt: 2.5, 
              borderTop: '1px solid #eee' 
            }}>
              <Typography variant="h6" sx={{ 
                mb: 1, 
                fontSize: '18px', 
                color: '#333' 
              }}>
                {workshopSettingsData.name}
              </Typography>
              <Typography sx={{ 
                fontSize: '12px', 
                color: '#666', 
                mb: 0.5 
              }}>
                Tél: {workshopSettingsData.phone} • Email: {workshopSettingsData.email}
              </Typography>
              {workshopSettingsData.siret && (
                <Typography sx={{ 
                  fontSize: '12px', 
                  color: '#666', 
                  mb: 0.5 
                }}>
                  SIRET: {workshopSettingsData.siret}
                </Typography>
              )}
              {workshopSettingsData.vatNumber && (
                <Typography sx={{ 
                  fontSize: '12px', 
                  color: '#666', 
                  mb: 1 
                }}>
                  TVA: {workshopSettingsData.vatNumber}
                </Typography>
              )}
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
    </Dialog>
  );
};

export default Invoice;
