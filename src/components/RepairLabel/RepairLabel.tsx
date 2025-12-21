import React from 'react';
import { Box, Typography } from '@mui/material';
import { QRCodeSVG } from 'qrcode.react';
import { Repair, Client, Device } from '../../types';

interface RepairLabelProps {
  repair: Repair;
  client: Client;
  device: Device | null;
  workshopName: string;
  trackingUrl: string;
}

const RepairLabel: React.FC<RepairLabelProps> = ({
  repair,
  client,
  device,
  workshopName,
  trackingUrl,
}) => {
  // Tronquer la description si elle est trop longue
  const truncateDescription = (text: string, maxLength: number = 50) => {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  };

  return (
    <Box
      sx={{
        width: '80mm',
        height: '40mm',
        padding: '3mm',
        border: '1.5px solid #000',
        backgroundColor: '#fff',
        fontFamily: 'Arial, sans-serif',
        boxSizing: 'border-box',
        display: 'flex',
        flexDirection: 'column',
        '@media print': {
          width: '80mm',
          height: '40mm',
          border: '1.5px solid #000',
          padding: '3mm',
          pageBreakAfter: 'avoid',
          pageBreakInside: 'avoid',
          boxSizing: 'border-box',
        },
      }}
    >
      {/* Contenu principal en deux colonnes */}
      <Box sx={{ display: 'flex', flex: 1, gap: '2mm', height: '100%' }}>
        {/* Colonne gauche - Informations */}
        <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          {/* En-tête avec nom de l'atelier */}
          <Box sx={{ textAlign: 'center', mb: 0.3, borderBottom: '1px solid #000', pb: 0.3 }}>
            <Typography
              sx={{
                fontSize: '10px',
                fontWeight: 'bold',
                margin: 0,
                lineHeight: 1,
              }}
            >
              {workshopName}
            </Typography>
          </Box>

          {/* Numéro de réparation */}
          <Box sx={{ textAlign: 'center', mb: 0.4 }}>
            <Typography
              sx={{
                fontSize: '14px',
                fontWeight: 'bold',
                margin: 0,
                letterSpacing: '0.3px',
                lineHeight: 1,
              }}
            >
              {repair.repairNumber || `REP-${repair.id.slice(0, 8).toUpperCase()}`}
            </Typography>
          </Box>

          {/* Informations client - plus grand */}
          <Box sx={{ mb: 0.3, flex: 1 }}>
            <Typography
              sx={{
                fontSize: '10px',
                fontWeight: 'bold',
                margin: 0,
                marginBottom: '2px',
                lineHeight: 1.1,
              }}
            >
              Client:
            </Typography>
            <Typography
              sx={{
                fontSize: '11px',
                margin: 0,
                lineHeight: 1.2,
                fontWeight: 600,
              }}
            >
              {client.firstName} {client.lastName}
            </Typography>
            {client.phone && (
              <Typography
                sx={{
                  fontSize: '10px',
                  margin: 0,
                  marginTop: '1px',
                  lineHeight: 1.1,
                }}
              >
                {client.phone}
              </Typography>
            )}
          </Box>

          {/* Appareil - plus compact */}
          {device && (
            <Box sx={{ mb: 0.3 }}>
              <Typography
                sx={{
                  fontSize: '9px',
                  fontWeight: 'bold',
                  margin: 0,
                  marginBottom: '1px',
                  lineHeight: 1,
                }}
              >
                Appareil:
              </Typography>
              <Typography
                sx={{
                  fontSize: '9px',
                  margin: 0,
                  lineHeight: 1.1,
                }}
              >
                {device.brand} {device.model}
              </Typography>
            </Box>
          )}

          {/* Description de la réparation - plus grande */}
          <Box sx={{ flex: 1, minHeight: 0 }}>
            <Typography
              sx={{
                fontSize: '10px',
                fontWeight: 'bold',
                margin: 0,
                marginBottom: '2px',
                lineHeight: 1.1,
              }}
            >
              Description:
            </Typography>
            <Typography
              sx={{
                fontSize: '10px',
                margin: 0,
                lineHeight: 1.2,
                wordBreak: 'break-word',
                overflow: 'hidden',
              }}
            >
              {truncateDescription(repair.description || 'Aucune description', 50)}
            </Typography>
          </Box>
        </Box>

        {/* Colonne droite - QR Code */}
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            width: '25mm',
            flexShrink: 0,
          }}
        >
          <QRCodeSVG
            value={trackingUrl}
            size={60}
            level="M"
            includeMargin={false}
          />
          <Typography
            sx={{
              fontSize: '6px',
              margin: 0,
              marginTop: '1px',
              color: '#666',
              fontStyle: 'italic',
              lineHeight: 1,
            }}
          >
            Scannez
          </Typography>
        </Box>
      </Box>
    </Box>
  );
};

export default RepairLabel;

