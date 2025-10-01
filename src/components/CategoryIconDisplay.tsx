import React from 'react';
import {
  Phone as PhoneIcon,
  Tablet as TabletIcon,
  Laptop as LaptopIcon,
  Computer as ComputerIcon,
  Watch as WatchIcon,
  Headphones as HeadphonesIcon,
  CameraAlt as CameraIcon,
  Tv as TvIcon,
  Speaker as SpeakerIcon,
  Keyboard as KeyboardIcon,
  Mouse as MouseIcon,
  Router as RouterIcon,
  Smartphone as SmartphoneIcon,
  Gamepad as GamepadIcon,
  Memory as MemoryIcon,
  Storage as StorageIcon,
  Bluetooth as BluetoothIcon,
  Wifi as WifiIcon,
  BatteryFull as BatteryIcon,
  Usb as UsbIcon,
  Cable as CableIcon,
  Power as PowerIcon,
  VolumeUp as VolumeIcon,
  Mic as MicIcon,
  Videocam as VideocamIcon,
  ScreenShare as ScreenShareIcon,
  Print as PrintIcon,
  Scanner as ScannerIcon,
  Fax as FaxIcon,
  SmartToy as SmartToyIcon,
  Home as HomeIcon,
  CarRepair as CarRepairIcon,
  Construction as ConstructionIcon,
  MedicalServices as MedicalIcon,
  School as SchoolIcon,
  Business as BusinessIcon,
  SportsEsports as SportsIcon,
  MusicNote as MusicIcon,
  Palette as PaletteIcon,
  FitnessCenter as FitnessIcon,
  Restaurant as RestaurantIcon,
  LocalHospital as HospitalIcon,
  Security as SecurityIcon,
  Lock as LockIcon,
  Visibility as VisibilityIcon,
  Hearing as HearingIcon,
  Accessibility as AccessibilityIcon,
  ChildCare as ChildIcon,
  Pets as PetsIcon,
  Nature as NatureIcon,
  BeachAccess as BeachIcon,
  Pool as PoolIcon,
  AcUnit as AcIcon,
  LocalFireDepartment as FireIcon,
  WbSunny as SunIcon,
  Cloud as CloudIcon,
  WaterDrop as WaterIcon,
  ElectricBolt as ElectricIcon,
  Plumbing as PlumbingIcon,
  Build as BuildIcon,
  Handyman as HandymanIcon,
  Engineering as EngineeringIcon,
  Science as ScienceIcon,
  Biotech as BiotechIcon,
  Psychology as PsychologyIcon,
  AutoFixHigh as AutoFixIcon,
  PrecisionManufacturing as PrecisionIcon,
  Factory as FactoryIcon,
  Inventory as InventoryIcon,
  Category as CategoryIcon
} from '@mui/icons-material';

interface CategoryIconDisplayProps {
  iconType: string;
  size?: number;
  color?: string;
}

const CategoryIconDisplay: React.FC<CategoryIconDisplayProps> = ({ 
  iconType, 
  size = 24, 
  color = 'inherit' 
}) => {
  const iconMap: { [key: string]: React.ReactElement } = {
    // Téléphonie et Communication
    'smartphone': <SmartphoneIcon sx={{ fontSize: size, color }} />,
    'phone': <PhoneIcon sx={{ fontSize: size, color }} />,
    'tablet': <TabletIcon sx={{ fontSize: size, color }} />,
    'laptop': <LaptopIcon sx={{ fontSize: size, color }} />,
    'computer': <ComputerIcon sx={{ fontSize: size, color }} />,
    'watch': <WatchIcon sx={{ fontSize: size, color }} />,
    'router': <RouterIcon sx={{ fontSize: size, color }} />,
    'bluetooth': <BluetoothIcon sx={{ fontSize: size, color }} />,
    'wifi': <WifiIcon sx={{ fontSize: size, color }} />,
    
    // Audio et Vidéo
    'headphones': <HeadphonesIcon sx={{ fontSize: size, color }} />,
    'speaker': <SpeakerIcon sx={{ fontSize: size, color }} />,
    'volume': <VolumeIcon sx={{ fontSize: size, color }} />,
    'mic': <MicIcon sx={{ fontSize: size, color }} />,
    'camera': <CameraIcon sx={{ fontSize: size, color }} />,
    'videocam': <VideocamIcon sx={{ fontSize: size, color }} />,
    'tv': <TvIcon sx={{ fontSize: size, color }} />,
    'screen': <ScreenShareIcon sx={{ fontSize: size, color }} />,
    
    // Périphériques
    'keyboard': <KeyboardIcon sx={{ fontSize: size, color }} />,
    'mouse': <MouseIcon sx={{ fontSize: size, color }} />,
    'usb': <UsbIcon sx={{ fontSize: size, color }} />,
    'cable': <CableIcon sx={{ fontSize: size, color }} />,
    'power': <PowerIcon sx={{ fontSize: size, color }} />,
    'battery': <BatteryIcon sx={{ fontSize: size, color }} />,
    
    // Gaming et Divertissement
    'gaming': <GamepadIcon sx={{ fontSize: size, color }} />,
    
    // Mémoire et Stockage
    'memory': <MemoryIcon sx={{ fontSize: size, color }} />,
    'storage': <StorageIcon sx={{ fontSize: size, color }} />,
    
    // Imprimantes et Scan
    'printer': <PrintIcon sx={{ fontSize: size, color }} />,
    'scanner': <ScannerIcon sx={{ fontSize: size, color }} />,
    
    // Outils et Réparation
    'build': <BuildIcon sx={{ fontSize: size, color }} />,
    'handyman': <HandymanIcon sx={{ fontSize: size, color }} />,
    'engineering': <EngineeringIcon sx={{ fontSize: size, color }} />,
    'auto-fix': <AutoFixIcon sx={{ fontSize: size, color }} />,
    'precision': <PrecisionIcon sx={{ fontSize: size, color }} />,
    'factory': <FactoryIcon sx={{ fontSize: size, color }} />,
    
    // Par défaut
    'category': <CategoryIcon sx={{ fontSize: size, color }} />,
    'inventory': <InventoryIcon sx={{ fontSize: size, color }} />,
  };

  return iconMap[iconType] || <CategoryIcon sx={{ fontSize: size, color }} />;
};

export default CategoryIconDisplay;
