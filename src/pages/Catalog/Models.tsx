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
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
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
  Category as CategoryIcon,
  Grading as BrandingIcon,
  ModelTraining as ModelIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { Device, DeviceType, DeviceModel } from '../../types';

// Interfaces pour les nouvelles entités
interface Category {
  id: string;
  name: string;
  description: string;
  icon: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

interface Brand {
  id: string;
  name: string;
  categoryId: string;
  description: string;
  logo?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

interface Model {
  id: string;
  name: string;
  brandId: string;
  categoryId: string;
  year: number;
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
  
  // État principal pour les onglets
  const [mainTab, setMainTab] = useState(0);
  
  // États pour les catégories
  const [categories, setCategories] = useState<Category[]>([]);
  const [categoryDialogOpen, setCategoryDialogOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  const [newCategory, setNewCategory] = useState({
    name: '',
    description: '',
    icon: 'smartphone',
    isActive: true,
  });

  // États pour les marques
  const [brands, setBrands] = useState<Brand[]>([]);
  const [brandDialogOpen, setBrandDialogOpen] = useState(false);
  const [selectedBrand, setSelectedBrand] = useState<Brand | null>(null);
  const [newBrand, setNewBrand] = useState({
    name: '',
    categoryId: '',
    description: '',
    logo: '',
    isActive: true,
  });

  // États pour les modèles
  const [models, setModels] = useState<Model[]>([]);
  const [modelDialogOpen, setModelDialogOpen] = useState(false);
  const [selectedModel, setSelectedModel] = useState<Model | null>(null);
  const [newModel, setNewModel] = useState({
    name: '',
    brandId: '',
    categoryId: '',
    year: new Date().getFullYear(),
    commonIssues: [''],
    repairDifficulty: 'medium' as 'easy' | 'medium' | 'hard',
    partsAvailability: 'medium' as 'high' | 'medium' | 'low',
    isActive: true,
  });

  // États généraux
  const [searchQuery, setSearchQuery] = useState('');
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<any>(null);
  const [deleteType, setDeleteType] = useState<'category' | 'brand' | 'model'>('category');

  // Données de test pour les catégories
  const defaultCategories: Category[] = [
    {
      id: '1',
      name: 'Smartphones',
      description: 'Téléphones mobiles et smartphones',
      icon: 'smartphone',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '2',
      name: 'Tablettes',
      description: 'Tablettes tactiles',
      icon: 'tablet',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '3',
      name: 'Ordinateurs portables',
      description: 'Laptops et notebooks',
      icon: 'laptop',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '4',
      name: 'Ordinateurs fixes',
      description: 'PC de bureau et stations de travail',
      icon: 'desktop',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  // Données de test pour les marques
  const defaultBrands: Brand[] = [
    {
      id: '1',
      name: 'Apple',
      categoryId: '1',
      description: 'Fabricant américain de produits électroniques',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '2',
      name: 'Samsung',
      categoryId: '1',
      description: 'Fabricant coréen d\'électronique',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '3',
      name: 'Dell',
      categoryId: '3',
      description: 'Fabricant américain d\'ordinateurs',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  // Charger les données au montage
  useEffect(() => {
    setCategories(defaultCategories);
    setBrands(defaultBrands);
    setModels([]);
  }, []);

  // Fonctions utilitaires
  const getDeviceTypeIcon = (icon: string) => {
    const icons = {
      smartphone: <PhoneIcon />,
      tablet: <TabletIcon />,
      laptop: <LaptopIcon />,
      desktop: <ComputerIcon />,
      other: <DeviceHubIcon />,
    };
    return icons[icon as keyof typeof icons] || <DeviceHubIcon />;
  };

  const getDeviceTypeColor = (icon: string) => {
    const colors = {
      smartphone: '#2196f3',
      tablet: '#9c27b0',
      laptop: '#ff9800',
      desktop: '#4caf50',
      other: '#757575',
    };
    return colors[icon as keyof typeof colors] || '#757575';
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

  // Fonctions pour les catégories
  const handleCreateCategory = () => {
    const newCat: Category = {
      id: Date.now().toString(),
      ...newCategory,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    setCategories([...categories, newCat]);
    setCategoryDialogOpen(false);
    resetCategoryForm();
  };

  const handleUpdateCategory = () => {
    if (selectedCategory) {
      const updatedCategories = categories.map(cat =>
        cat.id === selectedCategory.id
          ? { ...cat, ...newCategory, updatedAt: new Date() }
          : cat
      );
      setCategories(updatedCategories);
      setCategoryDialogOpen(false);
      setSelectedCategory(null);
      resetCategoryForm();
    }
  };

  const resetCategoryForm = () => {
    setNewCategory({
      name: '',
      description: '',
      icon: 'smartphone',
      isActive: true,
    });
  };

  const openCategoryEditDialog = (category: Category) => {
    setSelectedCategory(category);
    setNewCategory({
      name: category.name,
      description: category.description,
      icon: category.icon,
      isActive: category.isActive,
    });
    setCategoryDialogOpen(true);
  };

  // Fonctions pour les marques
  const handleCreateBrand = () => {
    const newBrandItem: Brand = {
      id: Date.now().toString(),
      ...newBrand,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    setBrands([...brands, newBrandItem]);
    setBrandDialogOpen(false);
    resetBrandForm();
  };

  const handleUpdateBrand = () => {
    if (selectedBrand) {
      const updatedBrands = brands.map(brand =>
        brand.id === selectedBrand.id
          ? { ...brand, ...newBrand, updatedAt: new Date() }
          : brand
      );
      setBrands(updatedBrands);
      setBrandDialogOpen(false);
      setSelectedBrand(null);
      resetBrandForm();
    }
  };

  const resetBrandForm = () => {
    setNewBrand({
      name: '',
      categoryId: '',
      description: '',
      logo: '',
      isActive: true,
    });
  };

  const openBrandEditDialog = (brand: Brand) => {
    setSelectedBrand(brand);
    setNewBrand({
      name: brand.name,
      categoryId: brand.categoryId,
      description: brand.description,
      logo: brand.logo || '',
      isActive: brand.isActive,
    });
    setBrandDialogOpen(true);
  };

  // Fonctions pour les modèles
  const handleCreateModel = () => {
    const newModelItem: Model = {
      id: Date.now().toString(),
      ...newModel,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    setModels([...models, newModelItem]);
    setModelDialogOpen(false);
    resetModelForm();
  };

  const handleUpdateModel = () => {
    if (selectedModel) {
      const updatedModels = models.map(model =>
        model.id === selectedModel.id
          ? { ...model, ...newModel, updatedAt: new Date() }
          : model
      );
      setModels(updatedModels);
      setModelDialogOpen(false);
      setSelectedModel(null);
      resetModelForm();
    }
  };

  const resetModelForm = () => {
    setNewModel({
      name: '',
      brandId: '',
      categoryId: '',
      year: new Date().getFullYear(),
      commonIssues: [''],
      repairDifficulty: 'medium',
      partsAvailability: 'medium',
      isActive: true,
    });
  };

  const openModelEditDialog = (model: Model) => {
    setSelectedModel(model);
    setNewModel({
      name: model.name,
      brandId: model.brandId,
      categoryId: model.categoryId,
      year: model.year,
      commonIssues: [...model.commonIssues],
      repairDifficulty: model.repairDifficulty,
      partsAvailability: model.partsAvailability,
      isActive: model.isActive,
    });
    setModelDialogOpen(true);
  };

  // Fonction de suppression générique
  const handleDelete = () => {
    if (itemToDelete) {
      switch (deleteType) {
        case 'category':
          setCategories(categories.filter(cat => cat.id !== itemToDelete.id));
          break;
        case 'brand':
          setBrands(brands.filter(brand => brand.id !== itemToDelete.id));
          break;
        case 'model':
          setModels(models.filter(model => model.id !== itemToDelete.id));
          break;
      }
      setDeleteDialogOpen(false);
      setItemToDelete(null);
    }
  };

  const openDeleteDialog = (item: any, type: 'category' | 'brand' | 'model') => {
    setItemToDelete(item);
    setDeleteType(type);
    setDeleteDialogOpen(true);
  };

  // Filtrage des données
  const filteredCategories = categories.filter(cat =>
    cat.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredBrands = brands.filter(brand =>
    brand.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredModels = models.filter(model =>
    model.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Gestion des Appareils
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Organisez vos catégories, marques et modèles d'appareils
        </Typography>
      </Box>

      {/* Onglets principaux */}
      <Card sx={{ mb: 3 }}>
        <Tabs 
          value={mainTab} 
          onChange={(e, newValue) => setMainTab(newValue)}
          sx={{ borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab 
            icon={<CategoryIcon />} 
            label="Catégories" 
            iconPosition="start"
          />
          <Tab 
            icon={<BrandingIcon />} 
            label="Marques" 
            iconPosition="start"
          />
          <Tab 
            icon={<ModelIcon />} 
            label="Modèles" 
            iconPosition="start"
          />
        </Tabs>
      </Card>

      {/* Barre de recherche */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2, alignItems: 'center' }}>
        <TextField
          placeholder="Rechercher..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          InputProps={{
            startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
          }}
          sx={{ flexGrow: 1 }}
        />
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => {
            switch (mainTab) {
              case 0:
                setCategoryDialogOpen(true);
                break;
              case 1:
                setBrandDialogOpen(true);
                break;
              case 2:
                setModelDialogOpen(true);
                break;
            }
          }}
        >
          Ajouter
        </Button>
      </Box>

      {/* Contenu des onglets */}
      {mainTab === 0 && (
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Catégories d'Appareils ({filteredCategories.length})
            </Typography>
            <Grid container spacing={2}>
              {filteredCategories.map((category) => (
                <Grid item xs={12} sm={6} md={4} key={category.id}>
                  <Card variant="outlined">
                    <CardContent>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                        <Avatar
                          sx={{
                            bgcolor: getDeviceTypeColor(category.icon),
                            mr: 2,
                          }}
                        >
                          {getDeviceTypeIcon(category.icon)}
                        </Avatar>
                        <Box sx={{ flexGrow: 1 }}>
                          <Typography variant="h6">{category.name}</Typography>
                          <Typography variant="body2" color="text.secondary">
                            {category.description}
                          </Typography>
                        </Box>
                      </Box>
                      <Box sx={{ display: 'flex', gap: 1 }}>
                        <Button
                          size="small"
                          startIcon={<EditIcon />}
                          onClick={() => openCategoryEditDialog(category)}
                        >
                          Modifier
                        </Button>
                        <Button
                          size="small"
                          color="error"
                          startIcon={<DeleteIcon />}
                          onClick={() => openDeleteDialog(category, 'category')}
                        >
                          Supprimer
                        </Button>
                      </Box>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </CardContent>
        </Card>
      )}

      {mainTab === 1 && (
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Marques ({filteredBrands.length})
            </Typography>
            <TableContainer component={Paper} variant="outlined">
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Marque</TableCell>
                    <TableCell>Catégorie</TableCell>
                    <TableCell>Description</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredBrands.map((brand) => (
                    <TableRow key={brand.id} hover>
                      <TableCell>
                        <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                          {brand.name}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        {categories.find(cat => cat.id === brand.categoryId)?.name || 'N/A'}
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {brand.description}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                          <IconButton
                            size="small"
                            onClick={() => openBrandEditDialog(brand)}
                          >
                            <EditIcon />
                          </IconButton>
                          <IconButton
                            size="small"
                            color="error"
                            onClick={() => openDeleteDialog(brand, 'brand')}
                          >
                            <DeleteIcon />
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
      )}

      {mainTab === 2 && (
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Modèles ({filteredModels.length})
            </Typography>
            <TableContainer component={Paper} variant="outlined">
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Modèle</TableCell>
                    <TableCell>Marque</TableCell>
                    <TableCell>Catégorie</TableCell>
                    <TableCell>Année</TableCell>
                    <TableCell>Difficulté</TableCell>
                    <TableCell>Pièces</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredModels.map((model) => (
                    <TableRow key={model.id} hover>
                      <TableCell>
                        <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                          {model.name}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        {brands.find(brand => brand.id === model.brandId)?.name || 'N/A'}
                      </TableCell>
                      <TableCell>
                        {categories.find(cat => cat.id === model.categoryId)?.name || 'N/A'}
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
                        <Box sx={{ display: 'flex', gap: 1 }}>
                          <IconButton
                            size="small"
                            onClick={() => openModelEditDialog(model)}
                          >
                            <EditIcon />
                          </IconButton>
                          <IconButton
                            size="small"
                            color="error"
                            onClick={() => openDeleteDialog(model, 'model')}
                          >
                            <DeleteIcon />
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
      )}

      {/* Dialog pour les catégories */}
      <Dialog open={categoryDialogOpen} onClose={() => setCategoryDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {selectedCategory ? 'Modifier la catégorie' : 'Créer une nouvelle catégorie'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Nom de la catégorie *"
                value={newCategory.name}
                onChange={(e) => setNewCategory(prev => ({ ...prev, name: e.target.value }))}
                required
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={3}
                value={newCategory.description}
                onChange={(e) => setNewCategory(prev => ({ ...prev, description: e.target.value }))}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Icône</InputLabel>
                <Select
                  value={newCategory.icon}
                  label="Icône"
                  onChange={(e) => setNewCategory(prev => ({ ...prev, icon: e.target.value }))}
                >
                  <MenuItem value="smartphone">Smartphone</MenuItem>
                  <MenuItem value="tablet">Tablette</MenuItem>
                  <MenuItem value="laptop">Ordinateur portable</MenuItem>
                  <MenuItem value="desktop">Ordinateur fixe</MenuItem>
                  <MenuItem value="other">Autre</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCategoryDialogOpen(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={selectedCategory ? handleUpdateCategory : handleCreateCategory}
            disabled={!newCategory.name}
          >
            {selectedCategory ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog pour les marques */}
      <Dialog open={brandDialogOpen} onClose={() => setBrandDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {selectedBrand ? 'Modifier la marque' : 'Créer une nouvelle marque'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Nom de la marque *"
                value={newBrand.name}
                onChange={(e) => setNewBrand(prev => ({ ...prev, name: e.target.value }))}
                required
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Catégorie *</InputLabel>
                <Select
                  value={newBrand.categoryId}
                  label="Catégorie *"
                  onChange={(e) => setNewBrand(prev => ({ ...prev, categoryId: e.target.value }))}
                  required
                >
                  {categories.map((category) => (
                    <MenuItem key={category.id} value={category.id}>
                      {category.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={3}
                value={newBrand.description}
                onChange={(e) => setNewBrand(prev => ({ ...prev, description: e.target.value }))}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setBrandDialogOpen(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={selectedBrand ? handleUpdateBrand : handleCreateBrand}
            disabled={!newBrand.name || !newBrand.categoryId}
          >
            {selectedBrand ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog pour les modèles */}
      <Dialog open={modelDialogOpen} onClose={() => setModelDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          {selectedModel ? 'Modifier le modèle' : 'Créer un nouveau modèle'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Nom du modèle *"
                value={newModel.name}
                onChange={(e) => setNewModel(prev => ({ ...prev, name: e.target.value }))}
                required
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth>
                <InputLabel>Marque *</InputLabel>
                <Select
                  value={newModel.brandId}
                  label="Marque *"
                  onChange={(e) => setNewModel(prev => ({ ...prev, brandId: e.target.value }))}
                  required
                >
                  {brands.map((brand) => (
                    <MenuItem key={brand.id} value={brand.id}>
                      {brand.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth>
                <InputLabel>Catégorie *</InputLabel>
                <Select
                  value={newModel.categoryId}
                  label="Catégorie *"
                  onChange={(e) => setNewModel(prev => ({ ...prev, categoryId: e.target.value }))}
                  required
                >
                  {categories.map((category) => (
                    <MenuItem key={category.id} value={category.id}>
                      {category.name}
                    </MenuItem>
                  ))}
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
            <Grid item xs={12}>
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
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setModelDialogOpen(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={selectedModel ? handleUpdateModel : handleCreateModel}
            disabled={!newModel.name || !newModel.brandId || !newModel.categoryId}
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
          {itemToDelete && (
            <Alert severity="warning">
              Êtes-vous sûr de vouloir supprimer cet élément ?
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
            onClick={handleDelete}
          >
            Supprimer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Models;
