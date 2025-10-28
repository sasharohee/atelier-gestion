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

const Invoice: React.FC<InvoiceProps> = ({ sale, repair, client, open, onClose }) => {
  const { systemSettings, loadSystemSettings, products, services, parts } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';

  // Charger les paramètres système si nécessaire
  useEffect(() => {
    if (systemSettings.length === 0) {
      loadSystemSettings();
    }
  }, [systemSettings.length, loadSystemSettings]);

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
    currency: getSettingValue('currency', 'EUR')
  };

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
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
                  margin: 0; padding: 24px; background: white; color: #333; line-height: 1.6;
                }
                .invoice-container { max-width: 800px; margin: 0 auto; background: white; }
                .header { text-align: center; margin-bottom: 40px; padding-bottom: 20px; border-bottom: 1px solid #eee; }
                .header h1 { font-size: 24px; font-weight: 600; margin: 0 0 8px 0; color: #333; }
                .header .subtitle { font-size: 14px; color: #666; margin-bottom: 16px; }
                .header .contact-info { font-size: 12px; color: #666; line-height: 1.8; }
                .invoice-details { display: flex; justify-content: space-between; margin-bottom: 40px; }
                .client-section, .invoice-section { flex: 1; }
                .section-title { font-weight: 600; margin-bottom: 12px; color: #333; font-size: 14px; }
                .client-info, .invoice-info { font-size: 14px; color: #666; line-height: 1.6; }
                .client-name { font-weight: 600; color: #333; margin-bottom: 8px; }
                .invoice-number { font-weight: 600; color: #1976d2; font-size: 16px; margin-bottom: 8px; }
                table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
                th { background-color: #f8f9fa; padding: 12px; text-align: left; font-weight: 600; color: #333; border-bottom: 1px solid #eee; }
                td { padding: 12px; border-bottom: 1px solid #f1f1f1; }
                .totals-section { margin-bottom: 30px; }
                .total-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 14px; }
                .total-row:last-child { font-weight: 600; font-size: 16px; color: #1976d2; border-top: 1px solid #eee; padding-top: 8px; }
                .conditions { background-color: #f8f9fa; padding: 20px; border-radius: 4px; margin-bottom: 30px; }
                .conditions h3 { margin-bottom: 12px; font-size: 16px; color: #333; }
                .conditions ul { list-style: none; padding: 0; }
                .conditions li { margin-bottom: 6px; font-size: 14px; color: #666; }
                .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; }
                .footer h3 { margin-bottom: 8px; font-size: 18px; color: #333; }
                .footer p { font-size: 12px; color: #666; margin-bottom: 4px; }
                .thank-you { font-weight: 600; color: #1976d2; margin-top: 12px; }
              </style>
            </head>
            <body>
              <div class="invoice-container">
                <div class="header">
                  <h1>${workshopSettingsData.name}</h1>
                  <div class="subtitle">${workshopSettingsData.address}</div>
                  <div class="contact-info">
                    Tél: ${workshopSettingsData.phone} • Email: ${workshopSettingsData.email}
                    ${workshopSettingsData.siret ? `<br>SIRET: ${workshopSettingsData.siret}` : ''}
                    ${workshopSettingsData.vatNumber ? ` • TVA: ${workshopSettingsData.vatNumber}` : ''}
                  </div>
                </div>

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
                      <div class="invoice-number">#${data.id.slice(0, 8)}</div>
                      <div><strong>Date :</strong> ${format(new Date(data.createdAt), 'dd/MM/yyyy', { locale: fr })}</div>
                      <div><strong>Statut :</strong> ${getStatusLabel(isRepair ? (data as Repair).status : (data as Sale).status)}</div>
                      ${isRepair ? `<div><strong>Paiement :</strong> ${(data as Repair).isPaid ? 'Payé' : 'Non payé'}</div>` : ''}
                      ${!isRepair ? `<div><strong>Paiement :</strong> ${getPaymentMethodLabel((data as Sale).paymentMethod)}</div>` : ''}
                    </div>
                  </div>
                </div>

                ${isRepair ? `
                  <div class="repair-details">
                    <h3>Détails de la réparation</h3>
                    <p><strong>Prix de la réparation (TTC) :</strong> ${formatFromEUR((data as Repair).totalPrice, currency)}</p>
                    ${(data as Repair).notes ? `<p><strong>Notes :</strong> ${(data as Repair).notes}</p>` : ''}
                  </div>
                ` : `
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
                      ${Array.isArray((data as Sale).items) ? (data as Sale).items.map(item => `
                        <tr>
                          <td><span class="item-name">${item.name}</span></td>
                          <td><span class="item-type">${item.type === 'product' ? 'Produit' : item.type === 'service' ? 'Service' : 'Pièce'}</span></td>
                          <td style="text-align: right;"><span class="price">${formatFromEUR(item.unitPrice, currency)}</span></td>
                          <td style="text-align: center;">${item.quantity}</td>
                          <td style="text-align: right;"><span class="price">${formatFromEUR(item.totalPrice, currency)}</span></td>
                        </tr>
                      `).join('') : '<tr><td colspan="5" style="text-align: center; color: #666; font-style: italic;">Aucun article disponible</td></tr>'}
                    </tbody>
                  </table>

                  <div class="totals-section">
                    <div class="total-row">
                      <span>Sous-total HT :</span>
                      <span>${formatFromEUR((data as Sale).subtotal, currency)}</span>
                    </div>
                    <div class="total-row">
                      <span>TVA (${workshopSettingsData.vatRate}%) :</span>
                      <span>${formatFromEUR((data as Sale).tax, currency)}</span>
                    </div>
                    <div class="total-row">
                      <span>TOTAL TTC :</span>
                      <span>${formatFromEUR((data as Sale).total, currency)}</span>
                    </div>
                  </div>
                `}

                <div class="conditions">
                  <h3>CONDITIONS DE PAIEMENT</h3>
                  <ul>
                    ${!isRepair ? `<li>Paiement immédiat par ${getPaymentMethodLabel((data as Sale).paymentMethod).toLowerCase()}</li>` : ''}
                    <li>Facture valable 30 jours à compter de la date d'émission</li>
                    <li>Aucun escompte en cas de paiement anticipé</li>
                    <li>Pour toute question, contactez-nous au ${workshopSettingsData.phone} ou par email à ${workshopSettingsData.email}</li>
                  </ul>
                </div>

                <div class="footer">
                  <h3>${workshopSettingsData.name}</h3>
                  <p>Tél: ${workshopSettingsData.phone} • Email: ${workshopSettingsData.email}</p>
                  <p>Tél: ${workshopSettingsData.phone} • Email: ${workshopSettingsData.email}</p>
                  ${workshopSettingsData.siret ? `<p>SIRET: ${workshopSettingsData.siret}</p>` : ''}
                  ${workshopSettingsData.vatNumber ? `<p>TVA: ${workshopSettingsData.vatNumber}</p>` : ''}
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
                  <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                    <strong>Paiement :</strong> {(data as Repair).isPaid ? 'Payé' : 'Non payé'}
                  </Typography>
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
                  {(data as Repair).notes && (
                    <Typography sx={{ fontSize: '14px', color: '#666' }}>
                      <strong>Notes :</strong> {(data as Repair).notes}
                    </Typography>
                  )}
                </Box>
                
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
                        {formatFromEUR(
                          sale && products && services && parts 
                            ? calculateRealSubtotalHT(data as Sale, products, services, parts)
                            : (data as Sale).subtotal / 1.20, // Fallback si les données ne sont pas chargées
                          currency
                        )}
                      </Typography>
                    </Box>
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
                        {formatFromEUR((data as Sale).subtotal, currency)}
                      </Typography>
                    </Box>
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
                        {formatFromEUR((data as Sale).total, currency)}
                      </Typography>
                    </Box>
                  </Box>
                </Box>
              </>
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
