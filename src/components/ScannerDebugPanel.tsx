import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Chip,
  TextField,
  Alert,
} from '@mui/material';
import {
  QrCodeScanner as ScannerIcon,
  BugReport as DebugIcon,
} from '@mui/icons-material';
import BarcodeScannerService from '../services/barcodeScannerService';

interface ScannerDebugPanelProps {
  onBarcodeScanned?: (barcode: string) => void;
}

const ScannerDebugPanel: React.FC<ScannerDebugPanelProps> = ({ onBarcodeScanned }) => {
  const [bufferState, setBufferState] = useState<{ buffer: string; isListening: boolean }>({
    buffer: '',
    isListening: false
  });
  const [testBarcode, setTestBarcode] = useState('2001234567890');
  const [lastScanned, setLastScanned] = useState<string | null>(null);

  useEffect(() => {
    const scannerService = BarcodeScannerService.getInstance();
    
    // Mettre à jour l'état toutes les 500ms
    const interval = setInterval(() => {
      const state = scannerService.getBufferState();
      setBufferState(state);
    }, 500);

    // Ajouter un listener pour les scans
    const handleScan = (barcode: string) => {
      setLastScanned(barcode);
      if (onBarcodeScanned) {
        onBarcodeScanned(barcode);
      }
    };

    scannerService.addScanListener(handleScan);

    return () => {
      clearInterval(interval);
      scannerService.removeScanListener(handleScan);
    };
  }, [onBarcodeScanned]);

  const handleTestScan = () => {
    const scannerService = BarcodeScannerService.getInstance();
    console.log('🧪 Test normal avec code:', testBarcode);
    scannerService.testBarcode(testBarcode);
  };

  const handleForceScan = () => {
    const scannerService = BarcodeScannerService.getInstance();
    console.log('🔧 Test forcé avec code:', testBarcode);
    scannerService.forceProcessBarcode(testBarcode);
  };

  return (
    <Card variant="outlined" sx={{ mb: 2 }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
          <DebugIcon color="primary" />
          <Typography variant="h6">Debug Scanner</Typography>
        </Box>

        <Box sx={{ display: 'flex', gap: 2, mb: 2, flexWrap: 'wrap' }}>
          <Chip
            icon={<ScannerIcon />}
            label={bufferState.isListening ? 'Actif' : 'Inactif'}
            color={bufferState.isListening ? 'success' : 'default'}
            size="small"
          />
          
          <Chip
            label={`Buffer: ${bufferState.buffer.length} caractères`}
            color={bufferState.buffer.length > 0 ? 'info' : 'default'}
            size="small"
          />
        </Box>

        {bufferState.buffer && (
          <Alert severity="info" sx={{ mb: 2 }}>
            <Typography variant="body2">
              <strong>Buffer actuel:</strong> "{bufferState.buffer}"
            </Typography>
          </Alert>
        )}

        {lastScanned && (
          <Alert severity="success" sx={{ mb: 2 }}>
            <Typography variant="body2">
              <strong>Dernier scan:</strong> {lastScanned}
            </Typography>
          </Alert>
        )}

        <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
          <TextField
            size="small"
            label="Code-barres de test"
            value={testBarcode}
            onChange={(e) => setTestBarcode(e.target.value)}
            sx={{ flex: 1 }}
          />
          
          <Button
            variant="outlined"
            size="small"
            onClick={handleTestScan}
          >
            Test Normal
          </Button>
          
          <Button
            variant="outlined"
            size="small"
            onClick={handleForceScan}
            color="warning"
          >
            Test Forcé
          </Button>
        </Box>

        <Typography variant="caption" color="text.secondary">
          Le scanner écoute les événements clavier. Scannez un code-barres ou utilisez les boutons de test.
        </Typography>
        
        <Typography variant="caption" color="warning.main" sx={{ display: 'block', mt: 1 }}>
          💡 Conseil: Utilisez un code-barres d'un produit existant pour tester la recherche.
        </Typography>
      </CardContent>
    </Card>
  );
};

export default ScannerDebugPanel;
