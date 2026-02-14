// @ts-nocheck
import React, { useState, useEffect } from 'react';
import { useAppStore } from '../../store';
import { DeviceCategory, DeviceBrand, DeviceModel } from '../../types/deviceManagement';
import { deviceCategoryService } from '../../services/deviceCategoryService';
import { brandService, BrandWithCategories, CreateBrandData, UpdateBrandData } from '../../services/brandService';
import { deviceModelService } from '../../services/deviceModelService';
import { deviceModelServiceService } from '../../services/deviceModelServiceService';
import { DeviceModelServiceDetailed, CreateDeviceModelServiceData } from '../../types/deviceModelService';

// CSV templates
const brandsCsvContent = `name,description,categoryIds
Apple,Fabricant américain de produits électroniques,Smartphone;Ordinateur portable;Ordinateur;Tablette
Samsung,Conglomérat sud-coréen spécialisé dans l'électronique,Smartphone;Tablette
Huawei,Entreprise chinoise de télécommunications,Smartphone;Tablette
Xiaomi,Entreprise chinoise de technologie,Smartphone;Tablette
OnePlus,Fabricant chinois de smartphones haut de gamme,Smartphone
Google,Entreprise américaine spécialisée dans les services Internet,Smartphone;Tablette;Ordinateur portable
Sony,Conglomérat japonais spécialisé dans l'électronique,Smartphone
LG,Entreprise sud-coréenne d'électronique grand public,Smartphone
Motorola,Fabricant américain de télécommunications,Smartphone
Nokia,Entreprise finlandaise de télécommunications,Smartphone
Honor,Marque de smartphones Huawei,Smartphone
Realme,Marque de smartphones chinoise,Smartphone
Oppo,Fabricant chinois d'électronique,Smartphone
Vivo,Fabricant chinois de smartphones,Smartphone
Asus,Fabricant taïwanais d'ordinateurs,Ordinateur portable;Ordinateur
Lenovo,Entreprise chinoise multinationale de technologie,Ordinateur portable;Ordinateur
Microsoft,Entreprise américaine multinationale de technologie,Ordinateur portable;Tablette
Amazon,Entreprise américaine de commerce électronique,Tablette
Dell,Entreprise américaine de technologie informatique,Ordinateur portable;Ordinateur
HP,Entreprise américaine multinationale de technologie informatique,Ordinateur portable;Ordinateur
Acer,Fabricant taïwanais d'ordinateurs,Ordinateur portable;Ordinateur
MSI,Fabricant taïwanais d'ordinateurs,Ordinateur portable;Ordinateur
Razer,Entreprise américaine de matériel informatique gaming,Ordinateur portable
Alienware,Marque d'ordinateurs gaming Dell,Ordinateur portable;Ordinateur
Gigabyte,Fabricant taïwanais de cartes mères,Ordinateur portable;Ordinateur
Framework,Fabricant américain d'ordinateurs portables modulaires,Ordinateur portable
HTC,Fabricant taïwanais de smartphones,Smartphone
BlackBerry,Entreprise canadienne de technologies mobiles,Smartphone
TCL,Entreprise chinoise multinationale de technologie,Smartphone
Nothing,Marque de smartphones britannique,Smartphone
Fairphone,Marque de smartphones néerlandaise éthique,Smartphone
Caterpillar,Entreprise américaine de matériel lourd,Smartphone
Crosscall,Marque française de smartphones robustes,Smartphone
Wiko,Marque française de smartphones,Smartphone
Archos,Marque française d'électronique grand public,Smartphone;Tablette
Bull,Entreprise française d'informatique,Ordinateur portable;Ordinateur
Thomson,Marque française d'électronique grand public,Smartphone;Tablette`;

const categoriesCsvContent = `name,description,icon
Smartphone,Téléphones mobiles intelligents,phone
Tablette,Appareils tactiles portables,tablet
Ordinateur portable,Ordinateurs portables,laptop
Ordinateur,Ordinateurs de bureau,computer
Autre,Autres appareils électroniques,device-hub`;

const modelsCsvContent = `name,description,brandName,categoryName
iPhone 15 Pro Max,Smartphone haut de gamme Apple 2023,Apple,Smartphone
iPhone 15 Pro,Smartphone professionnel Apple 2023,Apple,Smartphone
iPhone 15,Smartphone standard Apple 2023,Apple,Smartphone
iPhone 14 Pro Max,Smartphone haut de gamme Apple 2022,Apple,Smartphone
iPhone 14 Pro,Smartphone professionnel Apple 2022,Apple,Smartphone
iPhone 14,Smartphone standard Apple 2022,Apple,Smartphone
iPhone 13 Pro Max,Smartphone haut de gamme Apple 2021,Apple,Smartphone
iPhone 13,Smartphone standard Apple 2021,Apple,Smartphone
iPhone 12 Pro,Smartphone professionnel Apple 2020,Apple,Smartphone
iPhone 12,Smartphone standard Apple 2020,Apple,Smartphone
iPhone 11,Smartphone Apple 2019,Apple,Smartphone
iPhone SE 2022,Smartphone compact Apple 2022,Apple,Smartphone
Galaxy S24 Ultra,Smartphone haut de gamme Samsung 2024,Samsung,Smartphone
Galaxy S24 Plus,Smartphone grand format Samsung 2024,Samsung,Smartphone
Galaxy S24,Smartphone standard Samsung 2024,Samsung,Smartphone
Galaxy S23 Ultra,Smartphone haut de gamme Samsung 2023,Samsung,Smartphone
Galaxy S23,Smartphone standard Samsung 2023,Samsung,Smartphone
Galaxy S22 Ultra,Smartphone haut de gamme Samsung 2022,Samsung,Smartphone
Galaxy Z Fold 5,Smartphone pliable Samsung 2023,Samsung,Smartphone
Galaxy Z Flip 5,Smartphone pliable compact Samsung 2023,Samsung,Smartphone
Galaxy A54,Smartphone milieu de gamme Samsung,Samsung,Smartphone
Galaxy A34,Smartphone entrée de gamme Samsung,Samsung,Smartphone
P60 Pro,Smartphone haut de gamme Huawei,Huawei,Smartphone
Mate 60 Pro,Smartphone professionnel Huawei,Huawei,Smartphone
Xiaomi 14 Pro,Smartphone haut de gamme Xiaomi,Xiaomi,Smartphone
Xiaomi 14,Smartphone standard Xiaomi,Xiaomi,Smartphone
Redmi Note 13 Pro,Smartphone milieu de gamme Xiaomi,Xiaomi,Smartphone
OnePlus 12 Pro,Smartphone haut de gamme OnePlus,OnePlus,Smartphone
OnePlus 11,Smartphone standard OnePlus,OnePlus,Smartphone
Pixel 8 Pro,Smartphone Google haut de gamme,Google,Smartphone
Pixel 8,Smartphone Google standard,Google,Smartphone
Pixel 7a,Smartphone Google abordable,Google,Smartphone
Xperia 1 V,Smartphone professionnel Sony,Sony,Smartphone
Xperia 5 V,Smartphone compact Sony,Sony,Smartphone
MacBook Pro 16,Ordinateur portable professionnel 16 pouces,Apple,Ordinateur portable
MacBook Pro 14,Ordinateur portable professionnel 14 pouces,Apple,Ordinateur portable
MacBook Air M2,Ordinateur portable ultraportable M2,Apple,Ordinateur portable
MacBook Air M1,Ordinateur portable ultraportable M1,Apple,Ordinateur portable
Dell XPS 15,Ordinateur portable premium 15 pouces,Dell,Ordinateur portable
Dell XPS 13,Ordinateur portable ultraportable 13 pouces,Dell,Ordinateur portable
ThinkPad X1 Carbon,Ordinateur portable professionnel Lenovo,Lenovo,Ordinateur portable
ThinkPad T14,Ordinateur portable professionnel 14 pouces,Lenovo,Ordinateur portable
HP Spectre x360,Ordinateur portable convertible premium,HP,Ordinateur portable
HP EliteBook 840,Ordinateur portable professionnel 14 pouces,HP,Ordinateur portable
Surface Laptop 5,Ordinateur portable Microsoft 2022,Microsoft,Ordinateur portable
Surface Laptop Studio,Ordinateur portable créatif Microsoft,Microsoft,Ordinateur portable
Asus ZenBook 14,Ordinateur portable ultraportable 14 pouces,Asus,Ordinateur portable
Acer Swift 3,Ordinateur portable abordable 14 pouces,Acer,Ordinateur portable
iMac 24,Ordinateur tout-en-un Apple M1,Apple,Ordinateur
Mac Studio,Station de travail compacte Apple,Apple,Ordinateur
Mac Mini M2,Ordinateur de bureau compact M2,Apple,Ordinateur
OptiPlex 7090,Ordinateur de bureau professionnel Dell,Dell,Ordinateur
EliteDesk 800,Ordinateur de bureau professionnel HP,HP,Ordinateur
ThinkCentre M90,Ordinateur de bureau professionnel Lenovo,Lenovo,Ordinateur
iPad Pro 12.9,Tablette professionnelle 12.9 pouces,Apple,Tablette
iPad Pro 11,Tablette professionnelle 11 pouces,Apple,Tablette
iPad Air,Tablette ultraportable Apple,Apple,Tablette
iPad Mini,Tablette compacte Apple,Apple,Tablette
iPad 10,Tablette standard Apple 10ème génération,Apple,Tablette
Galaxy Tab S9 Ultra,Tablette haut de gamme Samsung 14.6 pouces,Samsung,Tablette
Galaxy Tab S9 Plus,Tablette haut de gamme Samsung 12.4 pouces,Samsung,Tablette
Galaxy Tab S9,Tablette haut de gamme Samsung 11 pouces,Samsung,Tablette
Galaxy Tab A9,Tablette entrée de gamme Samsung,Samsung,Tablette
Surface Pro 9,Tablette hybride Microsoft 2022,Microsoft,Tablette
Surface Go 3,Tablette compacte Microsoft,Microsoft,Tablette
MatePad Pro,Tablette professionnelle Huawei,Huawei,Tablette
Xiaomi Pad 6,Tablette Xiaomi 11 pouces,Xiaomi,Tablette`;

