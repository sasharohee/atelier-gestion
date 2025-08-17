import { v4 as uuidv4 } from 'uuid';
import {
  User,
  Client,
  Device,
  Service,
  Part,
  Product,
  RepairStatus,
  Repair,
  Message,
  Appointment,
  Sale,
  StockAlert,
  Notification,
  DashboardStats
} from '../types';

// Utilisateurs de démonstration
export const mockUsers: User[] = [
  {
    id: uuidv4(),
    firstName: 'Jean',
    lastName: 'Dupont',
    email: 'jean.dupont@atelier.fr',
    role: 'admin',
    avatar: '/avatars/jean.jpg',
    createdAt: new Date('2024-01-01'),
  },
  {
    id: uuidv4(),
    firstName: 'Marie',
    lastName: 'Martin',
    email: 'marie.martin@atelier.fr',
    role: 'technician',
    avatar: '/avatars/marie.jpg',
    createdAt: new Date('2024-01-15'),
  },
  {
    id: uuidv4(),
    firstName: 'Pierre',
    lastName: 'Durand',
    email: 'pierre.durand@atelier.fr',
    role: 'technician',
    avatar: '/avatars/pierre.jpg',
    createdAt: new Date('2024-02-01'),
  },
];

// Clients de démonstration
export const mockClients: Client[] = [
  {
    id: uuidv4(),
    firstName: 'Sophie',
    lastName: 'Bernard',
    email: 'sophie.bernard@email.com',
    phone: '06 12 34 56 78',
    address: '123 Rue de la Paix, 75001 Paris',
    notes: 'Client fidèle, préfère les réparations express',
    createdAt: new Date('2024-01-10'),
    updatedAt: new Date('2024-01-10'),
  },
  {
    id: uuidv4(),
    firstName: 'Thomas',
    lastName: 'Petit',
    email: 'thomas.petit@email.com',
    phone: '06 98 76 54 32',
    address: '456 Avenue des Champs, 69000 Lyon',
    notes: 'Entreprise, facturation mensuelle',
    createdAt: new Date('2024-01-20'),
    updatedAt: new Date('2024-01-20'),
  },
  {
    id: uuidv4(),
    firstName: 'Emma',
    lastName: 'Robert',
    email: 'emma.robert@email.com',
    phone: '06 55 44 33 22',
    address: '789 Boulevard Central, 13000 Marseille',
    notes: 'Étudiante, budget limité',
    createdAt: new Date('2024-02-05'),
    updatedAt: new Date('2024-02-05'),
  },
];

// Appareils de démonstration
export const mockDevices: Device[] = [
  {
    id: uuidv4(),
    brand: 'Apple',
    model: 'iPhone 13',
    serialNumber: 'A2482',
    type: 'smartphone',
    specifications: {
      storage: '128GB',
      color: 'Bleu',
      year: 2021,
    },
    createdAt: new Date('2024-01-15'),
    updatedAt: new Date('2024-01-15'),
  },
  {
    id: uuidv4(),
    brand: 'Samsung',
    model: 'Galaxy S21',
    serialNumber: 'SM-G991B',
    type: 'smartphone',
    specifications: {
      storage: '256GB',
      color: 'Noir',
      year: 2021,
    },
    createdAt: new Date('2024-01-20'),
    updatedAt: new Date('2024-01-20'),
  },
  {
    id: uuidv4(),
    brand: 'Apple',
    model: 'MacBook Pro 13"',
    serialNumber: 'C02XYZ123456',
    type: 'laptop',
    specifications: {
      processor: 'M1',
      ram: '8GB',
      storage: '256GB',
      year: 2020,
    },
    createdAt: new Date('2024-02-01'),
    updatedAt: new Date('2024-02-01'),
  },
];

