import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Grid,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Divider,
  IconButton,
  Tooltip,
  Alert,
} from '@mui/material';
import {
  Close as CloseIcon,
  Print as PrintIcon,
  Send as SendIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  Schedule as ScheduleIcon,
  Warning as WarningIcon,
  Description as DescriptionIcon,
  Person as PersonIcon,
  CalendarToday as CalendarTodayIcon,
  MonetizationOn as MonetizationOnIcon,
  Euro as EuroIcon,
  AttachMoney as AttachMoneyIcon,
  Email as EmailIcon,
} from '@mui/icons-material';
import { format, addDays } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Quote, Client, Repair } from '../../types';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatQuoteNumber } from '../../utils/quoteUtils';

interface QuoteViewProps {
  open: boolean;
  onClose: () => void;
  quote: Quote | null;
  client: Client | null;
  onStatusChange: (quoteId: string, newStatus: Quote['status']) => void;
}

const QuoteView: React.FC<QuoteViewProps> = ({
  open,
  onClose,
  quote,
  client,
  onStatusChange,
}) => {
  const { addRepair, repairStatuses } = useAppStore();
  const { workshopSettings, isLoading: settingsLoading } = useWorkshopSettings();
  
  if (!quote) return null;

  const isExpired = new Date(quote.validUntil) < new Date();

  const getStatusLabel = (status: string) => {
    const labels = {
      draft: 'Brouillon',
      sent: 'Envoyé',
      accepted: 'Accepté',
      rejected: 'Refusé',
      expired: 'Expiré',
    };
    return labels[status as keyof typeof labels] || status;
  };

  const getStatusColor = (status: string) => {
    const colors = {
      draft: 'default',
      sent: 'primary',
      accepted: 'success',
      rejected: 'error',
      expired: 'warning',
    };
    return colors[status as keyof typeof colors] || 'default';
  };

  const handleStatusChange = async (newStatus: Quote['status']) => {
    // Si le devis est accepté, demander confirmation et créer une réparation
    if (newStatus === 'accepted') {
      const confirmed = window.confirm(
        `Êtes-vous sûr de vouloir accepter ce devis ?\n\n` +
        `✅ Le devis passera en statut "Accepté"\n` +
        `🔧 Une nouvelle réparation sera créée automatiquement\n` +
        `📋 La réparation apparaîtra dans le suivi avec le statut "Nouvelle"\n\n` +
        `Continuer ?`
      );
      
      if (!confirmed) {
        return;
      }
      
      try {
        await convertQuoteToRepair();
      } catch (error) {
        console.error('Erreur lors de la conversion en réparation:', error);
        alert('❌ Erreur lors de la création de la réparation. Veuillez réessayer.');
        return;
      }
    }
    
    // Mettre à jour le statut du devis
    onStatusChange(quote.id, newStatus);
  };

  const handleValidateQuote = async () => {
    // Validation directe d'un devis sans envoi d'email
    const confirmed = window.confirm(
      `Êtes-vous sûr de vouloir valider ce devis ?\n\n` +
      `✅ Le devis passera en statut "Accepté"\n` +
      `🔧 Une nouvelle réparation sera créée automatiquement\n` +
      `📋 La réparation apparaîtra dans le suivi avec le statut "Nouvelle"\n` +
      `📧 Aucun email ne sera envoyé\n\n` +
      `Continuer ?`
    );
    
    if (!confirmed) {
      return;
    }
    
    try {
      await convertQuoteToRepair();
      // Mettre à jour le statut du devis
      onStatusChange(quote.id, 'accepted');
      alert('✅ Devis validé avec succès ! Une réparation a été créée automatiquement.');
    } catch (error) {
      console.error('Erreur lors de la validation du devis:', error);
      alert('❌ Erreur lors de la validation du devis. Veuillez réessayer.');
    }
  };

  const handleRejectQuote = async () => {
    // Refus direct d'un devis sans envoi d'email
    const confirmed = window.confirm(
      `Êtes-vous sûr de vouloir refuser ce devis ?\n\n` +
      `❌ Le devis passera en statut "Refusé"\n` +
      `📋 Aucune réparation ne sera créée\n` +
      `📧 Aucun email ne sera envoyé\n\n` +
      `Continuer ?`
    );
    
    if (!confirmed) {
      return;
    }
    
    try {
      // Mettre à jour le statut du devis
      onStatusChange(quote.id, 'rejected');
      alert('❌ Devis refusé avec succès !');
    } catch (error) {
      console.error('Erreur lors du refus du devis:', error);
      alert('❌ Erreur lors du refus du devis. Veuillez réessayer.');
    }
  };

  const convertQuoteToRepair = async () => {
    if (!client) {
      alert('❌ Impossible de créer la réparation : client non trouvé.');
      return;
    }

    // Trouver le statut "Nouvelle" pour les réparations
    const newStatus = repairStatuses.find(status => 
      status.name.toLowerCase().includes('nouvelle') || 
      status.name.toLowerCase().includes('new') ||
      status.order === 1
    );

    if (!newStatus) {
      alert('❌ Impossible de créer la réparation : statut "Nouvelle" non trouvé.');
      return;
    }

    // Convertir les articles du devis en services et pièces
    const services: any[] = [];
    const parts: any[] = [];
    
    quote.items.forEach((item, index) => {
      if (item.type === 'service') {
        services.push({
          id: `temp_${index}`,
          serviceId: item.itemId,
          quantity: item.quantity,
          price: item.unitPrice,
        });
      } else if (item.type === 'part') {
        parts.push({
          id: `temp_${index}`,
          partId: item.itemId,
          quantity: item.quantity,
          price: item.unitPrice,
          isUsed: false,
        });
      }
    });

    // Créer la réparation à partir du devis
    const repairData: Repair = {
      id: '', // Sera généré par le backend
      clientId: client.id,
      deviceId: quote.repairDetails?.deviceId || null, // Utiliser null si aucun appareil
      status: newStatus.id,
      description: quote.repairDetails?.description || quote.notes || 'Réparation basée sur devis accepté',
      issue: quote.repairDetails?.issue || 'Réparation demandée',
      estimatedDuration: quote.repairDetails?.estimatedDuration || 120, // 2h par défaut
      estimatedStartDate: quote.repairDetails?.estimatedStartDate || new Date(),
      estimatedEndDate: quote.repairDetails?.estimatedEndDate || addDays(new Date(), 7),
      dueDate: addDays(new Date(), 7), // Échéance dans 7 jours
      isUrgent: quote.repairDetails?.isUrgent || false,
      notes: `Devis accepté ${formatQuoteNumber(quote.quoteNumber)} - ${quote.notes || ''}`,
      services: services,
      parts: parts,
      totalPrice: quote.total,
      isPaid: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    try {
      await addRepair(repairData);
      alert(`✅ Réparation créée avec succès !\n\nLa réparation a été ajoutée au suivi avec le statut "${newStatus.name}".\n\nVous pouvez maintenant la gérer depuis la page de suivi des réparations.`);
    } catch (error) {
      console.error('Erreur lors de la création de la réparation:', error);
      throw error;
    }
  };

  const handleSendEmail = () => {
    if (!client?.email) {
      alert('❌ Aucune adresse email disponible pour ce client.');
      return;
    }

    // Créer le sujet de l'email
    const subject = `Devis ${formatQuoteNumber(quote.quoteNumber)} - Mon Atelier`;

    // Créer le contenu de l'email avec un template professionnel
    const emailBody = `Bonjour ${client.firstName} ${client.lastName},

Nous avons le plaisir de vous transmettre notre devis pour les services demandés.

📋 DÉTAILS DU DEVIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Numéro de devis : ${formatQuoteNumber(quote.quoteNumber)}
• Date de création : ${format(new Date(quote.createdAt), 'dd/MM/yyyy', { locale: fr })}
• Validité : jusqu'au ${format(new Date(quote.validUntil), 'dd/MM/yyyy', { locale: fr })}
• Montant total : ${quote.total.toLocaleString('fr-FR')} €

${quote.items.length > 0 ? `
📦 ARTICLES INCLUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${quote.items.map(item => `• ${item.name} - ${item.quantity}x ${item.unitPrice.toLocaleString('fr-FR')}€ = ${item.totalPrice.toLocaleString('fr-FR')}€`).join('\n')}
` : ''}

${quote.notes ? `
📝 NOTES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${quote.notes}
` : ''}

${quote.terms ? `
📋 CONDITIONS ET TERMES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${quote.terms}
` : ''}

💡 PROCHAINES ÉTAPES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pour accepter ce devis, vous pouvez :
• Répondre à cet email avec "J'accepte"
• Nous appeler au 01 23 45 67 89
• Nous contacter via notre site web

❓ QUESTIONS ?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pour toute question concernant ce devis, n'hésitez pas à nous contacter.

Cordialement,
L'équipe Mon Atelier
📧 contact@monatelier.fr
📞 01 23 45 67 89
🌐 www.monatelier.fr`;

    // Encoder l'email pour l'URL
    const encodedSubject = encodeURIComponent(subject);
    const encodedBody = encodeURIComponent(emailBody);

    // Créer l'URL mailto
    const mailtoUrl = `mailto:${client.email}?subject=${encodedSubject}&body=${encodedBody}`;

    // Ouvrir l'email dans le client par défaut
    window.open(mailtoUrl, '_blank');

    // Mettre à jour le statut du devis
    if (quote.status === 'draft') {
      handleStatusChange('sent');
    }
  };

  const handlePrint = () => {
    const printContent = document.getElementById('quote-content');
    if (printContent) {
      const printWindow = window.open('', '_blank');
      if (printWindow) {
        printWindow.document.write(`
          <!DOCTYPE html>
          <html>
            <head>
              <title>Devis ${formatQuoteNumber(quote.quoteNumber)}</title>
              <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
                  margin: 0; padding: 24px; background: white; color: #333; line-height: 1.6;
                }
                .quote-container { max-width: 800px; margin: 0 auto; background: white; }
                .header { text-align: center; margin-bottom: 40px; padding-bottom: 20px; border-bottom: 1px solid #eee; }
                .header h1 { font-size: 24px; font-weight: 600; margin: 0 0 8px 0; color: #333; }
                .header .subtitle { font-size: 14px; color: #666; margin-bottom: 16px; }
                .header .contact-info { font-size: 12px; color: #666; line-height: 1.8; }
                .quote-details { display: flex; justify-content: space-between; margin-bottom: 40px; }
                .client-section, .quote-section { flex: 1; }
                .section-title { font-weight: 600; margin-bottom: 12px; color: #333; font-size: 14px; }
                .client-info, .quote-info { font-size: 14px; color: #666; line-height: 1.6; }
                .client-name { font-weight: 600; color: #333; margin-bottom: 8px; }
                .quote-number { font-weight: 600; color: #1976d2; font-size: 16px; margin-bottom: 8px; }
                table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
                th { background-color: #f8f9fa; padding: 12px; text-align: left; font-weight: 600; color: #333; border-bottom: 1px solid #eee; }
                td { padding: 12px; border-bottom: 1px solid #f1f1f1; }
                .totals-section { margin-bottom: 30px; }
                .total-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 14px; }
                .total-row:last-child { font-weight: 600; font-size: 16px; color: #1976d2; border-top: 1px solid #eee; padding-top: 8px; }
                .conditions { background-color: #f8f9fa; padding: 20px; border-radius: 4px; margin-bottom: 30px; }
                .conditions h3 { margin-bottom: 12px; font-size: 16px; color: #333; }
                .conditions p { font-size: 14px; color: #666; line-height: 1.6; }
                .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; }
                .footer h3 { margin-bottom: 8px; font-size: 18px; color: #333; }
                .footer p { font-size: 12px; color: #666; margin-bottom: 4px; }
                .thank-you { font-weight: 600; color: #1976d2; margin-top: 12px; }
              </style>
            </head>
            <body>
              <div class="quote-container">
                <div class="header">
                  <h1>DEVIS</h1>
                  <div class="subtitle">Mon Atelier - Réparation et Vente</div>
                  <div class="contact-info">
                    Tél: +33 1 23 45 67 89 • Email: contact@monatelier.fr<br>
                    Adresse: 123 Rue de la Réparation, 75001 Paris
                  </div>
                </div>

                <div class="quote-details">
                  <div class="client-section">
                    <div class="section-title">DEVISÉ À</div>
                    <div class="client-info">
                      ${client ? `
                        <div class="client-name">${client.firstName} ${client.lastName}</div>
                        <div>${client.email}</div>
                        <div>${client.phone}</div>
                        ${client.address ? `<div>${client.address}</div>` : ''}
                      ` : '<div>Client anonyme</div>'}
                    </div>
                  </div>
                  
                  <div class="quote-section">
                    <div class="section-title">DÉTAILS DU DEVIS</div>
                    <div class="quote-info">
                      <div class="quote-number">${formatQuoteNumber(quote.quoteNumber)}</div>
                      <div><strong>Date :</strong> ${format(new Date(quote.createdAt), 'dd/MM/yyyy', { locale: fr })}</div>
                      <div><strong>Validité :</strong> ${format(new Date(quote.validUntil), 'dd/MM/yyyy', { locale: fr })}</div>
                      <div><strong>Statut :</strong> ${getStatusLabel(quote.status)}</div>
                    </div>
                  </div>
                </div>

                <table>
                  <thead>
                    <tr>
                      <th>Article</th>
                      <th>Description</th>
                      <th>Quantité</th>
                      <th>Prix unitaire</th>
                      <th>Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${quote.items.map(item => `
                      <tr>
                        <td>${item.name}${item.type === 'repair' ? ' <span style="color: #1976d2; font-weight: 500;">(Réparation)</span>' : ''}</td>
                        <td>${item.description || '-'}</td>
                        <td>${item.quantity}</td>
                        <td>${item.unitPrice.toLocaleString('fr-FR')} €</td>
                        <td>${item.totalPrice.toLocaleString('fr-FR')} €</td>
                      </tr>
                    `).join('')}
                  </tbody>
                </table>

                <div class="totals-section">
                  <div class="total-row">
                    <span>Sous-total :</span>
                    <span>${quote.subtotal.toLocaleString('fr-FR')} €</span>
                  </div>
                  <div class="total-row">
                    <span>TVA (${settingsLoading ? '...' : workshopSettings.vatRate}%) :</span>
                    <span>${quote.tax.toLocaleString('fr-FR')} €</span>
                  </div>
                  <div class="total-row">
                    <span>Total :</span>
                    <span>${quote.total.toLocaleString('fr-FR')} €</span>
                  </div>
                </div>

                ${quote.notes ? `
                  <div class="conditions">
                    <h3>Notes</h3>
                    <p>${quote.notes}</p>
                  </div>
                ` : ''}

                ${quote.terms ? `
                  <div class="conditions">
                    <h3>Conditions et termes</h3>
                    <p>${quote.terms}</p>
                  </div>
                ` : ''}

                <div class="footer">
                  <h3>Merci de votre confiance</h3>
                  <p>Ce devis est valable jusqu'au ${format(new Date(quote.validUntil), 'dd/MM/yyyy', { locale: fr })}</p>
                  <p>Pour toute question, n'hésitez pas à nous contacter</p>
                  <div class="thank-you">Mon Atelier</div>
                </div>
              </div>
            </body>
          </html>
        `);
        printWindow.document.close();
        printWindow.print();
      }
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <DescriptionIcon sx={{ color: '#1976d2' }} />
                            <Typography variant="h6">Devis {formatQuoteNumber(quote.quoteNumber)}</Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Tooltip title="Imprimer">
              <IconButton onClick={handlePrint} sx={{ color: '#1976d2' }}>
                <PrintIcon />
              </IconButton>
            </Tooltip>
            <IconButton onClick={onClose}>
              <CloseIcon />
            </IconButton>
          </Box>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <div id="quote-content">
          {/* Alert pour devis expiré */}
          {isExpired && (
            <Alert severity="warning" sx={{ mb: 3 }}>
              <Typography variant="body2">
                <strong>Attention :</strong> Ce devis a expiré le {format(new Date(quote.validUntil), 'dd/MM/yyyy', { locale: fr })}.
              </Typography>
            </Alert>
          )}

          {/* Informations générales */}
          <Grid container spacing={3} sx={{ mb: 3 }}>
            <Grid item xs={12} md={6}>
              <Box sx={{ p: 2, border: '1px solid #e0e0e0', borderRadius: 1 }}>
                <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <PersonIcon sx={{ fontSize: '20px' }} />
                  Client
                </Typography>
                {client ? (
                  <Box>
                    <Typography variant="body1" sx={{ fontWeight: 500 }}>
                      {client.firstName} {client.lastName}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {client.email}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {client.phone}
                    </Typography>
                    {client.address && (
                      <Typography variant="body2" color="text.secondary">
                        {client.address}
                      </Typography>
                    )}
                  </Box>
                ) : (
                  <Typography variant="body2" color="text.secondary">
                    Client anonyme
                  </Typography>
                )}
              </Box>
            </Grid>
            
            <Grid item xs={12} md={6}>
              <Box sx={{ p: 2, border: '1px solid #e0e0e0', borderRadius: 1 }}>
                <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <DescriptionIcon sx={{ fontSize: '20px' }} />
                  Détails du devis
                </Typography>
                <Box>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    N° Devis : {formatQuoteNumber(quote.quoteNumber)}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Date : {format(new Date(quote.createdAt), 'dd/MM/yyyy', { locale: fr })}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Validité : {format(new Date(quote.validUntil), 'dd/MM/yyyy', { locale: fr })}
                  </Typography>
                  <Box sx={{ mt: 1 }}>
                    <Chip
                      label={getStatusLabel(quote.status)}
                      color={getStatusColor(quote.status) as any}
                      size="small"
                      variant={quote.status === 'draft' ? 'outlined' : 'filled'}
                    />
                  </Box>
                </Box>
              </Box>
            </Grid>
          </Grid>

          {/* Articles */}
          <Typography variant="h6" gutterBottom>
            Articles du devis
          </Typography>
          
          <TableContainer component={Paper} variant="outlined" sx={{ mb: 3 }}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Article</TableCell>
                  <TableCell>Description</TableCell>
                  <TableCell align="center">Quantité</TableCell>
                  <TableCell align="right">Prix unitaire</TableCell>
                  <TableCell align="right">Total</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {quote.items.map((item) => (
                  <TableRow key={item.id}>
                                         <TableCell>
                       <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                         <Typography variant="body2" sx={{ fontWeight: 500 }}>
                           {item.name}
                         </Typography>
                         {item.type === 'repair' && (
                           <Chip 
                             label="Réparation" 
                             size="small" 
                             color="primary" 
                             variant="outlined"
                           />
                         )}
                       </Box>
                     </TableCell>
                    <TableCell>
                      <Typography variant="body2" color="text.secondary">
                        {item.description || '-'}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Typography variant="body2">
                        {item.quantity}
                      </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2">
                        {item.unitPrice.toLocaleString('fr-FR')} €
                      </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2" sx={{ fontWeight: 500 }}>
                        {item.totalPrice.toLocaleString('fr-FR')} €
                      </Typography>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>

          {/* Totaux */}
          <Box sx={{ 
            display: 'flex', 
            justifyContent: 'flex-end', 
            border: '1px solid #e0e0e0', 
            borderRadius: 1, 
            p: 2,
            backgroundColor: '#fafafa',
            mb: 3
          }}>
            <Box sx={{ textAlign: 'right' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
                <Typography variant="body2">Sous-total :</Typography>
                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                  {quote.subtotal.toLocaleString('fr-FR')} €
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
                <Typography variant="body2">
                  TVA ({settingsLoading ? '...' : workshopSettings.vatRate}%) :
                </Typography>
                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                  {quote.tax.toLocaleString('fr-FR')} €
                </Typography>
              </Box>
              <Divider sx={{ my: 1 }} />
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Total :
                </Typography>
                <Typography variant="h6" sx={{ fontWeight: 600, color: '#1976d2' }}>
                  {quote.total.toLocaleString('fr-FR')} €
                </Typography>
              </Box>
            </Box>
          </Box>

          {/* Notes et conditions */}
          {(quote.notes || quote.terms) && (
            <Grid container spacing={2} sx={{ mb: 3 }}>
              {quote.notes && (
                <Grid item xs={12} md={6}>
                  <Box sx={{ p: 2, border: '1px solid #e0e0e0', borderRadius: 1 }}>
                    <Typography variant="h6" gutterBottom>
                      Notes
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {quote.notes}
                    </Typography>
                  </Box>
                </Grid>
              )}
              {quote.terms && (
                <Grid item xs={12} md={6}>
                  <Box sx={{ p: 2, border: '1px solid #e0e0e0', borderRadius: 1 }}>
                    <Typography variant="h6" gutterBottom>
                      Conditions et termes
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {quote.terms}
                    </Typography>
                  </Box>
                </Grid>
              )}
            </Grid>
          )}
        </div>
      </DialogContent>
      
      <DialogActions sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          {quote.status === 'draft' && (
            <>
              <Button
                variant="contained"
                color="success"
                startIcon={<CheckCircleIcon />}
                onClick={handleValidateQuote}
              >
                Valider le devis
              </Button>
              <Button
                variant="contained"
                color="error"
                startIcon={<CancelIcon />}
                onClick={handleRejectQuote}
              >
                Refuser le devis
              </Button>
              <Button
                variant="outlined"
                startIcon={<EmailIcon />}
                onClick={handleSendEmail}
                disabled={!client?.email}
              >
                Envoyer par email
              </Button>
            </>
          )}
          
          {quote.status === 'sent' && (
            <>
              <Button
                variant="contained"
                color="success"
                startIcon={<CheckCircleIcon />}
                onClick={handleValidateQuote}
              >
                Valider le devis
              </Button>
              <Button
                variant="contained"
                color="error"
                startIcon={<CancelIcon />}
                onClick={handleRejectQuote}
              >
                Refuser le devis
              </Button>
              <Button
                variant="outlined"
                startIcon={<EmailIcon />}
                onClick={handleSendEmail}
                disabled={!client?.email}
              >
                Renvoyer par email
              </Button>
            </>
          )}
          
          <Button onClick={onClose} variant="outlined">
            Fermer
          </Button>
        </Box>
      </DialogActions>
    </Dialog>
  );
};

export default QuoteView;
