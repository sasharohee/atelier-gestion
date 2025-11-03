import { jsPDF } from 'jspdf';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { PrintTemplate, Repair, Client, Device, User } from '../../types';

class PrintTemplatesService {
  /**
   * Imprime une étiquette pour l'appareil - Version améliorée
   */
  printLabel(template: PrintTemplate): void {
    const { repair, client, device, technician, workshopInfo } = template.data;
    const doc = new jsPDF({
      orientation: 'landscape',
      unit: 'mm',
      format: [120, 70], // Format étiquette plus grand
    });

    // Configuration
    doc.setFont('helvetica');

    // En-tête atelier
    if (workshopInfo?.name) {
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      doc.text(workshopInfo.name, 60, 8, { align: 'center' });
    }

    // Titre
    doc.setFontSize(16);
    doc.setFont('helvetica', 'bold');
    doc.text('RÉPARATION', 60, 16, { align: 'center' });

    // Numéro de réparation
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text(repair.repairNumber || `#${repair.id.slice(0, 8)}`, 60, 22, { align: 'center' });

    // Ligne séparatrice
    doc.setLineWidth(0.5);
    doc.line(10, 25, 110, 25);

    // Informations client
    doc.setFontSize(9);
    doc.setFont('helvetica', 'bold');
    doc.text('CLIENT:', 10, 30);
    doc.setFont('helvetica', 'normal');
    doc.text(`${client.firstName} ${client.lastName}`, 10, 35);
    doc.text(`Tél: ${client.phone || 'N/A'}`, 10, 40);
    if (client.email) {
      doc.setFontSize(8);
      doc.text(`Email: ${client.email}`, 10, 44);
    }

    // Informations appareil
    if (device) {
      doc.setFontSize(9);
      doc.setFont('helvetica', 'bold');
      doc.text('APPAREIL:', 10, 49);
      doc.setFont('helvetica', 'normal');
      doc.text(`${device.brand} ${device.model}`, 10, 54);
      if (device.serialNumber) {
        doc.setFontSize(8);
        doc.text(`S/N: ${device.serialNumber}`, 10, 58);
      }
      doc.text(`Type: ${device.type}`, 10, 62);
    }

    // Informations de réparation
    doc.setFontSize(9);
    doc.setFont('helvetica', 'bold');
    doc.text('RÉPARATION:', 10, 67);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    doc.text(`Date: ${format(new Date(repair.createdAt), 'dd/MM/yyyy', { locale: fr })}`, 60, 67);
    doc.text(`Échéance: ${format(new Date(repair.dueDate), 'dd/MM/yyyy', { locale: fr })}`, 60, 71);
    doc.text(`Prix: ${repair.totalPrice.toFixed(2)} €`, 60, 75);

    // Technicien assigné
    if (technician) {
      doc.setFontSize(8);
      doc.setFont('helvetica', 'bold');
      doc.text(`Tech: ${technician.firstName} ${technician.lastName}`, 10, 71);
    }

    // Badge urgent si nécessaire
    if (repair.isUrgent) {
      doc.setFillColor(239, 68, 68);
      doc.rect(85, 28, 20, 8, 'F');
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(8);
      doc.setFont('helvetica', 'bold');
      doc.text('URGENT', 95, 33, { align: 'center' });
    }

    // Statut de paiement
    if (repair.isPaid) {
      doc.setFillColor(16, 185, 129);
      doc.rect(85, 38, 20, 6, 'F');
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(7);
      doc.setFont('helvetica', 'bold');
      doc.text('PAYÉ', 95, 42, { align: 'center' });
    } else {
      doc.setFillColor(239, 68, 68);
      doc.rect(85, 38, 20, 6, 'F');
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(7);
      doc.setFont('helvetica', 'bold');
      doc.text('NON PAYÉ', 95, 42, { align: 'center' });
    }

    // Ouvrir dans un nouvel onglet pour impression
    window.open(doc.output('bloburl'), '_blank');
  }

