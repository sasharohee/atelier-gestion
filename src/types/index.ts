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
