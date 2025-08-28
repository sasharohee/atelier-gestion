import React, { useState, useEffect } from 'react';
import { useAppStore } from '../../store';
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
import { DeviceCategory, DeviceBrand, DeviceModel } from '../../types/deviceManagement';
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
    categoryId: '',
    description: '',
    logo: '',
    isActive: true,
  });

  // États pour les modèles
  const [modelDialogOpen, setModelDialogOpen] = useState(false);
  const [selectedModel, setSelectedModel] = useState<DeviceModel | null>(null);
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
  const [selectedCategoryForBrands, setSelectedCategoryForBrands] = useState<string>('all');

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

  // Liste des icônes disponibles pour les catégories (icônes sûres et testées)
  const availableIcons = [
    { value: 'smartphone', label: 'Smartphone', icon: <PhoneIcon />, color: '#2196f3' },
    { value: 'tablet', label: 'Tablette', icon: <TabletIcon />, color: '#9c27b0' },
    { value: 'laptop', label: 'Ordinateur portable', icon: <LaptopIcon />, color: '#ff9800' },
    { value: 'desktop', label: 'Ordinateur fixe', icon: <ComputerIcon />, color: '#4caf50' },
    { value: 'watch', label: 'Montre connectée', icon: <WatchIcon />, color: '#e91e63' },
    { value: 'headphones', label: 'Casque audio', icon: <HeadphonesIcon />, color: '#795548' },
    { value: 'camera', label: 'Appareil photo', icon: <CameraIcon />, color: '#607d8b' },
    { value: 'tv', label: 'Télévision', icon: <TvIcon />, color: '#3f51b5' },
    { value: 'speaker', label: 'Haut-parleur', icon: <SpeakerIcon />, color: '#8bc34a' },
    { value: 'keyboard', label: 'Clavier', icon: <KeyboardIcon />, color: '#ff5722' },
    { value: 'mouse', label: 'Souris', icon: <MouseIcon />, color: '#9e9e9e' },
    { value: 'router', label: 'Routeur', icon: <RouterIcon />, color: '#00bcd4' },
    { value: 'memory', label: 'Mémoire', icon: <MemoryIcon />, color: '#673ab7' },
    { value: 'storage', label: 'Stockage', icon: <StorageIcon />, color: '#ffc107' },
    { value: 'battery', label: 'Batterie', icon: <BatteryIcon />, color: '#4caf50' },
    { value: 'wifi', label: 'Wi-Fi', icon: <WifiIcon />, color: '#2196f3' },
    { value: 'bluetooth', label: 'Bluetooth', icon: <BluetoothIcon />, color: '#3f51b5' },
    { value: 'usb', label: 'USB', icon: <UsbIcon />, color: '#ff9800' },
    { value: 'power', label: 'Alimentation', icon: <PowerIcon />, color: '#f44336' },
    { value: 'security', label: 'Sécurité', icon: <SecurityIcon />, color: '#e91e63' },
    { value: 'speed', label: 'Performance', icon: <SpeedIcon />, color: '#00bcd4' },
    { value: 'sdcard', label: 'Carte SD', icon: <SdCardIcon />, color: '#795548' },
    { value: 'simcard', label: 'Carte SIM', icon: <SimCardIcon />, color: '#607d8b' },
    { value: 'network', label: 'Réseau', icon: <NetworkIcon />, color: '#3f51b5' },
    { value: 'signal', label: 'Signal', icon: <SignalIcon />, color: '#4caf50' },
    { value: 'gps', label: 'GPS', icon: <GpsIcon />, color: '#2196f3' },
    { value: 'sensors', label: 'Capteurs', icon: <SensorsIcon />, color: '#9c27b0' },
    { value: 'flash', label: 'Flash', icon: <FlashIcon />, color: '#ffc107' },
    { value: 'volume', label: 'Volume', icon: <VolumeIcon />, color: '#ff9800' },
    { value: 'mic', label: 'Microphone', icon: <MicIcon />, color: '#795548' },
    { value: 'videocam', label: 'Caméra vidéo', icon: <VideocamIcon />, color: '#e91e63' },
    { value: 'photocamera', label: 'Appareil photo', icon: <PhotoCameraIcon />, color: '#607d8b' },
    { value: 'print', label: 'Imprimante', icon: <PrintIcon />, color: '#9e9e9e' },
    { value: 'scanner', label: 'Scanner', icon: <ScannerIcon />, color: '#795548' },
    { value: 'fax', label: 'Fax', icon: <FaxIcon />, color: '#607d8b' },
    { value: 'monitor', label: 'Écran', icon: <MonitorIcon />, color: '#3f51b5' },
    { value: 'display', label: 'Affichage', icon: <DisplayIcon />, color: '#2196f3' },
    { value: 'brightness', label: 'Luminosité', icon: <BrightnessIcon />, color: '#ffc107' },
    { value: 'contrast', label: 'Contraste', icon: <ContrastIcon />, color: '#9e9e9e' },
    { value: 'color', label: 'Couleur', icon: <ColorIcon />, color: '#e91e63' },
    { value: 'hdr', label: 'HDR', icon: <HdrIcon />, color: '#ff9800' },
    { value: 'autoawesome', label: 'Auto', icon: <AutoAwesomeIcon />, color: '#4caf50' },
    { value: 'quality', label: 'Qualité', icon: <QualityIcon />, color: '#2196f3' },
    { value: 'surround', label: 'Surround', icon: <SurroundIcon />, color: '#3f51b5' },
    { value: 'subscriptions', label: 'Abonnements', icon: <SubscriptionsIcon />, color: '#e91e63' },
    { value: 'livetv', label: 'TV en direct', icon: <LiveTvIcon />, color: '#f44336' },
    { value: 'music', label: 'Musique', icon: <MusicIcon />, color: '#9c27b0' },
    { value: 'radio', label: 'Radio', icon: <RadioIcon />, color: '#ff9800' },
    { value: 'podcasts', label: 'Podcasts', icon: <PodcastsIcon />, color: '#795548' },
    { value: 'audiotrack', label: 'Piste audio', icon: <AudiotrackIcon />, color: '#607d8b' },
    { value: 'equalizer', label: 'Égaliseur', icon: <EqualizerIcon />, color: '#3f51b5' },
    { value: 'graphiceq', label: 'Graphic EQ', icon: <GraphicEqIcon />, color: '#2196f3' },
    { value: 'volumeoff', label: 'Volume off', icon: <VolumeOffIcon />, color: '#9e9e9e' },
    { value: 'volumedown', label: 'Volume bas', icon: <VolumeDownIcon />, color: '#ff9800' },
    { value: 'bluetoothaudio', label: 'Audio Bluetooth', icon: <BluetoothAudioIcon />, color: '#3f51b5' },
    { value: 'airplay', label: 'AirPlay', icon: <AirplayIcon />, color: '#2196f3' },
    { value: 'cast', label: 'Cast', icon: <CastIcon />, color: '#ff5722' },
    { value: 'screenshare', label: 'Partage écran', icon: <ScreenShareIcon />, color: '#00bcd4' },
    { value: 'connectedtv', label: 'TV connectée', icon: <ConnectedTvIcon />, color: '#673ab7' },
    { value: 'smartdisplay', label: 'Écran intelligent', icon: <SmartDisplayIcon />, color: '#4caf50' },
    { value: 'videocall', label: 'Appel vidéo', icon: <VideoCallIcon />, color: '#e91e63' },
    { value: 'videochat', label: 'Chat vidéo', icon: <VideoChatIcon />, color: '#2196f3' },
    { value: 'videosettings', label: 'Paramètres vidéo', icon: <VideoSettingsIcon />, color: '#3f51b5' },
    { value: 'videostable', label: 'Stabilisation vidéo', icon: <VideoStableIcon />, color: '#ff9800' },
    { value: 'videofile', label: 'Fichier vidéo', icon: <VideoFileIcon />, color: '#795548' },
    { value: 'videolabel', label: 'Label vidéo', icon: <VideoLabelIcon />, color: '#607d8b' },
    { value: 'other', label: 'Autre', icon: <DeviceHubIcon />, color: '#757575' },
  ];

  // Fonctions utilitaires
  const getDeviceTypeIcon = (icon: string) => {
    const iconData = availableIcons.find(i => i.value === icon);
    return iconData ? iconData.icon : <DeviceHubIcon />;
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
  const handleCreateCategory = () => {
    addDeviceCategory({
      name: newCategory.name,
      description: newCategory.description,
      icon: newCategory.icon,
      isActive: newCategory.isActive,
    });
    setCategoryDialogOpen(false);
    resetCategoryForm();
  };

  const handleUpdateCategory = () => {
    if (selectedCategory) {
      updateDeviceCategory(selectedCategory.id, {
        name: newCategory.name,
        description: newCategory.description,
        icon: newCategory.icon,
        isActive: newCategory.isActive,
      });
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
  const handleCreateBrand = () => {
    addDeviceBrand({
      name: newBrand.name,
      categoryId: newBrand.categoryId,
      description: newBrand.description,
      logo: newBrand.logo,
      isActive: newBrand.isActive,
    });
    setBrandDialogOpen(false);
    resetBrandForm();
  };

  const handleUpdateBrand = () => {
    if (selectedBrand) {
      updateDeviceBrand(selectedBrand.id, {
        name: newBrand.name,
        categoryId: newBrand.categoryId,
        description: newBrand.description,
        logo: newBrand.logo,
        isActive: newBrand.isActive,
      });
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

  const openBrandEditDialog = (brand: DeviceBrand) => {
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
    addDeviceModel({
      name: newModel.name,
      brandId: newModel.brandId,
      categoryId: newModel.categoryId,
      year: newModel.year,
      commonIssues: newModel.commonIssues.filter(issue => issue.trim() !== ''),
      repairDifficulty: newModel.repairDifficulty,
      partsAvailability: newModel.partsAvailability,
      isActive: newModel.isActive,
    });
    setModelDialogOpen(false);
    resetModelForm();
  };

  const handleUpdateModel = () => {
    if (selectedModel) {
      updateDeviceModel(selectedModel.id, {
        name: newModel.name,
        brandId: newModel.brandId,
        categoryId: newModel.categoryId,
        year: newModel.year,
        commonIssues: newModel.commonIssues.filter(issue => issue.trim() !== ''),
        repairDifficulty: newModel.repairDifficulty,
        partsAvailability: newModel.partsAvailability,
        isActive: newModel.isActive,
      });
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

  const openModelEditDialog = (model: DeviceModel) => {
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
          deleteDeviceCategory(itemToDelete.id);
          break;
        case 'brand':
          deleteDeviceBrand(itemToDelete.id);
          break;
        case 'model':
          deleteDeviceModel(itemToDelete.id);
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
  const filteredCategories = deviceCategories.filter(cat =>
    cat.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredBrands = deviceBrands.filter(brand => {
    const matchesSearch = brand.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategoryForBrands === 'all' || brand.categoryId === selectedCategoryForBrands;
    return matchesSearch && matchesCategory;
  });

  const filteredModels = deviceModels.filter(model =>
    model.name.toLowerCase().includes(searchQuery.toLowerCase())
  );



  // Fonction pour obtenir les informations d'un modèle
  const getModelInfo = (modelId: string) => {
    const model = deviceModels.find(m => m.id === modelId);
    if (!model) return { name: 'N/A', brand: 'N/A', category: 'N/A' };
    
    const brand = deviceBrands.find(b => b.id === model.brandId);
    const category = deviceCategories.find(c => c.id === model.categoryId);
    
    return {
      name: model.name,
      brand: brand?.name || 'N/A',
      category: category?.name || 'N/A',
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
                {deviceCategories.map((category) => {
                  const brandCount = deviceBrands.filter(brand => brand.categoryId === category.id).length;
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
                    const category = deviceCategories.find(cat => cat.id === brand.categoryId);
                    const modelCount = deviceModels.filter(model => model.brandId === brand.id).length;
                    return (
                      <TableRow key={brand.id} hover>
                        <TableCell>
                          <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                            {brand.name}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={category?.name || 'N/A'}
                            size="small"
                            sx={{
                              bgcolor: category ? getDeviceTypeColor(category.icon) : '#9e9e9e',
                              color: 'white',
                              fontSize: '0.7rem'
                            }}
                          />
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
                          {model.name}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        {deviceBrands.find(brand => brand.id === model.brandId)?.name || 'N/A'}
                      </TableCell>
                      <TableCell>
                        {deviceCategories.find(cat => cat.id === model.categoryId)?.name || 'N/A'}
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
                      {iconData.icon}
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
                  {deviceCategories.map((category) => (
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
                  {deviceBrands.map((brand) => (
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
                  {deviceCategories.map((category) => (
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