  /**
   * Imprime un bon de travail
   */
  printWorkOrder(template: PrintTemplate): void {
    const { repair, client, device, technician, workshopInfo } = template.data;
    const doc = new jsPDF();

    let yPos = 20;

    // En-tête atelier
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text(workshopInfo?.name || 'Atelier de Réparation', 105, yPos, { align: 'center' });
    yPos += 7;

    if (workshopInfo) {
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.text(workshopInfo.address || '', 105, yPos, { align: 'center' });
      yPos += 5;
      doc.text(`${workshopInfo.phone || ''} - ${workshopInfo.email || ''}`, 105, yPos, { align: 'center' });
    }
    yPos += 10;

    // Titre
    doc.setFontSize(16);
    doc.setFont('helvetica', 'bold');
    doc.text('BON DE TRAVAIL', 105, yPos, { align: 'center' });
    yPos += 10;

    // Numéro de réparation et date
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text(`N° ${repair.repairNumber || repair.id.slice(0, 8)}`, 20, yPos);
    doc.text(`Date: ${format(new Date(repair.createdAt), 'dd/MM/yyyy', { locale: fr })}`, 150, yPos);
    yPos += 10;

    // Ligne séparatrice
    doc.setLineWidth(0.5);
    doc.line(20, yPos, 190, yPos);
    yPos += 10;

    // Informations client
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('CLIENT', 20, yPos);
    yPos += 6;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    doc.text(`Nom: ${client.firstName} ${client.lastName}`, 20, yPos);
    yPos += 5;
    doc.text(`Email: ${client.email}`, 20, yPos);
    yPos += 5;
    doc.text(`Téléphone: ${client.phone || 'N/A'}`, 20, yPos);
    if (client.address) {
      yPos += 5;
      doc.text(`Adresse: ${client.address}`, 20, yPos);
    }
    yPos += 10;

    // Informations appareil
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('APPAREIL', 20, yPos);
    yPos += 6;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    if (device) {
      doc.text(`Type: ${device.type}`, 20, yPos);
      yPos += 5;
      doc.text(`Marque: ${device.brand}`, 20, yPos);
      yPos += 5;
      doc.text(`Modèle: ${device.model}`, 20, yPos);
      if (device.serialNumber) {
        yPos += 5;
        doc.text(`N° série: ${device.serialNumber}`, 20, yPos);
      }
    } else {
      doc.text('Aucune information d\'appareil', 20, yPos);
    }
    yPos += 10;

    // Description et problème
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('DESCRIPTION DE LA PANNE', 20, yPos);
    yPos += 6;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    const description = doc.splitTextToSize(repair.description, 170);
    doc.text(description, 20, yPos);
    yPos += description.length * 5 + 5;

    if (repair.issue) {
      doc.setFont('helvetica', 'bold');
      doc.text('Problème:', 20, yPos);
      doc.setFont('helvetica', 'normal');
      yPos += 5;
      const issue = doc.splitTextToSize(repair.issue, 170);
      doc.text(issue, 20, yPos);
      yPos += issue.length * 5 + 5;
    }

    // Informations de réparation
    yPos += 5;
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('INFORMATIONS DE RÉPARATION', 20, yPos);
    yPos += 6;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    doc.text(`Date limite: ${format(new Date(repair.dueDate), 'dd/MM/yyyy', { locale: fr })}`, 20, yPos);
    yPos += 5;
    doc.text(`Durée estimée: ${repair.estimatedDuration} minutes`, 20, yPos);
    yPos += 5;
    doc.text(`Prix estimé: ${repair.totalPrice.toFixed(2)} €`, 20, yPos);
    yPos += 5;

    if (technician) {
      doc.text(`Technicien: ${technician.firstName} ${technician.lastName}`, 20, yPos);
      yPos += 5;
    }

    if (repair.isUrgent) {
      doc.setTextColor(239, 68, 68);
      doc.setFont('helvetica', 'bold');
      doc.text('⚠ RÉPARATION URGENTE', 20, yPos);
      doc.setTextColor(0, 0, 0);
      yPos += 5;
    }

    // Checklist de travail
    yPos += 10;
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('CHECKLIST DE TRAVAIL', 20, yPos);
    yPos += 8;

    const checklist = [
      '☐ Diagnostic effectué',
      '☐ Pièces commandées',
      '☐ Réparation effectuée',
      '☐ Tests de fonctionnement',
      '☐ Nettoyage de l\'appareil',
      '☐ Prêt à livrer',
    ];

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    checklist.forEach((item) => {
      doc.text(item, 25, yPos);
      yPos += 6;
    });

    // Zone de notes
    yPos += 10;
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('NOTES DU TECHNICIEN', 20, yPos);
    yPos += 6;

    doc.setLineWidth(0.3);
    for (let i = 0; i < 4; i++) {
      doc.line(20, yPos, 190, yPos);
      yPos += 7;
    }

    // Signature
    yPos += 5;
    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.text('Signature du technicien:', 20, yPos);
    doc.text('Signature du client:', 120, yPos);

    // Ouvrir dans un nouvel onglet pour impression
    window.open(doc.output('bloburl'), '_blank');
  }

