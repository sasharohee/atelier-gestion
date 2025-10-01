// Service simplifié pour les demandes de devis (version de fallback)
// Ce service évite les erreurs de compilation en utilisant des types simplifiés

export class QuoteRequestServiceSimple {
  // Récupérer les informations d'un réparateur par son URL personnalisée
  static async getTechnicianByCustomUrl(customUrl: string): Promise<any> {
    try {
      // Simulation des données pour le moment
      return {
        technician: {
          id: '123e4567-e89b-12d3-a456-426614174000',
          firstName: 'Jean',
          lastName: 'Dupont',
          email: 'jean.dupont@atelier.com',
          phone: '01 23 45 67 89',
          companyName: 'Atelier Réparation Express',
          address: '123 Rue de la Réparation, 75001 Paris',
        },
        customUrlData: {
          id: '123e4567-e89b-12d3-a456-426614174001',
          technicianId: '123e4567-e89b-12d3-a456-426614174000',
          customUrl: customUrl,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        }
      };
    } catch (error) {
      console.error('Erreur lors de la récupération du réparateur:', error);
      return null;
    }
  }

  // Créer une nouvelle demande de devis
  static async createQuoteRequest(requestData: any): Promise<any> {
    try {
      // Simulation de la création
      const newRequest = {
        id: crypto.randomUUID(),
        requestNumber: `QR-${Date.now()}`,
        ...requestData,
        status: 'pending',
        priority: 'medium',
        source: 'website',
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      return newRequest;
    } catch (error) {
      console.error('Erreur lors de la création de la demande:', error);
      return null;
    }
  }

  // Récupérer les demandes de devis d'un réparateur
  static async getQuoteRequestsByTechnician(technicianId: string): Promise<any[]> {
    try {
      // Simulation des données avec un délai pour simuler une vraie API
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      return [
        {
          id: '1',
          requestNumber: 'QR-20241201-0001',
          customUrl: 'repphone',
          technicianId: technicianId,
          clientFirstName: 'Marie',
          clientLastName: 'Martin',
          clientEmail: 'marie.martin@email.com',
          clientPhone: '06 12 34 56 78',
          description: 'Réparation écran iPhone',
          deviceType: 'Smartphone',
          deviceBrand: 'Apple',
          deviceModel: 'iPhone 14',
          issueDescription: 'Écran fissuré après une chute, affichage défaillant',
          urgency: 'high',
          attachments: [],
          status: 'pending',
          priority: 'high',
          source: 'website',
          createdAt: new Date('2024-12-01T10:30:00'),
          updatedAt: new Date('2024-12-01T10:30:00'),
        },
        {
          id: '2',
          requestNumber: 'QR-20241201-0002',
          customUrl: 'repphone',
          technicianId: technicianId,
          clientFirstName: 'Pierre',
          clientLastName: 'Durand',
          clientEmail: 'pierre.durand@email.com',
          clientPhone: '06 98 76 54 32',
          description: 'Problème de batterie',
          deviceType: 'Smartphone',
          deviceBrand: 'Samsung',
          deviceModel: 'Galaxy S23',
          issueDescription: 'Batterie qui se décharge très rapidement, téléphone s\'éteint à 30%',
          urgency: 'medium',
          attachments: [],
          status: 'in_review',
          priority: 'medium',
          source: 'website',
          createdAt: new Date('2024-12-01T14:15:00'),
          updatedAt: new Date('2024-12-01T14:15:00'),
        },
        {
          id: '3',
          requestNumber: 'QR-20241201-0003',
          customUrl: 'repphone',
          technicianId: technicianId,
          clientFirstName: 'Sophie',
          clientLastName: 'Bernard',
          clientEmail: 'sophie.bernard@email.com',
          clientPhone: '06 55 44 33 22',
          description: 'Réparation ordinateur portable',
          deviceType: 'Laptop',
          deviceBrand: 'Dell',
          deviceModel: 'XPS 13',
          issueDescription: 'Ordinateur qui ne démarre plus, écran noir au démarrage',
          urgency: 'low',
          attachments: [],
          status: 'quoted',
          priority: 'low',
          source: 'website',
          createdAt: new Date('2024-11-30T16:45:00'),
          updatedAt: new Date('2024-12-01T09:20:00'),
        },
      ];
    } catch (error) {
      console.error('Erreur lors de la récupération des demandes:', error);
      return [];
    }
  }

  // Récupérer les statistiques des demandes
  static async getQuoteRequestStats(technicianId: string): Promise<any> {
    try {
      // Simulation avec un délai
      await new Promise(resolve => setTimeout(resolve, 500));
      
      return {
        total: 3,
        pending: 1,
        inReview: 1,
        quoted: 1,
        accepted: 0,
        rejected: 0,
        byUrgency: { low: 1, medium: 1, high: 1 },
        byStatus: { pending: 1, in_review: 1, quoted: 1, accepted: 0, rejected: 0, cancelled: 0 },
        monthly: 3,
        weekly: 3,
        daily: 2,
      };
    } catch (error) {
      console.error('Erreur lors de la récupération des statistiques:', error);
      return null;
    }
  }

  // Gérer les URLs personnalisées
  static async getCustomUrls(technicianId: string): Promise<any[]> {
    try {
      // Simulation avec un délai
      await new Promise(resolve => setTimeout(resolve, 300));
      
      return [
        {
          id: '1',
          technicianId: technicianId,
          customUrl: 'repphone',
          isActive: true,
          createdAt: new Date('2024-11-01'),
          updatedAt: new Date('2024-11-01'),
        },
        {
          id: '2',
          technicianId: technicianId,
          customUrl: 'atelier-express',
          isActive: true,
          createdAt: new Date('2024-11-15'),
          updatedAt: new Date('2024-11-15'),
        },
        {
          id: '3',
          technicianId: technicianId,
          customUrl: 'reparation-rapide',
          isActive: false,
          createdAt: new Date('2024-11-20'),
          updatedAt: new Date('2024-11-25'),
        },
      ];
    } catch (error) {
      console.error('Erreur lors de la récupération des URLs:', error);
      return [];
    }
  }

  static async createCustomUrl(technicianId: string, customUrl: string): Promise<any> {
    try {
      return {
        id: crypto.randomUUID(),
        technicianId: technicianId,
        customUrl: customUrl,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
    } catch (error) {
      console.error('Erreur lors de la création de l\'URL:', error);
      return null;
    }
  }

  static async updateCustomUrlStatus(urlId: string, isActive: boolean): Promise<boolean> {
    try {
      // Simulation de la mise à jour
      return true;
    } catch (error) {
      console.error('Erreur lors de la mise à jour de l\'URL:', error);
      return false;
    }
  }

  static async updateCustomUrl(urlId: string, newCustomUrl: string): Promise<boolean> {
    try {
      // Simulation de la mise à jour
      return true;
    } catch (error) {
      console.error('Erreur lors de la mise à jour de l\'URL:', error);
      return false;
    }
  }

  static async deleteCustomUrl(urlId: string): Promise<boolean> {
    try {
      // Simulation de la suppression
      return true;
    } catch (error) {
      console.error('Erreur lors de la suppression de l\'URL:', error);
      return false;
    }
  }
}

export const quoteRequestServiceSimple = QuoteRequestServiceSimple;
