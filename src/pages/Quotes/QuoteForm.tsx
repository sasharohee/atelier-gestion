import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Grid,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  List,
  ListItem,
  ListItemText,
  IconButton,
  Typography,
  Box,
  Divider,
  Alert,
  InputAdornment,
  Tooltip,
  Badge,
  Chip,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Inventory as InventoryIcon,
  Build as BuildIcon,
  ShoppingCart as ShoppingCartIcon,
  Euro as EuroIcon,
  AttachMoney as AttachMoneyIcon,
  CalendarToday as CalendarTodayIcon,
  Note as NoteIcon,
  Description as DescriptionIcon,
} from '@mui/icons-material';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { Client, Product, Service, Part, Device } from '../../types';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import RepairForm, { RepairFormData } from './RepairForm';

interface QuoteItemForm {
  type: 'product' | 'service' | 'part' | 'repair';
  itemId: string;
  name: string;
  description?: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

interface QuoteFormProps {
  open: boolean;
  onClose: () => void;
  onSubmit: () => void;
  clients: Client[];
  products: Product[];
  services: Service[];
  parts: Part[];
  devices: Device[];
  selectedClientId: string;
  setSelectedClientId: (clientId: string) => void;
  quoteItems: QuoteItemForm[];
  setQuoteItems: (items: QuoteItemForm[] | ((prev: QuoteItemForm[]) => QuoteItemForm[])) => void;
  totals: { subtotal: number; tax: number; total: number };
  validUntil: Date;
  setValidUntil: (date: Date) => void;
  notes: string;
  setNotes: (notes: string) => void;
  terms: string;
  setTerms: (terms: string) => void;
  filteredItems: Array<{ id: string; name: string; price: number; type: string; category?: string; description?: string }>;
  selectedItemType: 'product' | 'service' | 'part' | 'repair';
  setSelectedItemType: (type: 'product' | 'service' | 'part' | 'repair') => void;
  selectedCategory: string;
  setSelectedCategory: (category: string) => void;
  searchQuery: string;
  setSearchQuery: (query: string) => void;
  availableCategories: string[];
  addItemToQuote: (item: { id: string; name: string; price: number; type: string; description?: string }) => void;
  removeItemFromQuote: (itemId: string) => void;
  updateItemQuantity: (itemId: string, quantity: number) => void;
}

const QuoteForm: React.FC<QuoteFormProps> = ({
  open,
  onClose,
  onSubmit,
  clients,
  devices,
  selectedClientId,
  setSelectedClientId,
  quoteItems,
  setQuoteItems,
  totals,
  validUntil,
  setValidUntil,
  notes,
  setNotes,
  terms,
  setTerms,
  filteredItems,
  selectedItemType,
  setSelectedItemType,
  selectedCategory,
  setSelectedCategory,
  searchQuery,
  setSearchQuery,
  availableCategories,
  addItemToQuote,
  removeItemFromQuote,
  updateItemQuantity,
}) => {
  const [repairFormOpen, setRepairFormOpen] = useState(false);
  const { workshopSettings, isLoading: settingsLoading } = useWorkshopSettings();

  // Gérer la création d'une réparation
  const handleCreateRepair = (repairData: RepairFormData) => {
    const repairItem: QuoteItemForm = {
      type: 'repair',
      itemId: `repair_${Date.now()}`, // ID temporaire
      name: `Réparation - ${repairData.description.substring(0, 50)}${repairData.description.length > 50 ? '...' : ''}`,
      description: repairData.description,
      quantity: 1,
      unitPrice: repairData.estimatedPrice,
      totalPrice: repairData.estimatedPrice,
    };

    setQuoteItems((prev: QuoteItemForm[]) => [...prev, repairItem]);
    
    // Mettre à jour le client sélectionné si pas encore défini
    if (!selectedClientId) {
      setSelectedClientId(repairData.clientId);
    }
  };

  return (
    <>
      <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <DescriptionIcon sx={{ color: '#1976d2' }} />
            <Typography variant="h6">Nouveau devis</Typography>
          </Box>
        </DialogTitle>
        
        <DialogContent sx={{ minHeight: '600px' }}>
          <Grid container spacing={3}>
            {/* Informations client et validité */}
            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                📋 Informations générales
              </Typography>
              
              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Client</InputLabel>
                <Select 
                  value={selectedClientId} 
                  onChange={(e) => setSelectedClientId(e.target.value)}
                  label="Client"
                >
                  <MenuItem value="">Client anonyme</MenuItem>
                  {clients.map((client) => (
                    <MenuItem key={client.id} value={client.id}>
                      {client.firstName} {client.lastName}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              <DatePicker
                label="Validité jusqu'au"
                value={validUntil}
                onChange={(newValue) => newValue && setValidUntil(newValue)}
                slotProps={{
                  textField: {
                    fullWidth: true,
                    sx: { mb: 2 }
                  }
                }}
              />

              <TextField
                fullWidth
                multiline
                rows={3}
                label="Notes"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Notes additionnelles pour le client..."
                sx={{ mb: 2 }}
              />

              <TextField
                fullWidth
                multiline
                rows={3}
                label="Conditions et termes"
                value={terms}
                onChange={(e) => setTerms(e.target.value)}
                placeholder="Conditions de paiement, délais, garanties..."
              />
            </Grid>

            {/* Sélection d'articles */}
            <Grid item xs={12} md={6}>
              <Typography variant="h6" gutterBottom>
                📦 Sélection d'articles
              </Typography>
              
              {/* Type d'article */}
              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Type d'article</InputLabel>
                <Select 
                  value={selectedItemType} 
                  onChange={(e) => {
                    setSelectedItemType(e.target.value as 'product' | 'service' | 'part' | 'repair');
                    setSelectedCategory('all');
                    setSearchQuery('');
                  }}
                  label="Type d'article"
                >
                  <MenuItem value="product">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <span>🛍️ Produits & Accessoires</span>
                      <Chip 
                        label={filteredItems.filter(i => i.type === 'product').length} 
                        size="small" 
                        color="primary" 
                        variant="outlined"
                      />
                    </Box>
                  </MenuItem>
                  <MenuItem value="service">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <span>🔧 Services de Réparation</span>
                      <Chip 
                        label={filteredItems.filter(i => i.type === 'service').length} 
                        size="small" 
                        color="primary" 
                        variant="outlined"
                      />
                    </Box>
                  </MenuItem>
                  <MenuItem value="part">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <span>🔩 Pièces Détachées</span>
                      <Chip 
                        label={filteredItems.filter(i => i.type === 'part').length} 
                        size="small" 
                        color="primary" 
                        variant="outlined"
                      />
                    </Box>
                  </MenuItem>
                  <MenuItem value="repair">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <span>🔧 Réparations</span>
                      <Chip 
                        label="Créer" 
                        size="small" 
                        color="secondary" 
                        variant="outlined"
                      />
                    </Box>
                  </MenuItem>
                </Select>
              </FormControl>

              {/* Catégorie */}
              <FormControl fullWidth sx={{ mb: 2 }}>
                <InputLabel>Catégorie</InputLabel>
                <Select 
                  value={selectedCategory} 
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  label="Catégorie"
                >
                  {availableCategories.map((category) => (
                    <MenuItem key={category} value={category}>
                      {category === 'all' ? 'Toutes les catégories' : category}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              {/* Recherche et création de réparation */}
              {selectedItemType === 'repair' ? (
                <Box sx={{ textAlign: 'center', py: 3 }}>
                  <BuildIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
                  <Typography variant="h6" color="text.secondary" gutterBottom>
                    Créer une nouvelle réparation
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                    Créez une réparation personnalisée pour ce devis
                  </Typography>
                  <Button
                    variant="contained"
                    startIcon={<BuildIcon />}
                    onClick={() => setRepairFormOpen(true)}
                    sx={{ 
                      backgroundColor: '#1976d2',
                      '&:hover': { backgroundColor: '#1565c0' }
                    }}
                  >
                    Créer une réparation
                  </Button>
                </Box>
              ) : (
                <>
                  {/* Recherche */}
                  <TextField
                    fullWidth
                    placeholder="Rechercher un article..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <SearchIcon />
                        </InputAdornment>
                      ),
                    }}
                    sx={{ mb: 2 }}
                  />

                  {/* Liste des articles disponibles */}
                  <Box sx={{ maxHeight: '300px', overflow: 'auto', border: '1px solid #e0e0e0', borderRadius: 1, p: 1 }}>
                    {filteredItems.length === 0 ? (
                      <Box sx={{ textAlign: 'center', py: 2 }}>
                        <Typography variant="body2" color="text.secondary">
                          Aucun article trouvé
                        </Typography>
                      </Box>
                    ) : (
                      <List dense>
                        {filteredItems.map((item) => (
                          <ListItem
                            key={item.id}
                            button
                            onClick={() => addItemToQuote(item)}
                            sx={{
                              border: '1px solid #f0f0f0',
                              borderRadius: 1,
                              mb: 1,
                              flexDirection: 'column',
                              alignItems: 'stretch',
                              gap: 1,
                              py: 1,
                              '&:hover': {
                                backgroundColor: '#f5f5f5',
                                borderColor: '#1976d2',
                              },
                            }}
                          >
                            {/* Ligne principale avec nom et prix */}
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Typography variant="body2" sx={{ fontWeight: 500 }}>
                                {item.name}
                              </Typography>
                              <Typography variant="body2" sx={{ fontWeight: 600, color: '#1976d2' }}>
                                {item.price.toLocaleString('fr-FR')} €
                              </Typography>
                            </Box>
                            
                            {/* Ligne secondaire avec description et type */}
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              {item.description && (
                                <Typography variant="caption" color="text.secondary">
                                  {item.description}
                                </Typography>
                              )}
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                {item.type === 'product' && <ShoppingCartIcon sx={{ fontSize: '14px' }} />}
                                {item.type === 'service' && <BuildIcon sx={{ fontSize: '14px' }} />}
                                {item.type === 'part' && <InventoryIcon sx={{ fontSize: '14px' }} />}
                                <Typography variant="caption" color="text.secondary">
                                  {item.category || 'Sans catégorie'}
                                </Typography>
                              </Box>
                            </Box>
                          </ListItem>
                        ))}
                      </List>
                    )}
                  </Box>
                </>
              )}
            </Grid>

            {/* Articles sélectionnés */}
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                📋 Articles du devis
              </Typography>
              
              {quoteItems.length === 0 ? (
                <Alert severity="info">
                  Aucun article ajouté au devis. Sélectionnez des articles dans la liste ci-dessus.
                </Alert>
              ) : (
                <Box sx={{ border: '1px solid #e0e0e0', borderRadius: 1, overflow: 'hidden' }}>
                  <List dense>
                    {quoteItems.map((item) => (
                      <ListItem
                        key={item.itemId}
                        sx={{
                          borderBottom: '1px solid #f0f0f0',
                          '&:last-child': { borderBottom: 'none' },
                          flexDirection: 'column',
                          alignItems: 'stretch',
                          gap: 1,
                          py: 2
                        }}
                      >
                        {/* Ligne principale avec nom et prix */}
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Typography variant="body2" sx={{ fontWeight: 500 }}>
                            {item.name}
                          </Typography>
                          <Typography variant="body2" sx={{ fontWeight: 600, color: '#1976d2' }}>
                            {item.totalPrice.toLocaleString('fr-FR')} €
                          </Typography>
                        </Box>
                        
                        {/* Ligne secondaire avec quantité et prix unitaire */}
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                            <TextField
                              type="number"
                              size="small"
                              label="Qté"
                              value={item.quantity}
                              onChange={(e) => updateItemQuantity(item.itemId, parseInt(e.target.value) || 0)}
                              inputProps={{ min: 1, style: { width: '60px' } }}
                              sx={{ width: '80px' }}
                            />
                            <Typography variant="caption" color="text.secondary">
                              {item.unitPrice.toLocaleString('fr-FR')} € l'unité
                            </Typography>
                          </Box>
                          
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            {item.description && (
                              <Typography variant="caption" color="text.secondary" sx={{ maxWidth: '200px' }}>
                                {item.description}
                              </Typography>
                            )}
                            <Tooltip title="Supprimer">
                              <IconButton
                                size="small"
                                onClick={() => removeItemFromQuote(item.itemId)}
                                sx={{ color: '#f44336' }}
                              >
                                <DeleteIcon />
                              </IconButton>
                            </Tooltip>
                          </Box>
                        </Box>
                      </ListItem>
                    ))}
                  </List>
                </Box>
              )}
            </Grid>

            {/* Totaux */}
            <Grid item xs={12}>
              <Box sx={{ 
                display: 'flex', 
                justifyContent: 'flex-end', 
                border: '1px solid #e0e0e0', 
                borderRadius: 1, 
                p: 2,
                backgroundColor: '#fafafa'
              }}>
                <Box sx={{ textAlign: 'right' }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
                    <Typography variant="body2">Sous-total :</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                      {totals.subtotal.toLocaleString('fr-FR')} €
                    </Typography>
                  </Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
                    <Typography variant="body2">
                      TVA ({settingsLoading ? '...' : workshopSettings.vatRate}%) :
                    </Typography>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                      {totals.tax.toLocaleString('fr-FR')} €
                    </Typography>
                  </Box>
                  <Divider sx={{ my: 1 }} />
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Typography variant="h6" sx={{ fontWeight: 600 }}>
                      Total :
                    </Typography>
                    <Typography variant="h6" sx={{ fontWeight: 600, color: '#1976d2' }}>
                      {totals.total.toLocaleString('fr-FR')} €
                    </Typography>
                  </Box>
                </Box>
              </Box>
            </Grid>
          </Grid>
        </DialogContent>
        
        <DialogActions sx={{ p: 3 }}>
          <Button onClick={onClose} variant="outlined">
            Annuler
          </Button>
          <Button 
            onClick={onSubmit} 
            variant="contained"
            disabled={quoteItems.length === 0}
            sx={{ 
              backgroundColor: '#1976d2',
              '&:hover': { backgroundColor: '#1565c0' }
            }}
          >
            Créer le devis
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog de création de réparation */}
      <RepairForm
        open={repairFormOpen}
        onClose={() => setRepairFormOpen(false)}
        onSubmit={handleCreateRepair}
        clients={clients}
        devices={devices}
        selectedClientId={selectedClientId}
      />
    </>
  );
};

export default QuoteForm;
