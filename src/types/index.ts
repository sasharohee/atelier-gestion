// Types de base
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
  createdAt: Date;
  updatedAt: Date;
}

export interface Device {
  id: string;
  brand: string;
  model: string;
  serialNumber?: string;
  type: 'smartphone' | 'tablet' | 'laptop' | 'desktop' | 'other';
  specifications?: Record<string, any>;
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
  clientId: string;
  deviceId: string;
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
  tax: number;
  total: number;
  paymentMethod: 'cash' | 'card' | 'transfer';
  status: 'pending' | 'completed' | 'cancelled';
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
