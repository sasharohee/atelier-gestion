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
  Alert,
} from '@mui/material';
import {
  Close as CloseIcon,
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
import { jsPDF } from 'jspdf';
import { Quote, Client, Repair } from '../../types';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatQuoteNumber } from '../../utils/quoteUtils';
import { formatFromEUR } from '../../utils/currencyUtils';

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
  
  // Normaliser les items du devis (au cas où ils viennent de JSONB non parsé)
  const normalizeQuoteItems = (items: any): any[] => {
    if (!items) return [];
    if (Array.isArray(items)) return items;
    if (typeof items === 'string') {
      try {
        const parsed = JSON.parse(items);
        return Array.isArray(parsed) ? parsed : [];
      } catch {
        return [];
      }
    }
    return [];
  };

  // Normaliser les items (doit être appelé avant le return conditionnel pour respecter les règles des Hooks)
  const quoteItems = quote ? normalizeQuoteItems(quote.items) : [];

  // Log de débogage (à retirer en production) - doit être avant le return conditionnel
  React.useEffect(() => {
    if (quote && quoteItems.length === 0 && quote.total > 0) {
      console.warn('⚠️ Devis avec total mais sans articles:', {
        quoteId: quote.id,
        items: quote.items,
        itemsType: typeof quote.items,
        isArray: Array.isArray(quote.items),
        total: quote.total,
        subtotal: quote.subtotal
      });
    }
  }, [quote, quoteItems]);

  if (!quote) return null;

  const isExpired = new Date(quote.validUntil) < new Date();

  // Fonctions utilitaires pour la génération PDF
  const sanitizeString = (value?: string, fallback = '') => {
    const base = value ?? '';
    const trimmed = base.trim();
    return trimmed.length > 0 ? trimmed : fallback;
  };

  const formatAddressForPdf = (address: string) => {
    if (!address) {
      return '';
    }
    return address
      .split(/\r?\n/)
      .map(line => line.trim())
      .filter(Boolean)
      .join('\n');
  };

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
    
    quoteItems.forEach((item, index) => {
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

  // Fonction pour générer et télécharger le PDF du devis
  const generateAndDownloadQuotePDF = (): void => {
    try {
      const doc = new jsPDF();
      const pageWidth = doc.internal.pageSize.getWidth();
      const pageHeight = doc.internal.pageSize.getHeight();
      const margin = 15;
      let yPosition = margin;

      // Informations de l'atelier
      const workshopName = sanitizeString(workshopSettings?.name, 'Atelier de Réparation');
      const workshopAddress = formatAddressForPdf(
        sanitizeString(workshopSettings?.address, '123 Rue de la Paix\n75001 Paris, France')
      );
      const workshopPhone = sanitizeString(workshopSettings?.phone, '07 59 23 91 70');
      const workshopEmail = sanitizeString(workshopSettings?.email, 'contact.ateliergestion@gmail.com');

      // Informations du client
      const clientName = client ? `${client.firstName} ${client.lastName}` : 'Client anonyme';
      const clientEmail = client?.email || '';
      const clientPhone = client?.phone || '';

      // En-tête - identique au HTML
      doc.setFontSize(28);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(255, 152, 0); // Orange #ff9800
      doc.text('DEVIS', pageWidth / 2, yPosition, { align: 'center' });
      yPosition += 10;

      doc.setFontSize(16);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(100, 100, 100); // Gris #666
      doc.text(`N° ${formatQuoteNumber(quote.quoteNumber)}`, pageWidth / 2, yPosition, { align: 'center' });
      yPosition += 20;

      // Ligne séparatrice orange (border-bottom comme dans le HTML) - 2px comme dans le CSS
      doc.setDrawColor(255, 152, 0);
      doc.setLineWidth(2);
      doc.line(margin, yPosition, pageWidth - margin, yPosition);
      yPosition += 20; // Espacement après la ligne

      // Informations atelier et client - layout identique au HTML (45% chaque côté)
      const infoStartY = yPosition;
      
      // Atelier (gauche)
      doc.setFontSize(18);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(0, 0, 0);
      doc.text(workshopName, margin, yPosition);
      yPosition += 7;
      doc.setFontSize(14);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(100, 100, 100);
      const addressLines = workshopAddress.split('\n');
      addressLines.forEach(line => {
        if (line.trim()) {
          doc.text(line, margin, yPosition);
          yPosition += 5;
        }
      });
      doc.text(`Tél: ${workshopPhone}`, margin, yPosition);
      yPosition += 5;
      doc.text(`Email: ${workshopEmail}`, margin, yPosition);
      
      // Client (droite) - aligner au même niveau que l'atelier
      const clientStartY = infoStartY;
      let clientY = clientStartY;
      doc.setFontSize(18);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(0, 0, 0);
      doc.text('Devis pour', pageWidth - margin, clientY, { align: 'right' });
      clientY += 7;
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text(clientName, pageWidth - margin, clientY, { align: 'right' });
      clientY += 5;
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(100, 100, 100);
      if (clientEmail) {
        doc.text(`Email: ${clientEmail}`, pageWidth - margin, clientY, { align: 'right' });
        clientY += 5;
      }
      if (clientPhone) {
        doc.text(`Tél: ${clientPhone}`, pageWidth - margin, clientY, { align: 'right' });
        clientY += 5;
      }

      // Validité du devis - barre orange avec fond clair (comme validity-info dans HTML)
      yPosition = Math.max(yPosition, clientY) + 15;
      const validityBarHeight = 15;
      const validityBarY = yPosition;
      // Fond orange clair
      doc.setFillColor(255, 243, 224); // #fff3e0 - fond orange clair
      doc.setDrawColor(255, 152, 0); // Bordure orange
      doc.setLineWidth(1);
      // Rectangle avec coins arrondis simulés (jsPDF ne supporte pas roundedRect directement)
      doc.rect(margin, validityBarY, pageWidth - 2 * margin, validityBarHeight, 'FD');
      doc.setFontSize(9);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(0, 0, 0);
      doc.text(
        `Validité du devis : ${format(new Date(quote.validUntil), 'dd/MM/yyyy', { locale: fr })}`,
        pageWidth / 2,
        validityBarY + validityBarHeight / 2 + 2,
        { align: 'center' }
      );
      yPosition += validityBarHeight + 10;

      // Tableau des articles
      // Utiliser les items normalisés
      const pdfQuoteItems = normalizeQuoteItems(quote.items);
      const hasItems = pdfQuoteItems.length > 0;

      if (hasItems) {
        yPosition += 5;
        // Largeurs de colonnes équilibrées pour correspondre au HTML
        const colWidths = [
          (pageWidth - 2 * margin) * 0.20, // Article
          (pageWidth - 2 * margin) * 0.35, // Description
          (pageWidth - 2 * margin) * 0.12, // Quantité
          (pageWidth - 2 * margin) * 0.16, // Prix unitaire
          (pageWidth - 2 * margin) * 0.17, // Total
        ];
        const colX = [margin, margin + colWidths[0], margin + colWidths[0] + colWidths[1], 
                      margin + colWidths[0] + colWidths[1] + colWidths[2],
                      margin + colWidths[0] + colWidths[1] + colWidths[2] + colWidths[3]];

        // En-tête du tableau avec bordures plus visibles
        doc.setFontSize(9);
        doc.setFont('helvetica', 'bold');
        doc.setFillColor(245, 245, 245);
        doc.setDrawColor(150, 150, 150); // Bordures plus visibles
        doc.setLineWidth(0.3);
        // Rectangle principal de l'en-tête
        doc.rect(margin, yPosition, pageWidth - 2 * margin, 8, 'FD'); // FD = Fill + Draw
        // Bordures verticales pour séparer les colonnes
        doc.line(colX[1], yPosition, colX[1], yPosition + 8); // Entre Article et Description
        doc.line(colX[2], yPosition, colX[2], yPosition + 8); // Entre Description et Qté
        doc.line(colX[3], yPosition, colX[3], yPosition + 8); // Entre Qté et Prix unit.
        doc.line(colX[4], yPosition, colX[4], yPosition + 8); // Entre Prix unit. et Total
        doc.setTextColor(0, 0, 0);
        doc.text('Article', colX[0] + 2, yPosition + 6);
        doc.text('Description', colX[1] + 2, yPosition + 6);
        doc.text('Quantité', colX[2] + colWidths[2] / 2, yPosition + 6, { align: 'center' });
        doc.text('Prix unitaire', colX[3] + colWidths[3] - 2, yPosition + 6, { align: 'right' });
        doc.text('Total', colX[4] + colWidths[4] - 2, yPosition + 6, { align: 'right' });
        yPosition += 8;

        // Lignes du tableau
        doc.setFont('helvetica', 'normal');
        doc.setFontSize(8);
        doc.setTextColor(0, 0, 0);
        doc.setDrawColor(180, 180, 180); // Bordures plus visibles que 200,200,200
        doc.setLineWidth(0.2);
        
        pdfQuoteItems.forEach((item, index) => {
          // Vérifier si on doit ajouter une nouvelle page
          if (yPosition > pageHeight - 50) {
            doc.addPage();
            yPosition = margin;
            // Réafficher l'en-tête du tableau sur la nouvelle page
            doc.setFontSize(9);
            doc.setFont('helvetica', 'bold');
            doc.setFillColor(245, 245, 245);
            doc.setDrawColor(150, 150, 150);
            doc.setLineWidth(0.3);
            doc.rect(margin, yPosition, pageWidth - 2 * margin, 8, 'FD');
            // Bordures verticales pour séparer les colonnes
            doc.line(colX[1], yPosition, colX[1], yPosition + 8);
            doc.line(colX[2], yPosition, colX[2], yPosition + 8);
            doc.line(colX[3], yPosition, colX[3], yPosition + 8);
            doc.line(colX[4], yPosition, colX[4], yPosition + 8);
            doc.setTextColor(0, 0, 0);
            doc.text('Article', colX[0] + 2, yPosition + 6);
            doc.text('Description', colX[1] + 2, yPosition + 6);
            doc.text('Quantité', colX[2] + colWidths[2] / 2, yPosition + 6, { align: 'center' });
            doc.text('Prix unitaire', colX[3] + colWidths[3] - 2, yPosition + 6, { align: 'right' });
            doc.text('Total', colX[4] + colWidths[4] - 2, yPosition + 6, { align: 'right' });
            yPosition += 8;
            doc.setFont('helvetica', 'normal');
            doc.setFontSize(8);
            doc.setDrawColor(220, 220, 220);
            doc.setLineWidth(0.2);
          }

          // Calculer la hauteur de ligne en fonction du contenu (description peut être sur plusieurs lignes)
          const descriptionText = item.description || '-';
          const descriptionLines = doc.splitTextToSize(descriptionText, colWidths[1] - 4);
          const itemNameLines = doc.splitTextToSize(item.name || 'Article', colWidths[0] - 4);
          const maxLines = Math.max(descriptionLines.length, itemNameLines.length, 1);
          const rowHeight = Math.max(8, maxLines * 4.5);
          
          // Fond alterné pour les lignes paires (comme tr:nth-child(even) dans le HTML - #f9f9f9)
          if (index % 2 === 1) {
            doc.setFillColor(249, 249, 249);
            doc.rect(margin, yPosition, pageWidth - 2 * margin, rowHeight, 'F');
          }
          
          // Dessiner la bordure de la ligne avec séparateurs verticaux
          doc.setDrawColor(220, 220, 220); // #ddd comme dans le HTML
          doc.setLineWidth(0.2);
          doc.rect(margin, yPosition, pageWidth - 2 * margin, rowHeight, 'S');
          // Bordures verticales pour séparer les colonnes
          doc.line(colX[1], yPosition, colX[1], yPosition + rowHeight); // Entre Article et Description
          doc.line(colX[2], yPosition, colX[2], yPosition + rowHeight); // Entre Description et Quantité
          doc.line(colX[3], yPosition, colX[3], yPosition + rowHeight); // Entre Quantité et Prix unitaire
          doc.line(colX[4], yPosition, colX[4], yPosition + rowHeight); // Entre Prix unitaire et Total

          // Article (peut être sur plusieurs lignes)
          let itemY = yPosition + 4;
          itemNameLines.forEach((line: string, idx: number) => {
            if (itemY + 4 <= yPosition + rowHeight) {
              doc.text(line, colX[0] + 2, itemY);
              itemY += 4.5;
            }
          });
          
          // Description (sur plusieurs lignes si nécessaire)
          let descY = yPosition + 4;
          descriptionLines.forEach((line: string) => {
            if (descY + 4 <= yPosition + rowHeight) {
              doc.text(line, colX[1] + 2, descY);
              descY += 4.5;
            }
          });
          
          // Quantité (centré verticalement)
          const qtyY = yPosition + (rowHeight / 2) + 2;
          doc.text(String(item.quantity || 1), colX[2] + colWidths[2] / 2, qtyY, { align: 'center' });
          
          // Prix unitaire (aligné à droite, centré verticalement)
          const priceY = yPosition + (rowHeight / 2) + 2;
          doc.text(formatFromEUR(item.unitPrice || 0, workshopSettings.currency), colX[3] + colWidths[3] - 2, priceY, { align: 'right' });
          
          // Total (aligné à droite, centré verticalement) - une seule fois
          const totalY = yPosition + (rowHeight / 2) + 2;
          doc.setTextColor(0, 0, 0); // S'assurer que la couleur est noire
          doc.text(formatFromEUR(item.totalPrice || 0, workshopSettings.currency), colX[4] + colWidths[4] - 2, totalY, { align: 'right' });

          yPosition += rowHeight;
        });
      } else {
        // Si pas d'articles - afficher un message centré comme dans le HTML
        doc.setFontSize(9);
        doc.setFont('helvetica', 'normal');
        doc.setTextColor(100, 100, 100); // #666 comme dans le HTML
        // Dessiner une ligne de tableau vide
        doc.setDrawColor(220, 220, 220); // #ddd
        doc.setLineWidth(0.2);
        doc.rect(margin, yPosition, pageWidth - 2 * margin, 10, 'S');
        doc.text('Aucun article dans ce devis', pageWidth / 2, yPosition + 6, { align: 'center' });
        yPosition += 12;
      }

      // Totaux - alignés à droite comme dans le HTML (totals class)
      yPosition += 10;
      // Largeur des totaux comme dans le HTML (300px = environ 80mm)
      const totalsWidth = 80;
      const totalsX = pageWidth - margin - totalsWidth;
      
      doc.setFontSize(9);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(0, 0, 0);
      // Sous-total HT
      doc.text('Sous-total HT:', totalsX, yPosition, { align: 'right' });
      doc.text(formatFromEUR(quote.subtotal || 0, workshopSettings.currency), pageWidth - margin, yPosition, { align: 'right' });
      yPosition += 6;
      // TVA
      doc.text(`TVA (${workshopSettings?.vatRate || 20}%):`, totalsX, yPosition, { align: 'right' });
      doc.text(formatFromEUR(quote.tax || 0, workshopSettings.currency), pageWidth - margin, yPosition, { align: 'right' });
      yPosition += 10;
      // TOTAL TTC - ligne orange au-dessus, puis texte en dessous (comme dans le HTML)
      // Dessiner la ligne orange AVANT le texte avec un espacement suffisant (2px comme border-top)
      doc.setDrawColor(255, 152, 0);
      doc.setLineWidth(2);
      const totalLineY = yPosition;
      doc.line(totalsX - 10, totalLineY, pageWidth - margin, totalLineY);
      // Texte TOTAL TTC en orange, en dessous de la ligne avec espacement (padding-top: 10px)
      yPosition += 10; // Espacement après la ligne (padding-top)
      doc.setFontSize(18);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(255, 152, 0);
      // Aligner le texte et le montant sur la même ligne
      const totalTextY = yPosition;
      doc.text('TOTAL TTC:', totalsX, totalTextY, { align: 'right' });
      doc.text(formatFromEUR(quote.total || 0, workshopSettings.currency), pageWidth - margin, totalTextY, { align: 'right' });
      yPosition += 20;

      // Notes - style identique au HTML (notes-section)
      if (quote.notes) {
        yPosition += 5;
        const notesStartY = yPosition;
        const notesLines = doc.splitTextToSize(quote.notes, pageWidth - 2 * margin - 30);
        const notesHeight = notesLines.length * 5 + 10;
        
        // Fond gris clair comme dans le HTML (#f9f9f9)
        doc.setFillColor(249, 249, 249);
        doc.setDrawColor(220, 220, 220);
        doc.setLineWidth(0.5);
        doc.rect(margin, notesStartY, pageWidth - 2 * margin, notesHeight, 'FD');
        
        doc.setFontSize(9);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(0, 0, 0);
        doc.text('Notes :', margin + 5, notesStartY + 6);
        yPosition = notesStartY + 10;
        doc.setFont('helvetica', 'normal');
        notesLines.forEach((line: string) => {
          if (yPosition > pageHeight - 20) {
            doc.addPage();
            yPosition = margin;
          }
          doc.text(line, margin + 5, yPosition);
          yPosition += 5;
        });
        yPosition += 5;
      }

      // Conditions - style identique au HTML (notes-section)
      if (quote.terms) {
        yPosition += 5;
        const termsStartY = yPosition;
        const termsLines = doc.splitTextToSize(quote.terms, pageWidth - 2 * margin - 30);
        const termsHeight = termsLines.length * 5 + 10;
        
        // Fond gris clair comme dans le HTML (#f9f9f9)
        doc.setFillColor(249, 249, 249);
        doc.setDrawColor(220, 220, 220);
        doc.setLineWidth(0.5);
        doc.rect(margin, termsStartY, pageWidth - 2 * margin, termsHeight, 'FD');
        
        doc.setFontSize(9);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(0, 0, 0);
        doc.text('Conditions :', margin + 5, termsStartY + 6);
        yPosition = termsStartY + 10;
        doc.setFont('helvetica', 'normal');
        termsLines.forEach((line: string) => {
          if (yPosition > pageHeight - 20) {
            doc.addPage();
            yPosition = margin;
          }
          doc.text(line, margin + 5, yPosition);
          yPosition += 5;
        });
      }

      // Pied de page - identique au HTML (quote-footer)
      const footerY = pageHeight - 20;
      doc.setDrawColor(220, 220, 220); // #ddd
      doc.setLineWidth(1);
      doc.line(margin, footerY - 10, pageWidth - margin, footerY - 10);
      doc.setFontSize(12);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(100, 100, 100);
      doc.text(
        `Date d'émission: ${format(new Date(quote.createdAt), 'dd/MM/yyyy', { locale: fr })}`,
        pageWidth / 2,
        footerY,
        { align: 'center' }
      );
      doc.text(
        `Statut: ${getStatusLabel(quote.status)}`,
        pageWidth / 2,
        footerY + 5,
        { align: 'center' }
      );
      doc.text(
        'Merci de votre confiance !',
        pageWidth / 2,
        footerY + 10,
        { align: 'center' }
      );

      // Télécharger le PDF
      const fileName = `Devis_${formatQuoteNumber(quote.quoteNumber)}_${format(new Date(quote.createdAt), 'yyyy-MM-dd')}.pdf`;
      doc.save(fileName);
    } catch (error) {
      console.error('Erreur lors de la génération du PDF:', error);
      alert('❌ Erreur lors de la génération du PDF du devis. Veuillez réessayer.');
    }
  };

  const handleSendEmail = () => {
    if (!client?.email) {
      alert('❌ Aucune adresse email disponible pour ce client.');
      return;
    }

    try {
      // Générer et télécharger le PDF
      generateAndDownloadQuotePDF();

      // Créer le sujet de l'email (corps vide)
      const subject = `Devis ${formatQuoteNumber(quote.quoteNumber)} - Mon Atelier`;

      // Encoder le sujet pour l'URL
      const encodedSubject = encodeURIComponent(subject);

      // Créer l'URL mailto avec un corps vide
      const mailtoUrl = `mailto:${client.email}?subject=${encodedSubject}&body=`;

      // Ouvrir l'email dans le client par défaut
      window.open(mailtoUrl, '_blank');

      // Mettre à jour le statut du devis
      if (quote.status === 'draft') {
        handleStatusChange('sent');
      }

      // Message informatif
      alert('✅ Le PDF du devis a été téléchargé. Veuillez joindre le fichier PDF à votre email.');
    } catch (error) {
      console.error('Erreur lors de l\'envoi de l\'email:', error);
      alert('❌ Erreur lors de l\'ouverture du client email. Veuillez réessayer.');
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
                {quoteItems.length > 0 ? (
                  quoteItems.map((item) => (
                    <TableRow key={item.id || `${item.itemId}-${item.name}`}>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography variant="body2" sx={{ fontWeight: 500 }}>
                            {item.name || 'Article'}
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
                          {item.quantity || 1}
                        </Typography>
                      </TableCell>
                      <TableCell align="right">
                        <Typography variant="body2">
                          {formatFromEUR(item.unitPrice || 0, workshopSettings.currency)}
                        </Typography>
                      </TableCell>
                      <TableCell align="right">
                        <Typography variant="body2" sx={{ fontWeight: 500 }}>
                          {formatFromEUR(item.totalPrice || 0, workshopSettings.currency)}
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={5} align="center">
                      <Typography variant="body2" color="text.secondary">
                        Aucun article dans ce devis
                      </Typography>
                    </TableCell>
                  </TableRow>
                )}
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
                  {formatFromEUR(quote.subtotal, workshopSettings.currency)}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
                <Typography variant="body2">
                  TVA ({settingsLoading ? '...' : workshopSettings.vatRate}%) :
                </Typography>
                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                  {formatFromEUR(quote.tax, workshopSettings.currency)}
                </Typography>
              </Box>
              <Divider sx={{ my: 1 }} />
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Total :
                </Typography>
                <Typography variant="h6" sx={{ fontWeight: 600, color: '#1976d2' }}>
                  {formatFromEUR(quote.total, workshopSettings.currency)}
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
