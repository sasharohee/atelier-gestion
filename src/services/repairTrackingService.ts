import { supabase } from '../lib/supabase';

export interface RepairTrackingData {
  id: string;
  repairNumber: string;
  status: string;
  description: string;
  issue: string;
  estimatedStartDate: string | null;
  estimatedEndDate: string | null;
  startDate: string | null;
  endDate: string | null;
  dueDate: string;
  isUrgent: boolean;
  notes: string | null;
  totalPrice: number;
  isPaid: boolean;
  createdAt: string;
  updatedAt: string;
  client: {
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
  };
  device: {
    brand: string;
    model: string;
    serialNumber: string | null;
    type: string;
  } | null;
  technician: {
    firstName: string;
    lastName: string;
  } | null;
}

export interface RepairHistoryItem {
  id: string;
  repairNumber: string;
  status: string;
  description: string;
  totalPrice: number;
  isPaid: boolean;
  createdAt: string;
  device: {
    brand: string;
    model: string;
  } | null;
}

class RepairTrackingService {
  /**
   * Recherche une réparation par ID ou numéro de réparation et email du client
   */
  async getRepairTracking(repairIdOrNumber: string, clientEmail: string): Promise<RepairTrackingData | null> {
    try {
      // Déterminer si c'est un UUID (ID) ou un numéro de réparation
      const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(repairIdOrNumber);
      
      console.log('🔍 Recherche de réparation:', { repairIdOrNumber, clientEmail, isUUID });
      
      // Méthode simple : requête directe avec jointure
      try {
        // D'abord, trouver le client par email
        const { data: clientData, error: clientError } = await supabase
          .from('clients')
          .select('id, first_name, last_name, email, phone')
          .eq('email', clientEmail)
          .single();

        if (clientError || !clientData) {
          console.error('❌ Client non trouvé:', clientError);
          return null;
        }

        console.log('✅ Client trouvé:', clientData);

        // Ensuite, trouver la réparation par numéro et client_id (sans jointures)
        let repairQuery = supabase
          .from('repairs')
          .select('*')
          .eq('client_id', clientData.id);

        if (isUUID) {
          repairQuery = repairQuery.eq('id', repairIdOrNumber);
        } else {
          repairQuery = repairQuery.eq('repair_number', repairIdOrNumber);
        }

        const { data: repairData, error: repairError } = await repairQuery.single();

        if (repairError || !repairData) {
          console.error('❌ Réparation non trouvée:', repairError);
          return null;
        }

        console.log('✅ Réparation trouvée:', repairData);
        
        // Récupérer les informations de l'appareil si nécessaire
        let deviceData = null;
        if (repairData.device_id) {
          const { data: device, error: deviceError } = await supabase
            .from('devices')
            .select('brand, model, serial_number, type')
            .eq('id', repairData.device_id)
            .single();
          
          if (!deviceError && device) {
            deviceData = device;
          }
        }

        // Récupérer les informations du technicien si nécessaire
        let technicianData = null;
        if (repairData.assigned_technician_id) {
          const { data: technician, error: technicianError } = await supabase
            .from('users')
            .select('first_name, last_name')
            .eq('id', repairData.assigned_technician_id)
            .single();
          
          if (!technicianError && technician) {
            technicianData = technician;
          }
        }
        
        // Transformer les données pour correspondre à l'interface
        return {
          id: repairData.id,
          repairNumber: repairData.repair_number,
          status: repairData.status,
          description: repairData.description,
          issue: repairData.issue,
          estimatedStartDate: repairData.estimated_start_date,
          estimatedEndDate: repairData.estimated_end_date,
          startDate: repairData.start_date,
          endDate: repairData.end_date,
          dueDate: repairData.due_date,
          isUrgent: repairData.is_urgent,
          notes: repairData.notes,
          totalPrice: repairData.total_price,
          isPaid: repairData.is_paid,
          createdAt: repairData.created_at,
          updatedAt: repairData.updated_at,
          client: {
            firstName: clientData.first_name || '',
            lastName: clientData.last_name || '',
            email: clientData.email || '',
            phone: clientData.phone || ''
          },
          device: deviceData ? {
            brand: deviceData.brand,
            model: deviceData.model,
            serialNumber: deviceData.serial_number,
            type: deviceData.type
          } : null,
          technician: technicianData ? {
            firstName: technicianData.first_name,
            lastName: technicianData.last_name
          } : null
        };
        
      } catch (error) {
        console.error('❌ Erreur lors de la recherche:', error);
        return null;
      }
    } catch (error) {
      console.error('Erreur lors de la recherche de réparation:', error);
      return null;
    }
  }

