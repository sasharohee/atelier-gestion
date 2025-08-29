import { v4 as uuidv4 } from 'uuid';
import { supabase } from '../lib/supabase';
import {
  Client,
  Device,
  Service,
  Part,
  Product,
  Sale,
  SaleItem,
  Repair,
  RepairService,
  RepairPart,
  Appointment,
  Message
} from '../types';

export interface DemoData {
  clients: Client[];
  devices: Device[];
  services: Service[];
  parts: Part[];
  products: Product[];
  sales: Sale[];
  repairs: Repair[];
  appointments: Appointment[];
  messages: Message[];
}

class DemoDataService {
  private generateId(): string {
    return uuidv4();
  }

  private getCurrentDate(): Date {
    return new Date();
  }

  private getPastDate(daysAgo: number): Date {
    const date = new Date();
    date.setDate(date.getDate() - daysAgo);
    return date;
  }

  // Méthode pour vérifier si des données existent déjà
  async hasData(): Promise<boolean> {
    try {
      const { data: clients } = await supabase
        .from('clients')
        .select('id')
        .limit(1);
      
      return Boolean(clients && clients.length > 0);
    } catch (error) {
      console.error('Erreur lors de la vérification des données:', error);
      return false;
    }
  }

  // Méthode pour charger automatiquement les données si nécessaire
  async ensureDemoData(): Promise<void> {
    try {
      const hasExistingData = await this.hasData();
      
      if (!hasExistingData) {
        console.log('📊 Aucune donnée trouvée, base de données vierge prête à l\'emploi');
        // Ne plus charger automatiquement les données de démonstration
        return;
      } else {
        console.log('📊 Données existantes trouvées, pas de chargement nécessaire');
      }
    } catch (error) {
      console.error('❌ Erreur lors de la vérification des données:', error);
    }
  }

  // Méthode pour nettoyer toutes les données (site vierge)
  async clearAllData(): Promise<void> {
    try {
      console.log('🧹 Nettoyage de toutes les données...');
      
      // Supprimer dans l'ordre pour respecter les contraintes de clés étrangères
      const tables = [
        'repair_parts',
        'repair_services', 
        'sales',
        'sale_items',
        'repairs',
        'appointments',
        'messages',
        'devices',
        'clients',
        'parts',
        'services',
        'products'
      ];

      for (const table of tables) {
        const { error } = await supabase
          .from(table)
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000'); // Supprimer tout sauf les enregistrements système
        
        if (error) {
          console.error(`❌ Erreur lors de la suppression de ${table}:`, error);
        } else {
          console.log(`✅ Table ${table} nettoyée`);
        }
      }
      
      console.log('✅ Toutes les données ont été supprimées. Site vierge prêt à l\'emploi.');
    } catch (error) {
      console.error('❌ Erreur lors du nettoyage des données:', error);
      throw error;
    }
  }

