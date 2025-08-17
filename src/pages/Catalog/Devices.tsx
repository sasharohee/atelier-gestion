import React from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Grid,
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
  Phone as PhoneIcon,
  Laptop as LaptopIcon,
  Tablet as TabletIcon,
  Computer as ComputerIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { deviceTypeColors } from '../../theme';

const Devices: React.FC = () => {
  const { devices } = useAppStore();

  const getDeviceTypeIcon = (type: string) => {
    const icons = {
      smartphone: <PhoneIcon />,
      tablet: <TabletIcon />,
      laptop: <LaptopIcon />,
      desktop: <ComputerIcon />,
      other: <ComputerIcon />,
    };
    return icons[type as keyof typeof icons] || <ComputerIcon />;
  };

  const getDeviceTypeColor = (type: string) => {
    return deviceTypeColors[type as keyof typeof deviceTypeColors] || '#757575';
  };

  const getDeviceTypeLabel = (type: string) => {
    const labels = {
      smartphone: 'Smartphone',
      tablet: 'Tablette',
      laptop: 'Ordinateur portable',
      desktop: 'Ordinateur fixe',
      other: 'Autre',
    };
    return labels[type as keyof typeof labels] || type;
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Appareils
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gestion des modèles d'appareils
        </Typography>
      </Box>

      {/* Actions */}
      <Box sx={{ mb: 3 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
        >
          Nouvel appareil
        </Button>
      </Box>

      {/* Liste des appareils */}
      <Card>
        <CardContent>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Appareil</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell>Numéro de série</TableCell>
                  <TableCell>Spécifications</TableCell>
                  <TableCell>Date de création</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {devices.map((device) => (
                  <TableRow key={device.id}>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Box
                          sx={{
                            backgroundColor: getDeviceTypeColor(device.type),
                            borderRadius: 1,
                            p: 1,
                            mr: 2,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                          }}
                        >
                          {getDeviceTypeIcon(device.type)}
                        </Box>
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {device.brand} {device.model}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={getDeviceTypeLabel(device.type)}
                        size="small"
                        sx={{ backgroundColor: getDeviceTypeColor(device.type), color: 'white' }}
                      />
                    </TableCell>
                    <TableCell>{device.serialNumber || '-'}</TableCell>
                    <TableCell>
                      <Typography variant="body2" color="text.secondary">
                        {device.specifications ? Object.entries(device.specifications).map(([key, value]) => `${key}: ${value}`).join(', ') : '-'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      {new Date(device.createdAt).toLocaleDateString('fr-FR')}
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

export default Devices;
