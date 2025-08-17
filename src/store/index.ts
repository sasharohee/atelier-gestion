import { create } from 'zustand';
import { devtools } from 'zustand/middleware';
import {
  User,
  Client,
  Device,
  Service,
  Part,
  Product,
  Repair,
  RepairStatus,
  Message,
  Appointment,
  Sale,
  StockAlert,
  Notification,
  DashboardStats,
  RepairFilters
} from '../types';

interface AppState {
  // État utilisateur
  currentUser: User | null;
  isAuthenticated: boolean;
  
  // Données principales
  clients: Client[];
  devices: Device[];
  services: Service[];
  parts: Part[];
  products: Product[];
  repairs: Repair[];
  repairStatuses: RepairStatus[];
  messages: Message[];
  appointments: Appointment[];
  sales: Sale[];
  stockAlerts: StockAlert[];
  notifications: Notification[];
  
  // Filtres et recherche
  repairFilters: RepairFilters;
  searchQuery: string;
  
  // Statistiques
  dashboardStats: DashboardStats | null;
  
  // UI State
  sidebarOpen: boolean;
  currentPage: string;
  loading: boolean;
  error: string | null;
}

interface AppActions {
  // Authentification
  setCurrentUser: (user: User | null) => void;
  setAuthenticated: (authenticated: boolean) => void;
  
  // CRUD Operations
  addClient: (client: Client) => void;
  updateClient: (id: string, updates: Partial<Client>) => void;
  deleteClient: (id: string) => void;
  
  addDevice: (device: Device) => void;
  updateDevice: (id: string, updates: Partial<Device>) => void;
  deleteDevice: (id: string) => void;
  
  addService: (service: Service) => void;
  updateService: (id: string, updates: Partial<Service>) => void;
  deleteService: (id: string) => void;
  
  addPart: (part: Part) => void;
  updatePart: (id: string, updates: Partial<Part>) => void;
  deletePart: (id: string) => void;
  
  addProduct: (product: Product) => void;
  updateProduct: (id: string, updates: Partial<Product>) => void;
  deleteProduct: (id: string) => void;
  
  addRepair: (repair: Repair) => void;
  updateRepair: (id: string, updates: Partial<Repair>) => void;
  deleteRepair: (id: string) => void;
  
  addMessage: (message: Message) => void;
  updateMessage: (id: string, updates: Partial<Message>) => void;
  deleteMessage: (id: string) => void;
  
  addAppointment: (appointment: Appointment) => void;
  updateAppointment: (id: string, updates: Partial<Appointment>) => void;
  deleteAppointment: (id: string) => void;
  
  addSale: (sale: Sale) => void;
  updateSale: (id: string, updates: Partial<Sale>) => void;
  deleteSale: (id: string) => void;
  
  // Filtres et recherche
  setRepairFilters: (filters: RepairFilters) => void;
  setSearchQuery: (query: string) => void;
  
  // Statistiques
  setDashboardStats: (stats: DashboardStats) => void;
  
  // UI Actions
  toggleSidebar: () => void;
  setCurrentPage: (page: string) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  
  // Actions spéciales
  markMessageAsRead: (id: string) => void;
  markNotificationAsRead: (id: string) => void;
  resolveStockAlert: (id: string) => void;
  
  // Getters
  getRepairsByStatus: (statusId: string) => Repair[];
  getClientById: (id: string) => Client | undefined;
  getDeviceById: (id: string) => Device | undefined;
  getServiceById: (id: string) => Service | undefined;
  getPartById: (id: string) => Part | undefined;
  getProductById: (id: string) => Product | undefined;
  getRepairById: (id: string) => Repair | undefined;
  getUnreadMessagesCount: () => number;
  getUnreadNotificationsCount: () => number;
  getActiveStockAlerts: () => StockAlert[];
}

type AppStore = AppState & AppActions;