  async getDemoData(): Promise<DemoData> {
    // Clients de démonstration
    const demoClients: Client[] = [
      {
        id: this.generateId(),
        firstName: 'Jean',
        lastName: 'Dupont',
        email: 'jean.dupont@email.com',
        phone: '06 12 34 56 78',
        address: '123 Rue de la Paix, 75001 Paris',
        notes: 'Client fidèle, préfère les réparations express',
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        firstName: 'Marie',
        lastName: 'Martin',
        email: 'marie.martin@email.com',
        phone: '06 98 76 54 32',
        address: '456 Avenue des Champs, 75008 Paris',
        notes: 'Cliente régulière, aime les accessoires premium',
        createdAt: this.getPastDate(25),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        firstName: 'Pierre',
        lastName: 'Durand',
        email: 'pierre.durand@email.com',
        phone: '06 11 22 33 44',
        address: '789 Boulevard Saint-Germain, 75006 Paris',
        notes: 'Technicien informatique, très exigeant sur la qualité',
        createdAt: this.getPastDate(20),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        firstName: 'Sophie',
        lastName: 'Leroy',
        email: 'sophie.leroy@email.com',
        phone: '06 55 66 77 88',
        address: '321 Rue de Rivoli, 75001 Paris',
        notes: 'Étudiante, budget limité mais fidèle',
        createdAt: this.getPastDate(15),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        firstName: 'Lucas',
        lastName: 'Moreau',
        email: 'lucas.moreau@email.com',
        phone: '06 99 88 77 66',
        address: '654 Rue du Commerce, 75015 Paris',
        notes: 'Entrepreneur, réparations urgentes fréquentes',
        createdAt: this.getPastDate(10),
        updatedAt: this.getCurrentDate()
      }
    ];

    // Appareils de démonstration
    const demoDevices: Device[] = [
      {
        id: this.generateId(),
        brand: 'Apple',
        model: 'iPhone 13 Pro',
        serialNumber: 'IP13P001',
        type: 'smartphone',
        specifications: {
          storage: '256GB',
          color: 'Sierra Blue',
          os: 'iOS 17'
        },
        createdAt: this.getPastDate(25),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        brand: 'Apple',
        model: 'MacBook Pro 14"',
        serialNumber: 'MBP14001',
        type: 'laptop',
        specifications: {
          processor: 'M2 Pro',
          memory: '16GB',
          storage: '512GB SSD',
          os: 'macOS Sonoma'
        },
        createdAt: this.getPastDate(20),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        brand: 'Samsung',
        model: 'Galaxy S21',
        serialNumber: 'SGS21001',
        type: 'smartphone',
        specifications: {
          storage: '128GB',
          color: 'Phantom Black',
          os: 'Android 14'
        },
        createdAt: this.getPastDate(15),
        updatedAt: this.getCurrentDate()
      }
    ];

    // Services de réparation
    const demoServices: Service[] = [
      {
        id: this.generateId(),
        name: 'Remplacement écran',
        description: 'Remplacement complet de l\'écran avec garantie',
        duration: 60,
        price: 89,
        category: 'Réparation écran',
        applicableDevices: ['smartphone', 'tablet', 'laptop'],
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Remplacement batterie',
        description: 'Remplacement de la batterie avec test complet',
        duration: 45,
        price: 49,
        category: 'Réparation batterie',
        applicableDevices: ['smartphone', 'tablet', 'laptop'],
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Nettoyage logiciel',
        description: 'Nettoyage complet du système et optimisation',
        duration: 30,
        price: 29,
        category: 'Maintenance',
        applicableDevices: ['smartphone', 'tablet', 'laptop', 'desktop'],
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Récupération données',
        description: 'Récupération de données depuis appareil endommagé',
        duration: 120,
        price: 79,
        category: 'Récupération',
        applicableDevices: ['smartphone', 'tablet', 'laptop', 'desktop'],
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Diagnostic complet',
        description: 'Diagnostic approfondi de l\'appareil',
        duration: 20,
        price: 19,
        category: 'Diagnostic',
        applicableDevices: ['smartphone', 'tablet', 'laptop', 'desktop'],
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Remplacement connecteur de charge',
        description: 'Remplacement du port de charge endommagé',
        duration: 90,
        price: 69,
        category: 'Réparation matérielle',
        applicableDevices: ['smartphone', 'tablet', 'laptop'],
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Remplacement haut-parleur',
        description: 'Remplacement du haut-parleur défaillant',
        duration: 40,
        price: 39,
        category: 'Réparation audio',
        applicableDevices: ['smartphone', 'tablet', 'laptop'],
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Remplacement caméra',
        description: 'Remplacement de la caméra arrière ou avant',
        duration: 75,
        price: 59,
        category: 'Réparation caméra',
        applicableDevices: ['smartphone', 'tablet'],
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Déverrouillage iCloud',
        description: 'Déverrouillage d\'un appareil Apple verrouillé',
        duration: 180,
        price: 99,
        category: 'Déverrouillage',
        applicableDevices: ['smartphone', 'tablet', 'laptop'],
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Installation logiciel',
        description: 'Installation et configuration de logiciels',
        duration: 25,
        price: 25,
        category: 'Installation',
        applicableDevices: ['laptop', 'desktop'],
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      }
    ];

    // Pièces détachées
    const demoParts: Part[] = [
      {
        id: this.generateId(),
        name: 'Écran iPhone 13',
        description: 'Écran LCD original pour iPhone 13/13 Pro',
        partNumber: 'IP13-SCR-001',
        brand: 'Apple',
        compatibleDevices: [demoDevices[0].id],
        stockQuantity: 5,
        minStockLevel: 3,
        price: 89,
        supplier: 'Apple Store',
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Batterie iPhone',
        description: 'Batterie Li-ion haute capacité pour iPhone',
        partNumber: 'IP-BAT-001',
        brand: 'Apple',
        compatibleDevices: [demoDevices[0].id, demoDevices[2].id],
        stockQuantity: 12,
        minStockLevel: 1,
        price: 29,
        supplier: 'BatteryStore',
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Écran MacBook Pro 14"',
        description: 'Écran Retina pour MacBook Pro 14"',
        partNumber: 'MBP14-SCR-001',
        brand: 'Apple',
        compatibleDevices: [demoDevices[1].id],
        stockQuantity: 3,
        minStockLevel: 2,
        price: 299,
        supplier: 'Apple Store',
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Clavier MacBook Pro',
        description: 'Clavier rétroéclairé pour MacBook Pro',
        partNumber: 'MBP-KBD-001',
        brand: 'Apple',
        compatibleDevices: [demoDevices[1].id],
        stockQuantity: 8,
        minStockLevel: 3,
        price: 89,
        supplier: 'Apple Store',
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Câble USB-C',
        description: 'Câble USB-C haute vitesse 100W',
        partNumber: 'USB-C-001',
        brand: 'Generic',
        compatibleDevices: [demoDevices[1].id],
        stockQuantity: 25,
        minStockLevel: 10,
        price: 9,
        supplier: 'CableStore',
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Coque iPhone Premium',
        description: 'Coque en silicone premium pour iPhone',
        partNumber: 'IP-CASE-001',
        brand: 'Generic',
        compatibleDevices: [demoDevices[0].id, demoDevices[2].id],
        stockQuantity: 15,
        minStockLevel: 1,
        price: 19,
        supplier: 'CaseStore',
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Chargeur sans fil',
        description: 'Chargeur sans fil 15W compatible Qi',
        partNumber: 'WIRELESS-CHG-001',
        brand: 'Generic',
        compatibleDevices: [demoDevices[0].id, demoDevices[2].id],
        stockQuantity: 10,
        minStockLevel: 1,
        price: 25,
        supplier: 'ChargerStore',
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Écouteurs Bluetooth',
        description: 'Écouteurs sans fil avec réduction de bruit',
        partNumber: 'BT-EAR-001',
        brand: 'Generic',
        compatibleDevices: [demoDevices[0].id, demoDevices[2].id],
        stockQuantity: 8,
        minStockLevel: 3,
        price: 35,
        supplier: 'AudioStore',
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Support téléphone',
        description: 'Support de bureau ajustable pour téléphone',
        partNumber: 'PHONE-STAND-001',
        brand: 'Generic',
        compatibleDevices: [demoDevices[0].id, demoDevices[2].id],
        stockQuantity: 20,
        minStockLevel: 8,
        price: 12,
        supplier: 'StandStore',
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Câble Lightning',
        description: 'Câble Lightning original Apple',
        partNumber: 'LIGHTNING-001',
        brand: 'Apple',
        compatibleDevices: [demoDevices[0].id],
        stockQuantity: 30,
        minStockLevel: 15,
        price: 15,
        supplier: 'Apple Store',
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      }
    ];

    // Produits en vente
    const demoProducts: Product[] = [
      {
        id: this.generateId(),
        name: 'Coque iPhone Premium',
        description: 'Coque en silicone premium avec protection renforcée',
        category: 'Accessoires',
        price: 29,
        stockQuantity: 20,
        minStockLevel: 1,
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Chargeur sans fil',
        description: 'Chargeur sans fil 15W compatible Qi',
        category: 'Accessoires',
        price: 39,
        stockQuantity: 15,
        minStockLevel: 3,
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Écouteurs Bluetooth',
        description: 'Écouteurs sans fil avec réduction de bruit active',
        category: 'Audio',
        price: 49,
        stockQuantity: 12,
        minStockLevel: 2,
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Support téléphone',
        description: 'Support de bureau ajustable et pliable',
        category: 'Accessoires',
        price: 19,
        stockQuantity: 25,
        minStockLevel: 8,
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        name: 'Câble Lightning',
        description: 'Câble Lightning original Apple 1m',
        category: 'Accessoires',
        price: 15,
        stockQuantity: 30,
        minStockLevel: 10,
        isActive: true,
        createdAt: this.getPastDate(30),
        updatedAt: this.getCurrentDate()
      }
    ];

    // Ventes de démonstration
    const demoSales: Sale[] = [
      {
        id: this.generateId(),
        clientId: demoClients[0].id,
        items: [
          {
            id: this.generateId(),
            type: 'product',
            itemId: demoProducts[0].id,
            name: 'Coque iPhone Premium',
            quantity: 1,
            unitPrice: 29,
            totalPrice: 29
          },
          {
            id: this.generateId(),
            type: 'product',
            itemId: demoProducts[1].id,
            name: 'Chargeur sans fil',
            quantity: 1,
            unitPrice: 39,
            totalPrice: 39
          }
        ],
        subtotal: 68,
        tax: 13.6,
        total: 81.6,
        paymentMethod: 'card',
        status: 'completed',
        createdAt: this.getPastDate(5),
        updatedAt: this.getPastDate(5)
      },
      {
        id: this.generateId(),
        clientId: demoClients[1].id,
        items: [
          {
            id: this.generateId(),
            type: 'product',
            itemId: demoProducts[2].id,
            name: 'Écouteurs Bluetooth',
            quantity: 1,
            unitPrice: 49,
            totalPrice: 49
          }
        ],
        subtotal: 49,
        tax: 9.8,
        total: 58.8,
        paymentMethod: 'card',
        status: 'completed',
        createdAt: this.getPastDate(3),
        updatedAt: this.getPastDate(3)
      },
      {
        id: this.generateId(),
        clientId: demoClients[2].id,
        items: [
          {
            id: this.generateId(),
            type: 'product',
            itemId: demoProducts[3].id,
            name: 'Support téléphone',
            quantity: 2,
            unitPrice: 19,
            totalPrice: 38
          },
          {
            id: this.generateId(),
            type: 'product',
            itemId: demoProducts[4].id,
            name: 'Câble Lightning',
            quantity: 1,
            unitPrice: 15,
            totalPrice: 15
          }
        ],
        subtotal: 53,
        tax: 10.6,
        total: 63.6,
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: this.getPastDate(1),
        updatedAt: this.getPastDate(1)
      }
    ];

    // Réparations de démonstration
    const demoRepairs: Repair[] = [
      {
        id: this.generateId(),
        clientId: demoClients[0].id,
        deviceId: demoDevices[0].id,
        status: 'in_progress',
        assignedTechnicianId: undefined,
        description: 'Remplacement écran iPhone 13 Pro',
        issue: 'Écran cassé après chute',
        estimatedDuration: 60,
        actualDuration: undefined,
        estimatedStartDate: this.getPastDate(2),
        estimatedEndDate: this.getCurrentDate(),
        startDate: this.getPastDate(2),
        endDate: undefined,
        dueDate: this.getCurrentDate(),
        isUrgent: false,
        notes: 'Client souhaite une réparation express',
        services: [
          {
            id: this.generateId(),
            serviceId: demoServices[0].id,
            quantity: 1,
            price: 89
          }
        ],
        parts: [
          {
            id: this.generateId(),
            partId: demoParts[0].id,
            quantity: 1,
            price: 89,
            isUsed: true
          }
        ],
        totalPrice: 178,
        isPaid: false,
        createdAt: this.getPastDate(3),
        updatedAt: this.getPastDate(2)
      },
      {
        id: this.generateId(),
        clientId: demoClients[1].id,
        deviceId: demoDevices[1].id,
        status: 'completed',
        assignedTechnicianId: undefined,
        description: 'Remplacement batterie MacBook Pro',
        issue: 'Batterie qui ne tient plus la charge',
        estimatedDuration: 45,
        actualDuration: 50,
        estimatedStartDate: this.getPastDate(10),
        estimatedEndDate: this.getPastDate(10),
        startDate: this.getPastDate(10),
        endDate: this.getPastDate(10),
        dueDate: this.getPastDate(10),
        isUrgent: false,
        notes: 'Réparation effectuée avec succès',
        services: [
          {
            id: this.generateId(),
            serviceId: demoServices[1].id,
            quantity: 1,
            price: 49
          }
        ],
        parts: [
          {
            id: this.generateId(),
            partId: demoParts[1].id,
            quantity: 1,
            price: 29,
            isUsed: true
          }
        ],
        totalPrice: 78,
        isPaid: true,
        createdAt: this.getPastDate(12),
        updatedAt: this.getPastDate(10)
      },
      {
        id: this.generateId(),
        clientId: demoClients[2].id,
        deviceId: demoDevices[2].id,
        status: 'waiting_parts',
        assignedTechnicianId: undefined,
        description: 'Remplacement connecteur de charge Samsung Galaxy S21',
        issue: 'Port de charge endommagé, ne charge plus',
        estimatedDuration: 90,
        actualDuration: undefined,
        estimatedStartDate: this.getPastDate(1),
        estimatedEndDate: this.getCurrentDate(),
        startDate: this.getPastDate(1),
        endDate: undefined,
        dueDate: this.getCurrentDate(),
        isUrgent: true,
        notes: 'En attente de la pièce de rechange',
        services: [
          {
            id: this.generateId(),
            serviceId: demoServices[5].id,
            quantity: 1,
            price: 69
          }
        ],
        parts: [
          {
            id: this.generateId(),
            partId: demoParts[2].id,
            quantity: 1,
            price: 45,
            isUsed: false
          }
        ],
        totalPrice: 114,
        isPaid: false,
        createdAt: this.getPastDate(1),
        updatedAt: this.getPastDate(1)
      },
      {
        id: this.generateId(),
        clientId: demoClients[3].id,
        deviceId: demoDevices[0].id,
        status: 'new',
        assignedTechnicianId: undefined,
        description: 'Nettoyage logiciel iPhone 13 Pro',
        issue: 'Appareil lent, batterie qui se décharge vite',
        estimatedDuration: 30,
        actualDuration: undefined,
        estimatedStartDate: this.getCurrentDate(),
        estimatedEndDate: this.getCurrentDate(),
        startDate: undefined,
        endDate: undefined,
        dueDate: this.getCurrentDate(),
        isUrgent: false,
        notes: 'Réparation simple, diagnostic préalable effectué',
        services: [
          {
            id: this.generateId(),
            serviceId: demoServices[2].id,
            quantity: 1,
            price: 29
          }
        ],
        parts: [],
        totalPrice: 29,
        isPaid: false,
        createdAt: this.getCurrentDate(),
        updatedAt: this.getCurrentDate()
      }
    ];

    // Rendez-vous de démonstration
    const demoAppointments: Appointment[] = [
      {
        id: this.generateId(),
        title: 'Réparation iPhone - Jean Dupont',
        description: 'Remplacement écran iPhone 13 Pro',
        clientId: demoClients[0].id,
        startDate: new Date(new Date().setHours(10, 0, 0, 0)),
        endDate: new Date(new Date().setHours(11, 0, 0, 0)),
        status: 'confirmed',

        createdAt: this.getPastDate(1),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        title: 'Diagnostic MacBook - Marie Martin',
        description: 'Diagnostic complet MacBook Pro',
        clientId: demoClients[1].id,
        startDate: new Date(new Date().setHours(14, 0, 0, 0)),
        endDate: new Date(new Date().setHours(15, 0, 0, 0)),
        status: 'confirmed',

        createdAt: this.getPastDate(1),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        title: 'Récupération données - Pierre Durand',
        description: 'Récupération données disque dur',
        clientId: demoClients[2].id,
        startDate: new Date(new Date().setHours(16, 0, 0, 0)),
        endDate: new Date(new Date().setHours(18, 0, 0, 0)),
        status: 'scheduled',
        createdAt: this.getCurrentDate(),
        updatedAt: this.getCurrentDate()
      }
    ];

    // Messages de démonstration
    const demoMessages: Message[] = [
      {
        id: this.generateId(),
        senderId: demoClients[0].id,
        recipientId: 'technician',
        subject: 'Question sur ma réparation',
        content: 'Bonjour, j\'aimerais savoir où en est ma réparation d\'iPhone. Merci.',
        isRead: false,
        createdAt: this.getPastDate(1),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        senderId: demoClients[1].id,
        recipientId: 'technician',
        subject: 'Rendez-vous confirmé',
        content: 'Parfait, je confirme mon rendez-vous pour demain à 14h.',
        isRead: true,
        createdAt: this.getPastDate(2),
        updatedAt: this.getCurrentDate()
      },
      {
        id: this.generateId(),
        senderId: 'technician',
        recipientId: demoClients[2].id,
        subject: 'Réparation terminée',
        content: 'Votre MacBook Pro est prêt. Vous pouvez le récupérer dès maintenant.',
        isRead: false,
        createdAt: this.getCurrentDate(),
        updatedAt: this.getCurrentDate()
      }
    ];

    return {
      clients: demoClients,
      devices: demoDevices,
      services: demoServices,
      parts: demoParts,
      products: demoProducts,
      sales: demoSales,
      repairs: demoRepairs,
      appointments: demoAppointments,
      messages: demoMessages
    };
  }

