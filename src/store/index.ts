import { create } from 'zustand';
import { devtools } from 'zustand/middleware';
import { v4 as uuidv4 } from 'uuid';
import {
  User,
  SystemSetting,
  UserProfile,
  UserPreferences,
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
import {
  userService,
  systemSettingsService,
  userSettingsService,
  clientService,
  deviceService,
  repairService,
  partService,
  productService,
  serviceService,
  saleService,
  appointmentService,
  dashboardService
} from '../services/supabaseService';

// Helper function to convert Supabase user to app user
const convertSupabaseUser = (supabaseUser: any): User => ({
  id: supabaseUser?.id || '',
  firstName: supabaseUser?.user_metadata?.firstName || '',
  lastName: supabaseUser?.user_metadata?.lastName || '',
  email: supabaseUser?.email || '',
  role: supabaseUser?.user_metadata?.role || 'technician',
  avatar: supabaseUser?.user_metadata?.avatar,
  createdAt: new Date(supabaseUser?.created_at || Date.now())
});

interface AppState {
  // État utilisateur
  currentUser: User | null;
  isAuthenticated: boolean;
  
  // Données principales
  users: User[];
  systemSettings: SystemSetting[];
  userProfile: UserProfile | null;
  userPreferences: UserPreferences | null;
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
  
  // Authentification avec Supabase
  signIn: (email: string, password: string) => Promise<{ success: boolean; data?: any; error?: string }>;
  signUp: (email: string, password: string, userData: Partial<User>) => Promise<{ success: boolean; data?: any; error?: string }>;
  signOut: () => Promise<{ success: boolean; data?: any; error?: string }>;
  checkAuth: () => Promise<{ success: boolean; data?: any; error?: string }>;
  
  // CRUD Operations avec Supabase
        addUser: (user: Omit<User, 'id' | 'createdAt' | 'updatedAt'> & { password: string }) => Promise<void>;
  updateUser: (id: string, updates: Partial<User>) => Promise<void>;
  deleteUser: (id: string) => Promise<void>;
  
  // Paramètres système
  loadSystemSettings: () => Promise<void>;
  updateSystemSetting: (key: string, value: string) => Promise<void>;
  updateMultipleSystemSettings: (settings: Array<{ key: string; value: string }>) => Promise<void>;
  
  // Paramètres utilisateur
  loadUserProfile: (userId: string) => Promise<void>;
  updateUserProfile: (userId: string, profile: Partial<UserProfile>) => Promise<void>;
  loadUserPreferences: (userId: string) => Promise<void>;
  updateUserPreferences: (userId: string, preferences: Partial<UserPreferences>) => Promise<void>;
  changePassword: (userId: string, oldPassword: string, newPassword: string) => Promise<void>;
  
  addClient: (client: Client) => Promise<void>;
  updateClient: (id: string, updates: Partial<Client>) => Promise<void>;
  deleteClient: (id: string) => Promise<void>;
  
  addDevice: (device: Device) => Promise<void>;
  updateDevice: (id: string, updates: Partial<Device>) => Promise<void>;
  deleteDevice: (id: string) => Promise<void>;
  
  addService: (service: Service) => Promise<void>;
  updateService: (id: string, updates: Partial<Service>) => Promise<void>;
  deleteService: (id: string) => Promise<void>;
  
  addPart: (part: Part) => Promise<void>;
  updatePart: (id: string, updates: Partial<Part>) => Promise<void>;
  deletePart: (id: string) => Promise<void>;
  
  addProduct: (product: Product) => Promise<void>;
  updateProduct: (id: string, updates: Partial<Product>) => Promise<void>;
  deleteProduct: (id: string) => Promise<void>;
  
  addRepair: (repair: Repair) => Promise<void>;
  updateRepair: (id: string, updates: Partial<Repair>) => Promise<void>;
  deleteRepair: (id: string) => Promise<void>;
  
  addMessage: (message: Omit<Message, 'id'>) => Promise<void>;
  updateMessage: (id: string, updates: Partial<Message>) => Promise<void>;
  deleteMessage: (id: string) => Promise<void>;
  
  addAppointment: (appointment: Omit<Appointment, 'id'>) => Promise<void>;
  updateAppointment: (id: string, updates: Partial<Appointment>) => Promise<void>;
  deleteAppointment: (id: string) => Promise<void>;
  
  addSale: (sale: Sale) => Promise<void>;
  updateSale: (id: string, updates: Partial<Sale>) => Promise<void>;
  deleteSale: (id: string) => Promise<void>;
  
  // Chargement des données depuis Supabase
  loadUsers: () => Promise<void>;
  loadClients: () => Promise<void>;
  loadDevices: () => Promise<void>;
  loadServices: () => Promise<void>;
  loadParts: () => Promise<void>;
  loadProducts: () => Promise<void>;
  loadRepairs: () => Promise<void>;
  loadSales: () => Promise<void>;
  loadAppointments: () => Promise<void>;
  
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
  markMessageAsRead: (id: string) => Promise<void>;
  markNotificationAsRead: (id: string) => Promise<void>;
  resolveStockAlert: (id: string) => Promise<void>;
  
  // Getters
  getRepairsByStatus: (statusId: string) => Repair[];
  getUserById: (id: string) => User | undefined;
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
      
      users: [],
      systemSettings: [],
      userProfile: null,
      userPreferences: null,
      clients: [],
      devices: [],
      services: [],
      parts: [],
      products: [],
      repairs: [],
      repairStatuses: [
        {
          id: 'new',
          name: 'Nouvelle',
          color: '#2196f3',
          order: 1,
        },
        {
          id: 'in_progress',
          name: 'En cours',
          color: '#ff9800',
          order: 2,
        },
        {
          id: 'waiting_parts',
          name: 'En attente de pièces',
          color: '#f44336',
          order: 3,
        },
        {
          id: 'waiting_delivery',
          name: 'Livraison attendue',
          color: '#9c27b0',
          order: 4,
        },
        {
          id: 'completed',
          name: 'Terminée',
          color: '#4caf50',
          order: 5,
        },
        {
          id: 'cancelled',
          name: 'Annulée',
          color: '#757575',
          order: 6,
        },
      ],
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
      
      // Authentification avec Supabase
      signIn: async (email: string, password: string) => {
        set({ loading: true, error: null });
        const result = await userService.signIn(email, password);
        if (result.success && 'data' in result && result.data) {
          const supabaseUser = result.data.user;
          if (supabaseUser) {
            const appUser: User = {
              id: supabaseUser.id,
              firstName: supabaseUser.user_metadata?.firstName || '',
              lastName: supabaseUser.user_metadata?.lastName || '',
              email: supabaseUser.email || '',
              role: supabaseUser.user_metadata?.role || 'technician',
              avatar: supabaseUser.user_metadata?.avatar,
              createdAt: new Date(supabaseUser.created_at)
            };
            set({ 
              currentUser: appUser, 
              isAuthenticated: true, 
              loading: false 
            });
          }
        } else if ('error' in result) {
          set({ 
            error: result.error, 
            loading: false 
          });
        }
        return result;
      },
      
      signUp: async (email: string, password: string, userData: Partial<User>) => {
        set({ loading: true, error: null });
        const result = await userService.signUp(email, password, userData);
        if (result.success && 'data' in result && result.data) {
          const supabaseUser = result.data.user;
          if (supabaseUser) {
            const appUser: User = {
              id: supabaseUser.id,
              firstName: supabaseUser.user_metadata?.firstName || '',
              lastName: supabaseUser.user_metadata?.lastName || '',
              email: supabaseUser.email || '',
              role: supabaseUser.user_metadata?.role || 'technician',
              avatar: supabaseUser.user_metadata?.avatar,
              createdAt: new Date(supabaseUser.created_at)
            };
            set({ 
              currentUser: appUser, 
              isAuthenticated: true, 
              loading: false 
            });
          }
        } else if ('error' in result) {
          set({ 
            error: result.error, 
            loading: false 
          });
        }
        return result;
      },
      
      signOut: async () => {
        set({ loading: true });
        const result = await userService.signOut();
        set({ 
          currentUser: null, 
          isAuthenticated: false, 
          loading: false 
        });
        return result;
      },
      
      checkAuth: async () => {
        const result = await userService.getCurrentUser();
        if (result.success && 'data' in result && result.data) {
          const supabaseUser = result.data;
          if (supabaseUser) {
            const appUser: User = {
              id: supabaseUser.id,
              firstName: supabaseUser.user_metadata?.firstName || '',
              lastName: supabaseUser.user_metadata?.lastName || '',
              email: supabaseUser.email || '',
              role: supabaseUser.user_metadata?.role || 'technician',
              avatar: supabaseUser.user_metadata?.avatar,
              createdAt: new Date(supabaseUser.created_at)
            };
            set({ 
              currentUser: appUser, 
              isAuthenticated: true 
            });
          }
        }
        return result;
      },
      
      // CRUD Operations avec Supabase
      addUser: async (user) => {
        try {
          const result = await userService.createUser(user);
          if (result.success && 'data' in result && result.data) {
            const newUser: User = {
              id: result.data.id,
              firstName: result.data.first_name,
              lastName: result.data.last_name,
              email: result.data.email,
              role: result.data.role,
              avatar: result.data.avatar,
              createdAt: new Date(result.data.created_at),
            };
            set((state) => ({ users: [...state.users, newUser] }));
          }
        } catch (error) {
          console.error('Erreur lors de l\'ajout de l\'utilisateur:', error);
          throw error;
        }
      },
      
      updateUser: async (id, updates) => {
        try {
          const result = await userService.updateUser(id, updates);
          if (result.success) {
            set((state) => ({
              users: state.users.map(user => 
                user.id === id ? { ...user, ...updates } : user
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour de l\'utilisateur:', error);
          throw error;
        }
      },
      
      deleteUser: async (id) => {
        try {
          const result = await userService.deleteUser(id);
          if (result.success) {
            set((state) => ({
              users: state.users.filter(user => user.id !== id)
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la suppression de l\'utilisateur:', error);
          throw error;
        }
      },
      
      // Paramètres système
      loadSystemSettings: async () => {
        try {
          console.log('🔄 Chargement des paramètres système...');
          set({ loading: true });
          
          const result = await systemSettingsService.getAll();
          console.log('📊 Résultat du chargement:', result);
          
          if (result.success && 'data' in result && result.data) {
            const transformedSettings = result.data.map((setting: any) => ({
              id: setting.id,
              key: setting.key,
              value: setting.value,
              description: setting.description,
              category: setting.category,
              createdAt: new Date(setting.created_at),
              updatedAt: new Date(setting.updated_at),
            }));
            console.log('✅ Paramètres système chargés:', transformedSettings);
            set({ systemSettings: transformedSettings, loading: false });
          } else {
            console.log('⚠️ Aucun paramètre système trouvé');
            set({ systemSettings: [], loading: false });
          }
        } catch (error) {
          console.error('❌ Erreur lors du chargement des paramètres système:', error);
          set({ systemSettings: [], loading: false, error: 'Erreur lors du chargement des paramètres' });
        }
      },
      
      updateSystemSetting: async (key, value) => {
        try {
          const result = await systemSettingsService.update(key, value);
          if (result.success) {
            set((state) => ({
              systemSettings: state.systemSettings.map(setting => 
                setting.key === key ? { ...setting, value, updatedAt: new Date() } : setting
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour du paramètre:', error);
          throw error;
        }
      },
      
      updateMultipleSystemSettings: async (settings) => {
        try {
          const result = await systemSettingsService.updateMultiple(settings);
          if (result.success) {
            set((state) => ({
              systemSettings: state.systemSettings.map(setting => {
                const update = settings.find(s => s.key === setting.key);
                return update ? { ...setting, value: update.value, updatedAt: new Date() } : setting;
              })
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour des paramètres:', error);
          throw error;
        }
      },
      
      // Paramètres utilisateur
      loadUserProfile: async (userId) => {
        try {
          const result = await userSettingsService.getUserProfile(userId);
          if (result.success && 'data' in result && result.data) {
            set({ userProfile: result.data });
          }
        } catch (error) {
          console.error('Erreur lors du chargement du profil utilisateur:', error);
          throw error;
        }
      },
      
      updateUserProfile: async (userId, profile) => {
        try {
          const result = await userSettingsService.updateUserProfile(userId, profile);
          if (result.success && 'data' in result && result.data) {
            set({ userProfile: result.data });
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour du profil utilisateur:', error);
          throw error;
        }
      },
      
      loadUserPreferences: async (userId) => {
        try {
          const result = await userSettingsService.getUserPreferences(userId);
          if (result.success && 'data' in result && result.data) {
            set({ userPreferences: result.data });
          } else {
            // Créer des préférences par défaut si aucune n'existe
            const defaultPreferences: UserPreferences = {
              user_id: userId,
              notifications_email: true,
              notifications_push: true,
              notifications_sms: false,
              theme_dark_mode: false,
              theme_compact_mode: false,
              language: 'fr',
              two_factor_auth: false,
              multiple_sessions: true,
              repair_notifications: true,
              status_notifications: true,
              stock_notifications: true,
              daily_reports: false,
            };
            set({ userPreferences: defaultPreferences });
          }
        } catch (error) {
          console.error('Erreur lors du chargement des préférences utilisateur:', error);
          throw error;
        }
      },
      
      updateUserPreferences: async (userId, preferences) => {
        try {
          const result = await userSettingsService.updateUserPreferences(userId, preferences);
          if (result.success && 'data' in result && result.data) {
            set({ userPreferences: result.data });
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour des préférences utilisateur:', error);
          throw error;
        }
      },
      
      changePassword: async (userId, oldPassword, newPassword) => {
        try {
          const result = await userSettingsService.changePassword(userId, oldPassword, newPassword);
          if (!result.success && 'error' in result) {
            throw new Error(result.error || 'Erreur lors du changement de mot de passe');
          }
        } catch (error) {
          console.error('Erreur lors du changement de mot de passe:', error);
          throw error;
        }
      },
      
      addClient: async (client) => {
        try {
          const result = await clientService.create(client);
          if (result.success && 'data' in result && result.data) {
            // Transformer les données de Supabase vers le format de l'application
            const transformedClient: Client = {
              id: result.data.id,
              firstName: result.data.first_name || result.data.firstName,
              lastName: result.data.last_name || result.data.lastName,
              email: result.data.email,
              phone: result.data.phone,
              address: result.data.address,
              notes: result.data.notes,
              createdAt: result.data.created_at ? new Date(result.data.created_at) : new Date(),
              updatedAt: result.data.updated_at ? new Date(result.data.updated_at) : new Date(),
            };
            set((state) => ({ clients: [...state.clients, transformedClient] }));
          }
        } catch (error) {
          console.error('Erreur lors de l\'ajout du client:', error);
          throw error;
        }
      },
      
      updateClient: async (id, updates) => {
        try {
          const result = await clientService.update(id, updates);
          if (result.success) {
            set((state) => ({
              clients: state.clients.map(client => 
                client.id === id ? { ...client, ...updates, updatedAt: new Date() } : client
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour du client:', error);
        }
      },
      
      deleteClient: async (id) => {
        try {
          const result = await clientService.delete(id);
          if (result.success) {
            set((state) => ({
              clients: state.clients.filter(client => client.id !== id)
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la suppression du client:', error);
        }
      },
      
      addDevice: async (device) => {
        try {
          const result = await deviceService.create(device);
          if (result.success && 'data' in result && result.data) {
            // Transformer les données de Supabase vers le format de l'application
            const transformedDevice: Device = {
              id: result.data.id,
              brand: result.data.brand,
              model: result.data.model,
              serialNumber: result.data.serial_number || result.data.serialNumber,
              type: result.data.type,
              specifications: result.data.specifications,
              createdAt: result.data.created_at ? new Date(result.data.created_at) : new Date(),
              updatedAt: result.data.updated_at ? new Date(result.data.updated_at) : new Date(),
            };
            set((state) => ({ devices: [...state.devices, transformedDevice] }));
          }
        } catch (error) {
          console.error('Erreur lors de l\'ajout de l\'appareil:', error);
          throw error;
        }
      },
      
      updateDevice: async (id, updates) => {
        try {
          const result = await deviceService.update(id, updates);
          if (result.success) {
            set((state) => ({
              devices: state.devices.map(device => 
                device.id === id ? { ...device, ...updates, updatedAt: new Date() } : device
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour de l\'appareil:', error);
        }
      },
      
      deleteDevice: async (id) => {
        try {
          const result = await deviceService.delete(id);
          if (result.success) {
            set((state) => ({
              devices: state.devices.filter(device => device.id !== id)
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la suppression de l\'appareil:', error);
        }
      },
      
      addService: async (service) => {
        try {
          const result = await serviceService.create(service);
          if (result.success) {
            set((state) => ({ services: [...state.services, service] }));
          }
        } catch (error) {
          console.error('Erreur lors de l\'ajout du service:', error);
        }
      },
      
      updateService: async (id, updates) => {
        try {
          const result = await serviceService.update(id, updates);
          if (result.success) {
            set((state) => ({
              services: state.services.map(service => 
                service.id === id ? { ...service, ...updates, updatedAt: new Date() } : service
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour du service:', error);
        }
      },
      
      deleteService: async (id) => {
        try {
          const result = await serviceService.delete(id);
          if (result.success) {
            set((state) => ({
              services: state.services.filter(service => service.id !== id)
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la suppression du service:', error);
        }
      },
      
      addPart: async (part) => {
        try {
          const result = await partService.create(part);
          if (result.success) {
            set((state) => ({ parts: [...state.parts, part] }));
          }
        } catch (error) {
          console.error('Erreur lors de l\'ajout de la pièce:', error);
        }
      },
      
      updatePart: async (id, updates) => {
        try {
          const result = await partService.update(id, updates);
          if (result.success) {
            set((state) => ({
              parts: state.parts.map(part => 
                part.id === id ? { ...part, ...updates, updatedAt: new Date() } : part
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour de la pièce:', error);
        }
      },
      
      deletePart: async (id) => {
        try {
          const result = await partService.delete(id);
          if (result.success) {
            set((state) => ({
              parts: state.parts.filter(part => part.id !== id)
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la suppression de la pièce:', error);
        }
      },
      
      addProduct: async (product) => {
        try {
          const result = await productService.create(product);
          if (result.success) {
            set((state) => ({ products: [...state.products, product] }));
          }
        } catch (error) {
          console.error('Erreur lors de l\'ajout du produit:', error);
        }
      },
      
      updateProduct: async (id, updates) => {
        try {
          const result = await productService.update(id, updates);
          if (result.success) {
            set((state) => ({
              products: state.products.map(product => 
                product.id === id ? { ...product, ...updates, updatedAt: new Date() } : product
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour du produit:', error);
        }
      },
      
      deleteProduct: async (id) => {
        try {
          const result = await productService.delete(id);
          if (result.success) {
            set((state) => ({
              products: state.products.filter(product => product.id !== id)
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la suppression du produit:', error);
        }
      },
      
      addRepair: async (repair) => {
        try {
          const result = await repairService.create(repair);
          if (result.success && 'data' in result && result.data) {
            // Transformer les données de Supabase vers le format de l'application
            const transformedRepair: Repair = {
              id: result.data.id,
              clientId: result.data.client_id,
              deviceId: result.data.device_id,
              status: result.data.status,
              assignedTechnicianId: result.data.assigned_technician_id,
              description: result.data.description,
              issue: result.data.issue || '',
              estimatedDuration: result.data.estimated_duration || 0,
              actualDuration: result.data.actual_duration,
              estimatedStartDate: result.data.estimated_start_date ? new Date(result.data.estimated_start_date) : undefined,
              estimatedEndDate: result.data.estimated_end_date ? new Date(result.data.estimated_end_date) : undefined,
              startDate: result.data.start_date ? new Date(result.data.start_date) : undefined,
              endDate: result.data.end_date ? new Date(result.data.end_date) : undefined,
              dueDate: result.data.due_date ? new Date(result.data.due_date) : new Date(),
              isUrgent: result.data.is_urgent || false,
              notes: result.data.notes,
              services: [], // Tableau vide par défaut
              parts: [], // Tableau vide par défaut
              totalPrice: result.data.total_price || 0,
              isPaid: result.data.is_paid || false,
              createdAt: result.data.created_at ? new Date(result.data.created_at) : new Date(),
              updatedAt: result.data.updated_at ? new Date(result.data.updated_at) : new Date(),
            };
            set((state) => ({ repairs: [...state.repairs, transformedRepair] }));
          }
        } catch (error) {
          console.error('Erreur lors de l\'ajout de la réparation:', error);
          throw error; // Propager l'erreur pour l'afficher à l'utilisateur
        }
      },
      
      updateRepair: async (id, updates) => {
        try {
          const result = await repairService.update(id, updates);
          if (result.success) {
            set((state) => ({
              repairs: state.repairs.map(repair => 
                repair.id === id ? { ...repair, ...updates, updatedAt: new Date() } : repair
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour de la réparation:', error);
        }
      },
      
      deleteRepair: async (id) => {
        try {
          const result = await repairService.delete(id);
          if (result.success) {
            set((state) => ({
              repairs: state.repairs.filter(repair => repair.id !== id)
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la suppression de la réparation:', error);
        }
      },
      
      addMessage: async (message) => {
        try {
          const messageWithId = { ...message, id: uuidv4() };
          set((state) => ({ 
            messages: [...state.messages, messageWithId] 
          }));
        } catch (error) {
          console.error('Erreur lors de l\'ajout du message:', error);
        }
      },
      
      updateMessage: async (id, updates) => {
        try {
          set((state) => ({
            messages: state.messages.map(message => 
              message.id === id ? { ...message, ...updates } : message
            )
          }));
        } catch (error) {
          console.error('Erreur lors de la mise à jour du message:', error);
        }
      },
      
      deleteMessage: async (id) => {
        try {
          set((state) => ({
            messages: state.messages.filter(message => message.id !== id)
          }));
        } catch (error) {
          console.error('Erreur lors de la suppression du message:', error);
        }
      },
      
      addAppointment: async (appointment) => {
        try {
          const appointmentWithId = { ...appointment, id: uuidv4() };
          const result = await appointmentService.create(appointmentWithId);
          if (result.success) {
            set((state) => ({ 
              appointments: [...state.appointments, appointmentWithId] 
            }));
          }
        } catch (error) {
          console.error('Erreur lors de l\'ajout du rendez-vous:', error);
        }
      },
      
      updateAppointment: async (id, updates) => {
        try {
          const result = await appointmentService.update(id, updates);
          if (result.success) {
            set((state) => ({
              appointments: state.appointments.map(appointment => 
                appointment.id === id ? { ...appointment, ...updates, updatedAt: new Date() } : appointment
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour du rendez-vous:', error);
        }
      },
      
      deleteAppointment: async (id) => {
        try {
          const result = await appointmentService.delete(id);
          if (result.success) {
            set((state) => ({
              appointments: state.appointments.filter(appointment => appointment.id !== id)
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la suppression du rendez-vous:', error);
        }
      },
      
      addSale: async (sale) => {
        try {
          // Générer un ID temporaire pour l'affichage immédiat
          const saleWithId = { ...sale, id: sale.id || uuidv4() };
          
          // Ajouter immédiatement au store local pour l'affichage
          set((state) => ({ sales: [saleWithId, ...state.sales] }));
          
          // Envoyer au backend en arrière-plan
          const result = await saleService.create(saleWithId);
          if (result.success && 'data' in result && result.data) {
            // Mettre à jour avec l'ID du backend si nécessaire
            set((state) => ({
              sales: state.sales.map(s => 
                s.id === saleWithId.id 
                  ? { ...s, id: result.data.id || s.id }
                  : s
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de l\'ajout de la vente:', error);
          // En cas d'erreur, on garde la vente en local
        }
      },
      
      updateSale: async (id, updates) => {
        try {
          const result = await saleService.update(id, updates);
          if (result.success) {
            set((state) => ({
              sales: state.sales.map(sale => 
                sale.id === id ? { ...sale, ...updates, updatedAt: new Date() } : sale
              )
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la mise à jour de la vente:', error);
        }
      },
      
      deleteSale: async (id) => {
        try {
          const result = await saleService.delete(id);
          if (result.success) {
            set((state) => ({
              sales: state.sales.filter(sale => sale.id !== id)
            }));
          }
        } catch (error) {
          console.error('Erreur lors de la suppression de la vente:', error);
        }
      },
      
      // Chargement des données depuis Supabase
      loadUsers: async () => {
        try {
          const result = await userService.getAllUsers();
          if (result.success && 'data' in result && result.data) {
            // Transformer les données de Supabase vers le format de l'application
            const transformedUsers = result.data.map((user: any) => ({
              id: user.id,
              firstName: user.first_name || user.firstName,
              lastName: user.last_name || user.lastName,
              email: user.email,
              role: user.role,
              avatar: user.avatar,
              createdAt: user.created_at ? new Date(user.created_at) : new Date(),
            }));
            set({ users: transformedUsers });
          }
        } catch (error) {
          console.error('Erreur lors du chargement des utilisateurs:', error);
          // En cas d'erreur, on garde les données existantes
        }
      },
      
      loadClients: async () => {
        try {
          const result = await clientService.getAll();
          if (result.success && 'data' in result && result.data) {
            // Transformer les données de Supabase vers le format de l'application
            const transformedClients = result.data.map((client: any) => ({
              id: client.id,
              firstName: client.first_name || client.firstName,
              lastName: client.last_name || client.lastName,
              email: client.email,
              phone: client.phone,
              address: client.address,
              notes: client.notes,
              createdAt: client.created_at ? new Date(client.created_at) : new Date(),
              updatedAt: client.updated_at ? new Date(client.updated_at) : new Date(),
            }));
            set({ clients: transformedClients });
          }
        } catch (error) {
          console.error('Erreur lors du chargement des clients:', error);
          // En cas d'erreur, on garde les données existantes
        }
      },
      
      loadDevices: async () => {
        try {
          const result = await deviceService.getAll();
          if (result.success && 'data' in result && result.data) {
            // Transformer les données de Supabase vers le format de l'application
            const transformedDevices = result.data.map((device: any) => ({
              id: device.id,
              brand: device.brand,
              model: device.model,
              serialNumber: device.serial_number || device.serialNumber,
              type: device.type,
              specifications: device.specifications,
              createdAt: device.created_at ? new Date(device.created_at) : new Date(),
              updatedAt: device.updated_at ? new Date(device.updated_at) : new Date(),
            }));
            set({ devices: transformedDevices });
          }
        } catch (error) {
          console.error('Erreur lors du chargement des appareils:', error);
          // En cas d'erreur, on garde les données existantes
        }
      },
      
      loadServices: async () => {
        try {
          const result = await serviceService.getAll();
          if (result.success && 'data' in result && result.data) {
            // Transformer les données de Supabase vers le format de l'application
            const transformedServices = result.data.map((service: any) => ({
              id: service.id,
              name: service.name,
              description: service.description,
              duration: service.duration,
              price: service.price,
              category: service.category,
              applicableDevices: service.applicable_devices || service.applicableDevices,
              isActive: service.is_active !== undefined ? service.is_active : service.isActive,
              createdAt: service.created_at ? new Date(service.created_at) : new Date(),
              updatedAt: service.updated_at ? new Date(service.updated_at) : new Date(),
            }));
            set({ services: transformedServices });
          }
        } catch (error) {
          console.error('Erreur lors du chargement des services:', error);
        }
      },
      
      loadParts: async () => {
        try {
          const result = await partService.getAll();
          if (result.success && 'data' in result && result.data) {
            // Transformer les données de Supabase vers le format de l'application
            const transformedParts = result.data.map((part: any) => ({
              id: part.id,
              name: part.name,
              description: part.description,
              partNumber: part.part_number || part.partNumber,
              brand: part.brand,
              compatibleDevices: part.compatible_devices || part.compatibleDevices,
              stockQuantity: part.stock_quantity || part.stockQuantity,
              minStockLevel: part.min_stock_level || part.minStockLevel,
              price: part.price,
              supplier: part.supplier,
              isActive: part.is_active !== undefined ? part.is_active : part.isActive,
              createdAt: part.created_at ? new Date(part.created_at) : new Date(),
              updatedAt: part.updated_at ? new Date(part.updated_at) : new Date(),
            }));
            set({ parts: transformedParts });
          }
        } catch (error) {
          console.error('Erreur lors du chargement des pièces:', error);
        }
      },
      
      loadProducts: async () => {
        try {
          const result = await productService.getAll();
          if (result.success && 'data' in result && result.data) {
            // Transformer les données de Supabase vers le format de l'application
            const transformedProducts = result.data.map((product: any) => ({
              id: product.id,
              name: product.name,
              description: product.description,
              category: product.category,
              price: product.price,
              stockQuantity: product.stock_quantity || product.stockQuantity,
              isActive: product.is_active !== undefined ? product.is_active : product.isActive,
              createdAt: product.created_at ? new Date(product.created_at) : new Date(),
              updatedAt: product.updated_at ? new Date(product.updated_at) : new Date(),
            }));
            set({ products: transformedProducts });
          }
        } catch (error) {
          console.error('Erreur lors du chargement des produits:', error);
        }
      },
      
      loadRepairs: async () => {
        try {
          const result = await repairService.getAll();
          if (result.success && 'data' in result && result.data) {
            set({ repairs: result.data });
          }
        } catch (error) {
          console.error('Erreur lors du chargement des réparations:', error);
        }
      },
      
      loadSales: async () => {
        try {
          const result = await saleService.getAll();
          if (result.success && 'data' in result && result.data) {
            set({ sales: result.data });
          }
        } catch (error) {
          console.error('Erreur lors du chargement des ventes:', error);
        }
      },
      
      loadAppointments: async () => {
        try {
          const result = await appointmentService.getAll();
          if (result.success && 'data' in result && result.data) {
            set({ appointments: result.data });
          }
        } catch (error) {
          console.error('Erreur lors du chargement des rendez-vous:', error);
        }
      },
      
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
      markMessageAsRead: async (id) => {
        try {
          set((state) => ({
            messages: state.messages.map(message => 
              message.id === id ? { ...message, isRead: true } : message
            )
          }));
        } catch (error) {
          console.error('Erreur lors du marquage du message:', error);
        }
      },
      
      markNotificationAsRead: async (id) => {
        try {
          set((state) => ({
            notifications: state.notifications.map(notification => 
              notification.id === id ? { ...notification, isRead: true } : notification
            )
          }));
        } catch (error) {
          console.error('Erreur lors du marquage de la notification:', error);
        }
      },
      
      resolveStockAlert: async (id) => {
        try {
          set((state) => ({
            stockAlerts: state.stockAlerts.map(alert => 
              alert.id === id ? { ...alert, isResolved: true } : alert
            )
          }));
        } catch (error) {
          console.error('Erreur lors de la résolution de l\'alerte:', error);
        }
      },
      
      // Getters
      getUserById: (id) => {
        const state = get();
        return state.users.find(user => user.id === id);
      },
      
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