  /**
   * Imprime un reçu de dépôt
   */
  printDepositReceipt(template: PrintTemplate): void {
    const { repair, client, device, workshopInfo } = template.data;
    const doc = new jsPDF();

    let yPos = 20;

    // En-tête
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text(workshopInfo?.name || 'Atelier de Réparation', 105, yPos, { align: 'center' });
    yPos += 7;

    if (workshopInfo) {
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.text(workshopInfo.address || '', 105, yPos, { align: 'center' });
      yPos += 5;
      doc.text(`${workshopInfo.phone || ''} - ${workshopInfo.email || ''}`, 105, yPos, { align: 'center' });
    }
    yPos += 10;

    // Titre
    doc.setFontSize(16);
    doc.setFont('helvetica', 'bold');
    doc.text('REÇU DE DÉPÔT', 105, yPos, { align: 'center' });
    yPos += 10;

    // Numéro et date
    doc.setFontSize(12);
    doc.text(`N° ${repair.repairNumber || repair.id.slice(0, 8)}`, 105, yPos, { align: 'center' });
    yPos += 7;
    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.text(`Date de dépôt: ${format(new Date(repair.createdAt), 'dd/MM/yyyy à HH:mm', { locale: fr })}`, 105, yPos, { align: 'center' });
    yPos += 15;

    // Ligne
    doc.setLineWidth(0.5);
    doc.line(20, yPos, 190, yPos);
    yPos += 10;

    // Client
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('CLIENT', 20, yPos);
    yPos += 6;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    doc.text(`${client.firstName} ${client.lastName}`, 20, yPos);
    yPos += 5;
    doc.text(`${client.email}`, 20, yPos);
    yPos += 5;
    doc.text(`${client.phone || 'N/A'}`, 20, yPos);
    yPos += 15;

    // Appareil
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('APPAREIL DÉPOSÉ', 20, yPos);
    yPos += 6;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    if (device) {
      doc.text(`${device.brand} ${device.model}`, 20, yPos);
      yPos += 5;
      doc.text(`Type: ${device.type}`, 20, yPos);
      if (device.serialNumber) {
        yPos += 5;
        doc.text(`N° série: ${device.serialNumber}`, 20, yPos);
      }
    }
    yPos += 15;

    // Description
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('DESCRIPTION DU PROBLÈME', 20, yPos);
    yPos += 6;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    const description = doc.splitTextToSize(repair.description, 170);
    doc.text(description, 20, yPos);
    yPos += description.length * 5 + 15;

    // Estimation
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('ESTIMATION', 20, yPos);
    yPos += 6;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    doc.text(`Prix estimé: ${repair.totalPrice.toFixed(2)} €`, 20, yPos);
    yPos += 5;
    doc.text(`Délai estimé: ${format(new Date(repair.dueDate), 'dd/MM/yyyy', { locale: fr })}`, 20, yPos);
    yPos += 15;

    // Conditions
    doc.setFontSize(9);
    doc.setFont('helvetica', 'italic');
    const conditions = [
      'Le client certifie être propriétaire de l\'appareil déposé.',
      'L\'atelier n\'est pas responsable des données présentes sur l\'appareil.',
      'Le devis est valable 30 jours.',
      'Tout appareil non récupéré après 6 mois sera considéré comme abandonné.',
    ];
    
    conditions.forEach((condition) => {
      const lines = doc.splitTextToSize(`• ${condition}`, 170);
      doc.text(lines, 20, yPos);
      yPos += lines.length * 4;
    });

    // Signatures
    yPos += 20;
    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.text('Signature du client:', 20, yPos);
    doc.text('Cachet de l\'atelier:', 120, yPos);

    doc.line(20, yPos + 15, 80, yPos + 15);
    doc.line(120, yPos + 15, 180, yPos + 15);

    // Ouvrir dans un nouvel onglet pour impression
    window.open(doc.output('bloburl'), '_blank');
  }

