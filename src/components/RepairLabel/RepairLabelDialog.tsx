import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  IconButton,
  Typography,
} from '@mui/material';
import {
  Close as CloseIcon,
  Print as PrintIcon,
} from '@mui/icons-material';
import { Repair, Client, Device } from '../../types';
import RepairLabel from './RepairLabel';
import { repairTrackingService } from '../../services/repairTrackingService';

interface RepairLabelDialogProps {
  open: boolean;
  onClose: () => void;
  repair: Repair;
  client: Client;
  device: Device | null;
  workshopName: string;
}

const RepairLabelDialog: React.FC<RepairLabelDialogProps> = ({
  open,
  onClose,
  repair,
  client,
  device,
  workshopName,
}) => {
  // Vérifier que le client existe
  if (!client || !client.email) {
    return (
      <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
        <DialogTitle>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h6">Erreur</Typography>
            <IconButton onClick={onClose} size="small">
              <CloseIcon />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent>
          <Typography color="error">
            Impossible de générer l'étiquette : les informations du client sont manquantes.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={onClose} variant="contained">
            Fermer
          </Button>
        </DialogActions>
      </Dialog>
    );
  }

  // Générer l'URL de suivi
  const trackingUrl = repairTrackingService.generateTrackingUrl(
    repair.repairNumber || repair.id,
    client.email
  );

  const handlePrint = () => {
    // Récupérer le contenu de l'étiquette
    const labelContent = document.getElementById('repair-label-content');
    if (!labelContent) {
      alert('Erreur: contenu de l\'étiquette introuvable');
      return;
    }

    // Trouver le SVG du QR code dans le DOM
    const qrSvg = labelContent.querySelector('svg') as SVGSVGElement;
    let qrCodeHtml = '';
    
    if (qrSvg) {
      // Cloner le SVG et le convertir en string
      const clonedSvg = qrSvg.cloneNode(true) as SVGSVGElement;
      qrCodeHtml = clonedSvg.outerHTML;
    } else {
      // Fallback: utiliser une image depuis une API
      qrCodeHtml = `<img src="https://api.qrserver.com/v1/create-qr-code/?size=60x60&data=${encodeURIComponent(trackingUrl)}" class="qr-code" alt="QR Code" />`;
    }

    // Créer une nouvelle fenêtre pour l'impression
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      alert('Veuillez autoriser les popups pour imprimer l\'étiquette');
      return;
    }

    // Générer le HTML pour l'impression en reproduisant exactement la structure
    const printContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <title>Étiquette Réparation</title>
          <meta charset="utf-8">
          <style>
            @page {
              size: 80mm 40mm;
              margin: 0;
            }
            * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
            }
            body {
              font-family: Arial, sans-serif;
              margin: 0;
              padding: 0;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
              background-color: white;
            }
            .label-container {
              width: 80mm;
              height: 40mm;
              padding: 3mm;
              border: 1.5px solid #000;
              background-color: #fff;
              display: flex;
              flex-direction: column;
            }
            .label-content {
              display: flex;
              flex: 1;
              gap: 2mm;
              height: 100%;
            }
            .label-left {
              flex: 1;
              display: flex;
              flex-direction: column;
              min-width: 0;
            }
            .label-right {
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              width: 25mm;
              flex-shrink: 0;
            }
            .header {
              text-align: center;
              margin-bottom: 2.5px;
              border-bottom: 1px solid #000;
              padding-bottom: 2.5px;
            }
            .header-text {
              font-size: 10px;
              font-weight: bold;
              line-height: 1;
            }
            .repair-number {
              text-align: center;
              margin-bottom: 3px;
            }
            .repair-number-text {
              font-size: 14px;
              font-weight: bold;
              letter-spacing: 0.3px;
              line-height: 1;
            }
            .section {
              margin-bottom: 2.5px;
            }
            .section-label {
              font-size: 10px;
              font-weight: bold;
              margin-bottom: 1.5px;
              line-height: 1.1;
            }
            .section-value {
              font-size: 11px;
              line-height: 1.2;
              font-weight: 600;
            }
            .section-value-small {
              font-size: 10px;
              line-height: 1.1;
              margin-top: 1px;
            }
            .section-value-compact {
              font-size: 9px;
              line-height: 1.1;
            }
            .description-section {
              flex: 1;
              min-height: 0;
            }
            .description-text {
              font-size: 10px;
              line-height: 1.2;
              word-break: break-word;
              overflow: hidden;
            }
            .qr-code {
              width: 60px;
              height: 60px;
            }
            .qr-text {
              font-size: 6px;
              margin-top: 1px;
              color: #666;
              font-style: italic;
              line-height: 1;
              text-align: center;
            }
            @media print {
              body {
                background-color: white;
              }
            }
          </style>
        </head>
        <body>
          <div class="label-container">
            <div class="label-content">
              <div class="label-left">
                <div class="header">
                  <div class="header-text">${workshopName}</div>
                </div>
                <div class="repair-number">
                  <div class="repair-number-text">${repair.repairNumber || `REP-${repair.id.slice(0, 8).toUpperCase()}`}</div>
                </div>
                <div class="section">
                  <div class="section-label">Client:</div>
                  <div class="section-value">${client.firstName} ${client.lastName}</div>
                  ${client.phone ? `<div class="section-value-small">${client.phone}</div>` : ''}
                </div>
                ${device ? `
                <div class="section">
                  <div class="section-label">Appareil:</div>
                  <div class="section-value-compact">${device.brand} ${device.model}</div>
                </div>
                ` : ''}
                <div class="section description-section">
                  <div class="section-label">Description:</div>
                  <div class="description-text">${(repair.description || 'Aucune description').substring(0, 50)}${(repair.description || '').length > 50 ? '...' : ''}</div>
                </div>
              </div>
              <div class="label-right">
                ${qrCodeHtml}
                <div class="qr-text">Scannez</div>
              </div>
            </div>
          </div>
        </body>
      </html>
    `;

    printWindow.document.write(printContent);
    printWindow.document.close();

    // Attendre que le contenu soit chargé avant d'imprimer
    const printAfterLoad = () => {
      setTimeout(() => {
        printWindow.print();
        // Fermer automatiquement la fenêtre après l'impression
        // Utiliser un délai pour permettre à la boîte de dialogue d'impression de s'afficher
        setTimeout(() => {
          if (printWindow && !printWindow.closed) {
            printWindow.close();
          }
        }, 1000);
      }, 500);
    };

    // Vérifier si le document est déjà chargé
    if (printWindow.document.readyState === 'complete') {
      printAfterLoad();
    } else {
      printWindow.onload = printAfterLoad;
    }

    // Gérer le retour du focus sur la fenêtre principale
    const handleFocus = () => {
      // Si la fenêtre d'impression existe encore après un certain temps, la fermer
      setTimeout(() => {
        if (printWindow && !printWindow.closed) {
          printWindow.close();
        }
        // Retirer l'écouteur après utilisation
        window.removeEventListener('focus', handleFocus);
      }, 2000);
    };

    window.addEventListener('focus', handleFocus);
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          '@media print': {
            boxShadow: 'none',
            margin: 0,
          },
        },
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6">Étiquette de réparation</Typography>
          <IconButton onClick={onClose} size="small" className="no-print">
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>
      <DialogContent>
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            padding: 2,
            backgroundColor: '#f5f5f5',
            '@media print': {
              padding: 0,
              backgroundColor: 'transparent',
            },
          }}
        >
          <Box
            id="repair-label-content"
            sx={{
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
            }}
          >
            <RepairLabel
              repair={repair}
              client={client}
              device={device}
              workshopName={workshopName}
              trackingUrl={trackingUrl}
            />
          </Box>
        </Box>
      </DialogContent>
      <DialogActions className="no-print">
        <Button onClick={onClose} variant="outlined">
          Fermer
        </Button>
        <Button
          onClick={handlePrint}
          variant="contained"
          startIcon={<PrintIcon />}
          color="primary"
        >
          Imprimer
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default RepairLabelDialog;