// Services de démonstration
export const mockServices: Service[] = [
  {
    id: uuidv4(),
    name: 'Remplacement écran iPhone',
    description: 'Remplacement complet de l\'écran avec garantie',
    duration: 60,
    price: 89.99,
    category: 'Écran',
    applicableDevices: ['smartphone'],
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  },
  {
    id: uuidv4(),
    name: 'Remplacement batterie',
    description: 'Remplacement de la batterie avec test complet',
    duration: 45,
    price: 49.99,
    category: 'Batterie',
    applicableDevices: ['smartphone', 'tablet', 'laptop'],
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  },
  {
    id: uuidv4(),
    name: 'Nettoyage et optimisation',
    description: 'Nettoyage complet et optimisation des performances',
    duration: 30,
    price: 29.99,
    category: 'Maintenance',
    applicableDevices: ['smartphone', 'tablet', 'laptop', 'desktop'],
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  },
];

// Pièces détachées de démonstration
export const mockParts: Part[] = [
  {
    id: uuidv4(),
    name: 'Écran iPhone 13',
    description: 'Écran LCD original pour iPhone 13',
    partNumber: 'IP13-SCR-001',
    brand: 'Apple',
    compatibleDevices: ['smartphone'],
    stockQuantity: 5,
    minStockLevel: 2,
    price: 45.00,
    supplier: 'Fournisseur Apple',
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  },
  {
    id: uuidv4(),
    name: 'Batterie iPhone 13',
    description: 'Batterie Li-ion 3240mAh pour iPhone 13',
    partNumber: 'IP13-BAT-001',
    brand: 'Apple',
    compatibleDevices: ['smartphone'],
    stockQuantity: 12,
    minStockLevel: 5,
    price: 25.00,
    supplier: 'Fournisseur Apple',
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  },
  {
    id: uuidv4(),
    name: 'Clavier MacBook Pro',
    description: 'Clavier rétroéclairé pour MacBook Pro 13"',
    partNumber: 'MBP13-KBD-001',
    brand: 'Apple',
    compatibleDevices: ['laptop'],
    stockQuantity: 2,
    minStockLevel: 3,
    price: 120.00,
    supplier: 'Fournisseur Apple',
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  },
];

// Produits de démonstration
export const mockProducts: Product[] = [
  {
    id: uuidv4(),
    name: 'Coque iPhone 13',
    description: 'Coque de protection en silicone',
    category: 'Accessoires',
    price: 19.99,
    stockQuantity: 25,
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  },
  {
    id: uuidv4(),
    name: 'Chargeur sans fil',
    description: 'Chargeur sans fil 15W compatible Qi',
    category: 'Accessoires',
    price: 34.99,
    stockQuantity: 15,
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  },
];

// Statuts de réparation
export const mockRepairStatuses: RepairStatus[] = [
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
];

// Réparations de démonstration
export const mockRepairs: Repair[] = [
  {
    id: uuidv4(),
    clientId: mockClients[0].id,
    deviceId: mockDevices[0].id,
    status: 'in_progress',
    assignedTechnicianId: mockUsers[1].id,
    description: 'Écran cassé, remplacement nécessaire',
    issue: 'Écran cassé',
    estimatedDuration: 60,
    actualDuration: 45,
    estimatedStartDate: new Date('2024-02-15T09:00:00'),
    estimatedEndDate: new Date('2024-02-15T10:30:00'),
    startDate: new Date('2024-02-15T09:00:00'),
    endDate: new Date('2024-02-15T10:30:00'),
    dueDate: new Date('2024-02-16T17:00:00'),
    isUrgent: false,
    notes: 'Client a demandé une réparation express',
    services: [
      {
        id: uuidv4(),
        serviceId: mockServices[0].id,
        quantity: 1,
        price: 89.99,
      },
    ],
    parts: [
      {
        id: uuidv4(),
        partId: mockParts[0].id,
        quantity: 1,
        price: 45.00,
        isUsed: true,
      },
    ],
    totalPrice: 134.99,
    isPaid: true,
    createdAt: new Date('2024-02-15T08:30:00'),
    updatedAt: new Date('2024-02-15T10:30:00'),
  },
  {
    id: uuidv4(),
    clientId: mockClients[1].id,
    deviceId: mockDevices[2].id,
    status: 'waiting_parts',
    assignedTechnicianId: mockUsers[2].id,
    description: 'Clavier défectueux, touches qui ne répondent plus',
    issue: 'Clavier défectueux',
    estimatedDuration: 90,
    estimatedStartDate: new Date('2024-02-14T14:00:00'),
    estimatedEndDate: new Date('2024-02-14T15:30:00'),
    startDate: new Date('2024-02-14T14:00:00'),
    dueDate: new Date('2024-02-20T17:00:00'),
    isUrgent: true,
    notes: 'Client professionnel, priorité haute',
    services: [
      {
        id: uuidv4(),
        serviceId: mockServices[1].id,
        quantity: 1,
        price: 49.99,
      },
    ],
    parts: [
      {
        id: uuidv4(),
        partId: mockParts[2].id,
        quantity: 1,
        price: 120.00,
        isUsed: false,
      },
    ],
    totalPrice: 169.99,
    isPaid: false,
    createdAt: new Date('2024-02-14T13:30:00'),
    updatedAt: new Date('2024-02-14T14:00:00'),
  },
];

