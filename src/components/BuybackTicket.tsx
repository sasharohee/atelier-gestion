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
import { Buyback } from '../types';
import { useAppStore } from '../store';
import { useWorkshopSettings } from '../contexts/WorkshopSettingsContext';

interface BuybackTicketProps {
  buyback: Buyback;
  open: boolean;
  onClose: () => void;
}

const BuybackTicket: React.FC<BuybackTicketProps> = ({ buyback, open, onClose }) => {
  const { workshopSettings } = useWorkshopSettings();

  const getStatusLabel = (status: string) => {
    const labels: { [key: string]: string } = {
      'pending': 'En attente',
      'accepted': 'Accepté',
      'rejected': 'Refusé',
      'paid': 'Payé'
    };
    return labels[status] || status;
  };

  const getStatusColor = (status: string) => {
    const colors: { [key: string]: string } = {
      'pending': '#f59e0b',
      'accepted': '#10b981',
      'rejected': '#ef4444',
      'paid': '#3b82f6'
    };
    return colors[status] || '#6b7280';
  };

  const getPaymentMethodLabel = (method: string) => {
    const labels: { [key: string]: string } = {
      'cash': 'Espèces',
      'transfer': 'Virement',
      'check': 'Chèque',
      'credit': 'Avoir'
    };
    return labels[method] || method;
  };

  const getBuybackReasonLabel = (reason: string) => {
    const labels: { [key: string]: string } = {
      'resale': 'Revente',
      'parts': 'Pièces détachées',
      'collection': 'Collection',
      'other': 'Autre'
    };
    return labels[reason] || reason;
  };

  const getConditionLabel = (condition: string) => {
    const labels: { [key: string]: string } = {
      'excellent': 'Excellent',
      'good': 'Bon',
      'fair': 'Correct',
      'poor': 'Mauvais',
      'broken': 'Cassé'
    };
    return labels[condition] || condition;
  };

  const handlePrint = () => {
    const printContent = document.getElementById('buyback-ticket-content');
    if (printContent) {
      const printWindow = window.open('', '_blank');
      if (printWindow) {
        printWindow.document.write(`
          <!DOCTYPE html>
          <html>
            <head>
              <title>Ticket de Rachat ${buyback.id.slice(0, 8)}</title>
              <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
                  margin: 0; padding: 24px; background: white; color: #333; line-height: 1.6;
                }
                .ticket-container { max-width: 800px; margin: 0 auto; background: white; }
                .header { text-align: center; margin-bottom: 40px; padding-bottom: 20px; border-bottom: 2px solid #10b981; }
                .header h1 { font-size: 28px; font-weight: 700; margin: 0 0 8px 0; color: #10b981; }
                .header .subtitle { font-size: 16px; color: #666; margin-bottom: 16px; }
                .header .contact-info { font-size: 12px; color: #666; line-height: 1.8; }
                .buyback-details { display: flex; justify-content: space-between; margin-bottom: 40px; }
                .client-section, .buyback-section { flex: 1; margin-right: 20px; }
                .section-title { font-weight: 600; margin-bottom: 12px; color: #333; font-size: 16px; text-transform: uppercase; }
                .client-info, .buyback-info { font-size: 14px; color: #666; line-height: 1.6; }
                .client-name { font-weight: 600; color: #333; margin-bottom: 8px; }
                .buyback-number { font-weight: 600; color: #10b981; font-size: 18px; margin-bottom: 8px; }
                .device-info { background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
                .device-info h3 { margin-bottom: 15px; font-size: 18px; color: #333; }
                .device-details { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
                .device-detail { margin-bottom: 8px; }
                .device-detail strong { color: #333; }
                .condition-info { background-color: #f0f9ff; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
                .condition-info h3 { margin-bottom: 15px; font-size: 18px; color: #333; }
                .condition-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
                .accessories-info { background-color: #f0fdf4; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
                .accessories-info h3 { margin-bottom: 15px; font-size: 18px; color: #333; }
                .accessories-list { display: flex; flex-wrap: wrap; gap: 10px; }
                .accessory-tag { background-color: #10b981; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
                .price-section { background-color: #fef3c7; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
                .price-section h3 { margin-bottom: 15px; font-size: 18px; color: #333; }
                .price-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 14px; }
                .price-row:last-child { font-weight: 600; font-size: 18px; color: #10b981; border-top: 1px solid #e5e7eb; padding-top: 8px; }
                .conditions { background-color: #f3f4f6; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
                .conditions h3 { margin-bottom: 12px; font-size: 16px; color: #333; }
                .conditions ul { list-style: none; padding: 0; }
                .conditions li { margin-bottom: 6px; font-size: 14px; color: #666; }
                .signatures { display: flex; justify-content: space-between; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e5e7eb; }
                .signature-box { text-align: center; width: 45%; }
                .signature-line { border-bottom: 1px solid #333; margin-bottom: 5px; height: 40px; }
                .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e5e7eb; }
                .footer h3 { margin-bottom: 8px; font-size: 18px; color: #333; }
                .footer p { font-size: 12px; color: #666; margin-bottom: 4px; }
                .thank-you { font-weight: 600; color: #10b981; margin-top: 12px; }
              </style>
            </head>
            <body>
              <div class="ticket-container">
                <div class="header">
                  <h1>TICKET DE RACHAT</h1>
                  <div class="subtitle">${workshopSettings.name}</div>
                  <div class="contact-info">
                    Tél: ${workshopSettings.phone} • Email: ${workshopSettings.email}
                    ${workshopSettings.siret ? `<br>SIRET: ${workshopSettings.siret}` : ''}
                    ${workshopSettings.vatNumber ? ` • TVA: ${workshopSettings.vatNumber}` : ''}
                  </div>
                </div>

                <div class="buyback-details">
                  <div class="client-section">
                    <div class="section-title">Vendeur</div>
                    <div class="client-info">
                      <div class="client-name">${buyback.clientFirstName} ${buyback.clientLastName}</div>
                      <div>${buyback.clientEmail}</div>
                      <div>${buyback.clientPhone}</div>
                      ${buyback.clientAddress ? `<div>${buyback.clientAddress}</div>` : ''}
                      ${buyback.clientPostalCode && buyback.clientCity ? `<div>${buyback.clientPostalCode} ${buyback.clientCity}</div>` : ''}
                    </div>
                  </div>
                  
                  <div class="buyback-section">
                    <div class="section-title">Détails du Rachat</div>
                    <div class="buyback-info">
                      <div class="buyback-number">#${buyback.id.slice(0, 8)}</div>
                      <div><strong>Date :</strong> ${format(new Date(buyback.createdAt), 'dd/MM/yyyy', { locale: fr })}</div>
                      <div><strong>Statut :</strong> ${getStatusLabel(buyback.status)}</div>
                      <div><strong>Paiement :</strong> ${getPaymentMethodLabel(buyback.paymentMethod)}</div>
                      <div><strong>Raison :</strong> ${getBuybackReasonLabel(buyback.buybackReason)}</div>
                    </div>
                  </div>
                </div>

                <div class="device-info">
                  <h3>Appareil Racheté</h3>
                  <div class="device-details">
                    <div class="device-detail">
                      <strong>Type :</strong> ${buyback.deviceType}
                    </div>
                    <div class="device-detail">
                      <strong>Marque :</strong> ${buyback.deviceBrand}
                    </div>
                    <div class="device-detail">
                      <strong>Modèle :</strong> ${buyback.deviceModel}
                    </div>
                    <div class="device-detail">
                      <strong>IMEI :</strong> ${buyback.deviceImei || 'Non renseigné'}
                    </div>
                    <div class="device-detail">
                      <strong>Numéro de série :</strong> ${buyback.deviceSerialNumber || 'Non renseigné'}
                    </div>
                    <div class="device-detail">
                      <strong>Couleur :</strong> ${buyback.deviceColor || 'Non renseigné'}
                    </div>
                    <div class="device-detail">
                      <strong>Capacité :</strong> ${buyback.deviceStorageCapacity || 'Non renseigné'}
                    </div>
                  </div>
                </div>

                <div class="condition-info">
                  <h3>État de l'Appareil</h3>
                  <div class="condition-grid">
                    <div class="device-detail">
                      <strong>État physique :</strong> ${getConditionLabel(buyback.physicalCondition)}
                    </div>
                    <div class="device-detail">
                      <strong>Santé batterie :</strong> ${buyback.batteryHealth ? buyback.batteryHealth + '%' : 'Non renseigné'}
                    </div>
                    <div class="device-detail">
                      <strong>État écran :</strong> ${buyback.screenCondition || 'Non renseigné'}
                    </div>
                    <div class="device-detail">
                      <strong>État boutons :</strong> ${buyback.buttonCondition || 'Non renseigné'}
                    </div>
                  </div>
                  <div style="margin-top: 15px;">
                    <strong>Blocages :</strong>
                    ${buyback.icloudLocked ? '<span style="color: #ef4444;">iCloud</span>' : ''}
                    ${buyback.googleLocked ? '<span style="color: #ef4444;">Google</span>' : ''}
                    ${buyback.carrierLocked ? '<span style="color: #ef4444;">Opérateur</span>' : ''}
                    ${!buyback.icloudLocked && !buyback.googleLocked && !buyback.carrierLocked ? 'Aucun' : ''}
                  </div>
                </div>

                ${Object.values(buyback.accessories).some(v => v) ? `
                  <div class="accessories-info">
                    <h3>Accessoires Inclus</h3>
                    <div class="accessories-list">
                      ${buyback.accessories.charger ? '<span class="accessory-tag">Chargeur</span>' : ''}
                      ${buyback.accessories.cable ? '<span class="accessory-tag">Câble</span>' : ''}
                      ${buyback.accessories.headphones ? '<span class="accessory-tag">Écouteurs</span>' : ''}
                      ${buyback.accessories.originalBox ? '<span class="accessory-tag">Boîte d\'origine</span>' : ''}
                      ${buyback.accessories.screenProtector ? '<span class="accessory-tag">Protection écran</span>' : ''}
                      ${buyback.accessories.case ? '<span class="accessory-tag">Coque</span>' : ''}
                      ${buyback.accessories.manual ? '<span class="accessory-tag">Manuel</span>' : ''}
                    </div>
                  </div>
                ` : ''}

                <div class="price-section">
                  <h3>Détails Financiers</h3>
                  ${buyback.suggestedPrice ? `
                    <div class="price-row">
                      <span>Prix suggéré :</span>
                      <span>${buyback.suggestedPrice.toLocaleString('fr-FR')} €</span>
                    </div>
                  ` : ''}
                  <div class="price-row">
                    <span>Prix proposé :</span>
                    <span>${buyback.offeredPrice.toLocaleString('fr-FR')} €</span>
                  </div>
                  ${buyback.finalPrice ? `
                    <div class="price-row">
                      <span>Prix final :</span>
                      <span>${buyback.finalPrice.toLocaleString('fr-FR')} €</span>
                    </div>
                  ` : ''}
                </div>

                <div class="conditions">
                  <h3>CONDITIONS DE RACHAT</h3>
                  <ul>
                    <li>Le vendeur certifie être propriétaire légitime de l'appareil</li>
                    <li>L'appareil est vendu en l'état, sans garantie</li>
                    <li>Le paiement sera effectué selon le mode choisi</li>
                    <li>En cas de blocage découvert après le rachat, le vendeur s'engage à le résoudre</li>
                    <li>Pour toute question, contactez-nous au ${workshopSettings.phone}</li>
                  </ul>
                </div>

                <div class="signatures">
                  <div class="signature-box">
                    <div class="signature-line"></div>
                    <div>Signature du Vendeur</div>
                  </div>
                  <div class="signature-box">
                    <div class="signature-line"></div>
                    <div>Signature du Réparateur</div>
                  </div>
                </div>

                <div class="footer">
                  <h3>${workshopSettings.name}</h3>
                  <p>Tél: ${workshopSettings.phone} • Email: ${workshopSettings.email}</p>
                  ${workshopSettings.siret ? `<p>SIRET: ${workshopSettings.siret}</p>` : ''}
                  ${workshopSettings.vatNumber ? `<p>TVA: ${workshopSettings.vatNumber}</p>` : ''}
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
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6">
            Ticket de Rachat #{buyback.id.slice(0, 8)}
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
          id="buyback-ticket-content" 
          sx={{ 
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
            backgroundColor: 'white',
            p: 3
          }}
        >
          <Box sx={{ maxWidth: '800px', mx: 'auto' }}>
            
            {/* En-tête */}
            <Box sx={{ 
              textAlign: 'center', 
              mb: 5, 
              pb: 2.5, 
              borderBottom: '2px solid #10b981' 
            }}>
              <Typography variant="h4" sx={{ 
                fontWeight: 700, 
                mb: 1, 
                color: '#10b981',
                fontSize: '28px'
              }}>
                TICKET DE RACHAT
              </Typography>
              <Typography variant="h6" sx={{ 
                mb: 2, 
                color: '#666',
                fontSize: '16px'
              }}>
                {workshopSettings.name}
              </Typography>
              <Box sx={{ fontSize: '12px', color: '#666', lineHeight: 1.8 }}>
                <Typography sx={{ mb: 0.5 }}>
                  Tél: {workshopSettings.phone} • Email: {workshopSettings.email}
                </Typography>
                {workshopSettings.siret && (
                  <Typography>
                    SIRET: {workshopSettings.siret}
                  </Typography>
                )}
                {workshopSettings.vatNumber && (
                  <Typography>
                    TVA: {workshopSettings.vatNumber}
                  </Typography>
                )}
              </Box>
            </Box>
            
            {/* Détails vendeur et rachat */}
            <Box sx={{ 
              display: 'flex', 
              justifyContent: 'space-between', 
              mb: 5, 
              gap: 5 
            }}>
              
              {/* Informations vendeur */}
              <Box sx={{ flex: 1 }}>
                <Typography variant="h6" sx={{ 
                  fontWeight: 600, 
                  color: '#333', 
                  mb: 1.5, 
                  pb: 0.5, 
                  borderBottom: '1px solid #eee',
                  fontSize: '16px',
                  textTransform: 'uppercase'
                }}>
                  Vendeur
                </Typography>
                <Box>
                  <Typography sx={{ 
                    fontWeight: 600, 
                    fontSize: '14px', 
                    mb: 1, 
                    color: '#333' 
                  }}>
                    {buyback.clientFirstName} {buyback.clientLastName}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                    {buyback.clientEmail}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                    {buyback.clientPhone}
                  </Typography>
                  {buyback.clientAddress && (
                    <Typography sx={{ fontSize: '14px', color: '#666' }}>
                      {buyback.clientAddress}
                    </Typography>
                  )}
                  {buyback.clientPostalCode && buyback.clientCity && (
                    <Typography sx={{ fontSize: '14px', color: '#666' }}>
                      {buyback.clientPostalCode} {buyback.clientCity}
                    </Typography>
                  )}
                </Box>
              </Box>
              
              {/* Détails du rachat */}
              <Box sx={{ flex: 1 }}>
                <Typography variant="h6" sx={{ 
                  fontWeight: 600, 
                  color: '#333', 
                  mb: 1.5, 
                  pb: 0.5, 
                  borderBottom: '1px solid #eee',
                  fontSize: '16px',
                  textTransform: 'uppercase'
                }}>
                  Détails du Rachat
                </Typography>
                <Box>
                  <Typography sx={{ 
                    fontWeight: 600, 
                    fontSize: '18px', 
                    mb: 1, 
                    color: '#10b981' 
                  }}>
                    #{buyback.id.slice(0, 8)}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                    <strong>Date :</strong> {format(new Date(buyback.createdAt), 'dd/MM/yyyy', { locale: fr })}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                    <strong>Statut :</strong> {getStatusLabel(buyback.status)}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5, color: '#666' }}>
                    <strong>Paiement :</strong> {getPaymentMethodLabel(buyback.paymentMethod)}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', color: '#666' }}>
                    <strong>Raison :</strong> {getBuybackReasonLabel(buyback.buybackReason)}
                  </Typography>
                </Box>
              </Box>
            </Box>

            {/* Informations appareil */}
            <Paper sx={{ p: 3, mb: 3, backgroundColor: '#f8f9fa' }}>
              <Typography variant="h6" sx={{ mb: 2, color: '#333', fontSize: '18px' }}>
                Appareil Racheté
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>Type :</strong> {buyback.deviceType}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>Marque :</strong> {buyback.deviceBrand}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>Modèle :</strong> {buyback.deviceModel}
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>IMEI :</strong> {buyback.deviceImei || 'Non renseigné'}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>Numéro de série :</strong> {buyback.deviceSerialNumber || 'Non renseigné'}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>Couleur :</strong> {buyback.deviceColor || 'Non renseigné'}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>Capacité :</strong> {buyback.deviceStorageCapacity || 'Non renseigné'}
                  </Typography>
                </Grid>
              </Grid>
            </Paper>

            {/* État de l'appareil */}
            <Paper sx={{ p: 3, mb: 3, backgroundColor: '#f0f9ff' }}>
              <Typography variant="h6" sx={{ mb: 2, color: '#333', fontSize: '18px' }}>
                État de l'Appareil
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>État physique :</strong> {getConditionLabel(buyback.physicalCondition)}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>Santé batterie :</strong> {buyback.batteryHealth ? `${buyback.batteryHealth}%` : 'Non renseigné'}
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>État écran :</strong> {buyback.screenCondition || 'Non renseigné'}
                  </Typography>
                  <Typography sx={{ fontSize: '14px', mb: 0.5 }}>
                    <strong>État boutons :</strong> {buyback.buttonCondition || 'Non renseigné'}
                  </Typography>
                </Grid>
              </Grid>
              <Box sx={{ mt: 2 }}>
                <Typography sx={{ fontSize: '14px', mb: 1 }}>
                  <strong>Blocages :</strong>
                </Typography>
                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                  {buyback.icloudLocked && <Chip label="iCloud" size="small" color="error" />}
                  {buyback.googleLocked && <Chip label="Google" size="small" color="error" />}
                  {buyback.carrierLocked && <Chip label="Opérateur" size="small" color="error" />}
                  {!buyback.icloudLocked && !buyback.googleLocked && !buyback.carrierLocked && (
                    <Chip label="Aucun" size="small" color="success" />
                  )}
                </Box>
              </Box>
            </Paper>

            {/* Accessoires */}
            {Object.values(buyback.accessories).some(v => v) && (
              <Paper sx={{ p: 3, mb: 3, backgroundColor: '#f0fdf4' }}>
                <Typography variant="h6" sx={{ mb: 2, color: '#333', fontSize: '18px' }}>
                  Accessoires Inclus
                </Typography>
                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                  {buyback.accessories.charger && <Chip label="Chargeur" size="small" color="success" />}
                  {buyback.accessories.cable && <Chip label="Câble" size="small" color="success" />}
                  {buyback.accessories.headphones && <Chip label="Écouteurs" size="small" color="success" />}
                  {buyback.accessories.originalBox && <Chip label="Boîte d'origine" size="small" color="success" />}
                  {buyback.accessories.screenProtector && <Chip label="Protection écran" size="small" color="success" />}
                  {buyback.accessories.case && <Chip label="Coque" size="small" color="success" />}
                  {buyback.accessories.manual && <Chip label="Manuel" size="small" color="success" />}
                </Box>
              </Paper>
            )}

            {/* Détails financiers */}
            <Paper sx={{ p: 3, mb: 3, backgroundColor: '#fef3c7' }}>
              <Typography variant="h6" sx={{ mb: 2, color: '#333', fontSize: '18px' }}>
                Détails Financiers
              </Typography>
              {buyback.suggestedPrice && (
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography sx={{ fontSize: '14px' }}>Prix suggéré :</Typography>
                  <Typography sx={{ fontSize: '14px' }}>{buyback.suggestedPrice.toLocaleString('fr-FR')} €</Typography>
                </Box>
              )}
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography sx={{ fontSize: '14px' }}>Prix proposé :</Typography>
                <Typography sx={{ fontSize: '14px' }}>{buyback.offeredPrice.toLocaleString('fr-FR')} €</Typography>
              </Box>
              {buyback.finalPrice && (
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography sx={{ fontSize: '14px' }}>Prix final :</Typography>
                  <Typography sx={{ fontSize: '14px' }}>{buyback.finalPrice.toLocaleString('fr-FR')} €</Typography>
                </Box>
              )}
            </Paper>

            {/* Conditions */}
            <Paper sx={{ p: 3, mb: 3, backgroundColor: '#f3f4f6' }}>
              <Typography variant="h6" sx={{ mb: 2, color: '#333', fontSize: '16px' }}>
                CONDITIONS DE RACHAT
              </Typography>
              <Box component="ul" sx={{ listStyle: 'none', padding: 0, margin: 0 }}>
                <Typography component="li" sx={{ fontSize: '14px', color: '#666', mb: 1 }}>
                  • Le vendeur certifie être propriétaire légitime de l'appareil
                </Typography>
                <Typography component="li" sx={{ fontSize: '14px', color: '#666', mb: 1 }}>
                  • L'appareil est vendu en l'état, sans garantie
                </Typography>
                <Typography component="li" sx={{ fontSize: '14px', color: '#666', mb: 1 }}>
                  • Le paiement sera effectué selon le mode choisi
                </Typography>
                <Typography component="li" sx={{ fontSize: '14px', color: '#666', mb: 1 }}>
                  • En cas de blocage découvert après le rachat, le vendeur s'engage à le résoudre
                </Typography>
                <Typography component="li" sx={{ fontSize: '14px', color: '#666' }}>
                  • Pour toute question, contactez-nous au {workshopSettings.phone}
                </Typography>
              </Box>
            </Paper>

            {/* Signatures */}
            <Box sx={{ 
              display: 'flex', 
              justifyContent: 'space-between', 
              mt: 5, 
              pt: 3, 
              borderTop: '1px solid #e5e7eb' 
            }}>
              <Box sx={{ textAlign: 'center', width: '45%' }}>
                <Box sx={{ 
                  borderBottom: '1px solid #333', 
                  mb: 1, 
                  height: 40 
                }} />
                <Typography sx={{ fontSize: '12px', color: '#666' }}>
                  Signature du Vendeur
                </Typography>
              </Box>
              <Box sx={{ textAlign: 'center', width: '45%' }}>
                <Box sx={{ 
                  borderBottom: '1px solid #333', 
                  mb: 1, 
                  height: 40 
                }} />
                <Typography sx={{ fontSize: '12px', color: '#666' }}>
                  Signature du Réparateur
                </Typography>
              </Box>
            </Box>

            {/* Footer */}
            <Box sx={{ 
              textAlign: 'center', 
              mt: 5, 
              pt: 3, 
              borderTop: '1px solid #e5e7eb' 
            }}>
              <Typography variant="h6" sx={{ 
                mb: 2, 
                color: '#333', 
                fontSize: '18px' 
              }}>
                {workshopSettings.name}
              </Typography>
              <Typography sx={{ fontSize: '12px', color: '#666', mb: 1 }}>
                Tél: {workshopSettings.phone} • Email: {workshopSettings.email}
              </Typography>
              {workshopSettings.siret && (
                <Typography sx={{ fontSize: '12px', color: '#666', mb: 1 }}>
                  SIRET: {workshopSettings.siret}
                </Typography>
              )}
              {workshopSettings.vatNumber && (
                <Typography sx={{ fontSize: '12px', color: '#666', mb: 1 }}>
                  TVA: {workshopSettings.vatNumber}
                </Typography>
              )}
              <Typography sx={{ 
                fontWeight: 600, 
                color: '#10b981', 
                mt: 2,
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

export default BuybackTicket;
