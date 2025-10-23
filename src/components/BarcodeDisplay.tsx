import React, { useState, useEffect } from 'react';
import { Box, Typography, Skeleton, Alert } from '@mui/material';
import { BarcodeService } from '../services/barcodeService';

interface BarcodeDisplayProps {
  barcode: string;
  width?: number;
  height?: number;
  showValue?: boolean;
  scale?: number;
  className?: string;
}

const BarcodeDisplay: React.FC<BarcodeDisplayProps> = ({
  barcode,
  width = 200,
  height = 50,
  showValue = true,
  scale = 2,
  className
}) => {
  const [barcodeSvg, setBarcodeSvg] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (barcode && barcode.length === 13) {
      generateBarcode();
    } else {
      setBarcodeSvg('');
      setError(null);
    }
  }, [barcode, width, height, scale]);

  const generateBarcode = async () => {
    if (!barcode) return;

    setLoading(true);
    setError(null);

    try {
      // Valider le code-barres
      if (!BarcodeService.validateEAN13(barcode)) {
        throw new Error('Code-barres EAN-13 invalide');
      }

      // Générer l'image
      const barcodeImage = BarcodeService.generateBarcodeImage(barcode, {
        width,
        height,
        scale
      });

      setBarcodeSvg(barcodeImage);
    } catch (err) {
      console.error('Erreur génération code-barres:', err);
      setError(err instanceof Error ? err.message : 'Erreur lors de la génération');
    } finally {
      setLoading(false);
    }
  };

  if (!barcode) {
    return (
      <Box className={className} sx={{ textAlign: 'center', p: 2 }}>
        <Typography variant="body2" color="text.secondary">
          Aucun code-barres
        </Typography>
      </Box>
    );
  }

  if (loading) {
    return (
      <Box className={className} sx={{ textAlign: 'center', p: 2 }}>
        <Skeleton variant="rectangular" width={width} height={height} />
        <Typography variant="caption" color="text.secondary">
          Génération du code-barres...
        </Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Box className={className} sx={{ textAlign: 'center', p: 2 }}>
        <Alert severity="error" sx={{ mb: 1 }}>
          {error}
        </Alert>
        <Typography variant="body2" color="text.secondary">
          Code: {barcode}
        </Typography>
      </Box>
    );
  }

  return (
    <Box className={className} sx={{ textAlign: 'center', p: 1 }}>
      {barcodeSvg && (
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 1
          }}
        >
          <Box
            sx={{
              border: '1px solid #e0e0e0',
              borderRadius: 1,
              p: 1,
              backgroundColor: 'white',
              display: 'inline-block',
              maxWidth: '100%',
              overflow: 'hidden'
            }}
            dangerouslySetInnerHTML={{ __html: barcodeSvg }}
          />
          {showValue && (
            <Typography 
              variant="caption" 
              color="text.secondary"
              sx={{ 
                fontFamily: 'monospace',
                fontSize: '0.75rem',
                wordBreak: 'break-all'
              }}
            >
              {BarcodeService.formatBarcode(barcode)}
            </Typography>
          )}
        </Box>
      )}
    </Box>
  );
};

export default BarcodeDisplay;
