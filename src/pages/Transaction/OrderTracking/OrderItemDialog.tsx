import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Grid,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Typography,
  Box,
  Fab,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material';
import { OrderItem } from '../../../types/order';

interface OrderItemDialogProps {
  open: boolean;
  items: OrderItem[];
  onClose: () => void;
  onSave: (items: OrderItem[]) => void;
}

const OrderItemDialog: React.FC<OrderItemDialogProps> = ({
  open,
  items,
  onClose,
  onSave
}) => {
  const [orderItems, setOrderItems] = useState<OrderItem[]>(items);
  const [editingItem, setEditingItem] = useState<OrderItem | null>(null);
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    setOrderItems(items);
  }, [items]);

  const handleAddItem = () => {
    const newItem: OrderItem = {
      id: Date.now().toString(),
      productName: '',
      quantity: 1,
      unitPrice: 0,
      totalPrice: 0,
      description: ''
    };
    setEditingItem(newItem);
    setIsAdding(true);
  };

  const handleEditItem = (item: OrderItem) => {
    setEditingItem({ ...item });
    setIsAdding(false);
  };

  const handleDeleteItem = (itemId: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer cet article ?')) {
      setOrderItems(prev => prev.filter(item => item.id !== itemId));
    }
  };

  const handleSaveItem = () => {
    if (!editingItem) return;

    // Calculer le prix total
    const totalPrice = editingItem.quantity * editingItem.unitPrice;
    const updatedItem = { ...editingItem, totalPrice };

    if (isAdding) {
      setOrderItems(prev => [...prev, updatedItem]);
    } else {
      setOrderItems(prev => prev.map(item => 
        item.id === updatedItem.id ? updatedItem : item
      ));
    }

    setEditingItem(null);
    setIsAdding(false);
  };

  const handleCancelEdit = () => {
    setEditingItem(null);
    setIsAdding(false);
  };

  const handleSaveAll = () => {
    onSave(orderItems);
    onClose();
  };

  const totalAmount = orderItems.reduce((sum, item) => sum + item.totalPrice, 0);

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        Gestion des Articles de Commande
      </DialogTitle>
      <DialogContent>
        <Box sx={{ mb: 3 }}>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs>
              <Typography variant="h6">
                Articles ({orderItems.length})
              </Typography>
            </Grid>
            <Grid item>
              <Typography variant="h6" color="primary" sx={{ fontWeight: 600 }}>
                Total: {totalAmount.toLocaleString('fr-FR', {
                  style: 'currency',
                  currency: 'EUR'
                })}
              </Typography>
            </Grid>
          </Grid>
        </Box>

        {/* Formulaire d'édition d'article */}
        {editingItem && (
          <Paper sx={{ p: 2, mb: 2 }}>
            <Typography variant="subtitle1" gutterBottom>
              {isAdding ? 'Ajouter un article' : 'Modifier l\'article'}
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nom du produit"
                  value={editingItem.productName}
                  onChange={(e) => setEditingItem({
                    ...editingItem,
                    productName: e.target.value
                  })}
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <TextField
                  fullWidth
                  label="Quantité"
                  type="number"
                  value={editingItem.quantity}
                  onChange={(e) => setEditingItem({
                    ...editingItem,
                    quantity: parseInt(e.target.value) || 0
                  })}
                />
              </Grid>
              <Grid item xs={12} md={3}>
                <TextField
                  fullWidth
                  label="Prix unitaire (€)"
                  type="number"
                  value={editingItem.unitPrice}
                  onChange={(e) => setEditingItem({
                    ...editingItem,
                    unitPrice: parseFloat(e.target.value) || 0
                  })}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Description"
                  multiline
                  rows={2}
                  value={editingItem.description}
                  onChange={(e) => setEditingItem({
                    ...editingItem,
                    description: e.target.value
                  })}
                />
              </Grid>
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', gap: 1 }}>
                  <Button
                    variant="contained"
                    startIcon={<SaveIcon />}
                    onClick={handleSaveItem}
                    disabled={!editingItem.productName}
                  >
                    Enregistrer
                  </Button>
                  <Button
                    variant="outlined"
                    startIcon={<CancelIcon />}
                    onClick={handleCancelEdit}
                  >
                    Annuler
                  </Button>
                </Box>
              </Grid>
            </Grid>
          </Paper>
        )}

        {/* Liste des articles */}
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Produit</TableCell>
                <TableCell>Description</TableCell>
                <TableCell align="right">Quantité</TableCell>
                <TableCell align="right">Prix unitaire</TableCell>
                <TableCell align="right">Total</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {orderItems.map((item) => (
                <TableRow key={item.id} hover>
                  <TableCell>
                    <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                      {item.productName}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">
                      {item.description}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    {item.quantity}
                  </TableCell>
                  <TableCell align="right">
                    {item.unitPrice.toLocaleString('fr-FR', {
                      style: 'currency',
                      currency: 'EUR'
                    })}
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                      {item.totalPrice.toLocaleString('fr-FR', {
                        style: 'currency',
                        currency: 'EUR'
                      })}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <IconButton
                      size="small"
                      onClick={() => handleEditItem(item)}
                      title="Modifier"
                    >
                      <EditIcon />
                    </IconButton>
                    <IconButton
                      size="small"
                      onClick={() => handleDeleteItem(item.id)}
                      title="Supprimer"
                      color="error"
                    >
                      <DeleteIcon />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        {/* Bouton flottant pour ajouter un article */}
        <Tooltip title="Ajouter un article">
          <Fab
            color="primary"
            aria-label="add item"
            sx={{ position: 'fixed', bottom: 80, right: 16 }}
            onClick={handleAddItem}
          >
            <AddIcon />
          </Fab>
        </Tooltip>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Annuler</Button>
        <Button onClick={handleSaveAll} variant="contained">
          Enregistrer les articles
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default OrderItemDialog;
