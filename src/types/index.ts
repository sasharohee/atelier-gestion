// Types de base
export interface SystemSetting {
  id: string;
  key: string;
  value: string;
  description?: string;
  category: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface User {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  role: 'admin' | 'technician' | 'manager';
  avatar?: string;
  createdAt: Date;
}

export interface Client {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address?: string;
  notes?: string;
  
  // Nouveaux champs pour les informations personnelles et entreprise
  category?: string;
  title?: string;
  companyName?: string;
  vatNumber?: string;
  sirenNumber?: string;
  countryCode?: string;
  
  // Nouveaux champs pour l'adresse détaillée
  addressComplement?: string;
  region?: string;
  postalCode?: string;
  city?: string;
  
  // Nouveaux champs pour l'adresse de facturation
  billingAddressSame?: boolean;
  billingAddress?: string;
  billingAddressComplement?: string;
  billingRegion?: string;
  billingPostalCode?: string;
  billingCity?: string;
  
  // Nouveaux champs pour les informations complémentaires
  accountingCode?: string;
  cniIdentifier?: string;
  attachedFilePath?: string;
  internalNote?: string;
  
  // Nouveaux champs pour les préférences
  status?: string;
  smsNotification?: boolean;
  emailNotification?: boolean;
  smsMarketing?: boolean;
  emailMarketing?: boolean;
  
  createdAt: Date;
  updatedAt: Date;
}

export type DeviceType = 'smartphone' | 'tablet' | 'laptop' | 'desktop' | 'other';

// Types pour les rachats d'appareils
export type BuybackStatus = 'pending' | 'accepted' | 'rejected' | 'paid';
export type DeviceCondition = 'excellent' | 'good' | 'fair' | 'poor' | 'broken';
export type PaymentMethod = 'cash' | 'transfer' | 'check' | 'credit';
export type BuybackReason = 'resale' | 'parts' | 'collection' | 'other';
export type IDType = 'cni' | 'passeport' | 'permis' | 'autre';

export interface Buyback {
  id: string;
  
  // Informations client vendeur
  clientFirstName: string;
  clientLastName: string;
  clientEmail: string;
  clientPhone: string;
  clientAddress?: string;
  clientAddressComplement?: string;
  clientPostalCode?: string;
  clientCity?: string;
  clientIdType?: IDType;
  clientIdNumber?: string;
  
  // Informations appareil
  deviceType: DeviceType;
  deviceBrand: string;
  deviceModel: string;
  deviceImei?: string;
  deviceSerialNumber?: string;
  deviceColor?: string;
  deviceStorageCapacity?: string;
  
  // État technique
  physicalCondition: DeviceCondition;
  functionalCondition: {
    powersOn?: boolean;
    touchWorks?: boolean;
    soundWorks?: boolean;
    camerasWork?: boolean;
    buttonsWork?: boolean;
  };
  batteryHealth?: number; // pourcentage 0-100
  screenCondition?: 'perfect' | 'minor_scratches' | 'major_scratches' | 'cracked' | 'broken';
  buttonCondition?: 'perfect' | 'sticky' | 'broken' | 'missing';
  
  // Blocages
  icloudLocked: boolean;
  googleLocked: boolean;
  carrierLocked: boolean;
  otherLocks?: string;
  
  // Accessoires inclus
  accessories: {
    charger?: boolean;
    cable?: boolean;
    headphones?: boolean;
    originalBox?: boolean;
    screenProtector?: boolean;
    case?: boolean;
    manual?: boolean;
  };
  
  // Informations commerciales
  suggestedPrice?: number;
  offeredPrice: number;
  finalPrice?: number;
  paymentMethod: PaymentMethod;
  buybackReason: BuybackReason;
  
  // Garantie
  hasWarranty: boolean;
  warrantyExpiresAt?: Date;
  
  // Photos et documents
  photos?: string[];
  documents?: string[];
  
  // Statut et notes
  status: BuybackStatus;
  internalNotes?: string;
  clientNotes?: string;
  
  // Conditions acceptées
  termsAccepted: boolean;
  termsAcceptedAt?: Date;
  