  /**
   * Récupère l'historique des réparations d'un client
   */
  async getClientRepairHistory(clientEmail: string): Promise<RepairHistoryItem[]> {
    try {
      // D'abord, trouver le client par email
      const { data: clientData, error: clientError } = await supabase
        .from('clients')
        .select('id, first_name, last_name, email')
        .eq('email', clientEmail)
        .single();

      if (clientError || !clientData) {
        console.error('❌ Client non trouvé pour l\'historique:', clientError);
        return [];
      }

      // Ensuite, récupérer toutes les réparations du client (sans jointures)
      const { data: repairsData, error: repairsError } = await supabase
        .from('repairs')
        .select('*')
        .eq('client_id', clientData.id)
        .order('created_at', { ascending: false });

      if (repairsError) {
        console.error('❌ Erreur lors de la récupération des réparations:', repairsError);
        return [];
      }

      // Récupérer les informations des appareils pour toutes les réparations
      const repairsWithDevices = await Promise.all(
        (repairsData || []).map(async (repair) => {
          let deviceData = null;
          if (repair.device_id) {
            const { data: device, error: deviceError } = await supabase
              .from('devices')
              .select('brand, model')
              .eq('id', repair.device_id)
              .single();
            
            if (!deviceError && device) {
              deviceData = device;
            }
          }

          return {
            id: repair.id,
            repairNumber: repair.repair_number,
            status: repair.status,
            description: repair.description,
            totalPrice: repair.total_price,
            isPaid: repair.is_paid,
            createdAt: repair.created_at,
            device: deviceData ? {
              brand: deviceData.brand,
              model: deviceData.model
            } : null
          };
        })
      );

      return repairsWithDevices;
    } catch (error) {
      console.error('Erreur lors de la récupération de l\'historique:', error);
      return [];
    }
  }

  /**
   * Vérifie si une réparation existe pour un client donné
   */
  async verifyRepairAccess(repairId: string, clientEmail: string): Promise<boolean> {
    try {
      const { data, error } = await supabase
        .from('repairs')
        .select('id')
        .eq('id', repairId)
        .eq('clients.email', clientEmail)
        .single();

      if (error) {
        return false;
      }

      return !!data;
    } catch (error) {
      return false;
    }
  }

  /**
   * Récupère les statistiques de réparation d'un client
   */
  async getClientRepairStats(clientEmail: string): Promise<{
    totalRepairs: number;
    completedRepairs: number;
    pendingRepairs: number;
    totalSpent: number;
  }> {
    try {
      const { data, error } = await supabase
        .from('repairs')
        .select('status, total_price, is_paid')
        .eq('clients.email', clientEmail);

      if (error) {
        console.error('Erreur lors de la récupération des statistiques:', error);
        return {
          totalRepairs: 0,
          completedRepairs: 0,
          pendingRepairs: 0,
          totalSpent: 0
        };
      }

      const repairs = data || [];
      const totalRepairs = repairs.length;
      const completedRepairs = repairs.filter(r => r.status === 'completed').length;
      const pendingRepairs = repairs.filter(r => ['new', 'in_progress', 'waiting_parts'].includes(r.status)).length;
      const totalSpent = repairs
        .filter(r => r.is_paid)
        .reduce((sum, r) => sum + (r.total_price || 0), 0);

      return {
        totalRepairs,
        completedRepairs,
        pendingRepairs,
        totalSpent
      };
    } catch (error) {
      console.error('Erreur lors de la récupération des statistiques:', error);
      return {
        totalRepairs: 0,
        completedRepairs: 0,
        pendingRepairs: 0,
        totalSpent: 0
      };
    }
  }

  /**
   * Envoie une notification de mise à jour de statut (placeholder)
   */
  async sendStatusUpdateNotification(repairId: string, newStatus: string): Promise<boolean> {
    try {
      // Ici on pourrait intégrer un service d'envoi d'email/SMS
      // Pour l'instant, on simule juste l'envoi
      console.log(`Notification envoyée pour la réparation ${repairId} - Nouveau statut: ${newStatus}`);
      return true;
    } catch (error) {
      console.error('Erreur lors de l\'envoi de la notification:', error);
      return false;
    }
  }

  /**
   * Génère l'URL de suivi de réparation avec les paramètres de requête
   */
  generateTrackingUrl(repairNumber: string, clientEmail: string): string {
    // Utiliser le domaine de production pour les QR codes
    // En développement, on peut détecter si on est en localhost
    let baseUrl = 'https://atelier-gestion.com';
    
    if (typeof window !== 'undefined') {
      const hostname = window.location.hostname;
      // Si on est en localhost ou en développement, on peut utiliser localhost
      // Mais pour les QR codes, on veut toujours utiliser le domaine de production
      // pour que les clients puissent scanner même en développement
      if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname.includes('localhost')) {
        // En développement, on peut garder localhost pour tester
        // Mais pour la production, on utilise toujours atelier-gestion.com
        baseUrl = 'https://atelier-gestion.com';
      } else if (hostname.includes('atelier-gestion.com') || hostname.includes('vercel.app')) {
        // Si on est déjà sur le domaine de production ou Vercel, utiliser le protocole HTTPS
        baseUrl = `https://${hostname}`;
      } else {
        // Sinon, utiliser le domaine de production par défaut
        baseUrl = 'https://atelier-gestion.com';
      }
    }
    
    const params = new URLSearchParams({
      repairNumber: repairNumber,
      email: clientEmail,
    });
    return `${baseUrl}/repair-tracking?${params.toString()}`;
  }
}

export const repairTrackingService = new RepairTrackingService();
