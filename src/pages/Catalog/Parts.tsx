import React, { useState } from 'react';
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
  Switch,
  FormControlLabel,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

const Parts: React.FC = () => {
  const { parts, addPart, deletePart, updatePart } = useAppStore();
  const [openDialog, setOpenDialog] = useState(false);
  const [editingPart, setEditingPart] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    partNumber: '',
    brand: '',
    compatibleDevices: [] as string[],
    stockQuantity: 0,
    minStockLevel: 1,
    price: 0,
    supplier: '',
    isActive: true,
  });

  const deviceTypes = [
    { value: 'smartphone', label: 'Smartphone' },
    { value: 'tablet', label: 'Tablette' },
    { value: 'laptop', label: 'Ordinateur portable' },
    { value: 'desktop', label: 'Ordinateur fixe' },
    { value: 'other', label: 'Autre' },
  ];

  const handleOpenDialog = (part?: any) => {
    setOpenDialog(true);
    setError(null);
    if (part) {
      setEditingPart(part.id);
      setFormData({
        name: part.name,
        description: part.description,
        partNumber: part.partNumber,
        brand: part.brand,
        compatibleDevices: part.compatibleDevices || [],
        stockQuantity: part.stockQuantity,
        minStockLevel: part.minStockLevel,
        price: part.price,
        supplier: part.supplier,
        isActive: part.isActive,
      });
    } else {
      setEditingPart(null);
      setFormData({
        name: '',
        description: '',
        partNumber: '',
        brand: '',
        compatibleDevices: [],
        stockQuantity: 0,
        minStockLevel: 1,
        price: 0,
        supplier: '',
        isActive: true,
      });
    }
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setError(null);
    setEditingPart(null);
  };

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleDeletePart = async (partId: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer cette pièce ?')) {
      try {
        await deletePart(partId);
      } catch (error) {
        console.error('Erreur lors de la suppression de la pièce:', error);
        alert('Erreur lors de la suppression de la pièce');
      }
    }
  };

  const handleSubmit = async () => {
    if (!formData.name || !formData.partNumber || !formData.brand) {
      setError('Le nom, la référence et la marque sont obligatoires');
      return;
    }

    if (formData.price < 0) {
      setError('Le prix ne peut pas être négatif');
      return;
    }

    if (formData.stockQuantity < 0) {
      setError('Le stock ne peut pas être négatif');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      if (editingPart) {
        // Mode édition
        await updatePart(editingPart, {
          name: formData.name,
          description: formData.description,
          partNumber: formData.partNumber,
          brand: formData.brand,
          compatibleDevices: formData.compatibleDevices,
          stockQuantity: formData.stockQuantity,
          minStockLevel: formData.minStockLevel,
          price: formData.price,
          supplier: formData.supplier || undefined,
          isActive: formData.isActive,
        });
      } else {
        // Mode création
        const newPart = {
          name: formData.name,
          description: formData.description,
          partNumber: formData.partNumber,
          brand: formData.brand,
          compatibleDevices: formData.compatibleDevices,
          stockQuantity: formData.stockQuantity,
          minStockLevel: formData.minStockLevel,
          price: formData.price,
          supplier: formData.supplier || undefined,
          isActive: formData.isActive,
        };

        await addPart(newPart as any);
      }
      
      handleCloseDialog();
    } catch (err) {
      setError('Erreur lors de la sauvegarde de la pièce');
      console.error('Erreur sauvegarde pièce:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Pièces détachées
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Stock des pièces détachées
        </Typography>
      </Box>

      <Box sx={{ mb: 3 }}>
        <Button 
          variant="contained" 
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
        >
          Nouvelle pièce
        </Button>
      </Box>

      <Card>
        <CardContent>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Pièce</TableCell>
                  <TableCell>Référence</TableCell>
                  <TableCell>Marque</TableCell>
                  <TableCell>Stock</TableCell>
                  <TableCell>Prix</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {parts.map((part) => (
                  <TableRow key={part.id}>
                    <TableCell>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {part.name}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {part.description}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>{part.partNumber}</TableCell>
                    <TableCell>{part.brand}</TableCell>
                    <TableCell>
                      <Chip
                        label={`${part.stockQuantity} en stock`}
                        color={part.stockQuantity <= part.minStockLevel ? 'warning' : 'success'}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>{part.price} €</TableCell>
                    <TableCell>
                      <Chip
                        label={part.isActive ? 'Actif' : 'Inactif'}
                        color={part.isActive ? 'success' : 'default'}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 1 }}>
                        <IconButton 
                          size="small" 
                          title="Modifier"
                          onClick={() => handleOpenDialog(part)}
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                        <IconButton 
                          size="small" 
                          title="Supprimer" 
                          color="error"
                          onClick={() => handleDeletePart(part.id)}
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Box>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Dialogue de création/édition */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>{editingPart ? 'Modifier la pièce' : 'Créer une nouvelle pièce'}</DialogTitle>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Nom de la pièce *"
              value={formData.name}
              onChange={(e) => handleInputChange('name', e.target.value)}
              required
            />
            
            <TextField
              fullWidth
              label="Description"
              value={formData.description}
              onChange={(e) => handleInputChange('description', e.target.value)}
              multiline
              rows={2}
            />
            
            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                fullWidth
                label="Référence *"
                value={formData.partNumber}
                onChange={(e) => handleInputChange('partNumber', e.target.value)}
                required
              />
              
              <TextField
                fullWidth
                label="Marque *"
                value={formData.brand}
                onChange={(e) => handleInputChange('brand', e.target.value)}
                required
              />
            </Box>
            
            <FormControl fullWidth>
              <InputLabel>Appareils compatibles</InputLabel>
              <Select
                multiple
                value={formData.compatibleDevices}
                label="Appareils compatibles"
                onChange={(e) => handleInputChange('compatibleDevices', e.target.value)}
              >
                {deviceTypes.map((type) => (
                  <MenuItem key={type.value} value={type.value}>
                    {type.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                fullWidth
                label="Stock actuel"
                type="number"
                value={formData.stockQuantity}
                onChange={(e) => handleInputChange('stockQuantity', parseInt(e.target.value) || 0)}
                inputProps={{ min: 0 }}
              />
              
              <TextField
                fullWidth
                label="Stock minimum"
                type="number"
                value={formData.minStockLevel}
                onChange={(e) => handleInputChange('minStockLevel', parseInt(e.target.value) || 0)}
                inputProps={{ min: 0 }}
              />
            </Box>
            
            <Box sx={{ display: 'flex', gap: 2 }}>
              <TextField
                fullWidth
                label="Prix (€)"
                type="number"
                value={formData.price}
                onChange={(e) => handleInputChange('price', parseFloat(e.target.value) || 0)}
                inputProps={{ min: 0, step: 0.01 }}
              />
              
              <TextField
                fullWidth
                label="Fournisseur"
                value={formData.supplier}
                onChange={(e) => handleInputChange('supplier', e.target.value)}
              />
            </Box>
            
            <FormControlLabel
              control={
                <Switch
                  checked={formData.isActive}
                  onChange={(e) => handleInputChange('isActive', e.target.checked)}
                />
              }
              label="Pièce active"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog} disabled={loading}>
            Annuler
          </Button>
          <Button 
            onClick={handleSubmit} 
            variant="contained" 
            disabled={loading || !formData.name || !formData.partNumber || !formData.brand}
          >
            {loading ? (editingPart ? 'Modification...' : 'Création...') : (editingPart ? 'Modifier' : 'Créer')}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Parts;