  // Métadonnées
  userId: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Device {
  id: string;
  brand: string;
  model: string;
  serialNumber?: string;
  type: DeviceType;
  specifications?: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

export interface DeviceModel {
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

export interface Service {
  id: string;
  name: string;
  description: string;
  duration: number; // en minutes
  price: number;
  category: string;
  applicableDevices: string[]; // IDs des types d'appareils
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Interfaces pour le système de pricing des rachats
export interface DeviceMarketPrice {
  id: string;
  deviceModelId?: string;
  deviceBrand: string;
  deviceModel: string;
  deviceType: DeviceType;
  pricesByCapacity: Record<string, number>; // {"64GB": 350, "128GB": 420}
  releaseYear?: number;
  marketSegment?: 'premium' | 'mid-range' | 'budget';
  baseMarketPrice?: number;
  currentMarketPrice?: number;
  depreciationRate: number; // Taux de dépréciation annuel (%)
  conditionMultipliers: Record<string, number>;
  screenConditionMultipliers: Record<string, number>;
  batteryHealthPenalty: number; // € par % de batterie manquante
  buttonConditionPenalty: Record<string, number>;
  functionalPenalties: Record<string, number>;
  accessoriesBonus: Record<string, number>;
  warrantyBonusPercentage: number; // % de bonus si garantie > 6 mois
  lockPenalties: Record<string, number>;
  isActive: boolean;
  lastPriceUpdate: Date;
  priceSource: 'manual' | 'api' | 'import';
  externalApiId?: string;
  userId: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface BuybackPricing {
  estimatedPrice: number;
  basePrice: number;
  breakdown: {
    basePrice: number;
    conditionMultiplier: number;
    screenMultiplier: number;
    batteryPenalty: number;
    buttonPenalty: number;
    functionalPenalty: number;
    accessoriesBonus: number;
    warrantyBonus: number;
    lockPenalty: number;
    finalPrice: number;
  };
}

export interface BuybackPricingInput {
  deviceBrand: string;
  deviceModel: string;
  deviceType: DeviceType;
  storageCapacity?: string;
  physicalCondition: DeviceCondition;
  batteryHealth?: number;
  screenCondition?: 'perfect' | 'minor_scratches' | 'major_scratches' | 'cracked' | 'broken';
  buttonCondition?: 'perfect' | 'sticky' | 'broken' | 'missing';
  functionalCondition: {
    powersOn?: boolean;
    touchWorks?: boolean;
    soundWorks?: boolean;
    camerasWork?: boolean;
    buttonsWork?: boolean;
  };
  accessories: {
    charger?: boolean;
    cable?: boolean;
    headphones?: boolean;
    originalBox?: boolean;
    screenProtector?: boolean;
    case?: boolean;
    manual?: boolean;
  };
  hasWarranty?: boolean;
  warrantyExpiresAt?: Date;
  icloudLocked?: boolean;
  googleLocked?: boolean;
  carrierLocked?: boolean;
}

export interface Part {
  id: string;
  name: string;
  description: string;
  partNumber: string;
  brand: string;
  compatibleDevices: string[]; // IDs des appareils compatibles
  stockQuantity: number;
  minStockLevel: number;
  price: number;
  supplier?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  category: string;
  price: number;
  stockQuantity: number;
  minStockLevel: number;
  isActive: boolean;
  barcode?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface RepairStatus {
  id: string;
  name: string;
  color: string;
  order: number;
}

export interface Repair {
  id: string;
  repairNumber?: string; // Numéro de réparation unique (ex: REP-20241201-1234)
  clientId: string;
  deviceId: string | null; // Peut être null si aucun appareil n'est sélectionné
  status: string; // ID du statut
  assignedTechnicianId?: string;
  description: string;
  issue: string;
  estimatedDuration: number; // en minutes
  actualDuration?: number;
  estimatedStartDate?: Date;
  estimatedEndDate?: Date;
  startDate?: Date;
  endDate?: Date;
  dueDate: Date;
  isUrgent: boolean;
  notes?: string;
  services: RepairService[];
  parts: RepairPart[];
  totalPrice: number;
  discountPercentage?: number;
  discountAmount?: number;
  originalPrice?: number;
  isPaid: boolean;
  source?: 'kanban' | 'sav' | 'sale'; // Source de création de la réparation
  createdAt: Date;
  updatedAt: Date;
}

export interface RepairService {
  id: string;
  serviceId: string;
  quantity: number;
  price: number;
}

export interface RepairPart {
  id: string;
  partId: string;
  quantity: number;
  price: number;
  isUsed: boolean;
}

export interface Message {
  id: string;
  senderId: string;
  recipientId: string;
  repairId?: string;
  subject: string;
  content: string;
  isRead: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface Appointment {
  id: string;
  userId?: string;
  clientId?: string;
  repairId?: string;
  title: string;
  description: string;
  startDate: Date;
  endDate: Date;
  assignedUserId?: string;
  status: 'scheduled' | 'confirmed' | 'completed' | 'cancelled';
  createdAt: Date;
  updatedAt: Date;
}

export interface Sale {
  id: string;
  clientId?: string;
  items: SaleItem[];
  subtotal: number;
  discountPercentage?: number;
  discountAmount?: number;
  originalTotal?: number;
  tax: number;
  total: number;
  paymentMethod: 'cash' | 'card' | 'transfer' | 'check' | 'payment_link';
  status: 'pending' | 'completed' | 'cancelled' | 'returned';
  createdAt: Date;
  updatedAt: Date;
}

export interface SaleItem {
  id: string;
  type: 'product' | 'service' | 'part';
  itemId: string;
  name: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

export interface StockAlert {
  id: string;
  partId: string;
  type: 'low_stock' | 'out_of_stock';
  message: string;
  isResolved: boolean;
  createdAt: Date;
}

export interface Notification {
  id: string;
  userId: string;
  type: 'repair_status' | 'appointment' | 'stock_alert' | 'message';
  title: string;
  message: string;
  isRead: boolean;
  relatedId?: string;
  createdAt: Date;
}

// Types pour les statistiques
export interface DashboardStats {
  totalRepairs: number;
  activeRepairs: number;
  completedRepairs: number;
  overdueRepairs: number;
  todayAppointments: number;
  monthlyRevenue: number;
  lowStockItems: number;
  pendingMessages: number;
}

export interface RepairStats {
  total: number;
  byStatus: Record<string, number>;
  byDeviceType: Record<string, number>;
  averageDuration: number;
  completionRate: number;
}

export interface RevenueStats {
  daily: number;
  weekly: number;
  monthly: number;
  yearly: number;
  byCategory: Record<string, number>;
}

// Types pour les filtres et recherche
export interface RepairFilters {
  status?: string;
  technicianId?: string;
  clientId?: string;
  deviceType?: string;
  dateRange?: {
    start: Date;
    end: Date;
  };
  isUrgent?: boolean;
}

export interface SearchFilters {
  query: string;
  type: 'repairs' | 'clients' | 'devices' | 'parts' | 'services';
  filters?: Record<string, any>;
}

// Types pour les paramètres utilisateur
export interface UserProfile {
  id?: string;
  user_id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone?: string;
  avatar?: string;
  created_at?: string;
  updated_at?: string;
}

export interface UserPreferences {
  id?: string;
  user_id: string;
  notifications_email: boolean;
  notifications_push: boolean;
  notifications_sms: boolean;
  theme_dark_mode: boolean;
  theme_compact_mode: boolean;
  language: string;
  two_factor_auth: boolean;
  multiple_sessions: boolean;
  repair_notifications: boolean;
  status_notifications: boolean;
  stock_notifications: boolean;
  daily_reports: boolean;
  created_at?: string;
  updated_at?: string;
}

// Types pour le système d'abonnement
export interface SubscriptionStatus {
  id: string;
  user_id: string;
  first_name: string;
  last_name: string;
  email: string;
  is_active: boolean;
  subscription_type: 'free' | 'premium' | 'enterprise';
  created_at: string;
  updated_at: string;
  activated_at?: string;
  activated_by?: string;
  notes?: string;
}

export interface SubscriptionPlan {
  id: string;
  name: string;
  type: 'free' | 'premium' | 'enterprise';
  price: number;
  currency: string;
  billing_cycle: 'monthly' | 'yearly';
  features: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Types pour les devis
export interface Quote {
  id: string;
  quoteNumber: string; // Numéro de devis unique généré aléatoirement
  clientId?: string;
  items: QuoteItem[];
  subtotal: number;
  tax: number;
  total: number;
  status: 'draft' | 'sent' | 'accepted' | 'rejected' | 'expired';
  validUntil: Date;
  notes?: string;
  terms?: string;
  // Nouveaux champs pour les devis de réparation
  isRepairQuote?: boolean;
  repairDetails?: {
    deviceId?: string;
    description: string;
    issue?: string;
    estimatedDuration?: number;
    estimatedStartDate?: Date;
    estimatedEndDate?: Date;
    isUrgent?: boolean;
  };
  createdAt: Date;
  updatedAt: Date;
}

export interface QuoteItem {
  id: string;
  type: 'product' | 'service' | 'part' | 'repair';
  itemId: string;
  name: string;
  description?: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

// Types pour les dépenses
export interface Expense {
  id: string;
  title: string;
  description?: string;
  amount: number;
  supplier?: string;
  invoiceNumber?: string;
  paymentMethod: 'cash' | 'card' | 'transfer' | 'check';
  status: 'pending' | 'paid' | 'cancelled';
  expenseDate: Date;
  dueDate?: Date;
  receiptPath?: string;
  tags?: string[];
  createdAt: Date;
  updatedAt: Date;
}

// ExpenseCategory - SUPPRIMÉ
// Les catégories ne sont plus utilisées pour les dépenses

export interface ExpenseStats {
  total: number;
  monthly: number;
  pending: number;
  paid: number;
}

// Types pour le SAV (Service Après-Vente)
export interface WorkTimer {
  id: string;
  repairId: string;
  startTime: Date;
  endTime?: Date;
  pausedTime?: number; // Temps total de pause en millisecondes
  totalDuration: number; // Durée totale en millisecondes
  isPaused: boolean;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface RepairLog {
  id: string;
  repairId: string;
  action: string;
  description?: string;
  userId: string;
  userName: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}

export type PrintTemplateType = 'label' | 'work_order' | 'deposit_receipt' | 'invoice' | 'complete_ticket';

export interface PrintTemplate {
  type: PrintTemplateType;
  data: {
    repair: Repair;
    client: Client;
    device?: Device | null;
    technician?: User | null;
    workshopInfo?: {
      name: string;
      address: string;
      phone: string;
      email: string;
    };
  };
}

export interface SAVStats {
  totalRepairs: number;
  newRepairs: number;
  inProgressRepairs: number;
  waitingPartsRepairs: number;
  completedRepairs: number;
  urgentRepairs: number;
  overdueRepairs: number;
  averageDuration: number; // en minutes
  completionRate: number; // en pourcentage
}

// Re-export des types pour les services par modèle
export * from './deviceModelService';

// Re-export des types comptables
export * from './accounting';
