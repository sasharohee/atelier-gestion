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

  const handleForceBuffer = () => {
    const scannerService = BarcodeScannerService.getInstance();
    console.log('🔧 Forcer le traitement du buffer actuel');
    scannerService.forceProcessCurrentBuffer();
  };

  const handleDiagnostic = () => {
    const scannerService = BarcodeScannerService.getInstance();
    const diagnostic = scannerService.getDiagnosticInfo();
    console.log('🔍 Diagnostic scanner:', diagnostic);
    alert(`Diagnostic Scanner:
État: ${diagnostic.isListening ? 'Actif' : 'Inactif'}
Buffer: "${diagnostic.buffer}" (${diagnostic.bufferLength} caractères)
Dernière touche: ${diagnostic.timeSinceLastKey}ms
Timeout actif: ${diagnostic.hasTimeout ? 'Oui' : 'Non'}
Listeners: ${diagnostic.listenersCount}`);
  };

  const handleCompatibilityTest = () => {
    const scannerService = BarcodeScannerService.getInstance();
    console.log('🧪 Lancement des tests de compatibilité...');
    scannerService.testScannerCompatibility();
    alert('Tests de compatibilité lancés ! Vérifiez la console pour les résultats.');
  };

  const handleUltraFastMode = () => {
    const scannerService = BarcodeScannerService.getInstance();
    console.log('🚀 Activation du mode ultra-rapide...');
    scannerService.enableUltraFastMode();
    alert('Mode ultra-rapide activé ! Essayez de scanner maintenant.');
  };

  const handleContinuousCapture = () => {
    const scannerService = BarcodeScannerService.getInstance();
    console.log('🔄 Activation du mode capture continue...');
    scannerService.enableContinuousCaptureMode();
    alert('Mode capture continue activé ! Le scanner va accumuler tous les caractères. Essayez de scanner maintenant.');
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
          
          <Button
            variant="outlined"
            size="small"
            onClick={handleForceBuffer}
            color="error"
          >
            Forcer Buffer
          </Button>
          
          <Button
            variant="outlined"
            size="small"
            onClick={handleDiagnostic}
            color="info"
          >
            Diagnostic
          </Button>
          
          <Button
            variant="outlined"
            size="small"
            onClick={handleCompatibilityTest}
            color="secondary"
          >
            Test Compatibilité
          </Button>
          
          <Button
            variant="outlined"
            size="small"
            onClick={handleUltraFastMode}
            color="success"
          >
            Mode Ultra-Rapide
          </Button>
          
          <Button
            variant="outlined"
            size="small"
            onClick={handleContinuousCapture}
            color="primary"
          >
            Capture Continue
          </Button>
        </Box>

        <Typography variant="caption" color="text.secondary">
          Le scanner écoute les événements clavier. Scannez un code-barres ou utilisez les boutons de test.
        </Typography>
        
        <Typography variant="caption" color="warning.main" sx={{ display: 'block', mt: 1 }}>
          💡 Conseil: Utilisez un code-barres d'un produit existant pour tester la recherche.
        </Typography>
        
        <Typography variant="caption" color="error.main" sx={{ display: 'block', mt: 1 }}>
          ⚠️ Si le scanner ne capture que les premiers chiffres (ex: 20093049 au lieu de 2009304971731):
          <br/>• Cliquez sur "Capture Continue" pour accumuler tous les caractères
          <br/>• Ou essayez "Mode Ultra-Rapide" pour les scanners très rapides
          <br/>• Vérifiez qu'il n'y a qu'un seul code-barres sur l'étiquette
          <br/>• Assurez-vous que le scanner est configuré pour EAN-13
          <br/>• Utilisez "Diagnostic" pour voir ce qui est capturé
        </Typography>
      </CardContent>
    </Card>
  );
};

export default ScannerDebugPanel;
