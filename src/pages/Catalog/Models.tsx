import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  IconButton,
  Chip,
  Avatar,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Alert,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Tooltip,
  Badge,
  Tabs,
  Tab,
  Divider,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  Sort as SortIcon,
  Phone as PhoneIcon,
  Tablet as TabletIcon,
  Laptop as LaptopIcon,
  Computer as ComputerIcon,
  DeviceHub as DeviceHubIcon,
  ExpandMore as ExpandMoreIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { Device, DeviceType, DeviceModel } from '../../types';

interface Model {
  id: string;
  brand: string;
  model: string;
  type: DeviceType;
  year: number;
  specifications: {
    screen?: string;
    processor?: string;
    ram?: string;
    storage?: string;
    battery?: string;
    os?: string;
  };
  commonIssues: string[];
  repairDifficulty: 'easy' | 'medium' | 'hard';
  partsAvailability: 'high' | 'medium' | 'low';
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const Models: React.FC = () => {
  const { 
    deviceModels, 
    addDeviceModel, 
    updateDeviceModel, 
    deleteDeviceModel,
    loadDeviceModels 
  } = useAppStore();
  
  const [models, setModels] = useState<Model[]>([]);
  const [selectedModel, setSelectedModel] = useState<Model | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [modelToDelete, setModelToDelete] = useState<Model | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<string>('all');
  const [sortBy, setSortBy] = useState<string>('brand');
  const [activeTab, setActiveTab] = useState(0);

  // État pour le nouveau modèle
  const [newModel, setNewModel] = useState({
    brand: '',
    model: '',
    type: 'smartphone' as DeviceType,
    year: new Date().getFullYear(),
    specifications: {
      screen: '',
      processor: '',
      ram: '',
      storage: '',
      battery: '',
      os: '',
    },
    commonIssues: [''],
    repairDifficulty: 'medium' as 'easy' | 'medium' | 'hard',
    partsAvailability: 'medium' as 'high' | 'medium' | 'low',
    isActive: true,
  });

  // Charger les modèles depuis la base de données
  useEffect(() => {
    loadDeviceModels();
  }, [loadDeviceModels]);

  // Utiliser les modèles du store
  useEffect(() => {
    setModels(deviceModels);
  }, [deviceModels]);

  const getDeviceTypeIcon = (type: DeviceType) => {
    const icons = {
      smartphone: <PhoneIcon />,
      tablet: <TabletIcon />,
      laptop: <LaptopIcon />,
      desktop: <ComputerIcon />,
      other: <DeviceHubIcon />,
    };
    return icons[type] || <DeviceHubIcon />;
  };

  const getDeviceTypeColor = (type: DeviceType) => {
    const colors = {
      smartphone: '#2196f3',
      tablet: '#9c27b0',
      laptop: '#ff9800',
      desktop: '#4caf50',
      other: '#757575',
    };
    return colors[type] || '#757575';
  };

  const getDifficultyColor = (difficulty: string): 'success' | 'warning' | 'error' | 'default' => {
    const colors: Record<string, 'success' | 'warning' | 'error'> = {
      easy: 'success',
      medium: 'warning',
      hard: 'error',
    };
    return colors[difficulty] || 'default';
  };

  const getAvailabilityColor = (availability: string): 'success' | 'warning' | 'error' | 'default' => {
    const colors: Record<string, 'success' | 'warning' | 'error'> = {
      high: 'success',
      medium: 'warning',
      low: 'error',
    };
    return colors[availability] || 'default';
  };

  const filteredModels = models.filter(model => {
    const matchesSearch = model.brand.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         model.model.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = filterType === 'all' || model.type === filterType;
    return matchesSearch && matchesFilter;
  });

  const sortedModels = [...filteredModels].sort((a, b) => {
    switch (sortBy) {
      case 'brand':
        return a.brand.localeCompare(b.brand);
      case 'model':
        return a.model.localeCompare(b.model);
      case 'year':
        return b.year - a.year;
      case 'difficulty':
        const difficultyOrder = { easy: 1, medium: 2, hard: 3 };
        return difficultyOrder[a.repairDifficulty] - difficultyOrder[b.repairDifficulty];
      default:
        return 0;
    }
  });

  const handleCreateModel = async () => {
    try {
      await addDeviceModel(newModel);
      setDialogOpen(false);
      resetNewModelForm();
    } catch (error) {
      console.error('Erreur lors de la création du modèle:', error);
    }
  };

  const handleUpdateModel = async () => {
    if (selectedModel) {
      try {
        await updateDeviceModel(selectedModel.id, newModel);
        setDialogOpen(false);
        setSelectedModel(null);
        resetNewModelForm();
      } catch (error) {
        console.error('Erreur lors de la mise à jour du modèle:', error);
      }
    }
  };

  const handleDeleteModel = async () => {
    if (modelToDelete) {
      try {
        await deleteDeviceModel(modelToDelete.id);
        setDeleteDialogOpen(false);
        setModelToDelete(null);
      } catch (error) {
        console.error('Erreur lors de la suppression du modèle:', error);
      }
    }
  };

  const resetNewModelForm = () => {
    setNewModel({
      brand: '',
      model: '',
      type: 'smartphone',
      year: new Date().getFullYear(),
      specifications: {
        screen: '',
        processor: '',
        ram: '',
        storage: '',
        battery: '',
        os: '',
      },
      commonIssues: [''],
      repairDifficulty: 'medium',
      partsAvailability: 'medium',
      isActive: true,
    });
  };

  const openEditDialog = (model: Model) => {
    setSelectedModel(model);
    setNewModel({
      brand: model.brand,
      model: model.model,
      type: model.type,
      year: model.year,
      specifications: { 
        screen: model.specifications.screen || '',
        processor: model.specifications.processor || '',
        ram: model.specifications.ram || '',
        storage: model.specifications.storage || '',
        battery: model.specifications.battery || '',
        os: model.specifications.os || '',
      },
      commonIssues: [...model.commonIssues],
      repairDifficulty: model.repairDifficulty,
      partsAvailability: model.partsAvailability,
      isActive: model.isActive,
    });
    setDialogOpen(true);
  };

  const openDeleteDialog = (model: Model) => {
    setModelToDelete(model);
    setDeleteDialogOpen(true);
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Modèles d'Appareils
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gestion des modèles et spécifications techniques
        </Typography>
      </Box>

      {/* Filtres et recherche */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                placeholder="Rechercher un modèle..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                }}
              />
            </Grid>
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Type d'appareil</InputLabel>
                <Select
                  value={filterType}
                  onChange={(e) => setFilterType(e.target.value)}
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
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Trier par</InputLabel>
                <Select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value)}
                  label="Trier par"
                >
                  <MenuItem value="brand">Marque</MenuItem>
                  <MenuItem value="model">Modèle</MenuItem>
                  <MenuItem value="year">Année</MenuItem>
                  <MenuItem value="difficulty">Difficulté</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={2}>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                fullWidth
                onClick={() => {
                  setSelectedModel(null);
                  resetNewModelForm();
                  setDialogOpen(true);
                }}
              >
                Nouveau modèle
              </Button>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Statistiques */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Avatar sx={{ bgcolor: 'primary.main', mr: 2 }}>
                  <DeviceHubIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6">{models.length}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total modèles
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Avatar sx={{ bgcolor: 'success.main', mr: 2 }}>
                  <CheckCircleIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6">
                    {models.filter(m => m.partsAvailability === 'high').length}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Pièces disponibles
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Avatar sx={{ bgcolor: 'warning.main', mr: 2 }}>
                  <WarningIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6">
                    {models.filter(m => m.repairDifficulty === 'hard').length}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Réparations difficiles
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Avatar sx={{ bgcolor: 'error.main', mr: 2 }}>
                  <ErrorIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6">
                    {models.filter(m => m.partsAvailability === 'low').length}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Pièces rares
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Tableau des modèles */}
      <Card>
        <CardContent>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Modèle</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell>Année</TableCell>
                  <TableCell>Difficulté</TableCell>
                  <TableCell>Pièces</TableCell>
                  <TableCell>Problèmes courants</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {sortedModels.map((model) => (
                  <TableRow key={model.id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Avatar
                          sx={{
                            bgcolor: getDeviceTypeColor(model.type),
                            width: 32,
                            height: 32,
                            mr: 2,
                          }}
                        >
                          {getDeviceTypeIcon(model.type)}
                        </Avatar>
                        <Box>
                          <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                            {model.brand} {model.model}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {model.specifications.processor}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={model.type}
                        size="small"
                        sx={{ bgcolor: getDeviceTypeColor(model.type), color: 'white' }}
                      />
                    </TableCell>
                    <TableCell>{model.year}</TableCell>
                    <TableCell>
                      <Chip
                        label={model.repairDifficulty}
                        size="small"
                        color={getDifficultyColor(model.repairDifficulty)}
                      />
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={model.partsAvailability}
                        size="small"
                        color={getAvailabilityColor(model.partsAvailability)}
                      />
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                        {model.commonIssues.slice(0, 2).map((issue, index) => (
                          <Chip
                            key={index}
                            label={issue}
                            size="small"
                            variant="outlined"
                          />
                        ))}
                        {model.commonIssues.length > 2 && (
                          <Chip
                            label={`+${model.commonIssues.length - 2}`}
                            size="small"
                            variant="outlined"
                          />
                        )}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 0.5 }}>
                        <Tooltip title="Modifier">
                          <IconButton size="small" onClick={() => openEditDialog(model)}>
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Supprimer">
                          <IconButton 
                            size="small" 
                            color="error"
                            onClick={() => openDeleteDialog(model)}
                          >
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Dialog pour créer/modifier un modèle */}
      <Dialog 
        open={dialogOpen} 
        onClose={() => setDialogOpen(false)} 
        maxWidth="md" 
        fullWidth
      >
        <DialogTitle>
          {selectedModel ? 'Modifier le modèle' : 'Nouveau modèle'}
        </DialogTitle>
        <DialogContent>
          <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)} sx={{ mb: 2 }}>
            <Tab label="Informations générales" />
            <Tab label="Spécifications" />
            <Tab label="Problèmes courants" />
          </Tabs>

          {activeTab === 0 && (
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Marque *"
                  value={newModel.brand}
                  onChange={(e) => setNewModel(prev => ({ ...prev, brand: e.target.value }))}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Modèle *"
                  value={newModel.model}
                  onChange={(e) => setNewModel(prev => ({ ...prev, model: e.target.value }))}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Type d'appareil *</InputLabel>
                  <Select
                    value={newModel.type}
                    onChange={(e) => setNewModel(prev => ({ ...prev, type: e.target.value as DeviceType }))}
                    label="Type d'appareil *"
                  >
                    <MenuItem value="smartphone">Smartphone</MenuItem>
                    <MenuItem value="tablet">Tablette</MenuItem>
                    <MenuItem value="laptop">Ordinateur portable</MenuItem>
                    <MenuItem value="desktop">Ordinateur fixe</MenuItem>
                    <MenuItem value="other">Autre</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Année"
                  type="number"
                  value={newModel.year}
                  onChange={(e) => setNewModel(prev => ({ ...prev, year: parseInt(e.target.value) }))}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Difficulté de réparation</InputLabel>
                  <Select
                    value={newModel.repairDifficulty}
                    onChange={(e) => setNewModel(prev => ({ ...prev, repairDifficulty: e.target.value as any }))}
                    label="Difficulté de réparation"
                  >
                    <MenuItem value="easy">Facile</MenuItem>
                    <MenuItem value="medium">Moyenne</MenuItem>
                    <MenuItem value="hard">Difficile</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Disponibilité des pièces</InputLabel>
                  <Select
                    value={newModel.partsAvailability}
                    onChange={(e) => setNewModel(prev => ({ ...prev, partsAvailability: e.target.value as any }))}
                    label="Disponibilité des pièces"
                  >
                    <MenuItem value="high">Élevée</MenuItem>
                    <MenuItem value="medium">Moyenne</MenuItem>
                    <MenuItem value="low">Faible</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          )}

          {activeTab === 1 && (
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Écran"
                  value={newModel.specifications.screen}
                  onChange={(e) => setNewModel(prev => ({ 
                    ...prev, 
                    specifications: { ...prev.specifications, screen: e.target.value }
                  }))}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Processeur"
                  value={newModel.specifications.processor}
                  onChange={(e) => setNewModel(prev => ({ 
                    ...prev, 
                    specifications: { ...prev.specifications, processor: e.target.value }
                  }))}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="RAM"
                  value={newModel.specifications.ram}
                  onChange={(e) => setNewModel(prev => ({ 
                    ...prev, 
                    specifications: { ...prev.specifications, ram: e.target.value }
                  }))}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Stockage"
                  value={newModel.specifications.storage}
                  onChange={(e) => setNewModel(prev => ({ 
                    ...prev, 
                    specifications: { ...prev.specifications, storage: e.target.value }
                  }))}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Batterie"
                  value={newModel.specifications.battery}
                  onChange={(e) => setNewModel(prev => ({ 
                    ...prev, 
                    specifications: { ...prev.specifications, battery: e.target.value }
                  }))}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Système d'exploitation"
                  value={newModel.specifications.os}
                  onChange={(e) => setNewModel(prev => ({ 
                    ...prev, 
                    specifications: { ...prev.specifications, os: e.target.value }
                  }))}
                />
              </Grid>
            </Grid>
          )}

          {activeTab === 2 && (
            <Box>
              <Typography variant="subtitle2" gutterBottom>
                Problèmes courants rencontrés
              </Typography>
              {newModel.commonIssues.map((issue, index) => (
                <Box key={index} sx={{ display: 'flex', gap: 1, mb: 1 }}>
                  <TextField
                    fullWidth
                    label={`Problème ${index + 1}`}
                    value={issue}
                    onChange={(e) => {
                      const updatedIssues = [...newModel.commonIssues];
                      updatedIssues[index] = e.target.value;
                      setNewModel(prev => ({ ...prev, commonIssues: updatedIssues }));
                    }}
                  />
                  <IconButton
                    color="error"
                    onClick={() => {
                      const updatedIssues = newModel.commonIssues.filter((_, i) => i !== index);
                      setNewModel(prev => ({ ...prev, commonIssues: updatedIssues }));
                    }}
                  >
                    <DeleteIcon />
                  </IconButton>
                </Box>
              ))}
              <Button
                startIcon={<AddIcon />}
                onClick={() => setNewModel(prev => ({ 
                  ...prev, 
                  commonIssues: [...prev.commonIssues, '']
                }))}
                sx={{ mt: 1 }}
              >
                Ajouter un problème
              </Button>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={selectedModel ? handleUpdateModel : handleCreateModel}
            disabled={!newModel.brand || !newModel.model}
          >
            {selectedModel ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog de confirmation de suppression */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          Confirmer la suppression
        </DialogTitle>
        <DialogContent>
          {modelToDelete && (
            <Alert severity="warning">
              Êtes-vous sûr de vouloir supprimer le modèle "{modelToDelete.brand} {modelToDelete.model}" ?
              Cette action est irréversible.
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            color="error"
            onClick={handleDeleteModel}
          >
            Supprimer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Models;
