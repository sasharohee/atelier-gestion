// =====================================================
// MISE À JOUR DES TYPES TYPESCRIPT POUR LES NOUVELLES FONCTIONNALITÉS
// =====================================================

// Types pour les nouvelles fonctionnalités
export type RepairDifficulty = 'easy' | 'medium' | 'hard';
export type PartsAvailability = 'high' | 'medium' | 'low';
export type AlertSeverity = 'info' | 'warning' | 'error' | 'critical';
export type ReportStatus = 'pending' | 'processing' | 'completed' | 'failed';
export type TransactionType = 'repair' | 'sale' | 'refund' | 'deposit' | 'withdrawal';
export type TransactionStatus = 'pending' | 'completed' | 'cancelled' | 'refunded';
export type PaymentMethod = 'cash' | 'card' | 'transfer' | 'check' | 'payment_link';

// Interface pour les modèles d'appareils
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
  repairDifficulty: RepairDifficulty;
  partsAvailability: PartsAvailability;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Interface pour les métriques de performance
export interface PerformanceMetric {
  id: string;
  metricName: string;
  metricValue: number;
  metricUnit?: string;
  periodStart: Date;
  periodEnd: Date;
  category?: string;
  createdAt: Date;
}

// Interface pour les rapports
export interface Report {
  id: string;
  reportName: string;
  reportType: string;
  parameters: Record<string, any>;
  generatedBy: string;
  filePath?: string;
  fileSize?: number;
  status: ReportStatus;
  createdAt: Date;
  completedAt?: Date;
}

// Interface pour les alertes avancées
export interface AdvancedAlert {
  id: string;
  alertType: string;
  title: string;
  message: string;
  severity: AlertSeverity;
  targetUserId?: string;
  targetRole?: UserRole;
  isRead: boolean;
  actionRequired: boolean;
  actionUrl?: string;
  expiresAt?: Date;
  createdAt: Date;
}

// Interface pour les métriques de performance des techniciens
export interface TechnicianPerformance {
  id: string;
  technicianId: string;
  periodStart: Date;
  periodEnd: Date;
  totalRepairs: number;
  completedRepairs: number;
  failedRepairs: number;
  avgRepairTime?: number; // en jours
  totalRevenue: number;
  customerSatisfaction?: number; // score de 0 à 5
  createdAt: Date;
  updatedAt: Date;
}

// Interface pour les transactions
export interface Transaction {
  id: string;
  transactionType: TransactionType;
  referenceId?: string;
  referenceType: string;
  amount: number;
  currency: string;
  status: TransactionStatus;
  clientId?: string;
  technicianId?: string;
  paymentMethod?: PaymentMethod;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Interface pour les logs d'activité
export interface ActivityLog {
  id: string;
  userId?: string;
  action: string;
  entityType: string;
  entityId?: string;
  oldValues?: Record<string, any>;
  newValues?: Record<string, any>;
  ipAddress?: string;
  userAgent?: string;
  createdAt: Date;
}

// Interface pour les paramètres avancés
export interface AdvancedSetting {
  id: string;
  settingKey: string;
  settingValue: any;
  settingType: string;
  description?: string;
  isSystem: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Interface pour les statistiques consolidées
export interface ConsolidatedStatistics {
  date: Date;
  totalRepairs: number;
  completedRepairs: number;
  urgentRepairs: number;
  overdueRepairs: number;
  totalRevenue: number;
  avgRepairTime: number;
}

// Interface pour les top clients
export interface TopClient {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  repairCount: number;
  totalSpent: number;
  avgRepairCost: number;
}

// Interface pour les top appareils
export interface TopDevice {
  id: string;
  brand: string;
  model: string;
  type: DeviceType;
  repairCount: number;
  totalRevenue: number;
  avgRepairCost: number;
}

// Mise à jour de l'interface Repair existante
export interface Repair {
  id: string;
  clientId: string;
  deviceId: string;
  description: string;
  issue?: string;
  status: string;
  estimatedDuration?: number;
  isUrgent: boolean;
  totalPrice: number;
  dueDate: Date;
  services: any[];
  parts: any[];
  isPaid: boolean;
  assignedTechnicianId?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Mise à jour de l'interface User existante
export interface User {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  role: UserRole;
  avatar?: string;
  createdAt: Date;
}

// Types pour les nouvelles fonctionnalités de l'interface
export interface StatisticsFilters {
  period: 'week' | 'month' | 'quarter' | 'year';
  deviceType: string;
  technicianId?: string;
  clientId?: string;
}

export interface ChartData {
  name: string;
  value: number;
  color?: string;
  percentage?: number;
}

export interface DashboardWidget {
  id: string;
  type: 'repairs' | 'revenue' | 'performance' | 'alerts';
  title: string;
  data: any;
  position: { x: number; y: number };
  size: { width: number; height: number };
}

// Types pour les nouvelles fonctionnalités de navigation
export interface NavigationItem {
  text: string;
  icon: React.ReactNode;
  path: string;
  subItems?: NavigationSubItem[];
}

export interface NavigationSubItem {
  text: string;
  path: string;
  icon?: React.ReactNode;
}

// Types pour les nouvelles fonctionnalités de formulaire
export interface ModelFormData {
  brand: string;
  model: string;
  type: DeviceType;
  year: number;
  specifications: {
    screen: string;
    processor: string;
    ram: string;
    storage: string;
    battery: string;
    os: string;
  };
  commonIssues: string[];
  repairDifficulty: RepairDifficulty;
  partsAvailability: PartsAvailability;
}

// Types pour les nouvelles fonctionnalités d'export
export interface ExportOptions {
  format: 'pdf' | 'excel' | 'csv';
  dateRange: {
    start: Date;
    end: Date;
  };
  includeCharts: boolean;
  includeTables: boolean;
}

// Types pour les nouvelles fonctionnalités de notification
export interface NotificationSettings {
  emailNotifications: boolean;
  pushNotifications: boolean;
  alertTypes: string[];
  frequency: 'immediate' | 'daily' | 'weekly';
}

// Mise à jour du store pour inclure les nouvelles fonctionnalités
export interface AppStore {
  // ... existing properties ...
  
