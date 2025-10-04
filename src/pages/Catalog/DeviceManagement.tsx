// @ts-nocheck
import React, { useState, useEffect } from 'react';
import { useAppStore } from '../../store';
import { DeviceCategory, DeviceBrand, DeviceModel } from '../../types/deviceManagement';
import { deviceCategoryService } from '../../services/deviceCategoryService';
import { brandService, BrandWithCategories, CreateBrandData, UpdateBrandData } from '../../services/brandService';
import { deviceModelService } from '../../services/deviceModelService';
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
  Switch,
  FormControlLabel,
  CircularProgress,
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
  Inventory as InventoryIcon,
  Settings as SettingsIcon,
} from '@mui/icons-material';
import CategoryIconDisplay from '../../components/CategoryIconDisplay';
import CategoryIconGrid from '../../components/CategoryIconGrid';

interface NewBrandForm {
  name: string;
  description: string;
  categoryIds: string[];
  isActive: boolean;
}

interface NewCategoryForm {
  name: string;
  description: string;
  icon: string;
  isActive: boolean;
}

interface NewModelForm {
  name: string;
  description: string;
  brandId: string;
  categoryId: string;
  isActive: boolean;
}

const DeviceManagement: React.FC = () => {
  // États pour les données
  const [allCategories, setAllCategories] = useState<DeviceCategory[]>([]);
  const [allBrands, setAllBrands] = useState<BrandWithCategories[]>([]);
  const [allModels, setAllModels] = useState<DeviceModel[]>([]);
  
  // États pour les filtres et recherche
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategoryForBrands, setSelectedCategoryForBrands] = useState<string>('');
  const [selectedCategoryForModels, setSelectedCategoryForModels] = useState<string>('');
  const [selectedBrandForModels, setSelectedBrandForModels] = useState<string>('');
  
  // États pour les dialogues
  const [activeTab, setActiveTab] = useState(0);
  const [brandDialogOpen, setBrandDialogOpen] = useState(false);
  const [categoryDialogOpen, setCategoryDialogOpen] = useState(false);
  const [modelDialogOpen, setModelDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleteItem, setDeleteItem] = useState<{ type: 'brand' | 'category' | 'model'; item: any } | null>(null);
  
  // États pour les formulaires
  const [selectedBrand, setSelectedBrand] = useState<BrandWithCategories | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<DeviceCategory | null>(null);
  const [selectedModel, setSelectedModel] = useState<DeviceModel | null>(null);
  const [newBrand, setNewBrand] = useState<NewBrandForm>({
    name: '',
    description: '',
    categoryIds: [],
    isActive: true,
  });
  const [newCategory, setNewCategory] = useState<NewCategoryForm>({
    name: '',
    description: '',
    icon: 'category',
    isActive: true,
  });
  const [newModel, setNewModel] = useState<NewModelForm>({
    name: '',
    description: '',
    brandId: '',
    categoryId: '',
    isActive: true,
  });
  
  // États pour le chargement
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Charger les données au montage du composant
  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    setError(null);
    
    try {
      // Charger les catégories
      const categoriesResult = await deviceCategoryService.getAll();
      if (categoriesResult.success && categoriesResult.data) {
        setAllCategories(categoriesResult.data);
      } else {
        console.warn('⚠️ Aucune catégorie trouvée ou erreur:', categoriesResult.error);
        setAllCategories([]);
      }
      
      // Charger les marques
      const brands = await brandService.getAll();
      setAllBrands(brands);
      
      // Charger les modèles
      const modelsResult = await deviceModelService.getAll();
      if (modelsResult.success && modelsResult.data) {
        setAllModels(modelsResult.data);
      } else {
        console.warn('⚠️ Aucun modèle trouvé ou erreur:', modelsResult.error);
        setAllModels([]);
      }
      
      console.log('✅ Données chargées avec succès');
    } catch (err) {
      console.error('❌ Erreur lors du chargement des données:', err);
      setError('Erreur lors du chargement des données');
      // S'assurer que les états sont des tableaux vides en cas d'erreur
      setAllCategories([]);
      setAllBrands([]);
    } finally {
      setLoading(false);
    }
  };

  // Fonctions pour les catégories
  const handleCreateCategory = async () => {
    try {
      setLoading(true);
      
      const result = await deviceCategoryService.create({
        name: newCategory.name,
        description: newCategory.description,
        icon: newCategory.icon,
      });
      
      if (result.success) {
        // Mettre à jour la liste des catégories
        await loadData();
        
        // Fermer le dialogue et réinitialiser le formulaire
        setCategoryDialogOpen(false);
        resetCategoryForm();
        
        console.log('✅ Catégorie créée avec succès:', result.data);
      } else {
        console.error('❌ Erreur lors de la création de la catégorie:', result.error);
        setError(result.error || 'Erreur lors de la création de la catégorie');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la création de la catégorie:', error);
      setError('Erreur lors de la création de la catégorie');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateCategory = async () => {
    if (!selectedCategory) return;
    
    try {
      setLoading(true);
      
      const result = await deviceCategoryService.update(selectedCategory.id, {
        name: newCategory.name,
        description: newCategory.description,
        icon: newCategory.icon,
      });
      
      if (result.success) {
        // Mettre à jour la liste des catégories
        await loadData();
        
        // Fermer le dialogue et réinitialiser le formulaire
        setCategoryDialogOpen(false);
        resetCategoryForm();
        
        console.log('✅ Catégorie mise à jour avec succès:', result.data);
      } else {
        console.error('❌ Erreur lors de la mise à jour de la catégorie:', result.error);
        setError(result.error || 'Erreur lors de la mise à jour de la catégorie');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la mise à jour de la catégorie:', error);
      setError('Erreur lors de la mise à jour de la catégorie');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteCategory = async (category: DeviceCategory) => {
    try {
      setLoading(true);
      
      const result = await deviceCategoryService.delete(category.id);
      
      if (result.success) {
        // Mettre à jour la liste des catégories
        await loadData();
        
        console.log('✅ Catégorie supprimée avec succès');
      } else {
        console.error('❌ Erreur lors de la suppression de la catégorie:', result.error);
        setError(result.error || 'Erreur lors de la suppression de la catégorie');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la suppression de la catégorie:', error);
      setError('Erreur lors de la suppression de la catégorie');
    } finally {
      setLoading(false);
    }
  };

  const openCategoryEditDialog = (category: DeviceCategory) => {
    setSelectedCategory(category);
    setNewCategory({
      name: category.name,
      description: category.description,
      icon: category.icon,
      isActive: category.isActive,
    });
    setCategoryDialogOpen(true);
  };

  const resetCategoryForm = () => {
    setSelectedCategory(null);
    setNewCategory({
      name: '',
      description: '',
      icon: 'category',
      isActive: true,
    });
  };

  // Fonctions pour les modèles
  const handleCreateModel = async () => {
    try {
      setLoading(true);
      
      const result = await deviceModelService.create({
        name: newModel.name,
        description: newModel.description,
        brandId: newModel.brandId,
        categoryId: newModel.categoryId,
      });
      
      if (result.success) {
        // Mettre à jour la liste des modèles
        await loadData();
        
        // Fermer le dialogue et réinitialiser le formulaire
        setModelDialogOpen(false);
        resetModelForm();
        
        console.log('✅ Modèle créé avec succès:', result.data);
      } else {
        console.error('❌ Erreur lors de la création du modèle:', result.error);
        setError(result.error || 'Erreur lors de la création du modèle');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la création du modèle:', error);
      setError('Erreur lors de la création du modèle');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateModel = async () => {
    if (!selectedModel) return;
    
    try {
      setLoading(true);
      
      const result = await deviceModelService.update(selectedModel.id, {
        name: newModel.name,
        description: newModel.description,
        brandId: newModel.brandId,
        categoryId: newModel.categoryId,
      });
      
      if (result.success) {
        // Mettre à jour la liste des modèles
        await loadData();
        
        // Fermer le dialogue et réinitialiser le formulaire
        setModelDialogOpen(false);
        resetModelForm();
        
        console.log('✅ Modèle mis à jour avec succès:', result.data);
      } else {
        console.error('❌ Erreur lors de la mise à jour du modèle:', result.error);
        setError(result.error || 'Erreur lors de la mise à jour du modèle');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la mise à jour du modèle:', error);
      setError('Erreur lors de la mise à jour du modèle');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteModel = async (model: DeviceModel) => {
    try {
      setLoading(true);
      
      const result = await deviceModelService.delete(model.id);
      
      if (result.success) {
        // Mettre à jour la liste des modèles
        await loadData();
        
        console.log('✅ Modèle supprimé avec succès');
      } else {
        console.error('❌ Erreur lors de la suppression du modèle:', result.error);
        setError(result.error || 'Erreur lors de la suppression du modèle');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la suppression du modèle:', error);
      setError('Erreur lors de la suppression du modèle');
    } finally {
      setLoading(false);
    }
  };

  const openModelEditDialog = (model: DeviceModel) => {
    setSelectedModel(model);
    setNewModel({
      name: model.name,
      description: model.description || '',
      brandId: model.brandId,
      categoryId: model.categoryId,
      isActive: model.isActive,
    });
    setModelDialogOpen(true);
  };

  const resetModelForm = () => {
    setSelectedModel(null);
    setNewModel({
      name: '',
      description: '',
      brandId: '',
      categoryId: '',
      isActive: true,
    });
  };

  // Fonctions pour les marques
  const handleCreateBrand = async () => {
    try {
      setLoading(true);
      
      const brandData: CreateBrandData = {
        name: newBrand.name,
        description: newBrand.description,
        categoryIds: newBrand.categoryIds,
      };
      
      const result = await brandService.create(brandData);
      
      // Mettre à jour la liste des marques
      await loadData();
      
      // Fermer le dialogue et réinitialiser le formulaire
      setBrandDialogOpen(false);
      resetBrandForm();
      
      console.log('✅ Marque créée avec succès:', result);
    } catch (error) {
      console.error('❌ Erreur lors de la création de la marque:', error);
      setError('Erreur lors de la création de la marque');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateBrand = async () => {
    if (!selectedBrand) return;
    
    try {
      setLoading(true);
      
      const updateData: UpdateBrandData = {
        name: newBrand.name,
        description: newBrand.description,
        categoryIds: newBrand.categoryIds,
      };
      
      const result = await brandService.update(selectedBrand.id, updateData);
      
      // Mettre à jour la liste des marques
      await loadData();
      
      // Fermer le dialogue et réinitialiser le formulaire
      setBrandDialogOpen(false);
      resetBrandForm();
      setSelectedBrand(null);
      
      console.log('✅ Marque mise à jour avec succès:', result);
    } catch (error) {
      console.error('❌ Erreur lors de la mise à jour de la marque:', error);
      setError('Erreur lors de la mise à jour de la marque');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteBrand = async (brand: BrandWithCategories) => {
    try {
      setLoading(true);
      
      await brandService.delete(brand.id);
      
      // Mettre à jour la liste des marques
      await loadData();
      
      console.log('✅ Marque supprimée avec succès');
    } catch (error) {
      console.error('❌ Erreur lors de la suppression de la marque:', error);
      setError('Erreur lors de la suppression de la marque');
    } finally {
      setLoading(false);
    }
  };

  const resetBrandForm = () => {
    setNewBrand({
      name: '',
      description: '',
      categoryIds: [],
      isActive: true,
    });
    setSelectedBrand(null);
  };

  const openBrandEditDialog = (brand: BrandWithCategories) => {
    setSelectedBrand(brand);
    setNewBrand({
      name: brand.name,
      description: brand.description,
      categoryIds: brand.categories.map(cat => cat.id),
      isActive: brand.isActive,
    });
    setBrandDialogOpen(true);
  };

  const openDeleteDialog = (item: any, type: 'brand' | 'category' | 'model') => {
    setDeleteItem({ type, item });
    setDeleteDialogOpen(true);
  };

  const confirmDelete = async () => {
    if (!deleteItem) return;
    
    if (deleteItem.type === 'brand') {
      await handleDeleteBrand(deleteItem.item);
    } else if (deleteItem.type === 'category') {
      await handleDeleteCategory(deleteItem.item);
    } else if (deleteItem.type === 'model') {
      await handleDeleteModel(deleteItem.item);
    }
    
    setDeleteDialogOpen(false);
    setDeleteItem(null);
  };

  // Filtrer les marques
  const filteredBrands = (allBrands || []).filter(brand => {
    const matchesSearch = brand.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         brand.description.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesCategory = !selectedCategoryForBrands || 
                           brand.categories.some(cat => cat.id === selectedCategoryForBrands);
    
    return matchesSearch && matchesCategory;
  });

  // Compter les marques par catégorie
  const brandCountByCategory = (allCategories || []).map(category => ({
    category,
    count: (allBrands || []).filter(brand => 
      brand.categories.some(cat => cat.id === category.id)
    ).length
  }));

  // Obtenir l'icône pour une catégorie
  const getCategoryIcon = (categoryName: string, iconValue?: string) => {
    const iconType = iconValue || categoryName.toLowerCase().replace(/\s+/g, '-');
    return <CategoryIconDisplay iconType={iconType} size={20} />;
  };

  if (loading && (allBrands || []).length === 0) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* En-tête */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" gutterBottom>
          Gestion des Appareils
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gérez vos marques, catégories et modèles d'appareils
        </Typography>
      </Box>

      {/* Affichage des erreurs */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Onglets */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
          <Tab label="Marques" icon={<BrandingIcon />} />
          <Tab label="Catégories" icon={<CategoryIcon />} />
          <Tab label="Modèles" icon={<ModelIcon />} />
        </Tabs>
      </Paper>

      {/* Onglet Marques */}
      {activeTab === 0 && (
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6">Marques ({filteredBrands.length})</Typography>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => {
                  resetBrandForm();
                  setBrandDialogOpen(true);
                }}
              >
                Ajouter une marque
              </Button>
            </Box>

            {/* Filtres */}
            <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
              <TextField
                placeholder="Rechercher une marque..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                size="small"
                sx={{ minWidth: 200 }}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
                }}
              />
              
              <FormControl size="small" sx={{ minWidth: 200 }}>
                <InputLabel>Filtrer par catégorie</InputLabel>
                <Select
                  value={selectedCategoryForBrands || ''}
                  onChange={(e) => setSelectedCategoryForBrands(e.target.value)}
                  label="Filtrer par catégorie"
                >
                  <MenuItem value="">Toutes les catégories</MenuItem>
                  {(allCategories || []).map((category) => (
                    <MenuItem key={category.id} value={category.id}>
                      {category.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Box>

            {/* Statistiques par catégorie */}
            <Box sx={{ mb: 3 }}>
              <Typography variant="subtitle2" gutterBottom>
                Marques par catégorie:
              </Typography>
              <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                {brandCountByCategory.map(({ category, count }) => (
                  <Chip
                    key={category.id}
                    label={`${category.name}: ${count}`}
                    variant={selectedCategoryForBrands === category.id ? 'filled' : 'outlined'}
                    onClick={() => setSelectedCategoryForBrands(
                      selectedCategoryForBrands === category.id ? '' : category.id
                    )}
                    color={selectedCategoryForBrands === category.id ? 'primary' : 'default'}
                  />
                ))}
              </Box>
            </Box>

            {/* Tableau des marques */}
            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Nom</TableCell>
                    <TableCell>Description</TableCell>
                    <TableCell>Catégories</TableCell>
                    <TableCell>Statut</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredBrands.map((brand) => (
                    <TableRow key={brand.id}>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.main' }}>
                            {brand.name.charAt(0)}
                          </Avatar>
                          <Typography variant="body2" fontWeight="medium">
                            {brand.name}
                          </Typography>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {brand.description || 'Aucune description'}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                          {brand.categories.length > 0 ? (
                            brand.categories.map((category) => (
                              <Chip
                                key={category.id}
                                label={category.name}
                                size="small"
                                icon={getCategoryIcon(category.name, category.icon)}
                              />
                            ))
                          ) : (
                            <Typography variant="body2" color="text.secondary">
                              Aucune catégorie
                            </Typography>
                          )}
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={brand.isActive ? 'Actif' : 'Inactif'}
                          color={brand.isActive ? 'success' : 'default'}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                          <Tooltip title="Modifier">
                            <IconButton
                              size="small"
                              onClick={() => openBrandEditDialog(brand)}
                            >
                              <EditIcon />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Supprimer">
                            <IconButton
                              size="small"
                              color="error"
                              onClick={() => openDeleteDialog(brand, 'brand')}
                            >
                              <DeleteIcon />
                            </IconButton>
                          </Tooltip>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>

            {filteredBrands.length === 0 && (
              <Box sx={{ textAlign: 'center', py: 4 }}>
                <Typography variant="body1" color="text.secondary">
                  Aucune marque trouvée
                </Typography>
              </Box>
            )}
          </CardContent>
        </Card>
      )}

      {/* Onglet Catégories */}
      {activeTab === 1 && (
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6">Catégories ({(allCategories || []).length})</Typography>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => {
                  resetCategoryForm();
                  setCategoryDialogOpen(true);
                }}
              >
                Ajouter une catégorie
              </Button>
            </Box>

            {/* Tableau des catégories */}
            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Nom</TableCell>
                    <TableCell>Description</TableCell>
                    <TableCell>Icône</TableCell>
                    <TableCell>Statut</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(allCategories || []).map((category) => (
                    <TableRow key={category.id}>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        {getCategoryIcon(category.name, category.icon)}
                        <Typography variant="body2" fontWeight="medium">
                          {category.name}
                        </Typography>
                      </Box>
                    </TableCell>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {category.description}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        {getCategoryIcon(category.name, category.icon)}
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={category.isActive ? 'Actif' : 'Inactif'}
                          color={category.isActive ? 'success' : 'default'}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                          <IconButton
                            size="small"
                            onClick={() => openCategoryEditDialog(category)}
                          >
                            <EditIcon />
                          </IconButton>
                          <IconButton
                            size="small"
                            color="error"
                            onClick={() => openDeleteDialog(category, 'category')}
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

            {(allCategories || []).length === 0 && (
              <Box sx={{ textAlign: 'center', py: 4 }}>
                <Typography variant="body1" color="text.secondary">
                  Aucune catégorie trouvée
                </Typography>
              </Box>
            )}
          </CardContent>
        </Card>
      )}

      {/* Onglet Modèles */}
      {activeTab === 2 && (
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6">Modèles ({(allModels || []).length})</Typography>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => {
                  resetModelForm();
                  setModelDialogOpen(true);
                }}
              >
                Ajouter un modèle
              </Button>
            </Box>

            {/* Filtres pour les modèles */}
            <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
              <TextField
                placeholder="Rechercher un modèle..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                size="small"
                sx={{ minWidth: 200 }}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
                }}
              />
              
              <FormControl size="small" sx={{ minWidth: 200 }}>
                <InputLabel>Filtrer par marque</InputLabel>
                <Select
                  value={selectedBrandForModels || ''}
                  onChange={(e) => setSelectedBrandForModels(e.target.value)}
                  label="Filtrer par marque"
                >
                  <MenuItem value="">Toutes les marques</MenuItem>
                  {(allBrands || []).map((brand) => (
                    <MenuItem key={brand.id} value={brand.id}>
                      {brand.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              <FormControl size="small" sx={{ minWidth: 200 }}>
                <InputLabel>Filtrer par catégorie</InputLabel>
                <Select
                  value={selectedCategoryForModels || ''}
                  onChange={(e) => setSelectedCategoryForModels(e.target.value)}
                  label="Filtrer par catégorie"
                >
                  <MenuItem value="">Toutes les catégories</MenuItem>
                  {(allCategories || []).map((category) => (
                    <MenuItem key={category.id} value={category.id}>
                      {category.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Box>

            {/* Tableau des modèles */}
            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Nom</TableCell>
                    <TableCell>Marque</TableCell>
                    <TableCell>Catégorie</TableCell>
                    <TableCell>Description</TableCell>
                    <TableCell>Statut</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {(allModels || []).map((model) => (
                    <TableRow key={model.id}>
                      <TableCell>
                        <Typography variant="body2" fontWeight="medium">
                          {model.name}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {model.brandName}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          {getCategoryIcon(model.categoryName)}
                          <Typography variant="body2" color="text.secondary">
                            {model.categoryName}
                          </Typography>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {model.description}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={model.isActive ? 'Actif' : 'Inactif'}
                          color={model.isActive ? 'success' : 'default'}
                          size="small"
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

            {(allModels || []).length === 0 && (
              <Box sx={{ textAlign: 'center', py: 4 }}>
                <Typography variant="body1" color="text.secondary">
                  Aucun modèle trouvé
                </Typography>
              </Box>
            )}
          </CardContent>
        </Card>
      )}

      {/* Dialogue pour créer/modifier une marque */}
      <Dialog open={brandDialogOpen} onClose={() => setBrandDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          {selectedBrand ? 'Modifier la marque' : 'Créer une nouvelle marque'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <TextField
              label="Nom de la marque"
              value={newBrand.name}
              onChange={(e) => setNewBrand({ ...newBrand, name: e.target.value })}
              fullWidth
              required
            />
            
            <TextField
              label="Description"
              value={newBrand.description}
              onChange={(e) => setNewBrand({ ...newBrand, description: e.target.value })}
              fullWidth
              multiline
              rows={3}
            />
            
            
            <FormControl fullWidth>
              <InputLabel>Catégories</InputLabel>
              <Select
                multiple
                value={newBrand.categoryIds}
                onChange={(e) => setNewBrand({ ...newBrand, categoryIds: e.target.value as string[] })}
                label="Catégories"
                renderValue={(selected) => (
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                    {(selected as string[]).map((value) => {
                      const category = (allCategories || []).find(cat => cat.id === value);
                      return (
                        <Chip
                          key={value}
                          label={category?.name || value}
                          size="small"
                        />
                      );
                    })}
                  </Box>
                )}
              >
                {(allCategories || []).map((category) => (
                  <MenuItem key={category.id} value={category.id}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {getCategoryIcon(category.name, category.icon)}
                      {category.name}
                    </Box>
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <FormControlLabel
              control={
                <Switch
                  checked={newBrand.isActive}
                  onChange={(e) => setNewBrand({ ...newBrand, isActive: e.target.checked })}
                />
              }
              label="Marque active"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setBrandDialogOpen(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={selectedBrand ? handleUpdateBrand : handleCreateBrand}
            disabled={!newBrand.name || loading}
          >
            {loading ? <CircularProgress size={20} /> : (selectedBrand ? 'Modifier' : 'Créer')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialogue pour créer/modifier une catégorie */}
      <Dialog open={categoryDialogOpen} onClose={() => setCategoryDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {selectedCategory ? 'Modifier la catégorie' : 'Créer une nouvelle catégorie'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <TextField
              label="Nom de la catégorie"
              value={newCategory.name}
              onChange={(e) => setNewCategory({ ...newCategory, name: e.target.value })}
              fullWidth
              required
            />
            
            <TextField
              label="Description"
              value={newCategory.description}
              onChange={(e) => setNewCategory({ ...newCategory, description: e.target.value })}
              fullWidth
              multiline
              rows={3}
            />
            
            <Box>
              <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 'bold' }}>
                Sélectionner une icône pour la catégorie
              </Typography>
              <Box sx={{ maxHeight: '400px', overflowY: 'auto', border: '1px solid #e0e0e0', borderRadius: 1, p: 2 }}>
                <CategoryIconGrid 
                  selectedIcon={newCategory.icon}
                  onIconSelect={(iconType) => setNewCategory({ ...newCategory, icon: iconType })}
                />
              </Box>
            </Box>
            
            <FormControlLabel
              control={
                <Switch
                  checked={newCategory.isActive}
                  onChange={(e) => setNewCategory({ ...newCategory, isActive: e.target.checked })}
                />
              }
              label="Catégorie active"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCategoryDialogOpen(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={selectedCategory ? handleUpdateCategory : handleCreateCategory}
            disabled={!newCategory.name || loading}
          >
            {loading ? <CircularProgress size={20} /> : (selectedCategory ? 'Modifier' : 'Créer')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialogue pour créer/modifier un modèle */}
      <Dialog open={modelDialogOpen} onClose={() => setModelDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          {selectedModel ? 'Modifier le modèle' : 'Créer un nouveau modèle'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <TextField
              label="Nom du modèle"
              value={newModel.name}
              onChange={(e) => setNewModel({ ...newModel, name: e.target.value })}
              fullWidth
              required
              placeholder="Ex: iPhone 14, Galaxy S23, etc."
            />
            
            <TextField
              label="Description"
              value={newModel.description}
              onChange={(e) => setNewModel({ ...newModel, description: e.target.value })}
              fullWidth
              multiline
              rows={3}
            />
            
            <FormControl fullWidth required>
              <InputLabel>Marque</InputLabel>
              <Select
                value={newModel.brandId || ''}
                onChange={(e) => setNewModel({ ...newModel, brandId: e.target.value })}
                label="Marque"
              >
                {(allBrands || []).map((brand) => (
                  <MenuItem key={brand.id} value={brand.id}>
                    {brand.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            <FormControl fullWidth required>
              <InputLabel>Catégorie</InputLabel>
              <Select
                value={newModel.categoryId || ''}
                onChange={(e) => setNewModel({ ...newModel, categoryId: e.target.value })}
                label="Catégorie"
              >
                {(allCategories || []).map((category) => (
                  <MenuItem key={category.id} value={category.id}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {getCategoryIcon(category.name, category.icon)}
                      <span>{category.name}</span>
                    </Box>
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            
            
            <FormControlLabel
              control={
                <Switch
                  checked={newModel.isActive}
                  onChange={(e) => setNewModel({ ...newModel, isActive: e.target.checked })}
                />
              }
              label="Modèle actif"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setModelDialogOpen(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            onClick={selectedModel ? handleUpdateModel : handleCreateModel}
            disabled={!newModel.name || !newModel.brandId || !newModel.categoryId || loading}
          >
            {loading ? <CircularProgress size={20} /> : (selectedModel ? 'Modifier' : 'Créer')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialogue de confirmation de suppression */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>
          Confirmer la suppression
        </DialogTitle>
        <DialogContent>
          <Typography>
            Êtes-vous sûr de vouloir supprimer {deleteItem?.type === 'brand' ? 'cette marque' : deleteItem?.type === 'category' ? 'cette catégorie' : 'ce modèle'} ?
            Cette action est irréversible.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>
            Annuler
          </Button>
          <Button 
            variant="contained" 
            color="error"
            onClick={confirmDelete}
            disabled={loading}
          >
            {loading ? <CircularProgress size={20} /> : 'Supprimer'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DeviceManagement;