import {
  Box, Typography, Card, CardContent, Grid, Button, TextField, Dialog, DialogTitle,
  DialogContent, DialogActions, IconButton, Chip, Avatar, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Alert, FormControl, InputLabel, Select, MenuItem,
  Tooltip, Divider, Switch, FormControlLabel, CircularProgress, Checkbox, alpha, InputAdornment,
} from '@mui/material';
import {
  Add as AddIcon, Edit as EditIcon, Delete as DeleteIcon, Search as SearchIcon,
  Category as CategoryIcon, Grading as BrandingIcon, ModelTraining as ModelIcon,
  Build as BuildIcon, CloudUpload as UploadIcon, CloudDownload as DownloadIcon,
  DeviceHub as DeviceHubIcon,
} from '@mui/icons-material';
import CategoryIconDisplay from '../../components/CategoryIconDisplay';
import CategoryIconGrid from '../../components/CategoryIconGrid';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

/* ─── Design tokens ─── */
const CARD_BASE = {
  borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
  transition: 'all 0.3s cubic-bezier(0.4,0,0.2,1)',
  '&:hover': { boxShadow: '0 8px 32px rgba(0,0,0,0.10)', transform: 'translateY(-2px)' },
} as const;

const TABLE_HEAD_SX = {
  '& th': {
    borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600,
    fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
} as const;

const BTN_DARK = {
  borderRadius: '10px', textTransform: 'none', fontWeight: 600,
  bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
} as const;

const INPUT_SX = { '& .MuiOutlinedInput-root': { borderRadius: '10px' } } as const;

/* ─── KPI Mini ─── */
function KpiMini({ icon, iconColor, label, value }: {
  icon: React.ReactNode; iconColor: string; label: string; value: string | number;
}) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '16px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{
            width: 40, height: 40, borderRadius: '12px', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
            color: '#fff', flexShrink: 0, boxShadow: `0 4px 14px ${alpha(iconColor, 0.3)}`,
          }}>{icon}</Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: '1.1rem' }}>{value}</Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, fontSize: '0.7rem' }}>{label}</Typography>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

/* ─── Tab options ─── */
const TAB_OPTIONS = [
  { value: 0, label: 'Marques' },
  { value: 1, label: 'Catégories' },
  { value: 2, label: 'Modèles' },
  { value: 3, label: 'Services par modèle' },
];

/* ─── Types ─── */
interface NewBrandForm { name: string; description: string; categoryIds: string[]; isActive: boolean; }
interface NewCategoryForm { name: string; description: string; icon: string; isActive: boolean; }
interface NewModelForm { name: string; description: string; brandId: string; categoryId: string; isActive: boolean; }