  // Nouvelles propriétés pour les modèles
  deviceModels: DeviceModel[];
  
  // Nouvelles propriétés pour les statistiques
  performanceMetrics: PerformanceMetric[];
  consolidatedStatistics: ConsolidatedStatistics[];
  topClients: TopClient[];
  topDevices: TopDevice[];
  
  // Nouvelles propriétés pour les alertes
  advancedAlerts: AdvancedAlert[];
  
  // Nouvelles propriétés pour les rapports
  reports: Report[];
  
  // Nouvelles propriétés pour les transactions
  transactions: Transaction[];
  
  // Nouvelles propriétés pour les paramètres
  advancedSettings: AdvancedSetting[];
  
  // Nouvelles propriétés pour les logs
  activityLogs: ActivityLog[];
  
  // Nouvelles méthodes
  getDeviceModels: () => DeviceModel[];
  addDeviceModel: (model: Omit<DeviceModel, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  updateDeviceModel: (id: string, updates: Partial<DeviceModel>) => Promise<void>;
  deleteDeviceModel: (id: string) => Promise<void>;
  
  getPerformanceMetrics: (filters?: StatisticsFilters) => PerformanceMetric[];
  getConsolidatedStatistics: (filters?: StatisticsFilters) => ConsolidatedStatistics[];
  getTopClients: (limit?: number) => TopClient[];
  getTopDevices: (limit?: number) => TopDevice[];
  
  getAdvancedAlerts: () => AdvancedAlert[];
  markAlertAsRead: (id: string) => Promise<void>;
  createAlert: (alert: Omit<AdvancedAlert, 'id' | 'createdAt'>) => Promise<void>;
  
  getReports: () => Report[];
  generateReport: (reportType: string, parameters: Record<string, any>) => Promise<void>;
  
  getTransactions: () => Transaction[];
  createTransaction: (transaction: Omit<Transaction, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  
  getAdvancedSettings: () => AdvancedSetting[];
  updateSetting: (key: string, value: any) => Promise<void>;
  
  getActivityLogs: () => ActivityLog[];
  logActivity: (log: Omit<ActivityLog, 'id' | 'createdAt'>) => Promise<void>;
}

// Types pour les nouvelles fonctionnalités de composant
export interface StatisticsProps {
  filters?: StatisticsFilters;
  onFilterChange?: (filters: StatisticsFilters) => void;
  onExport?: (options: ExportOptions) => void;
}

export interface ModelsProps {
  onModelSelect?: (model: DeviceModel) => void;
  onModelCreate?: (model: ModelFormData) => void;
  onModelUpdate?: (id: string, updates: Partial<ModelFormData>) => void;
  onModelDelete?: (id: string) => void;
}

export interface AlertProps {
  alert: AdvancedAlert;
  onRead?: (id: string) => void;
  onAction?: (alert: AdvancedAlert) => void;
}

// Types pour les nouvelles fonctionnalités de service
export interface StatisticsService {
  getMetrics: (filters?: StatisticsFilters) => Promise<PerformanceMetric[]>;
  getConsolidatedStats: (filters?: StatisticsFilters) => Promise<ConsolidatedStatistics[]>;
  getTopClients: (limit?: number) => Promise<TopClient[]>;
  getTopDevices: (limit?: number) => Promise<TopDevice[]>;
  exportData: (options: ExportOptions) => Promise<string>;
}

export interface ModelsService {
  getModels: () => Promise<DeviceModel[]>;
  createModel: (model: Omit<DeviceModel, 'id' | 'createdAt' | 'updatedAt'>) => Promise<DeviceModel>;
  updateModel: (id: string, updates: Partial<DeviceModel>) => Promise<DeviceModel>;
  deleteModel: (id: string) => Promise<void>;
}

export interface AlertsService {
  getAlerts: () => Promise<AdvancedAlert[]>;
  markAsRead: (id: string) => Promise<void>;
  createAlert: (alert: Omit<AdvancedAlert, 'id' | 'createdAt'>) => Promise<AdvancedAlert>;
  deleteAlert: (id: string) => Promise<void>;
}

export interface ReportsService {
  getReports: () => Promise<Report[]>;
  generateReport: (reportType: string, parameters: Record<string, any>) => Promise<Report>;
  downloadReport: (id: string) => Promise<Blob>;
  deleteReport: (id: string) => Promise<void>;
}

export interface TransactionsService {
  getTransactions: () => Promise<Transaction[]>;
  createTransaction: (transaction: Omit<Transaction, 'id' | 'createdAt' | 'updatedAt'>) => Promise<Transaction>;
  updateTransaction: (id: string, updates: Partial<Transaction>) => Promise<Transaction>;
  deleteTransaction: (id: string) => Promise<void>;
}

// Types pour les nouvelles fonctionnalités de hook
export interface UseStatisticsReturn {
  metrics: PerformanceMetric[];
  consolidatedStats: ConsolidatedStatistics[];
  topClients: TopClient[];
  topDevices: TopDevice[];
  loading: boolean;
  error: string | null;
  refresh: () => void;
  exportData: (options: ExportOptions) => Promise<void>;
}

export interface UseModelsReturn {
  models: DeviceModel[];
  loading: boolean;
  error: string | null;
  createModel: (model: ModelFormData) => Promise<void>;
  updateModel: (id: string, updates: Partial<ModelFormData>) => Promise<void>;
  deleteModel: (id: string) => Promise<void>;
}

export interface UseAlertsReturn {
  alerts: AdvancedAlert[];
  unreadCount: number;
  loading: boolean;
  error: string | null;
  markAsRead: (id: string) => Promise<void>;
  createAlert: (alert: Omit<AdvancedAlert, 'id' | 'createdAt'>) => Promise<void>;
}

// Types pour les nouvelles fonctionnalités de validation
export interface ModelValidationSchema {
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
  repairDifficulty: RepairDifficulty;
  partsAvailability: PartsAvailability;
}

export interface StatisticsValidationSchema {
  period: 'week' | 'month' | 'quarter' | 'year';
  deviceType: string;
  technicianId?: string;
  clientId?: string;
}

// Types pour les nouvelles fonctionnalités de configuration
export interface AppConfig {
  statistics: {
    refreshInterval: number;
    defaultPeriod: 'week' | 'month' | 'quarter' | 'year';
    maxDataPoints: number;
  };
  alerts: {
    retentionDays: number;
    maxAlertsPerUser: number;
    autoCleanup: boolean;
  };
  reports: {
    maxFileSize: number;
    allowedFormats: string[];
    autoCleanup: boolean;
  };
  performance: {
    trackingEnabled: boolean;
    metricsRetentionDays: number;
    autoCalculation: boolean;
  };
}

// Export de tous les types
export type {
  RepairDifficulty,
  PartsAvailability,
  AlertSeverity,
  ReportStatus,
  TransactionType,
  TransactionStatus,
  PaymentMethod,
  DeviceModel,
  PerformanceMetric,
  Report,
  AdvancedAlert,
  TechnicianPerformance,
  Transaction,
  ActivityLog,
  AdvancedSetting,
  ConsolidatedStatistics,
  TopClient,
  TopDevice,
  StatisticsFilters,
  ChartData,
  DashboardWidget,
  NavigationItem,
  NavigationSubItem,
  ModelFormData,
  ExportOptions,
  NotificationSettings,
  AppStore,
  StatisticsProps,
  ModelsProps,
  AlertProps,
  StatisticsService,
  ModelsService,
  AlertsService,
  ReportsService,
  TransactionsService,
  UseStatisticsReturn,
  UseModelsReturn,
  UseAlertsReturn,
  ModelValidationSchema,
  StatisticsValidationSchema,
  AppConfig
};
