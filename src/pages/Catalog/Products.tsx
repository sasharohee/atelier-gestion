import React from 'react';
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
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

const Products: React.FC = () => {
  const { products } = useAppStore();

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
        <Button variant="contained" startIcon={<AddIcon />}>
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
    </Box>
  );
};

export default Products;
