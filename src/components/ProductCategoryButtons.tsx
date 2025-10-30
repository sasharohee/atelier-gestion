import React, { useState } from 'react';
import {
  Box,
  Button,
  Typography,
  Paper,
  Grid,
  Chip,
  Tooltip,
  IconButton,
} from '@mui/material';
import {
  PhoneAndroid as PhoneIcon,
  SportsEsports as ConsoleIcon,
  Laptop as LaptopIcon,
  DesktopWindows as DesktopIcon,
  Watch as WatchIcon,
  Build as BuildIcon,
  Extension as AccessoryIcon,
  Category as CategoryIcon,
  Memory as MemoryIcon,
  Headset as HeadsetIcon,
  Speaker as SpeakerIcon,
  Cable as CableIcon,
  ShoppingCart as ShoppingCartIcon,
  Add as AddIcon,
} from '@mui/icons-material';

interface ProductItem {
  id: string;
  name: string;
  price: number;
  type: 'product' | 'service' | 'part';
  category: string;
  subcategory?: string;
  description?: string;
  stock?: number;
}

interface ProductCategoryButtonsProps {
  products: ProductItem[];
  services: ProductItem[];
  parts: ProductItem[];
  onItemSelect: (item: ProductItem) => void;
  onCreateItem: (type: 'product' | 'service' | 'part', category?: string) => void;
  disabled?: boolean;
}

