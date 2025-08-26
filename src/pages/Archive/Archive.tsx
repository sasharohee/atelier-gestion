import React, { useState, useMemo } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Chip,
  Avatar,
  Button,
  IconButton,
  Grid,
  Tooltip,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Pagination,
  FormControlLabel,
  Switch,
  Alert,
  Divider,
  Badge,
  Dialog,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Phone as PhoneIcon,
  Laptop as LaptopIcon,
  Tablet as TabletIcon,
  Computer as ComputerIcon,
  Search as SearchIcon,
  FilterList as FilterListIcon,
  Receipt as ReceiptIcon,
  Print as PrintIcon,
  Email as EmailIcon,
  Archive as ArchiveIcon,
  RestoreFromTrash as RestoreIcon,
  Delete as DeleteIcon,
  CalendarToday as CalendarIcon,
  Person as PersonIcon,
  DeviceHub as DeviceIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { deviceTypeColors } from '../../theme';
import { Repair, Device, Client } from '../../types';
import Invoice from '../../components/Invoice';

const Archive: React.FC = () => {
  const {
    repairs,
    clients,
    devices,
    getClientById,
    getDeviceById,
    updateRepair,
    deleteRepair,
  } = useAppStore();

  // Filtrer uniquement les réparations restituées
  const archivedRepairs = useMemo(() => {
    return repairs.filter(repair => repair.status === 'returned');
  }, [repairs]);

  // États pour la recherche et le filtrage
  const [searchQuery, setSearchQuery] = useState('');
  const [deviceTypeFilter, setDeviceTypeFilter] = useState<string>('all');
  const [dateFilter, setDateFilter] = useState<string>('all');
  const [showPaidOnly, setShowPaidOnly] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(10);

  // États pour les modales
  const [invoiceOpen, setInvoiceOpen] = useState(false);
  const [selectedRepairForInvoice, setSelectedRepairForInvoice] = useState<Repair | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [repairToDelete, setRepairToDelete] = useState<Repair | null>(null);

  // Filtrer les réparations selon les critères
  const filteredRepairs = useMemo(() => {
    let filtered = archivedRepairs;

    // Filtre par recherche textuelle
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(repair => {
        const client = getClientById(repair.clientId);
        const device = getDeviceById(repair.deviceId);
        
        return (
          client?.firstName?.toLowerCase().includes(query) ||
          client?.lastName?.toLowerCase().includes(query) ||
          client?.email?.toLowerCase().includes(query) ||
          device?.brand?.toLowerCase().includes(query) ||
          device?.model?.toLowerCase().includes(query) ||
          repair.description?.toLowerCase().includes(query) ||
          repair.issue?.toLowerCase().includes(query)
        );
      });
    }

    // Filtre par type d'appareil
    if (deviceTypeFilter !== 'all') {
      filtered = filtered.filter(repair => {
        const device = getDeviceById(repair.deviceId);
        return device?.type === deviceTypeFilter;
      });
    }

    // Filtre par date
    if (dateFilter !== 'all') {
      const now = new Date();
      const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
      const oneYearAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);

      filtered = filtered.filter(repair => {
        const repairDate = new Date(repair.updatedAt || repair.createdAt);
        
        switch (dateFilter) {
          case '30days':
            return repairDate >= thirtyDaysAgo;
          case '90days':
            return repairDate >= ninetyDaysAgo;
          case '1year':
            return repairDate >= oneYearAgo;
          default:
            return true;
        }
      });
    }

    // Filtre par statut de paiement
    if (showPaidOnly) {
      filtered = filtered.filter(repair => repair.isPaid);
    }

    return filtered;
  }, [archivedRepairs, searchQuery, deviceTypeFilter, dateFilter, showPaidOnly, getClientById, getDeviceById]);

  // Pagination
  const totalPages = Math.ceil(filteredRepairs.length / itemsPerPage);
  const paginatedRepairs = filteredRepairs.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  // Fonctions utilitaires
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

  const safeFormatDate = (date: any, formatString: string) => {
    try {
      if (!date) return 'Date inconnue';
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) return 'Date invalide';
      return format(dateObj, formatString, { locale: fr });
    } catch (error) {
      console.error('Erreur de formatage de date:', error);
      return 'Date invalide';
    }
  };

  const handleOpenInvoice = (repair: Repair) => {
    setSelectedRepairForInvoice(repair);
    setInvoiceOpen(true);
  };

  const handleDeleteRepair = (repair: Repair) => {
    setRepairToDelete(repair);
    setDeleteDialogOpen(true);
  };

  const confirmDeleteRepair = async () => {
    if (repairToDelete) {
      await deleteRepair(repairToDelete.id);
      setDeleteDialogOpen(false);
      setRepairToDelete(null);
    }
  };

  const handleRestoreRepair = async (repair: Repair) => {
    // Remettre la réparation en statut "completed" pour qu'elle réapparaisse dans le Kanban
    await updateRepair(repair.id, { status: 'completed' });
  };

  return (
    <Box sx={{ p: 3 }}>
      {/* En-tête */}
      <Box sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
        <ArchiveIcon sx={{ fontSize: 32, color: 'primary.main' }} />
        <Typography variant="h4" component="h1">
          Archives des Réparations
        </Typography>
        <Badge badgeContent={archivedRepairs.length} color="primary">
          <Chip label="Restituées" color="primary" variant="outlined" />
        </Badge>
      </Box>

      {/* Filtres et recherche */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Rechercher..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                }}
              />
            </Grid>
            <Grid item xs={12} md={2}>
              <FormControl fullWidth>
                <InputLabel>Type d'appareil</InputLabel>
                <Select
                  value={deviceTypeFilter}
                  onChange={(e) => setDeviceTypeFilter(e.target.value)}
                  label="Type d'appareil"
                >
                  <MenuItem value="all">Tous les types</MenuItem>
                  <MenuItem value="smartphone">Smartphone</MenuItem>
                  <MenuItem value="tablet">Tablette</MenuItem>
                  <MenuItem value="laptop">Ordinateur portable</MenuItem>
                  <MenuItem value="desktop">Ordinateur fixe</MenuItem>
                  <MenuItem value="other">Autre</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={2}>
              <FormControl fullWidth>
                <InputLabel>Période</InputLabel>
                <Select
                  value={dateFilter}
                  onChange={(e) => setDateFilter(e.target.value)}
                  label="Période"
                >
                  <MenuItem value="all">Toutes les dates</MenuItem>
                  <MenuItem value="30days">30 derniers jours</MenuItem>
                  <MenuItem value="90days">90 derniers jours</MenuItem>
                  <MenuItem value="1year">1 an</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={2}>
              <FormControlLabel
                control={
                  <Switch
                    checked={showPaidOnly}
                    onChange={(e) => setShowPaidOnly(e.target.checked)}
                  />
                }
                label="Payées uniquement"
              />
            </Grid>
            <Grid item xs={12} md={2}>
              <Typography variant="body2" color="text.secondary">
                {filteredRepairs.length} réparation(s) trouvée(s)
              </Typography>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Tableau des réparations archivées */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Client</TableCell>
              <TableCell>Appareil</TableCell>
              <TableCell>Description</TableCell>
              <TableCell>Date de restitution</TableCell>
              <TableCell>Prix</TableCell>
              <TableCell>Statut paiement</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {paginatedRepairs.map((repair) => {
              const client = getClientById(repair.clientId);
              const device = getDeviceById(repair.deviceId);
              
              return (
                <TableRow key={repair.id} hover>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Avatar sx={{ width: 32, height: 32 }}>
                        <PersonIcon />
                      </Avatar>
                      <Box>
                        <Typography variant="body2" fontWeight="medium">
                          {client ? `${client.firstName} ${client.lastName}` : 'Client inconnu'}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {client?.email || 'Email inconnu'}
                        </Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Avatar 
                        sx={{ 
                          width: 32, 
                          height: 32, 
                          bgcolor: getDeviceTypeColor(device?.type || 'other') 
                        }}
                      >
                        {getDeviceTypeIcon(device?.type || 'other')}
                      </Avatar>
                      <Box>
                        <Typography variant="body2" fontWeight="medium">
                          {device ? `${device.brand} ${device.model}` : 'Appareil inconnu'}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {device?.type || 'Type inconnu'}
                        </Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box>
                      <Typography variant="body2" noWrap sx={{ maxWidth: 200 }}>
                        {repair.description || 'Aucune description'}
                      </Typography>
                      <Typography variant="caption" color="text.secondary" noWrap sx={{ maxWidth: 200 }}>
                        {repair.issue || 'Aucun problème spécifié'}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <CalendarIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                      <Typography variant="body2">
                        {safeFormatDate(repair.updatedAt || repair.createdAt, 'dd/MM/yyyy')}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" fontWeight="medium">
                      {repair.totalPrice ? `${repair.totalPrice.toFixed(2)} €` : '0.00 €'}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={repair.isPaid ? 'Payée' : 'En attente'}
                      color={repair.isPaid ? 'success' : 'warning'}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', gap: 1 }}>
                      <Tooltip title="Voir la facture">
                        <IconButton
                          size="small"
                          onClick={() => handleOpenInvoice(repair)}
                          color="primary"
                        >
                          <ReceiptIcon />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Restaurer">
                        <IconButton
                          size="small"
                          onClick={() => handleRestoreRepair(repair)}
                          color="secondary"
                        >
                          <RestoreIcon />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Supprimer définitivement">
                        <IconButton
                          size="small"
                          onClick={() => handleDeleteRepair(repair)}
                          color="error"
                        >
                          <DeleteIcon />
                        </IconButton>
                      </Tooltip>
                    </Box>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Pagination */}
      {totalPages > 1 && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 3 }}>
          <Pagination
            count={totalPages}
            page={currentPage}
            onChange={(_, page) => setCurrentPage(page)}
            color="primary"
          />
        </Box>
      )}

      {/* Message si aucune réparation */}
      {filteredRepairs.length === 0 && (
        <Alert severity="info" sx={{ mt: 2 }}>
          {archivedRepairs.length === 0 ? (
            <>
              <Typography variant="body1" gutterBottom>
                <strong>Aucune réparation archivée</strong>
              </Typography>
              <Typography variant="body2">
                Les réparations apparaîtront ici automatiquement quand elles seront déplacées vers "Restitué" dans le Kanban.
              </Typography>
            </>
          ) : (
            'Aucune réparation restituée trouvée avec les critères actuels.'
          )}
        </Alert>
      )}

      {/* Modale de facture */}
      {selectedRepairForInvoice && (
        <Invoice
          open={invoiceOpen}
          onClose={() => {
            setInvoiceOpen(false);
            setSelectedRepairForInvoice(null);
          }}
          repair={selectedRepairForInvoice}
        />
      )}

      {/* Dialog de confirmation de suppression */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogContent>
          <Typography>
            Êtes-vous sûr de vouloir supprimer définitivement cette réparation ? 
            Cette action est irréversible.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Annuler</Button>
          <Button onClick={confirmDeleteRepair} color="error" variant="contained">
            Supprimer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Archive;
