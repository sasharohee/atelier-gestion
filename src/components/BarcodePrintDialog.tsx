import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Alert,
  CircularProgress,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Divider
} from '@mui/material';
import {
  Print as PrintIcon,
  Close as CloseIcon
} from '@mui/icons-material';
import { BarcodeService } from '../services/barcodeService';
import { formatFromEUR } from '../utils/currencyUtils';

interface BarcodePrintDialogProps {
  open: boolean;
  onClose: () => void;
  product: {
    name: string;
    price: number;
    barcode: string;
    description?: string;
  };
  currency?: string;
}

const BarcodePrintDialog: React.FC<BarcodePrintDialogProps> = ({
  open,
  onClose,
  product,
  currency = 'EUR'
}) => {
  const [barcodeSvg, setBarcodeSvg] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [labelSize, setLabelSize] = useState<'58mm' | '80mm'>('58mm');

  useEffect(() => {
    if (open && product.barcode) {
      generateBarcode();
    }
  }, [open, product.barcode]);

  const generateBarcode = async () => {
    if (!product.barcode) return;

    setLoading(true);
    setError(null);

    try {
      // Valider le code-barres
      if (!BarcodeService.validateEAN13(product.barcode)) {
        throw new Error('Code-barres EAN-13 invalide');
      }

      // Dimensions selon la taille d'étiquette
      const dimensions = labelSize === '58mm' 
        ? { width: 300, height: 80, scale: 3 }
        : { width: 400, height: 100, scale: 4 };

      // Générer l'image SVG
      const svg = BarcodeService.generateBarcodeImage(product.barcode, dimensions);
      setBarcodeSvg(svg);
    } catch (err) {
      console.error('Erreur génération code-barres:', err);
      setError(err instanceof Error ? err.message : 'Erreur lors de la génération');
    } finally {
      setLoading(false);
    }
  };

  const handlePrint = () => {
    const printWindow = window.open('', '_blank');
    if (!printWindow) return;

    const printContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <title>Code-barres - ${product.name}</title>
          <style>
            @page {
              margin: 0;
              size: ${labelSize === '58mm' ? '58mm 40mm' : '80mm 50mm'};
            }
            body {
              margin: 0;
              padding: 4mm;
              font-family: Arial, sans-serif;
              font-size: 10px;
              line-height: 1.2;
            }
            .label {
              width: 100%;
              text-align: center;
              border: 1px solid #ccc;
              padding: 2mm;
              box-sizing: border-box;
            }
            .product-name {
              font-weight: bold;
              margin-bottom: 2mm;
              word-wrap: break-word;
            }
            .product-price {
              font-size: 12px;
              font-weight: bold;
              color: #1976d2;
              margin-bottom: 2mm;
            }
            .barcode-container {
              margin: 2mm 0;
              text-align: center;
            }
            .barcode-text {
              font-family: monospace;
              font-size: 8px;
              margin-top: 1mm;
              word-break: break-all;
            }
            @media print {
              body { margin: 0; padding: 2mm; }
              .label { border: none; }
            }
          </style>
        </head>
        <body>
          <div class="label">
            <div class="product-name">${product.name}</div>
            <div class="product-price">${formatFromEUR(product.price, currency)}</div>
            <div class="barcode-container">
              ${barcodeSvg}
              <div class="barcode-text">${BarcodeService.formatBarcode(product.barcode)}</div>
            </div>
          </div>
        </body>
      </html>
    `;

    printWindow.document.write(printContent);
    printWindow.document.close();
    
    // Attendre que le contenu soit chargé puis imprimer
    printWindow.onload = () => {
      setTimeout(() => {
        printWindow.print();
        printWindow.close();
      }, 500);
    };
  };

  const handleClose = () => {
    setBarcodeSvg('');
    setError(null);
    onClose();
  };

  return (
    <Dialog 
      open={open} 
      onClose={handleClose}
      maxWidth="sm" 
      fullWidth
      PaperProps={{
        sx: { minHeight: 400 }
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <PrintIcon />
          <Typography variant="h6">Imprimer le code-barres</Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <Box sx={{ mb: 3 }}>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
            Produit: <strong>{product.name}</strong>
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Prix: <strong>{formatFromEUR(product.price, currency)}</strong>
          </Typography>
        </Box>

        <FormControl fullWidth sx={{ mb: 3 }}>
          <InputLabel>Taille d'étiquette</InputLabel>
          <Select
            value={labelSize}
            label="Taille d'étiquette"
            onChange={(e) => setLabelSize(e.target.value as '58mm' | '80mm')}
          >
            <MenuItem value="58mm">58mm (Étiquettes standard)</MenuItem>
            <MenuItem value="80mm">80mm (Étiquettes larges)</MenuItem>
          </Select>
        </FormControl>

        <Divider sx={{ my: 2 }} />

        {loading && (
          <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
            <CircularProgress />
          </Box>
        )}

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {barcodeSvg && !loading && (
          <Box sx={{ textAlign: 'center', p: 2 }}>
            <Typography variant="subtitle2" sx={{ mb: 2 }}>
              Aperçu de l'étiquette ({labelSize})
            </Typography>
            <Box
              sx={{
                border: '2px dashed #ccc',
                borderRadius: 1,
                p: 2,
                backgroundColor: '#fafafa',
                display: 'inline-block',
                maxWidth: '100%',
                overflow: 'hidden'
              }}
            >
              <Box
                sx={{
                  transform: labelSize === '58mm' ? 'scale(0.6)' : 'scale(0.7)',
                  transformOrigin: 'top center'
                }}
                dangerouslySetInnerHTML={{ __html: barcodeSvg }}
              />
            </Box>
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
              {BarcodeService.formatBarcode(product.barcode)}
            </Typography>
          </Box>
        )}
      </DialogContent>

      <DialogActions>
        <Button 
          onClick={handleClose}
          startIcon={<CloseIcon />}
        >
          Annuler
        </Button>
        <Button
          onClick={handlePrint}
          variant="contained"
          startIcon={<PrintIcon />}
          disabled={loading || !barcodeSvg || !!error}
        >
          Imprimer
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default BarcodePrintDialog;