const ProductCategoryButtons: React.FC<ProductCategoryButtonsProps> = ({
  products,
  services,
  parts,
  onItemSelect,
  onCreateItem,
  disabled = false,
}) => {
  // État pour la navigation par catégorie
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  // État pour la sous-catégorie (uniquement pour les produits)
  const [selectedSubcategory, setSelectedSubcategory] = useState<string | null>(null);

  // Mapping des catégories aux icônes
  const getCategoryIcon = (category: string) => {
    const iconMap: { [key: string]: React.ReactElement } = {
      smartphone: <PhoneIcon sx={{ fontSize: 32 }} />,
      console: <ConsoleIcon sx={{ fontSize: 32 }} />,
      ordinateur_portable: <LaptopIcon sx={{ fontSize: 32 }} />,
      ordinateur_fixe: <DesktopIcon sx={{ fontSize: 32 }} />,
      montre: <WatchIcon sx={{ fontSize: 32 }} />,
      manette_jeux: <ConsoleIcon sx={{ fontSize: 32 }} />,
      accessoire: <AccessoryIcon sx={{ fontSize: 32 }} />,
      réparation: <BuildIcon sx={{ fontSize: 32 }} />,
      maintenance: <BuildIcon sx={{ fontSize: 32 }} />,
      diagnostic: <BuildIcon sx={{ fontSize: 32 }} />,
      installation: <BuildIcon sx={{ fontSize: 32 }} />,
      memory: <MemoryIcon sx={{ fontSize: 32 }} />,
      headset: <HeadsetIcon sx={{ fontSize: 32 }} />,
      speaker: <SpeakerIcon sx={{ fontSize: 32 }} />,
      cable: <CableIcon sx={{ fontSize: 32 }} />,
    };
    return iconMap[category] || <CategoryIcon sx={{ fontSize: 32 }} />;
  };

  // Grouper les items par type (Produits, Services, Pièces détachées)
  const groupedByType = {
    'Produits': products,
    'Services': services,
    'Pièces détachées': parts,
  };

  // Obtenir les types qui ont des items
  const availableTypes = Object.keys(groupedByType).filter(type => 
    groupedByType[type as keyof typeof groupedByType].length > 0
  );

  const getTypeIcon = (type: string) => {
    const iconMap: { [key: string]: React.ReactElement } = {
      'Produits': <ShoppingCartIcon sx={{ fontSize: 32 }} />,
      'Services': <BuildIcon sx={{ fontSize: 32 }} />,
      'Pièces détachées': <MemoryIcon sx={{ fontSize: 32 }} />,
    };
    return iconMap[type] || <CategoryIcon sx={{ fontSize: 32 }} />;
  };

  const getTypeColor = (type: string) => {
    const colorMap: { [key: string]: string } = {
      'Produits': '#1976d2',
      'Services': '#9c27b0', 
      'Pièces détachées': '#2e7d32',
    };
    return colorMap[type] || '#666';
  };

  const getItemTypeColor = (type: string) => {
    switch (type) {
      case 'product':
        return '#1976d2';
      case 'service':
        return '#9c27b0';
      case 'part':
        return '#2e7d32';
      default:
        return '#666';
    }
  };

  const getItemTypeLabel = (type: string) => {
    switch (type) {
      case 'product':
        return 'Produit';
      case 'service':
        return 'Service';
      case 'part':
        return 'Pièce';
      default:
        return 'Article';
    }
  };

  // Fonction pour revenir à la vue des catégories
  const handleBackToCategories = () => {
    setSelectedCategory(null);
    setSelectedSubcategory(null);
  };

  // Fonction pour revenir aux sous-catégories (produits uniquement)
  const handleBackToSubcategories = () => {
    setSelectedSubcategory(null);
  };

  // Fonction pour sélectionner une catégorie
  const handleSelectCategory = (type: string) => {
    setSelectedCategory(type);
    setSelectedSubcategory(null);
  };

  // Fonction pour sélectionner une sous-catégorie (produits uniquement)
  const handleSelectSubcategory = (subcategory: string) => {
    setSelectedSubcategory(subcategory);
  };

  // Obtenir les sous-catégories pour les produits
  const getProductSubcategories = () => {
    const subcategories = Array.from(new Set(
      products
        .filter(p => p.subcategory)
        .map(p => p.subcategory!)
    ));
    return subcategories.sort();
  };

  // Obtenir les produits de la sous-catégorie sélectionnée
  const getProductsBySubcategory = (subcategory: string) => {
    return products.filter(p => p.subcategory === subcategory);
  };

  // Obtenir les produits sans sous-catégorie
  const getProductsWithoutSubcategory = () => {
    return products.filter(p => !p.subcategory);
  };

  // Obtenir les sous-catégories pour les services
  const getServiceSubcategories = () => {
    const subcategories = Array.from(new Set(
      services
        .filter(s => s.subcategory)
        .map(s => s.subcategory!)
    ));
    return subcategories.sort();
  };

  // Obtenir les services de la sous-catégorie sélectionnée
  const getServicesBySubcategory = (subcategory: string) => {
    return services.filter(s => s.subcategory === subcategory);
  };

  // Obtenir les services sans sous-catégorie
  const getServicesWithoutSubcategory = () => {
    return services.filter(s => !s.subcategory);
  };

  // Obtenir les sous-catégories pour les pièces détachées
  const getPartSubcategories = () => {
    const subcategories = Array.from(new Set(
      parts
        .filter(p => p.subcategory)
        .map(p => p.subcategory!)
    ));
    return subcategories.sort();
  };

  // Obtenir les pièces de la sous-catégorie sélectionnée
  const getPartsBySubcategory = (subcategory: string) => {
    return parts.filter(p => p.subcategory === subcategory);
  };

  // Obtenir les pièces sans sous-catégorie
  const getPartsWithoutSubcategory = () => {
    return parts.filter(p => !p.subcategory);
  };

  // Obtenir les sous-catégories selon le type
  const getSubcategories = () => {
    if (!selectedCategory) return [];
    switch (selectedCategory) {
      case 'Produits':
        return getProductSubcategories();
      case 'Services':
        return getServiceSubcategories();
      case 'Pièces détachées':
        return getPartSubcategories();
      default:
        return [];
    }
  };

  // Obtenir les items de la sous-catégorie sélectionnée selon le type
  const getItemsBySubcategory = (subcategory: string) => {
    if (!selectedCategory) return [];
    switch (selectedCategory) {
      case 'Produits':
        return getProductsBySubcategory(subcategory);
      case 'Services':
        return getServicesBySubcategory(subcategory);
      case 'Pièces détachées':
        return getPartsBySubcategory(subcategory);
      default:
        return [];
    }
  };

  // Obtenir les items sans sous-catégorie selon le type
  const getItemsWithoutSubcategory = () => {
    if (!selectedCategory) return [];
    switch (selectedCategory) {
      case 'Produits':
        return getProductsWithoutSubcategory();
      case 'Services':
        return getServicesWithoutSubcategory();
      case 'Pièces détachées':
        return getPartsWithoutSubcategory();
      default:
        return [];
    }
  };

  // Obtenir les items de la catégorie sélectionnée
  const getSelectedCategoryItems = () => {
    if (!selectedCategory) return [];
    
    // Si on a une sous-catégorie sélectionnée
    if (selectedSubcategory) {
      if (selectedSubcategory === '__NO_SUBCATEGORY__') {
        return getItemsWithoutSubcategory();
      }
      return getItemsBySubcategory(selectedSubcategory);
    }
    
    return groupedByType[selectedCategory as keyof typeof groupedByType] || [];
  };

  return (
    <Paper 
      elevation={2} 
      sx={{ 
        p: 2, 
        bgcolor: '#f8f9fa',
        borderRadius: 2,
        height: '100%',
        overflow: 'auto'
      }}
    >
      <Typography 
        variant="h6" 
        gutterBottom 
        sx={{ 
          fontWeight: 600, 
          color: '#333',
          mb: 2,
          textAlign: 'center'
        }}
      >
        📦 Sélection d'articles
      </Typography>

      {/* Vue des catégories principales */}
      {!selectedCategory && (
        <Grid container spacing={3}>
          {availableTypes.map((type) => {
            const items = groupedByType[type as keyof typeof groupedByType];
            const typeIcon = getTypeIcon(type);
            const typeColor = getTypeColor(type);

            return (
              <Grid item xs={12} sm={6} key={type}>
                <Button
                  fullWidth
                  variant="contained"
                  onClick={() => handleSelectCategory(type)}
                  disabled={disabled}
                  sx={{
                    height: 160,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    p: 3,
                    bgcolor: typeColor,
                    '&:hover': {
                      bgcolor: typeColor,
                      opacity: 0.9,
                      transform: 'translateY(-3px)',
                      boxShadow: 6,
                    },
                    '&:disabled': {
                      bgcolor: '#e0e0e0',
                      color: '#9e9e9e',
                    },
                    transition: 'all 0.3s ease-in-out',
                    borderRadius: 3,
                    minHeight: 160,
                  }}
                >
                  {/* Icône de la catégorie */}
                  <Box sx={{ color: 'white', mb: 2 }}>
                    {React.cloneElement(typeIcon, { sx: { fontSize: 48 } })}
                  </Box>

                  {/* Nom de la catégorie */}
                  <Typography 
                    variant="h5" 
                    sx={{ 
                      fontWeight: 700,
                      color: 'white',
                      textAlign: 'center',
                      mb: 1.5,
                      fontSize: '1.4rem'
                    }}
                  >
                    {type}
                  </Typography>

                  {/* Nombre d'articles */}
                  <Chip 
                    label={`${items.length} articles`}
                    size="medium"
                    sx={{
                      bgcolor: 'rgba(255,255,255,0.25)',
                      color: 'white',
                      fontWeight: 600,
                      fontSize: '0.9rem',
                      height: 32,
                      '& .MuiChip-label': {
                        px: 2,
                        py: 0.5,
                      },
                    }}
                  />
                </Button>
              </Grid>
            );
          })}
        </Grid>
      )}

      {/* Vue des sous-catégories pour tous les types OU articles directs */}
      {selectedCategory && (
        <Box>
          {/* Si aucune sous-catégorie n'est sélectionnée, afficher les sous-catégories */}
          {!selectedSubcategory ? (
            <>
              {/* En-tête avec bouton retour */}
              <Box 
                sx={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  mb: 2,
                  p: 1,
                  bgcolor: 'white',
                  borderRadius: 1,
                  border: '1px solid #e0e0e0'
                }}
              >
                <Button
                  size="small"
                  onClick={handleBackToCategories}
                  sx={{ mr: 2, minWidth: 'auto' }}
                >
                  ← Retour
                </Button>
                <Box sx={{ color: getTypeColor(selectedCategory), mr: 1 }}>
                  {getTypeIcon(selectedCategory)}
                </Box>
                <Typography 
                  variant="h6" 
                  sx={{ 
                    fontWeight: 600, 
                    color: '#333',
                    flexGrow: 1
                  }}
                >
                  {selectedCategory} - Sous-catégories
                </Typography>
                <Tooltip title={`Créer un nouveau ${selectedCategory.toLowerCase()}`}>
                  <IconButton
                    size="small"
                    onClick={() => {
                      const itemTypeMap: { [key: string]: 'product' | 'service' | 'part' } = {
                        'Produits': 'product',
                        'Services': 'service',
                        'Pièces détachées': 'part',
                      };
                      onCreateItem(itemTypeMap[selectedCategory] || 'product');
                    }}
                    disabled={disabled}
                    sx={{
                      bgcolor: getTypeColor(selectedCategory),
                      color: 'white',
                      '&:hover': {
                        bgcolor: getTypeColor(selectedCategory),
                        opacity: 0.8,
                      },
                      '&:disabled': {
                        bgcolor: '#e0e0e0',
                        color: '#9e9e9e',
                      },
                    }}
                  >
                    <AddIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </Box>

              {/* Grille des sous-catégories */}
              <Grid container spacing={1}>
                {getSubcategories().map((subcategory) => {
                  const count = getItemsBySubcategory(subcategory).length;
                  const itemLabel = selectedCategory === 'Produits' ? 'produit' : 
                                    selectedCategory === 'Services' ? 'service' : 'pièce';
                  return (
                    <Grid item xs={6} sm={4} key={subcategory}>
                      <Button
                        fullWidth
                        variant="contained"
                        onClick={() => handleSelectSubcategory(subcategory)}
                        disabled={disabled}
                        sx={{
                          height: 100,
                          display: 'flex',
                          flexDirection: 'column',
                          alignItems: 'center',
                          justifyContent: 'center',
                          p: 1,
                          bgcolor: getTypeColor(selectedCategory),
                          '&:hover': {
                            bgcolor: getTypeColor(selectedCategory),
                            opacity: 0.8,
                            transform: 'translateY(-2px)',
                            boxShadow: 3,
                          },
                          transition: 'all 0.2s ease-in-out',
                        }}
                      >
                        <Typography 
                          variant="body2" 
                          sx={{ 
                            fontWeight: 600,
                            color: 'white',
                            textAlign: 'center',
                            mb: 0.5,
                          }}
                        >
                          {subcategory}
                        </Typography>
                        <Chip
                          label={`${count} ${itemLabel}${count > 1 ? 's' : ''}`}
                          size="small"
                          sx={{
                            bgcolor: 'rgba(255,255,255,0.25)',
                            color: 'white',
                            height: 20,
                            fontSize: '0.7rem',
                            '& .MuiChip-label': {
                              px: 1,
                            },
                          }}
                        />
                      </Button>
                    </Grid>
                  );
                })}
                
                {/* Afficher les items sans sous-catégorie s'il y en a */}
                {getItemsWithoutSubcategory().length > 0 && (
                  <Grid item xs={6} sm={4}>
                    <Button
                      fullWidth
                      variant="contained"
                      onClick={() => handleSelectSubcategory('__NO_SUBCATEGORY__')}
                      disabled={disabled}
                      sx={{
                        height: 100,
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'center',
                        p: 1,
                        bgcolor: '#666',
                        '&:hover': {
                          bgcolor: '#555',
                          transform: 'translateY(-2px)',
                          boxShadow: 3,
                        },
                        transition: 'all 0.2s ease-in-out',
                      }}
                    >
                      <Typography 
                        variant="body2" 
                        sx={{ 
                          fontWeight: 600,
                          color: 'white',
                          textAlign: 'center',
                          mb: 0.5,
                        }}
                      >
                        Non catégorisé
                      </Typography>
                      <Chip
                        label={`${getItemsWithoutSubcategory().length} ${selectedCategory.toLowerCase()}`}
                        size="small"
                        sx={{
                          bgcolor: 'rgba(255,255,255,0.25)',
                          color: 'white',
                          height: 20,
                          fontSize: '0.7rem',
                          '& .MuiChip-label': {
                            px: 1,
                          },
                        }}
                      />
                    </Button>
                  </Grid>
                )}
              </Grid>

                  {getSubcategories().length === 0 && getItemsWithoutSubcategory().length === 0 && (
                <Box sx={{ textAlign: 'center', py: 4 }}>
                  <Typography variant="body1" color="text.secondary">
                    Aucun {selectedCategory.toLowerCase()} disponible
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Cliquez sur le bouton "+" pour en créer un
                  </Typography>
                </Box>
              )}
            </>
          ) : (
            <>
              {/* En-tête avec bouton retour */}
              <Box 
                sx={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  mb: 2,
                  p: 1,
                  bgcolor: 'white',
                  borderRadius: 1,
                  border: '1px solid #e0e0e0'
                }}
              >
                <Button
                  size="small"
                  onClick={handleBackToSubcategories}
                  sx={{ mr: 2, minWidth: 'auto' }}
                >
                  ← Retour
                </Button>
                <Box sx={{ color: getTypeColor(selectedCategory), mr: 1 }}>
                  {getTypeIcon(selectedCategory)}
                </Box>
                <Typography 
                  variant="h6" 
                  sx={{ 
                    fontWeight: 600, 
                    color: '#333',
                    flexGrow: 1
                  }}
                >
                  {selectedSubcategory === '__NO_SUBCATEGORY__' 
                    ? `${selectedCategory} - Non catégorisé`
                    : selectedSubcategory
                    ? `${selectedCategory} - ${selectedSubcategory}`
                    : selectedCategory}
                </Typography>
                <Chip 
                  label={getSelectedCategoryItems().length} 
                  size="small" 
                  sx={{ 
                    fontWeight: 600,
                    bgcolor: getTypeColor(selectedCategory),
                    color: 'white',
                    mr: 1
                  }}
                />
                <Tooltip title={`Créer un nouveau ${selectedCategory.toLowerCase()}`}>
                  <IconButton
                    size="small"
                    onClick={() => {
                      const typeMap = {
                        'Produits': 'product' as const,
                        'Services': 'service' as const,
                        'Pièces détachées': 'part' as const,
                      };
                      onCreateItem(typeMap[selectedCategory as keyof typeof typeMap]);
                    }}
                    disabled={disabled}
                    sx={{
                      bgcolor: getTypeColor(selectedCategory),
                      color: 'white',
                      '&:hover': {
                        bgcolor: getTypeColor(selectedCategory),
                        opacity: 0.8,
                      },
                      '&:disabled': {
                        bgcolor: '#e0e0e0',
                        color: '#9e9e9e',
                      },
                    }}
                  >
                    <AddIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </Box>

              {/* Grille des articles */}
              <Grid container spacing={1}>
                {(selectedSubcategory === '__NO_SUBCATEGORY__' 
                  ? getProductsWithoutSubcategory() 
                  : getSelectedCategoryItems()).map((item) => (
                  <Grid item xs={6} sm={4} key={`${item.type}-${item.id}`}>
                    <Tooltip 
                      title={
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {item.name}
                          </Typography>
                          {item.description && (
                            <Typography variant="caption" sx={{ display: 'block', mt: 0.5 }}>
                              {item.description}
                            </Typography>
                          )}
                          {item.stock !== undefined && (
                            <Typography variant="caption" sx={{ display: 'block', mt: 0.5 }}>
                              Stock: {item.stock}
                            </Typography>
                          )}
                        </Box>
                      }
                      arrow
                    >
                      <Button
                        fullWidth
                        variant="contained"
                        onClick={() => onItemSelect(item)}
                        disabled={disabled || (item.type === 'part' && (item.stock || 0) <= 0)}
                        sx={{
                          height: 100,
                          display: 'flex',
                          flexDirection: 'column',
                          alignItems: 'center',
                          justifyContent: 'center',
                          p: 1,
                          bgcolor: '#4caf50',
                          '&:hover': {
                            bgcolor: '#45a049',
                            transform: 'translateY(-2px)',
                            boxShadow: 3,
                          },
                          '&:disabled': {
                            bgcolor: '#e0e0e0',
                            color: '#9e9e9e',
                          },
                          transition: 'all 0.2s ease-in-out',
                        }}
                      >
                        {/* Icône du type */}
                        <Box 
                          sx={{ 
                            color: 'white', 
                            mb: 0.5,
                            opacity: 0.9
                          }}
                        >
                          {getCategoryIcon(item.category)}
                        </Box>

                        {/* Nom de l'article */}
                        <Typography 
                          variant="caption" 
                          sx={{ 
                            fontWeight: 600,
                            textAlign: 'center',
                            lineHeight: 1.2,
                            color: 'white',
                            fontSize: '0.7rem',
                            mb: 0.5,
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            display: '-webkit-box',
                            WebkitLineClamp: 2,
                            WebkitBoxOrient: 'vertical',
                          }}
                        >
                          {item.name}
                        </Typography>

                        {/* Prix */}
                        <Typography 
                          variant="caption" 
                          sx={{ 
                            fontWeight: 700,
                            color: 'white',
                            fontSize: '0.8rem',
                            bgcolor: 'rgba(0,0,0,0.2)',
                            px: 1,
                            py: 0.25,
                            borderRadius: 1,
                          }}
                        >
                          {item.price.toLocaleString('fr-FR')} €
                        </Typography>

                        {/* Badge stock pour les pièces */}
                        {item.type === 'part' && item.stock !== undefined && (
                          <Chip
                            label={`Stock: ${item.stock}`}
                            size="small"
                            sx={{
                              position: 'absolute',
                              bottom: 4,
                              left: 4,
                              height: 16,
                              fontSize: '0.6rem',
                              bgcolor: item.stock > 0 ? '#2e7d32' : '#f44336',
                              color: 'white',
                              '& .MuiChip-label': {
                                px: 0.5,
                                fontSize: '0.6rem',
                              },
                            }}
                          />
                        )}
                      </Button>
                    </Tooltip>
                  </Grid>
                ))}
              </Grid>

              {(selectedSubcategory === '__NO_SUBCATEGORY__' 
                ? getProductsWithoutSubcategory().length === 0 
                : getSelectedCategoryItems().length === 0) && (
                <Box sx={{ textAlign: 'center', py: 4 }}>
                  <Typography variant="body1" color="text.secondary">
                    Aucun article dans cette catégorie
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Cliquez sur le bouton "+" pour en créer un
                  </Typography>
                </Box>
              )}
            </>
          )}
        </Box>
      )}

      {availableTypes.length === 0 && (
        <Box sx={{ textAlign: 'center', py: 4 }}>
          <Typography variant="body1" color="text.secondary">
            Aucun article disponible
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Ajoutez des produits, services ou pièces dans le catalogue
          </Typography>
        </Box>
      )}
    </Paper>
  );
};

export default ProductCategoryButtons;
