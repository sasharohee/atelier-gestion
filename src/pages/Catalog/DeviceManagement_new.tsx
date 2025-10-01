// @ts-nocheck
import React, { useState, useEffect } from 'react';
import { useAppStore } from '../../store';
import { DeviceCategory, DeviceBrand, DeviceModel } from '../../types/deviceManagement';
import { categoryService, ProductCategory } from '../../services/categoryService';
import { brandService, BrandWithCategories, CreateBrandData, UpdateBrandData } from '../../services/brandService_new';
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

interface NewBrandForm {
  name: string;
  description: string;
  logo: string;
  categoryIds: string[];
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
  const [modelDialogOpen, setModelDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleteItem, setDeleteItem] = useState<{ type: 'brand' | 'model'; item: any } | null>(null);
  
  // États pour les formulaires
  const [selectedBrand, setSelectedBrand] = useState<BrandWithCategories | null>(null);
  const [selectedModel, setSelectedModel] = useState<DeviceModel | null>(null);
  const [newBrand, setNewBrand] = useState<NewBrandForm>({
    name: '',
    description: '',
    logo: '',
    categoryIds: [],
    isActive: true,
  });
  const [newModel, setNewModel] = useState<DeviceModel>({
    id: '',
    name: '',
    brandId: '',
    categoryId: '',
    description: '',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
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
      const categories = await categoryService.getAll();
      setAllCategories(categories);
      
      // Charger les marques
      const brands = await brandService.getAll();
      setAllBrands(brands);
      
      console.log('✅ Données chargées avec succès');
    } catch (err) {
      console.error('❌ Erreur lors du chargement des données:', err);
      setError('Erreur lors du chargement des données');
    } finally {
      setLoading(false);
    }
  };

  // Fonctions pour les marques
  const handleCreateBrand = async () => {
    try {
      setLoading(true);
      
      const brandData: CreateBrandData = {
        name: newBrand.name,
        description: newBrand.description,
        logo: newBrand.logo,
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
        logo: newBrand.logo,
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
      logo: '',
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
      logo: brand.logo,
      categoryIds: brand.categories.map(cat => cat.id),
      isActive: brand.isActive,
    });
    setBrandDialogOpen(true);
  };

  const openDeleteDialog = (item: any, type: 'brand' | 'model') => {
    setDeleteItem({ type, item });
    setDeleteDialogOpen(true);
  };

  const confirmDelete = async () => {
    if (!deleteItem) return;
    
    if (deleteItem.type === 'brand') {
      await handleDeleteBrand(deleteItem.item);
    }
    
    setDeleteDialogOpen(false);
    setDeleteItem(null);
  };

  // Filtrer les marques
  const filteredBrands = allBrands.filter(brand => {
    const matchesSearch = brand.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         brand.description.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesCategory = !selectedCategoryForBrands || 
                           brand.categories.some(cat => cat.id === selectedCategoryForBrands);
    
    return matchesSearch && matchesCategory;
  });

  // Compter les marques par catégorie
  const brandCountByCategory = allCategories.map(category => ({
    category,
    count: allBrands.filter(brand => 
      brand.categories.some(cat => cat.id === category.id)
    ).length
  }));

  // Obtenir l'icône pour une catégorie
  const getCategoryIcon = (categoryName: string) => {
    const iconMap: { [key: string]: React.ReactElement } = {
      'Smartphone': <PhoneIcon />,
      'Tablette': <TabletIcon />,
      'Ordinateur portable': <LaptopIcon />,
      'Ordinateur de bureau': <ComputerIcon />,
      'Accessoire': <DeviceHubIcon />,
    };
    return iconMap[categoryName] || <CategoryIcon />;
  };

  if (loading && allBrands.length === 0) {
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
                  value={selectedCategoryForBrands}
                  onChange={(e) => setSelectedCategoryForBrands(e.target.value)}
                  label="Filtrer par catégorie"
                >
                  <MenuItem value="">Toutes les catégories</MenuItem>
                  {allCategories.map((category) => (
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
                          {brand.logo && (
                            <Avatar src={brand.logo} sx={{ width: 32, height: 32 }}>
                              {brand.name.charAt(0)}
                            </Avatar>
                          )}
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
                                icon={getCategoryIcon(category.name)}
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
            
            <TextField
              label="URL du logo"
              value={newBrand.logo}
              onChange={(e) => setNewBrand({ ...newBrand, logo: e.target.value })}
              fullWidth
              placeholder="https://example.com/logo.png"
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
                      const category = allCategories.find(cat => cat.id === value);
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
                {allCategories.map((category) => (
                  <MenuItem key={category.id} value={category.id}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      {getCategoryIcon(category.name)}
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

      {/* Dialogue de confirmation de suppression */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>
          Confirmer la suppression
        </DialogTitle>
        <DialogContent>
          <Typography>
            Êtes-vous sûr de vouloir supprimer {deleteItem?.type === 'brand' ? 'cette marque' : 'ce modèle'} ?
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