export const useAppStore = create<AppStore>()(
  devtools(
    (set, get) => ({
      // État initial
      currentUser: null,
      isAuthenticated: false,
      
      clients: [],
      devices: [],
      services: [],
      parts: [],
      products: [],
      repairs: [],
      repairStatuses: [],
      messages: [],
      appointments: [],
      sales: [],
      stockAlerts: [],
      notifications: [],
      
      repairFilters: {},
      searchQuery: '',
      
      dashboardStats: null,
      
      sidebarOpen: true,
      currentPage: 'dashboard',
      loading: false,
      error: null,
      
      // Actions d'authentification
      setCurrentUser: (user) => set({ currentUser: user }),
      setAuthenticated: (authenticated) => set({ isAuthenticated: authenticated }),
      
      // CRUD Operations
      addClient: (client) => set((state) => ({ clients: [...state.clients, client] })),
      updateClient: (id, updates) => set((state) => ({
        clients: state.clients.map(client => 
          client.id === id ? { ...client, ...updates, updatedAt: new Date() } : client
        )
      })),
      deleteClient: (id) => set((state) => ({
        clients: state.clients.filter(client => client.id !== id)
      })),
      
      addDevice: (device) => set((state) => ({ devices: [...state.devices, device] })),
      updateDevice: (id, updates) => set((state) => ({
        devices: state.devices.map(device => 
          device.id === id ? { ...device, ...updates, updatedAt: new Date() } : device
        )
      })),
      deleteDevice: (id) => set((state) => ({
        devices: state.devices.filter(device => device.id !== id)
      })),
      
      addService: (service) => set((state) => ({ services: [...state.services, service] })),
      updateService: (id, updates) => set((state) => ({
        services: state.services.map(service => 
          service.id === id ? { ...service, ...updates, updatedAt: new Date() } : service
        )
      })),
      deleteService: (id) => set((state) => ({
        services: state.services.filter(service => service.id !== id)
      })),
      
      addPart: (part) => set((state) => ({ parts: [...state.parts, part] })),
      updatePart: (id, updates) => set((state) => ({
        parts: state.parts.map(part => 
          part.id === id ? { ...part, ...updates, updatedAt: new Date() } : part
        )
      })),
      deletePart: (id) => set((state) => ({
        parts: state.parts.filter(part => part.id !== id)
      })),
      
      addProduct: (product) => set((state) => ({ products: [...state.products, product] })),
      updateProduct: (id, updates) => set((state) => ({
        products: state.products.map(product => 
          product.id === id ? { ...product, ...updates, updatedAt: new Date() } : product
        )
      })),
      deleteProduct: (id) => set((state) => ({
        products: state.products.filter(product => product.id !== id)
      })),
      
      addRepair: (repair) => set((state) => ({ repairs: [...state.repairs, repair] })),
      updateRepair: (id, updates) => set((state) => ({
        repairs: state.repairs.map(repair => 
          repair.id === id ? { ...repair, ...updates, updatedAt: new Date() } : repair
        )
      })),
      deleteRepair: (id) => set((state) => ({
        repairs: state.repairs.filter(repair => repair.id !== id)
      })),
      
      addMessage: (message) => set((state) => ({ messages: [...state.messages, message] })),
      updateMessage: (id, updates) => set((state) => ({
        messages: state.messages.map(message => 
          message.id === id ? { ...message, ...updates } : message
        )
      })),
      deleteMessage: (id) => set((state) => ({
        messages: state.messages.filter(message => message.id !== id)
      })),
      
      addAppointment: (appointment) => set((state) => ({ appointments: [...state.appointments, appointment] })),
      updateAppointment: (id, updates) => set((state) => ({
        appointments: state.appointments.map(appointment => 
          appointment.id === id ? { ...appointment, ...updates, updatedAt: new Date() } : appointment
        )
      })),
      deleteAppointment: (id) => set((state) => ({
        appointments: state.appointments.filter(appointment => appointment.id !== id)
      })),
      
      addSale: (sale) => set((state) => ({ sales: [...state.sales, sale] })),
      updateSale: (id, updates) => set((state) => ({
        sales: state.sales.map(sale => 
          sale.id === id ? { ...sale, ...updates, updatedAt: new Date() } : sale
        )
      })),
      deleteSale: (id) => set((state) => ({
        sales: state.sales.filter(sale => sale.id !== id)
      })),
      
      // Filtres et recherche
      setRepairFilters: (filters) => set({ repairFilters: filters }),
      setSearchQuery: (query) => set({ searchQuery: query }),
      
      // Statistiques
      setDashboardStats: (stats) => set({ dashboardStats: stats }),
      
      // UI Actions
      toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
      setCurrentPage: (page) => set({ currentPage: page }),
      setLoading: (loading) => set({ loading }),
      setError: (error) => set({ error }),
      
      // Actions spéciales
      markMessageAsRead: (id) => set((state) => ({
        messages: state.messages.map(message => 
          message.id === id ? { ...message, isRead: true } : message
        )
      })),
      
      markNotificationAsRead: (id) => set((state) => ({
        notifications: state.notifications.map(notification => 
          notification.id === id ? { ...notification, isRead: true } : notification
        )
      })),
      
      resolveStockAlert: (id) => set((state) => ({
        stockAlerts: state.stockAlerts.map(alert => 
          alert.id === id ? { ...alert, isResolved: true } : alert
        )
      })),
      
      // Getters
      getRepairsByStatus: (statusId) => {
        const state = get();
        return state.repairs.filter(repair => repair.status === statusId);
      },
      
      getClientById: (id) => {
        const state = get();
        return state.clients.find(client => client.id === id);
      },
      
      getDeviceById: (id) => {
        const state = get();
        return state.devices.find(device => device.id === id);
      },
      
      getServiceById: (id) => {
        const state = get();
        return state.services.find(service => service.id === id);
      },
      
      getPartById: (id) => {
        const state = get();
        return state.parts.find(part => part.id === id);
      },
      
      getProductById: (id) => {
        const state = get();
        return state.products.find(product => product.id === id);
      },
      
      getRepairById: (id) => {
        const state = get();
        return state.repairs.find(repair => repair.id === id);
      },
      
      getUnreadMessagesCount: () => {
        const state = get();
        return state.messages.filter(message => !message.isRead).length;
      },
      
      getUnreadNotificationsCount: () => {
        const state = get();
        return state.notifications.filter(notification => !notification.isRead).length;
      },
      
      getActiveStockAlerts: () => {
        const state = get();
        return state.stockAlerts.filter(alert => !alert.isResolved);
      },
    }),
    {
      name: 'atelier-store',
    }
  )
);