  /**
   * Génère une facture simplifiée
   */
  printInvoice(template: PrintTemplate): void {
    const { repair, client, workshopInfo } = template.data;
    const doc = new jsPDF();

    let yPos = 20;

    // En-tête
    doc.setFontSize(20);
    doc.setFont('helvetica', 'bold');
    doc.text('FACTURE', 20, yPos);
    yPos += 10;

    // Informations atelier
    if (workshopInfo) {
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      doc.text(workshopInfo.name, 20, yPos);
      yPos += 5;
      doc.setFont('helvetica', 'normal');
      doc.text(workshopInfo.address, 20, yPos);
      yPos += 5;
      doc.text(`${workshopInfo.phone} - ${workshopInfo.email}`, 20, yPos);
    }

    // Numéro de facture et date (en haut à droite)
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    doc.text(`Facture N° ${repair.repairNumber || repair.id.slice(0, 8)}`, 140, 30);
    doc.setFont('helvetica', 'normal');
    doc.text(`Date: ${format(new Date(), 'dd/MM/yyyy', { locale: fr })}`, 140, 36);

    yPos = 60;

    // Informations client
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('FACTURER À:', 20, yPos);
    yPos += 6;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    doc.text(`${client.firstName} ${client.lastName}`, 20, yPos);
    yPos += 5;
    doc.text(client.email, 20, yPos);
    if (client.address) {
      yPos += 5;
      doc.text(client.address, 20, yPos);
    }

    yPos += 20;

    // Tableau des services/pièces
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    
    // En-têtes de tableau
    doc.text('Description', 20, yPos);
    doc.text('Qté', 130, yPos);
    doc.text('Prix Unit.', 150, yPos);
    doc.text('Total', 180, yPos, { align: 'right' });
    yPos += 3;

    doc.setLineWidth(0.5);
    doc.line(20, yPos, 190, yPos);
    yPos += 7;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);

    // Services
    if (repair.services && repair.services.length > 0) {
      repair.services.forEach((service) => {
        doc.text('Service de réparation', 20, yPos);
        doc.text(service.quantity.toString(), 130, yPos);
        doc.text(`${service.price.toFixed(2)} €`, 150, yPos);
        doc.text(`${(service.price * service.quantity).toFixed(2)} €`, 190, yPos, { align: 'right' });
        yPos += 6;
      });
    }

    // Pièces
    if (repair.parts && repair.parts.length > 0) {
      repair.parts.forEach((part) => {
        doc.text('Pièce détachée', 20, yPos);
        doc.text(part.quantity.toString(), 130, yPos);
        doc.text(`${part.price.toFixed(2)} €`, 150, yPos);
        doc.text(`${(part.price * part.quantity).toFixed(2)} €`, 190, yPos, { align: 'right' });
        yPos += 6;
      });
    }

    yPos += 5;
    doc.line(20, yPos, 190, yPos);
    yPos += 10;

    // Total
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('TOTAL:', 150, yPos);
    doc.text(`${repair.totalPrice.toFixed(2)} €`, 190, yPos, { align: 'right' });

    yPos += 10;

    // Acompte et reste à payer
    if (repair.deposit && repair.deposit > 0) {
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.text('Acompte payé:', 150, yPos);
      doc.text(`${repair.deposit.toFixed(2)} €`, 190, yPos, { align: 'right' });
      yPos += 6;
      
      const remaining = repair.totalPrice - repair.deposit;
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(0, 102, 204); // Bleu
      doc.text('Reste à payer:', 150, yPos);
      doc.text(`${remaining.toFixed(2)} €`, 190, yPos, { align: 'right' });
      doc.setTextColor(0, 0, 0);
      yPos += 8;
    } else {
      yPos += 4;
    }

