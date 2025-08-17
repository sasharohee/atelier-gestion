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
  Warning as WarningIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

const OutOfStock: React.FC = () => {
  const { getActiveStockAlerts, parts } = useAppStore();
  const stockAlerts = getActiveStockAlerts();

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
        <Button variant="contained" startIcon={<AddIcon />}>
          Nouvelle alerte
        </Button>
      </Box>

      <Card>
        <CardContent>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Pièce</TableCell>
                  <TableCell>Type d'alerte</TableCell>
                  <TableCell>Stock actuel</TableCell>
                  <TableCell>Seuil minimum</TableCell>
                  <TableCell>Date d'alerte</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {stockAlerts.map((alert) => {
                  const part = parts.find(p => p.id === alert.partId);
                  return (
                    <TableRow key={alert.id}>
                      <TableCell>
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {part?.name || 'Pièce inconnue'}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {part?.partNumber || 'N/A'}
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
                          {part?.stockQuantity || 0}
                        </Typography>
                      </TableCell>
                      <TableCell>{part?.minStockLevel || 0}</TableCell>
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
                          <IconButton size="small" title="Marquer comme résolue">
                            <EditIcon fontSize="small" />
                          </IconButton>
                          <IconButton size="small" title="Supprimer" color="error">
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        </Box>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
    </Box>
  );
};

export default OutOfStock;
