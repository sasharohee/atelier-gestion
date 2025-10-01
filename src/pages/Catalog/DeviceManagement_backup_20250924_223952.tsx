// @ts-nocheck
import React, { useState, useEffect } from 'react';
import { useAppStore } from '../../store';
import { DeviceCategory, DeviceBrand, DeviceModel } from '../../types/deviceManagement';
import { categoryService, ProductCategory } from '../../services/categoryService';
import { brandService } from '../../services/deviceManagementService';
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
  // Icônes de base pour les catégories (testées et sûres)
  Watch as WatchIcon,
  Headphones as HeadphonesIcon,
  CameraAlt as CameraIcon,
  Tv as TvIcon,
  Speaker as SpeakerIcon,
  Keyboard as KeyboardIcon,
  Mouse as MouseIcon,
  Router as RouterIcon,
  Memory as MemoryIcon,
  Storage as StorageIcon,
  BatteryChargingFull as BatteryIcon,
  Wifi as WifiIcon,
  Bluetooth as BluetoothIcon,
  Usb as UsbIcon,
  Power as PowerIcon,
  Security as SecurityIcon,
  Speed as SpeedIcon,
  SdCard as SdCardIcon,
  SimCard as SimCardIcon,
  NetworkCheck as NetworkIcon,
  SignalCellular4Bar as SignalIcon,
  GpsFixed as GpsIcon,
  Sensors as SensorsIcon,
  FlashOn as FlashIcon,
  VolumeUp as VolumeIcon,
  Mic as MicIcon,
  Videocam as VideocamIcon,
  PhotoCamera as PhotoCameraIcon,
  Print as PrintIcon,
  Scanner as ScannerIcon,
  Fax as FaxIcon,
  Monitor as MonitorIcon,
  DisplaySettings as DisplayIcon,
  Brightness6 as BrightnessIcon,
  Contrast as ContrastIcon,
  ColorLens as ColorIcon,
  HdrOn as HdrIcon,
  AutoAwesome as AutoAwesomeIcon,
  HighQuality as QualityIcon,
  SurroundSound as SurroundIcon,
  Subscriptions as SubscriptionsIcon,
  LiveTv as LiveTvIcon,
  MusicNote as MusicIcon,
  Radio as RadioIcon,
  Podcasts as PodcastsIcon,
  Audiotrack as AudiotrackIcon,
  Equalizer as EqualizerIcon,
  GraphicEq as GraphicEqIcon,
  VolumeOff as VolumeOffIcon,
  VolumeDown as VolumeDownIcon,
  BluetoothAudio as BluetoothAudioIcon,
  Airplay as AirplayIcon,
  Cast as CastIcon,
  ScreenShare as ScreenShareIcon,
  ConnectedTv as ConnectedTvIcon,
  SmartDisplay as SmartDisplayIcon,
  VideoCall as VideoCallIcon,
  VideoChat as VideoChatIcon,
  VideoSettings as VideoSettingsIcon,
  VideoStable as VideoStableIcon,
  VideoFile as VideoFileIcon,
  VideoLabel as VideoLabelIcon,
} from '@mui/icons-material';
import { Device, DeviceType } from '../../types';
import SpecificationsDisplay from '../../components/SpecificationsDisplay';



