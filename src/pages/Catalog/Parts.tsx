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

const Parts: React.FC = () => {
  const { parts } = useAppStore();

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
        <Button variant="contained" startIcon={<AddIcon />}>
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

export default Parts;
