import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  Snackbar,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

const OutOfStock: React.FC = () => {
  const { 
    getActiveStockAlerts, 
    parts, 
    products,
    addStockAlert, 
    resolveStockAlert, 
    deleteStockAlert,
    loadStockAlerts 
  } = useAppStore();
  
  const [openDialog, setOpenDialog] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    partId: '',
    type: 'low_stock' as 'low_stock' | 'out_of_stock',
    message: '',
  });

  const stockAlerts = getActiveStockAlerts();

  // Charger les alertes au montage du composant
  useEffect(() => {
    loadStockAlerts();
  }, [loadStockAlerts]);

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleSubmit = async () => {
    if (!formData.partId || !formData.message) {
      setError('Veuillez remplir tous les champs obligatoires');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      await addStockAlert({
        partId: formData.partId,
        type: formData.type,
        message: formData.message,
        isResolved: false,
      });
      
      setSuccess('Alerte créée avec succès');
      handleCloseDialog();
    } catch (err) {
      setError('Erreur lors de la création de l\'alerte');
      console.error('Erreur création alerte:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setFormData({
      partId: '',
      type: 'low_stock',
      message: '',
    });
    setError(null);
  };

  const handleResolveAlert = async (alertId: string) => {
    try {
      await resolveStockAlert(alertId);
      setSuccess('Alerte marquée comme résolue');
    } catch (err) {
      setError('Erreur lors de la résolution de l\'alerte');
      console.error('Erreur résolution alerte:', err);
    }
  };

  const handleDeleteAlert = async (alertId: string) => {
    try {
      await deleteStockAlert(alertId);
      setSuccess('Alerte supprimée avec succès');
    } catch (err) {
      setError('Erreur lors de la suppression de l\'alerte');
      console.error('Erreur suppression alerte:', err);
    }
  };

  const handleCloseSnackbar = () => {
    setSuccess(null);
    setError(null);
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Ruptures de stock
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Alertes et ruptures de stock
        </Typography>
      </Box>

      <Box sx={{ mb: 3 }}>
        <Button 
          variant="contained" 
          startIcon={<AddIcon />}
          onClick={() => setOpenDialog(true)}
        >
          Nouvelle alerte
        </Button>
      </Box>

      <Card>
        <CardContent>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Article</TableCell>
                  <TableCell>Type d'alerte</TableCell>
                  <TableCell>Stock actuel</TableCell>
                  <TableCell>Seuil minimum</TableCell>
                  <TableCell>Date d'alerte</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {stockAlerts.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} align="center">
                      <Typography variant="body2" color="text.secondary">
                        Aucune alerte de stock active
                      </Typography>
                    </TableCell>
                  </TableRow>
                ) : (
                  stockAlerts.map((alert) => {
                    const part = parts.find(p => p.id === alert.partId);
                    const product = products.find(p => p.id === alert.partId);
                    const item = part || product;
                    return (
                      <TableRow key={alert.id}>
                        <TableCell>
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 600 }}>
                              {item?.name || 'Article inconnu'}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {part ? part.partNumber : product ? product.category : 'N/A'}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Chip
                            icon={<WarningIcon />}
                            label={alert.type === 'low_stock' ? 'Stock faible' : 'Rupture'}
                            color={alert.type === 'low_stock' ? 'warning' : 'error'}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {part ? part.stockQuantity : product ? product.stockQuantity : 0}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          {part ? part.minStockLevel : product ? product.minStockLevel : 0}
                        </TableCell>
                        <TableCell>
                          {new Date(alert.createdAt).toLocaleDateString('fr-FR')}
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={alert.isResolved ? 'Résolue' : 'En attente'}
                            color={alert.isResolved ? 'success' : 'warning'}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', gap: 1 }}>
                            <IconButton 
                              size="small" 
                              title="Marquer comme résolue"
                              onClick={() => handleResolveAlert(alert.id)}
                              color="success"
                            >
                              <CheckCircleIcon fontSize="small" />
                            </IconButton>
                            <IconButton 
                              size="small" 
                              title="Supprimer" 
                              color="error"
                              onClick={() => handleDeleteAlert(alert.id)}
                            >
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Box>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Modal de création d'alerte */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>Nouvelle alerte de stock</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 2, display: 'flex', flexDirection: 'column', gap: 2 }}>
            <FormControl fullWidth>
              <InputLabel>Article</InputLabel>
              <Select
                value={formData.partId}
                onChange={(e) => handleInputChange('partId', e.target.value)}
                label="Article"
              >
                {parts.map((part) => (
                  <MenuItem key={`part-${part.id}`} value={part.id}>
                    🔩 {part.name} ({part.partNumber})
                  </MenuItem>
                ))}
                {products.map((product) => (
                  <MenuItem key={`product-${product.id}`} value={product.id}>
                    🛍️ {product.name} ({product.category})
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <FormControl fullWidth>
              <InputLabel>Type d'alerte</InputLabel>
              <Select
                value={formData.type}
                onChange={(e) => handleInputChange('type', e.target.value)}
                label="Type d'alerte"
              >
                <MenuItem value="low_stock">Stock faible</MenuItem>
                <MenuItem value="out_of_stock">Rupture de stock</MenuItem>
              </Select>
            </FormControl>

            <TextField
              label="Message"
              value={formData.message}
              onChange={(e) => handleInputChange('message', e.target.value)}
              multiline
              rows={3}
              fullWidth
              placeholder="Description de l'alerte..."
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Annuler</Button>
          <Button 
            onClick={handleSubmit} 
            variant="contained" 
            disabled={loading}
          >
            {loading ? 'Création...' : 'Créer l\'alerte'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar pour les messages */}
      <Snackbar
        open={!!success || !!error}
        autoHideDuration={6000}
        onClose={handleCloseSnackbar}
      >
        <Alert 
          onClose={handleCloseSnackbar} 
          severity={success ? 'success' : 'error'}
          sx={{ width: '100%' }}
        >
          {success || error}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default OutOfStock;