    // Statut de paiement
    if (repair.isPaid) {
      doc.setFontSize(11);
      doc.setTextColor(16, 185, 129);
      doc.text('✓ PAYÉ', 150, yPos);
      doc.setTextColor(0, 0, 0);
    } else {
      doc.setFontSize(11);
      doc.setTextColor(239, 68, 68);
      doc.text('NON PAYÉ', 150, yPos);
      doc.setTextColor(0, 0, 0);
    }

    // Mentions légales
    yPos = 270;
    doc.setFontSize(8);
    doc.setFont('helvetica', 'italic');
    doc.text('Merci pour votre confiance.', 105, yPos, { align: 'center' });

    // Ouvrir dans un nouvel onglet pour impression
    window.open(doc.output('bloburl'), '_blank');
  }

  /**
   * Imprime un ticket SAV complet - Version améliorée avec toutes les informations
   */
  printCompleteTicket(template: PrintTemplate): void {
    const { repair, client, device, technician, workshopInfo } = template.data;
    const doc = new jsPDF();
    
    let yPos = 20;

    // En-tête atelier
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text(workshopInfo?.name || 'Atelier de Réparation', 105, yPos, { align: 'center' });
    yPos += 7;

    if (workshopInfo) {
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.text(workshopInfo.address || '', 105, yPos, { align: 'center' });
      yPos += 5;
      doc.text(`${workshopInfo.phone || ''} - ${workshopInfo.email || ''}`, 105, yPos, { align: 'center' });
    }
    yPos += 10;

    // Titre principal
    doc.setFontSize(20);
    doc.setFont('helvetica', 'bold');
    doc.text('TICKET SAV - RÉPARATION', 105, yPos, { align: 'center' });
    yPos += 10;

    // Numéro de réparation et date
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text(`N° ${repair.repairNumber || repair.id.slice(0, 8)}`, 20, yPos);
    doc.text(`Date: ${format(new Date(repair.createdAt), 'dd/MM/yyyy à HH:mm', { locale: fr })}`, 120, yPos);
    yPos += 8;

    // Statuts visuels
    if (repair.isUrgent) {
      doc.setFillColor(239, 68, 68);
      doc.rect(160, yPos - 5, 25, 8, 'F');
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      doc.text('URGENT', 172.5, yPos, { align: 'center' });
    }

    if (repair.isPaid) {
      doc.setFillColor(16, 185, 129);
      doc.rect(160, yPos + 5, 25, 8, 'F');
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      doc.text('PAYÉ', 172.5, yPos + 10, { align: 'center' });
    } else {
      doc.setFillColor(239, 68, 68);
      doc.rect(160, yPos + 5, 25, 8, 'F');
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      doc.text('NON PAYÉ', 172.5, yPos + 10, { align: 'center' });
    }

    doc.setTextColor(0, 0, 0);
    yPos += 15;

    // Ligne séparatrice
    doc.setLineWidth(0.5);
    doc.line(20, yPos, 190, yPos);
    yPos += 10;

    // Section Client
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('INFORMATIONS CLIENT', 20, yPos);
    yPos += 8;

    doc.setFontSize(11);
    doc.setFont('helvetica', 'normal');
    doc.text(`Nom: ${client.firstName} ${client.lastName}`, 20, yPos);
    yPos += 6;
    doc.text(`Email: ${client.email}`, 20, yPos);
    yPos += 6;
    doc.text(`Téléphone: ${client.phone || 'N/A'}`, 20, yPos);
    if (client.address) {
      yPos += 6;
      doc.text(`Adresse: ${client.address}`, 20, yPos);
    }
    yPos += 12;

    // Section Appareil
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('INFORMATIONS APPAREIL', 20, yPos);
    yPos += 8;

    doc.setFontSize(11);
    doc.setFont('helvetica', 'normal');
    if (device) {
      doc.text(`Type: ${device.type}`, 20, yPos);
      yPos += 6;
      doc.text(`Marque: ${device.brand}`, 20, yPos);
      yPos += 6;
      doc.text(`Modèle: ${device.model}`, 20, yPos);
      if (device.serialNumber) {
        yPos += 6;
        doc.text(`N° série: ${device.serialNumber}`, 20, yPos);
      }
    } else {
      doc.text('Aucune information d\'appareil', 20, yPos);
    }
    yPos += 12;

    // Section Réparation
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('DÉTAILS DE LA RÉPARATION', 20, yPos);
    yPos += 8;

    doc.setFontSize(11);
    doc.setFont('helvetica', 'normal');
    doc.text(`Description: ${repair.description}`, 20, yPos);
    yPos += 6;

    if (repair.issue) {
      doc.text(`Problème signalé: ${repair.issue}`, 20, yPos);
      yPos += 6;
    }

    doc.text(`Date d'échéance: ${format(new Date(repair.dueDate), 'dd/MM/yyyy', { locale: fr })}`, 20, yPos);
    yPos += 6;
    doc.text(`Durée estimée: ${repair.estimatedDuration} minutes`, 20, yPos);
    yPos += 6;
    doc.text(`Prix total: ${repair.totalPrice.toFixed(2)} €`, 20, yPos);
    yPos += 6;

    if (technician) {
      doc.text(`Technicien assigné: ${technician.firstName} ${technician.lastName}`, 20, yPos);
      yPos += 6;
    }

    yPos += 10;

    // Section Services et Pièces
    if (repair.services && repair.services.length > 0) {
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('SERVICES', 20, yPos);
      yPos += 8;

      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      repair.services.forEach((service) => {
        doc.text(`• Service (x${service.quantity}): ${service.price.toFixed(2)} €`, 25, yPos);
        yPos += 5;
      });
      yPos += 5;
    }

    if (repair.parts && repair.parts.length > 0) {
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('PIÈCES DÉTACHÉES', 20, yPos);
      yPos += 8;

      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      repair.parts.forEach((part) => {
        doc.text(`• Pièce (x${part.quantity}): ${part.price.toFixed(2)} €`, 25, yPos);
        yPos += 5;
      });
      yPos += 5;
    }

    // Section Notes
    if (repair.notes) {
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('NOTES', 20, yPos);
      yPos += 8;

      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      const notes = doc.splitTextToSize(repair.notes, 170);
      doc.text(notes, 20, yPos);
      yPos += notes.length * 5 + 10;
    }

    // Conditions et mentions
    yPos += 10;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('CONDITIONS GÉNÉRALES', 20, yPos);
    yPos += 8;

    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    const conditions = [
      '• Le client certifie être propriétaire de l\'appareil déposé',
      '• L\'atelier n\'est pas responsable des données présentes sur l\'appareil',
      '• Le devis est valable 30 jours à compter de la date d\'émission',
      '• Tout appareil non récupéré après 6 mois sera considéré comme abandonné',
      '• La réparation est garantie pièces et main d\'œuvre',
      '• En cas de réparation impossible, seul le coût du diagnostic peut être facturé'
    ];
    
    conditions.forEach((condition) => {
      doc.text(condition, 20, yPos);
      yPos += 4;
    });

    // Pied de page
    yPos += 15;
    doc.setLineWidth(0.3);
    doc.line(20, yPos, 190, yPos);
    yPos += 10;

    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    doc.text('Merci de votre confiance !', 105, yPos, { align: 'center' });
    yPos += 6;
    
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    doc.text(`Ticket généré le ${format(new Date(), 'dd/MM/yyyy à HH:mm', { locale: fr })}`, 105, yPos, { align: 'center' });

    // Ouvrir dans un nouvel onglet pour impression
    window.open(doc.output('bloburl'), '_blank');
  }

  /**
   * Fonction principale de routage pour l'impression
   */
  print(template: PrintTemplate): void {
    switch (template.type) {
      case 'label':
        this.printLabel(template);
        break;
      case 'work_order':
        this.printWorkOrder(template);
        break;
      case 'deposit_receipt':
        this.printDepositReceipt(template);
        break;
      case 'invoice':
        this.printInvoice(template);
        break;
      case 'complete_ticket':
        this.printCompleteTicket(template);
        break;
      default:
        console.error('Type de template inconnu:', template.type);
    }
  }
}

export const printTemplatesService = new PrintTemplatesService();
export default printTemplatesService;