const DeviceManagement: React.FC = () => {
  const { 
    deviceCategories,
    deviceBrands,
    deviceModels,
    addDeviceCategory,
    updateDeviceCategory,
    deleteDeviceCategory,
    addDeviceBrand,
    updateDeviceBrand,
    deleteDeviceBrand,
    addDeviceModel,
    updateDeviceModel,
    deleteDeviceModel,
    getDeviceCategories,
    getDeviceBrands,
    getDeviceModels,
  } = useAppStore();
  
  // État principal pour les onglets
  const [mainTab, setMainTab] = useState(0);
  
  // États pour les catégories
  const [categoryDialogOpen, setCategoryDialogOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<DeviceCategory | null>(null);
  const [newCategory, setNewCategory] = useState({
    name: '',
    description: '',
    icon: 'smartphone',
    isActive: true,
  });

  // États pour les marques
  const [brandDialogOpen, setBrandDialogOpen] = useState(false);
  const [selectedBrand, setSelectedBrand] = useState<DeviceBrand | null>(null);
  const [newBrand, setNewBrand] = useState({
    name: '',
    categoryIds: [] as string[], // Tableau pour plusieurs catégories
    description: '',
    logo: '',
    isActive: true,
  });

  // États pour les modèles
  const [modelDialogOpen, setModelDialogOpen] = useState(false);
  const [selectedModel, setSelectedModel] = useState<DeviceModel | null>(null);
  const [newModel, setNewModel] = useState<any>({
    name: '', // Le champ 'name' du formulaire correspond au 'model' de la base
    brand: '',
    brandId: '',
    categoryId: '',
    type: 'smartphone',
    year: new Date().getFullYear(),
    specifications: {},
    commonIssues: [''],
    repairDifficulty: 'medium',
    partsAvailability: 'medium',
    isActive: true,
  });



  // États généraux
  const [searchQuery, setSearchQuery] = useState('');
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<any>(null);
  const [deleteType, setDeleteType] = useState<'category' | 'brand' | 'model'>('category');
  const [selectedCategoryForBrands, setSelectedCategoryForBrands] = useState<string>('all');
  const [categoriesLoading, setCategoriesLoading] = useState(true);
  const [categoriesError, setCategoriesError] = useState<string | null>(null);

  // État pour les catégories depuis la base de données
  const [dbCategories, setDbCategories] = useState<ProductCategory[]>([]);
  
  // État pour les marques depuis la base de données
  const [dbBrands, setDbBrands] = useState<DeviceBrand[]>([]);
  const [brandsLoading, setBrandsLoading] = useState(true);
  const [brandsError, setBrandsError] = useState<string | null>(null);

  // Charger les catégories depuis la base de données avec isolation
  useEffect(() => {
    const loadCategories = async () => {
      try {
        setCategoriesLoading(true);
        setCategoriesError(null);
        
        const result = await categoryService.getAll();
        if (result.success && result.data) {
          setDbCategories(result.data);
          console.log('✅ Catégories chargées depuis la base de données:', result.data.length);
          
          // Si aucune catégorie n'existe, créer les catégories par défaut
          if (result.data.length === 0) {
            console.log('📝 Aucune catégorie trouvée, création des catégories par défaut...');
            await createDefaultCategories();
          }
        } else {
          setCategoriesError(result.error || 'Erreur lors du chargement des catégories');
          console.error('❌ Erreur lors du chargement des catégories:', result.error);
        }
      } catch (error) {
        setCategoriesError('Erreur lors du chargement des catégories');
        console.error('❌ Erreur lors du chargement des catégories:', error);
      } finally {
        setCategoriesLoading(false);
      }
    };

    loadCategories();
  }, []);

  // Fonction pour créer les catégories par défaut
  const createDefaultCategories = async () => {
    const defaultCategoryData = [
      { name: 'Smartphone', description: 'Téléphones intelligents', icon: 'smartphone' },
      { name: 'Tablette', description: 'Tablettes tactiles', icon: 'tablet' },
      { name: 'Ordinateur portable', description: 'Laptops et notebooks', icon: 'laptop' },
      { name: 'Ordinateur fixe', description: 'Ordinateurs de bureau', icon: 'desktop' },
      { name: 'Autre', description: 'Autres appareils électroniques', icon: 'other' }
    ];

    try {
      for (const categoryData of defaultCategoryData) {
        const result = await categoryService.create(categoryData);
        if (result.success) {
          console.log('✅ Catégorie par défaut créée:', categoryData.name);
        } else {
          console.error('❌ Erreur lors de la création de la catégorie:', categoryData.name, result.error);
        }
      }
      
      // Recharger les catégories après création
      const categoriesResult = await categoryService.getAll();
      if (categoriesResult.success && categoriesResult.data) {
        setDbCategories(categoriesResult.data);
        console.log('✅ Catégories rechargées après création:', categoriesResult.data.length);
      }
    } catch (error) {
      console.error('❌ Erreur lors de la création des catégories par défaut:', error);
    }
  };

  // Charger les marques depuis la base de données
  useEffect(() => {
    const loadBrands = async () => {
      try {
        setBrandsLoading(true);
        setBrandsError(null);
        
        const result = await brandService.getAll();
        if (result.success && result.data) {
          setDbBrands(result.data);
          console.log('✅ Marques chargées depuis la base de données:', result.data.length);
        } else {
          setBrandsError(result.error || 'Erreur lors du chargement des marques');
          console.error('❌ Erreur lors du chargement des marques:', result.error);
        }
      } catch (error) {
        setBrandsError('Erreur lors du chargement des marques');
        console.error('❌ Erreur lors du chargement des marques:', error);
      } finally {
        setBrandsLoading(false);
      }
    };

    loadBrands();
  }, []);

  // Convertir les catégories de la base de données au format DeviceCategory
  const convertDbCategoryToDeviceCategory = (dbCategory: ProductCategory): DeviceCategory => ({
    id: dbCategory.id,
    name: dbCategory.name,
    description: dbCategory.description,
    icon: dbCategory.icon,
    isActive: dbCategory.is_active,
    createdAt: new Date(dbCategory.created_at),
    updatedAt: new Date(dbCategory.updated_at),
  });

  // Utiliser uniquement les catégories de la base de données (pas de fallback hardcodé)
  const defaultCategories: DeviceCategory[] = dbCategories.map(convertDbCategoryToDeviceCategory);

  // Données de test pour les marques
  const defaultBrands: DeviceBrand[] = [
    // Smartphones
    {
      id: '1',
      name: 'Apple',
      categoryId: '1',
      description: 'Fabricant américain de produits électroniques premium',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '2',
      name: 'Samsung',
      categoryId: '1',
      description: 'Fabricant coréen leader en électronique et smartphones',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '3',
      name: 'Xiaomi',
      categoryId: '1',
      description: 'Fabricant chinois de smartphones et IoT',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '4',
      name: 'Huawei',
      categoryId: '1',
      description: 'Fabricant chinois de télécommunications et smartphones',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '5',
      name: 'OnePlus',
      categoryId: '1',
      description: 'Marque de smartphones premium',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '6',
      name: 'Google',
      categoryId: '1',
      description: 'Fabricant des smartphones Pixel',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '7',
      name: 'Sony',
      categoryId: '1',
      description: 'Fabricant japonais d\'électronique',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '8',
      name: 'LG',
      categoryId: '1',
      description: 'Fabricant coréen d\'électronique',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '9',
      name: 'Nokia',
      categoryId: '1',
      description: 'Fabricant finlandais de télécommunications',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '10',
      name: 'Motorola',
      categoryId: '1',
      description: 'Fabricant américain de télécommunications',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '11',
      name: 'HTC',
      categoryId: '1',
      description: 'Fabricant taïwanais de smartphones',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '12',
      name: 'ASUS',
      categoryId: '1',
      description: 'Fabricant taïwanais d\'électronique',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '13',
      name: 'ZTE',
      categoryId: '1',
      description: 'Fabricant chinois de télécommunications',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '14',
      name: 'OPPO',
      categoryId: '1',
      description: 'Fabricant chinois de smartphones',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '15',
      name: 'Vivo',
      categoryId: '1',
      description: 'Fabricant chinois de smartphones',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '16',
      name: 'Realme',
      categoryId: '1',
      description: 'Marque de smartphones chinoise',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '17',
      name: 'Honor',
      categoryId: '1',
      description: 'Marque de smartphones chinoise',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '18',
      name: 'Nothing',
      categoryId: '1',
      description: 'Marque de smartphones innovante',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '19',
      name: 'Fairphone',
      categoryId: '1',
      description: 'Fabricant de smartphones éthiques',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '20',
      name: 'Cat',
      categoryId: '1',
      description: 'Smartphones robustes pour professionnels',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    // Tablettes
    {
      id: '21',
      name: 'iPad',
      categoryId: '2',
      description: 'Tablettes Apple',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '22',
      name: 'Samsung Galaxy Tab',
      categoryId: '2',
      description: 'Tablettes Samsung',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '23',
      name: 'Lenovo',
      categoryId: '2',
      description: 'Fabricant chinois d\'ordinateurs et tablettes',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '24',
      name: 'Huawei MediaPad',
      categoryId: '2',
      description: 'Tablettes Huawei',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '25',
      name: 'Xiaomi Mi Pad',
      categoryId: '2',
      description: 'Tablettes Xiaomi',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '26',
      name: 'Amazon',
      categoryId: '2',
      description: 'Fabricant des tablettes Kindle et Fire',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '27',
      name: 'Microsoft',
      categoryId: '2',
      description: 'Fabricant des tablettes Surface',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    // Ordinateurs portables
    {
      id: '28',
      name: 'Dell',
      categoryId: '3',
      description: 'Fabricant américain d\'ordinateurs',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '29',
      name: 'HP',
      categoryId: '3',
      description: 'Fabricant américain d\'imprimantes et ordinateurs',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '30',
      name: 'Lenovo',
      categoryId: '3',
      description: 'Fabricant chinois d\'ordinateurs',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '31',
      name: 'Acer',
      categoryId: '3',
      description: 'Fabricant taïwanais d\'ordinateurs',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '32',
      name: 'ASUS',
      categoryId: '3',
      description: 'Fabricant taïwanais d\'ordinateurs',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '33',
      name: 'MSI',
      categoryId: '3',
      description: 'Fabricant taïwanais d\'ordinateurs gaming',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '34',
      name: 'Razer',
      categoryId: '3',
      description: 'Fabricant américain d\'ordinateurs gaming',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '35',
      name: 'Alienware',
      categoryId: '3',
      description: 'Marque gaming de Dell',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '36',
      name: 'Gigabyte',
      categoryId: '3',
      description: 'Fabricant taïwanais d\'ordinateurs',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '37',
      name: 'Toshiba',
      categoryId: '3',
      description: 'Fabricant japonais d\'électronique',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '38',
      name: 'Fujitsu',
      categoryId: '3',
      description: 'Fabricant japonais d\'informatique',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '39',
      name: 'Sony VAIO',
      categoryId: '3',
      description: 'Ordinateurs portables Sony',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '40',
      name: 'Samsung',
      categoryId: '3',
      description: 'Ordinateurs portables Samsung',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '41',
      name: 'LG',
      categoryId: '3',
      description: 'Ordinateurs portables LG',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '42',
      name: 'Huawei',
      categoryId: '3',
      description: 'Ordinateurs portables Huawei',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '43',
      name: 'Xiaomi',
      categoryId: '3',
      description: 'Ordinateurs portables Xiaomi',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '44',
      name: 'Microsoft',
      categoryId: '3',
      description: 'Fabricant des ordinateurs Surface',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '45',
      name: 'Apple',
      categoryId: '3',
      description: 'Fabricant des MacBook',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    // Ordinateurs fixes
    {
      id: '46',
      name: 'Dell',
      categoryId: '4',
      description: 'Ordinateurs de bureau Dell',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '47',
      name: 'HP',
      categoryId: '4',
      description: 'Ordinateurs de bureau HP',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '48',
      name: 'Lenovo',
      categoryId: '4',
      description: 'Ordinateurs de bureau Lenovo',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '49',
      name: 'Acer',
      categoryId: '4',
      description: 'Ordinateurs de bureau Acer',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '50',
      name: 'ASUS',
      categoryId: '4',
      description: 'Ordinateurs de bureau ASUS',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '51',
      name: 'MSI',
      categoryId: '4',
      description: 'Ordinateurs de bureau gaming MSI',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '52',
      name: 'Alienware',
      categoryId: '4',
      description: 'Ordinateurs de bureau gaming Alienware',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '53',
      name: 'Corsair',
      categoryId: '4',
      description: 'Fabricant américain de composants gaming',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '54',
      name: 'CyberPowerPC',
      categoryId: '4',
      description: 'Fabricant américain d\'ordinateurs gaming',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '55',
      name: 'iBUYPOWER',
      categoryId: '4',
      description: 'Fabricant américain d\'ordinateurs gaming',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '56',
      name: 'Origin PC',
      categoryId: '4',
      description: 'Fabricant américain d\'ordinateurs gaming',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '57',
      name: 'Falcon Northwest',
      categoryId: '4',
      description: 'Fabricant américain d\'ordinateurs haut de gamme',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '58',
      name: 'Maingear',
      categoryId: '4',
      description: 'Fabricant américain d\'ordinateurs gaming',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '59',
      name: 'Digital Storm',
      categoryId: '4',
      description: 'Fabricant américain d\'ordinateurs gaming',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      id: '60',
      name: 'Apple',
      categoryId: '4',
      description: 'Fabricant des iMac et Mac Pro',
      logo: '',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  // Charger les données au montage
  useEffect(() => {
    // Les données sont maintenant gérées par le store centralisé
    // Pas besoin de charger ici car elles sont déjà initialisées dans le store
  }, []);

  // Initialiser les valeurs par défaut des formulaires quand les catégories sont chargées
  useEffect(() => {
    if (dbCategories.length > 0) {
      // Initialiser newBrand si categoryId est vide
      if (!newBrand.categoryId) {
        setNewBrand(prev => ({
          ...prev,
          categoryId: dbCategories[0].id
        }));
      }
      
      // Initialiser newModel si categoryId est vide
      if (!newModel.categoryId) {
        setNewModel(prev => ({
          ...prev,
          categoryId: dbCategories[0].id
        }));
      }
    }
  }, [dbCategories]);

  // Liste des icônes disponibles pour les catégories (icônes sûres et testées)
  const availableIcons = [
    { value: 'smartphone', label: 'Smartphone', color: '#2196f3' },
    { value: 'tablet', label: 'Tablette', color: '#9c27b0' },
    { value: 'laptop', label: 'Ordinateur portable', color: '#ff9800' },
    { value: 'desktop', label: 'Ordinateur fixe', color: '#4caf50' },
    { value: 'watch', label: 'Montre connectée', color: '#e91e63' },
    { value: 'headphones', label: 'Casque audio', color: '#795548' },
    { value: 'camera', label: 'Appareil photo', color: '#607d8b' },
    { value: 'tv', label: 'Télévision', color: '#3f51b5' },
    { value: 'speaker', label: 'Haut-parleur', color: '#8bc34a' },
    { value: 'keyboard', label: 'Clavier', color: '#ff5722' },
    { value: 'mouse', label: 'Souris', color: '#9e9e9e' },
    { value: 'router', label: 'Routeur', color: '#00bcd4' },
    { value: 'memory', label: 'Mémoire', color: '#673ab7' },
    { value: 'storage', label: 'Stockage', color: '#ffc107' },
    { value: 'battery', label: 'Batterie', color: '#4caf50' },
    { value: 'wifi', label: 'Wi-Fi', color: '#2196f3' },
    { value: 'bluetooth', label: 'Bluetooth', color: '#3f51b5' },
    { value: 'usb', label: 'USB', color: '#ff9800' },
    { value: 'power', label: 'Alimentation', color: '#f44336' },
    { value: 'security', label: 'Sécurité', color: '#e91e63' },
    { value: 'speed', label: 'Performance', color: '#00bcd4' },
    { value: 'sdcard', label: 'Carte SD', color: '#795548' },
    { value: 'simcard', label: 'Carte SIM', color: '#607d8b' },
    { value: 'network', label: 'Réseau', color: '#3f51b5' },
    { value: 'signal', label: 'Signal', color: '#4caf50' },
    { value: 'gps', label: 'GPS', color: '#2196f3' },
    { value: 'sensors', label: 'Capteurs', color: '#9c27b0' },
    { value: 'flash', label: 'Flash', color: '#ffc107' },
    { value: 'volume', label: 'Volume', color: '#ff9800' },
    { value: 'mic', label: 'Microphone', color: '#795548' },
    { value: 'videocam', label: 'Caméra vidéo', color: '#e91e63' },
    { value: 'photocamera', label: 'Appareil photo', color: '#607d8b' },
    { value: 'print', label: 'Imprimante', color: '#9e9e9e' },
    { value: 'scanner', label: 'Scanner', color: '#795548' },
    { value: 'fax', label: 'Fax', color: '#607d8b' },
    { value: 'monitor', label: 'Écran', color: '#3f51b5' },
    { value: 'display', label: 'Affichage', color: '#2196f3' },
    { value: 'brightness', label: 'Luminosité', color: '#ffc107' },
    { value: 'contrast', label: 'Contraste', color: '#9e9e9e' },
    { value: 'color', label: 'Couleur', color: '#e91e63' },
    { value: 'hdr', label: 'HDR', color: '#ff9800' },
    { value: 'autoawesome', label: 'Auto', color: '#4caf50' },
    { value: 'quality', label: 'Qualité', color: '#2196f3' },
    { value: 'surround', label: 'Surround', color: '#3f51b5' },
    { value: 'subscriptions', label: 'Abonnements', color: '#e91e63' },
    { value: 'livetv', label: 'TV en direct', color: '#f44336' },
    { value: 'music', label: 'Musique', color: '#9c27b0' },
    { value: 'radio', label: 'Radio', color: '#ff9800' },
    { value: 'podcasts', label: 'Podcasts', color: '#795548' },
    { value: 'audiotrack', label: 'Piste audio', color: '#607d8b' },
    { value: 'equalizer', label: 'Égaliseur', color: '#3f51b5' },
    { value: 'graphiceq', label: 'Graphic EQ', color: '#2196f3' },
    { value: 'volumeoff', label: 'Volume off', color: '#9e9e9e' },
    { value: 'volumedown', label: 'Volume bas', color: '#ff9800' },
    { value: 'bluetoothaudio', label: 'Audio Bluetooth', color: '#3f51b5' },
    { value: 'airplay', label: 'AirPlay', color: '#2196f3' },
    { value: 'cast', label: 'Cast', color: '#ff5722' },
    { value: 'screenshare', label: 'Partage écran', color: '#00bcd4' },
    { value: 'connectedtv', label: 'TV connectée', color: '#673ab7' },
    { value: 'smartdisplay', label: 'Écran intelligent', color: '#4caf50' },
    { value: 'videocall', label: 'Appel vidéo', color: '#e91e63' },
    { value: 'videochat', label: 'Chat vidéo', color: '#2196f3' },
    { value: 'videosettings', label: 'Paramètres vidéo', color: '#3f51b5' },
    { value: 'videostable', label: 'Stabilisation vidéo', color: '#ff9800' },
    { value: 'videofile', label: 'Fichier vidéo', color: '#795548' },
    { value: 'videolabel', label: 'Label vidéo', color: '#607d8b' },
    { value: 'other', label: 'Autre', color: '#757575' },
  ];

  // Fonctions utilitaires
  const getDeviceTypeIcon = (icon: string) => {
    switch (icon) {
      case 'smartphone': return <PhoneIcon />;
      case 'tablet': return <TabletIcon />;
      case 'laptop': return <LaptopIcon />;
      case 'desktop': return <ComputerIcon />;
      case 'watch': return <WatchIcon />;
      case 'headphones': return <HeadphonesIcon />;
      case 'camera': return <CameraIcon />;
      case 'tv': return <TvIcon />;
      case 'speaker': return <SpeakerIcon />;
      case 'keyboard': return <KeyboardIcon />;
      case 'mouse': return <MouseIcon />;
      case 'router': return <RouterIcon />;
      case 'memory': return <MemoryIcon />;
      case 'storage': return <StorageIcon />;
      case 'battery': return <BatteryIcon />;
      case 'wifi': return <WifiIcon />;
      case 'bluetooth': return <BluetoothIcon />;
      case 'usb': return <UsbIcon />;
      case 'power': return <PowerIcon />;
      case 'security': return <SecurityIcon />;
      case 'speed': return <SpeedIcon />;
      case 'sdcard': return <SdCardIcon />;
      case 'simcard': return <SimCardIcon />;
      case 'network': return <NetworkIcon />;
      case 'signal': return <SignalIcon />;
      case 'gps': return <GpsIcon />;
      case 'sensors': return <SensorsIcon />;
      case 'flash': return <FlashIcon />;
      case 'volume': return <VolumeIcon />;
      case 'mic': return <MicIcon />;
      case 'videocam': return <VideocamIcon />;
      case 'photocamera': return <PhotoCameraIcon />;
      case 'print': return <PrintIcon />;
      case 'scanner': return <ScannerIcon />;
      case 'fax': return <FaxIcon />;
      case 'monitor': return <MonitorIcon />;
      case 'display': return <DisplayIcon />;
      case 'brightness': return <BrightnessIcon />;
      case 'contrast': return <ContrastIcon />;
      case 'color': return <ColorIcon />;
      case 'hdr': return <HdrIcon />;
      case 'autoawesome': return <AutoAwesomeIcon />;
      case 'quality': return <QualityIcon />;
      case 'surround': return <SurroundIcon />;
      case 'subscriptions': return <SubscriptionsIcon />;
      case 'livetv': return <LiveTvIcon />;
      case 'music': return <MusicIcon />;
      case 'radio': return <RadioIcon />;
      case 'podcasts': return <PodcastsIcon />;
      case 'audiotrack': return <AudiotrackIcon />;
      case 'equalizer': return <EqualizerIcon />;
      case 'graphiceq': return <GraphicEqIcon />;
      case 'volumeoff': return <VolumeOffIcon />;
      case 'volumedown': return <VolumeDownIcon />;
      case 'bluetoothaudio': return <BluetoothAudioIcon />;
      case 'airplay': return <AirplayIcon />;
      case 'cast': return <CastIcon />;
      case 'screenshare': return <ScreenShareIcon />;
      case 'connectedtv': return <ConnectedTvIcon />;
      case 'smartdisplay': return <SmartDisplayIcon />;
      case 'videocall': return <VideoCallIcon />;
      case 'videochat': return <VideoChatIcon />;
      case 'videosettings': return <VideoSettingsIcon />;
      case 'videostable': return <VideoStableIcon />;
      case 'videofile': return <VideoFileIcon />;
      case 'videolabel': return <VideoLabelIcon />;
      default: return <DeviceHubIcon />;
    }
  };

  const getDeviceTypeColor = (icon: string) => {
    const iconData = availableIcons.find(i => i.value === icon);
    return iconData ? iconData.color : '#757575';
  };

  const getDeviceTypeLabel = (icon: string) => {
    const iconData = availableIcons.find(i => i.value === icon);
    return iconData ? iconData.label : 'Autre';
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
  const handleCreateCategory = async () => {
    try {
      const result = await categoryService.create({
        name: newCategory.name,
        description: newCategory.description,
        icon: newCategory.icon,
        is_active: newCategory.isActive,
      });

      if (result.success && result.data) {
        console.log('✅ Catégorie créée avec succès:', result.data);
        
        // Recharger les catégories depuis la base de données
        const categoriesResult = await categoryService.getAll();
        if (categoriesResult.success && categoriesResult.data) {
          setDbCategories(categoriesResult.data);
          console.log('✅ Catégories rechargées:', categoriesResult.data.length);
        } else {
          console.error('❌ Erreur lors du rechargement des catégories:', categoriesResult.error);
        }
        
        setCategoryDialogOpen(false);
        resetCategoryForm();
      } else {
        console.error('❌ Erreur lors de la création de la catégorie:', result.error);
        setCategoriesError(result.error || 'Erreur lors de la création de la catégorie');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la création de la catégorie:', error);
      setCategoriesError('Erreur lors de la création de la catégorie');
    }
  };

  const handleUpdateCategory = async () => {
    if (selectedCategory) {
      try {
        const result = await categoryService.update(selectedCategory.id, {
          name: newCategory.name,
          description: newCategory.description,
          icon: newCategory.icon,
          color: '#1976d2',
          is_active: newCategory.isActive,
        });

        if (result.success && result.data) {
          console.log('✅ Catégorie mise à jour avec succès:', result.data);
          
          // Recharger les catégories depuis la base de données
          const categoriesResult = await categoryService.getAll();
          if (categoriesResult.success && categoriesResult.data) {
            setDbCategories(categoriesResult.data);
            console.log('✅ Catégories rechargées après mise à jour:', categoriesResult.data.length);
          }
          
          setCategoryDialogOpen(false);
          setSelectedCategory(null);
          resetCategoryForm();
        } else {
          console.error('❌ Erreur lors de la mise à jour de la catégorie:', result.error);
          setCategoriesError(result.error || 'Erreur lors de la mise à jour de la catégorie');
        }
      } catch (error) {
        console.error('❌ Erreur lors de la mise à jour de la catégorie:', error);
        setCategoriesError('Erreur lors de la mise à jour de la catégorie');
      }
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

  // Fonctions pour les marques
  const handleCreateBrand = async () => {
    try {
      const result = await brandService.create({
        name: newBrand.name,
        categoryIds: newBrand.categoryIds, // Utiliser le tableau de catégories
        description: newBrand.description,
        logo: newBrand.logo,
        isActive: newBrand.isActive,
      });

      if (result.success && result.data) {
        console.log('✅ Marque créée avec succès:', result.data);
        console.log('📋 Catégories associées:', result.data.categories?.map(c => c.name));
        
        // Recharger les marques depuis la base de données
        const brandsResult = await brandService.getAll();
        if (brandsResult.success && brandsResult.data) {
          setDbBrands(brandsResult.data);
          console.log('✅ Marques rechargées:', brandsResult.data.length);
        }
        
        setBrandDialogOpen(false);
        resetBrandForm();
      } else {
        console.error('❌ Erreur lors de la création de la marque:', result.error);
      }
    } catch (error) {
      console.error('❌ Erreur lors de la création de la marque:', error);
    }
  };

  const handleUpdateBrand = async () => {
    console.log('🔧 handleUpdateBrand appelé');
    console.log('📋 selectedBrand:', selectedBrand);
    console.log('📋 newBrand:', newBrand);
    
    if (selectedBrand) {
      // Vérifier si c'est une marque hardcodée (ID non-UUID)
      const isHardcodedBrand = !selectedBrand.id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
      
      if (isHardcodedBrand) {
        console.log('⚠️ Modification de catégories pour une marque hardcodée:', selectedBrand.id);
        
        // Pour les marques hardcodées, on permet seulement la modification des catégories
        // via la création d'entrées dans la table brand_categories
        
        // Vérifier si le script SQL a été exécuté (si la fonction RPC existe)
        try {
          const testResult = await supabase.rpc('update_brand_categories', {
            p_brand_id: selectedBrand.id,
            p_category_ids: []
          });
          
          // Si ça fonctionne, on peut modifier les catégories
          console.log('✅ Système many-to-many disponible, modification des catégories autorisée');
        } catch (error) {
          console.log('⚠️ Système many-to-many non disponible, fallback vers l\'ancien système');
          
          // Fallback : modifier seulement le champ category_id avec la première catégorie
          if (newBrand.categoryIds.length > 0) {
            try {
              // Utiliser le service brandService pour la mise à jour
              const updateData = {
                categoryId: newBrand.categoryIds[0] // Utiliser le premier ID de catégorie
              };
              
              const result = await brandService.update(selectedBrand.id, updateData);
              
              if (result.success) {
                console.log('✅ Catégorie mise à jour avec succès');
                alert('Catégorie mise à jour avec succès !');
                
                // Recharger les marques
                const brandsResult = await brandService.getAll();
                if (brandsResult.success && brandsResult.data) {
                  setDbBrands(brandsResult.data);
                }
                
                setBrandDialogOpen(false);
                setSelectedBrand(null);
                resetBrandForm();
                return;
              } else {
                console.error('❌ Erreur lors de la mise à jour de la catégorie:', result.error);
                alert('Erreur lors de la mise à jour de la catégorie: ' + result.error);
                return;
              }
            } catch (error) {
              console.error('❌ Erreur lors de la mise à jour:', error);
              alert('Erreur lors de la mise à jour: ' + error);
              return;
            }
          } else {
            alert('Veuillez sélectionner au moins une catégorie.');
            return;
          }
        }
      }
      
      try {
        console.log('🚀 Début de la mise à jour de la marque:', selectedBrand.id);
        
        const updateData = {
          name: newBrand.name,
          categoryIds: newBrand.categoryIds, // Utiliser le tableau de catégories
          description: newBrand.description,
          logo: newBrand.logo,
          isActive: newBrand.isActive,
        };
        
        console.log('📤 Données à envoyer:', updateData);
        
        const result = await brandService.update(selectedBrand.id, updateData);
        
        console.log('📥 Résultat de la mise à jour:', result);

        if (result.success && result.data) {
          console.log('✅ Marque mise à jour avec succès:', result.data);
          console.log('📋 Catégories associées:', result.data.categories?.map(c => c.name));
          
          // Recharger les marques depuis la base de données
          const brandsResult = await brandService.getAll();
          if (brandsResult.success && brandsResult.data) {
            setDbBrands(brandsResult.data);
            console.log('✅ Marques rechargées après mise à jour:', brandsResult.data.length);
          }
          
          setBrandDialogOpen(false);
          setSelectedBrand(null);
          resetBrandForm();
        } else {
          console.error('❌ Erreur lors de la mise à jour de la marque:', result.error);
          alert('Erreur lors de la mise à jour: ' + (result.error || 'Erreur inconnue'));
        }
      } catch (error) {
        console.error('❌ Erreur lors de la mise à jour de la marque:', error);
        alert('Erreur lors de la mise à jour: ' + error);
      }
    } else {
      console.error('❌ Aucune marque sélectionnée pour la mise à jour');
      alert('Aucune marque sélectionnée');
    }
  };

  const resetBrandForm = () => {
    setNewBrand({
      name: '',
      categoryIds: [], // Réinitialiser le tableau de catégories
      description: '',
      logo: '',
      isActive: true,
    });
  };

  const openBrandEditDialog = (brand: DeviceBrand) => {
    console.log('🔧 openBrandEditDialog appelé avec:', brand);
    
    setSelectedBrand(brand);
    
    // Déterminer les catégories à afficher
    let categoryIds: string[] = [];
    if (brand.categoryIds && brand.categoryIds.length > 0) {
      categoryIds = brand.categoryIds;
      console.log('📋 Utilisation des categoryIds:', categoryIds);
    } else if (brand.categoryId) {
      categoryIds = [brand.categoryId];
      console.log('📋 Utilisation du categoryId (fallback):', categoryIds);
    } else {
      console.log('⚠️ Aucune catégorie trouvée pour cette marque');
    }
    
    const formData = {
      name: brand.name,
      categoryIds: categoryIds,
      description: brand.description || '',
      logo: brand.logo || '',
      isActive: brand.isActive,
    };
    
    console.log('📝 Données du formulaire:', formData);
    
    setNewBrand(formData);
    setBrandDialogOpen(true);
  };

  // Fonctions pour les modèles
  const handleCreateModel = async () => {
    try {
      // Trouver le nom de la marque à partir de l'ID
      const selectedBrand = allBrands.find(brand => brand.id === newModel.brandId);
      const brandName = selectedBrand ? selectedBrand.name : newModel.brandId;
      
      // Trouver le nom de la catégorie à partir de l'ID
      const selectedCategory = defaultCategories.find(cat => cat.id === newModel.categoryId);
      const categoryType = selectedCategory ? selectedCategory.name.toLowerCase() : 'smartphone';
      
      const modelData = {
        brand: brandName,
        model: newModel.name, // Le champ 'name' du formulaire correspond au 'model' de la base
        type: categoryType as any,
        year: newModel.year,
        specifications: newModel.specifications,
        commonIssues: newModel.commonIssues.filter(issue => issue.trim() !== ''),
        repairDifficulty: newModel.repairDifficulty,
        partsAvailability: newModel.partsAvailability,
        isActive: newModel.isActive,
      };

      console.log('📤 Création du modèle avec les données:', modelData);
      
      const result = await addDeviceModel(modelData);
      console.log('✅ Modèle créé avec succès');
      
      setModelDialogOpen(false);
      resetModelForm();
    } catch (error) {
      console.error('❌ Erreur lors de la création du modèle:', error);
    }
  };

  const handleUpdateModel = async () => {
    if (selectedModel) {
      try {
        // Trouver le nom de la marque à partir de l'ID
        const selectedBrand = allBrands.find(brand => brand.id === newModel.brandId);
        const brandName = selectedBrand ? selectedBrand.name : newModel.brandId;
        
        // Trouver le nom de la catégorie à partir de l'ID
        const selectedCategory = defaultCategories.find(cat => cat.id === newModel.categoryId);
        const categoryType = selectedCategory ? selectedCategory.name.toLowerCase() : 'smartphone';
        
        const updateData = {
          brand: brandName,
          model: newModel.name, // Le champ 'name' du formulaire correspond au 'model' de la base
          type: categoryType as any,
          year: newModel.year,
          specifications: newModel.specifications,
          commonIssues: newModel.commonIssues.filter((issue: string) => issue.trim() !== ''),
          repairDifficulty: newModel.repairDifficulty,
          partsAvailability: newModel.partsAvailability,
          isActive: newModel.isActive,
        };

        console.log('📤 Mise à jour du modèle avec les données:', updateData);
        
        await updateDeviceModel(selectedModel.id, updateData);
        console.log('✅ Modèle mis à jour avec succès');
        
        setModelDialogOpen(false);
        setSelectedModel(null);
        resetModelForm();
      } catch (error) {
        console.error('❌ Erreur lors de la mise à jour du modèle:', error);
      }
    }
  };

  const resetModelForm = () => {
    setNewModel({
      name: '', // Le champ 'name' du formulaire
      brand: '',
      brandId: '',
      categoryId: dbCategories.length > 0 ? dbCategories[0].id : '',
      type: 'smartphone',
      year: new Date().getFullYear(),
      specifications: {},
      commonIssues: [''],
      repairDifficulty: 'medium',
      partsAvailability: 'medium',
      isActive: true,
    });
  };

  const openModelEditDialog = (model: DeviceModel) => {
    setSelectedModel(model);
    
    // Trouver l'ID de la marque à partir du nom
    const brandId = allBrands.find(brand => brand.name === model.brand)?.id || '';
    
    // Trouver l'ID de la catégorie à partir du type
    const categoryId = defaultCategories.find(cat => cat.name.toLowerCase() === model.type)?.id || '';
    
    setNewModel({
      name: model.model, // Le champ 'model' de la base correspond au 'name' du formulaire
      brand: model.brand,
      brandId: brandId,
      categoryId: categoryId,
      type: model.type,
      year: model.year,
      specifications: model.specifications,
      commonIssues: [...model.commonIssues],
      repairDifficulty: model.repairDifficulty,
      partsAvailability: model.partsAvailability,
      isActive: model.isActive,
    });
    setModelDialogOpen(true);
  };



  // Fonction de suppression générique
  const handleDelete = async () => {
    if (itemToDelete) {
      try {
        switch (deleteType) {
          case 'category':
            const result = await categoryService.delete(itemToDelete.id);
            if (result.success) {
              console.log('✅ Catégorie supprimée avec succès');
              
              // Recharger les catégories depuis la base de données
              const categoriesResult = await categoryService.getAll();
              if (categoriesResult.success && categoriesResult.data) {
                setDbCategories(categoriesResult.data);
                console.log('✅ Catégories rechargées après suppression:', categoriesResult.data.length);
              }
            } else {
              console.error('❌ Erreur lors de la suppression de la catégorie:', result.error);
              setCategoriesError(result.error || 'Erreur lors de la suppression de la catégorie');
            }
            break;
          case 'brand':
            // Vérifier si c'est une marque hardcodée (ID non-UUID)
            const isHardcodedBrand = !itemToDelete.id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
            
            if (isHardcodedBrand) {
              console.log('⚠️ Tentative de suppression d\'une marque hardcodée:', itemToDelete.id);
              alert('Impossible de supprimer les marques prédéfinies.');
              setDeleteDialogOpen(false);
              setItemToDelete(null);
              setDeleteType(null);
              return;
            }
            
            try {
              const result = await brandService.delete(itemToDelete.id);
              if (result.success) {
                console.log('✅ Marque supprimée avec succès');
                
                // Recharger les marques depuis la base de données
                const brandsResult = await brandService.getAll();
                if (brandsResult.success && brandsResult.data) {
                  setDbBrands(brandsResult.data);
                  console.log('✅ Marques rechargées après suppression:', brandsResult.data.length);
                }
              } else {
                console.error('❌ Erreur lors de la suppression de la marque:', result.error);
                alert('Erreur lors de la suppression: ' + (result.error || 'Erreur inconnue'));
              }
            } catch (error) {
              console.error('❌ Erreur lors de la suppression de la marque:', error);
              alert('Erreur lors de la suppression: ' + error);
            }
            break;
          case 'model':
            deleteDeviceModel(itemToDelete.id);
            break;
        }
        setDeleteDialogOpen(false);
        setItemToDelete(null);
      } catch (error) {
        console.error('❌ Erreur lors de la suppression:', error);
        setCategoriesError('Erreur lors de la suppression');
      }
    }
  };

  const openDeleteDialog = (item: any, type: 'category' | 'brand' | 'model') => {
    setItemToDelete(item);
    setDeleteType(type);
    setDeleteDialogOpen(true);
  };

  // Filtrage des données
  const filteredCategories = defaultCategories.filter(cat =>
    cat.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Combiner les marques de la base de données avec les marques hardcodées (fallback)
  // Mais d'abord, corriger les categoryId des marques hardcodées pour qu'ils correspondent aux catégories existantes
  const correctedDefaultBrands = defaultBrands.map(brand => {
    // Mapper les anciens IDs vers les nouveaux UUIDs des catégories
    let correctedCategoryId = brand.categoryId;
    let categories: DeviceCategory[] = [];
    
    if (defaultCategories.length > 0) {
      // Mapping basé sur l'ordre des catégories (smartphone=0, tablet=1, laptop=2, desktop=3, etc.)
      const categoryMapping: { [key: string]: number } = {
        '1': 0, // Smartphone
        '2': 1, // Tablette  
        '3': 2, // Ordinateur portable
        '4': 3, // Ordinateur fixe
        '5': 4, // Autre
      };
      
      const categoryIndex = categoryMapping[brand.categoryId] || 0;
      if (defaultCategories[categoryIndex]) {
        correctedCategoryId = defaultCategories[categoryIndex].id;
        categories = [defaultCategories[categoryIndex]]; // Pour le nouveau système
      } else {
        correctedCategoryId = defaultCategories[0].id; // Fallback vers la première catégorie
        categories = [defaultCategories[0]];
      }
    }
    
    return {
      ...brand,
      categoryId: correctedCategoryId,
      categoryIds: categories.map(cat => cat.id),
      categories: categories
    };
  });

  const allBrands = [...dbBrands, ...correctedDefaultBrands.filter(brand => 
    !dbBrands.some(dbBrand => dbBrand.name === brand.name)
  )];

  const filteredBrands = allBrands.filter(brand => {
    const matchesSearch = brand.name.toLowerCase().includes(searchQuery.toLowerCase());
    
    // Vérifier si la marque appartient à la catégorie sélectionnée
    let matchesCategory = true;
    if (selectedCategoryForBrands !== 'all') {
      if (brand.categories && brand.categories.length > 0) {
        // Nouveau système : vérifier si une des catégories correspond
        matchesCategory = brand.categories.some(cat => cat.id === selectedCategoryForBrands);
      } else {
        // Ancien système : vérifier l'ancien categoryId
        matchesCategory = brand.categoryId === selectedCategoryForBrands;
      }
    }
    
    return matchesSearch && matchesCategory;
  });

  const filteredModels = deviceModels.filter(model => {
    const modelName = (model as any).name || (model as any).model || 'N/A';
    return modelName.toLowerCase().includes(searchQuery.toLowerCase());
  });



  // Fonction pour obtenir les informations d'un modèle
  const getModelInfo = (modelId: string) => {
    const model = deviceModels.find(m => m.id === modelId);
    if (!model) return { name: 'N/A', brand: 'N/A', category: 'N/A' };
    
    // Utiliser la nouvelle structure des modèles
    const modelName = (model as any).name || (model as any).model || 'N/A';
    const brandName = (model as any).brand || 'N/A';
    const categoryName = (model as any).type || 'N/A';
    
    return {
      name: modelName,
      brand: brandName,
      category: categoryName,
    };
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Gestion des Appareils et Modèles
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gestion centralisée des catégories, marques, modèles et instances d'appareils
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

      {/* Barre de recherche et filtres */}
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
        
        {mainTab === 1 && (
          <FormControl sx={{ minWidth: 200 }}>
            <InputLabel>Filtrer par catégorie</InputLabel>
            <Select
              value={selectedCategoryForBrands}
              label="Filtrer par catégorie"
              onChange={(e) => setSelectedCategoryForBrands(e.target.value)}
            >
              <MenuItem value="all">Toutes les catégories</MenuItem>
              {deviceCategories.map((category) => (
                <MenuItem key={category.id} value={category.id}>
                  {category.name}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        )}
        

        
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
                            width: 48,
                            height: 48,
                          }}
                        >
                          {getDeviceTypeIcon(category.icon)}
                        </Avatar>
                        <Box sx={{ flexGrow: 1 }}>
                          <Typography variant="h6">{category.name}</Typography>
                          <Typography variant="body2" color="text.secondary">
                            {category.description}
                          </Typography>
                          <Chip
                            label={getDeviceTypeLabel(category.icon)}
                            size="small"
                            sx={{ 
                              mt: 0.5,
                              bgcolor: getDeviceTypeColor(category.icon),
                              color: 'white',
                              fontSize: '0.7rem'
                            }}
                          />
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
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6">
                Marques ({filteredBrands.length})
              </Typography>
              <Box sx={{ display: 'flex', gap: 1 }}>
                {defaultCategories.map((category) => {
                  const brandCount = allBrands.filter(brand => {
                    if (brand.categories && brand.categories.length > 0) {
                      // Nouveau système : vérifier si une des catégories correspond
                      return brand.categories.some(cat => cat.id === category.id);
                    } else {
                      // Ancien système : vérifier l'ancien categoryId
                      return brand.categoryId === category.id;
                    }
                  }).length;
                  return (
                    <Chip
                      key={category.id}
                      label={`${category.name}: ${brandCount}`}
                      size="small"
                      color={selectedCategoryForBrands === category.id ? 'primary' : 'default'}
                      onClick={() => setSelectedCategoryForBrands(
                        selectedCategoryForBrands === category.id ? 'all' : category.id
                      )}
                      sx={{ cursor: 'pointer' }}
                    />
                  );
                })}
              </Box>
            </Box>
            <TableContainer component={Paper} variant="outlined">
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Marque</TableCell>
                    <TableCell>Catégorie</TableCell>
                    <TableCell>Description</TableCell>
                    <TableCell>Modèles</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredBrands.map((brand) => {
                    const category = defaultCategories.find(cat => cat.id === brand.categoryId);
                    const modelCount = deviceModels.filter(model => (model as any).brand === brand.name).length;
                    
                    console.log('🔍 Debug marque:', {
                      brandName: brand.name,
                      brandCategoryId: brand.categoryId,
                      foundCategory: category?.name || 'NON TROUVÉE',
                      availableCategories: defaultCategories.map(c => ({ id: c.id, name: c.name }))
                    });
                    return (
                      <TableRow key={brand.id} hover>
                        <TableCell>
                          <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                            {brand.name}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                            {brand.categories && brand.categories.length > 0 ? (
                              brand.categories.map((cat, index) => (
                                <Chip
                                  key={cat.id || index}
                                  label={cat.name}
                                  size="small"
                                  sx={{
                                    bgcolor: getDeviceTypeColor(cat.icon),
                                    color: 'white',
                                    fontSize: '0.7rem'
                                  }}
                                />
                              ))
                            ) : (
                              <Chip
                                label="N/A"
                                size="small"
                                sx={{
                                  bgcolor: '#9e9e9e',
                                  color: 'white',
                                  fontSize: '0.7rem'
                                }}
                              />
                            )}
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" color="text.secondary">
                            {brand.description}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={modelCount}
                            size="small"
                            color={modelCount > 0 ? 'success' : 'default'}
                            variant={modelCount > 0 ? 'filled' : 'outlined'}
                          />
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
                    );
                  })}
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
                          {(model as any).name || (model as any).model || 'N/A'}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        {(model as any).brand || 'N/A'}
                      </TableCell>
                      <TableCell>
                        {(model as any).type || 'N/A'}
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
              <Typography variant="subtitle2" gutterBottom>
                Sélectionner une icône pour la catégorie
              </Typography>
              <Box sx={{ 
                display: 'grid', 
                gridTemplateColumns: 'repeat(auto-fill, minmax(120px, 1fr))', 
                gap: 1,
                maxHeight: 300,
                overflowY: 'auto',
                border: 1,
                borderColor: 'divider',
                borderRadius: 1,
                p: 1
              }}>
                {availableIcons.map((iconData) => (
                  <Box
                    key={iconData.value}
                    onClick={() => setNewCategory(prev => ({ ...prev, icon: iconData.value }))}
                    sx={{
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      p: 1,
                      borderRadius: 1,
                      cursor: 'pointer',
                      border: newCategory.icon === iconData.value ? 2 : 1,
                      borderColor: newCategory.icon === iconData.value ? 'primary.main' : 'divider',
                      bgcolor: newCategory.icon === iconData.value ? 'primary.50' : 'transparent',
                      '&:hover': {
                        bgcolor: 'action.hover',
                      },
                      transition: 'all 0.2s',
                    }}
                  >
                    <Avatar sx={{ bgcolor: iconData.color, width: 40, height: 40, mb: 1 }}>
                      {getDeviceTypeIcon(iconData.value)}
                    </Avatar>
                    <Typography variant="caption" textAlign="center" sx={{ fontSize: '0.7rem' }}>
                      {iconData.label}
                    </Typography>
                  </Box>
                ))}
              </Box>
              <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                Icône sélectionnée : {getDeviceTypeLabel(newCategory.icon)}
              </Typography>
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
          {selectedBrand ? 
            (selectedBrand.id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i) ? 
              'Modifier la marque' : 
              'Modifier les catégories de la marque prédéfinie'
            ) : 
            'Créer une nouvelle marque'
          }
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
                disabled={selectedBrand && !selectedBrand.id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)}
                helperText={selectedBrand && !selectedBrand.id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i) ? "Marque prédéfinie - nom non modifiable" : ""}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Catégories *</InputLabel>
                <Select
                  multiple
                  value={newBrand.categoryIds}
                  label="Catégories *"
                  onChange={(e) => setNewBrand(prev => ({ 
                    ...prev, 
                    categoryIds: typeof e.target.value === 'string' ? e.target.value.split(',') : e.target.value
                  }))}
                  required
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {(selected as string[]).map((value) => {
                        const category = defaultCategories.find(cat => cat.id === value);
                        return (
                          <Chip
                            key={value}
                            label={category?.name || value}
                            size="small"
                            sx={{
                              bgcolor: getDeviceTypeColor(category?.icon || 'other'),
                              color: 'white',
                              fontSize: '0.7rem'
                            }}
                          />
                        );
                      })}
                    </Box>
                  )}
                >
                  {defaultCategories.map((category) => (
                    <MenuItem key={category.id} value={category.id}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Avatar sx={{ 
                          bgcolor: getDeviceTypeColor(category.icon), 
                          width: 24, 
                          height: 24 
                        }}>
                          {getDeviceTypeIcon(category.icon)}
                        </Avatar>
                        {category.name}
                      </Box>
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
                disabled={selectedBrand && !selectedBrand.id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)}
                helperText={selectedBrand && !selectedBrand.id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i) ? "Marque prédéfinie - description non modifiable" : ""}
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
            disabled={!newBrand.name || newBrand.categoryIds.length === 0}
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
                onChange={(e) => setNewModel((prev: any) => ({ ...prev, name: e.target.value }))}
                required
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth>
                <InputLabel>Marque *</InputLabel>
                <Select
                  value={newModel.brandId}
                  label="Marque *"
                  onChange={(e) => setNewModel((prev: any) => ({ ...prev, brandId: e.target.value }))}
                  required
                >
                  {allBrands.map((brand) => (
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
                  {defaultCategories.map((category) => (
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

export default DeviceManagement;
