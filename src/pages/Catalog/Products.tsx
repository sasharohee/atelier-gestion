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

const Products: React.FC = () => {
  const { products, addProduct } = useAppStore();
  const [openDialog, setOpenDialog] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    category: 'accessoire',
    price: 0,
    stockQuantity: 0,
    isActive: true,
  });

  const productCategories = [
    { value: 'accessoire', label: 'Accessoire' },
    { value: 'protection', label: 'Protection' },
    { value: 'connectique', label: 'Connectique' },
    { value: 'logiciel', label: 'Logiciel' },
    { value: 'autre', label: 'Autre' },
  ];

  const handleOpenDialog = () => {
    setOpenDialog(true);
    setError(null);
    setFormData({
      name: '',
      description: '',
      category: 'accessoire',
      price: 0,
      stockQuantity: 0,
      isActive: true,
    });
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setError(null);
  };

  const handleInputChange = (field: string, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleSubmit = async () => {
    if (!formData.name) {
      setError('Le nom du produit est obligatoire');
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
      const newProduct = {
        name: formData.name,
        description: formData.description,
        category: formData.category,
        price: formData.price,
        stockQuantity: formData.stockQuantity,
        isActive: formData.isActive,
      };

      await addProduct(newProduct as any);
      handleCloseDialog();
    } catch (err) {
      setError('Erreur lors de la création du produit');
      console.error('Erreur création produit:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Produits
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Produits et accessoires
        </Typography>
      </Box>

      <Box sx={{ mb: 3 }}>
        <Button 
          variant="contained" 
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
        >
          Nouveau produit
        </Button>
      </Box>

      <Card>
        <CardContent>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Produit</TableCell>
                  <TableCell>Catégorie</TableCell>
                  <TableCell>Stock</TableCell>
                  <TableCell>Prix</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {products.map((product) => (
                  <TableRow key={product.id}>
                    <TableCell>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {product.name}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {product.description}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip label={product.category} size="small" />
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={`${product.stockQuantity} en stock`}
                        color={product.stockQuantity === 0 ? 'error' : 'success'}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>{product.price} €</TableCell>
                    <TableCell>
                      <Chip
                        label={product.isActive ? 'Actif' : 'Inactif'}
                        color={product.isActive ? 'success' : 'default'}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 1 }}>
                        <IconButton size="small" title="Modifier">
                          <EditIcon fontSize="small" />
                        </IconButton>
                        <IconButton size="small" title="Supprimer" color="error">
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

      {/* Dialogue de création */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>Créer un nouveau produit</DialogTitle>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}
          
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Nom du produit *"
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
              rows={3}
            />
            
            <FormControl fullWidth>
              <InputLabel>Catégorie</InputLabel>
              <Select
                value={formData.category}
                label="Catégorie"
                onChange={(e) => handleInputChange('category', e.target.value)}
              >
                {productCategories.map((category) => (
                  <MenuItem key={category.value} value={category.value}>
                    {category.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
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
                label="Stock"
                type="number"
                value={formData.stockQuantity}
                onChange={(e) => handleInputChange('stockQuantity', parseInt(e.target.value) || 0)}
                inputProps={{ min: 0 }}
              />
            </Box>
            
            <FormControlLabel
              control={
                <Switch
                  checked={formData.isActive}
                  onChange={(e) => handleInputChange('isActive', e.target.checked)}
                />
              }
              label="Produit actif"
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
            disabled={loading || !formData.name}
          >
            {loading ? 'Création...' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Products;