// Messages de démonstration
export const mockMessages: Message[] = [
  {
    id: uuidv4(),
    senderId: mockUsers[0].id,
    recipientId: mockUsers[1].id,
    repairId: mockRepairs[0].id,
    subject: 'Réparation iPhone 13 - Priorité',
    content: 'Bonjour Marie, cette réparation est prioritaire. Merci de la traiter en premier.',
    isRead: false,
    createdAt: new Date('2024-02-15T08:00:00'),
    updatedAt: new Date('2024-02-15T08:00:00'),
  },
];

// Rendez-vous de démonstration
export const mockAppointments: Appointment[] = [
  {
    id: uuidv4(),
    clientId: mockClients[2].id,
    repairId: undefined,
    title: 'Diagnostic iPad',
    description: 'Client vient pour diagnostic de son iPad qui ne s\'allume plus',
    startDate: new Date('2024-02-16T10:00:00'),
    endDate: new Date('2024-02-16T11:00:00'),
    assignedUserId: mockUsers[1].id,
    status: 'scheduled',
    createdAt: new Date('2024-02-15T16:00:00'),
    updatedAt: new Date('2024-02-15T16:00:00'),
  },
];

// Ventes de démonstration
export const mockSales: Sale[] = [
  {
    id: uuidv4(),
    clientId: mockClients[0].id,
    items: [
      {
        id: uuidv4(),
        type: 'product',
        itemId: mockProducts[0].id,
        name: 'Coque iPhone 13',
        quantity: 1,
        unitPrice: 19.99,
        totalPrice: 19.99,
      },
    ],
    subtotal: 19.99,
    tax: 3.99,
    total: 23.98,
    paymentMethod: 'card',
    status: 'completed',
    createdAt: new Date('2024-02-15T11:00:00'),
    updatedAt: new Date('2024-02-15T11:00:00'),
  },
];

// Alertes de stock de démonstration
export const mockStockAlerts: StockAlert[] = [
  {
    id: uuidv4(),
    partId: mockParts[2].id,
    type: 'low_stock',
    message: 'Stock faible pour Clavier MacBook Pro (2 restants)',
    isResolved: false,
    createdAt: new Date('2024-02-15T12:00:00'),
  },
];

// Notifications de démonstration
export const mockNotifications: Notification[] = [
  {
    id: uuidv4(),
    userId: mockUsers[0].id,
    type: 'stock_alert',
    title: 'Alerte stock',
    message: 'Stock faible pour Clavier MacBook Pro',
    isRead: false,
    relatedId: mockStockAlerts[0].id,
    createdAt: new Date('2024-02-15T12:00:00'),
  },
];

// Statistiques du dashboard
export const mockDashboardStats: DashboardStats = {
  totalRepairs: 45,
  activeRepairs: 12,
  completedRepairs: 28,
  overdueRepairs: 3,
  todayAppointments: 5,
  monthlyRevenue: 15420.50,
  lowStockItems: 2,
  pendingMessages: 3,
};