const DeviceManagement: React.FC = () => {
  const { workshopSettings } = useWorkshopSettings();
  const currency = workshopSettings?.currency || 'EUR';

  const [allCategories, setAllCategories] = useState<DeviceCategory[]>([]);
  const [allBrands, setAllBrands] = useState<BrandWithCategories[]>([]);
  const [allModels, setAllModels] = useState<DeviceModel[]>([]);
  const [allDeviceModelServices, setAllDeviceModelServices] = useState<DeviceModelServiceDetailed[]>([]);

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategoryForBrands, setSelectedCategoryForBrands] = useState<string>('');
  const [selectedCategoryForModels, setSelectedCategoryForModels] = useState<string>('');
  const [selectedBrandForModels, setSelectedBrandForModels] = useState<string>('');
  const [selectedCategoryForServices, setSelectedCategoryForServices] = useState<string>('');
  const [selectedBrandForServices, setSelectedBrandForServices] = useState<string>('');

  const [activeTab, setActiveTab] = useState(0);
  const [brandDialogOpen, setBrandDialogOpen] = useState(false);
  const [categoryDialogOpen, setCategoryDialogOpen] = useState(false);
  const [modelDialogOpen, setModelDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleteItem, setDeleteItem] = useState<{ type: 'brand' | 'category' | 'model' | 'service'; item: any } | null>(null);
  const [serviceAssociationDialogOpen, setServiceAssociationDialogOpen] = useState(false);
  const [selectedModelForService, setSelectedModelForService] = useState<DeviceModel | null>(null);

  const [selectedBrand, setSelectedBrand] = useState<BrandWithCategories | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<DeviceCategory | null>(null);
  const [selectedModel, setSelectedModel] = useState<DeviceModel | null>(null);
  const [newBrand, setNewBrand] = useState<NewBrandForm>({ name: '', description: '', categoryIds: [], isActive: true });
  const [newCategory, setNewCategory] = useState<NewCategoryForm>({ name: '', description: '', icon: 'category', isActive: true });
  const [newModel, setNewModel] = useState<NewModelForm>({ name: '', description: '', brandId: '', categoryId: '', isActive: true });
  const [newServiceAssociation, setNewServiceAssociation] = useState<CreateDeviceModelServiceData>({ deviceModelId: '', serviceId: '', customPrice: undefined, customDuration: undefined });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [importDialogOpen, setImportDialogOpen] = useState(false);
  const [importType, setImportType] = useState<'brands' | 'models' | 'categories'>('brands');
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  const [bulkDeleteDialogOpen, setBulkDeleteDialogOpen] = useState(false);
  const [bulkDeleteType, setBulkDeleteType] = useState<'brands' | 'models' | 'categories'>('brands');

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    setLoading(true); setError(null);
    try {
      const categoriesResult = await deviceCategoryService.getAll();
      setAllCategories(categoriesResult.success && categoriesResult.data ? categoriesResult.data : []);
      const brands = await brandService.getAll();
      setAllBrands(brands);
      const modelsResult = await deviceModelService.getAll();
      setAllModels(modelsResult.success && modelsResult.data ? modelsResult.data : []);
      const servicesResult = await deviceModelServiceService.getAll();
      setAllDeviceModelServices(servicesResult.success && servicesResult.data ? servicesResult.data : []);
    } catch {
      setError('Erreur lors du chargement des données');
      setAllCategories([]); setAllBrands([]);
    } finally { setLoading(false); }
  };

  // ─── Category CRUD ───
  const handleCreateCategory = async () => {
    try {
      setLoading(true);
      const result = await deviceCategoryService.create({ name: newCategory.name, description: newCategory.description, icon: newCategory.icon });
      if (result.success) { await loadData(); setCategoryDialogOpen(false); resetCategoryForm(); }
      else setError(result.error || 'Erreur lors de la création');
    } catch { setError('Erreur lors de la création de la catégorie'); } finally { setLoading(false); }
  };
  const handleUpdateCategory = async () => {
    if (!selectedCategory) return;
    try {
      setLoading(true);
      const result = await deviceCategoryService.update(selectedCategory.id, { name: newCategory.name, description: newCategory.description, icon: newCategory.icon });
      if (result.success) { await loadData(); setCategoryDialogOpen(false); resetCategoryForm(); }
      else setError(result.error || 'Erreur lors de la mise à jour');
    } catch { setError('Erreur lors de la mise à jour'); } finally { setLoading(false); }
  };
  const handleDeleteCategory = async (category: DeviceCategory) => {
    try {
      setLoading(true);
      const result = await deviceCategoryService.delete(category.id);
      if (result.success) await loadData(); else setError(result.error || 'Erreur lors de la suppression');
    } catch { setError('Erreur lors de la suppression'); } finally { setLoading(false); }
  };
  const openCategoryEditDialog = (category: DeviceCategory) => {
    setSelectedCategory(category);
    setNewCategory({ name: category.name, description: category.description, icon: category.icon, isActive: category.isActive });
    setCategoryDialogOpen(true);
  };
  const resetCategoryForm = () => { setSelectedCategory(null); setNewCategory({ name: '', description: '', icon: 'category', isActive: true }); };

  // ─── Model CRUD ───
  const handleCreateModel = async () => {
    try {
      setLoading(true);
      const result = await deviceModelService.create({ name: newModel.name, description: newModel.description, brandId: newModel.brandId, categoryId: newModel.categoryId });
      if (result.success) { await loadData(); setModelDialogOpen(false); resetModelForm(); }
      else setError(result.error || 'Erreur lors de la création');
    } catch { setError('Erreur lors de la création du modèle'); } finally { setLoading(false); }
  };
  const handleUpdateModel = async () => {
    if (!selectedModel) return;
    try {
      setLoading(true);
      const result = await deviceModelService.update(selectedModel.id, { name: newModel.name, description: newModel.description, brandId: newModel.brandId, categoryId: newModel.categoryId });
      if (result.success) { await loadData(); setModelDialogOpen(false); resetModelForm(); }
      else setError(result.error || 'Erreur lors de la mise à jour');
    } catch { setError('Erreur lors de la mise à jour'); } finally { setLoading(false); }
  };
  const handleDeleteModel = async (model: DeviceModel) => {
    try {
      setLoading(true);
      const result = await deviceModelService.delete(model.id);
      if (result.success) await loadData(); else setError(result.error || 'Erreur lors de la suppression');
    } catch { setError('Erreur lors de la suppression'); } finally { setLoading(false); }
  };
  const openModelEditDialog = (model: DeviceModel) => {
    setSelectedModel(model);
    setNewModel({ name: model.name, description: model.description || '', brandId: model.brandId, categoryId: model.categoryId, isActive: model.isActive });
    setModelDialogOpen(true);
  };
  const resetModelForm = () => { setSelectedModel(null); setNewModel({ name: '', description: '', brandId: '', categoryId: '', isActive: true }); };

  // ─── Brand CRUD ───
  const handleCreateBrand = async () => {
    try {
      setLoading(true);
      await brandService.create({ name: newBrand.name, description: newBrand.description, categoryIds: newBrand.categoryIds });
      await loadData(); setBrandDialogOpen(false); resetBrandForm();
    } catch { setError('Erreur lors de la création de la marque'); } finally { setLoading(false); }
  };
  const handleUpdateBrand = async () => {
    if (!selectedBrand) return;
    try {
      setLoading(true);
      await brandService.update(selectedBrand.id, { name: newBrand.name, description: newBrand.description, categoryIds: newBrand.categoryIds });
      await loadData(); setBrandDialogOpen(false); resetBrandForm(); setSelectedBrand(null);
    } catch { setError('Erreur lors de la mise à jour'); } finally { setLoading(false); }
  };
  const handleDeleteBrand = async (brand: BrandWithCategories) => {
    try { setLoading(true); await brandService.delete(brand.id); await loadData(); }
    catch { setError('Erreur lors de la suppression'); } finally { setLoading(false); }
  };
  const resetBrandForm = () => { setNewBrand({ name: '', description: '', categoryIds: [], isActive: true }); setSelectedBrand(null); };
  const openBrandEditDialog = (brand: BrandWithCategories) => {
    setSelectedBrand(brand);
    setNewBrand({ name: brand.name, description: brand.description, categoryIds: brand.categories.map(c => c.id), isActive: brand.isActive });
    setBrandDialogOpen(true);
  };

  // ─── Delete confirm ───
  const openDeleteDialog = (item: any, type: 'brand' | 'category' | 'model') => { setDeleteItem({ type, item }); setDeleteDialogOpen(true); };
  const confirmDelete = async () => {
    if (!deleteItem) return;
    if (deleteItem.type === 'brand') await handleDeleteBrand(deleteItem.item);
    else if (deleteItem.type === 'category') await handleDeleteCategory(deleteItem.item);
    else if (deleteItem.type === 'model') await handleDeleteModel(deleteItem.item);
    setDeleteDialogOpen(false); setDeleteItem(null);
  };

  // ─── Service associations ───
  const handleCreateServiceAssociation = async () => {
    try {
      setLoading(true);
      const result = await deviceModelServiceService.create(newServiceAssociation);
      if (result.success) { await loadData(); setServiceAssociationDialogOpen(false); resetServiceAssociationForm(); }
      else throw new Error(result.error || 'Erreur');
    } catch (e: any) { setError(e.message || 'Erreur'); } finally { setLoading(false); }
  };
  const handleDeleteServiceAssociation = async (a: DeviceModelServiceDetailed) => {
    try { setLoading(true); await deviceModelServiceService.delete(a.id); await loadData(); }
    catch { setError("Erreur lors de la suppression"); } finally { setLoading(false); }
  };
  const resetServiceAssociationForm = () => { setNewServiceAssociation({ deviceModelId: '', serviceId: '', customPrice: undefined, customDuration: undefined }); setSelectedModelForService(null); };
  const openServiceAssociationDialog = (model: DeviceModel) => {
    setSelectedModelForService(model);
    setNewServiceAssociation({ deviceModelId: model.id, serviceId: '', customPrice: undefined, customDuration: undefined });
    setServiceAssociationDialogOpen(true);
  };

  // ─── CSV import/export ───
  const handleDownloadTemplate = (type: 'brands' | 'models' | 'categories') => {
    const map = { categories: { content: categoriesCsvContent, name: 'categories_import.csv' }, brands: { content: brandsCsvContent, name: 'brands_import.csv' }, models: { content: modelsCsvContent, name: 'models_import.csv' } };
    const { content, name } = map[type];
    const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a'); link.href = url; link.download = name; link.style.display = 'none';
    document.body.appendChild(link); link.click();
    setTimeout(() => { if (document.body.contains(link)) document.body.removeChild(link); URL.revokeObjectURL(url); }, 100);
  };

  const handleImportCSV = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]; if (!file) return;
    setLoading(true); setError(null); setSuccess(null);
    try {
      const text = await file.text();
      const lines = text.split('\n').filter(l => l.trim());
      const parseCSVLine = (line: string): string[] => {
        const result: string[] = []; let current = ''; let inQ = false;
        for (let i = 0; i < line.length; i++) {
          const c = line[i];
          if (c === '"') inQ = !inQ; else if (c === ',' && !inQ) { result.push(current.trim()); current = ''; } else current += c;
        }
        result.push(current.trim()); return result;
      };
      const headers = parseCSVLine(lines[0]);
      let ok = 0, fail = 0;

      if (importType === 'categories') {
        for (let i = 1; i < lines.length; i++) {
          const v = parseCSVLine(lines[i]); const cat: any = {}; headers.forEach((h, idx) => { cat[h] = v[idx] || ''; });
          if (!cat.name?.trim()) { fail++; continue; }
          try { const r = await deviceCategoryService.create({ name: cat.name, description: cat.description || `Catégorie ${cat.name}`, icon: cat.icon || cat.name.toLowerCase().replace(/\s+/g, '-') }); r.success ? ok++ : fail++; } catch { fail++; }
        }
      } else if (importType === 'brands') {
        for (let i = 1; i < lines.length; i++) {
          const v = parseCSVLine(lines[i]); const b: any = {}; headers.forEach((h, idx) => { b[h] = v[idx] || ''; });
          if (!b.name?.trim()) { fail++; continue; }
          const catIds: string[] = [];
          if (b.categoryIds) { for (const cn of b.categoryIds.split(';')) { const c = allCategories.find(x => x.name.toLowerCase() === cn.toLowerCase()); if (c) catIds.push(c.id); } }
          try { await brandService.create({ name: b.name, description: b.description || '', categoryIds: catIds }); ok++; } catch { fail++; }
        }
      } else {
        for (let i = 1; i < lines.length; i++) {
          const v = parseCSVLine(lines[i]); const m: any = {}; headers.forEach((h, idx) => { m[h] = v[idx] || ''; });
          if (!m.name?.trim()) { fail++; continue; }
          const brand = allBrands.find(b => b.name.toLowerCase() === m.brandName?.toLowerCase()); if (!brand) { fail++; continue; }
          const cat = allCategories.find(c => c.name.toLowerCase() === m.categoryName?.toLowerCase()); if (!cat) { fail++; continue; }
          try { const r = await deviceModelService.create({ name: m.name, description: m.description || '', brandId: brand.id, categoryId: cat.id }); r.success ? ok++ : fail++; } catch { fail++; }
        }
      }
      setSuccess(`Importation terminée : ${ok} importés${fail > 0 ? `, ${fail} erreurs` : ''}`);
      await loadData(); setImportDialogOpen(false);
    } catch { setError("Erreur lors de l'importation"); } finally { setLoading(false); }
  };

  // ─── Bulk delete ───
  const handleSelectAll = (items: any[]) => { setSelectedItems(selectedItems.length === items.length ? [] : items.map(i => i.id)); };
  const handleSelectItem = (id: string) => { setSelectedItems(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]); };
  const openBulkDeleteDialog = (type: 'brands' | 'models' | 'categories') => {
    if (selectedItems.length === 0) { setError('Sélectionnez au moins un élément'); return; }
    setBulkDeleteType(type); setBulkDeleteDialogOpen(true);
  };
  const handleBulkDelete = async () => {
    if (selectedItems.length === 0) return;
    setLoading(true); setError(null); setSuccess(null);
    let ok = 0, fail = 0;
    try {
      for (const id of selectedItems) {
        try {
          if (bulkDeleteType === 'brands') await brandService.delete(id);
          else if (bulkDeleteType === 'models') { const r = await deviceModelService.delete(id); if (!r.success) throw new Error(); }
          else { const r = await deviceCategoryService.delete(id); if (!r.success) throw new Error(); }
          ok++;
        } catch { fail++; }
      }
      setSuccess(`Suppression terminée : ${ok} supprimés${fail > 0 ? `, ${fail} erreurs` : ''}`);
      setSelectedItems([]); setBulkDeleteDialogOpen(false); await loadData();
    } catch { setError('Erreur lors de la suppression en lot'); } finally { setLoading(false); }
  };

  // ─── Filters ───
  const filteredBrands = (allBrands || []).filter(b => {
    const s = (b.name || '').toLowerCase().includes(searchTerm.toLowerCase()) || (b.description || '').toLowerCase().includes(searchTerm.toLowerCase());
    const c = !selectedCategoryForBrands || b.categories.some(cat => cat.id === selectedCategoryForBrands);
    return s && c;
  });
  const filteredModels = (allModels || []).filter(m => {
    const s = (m.name || '').toLowerCase().includes(searchTerm.toLowerCase());
    const b = !selectedBrandForModels || m.brandId === selectedBrandForModels;
    const c = !selectedCategoryForModels || m.categoryId === selectedCategoryForModels;
    return s && b && c;
  });

  const getCategoryIcon = (name: string, icon?: string) => <CategoryIconDisplay iconType={icon || (name || '').toLowerCase().replace(/\s+/g, '-')} size={20} />;

  if (loading && (allBrands || []).length === 0) {
    return <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '50vh' }}><CircularProgress sx={{ color: '#111827' }} /></Box>;
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700 }}>Gestion des appareils</Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>Marques, catégories, modèles et services</Typography>
        </Box>
      </Box>

      {/* KPI Cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}><KpiMini icon={<BrandingIcon sx={{ fontSize: 20 }} />} iconColor="#6366f1" label="Marques" value={(allBrands || []).length} /></Grid>
        <Grid item xs={6} md={3}><KpiMini icon={<CategoryIcon sx={{ fontSize: 20 }} />} iconColor="#f59e0b" label="Catégories" value={(allCategories || []).length} /></Grid>
        <Grid item xs={6} md={3}><KpiMini icon={<ModelIcon sx={{ fontSize: 20 }} />} iconColor="#22c55e" label="Modèles" value={(allModels || []).length} /></Grid>
        <Grid item xs={6} md={3}><KpiMini icon={<BuildIcon sx={{ fontSize: 20 }} />} iconColor="#8b5cf6" label="Services liés" value={allDeviceModelServices.length} /></Grid>
      </Grid>

      {error && <Alert severity="error" sx={{ mb: 2, borderRadius: '12px' }} onClose={() => setError(null)}>{error}</Alert>}
      {success && <Alert severity="success" sx={{ mb: 2, borderRadius: '12px' }} onClose={() => setSuccess(null)}>{success}</Alert>}

      {/* Tab chips */}
      <Box sx={{ display: 'flex', gap: 0.75, mb: 3, flexWrap: 'wrap' }}>
        {TAB_OPTIONS.map(opt => (
          <Chip key={opt.value} label={opt.label} onClick={() => { setActiveTab(opt.value); setSelectedItems([]); }}
            sx={{
              fontWeight: 600, borderRadius: '10px', fontSize: '0.8rem', px: 1, py: 2.2,
              ...(activeTab === opt.value
                ? { bgcolor: '#111827', color: '#fff', '&:hover': { bgcolor: '#1f2937' } }
                : { bgcolor: 'grey.100', color: 'text.secondary', '&:hover': { bgcolor: 'grey.200' } }),
            }} />
        ))}
      </Box>

      {/* ═══ TAB 0 : Brands ═══ */}
      {activeTab === 0 && (
        <Card sx={CARD_BASE}>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2, flexWrap: 'wrap', gap: 1 }}>
              <Typography variant="h6" sx={{ fontWeight: 600 }}>Marques ({filteredBrands.length})</Typography>
              <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                <Button size="small" variant="outlined" startIcon={<DownloadIcon />} onClick={() => handleDownloadTemplate('brands')}
                  sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'grey.300', color: 'text.secondary' }}>Modèle CSV</Button>
                <Button size="small" variant="outlined" startIcon={<UploadIcon />} onClick={() => { setImportType('brands'); setImportDialogOpen(true); }}
                  sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'grey.300', color: 'text.secondary' }}>Importer</Button>
                {selectedItems.length > 0 && (
                  <Button size="small" variant="outlined" startIcon={<DeleteIcon />} onClick={() => openBulkDeleteDialog('brands')}
                    sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: '#ef4444', color: '#ef4444' }}>Supprimer ({selectedItems.length})</Button>
                )}
                <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={() => { resetBrandForm(); setBrandDialogOpen(true); }} sx={BTN_DARK}>Ajouter</Button>
              </Box>
            </Box>

            <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap', alignItems: 'center' }}>
              <TextField placeholder="Rechercher..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} size="small"
                sx={{ minWidth: 200, ...INPUT_SX }}
                InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon sx={{ color: 'text.disabled', fontSize: 20 }} /></InputAdornment> }} />
              <Box sx={{ display: 'flex', gap: 0.75, flexWrap: 'wrap' }}>
                <Chip label="Toutes" size="small" onClick={() => setSelectedCategoryForBrands('')}
                  sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem', ...(selectedCategoryForBrands === '' ? { bgcolor: '#6366f1', color: '#fff' } : { bgcolor: 'grey.100', color: 'text.secondary' }) }} />
                {(allCategories || []).map(cat => (
                  <Chip key={cat.id} label={cat.name} size="small" onClick={() => setSelectedCategoryForBrands(selectedCategoryForBrands === cat.id ? '' : cat.id)}
                    sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.75rem', ...(selectedCategoryForBrands === cat.id ? { bgcolor: '#6366f1', color: '#fff' } : { bgcolor: 'grey.100', color: 'text.secondary' }) }} />
                ))}
              </Box>
            </Box>

            <TableContainer>
              <Table>
                <TableHead><TableRow sx={TABLE_HEAD_SX}>
                  <TableCell padding="checkbox"><Checkbox indeterminate={selectedItems.length > 0 && selectedItems.length < filteredBrands.length} checked={filteredBrands.length > 0 && selectedItems.length === filteredBrands.length} onChange={() => handleSelectAll(filteredBrands)} /></TableCell>
                  <TableCell>Nom</TableCell><TableCell>Description</TableCell><TableCell>Catégories</TableCell><TableCell>Statut</TableCell><TableCell align="center">Actions</TableCell>
                </TableRow></TableHead>
                <TableBody>
                  {filteredBrands.map(brand => (
                    <TableRow key={brand.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                      <TableCell padding="checkbox"><Checkbox checked={selectedItems.includes(brand.id)} onChange={() => handleSelectItem(brand.id)} /></TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                          <Avatar sx={{ width: 32, height: 32, fontSize: '0.75rem', fontWeight: 700, background: 'linear-gradient(135deg, #6366f1, #818cf8)', color: '#fff' }}>{brand.name.charAt(0)}</Avatar>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>{brand.name}</Typography>
                        </Box>
                      </TableCell>
                      <TableCell><Typography variant="body2" color="text.secondary">{brand.description || '—'}</Typography></TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                          {brand.categories.length > 0 ? brand.categories.map(cat => (
                            <Chip key={cat.id} label={cat.name} size="small" sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.7rem', bgcolor: alpha('#6366f1', 0.08), color: '#6366f1' }} />
                          )) : <Typography variant="caption" color="text.disabled">—</Typography>}
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Chip label={brand.isActive ? 'Actif' : 'Inactif'} size="small" sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem', bgcolor: alpha(brand.isActive ? '#22c55e' : '#9ca3af', 0.1), color: brand.isActive ? '#22c55e' : '#9ca3af' }} />
                      </TableCell>
                      <TableCell align="center">
                        <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                          <Tooltip title="Modifier"><IconButton size="small" onClick={() => openBrandEditDialog(brand)} sx={{ color: '#6366f1', bgcolor: alpha('#6366f1', 0.08), '&:hover': { bgcolor: alpha('#6366f1', 0.15) } }}><EditIcon sx={{ fontSize: 18 }} /></IconButton></Tooltip>
                          <Tooltip title="Supprimer"><IconButton size="small" onClick={() => openDeleteDialog(brand, 'brand')} sx={{ color: '#ef4444', bgcolor: alpha('#ef4444', 0.08), '&:hover': { bgcolor: alpha('#ef4444', 0.15) } }}><DeleteIcon sx={{ fontSize: 18 }} /></IconButton></Tooltip>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
            {filteredBrands.length === 0 && <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 6 }}><BrandingIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} /><Typography variant="body2" color="text.disabled">Aucune marque trouvée</Typography></Box>}
          </CardContent>
        </Card>
      )}

      {/* ═══ TAB 1 : Categories ═══ */}
      {activeTab === 1 && (
        <Card sx={CARD_BASE}>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2, flexWrap: 'wrap', gap: 1 }}>
              <Typography variant="h6" sx={{ fontWeight: 600 }}>Catégories ({(allCategories || []).length})</Typography>
              <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                <Button size="small" variant="outlined" startIcon={<DownloadIcon />} onClick={() => handleDownloadTemplate('categories')} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'grey.300', color: 'text.secondary' }}>Modèle CSV</Button>
                <Button size="small" variant="outlined" startIcon={<UploadIcon />} onClick={() => { setImportType('categories'); setImportDialogOpen(true); }} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'grey.300', color: 'text.secondary' }}>Importer</Button>
                {selectedItems.length > 0 && <Button size="small" variant="outlined" startIcon={<DeleteIcon />} onClick={() => openBulkDeleteDialog('categories')} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: '#ef4444', color: '#ef4444' }}>Supprimer ({selectedItems.length})</Button>}
                <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={() => { resetCategoryForm(); setCategoryDialogOpen(true); }} sx={BTN_DARK}>Ajouter</Button>
              </Box>
            </Box>
            <TableContainer>
              <Table>
                <TableHead><TableRow sx={TABLE_HEAD_SX}>
                  <TableCell padding="checkbox"><Checkbox indeterminate={selectedItems.length > 0 && selectedItems.length < (allCategories || []).length} checked={(allCategories || []).length > 0 && selectedItems.length === (allCategories || []).length} onChange={() => handleSelectAll(allCategories || [])} /></TableCell>
                  <TableCell>Nom</TableCell><TableCell>Description</TableCell><TableCell>Icône</TableCell><TableCell>Statut</TableCell><TableCell align="center">Actions</TableCell>
                </TableRow></TableHead>
                <TableBody>
                  {(allCategories || []).map(cat => (
                    <TableRow key={cat.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                      <TableCell padding="checkbox"><Checkbox checked={selectedItems.includes(cat.id)} onChange={() => handleSelectItem(cat.id)} /></TableCell>
                      <TableCell><Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>{getCategoryIcon(cat.name, cat.icon)}<Typography variant="body2" sx={{ fontWeight: 600 }}>{cat.name}</Typography></Box></TableCell>
                      <TableCell><Typography variant="body2" color="text.secondary">{cat.description}</Typography></TableCell>
                      <TableCell>{getCategoryIcon(cat.name, cat.icon)}</TableCell>
                      <TableCell><Chip label={cat.isActive ? 'Actif' : 'Inactif'} size="small" sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem', bgcolor: alpha(cat.isActive ? '#22c55e' : '#9ca3af', 0.1), color: cat.isActive ? '#22c55e' : '#9ca3af' }} /></TableCell>
                      <TableCell align="center">
                        <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                          <Tooltip title="Modifier"><IconButton size="small" onClick={() => openCategoryEditDialog(cat)} sx={{ color: '#6366f1', bgcolor: alpha('#6366f1', 0.08), '&:hover': { bgcolor: alpha('#6366f1', 0.15) } }}><EditIcon sx={{ fontSize: 18 }} /></IconButton></Tooltip>
                          <Tooltip title="Supprimer"><IconButton size="small" onClick={() => openDeleteDialog(cat, 'category')} sx={{ color: '#ef4444', bgcolor: alpha('#ef4444', 0.08), '&:hover': { bgcolor: alpha('#ef4444', 0.15) } }}><DeleteIcon sx={{ fontSize: 18 }} /></IconButton></Tooltip>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
            {(allCategories || []).length === 0 && <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 6 }}><CategoryIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} /><Typography variant="body2" color="text.disabled">Aucune catégorie</Typography></Box>}
          </CardContent>
        </Card>
      )}

      {/* ═══ TAB 2 : Models ═══ */}
      {activeTab === 2 && (
        <Card sx={CARD_BASE}>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2, flexWrap: 'wrap', gap: 1 }}>
              <Typography variant="h6" sx={{ fontWeight: 600 }}>Modèles ({filteredModels.length})</Typography>
              <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                <Button size="small" variant="outlined" startIcon={<DownloadIcon />} onClick={() => handleDownloadTemplate('models')} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'grey.300', color: 'text.secondary' }}>Modèle CSV</Button>
                <Button size="small" variant="outlined" startIcon={<UploadIcon />} onClick={() => { setImportType('models'); setImportDialogOpen(true); }} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'grey.300', color: 'text.secondary' }}>Importer</Button>
                {selectedItems.length > 0 && <Button size="small" variant="outlined" startIcon={<DeleteIcon />} onClick={() => openBulkDeleteDialog('models')} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: '#ef4444', color: '#ef4444' }}>Supprimer ({selectedItems.length})</Button>}
                <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={() => { resetModelForm(); setModelDialogOpen(true); }} sx={BTN_DARK}>Ajouter</Button>
              </Box>
            </Box>

            <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap', alignItems: 'center' }}>
              <TextField placeholder="Rechercher..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} size="small" sx={{ minWidth: 200, ...INPUT_SX }}
                InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon sx={{ color: 'text.disabled', fontSize: 20 }} /></InputAdornment> }} />
              <FormControl size="small" sx={{ minWidth: 160 }}>
                <InputLabel>Marque</InputLabel>
                <Select value={selectedBrandForModels || ''} onChange={e => setSelectedBrandForModels(e.target.value)} label="Marque" sx={{ borderRadius: '10px' }}>
                  <MenuItem value="">Toutes</MenuItem>
                  {(allBrands || []).map(b => <MenuItem key={b.id} value={b.id}>{b.name}</MenuItem>)}
                </Select>
              </FormControl>
              <FormControl size="small" sx={{ minWidth: 160 }}>
                <InputLabel>Catégorie</InputLabel>
                <Select value={selectedCategoryForModels || ''} onChange={e => setSelectedCategoryForModels(e.target.value)} label="Catégorie" sx={{ borderRadius: '10px' }}>
                  <MenuItem value="">Toutes</MenuItem>
                  {(allCategories || []).map(c => <MenuItem key={c.id} value={c.id}>{c.name}</MenuItem>)}
                </Select>
              </FormControl>
            </Box>

            <TableContainer>
              <Table>
                <TableHead><TableRow sx={TABLE_HEAD_SX}>
                  <TableCell padding="checkbox"><Checkbox indeterminate={selectedItems.length > 0 && selectedItems.length < filteredModels.length} checked={filteredModels.length > 0 && selectedItems.length === filteredModels.length} onChange={() => handleSelectAll(filteredModels)} /></TableCell>
                  <TableCell>Nom</TableCell><TableCell>Marque</TableCell><TableCell>Catégorie</TableCell><TableCell>Statut</TableCell><TableCell align="center">Actions</TableCell>
                </TableRow></TableHead>
                <TableBody>
                  {filteredModels.map(model => (
                    <TableRow key={model.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                      <TableCell padding="checkbox"><Checkbox checked={selectedItems.includes(model.id)} onChange={() => handleSelectItem(model.id)} /></TableCell>
                      <TableCell><Typography variant="body2" sx={{ fontWeight: 600 }}>{model.name}</Typography></TableCell>
                      <TableCell><Typography variant="body2" color="text.secondary">{model.brandName}</Typography></TableCell>
                      <TableCell><Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>{getCategoryIcon(model.categoryName)}<Typography variant="body2" color="text.secondary">{model.categoryName}</Typography></Box></TableCell>
                      <TableCell><Chip label={model.isActive ? 'Actif' : 'Inactif'} size="small" sx={{ fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem', bgcolor: alpha(model.isActive ? '#22c55e' : '#9ca3af', 0.1), color: model.isActive ? '#22c55e' : '#9ca3af' }} /></TableCell>
                      <TableCell align="center">
                        <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                          <Tooltip title="Modifier"><IconButton size="small" onClick={() => openModelEditDialog(model)} sx={{ color: '#6366f1', bgcolor: alpha('#6366f1', 0.08), '&:hover': { bgcolor: alpha('#6366f1', 0.15) } }}><EditIcon sx={{ fontSize: 18 }} /></IconButton></Tooltip>
                          <Tooltip title="Associer un service"><IconButton size="small" onClick={() => openServiceAssociationDialog(model)} sx={{ color: '#8b5cf6', bgcolor: alpha('#8b5cf6', 0.08), '&:hover': { bgcolor: alpha('#8b5cf6', 0.15) } }}><BuildIcon sx={{ fontSize: 18 }} /></IconButton></Tooltip>
                          <Tooltip title="Supprimer"><IconButton size="small" onClick={() => openDeleteDialog(model, 'model')} sx={{ color: '#ef4444', bgcolor: alpha('#ef4444', 0.08), '&:hover': { bgcolor: alpha('#ef4444', 0.15) } }}><DeleteIcon sx={{ fontSize: 18 }} /></IconButton></Tooltip>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
            {filteredModels.length === 0 && <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 6 }}><ModelIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} /><Typography variant="body2" color="text.disabled">Aucun modèle trouvé</Typography></Box>}
          </CardContent>
        </Card>
      )}

      {/* ═══ TAB 3 : Services by model ═══ */}
      {activeTab === 3 && (
        <Card sx={CARD_BASE}>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6" sx={{ fontWeight: 600 }}>Services par modèle ({allDeviceModelServices.length})</Typography>
            </Box>
            <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap', alignItems: 'center' }}>
              <TextField placeholder="Rechercher..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} size="small" sx={{ minWidth: 200, ...INPUT_SX }}
                InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon sx={{ color: 'text.disabled', fontSize: 20 }} /></InputAdornment> }} />
              <FormControl size="small" sx={{ minWidth: 160 }}>
                <InputLabel>Catégorie</InputLabel>
                <Select value={selectedCategoryForServices || ''} onChange={e => setSelectedCategoryForServices(e.target.value)} label="Catégorie" sx={{ borderRadius: '10px' }}>
                  <MenuItem value="">Toutes</MenuItem>
                  {(allCategories || []).map(c => <MenuItem key={c.id} value={c.id}>{c.name}</MenuItem>)}
                </Select>
              </FormControl>
              <FormControl size="small" sx={{ minWidth: 160 }}>
                <InputLabel>Marque</InputLabel>
                <Select value={selectedBrandForServices || ''} onChange={e => setSelectedBrandForServices(e.target.value)} label="Marque" sx={{ borderRadius: '10px' }}>
                  <MenuItem value="">Toutes</MenuItem>
                  {(allBrands || []).map(b => <MenuItem key={b.id} value={b.id}>{b.name}</MenuItem>)}
                </Select>
              </FormControl>
            </Box>
            <TableContainer>
              <Table>
                <TableHead><TableRow sx={TABLE_HEAD_SX}>
                  <TableCell>Modèle</TableCell><TableCell>Marque</TableCell><TableCell>Catégorie</TableCell><TableCell>Service</TableCell><TableCell align="right">Prix</TableCell><TableCell>Durée</TableCell><TableCell align="center">Actions</TableCell>
                </TableRow></TableHead>
                <TableBody>
                  {allDeviceModelServices
                    .filter(a => {
                      const s = (a.model_name || '').toLowerCase().includes(searchTerm.toLowerCase()) || (a.service_name || '').toLowerCase().includes(searchTerm.toLowerCase());
                      const c = !selectedCategoryForServices || a.category_id === selectedCategoryForServices;
                      const b = !selectedBrandForServices || a.brand_id === selectedBrandForServices;
                      return s && c && b;
                    })
                    .map(a => (
                      <TableRow key={a.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                        <TableCell><Typography variant="body2" sx={{ fontWeight: 600 }}>{a.model_name || 'N/A'}</Typography></TableCell>
                        <TableCell><Typography variant="body2" color="text.secondary">{a.brand_name || 'N/A'}</Typography></TableCell>
                        <TableCell><Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>{getCategoryIcon(a.category_name || '', a.category_icon)}<Typography variant="body2" color="text.secondary">{a.category_name || 'N/A'}</Typography></Box></TableCell>
                        <TableCell><Typography variant="body2" sx={{ fontWeight: 600 }}>{a.service_name || 'N/A'}</Typography></TableCell>
                        <TableCell align="right">
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, justifyContent: 'flex-end' }}>
                            <Typography variant="body2" sx={{ fontWeight: 700 }}>{formatFromEUR(a.effective_price || 0, currency)}</Typography>
                            {a.customPrice && <Chip label="Perso." size="small" sx={{ fontWeight: 600, borderRadius: '6px', fontSize: '0.65rem', bgcolor: alpha('#8b5cf6', 0.1), color: '#8b5cf6' }} />}
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                            <Typography variant="body2">{a.effective_duration || 0}h</Typography>
                            {a.customDuration && <Chip label="Perso." size="small" sx={{ fontWeight: 600, borderRadius: '6px', fontSize: '0.65rem', bgcolor: alpha('#8b5cf6', 0.1), color: '#8b5cf6' }} />}
                          </Box>
                        </TableCell>
                        <TableCell align="center">
                          <Tooltip title="Supprimer"><IconButton size="small" onClick={() => handleDeleteServiceAssociation(a)} sx={{ color: '#ef4444', bgcolor: alpha('#ef4444', 0.08), '&:hover': { bgcolor: alpha('#ef4444', 0.15) } }}><DeleteIcon sx={{ fontSize: 18 }} /></IconButton></Tooltip>
                        </TableCell>
                      </TableRow>
                    ))}
                </TableBody>
              </Table>
            </TableContainer>
            {allDeviceModelServices.length === 0 && <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 6 }}><BuildIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} /><Typography variant="body2" color="text.disabled">Aucune association</Typography></Box>}
          </CardContent>
        </Card>
      )}

      {/* ═══ DIALOGS ═══ */}

      {/* Brand dialog */}
      <Dialog open={brandDialogOpen} onClose={() => setBrandDialogOpen(false)} maxWidth="md" fullWidth PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>{selectedBrand ? 'Modifier la marque' : 'Nouvelle marque'}</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <TextField label="Nom *" value={newBrand.name} onChange={e => setNewBrand({ ...newBrand, name: e.target.value })} fullWidth sx={INPUT_SX} />
            <TextField label="Description" value={newBrand.description} onChange={e => setNewBrand({ ...newBrand, description: e.target.value })} fullWidth multiline rows={3} sx={INPUT_SX} />
            <FormControl fullWidth>
              <InputLabel>Catégories</InputLabel>
              <Select multiple value={newBrand.categoryIds} onChange={e => setNewBrand({ ...newBrand, categoryIds: e.target.value as string[] })} label="Catégories" sx={{ borderRadius: '10px' }}
                renderValue={selected => <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>{(selected as string[]).map(v => { const c = (allCategories || []).find(x => x.id === v); return <Chip key={v} label={c?.name || v} size="small" sx={{ fontWeight: 600, borderRadius: '8px', bgcolor: alpha('#6366f1', 0.08), color: '#6366f1' }} />; })}</Box>}>
                {(allCategories || []).map(c => <MenuItem key={c.id} value={c.id}><Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>{getCategoryIcon(c.name, c.icon)}{c.name}</Box></MenuItem>)}
              </Select>
            </FormControl>
            <FormControlLabel control={<Switch checked={newBrand.isActive} onChange={e => setNewBrand({ ...newBrand, isActive: e.target.checked })} />} label="Marque active" />
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setBrandDialogOpen(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>Annuler</Button>
          <Button variant="contained" onClick={selectedBrand ? handleUpdateBrand : handleCreateBrand} disabled={!newBrand.name || loading} sx={BTN_DARK}>
            {loading ? <CircularProgress size={20} /> : selectedBrand ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Category dialog */}
      <Dialog open={categoryDialogOpen} onClose={() => setCategoryDialogOpen(false)} maxWidth="sm" fullWidth PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>{selectedCategory ? 'Modifier la catégorie' : 'Nouvelle catégorie'}</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <TextField label="Nom *" value={newCategory.name} onChange={e => setNewCategory({ ...newCategory, name: e.target.value })} fullWidth sx={INPUT_SX} />
            <TextField label="Description" value={newCategory.description} onChange={e => setNewCategory({ ...newCategory, description: e.target.value })} fullWidth multiline rows={3} sx={INPUT_SX} />
            <Box>
              <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>Icône</Typography>
              <Box sx={{ maxHeight: 400, overflowY: 'auto', border: '1px solid rgba(0,0,0,0.08)', borderRadius: '12px', p: 2 }}>
                <CategoryIconGrid selectedIcon={newCategory.icon} onIconSelect={icon => setNewCategory({ ...newCategory, icon })} />
              </Box>
            </Box>
            <FormControlLabel control={<Switch checked={newCategory.isActive} onChange={e => setNewCategory({ ...newCategory, isActive: e.target.checked })} />} label="Catégorie active" />
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setCategoryDialogOpen(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>Annuler</Button>
          <Button variant="contained" onClick={selectedCategory ? handleUpdateCategory : handleCreateCategory} disabled={!newCategory.name || loading} sx={BTN_DARK}>
            {loading ? <CircularProgress size={20} /> : selectedCategory ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Model dialog */}
      <Dialog open={modelDialogOpen} onClose={() => setModelDialogOpen(false)} maxWidth="md" fullWidth PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>{selectedModel ? 'Modifier le modèle' : 'Nouveau modèle'}</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <TextField label="Nom *" value={newModel.name} onChange={e => setNewModel({ ...newModel, name: e.target.value })} fullWidth placeholder="Ex: iPhone 14, Galaxy S23..." sx={INPUT_SX} />
            <TextField label="Description" value={newModel.description} onChange={e => setNewModel({ ...newModel, description: e.target.value })} fullWidth multiline rows={3} sx={INPUT_SX} />
            <FormControl fullWidth required>
              <InputLabel>Marque</InputLabel>
              <Select value={newModel.brandId || ''} onChange={e => setNewModel({ ...newModel, brandId: e.target.value })} label="Marque" sx={{ borderRadius: '10px' }}>
                {(allBrands || []).map(b => <MenuItem key={b.id} value={b.id}>{b.name}</MenuItem>)}
              </Select>
            </FormControl>
            <FormControl fullWidth required>
              <InputLabel>Catégorie</InputLabel>
              <Select value={newModel.categoryId || ''} onChange={e => setNewModel({ ...newModel, categoryId: e.target.value })} label="Catégorie" sx={{ borderRadius: '10px' }}>
                {(allCategories || []).map(c => <MenuItem key={c.id} value={c.id}><Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>{getCategoryIcon(c.name, c.icon)}<span>{c.name}</span></Box></MenuItem>)}
              </Select>
            </FormControl>
            <FormControlLabel control={<Switch checked={newModel.isActive} onChange={e => setNewModel({ ...newModel, isActive: e.target.checked })} />} label="Modèle actif" />
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setModelDialogOpen(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>Annuler</Button>
          <Button variant="contained" onClick={selectedModel ? handleUpdateModel : handleCreateModel} disabled={!newModel.name || !newModel.brandId || !newModel.categoryId || loading} sx={BTN_DARK}>
            {loading ? <CircularProgress size={20} /> : selectedModel ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete confirm dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)} PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>Confirmer la suppression</DialogTitle>
        <DialogContent><Typography>Supprimer {deleteItem?.type === 'brand' ? 'cette marque' : deleteItem?.type === 'category' ? 'cette catégorie' : 'ce modèle'} ? Cette action est irréversible.</Typography></DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setDeleteDialogOpen(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>Annuler</Button>
          <Button variant="contained" onClick={confirmDelete} disabled={loading} sx={{ ...BTN_DARK, bgcolor: '#ef4444', '&:hover': { bgcolor: '#dc2626' }, boxShadow: '0 2px 8px rgba(239,68,68,0.25)' }}>
            {loading ? <CircularProgress size={20} /> : 'Supprimer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Service association dialog */}
      <Dialog open={serviceAssociationDialogOpen} onClose={() => setServiceAssociationDialogOpen(false)} maxWidth="md" fullWidth PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>Associer un service à {selectedModelForService?.name}</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <FormControl fullWidth required>
              <InputLabel>Service</InputLabel>
              <Select value={newServiceAssociation.serviceId || ''} onChange={e => setNewServiceAssociation({ ...newServiceAssociation, serviceId: e.target.value })} label="Service" sx={{ borderRadius: '10px' }}>
                {(useAppStore.getState().services || []).map(s => (
                  <MenuItem key={s.id} value={s.id}><Box sx={{ display: 'flex', justifyContent: 'space-between', width: '100%' }}><span>{s.name}</span><Typography variant="caption" color="text.secondary">{formatFromEUR(s.price, currency)} - {s.duration}h</Typography></Box></MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField label="Prix personnalisé (optionnel)" type="number" value={newServiceAssociation.customPrice || ''} onChange={e => setNewServiceAssociation({ ...newServiceAssociation, customPrice: e.target.value ? parseFloat(e.target.value) : undefined })} fullWidth placeholder="Laisser vide pour le prix par défaut" inputProps={{ min: 0, step: 0.01 }} sx={INPUT_SX} />
            <TextField label="Durée personnalisée en heures (optionnel)" type="number" value={newServiceAssociation.customDuration || ''} onChange={e => setNewServiceAssociation({ ...newServiceAssociation, customDuration: e.target.value ? parseInt(e.target.value) : undefined })} fullWidth placeholder="Laisser vide pour la durée par défaut" inputProps={{ min: 1, step: 1 }} sx={INPUT_SX} />
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setServiceAssociationDialogOpen(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>Annuler</Button>
          <Button variant="contained" onClick={handleCreateServiceAssociation} disabled={!newServiceAssociation.serviceId || loading} sx={BTN_DARK}>
            {loading ? <CircularProgress size={20} /> : 'Associer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Import CSV dialog */}
      <Dialog open={importDialogOpen} onClose={() => setImportDialogOpen(false)} maxWidth="sm" fullWidth PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>Importer des {importType === 'brands' ? 'marques' : importType === 'models' ? 'modèles' : 'catégories'}</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <Alert severity="info" sx={{ borderRadius: '12px' }}>
              <Typography variant="body2" gutterBottom><strong>Format attendu :</strong></Typography>
              {importType === 'categories' ? (
                <Typography variant="body2">name, description, icon (optionnel)</Typography>
              ) : importType === 'brands' ? (
                <Typography variant="body2">name, description, categoryIds (séparés par ;). Les catégories doivent exister.</Typography>
              ) : (
                <Typography variant="body2">name, description, brandName, categoryName. Les marques et catégories doivent exister.</Typography>
              )}
            </Alert>
            <Button variant="outlined" startIcon={<DownloadIcon />} onClick={() => handleDownloadTemplate(importType)} fullWidth sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'grey.300', color: 'text.secondary' }}>Télécharger le modèle CSV</Button>
            <Divider><Typography variant="caption" color="text.secondary">Sélectionner un fichier</Typography></Divider>
            <input accept=".csv" style={{ display: 'none' }} id="csv-upload-input" type="file" onChange={handleImportCSV} />
            <label htmlFor="csv-upload-input">
              <Button variant="contained" component="span" startIcon={loading ? <CircularProgress size={18} /> : <UploadIcon />} fullWidth disabled={loading} sx={BTN_DARK}>
                {loading ? 'Importation...' : 'Sélectionner et importer'}
              </Button>
            </label>
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setImportDialogOpen(false)} disabled={loading} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>Fermer</Button>
        </DialogActions>
      </Dialog>

      {/* Bulk delete dialog */}
      <Dialog open={bulkDeleteDialogOpen} onClose={() => setBulkDeleteDialogOpen(false)} PaperProps={{ sx: { borderRadius: '16px' } }}>
        <DialogTitle sx={{ fontWeight: 700 }}>Suppression en lot</DialogTitle>
        <DialogContent><Typography>Supprimer {selectedItems.length} {bulkDeleteType === 'brands' ? 'marque(s)' : bulkDeleteType === 'models' ? 'modèle(s)' : 'catégorie(s)'} ? Cette action est irréversible.</Typography></DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setBulkDeleteDialogOpen(false)} sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>Annuler</Button>
          <Button variant="contained" onClick={handleBulkDelete} disabled={loading} sx={{ ...BTN_DARK, bgcolor: '#ef4444', '&:hover': { bgcolor: '#dc2626' }, boxShadow: '0 2px 8px rgba(239,68,68,0.25)' }}>
            {loading ? <CircularProgress size={20} /> : 'Supprimer'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DeviceManagement;