  // Méthode pour ajouter directement les données à Supabase
  async addDemoDataToSupabase(): Promise<void> {
    try {
      const demoData = await this.getDemoData();
      
      // Ajouter les clients
      for (const client of demoData.clients) {
        const { error } = await supabase
          .from('clients')
          .insert([{
            id: client.id,
            first_name: client.firstName,
            last_name: client.lastName,
            email: client.email,
            phone: client.phone,
            address: client.address,
            notes: client.notes,
            created_at: client.createdAt.toISOString(),
            updated_at: client.updatedAt.toISOString()
          }]);
        
        if (error) {
          console.error('Erreur lors de l\'ajout du client:', error);
        }
      }

      // Ajouter les appareils
      for (const device of demoData.devices) {
        const { error } = await supabase
          .from('devices')
          .insert([{
            id: device.id,
            brand: device.brand,
            model: device.model,
            serial_number: device.serialNumber,
            type: device.type,
            specifications: device.specifications,
            created_at: device.createdAt.toISOString(),
            updated_at: device.updatedAt.toISOString()
          }]);
        
        if (error) {
          console.error('Erreur lors de l\'ajout de l\'appareil:', error);
        }
      }

      // Ajouter les services
      for (const service of demoData.services) {
        const { error } = await supabase
          .from('services')
          .insert([{
            id: service.id,
            name: service.name,
            description: service.description,
            duration: service.duration,
            price: service.price,
            category: service.category,
            applicable_devices: service.applicableDevices,
            is_active: service.isActive,
            created_at: service.createdAt.toISOString(),
            updated_at: service.updatedAt.toISOString()
          }]);
        
        if (error) {
          console.error('Erreur lors de l\'ajout du service:', error);
        }
      }

      // Ajouter les pièces
      for (const part of demoData.parts) {
        const { error } = await supabase
          .from('parts')
          .insert([{
            id: part.id,
            name: part.name,
            description: part.description,
            part_number: part.partNumber,
            brand: part.brand,
            compatible_devices: part.compatibleDevices,
            stock_quantity: part.stockQuantity,
            min_stock_level: part.minStockLevel,
            price: part.price,
            supplier: part.supplier,
            is_active: part.isActive,
            created_at: part.createdAt.toISOString(),
            updated_at: part.updatedAt.toISOString()
          }]);
        
        if (error) {
          console.error('Erreur lors de l\'ajout de la pièce:', error);
        }
      }

      // Ajouter les produits
      for (const product of demoData.products) {
        const { error } = await supabase
          .from('products')
          .insert([{
            id: product.id,
            name: product.name,
            description: product.description,
            category: product.category,
            price: product.price,
            stock_quantity: product.stockQuantity,
            is_active: product.isActive,
            created_at: product.createdAt.toISOString(),
            updated_at: product.updatedAt.toISOString()
          }]);
        
        if (error) {
          console.error('Erreur lors de l\'ajout du produit:', error);
        }
      }

      // Ajouter les réparations
      for (const repair of demoData.repairs) {
        const { error } = await supabase
          .from('repairs')
          .insert([{
            id: repair.id,
            client_id: repair.clientId,
            device_id: repair.deviceId,
            status: repair.status,
            assigned_technician_id: repair.assignedTechnicianId,
            description: repair.description,
            issue: repair.issue,
            estimated_duration: repair.estimatedDuration,
            actual_duration: repair.actualDuration,
            estimated_start_date: repair.estimatedStartDate?.toISOString(),
            estimated_end_date: repair.estimatedEndDate?.toISOString(),
            start_date: repair.startDate?.toISOString(),
            end_date: repair.endDate?.toISOString(),
            due_date: repair.dueDate.toISOString(),
            is_urgent: repair.isUrgent,
            notes: repair.notes,
            total_price: repair.totalPrice,
            is_paid: repair.isPaid,
            created_at: repair.createdAt.toISOString(),
            updated_at: repair.updatedAt.toISOString()
          }]);
        
        if (error) {
          console.error('Erreur lors de l\'ajout de la réparation:', error);
        }
      }

      // Ajouter les ventes
      for (const sale of demoData.sales) {
        const { error } = await supabase
          .from('sales')
          .insert([{
            id: sale.id,
            client_id: sale.clientId,
            subtotal: sale.subtotal,
            tax: sale.tax,
            total: sale.total,
            payment_method: sale.paymentMethod,
            status: sale.status,
            created_at: sale.createdAt.toISOString(),
            updated_at: sale.updatedAt.toISOString()
          }]);
        
        if (error) {
          console.error('Erreur lors de l\'ajout de la vente:', error);
        }
      }

      // Ajouter les rendez-vous
      for (const appointment of demoData.appointments) {
        const { error } = await supabase
          .from('appointments')
          .insert([{
            id: appointment.id,
            title: appointment.title,
            description: appointment.description,
            client_id: appointment.clientId,
            start_date: appointment.startDate.toISOString(),
            end_date: appointment.endDate.toISOString(),
            status: appointment.status,

            created_at: appointment.createdAt.toISOString(),
            updated_at: appointment.updatedAt.toISOString()
          }]);
        
        if (error) {
          console.error('Erreur lors de l\'ajout du rendez-vous:', error);
        }
      }

      // Ajouter les messages
      for (const message of demoData.messages) {
        const { error } = await supabase
          .from('messages')
          .insert([{
            id: message.id,
            sender_id: message.senderId,
            recipient_id: message.recipientId,
            subject: message.subject,
            content: message.content,
            is_read: message.isRead,
            created_at: message.createdAt.toISOString(),
            updated_at: message.updatedAt.toISOString()
          }]);
        
        if (error) {
          console.error('Erreur lors de l\'ajout du message:', error);
        }
      }

      console.log('✅ Données de démonstration ajoutées avec succès à Supabase');
    } catch (error) {
      console.error('❌ Erreur lors de l\'ajout des données de démonstration:', error);
      throw error;
    }
  }

  // Méthode pour vérifier si le guide a déjà été complété
  isOnboardingCompleted(): boolean {
    return localStorage.getItem('onboarding-completed') === 'true';
  }

  // Méthode pour marquer le guide comme terminé
  markOnboardingCompleted(): void {
    localStorage.setItem('onboarding-completed', 'true');
  }

  // Méthode pour réinitialiser le guide (pour les tests)
  resetOnboarding(): void {
    localStorage.removeItem('onboarding-completed');
  }
}

export const demoDataService = new DemoDataService();
