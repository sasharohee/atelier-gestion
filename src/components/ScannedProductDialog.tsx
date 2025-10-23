import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Card,
  CardContent,
  Chip,
  Alert,
  CircularProgress,
  Divider,
} from '@mui/material';
import {
  CheckCircle as CheckIcon,
  Error as ErrorIcon,
  QrCode2 as BarcodeIcon,
} from '@mui/icons-material';
import { formatFromEUR } from '../utils/currencyUtils';
import BarcodeDisplay from './BarcodeDisplay';

interface ScannedProductDialogProps {
  open: boolean;
  onClose: () => void;
  product: any | null;
  loading: boolean;
  error: string | null;
  barcode: string | null;
}

const ScannedProductDialog: React.FC<ScannedProductDialogProps> = ({
  open,
  onClose,
  product,
  loading,
  error,
  barcode,
}) => {
  return (
    <Dialog 
      open={open} 
      onClose={onClose} 
      maxWidth="md" 
      fullWidth
      PaperProps={{
        sx: { minHeight: '400px' }
      }}
    >
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <BarcodeIcon color="primary" />
        <Box>
          <Typography variant="h6">
            {loading ? 'Recherche du produit...' : 
             product ? 'Produit trouvé' : 
             error ? 'Erreur de recherche' : 
             'Code-barres scanné'}
          </Typography>
          {barcode && (
            <Typography variant="body2" color="text.secondary">
              Code-barres: {barcode}
            </Typography>
          )}
        </Box>
      </DialogTitle>

      <DialogContent>
        {loading && (
          <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', py: 4 }}>
            <CircularProgress />
            <Typography variant="body1" sx={{ ml: 2 }}>
              Recherche du produit...
            </Typography>
          </Box>
        )}

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            <Typography variant="body1" fontWeight="bold">
              Produit non trouvé
            </Typography>
            <Typography variant="body2">
              {error}
            </Typography>
          </Alert>
        )}

        {product && (
          <Card variant="outlined">
            <CardContent>
              <Box sx={{ display: 'flex', gap: 3, mb: 2 }}>
                <Box sx={{ flex: 1 }}>
                  <Typography variant="h6" gutterBottom>
                    {product.name}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    {product.description}
                  </Typography>
                  
                  <Box sx={{ display: 'flex', gap: 1, mb: 2 }}>
                    <Chip 
                      label={product.category} 
                      size="small" 
                      color="primary" 
                      variant="outlined"
                    />
                    <Chip 
                      label={product.isActive ? 'Actif' : 'Inactif'} 
                      size="small" 
                      color={product.isActive ? 'success' : 'default'}
                    />
                  </Box>
                </Box>

                <Box sx={{ textAlign: 'right', minWidth: '120px' }}>
                  <Typography variant="h5" color="primary" fontWeight="bold">
                    {formatFromEUR(product.price)} €
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Prix HT
                  </Typography>
                </Box>
              </Box>

              <Divider sx={{ my: 2 }} />

              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="body1" fontWeight="bold">
                  Stock disponible
                </Typography>
                <Typography 
                  variant="h6" 
                  color={product.stockQuantity > product.minStockLevel ? 'success.main' : 'warning.main'}
                >
                  {product.stockQuantity} unités
                </Typography>
              </Box>

              {product.stockQuantity <= product.minStockLevel && (
                <Alert severity="warning" sx={{ mb: 2 }}>
                  Stock faible ! Seuil minimum: {product.minStockLevel} unités
                </Alert>
              )}

              {product.barcode && (
                <Box sx={{ mt: 3 }}>
                  <Typography variant="body1" fontWeight="bold" gutterBottom>
                    Code-barres
                  </Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <BarcodeDisplay 
                      barcode={product.barcode}
                      width={200}
                      height={60}
                      showValue={true}
                    />
                  </Box>
                </Box>
              )}
            </CardContent>
          </Card>
        )}

        {!loading && !product && !error && barcode && (
          <Box sx={{ textAlign: 'center', py: 4 }}>
            <ErrorIcon color="disabled" sx={{ fontSize: 48, mb: 2 }} />
            <Typography variant="h6" color="text.secondary" gutterBottom>
              Aucun produit trouvé
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Le code-barres "{barcode}" ne correspond à aucun produit enregistré.
            </Typography>
          </Box>
        )}
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose} variant="outlined">
          Fermer
        </Button>
        {product && (
          <Button 
            onClick={onClose} 
            variant="contained" 
            startIcon={<CheckIcon />}
            color="success"
          >
            Produit identifié
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default ScannedProductDialog;
