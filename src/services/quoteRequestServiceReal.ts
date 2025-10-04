// Service réel pour les demandes de devis - utilise Supabase
import { supabase } from '../lib/supabase';

export class QuoteRequestServiceReal {
  // Récupérer les informations d'un réparateur par son URL personnalisée
  static async getTechnicianByCustomUrl(customUrl: string): Promise<{
    technician: any;
    customUrlData: any;
  } | null> {
    try {
      const { data: customUrlData, error: urlError } = await supabase
        .from('technician_custom_urls')
        .select('*')
        .eq('custom_url', customUrl)
        .eq('is_active', true)
        .single();

      if (urlError || !customUrlData) {
        console.error('URL personnalisée non trouvée:', urlError);
        return null;
      }

      const { data: technician, error: techError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('user_id', customUrlData.technician_id)
        .single();

      if (techError || !technician) {
        console.error('Réparateur non trouvé:', techError);
        return null;
      }

      return {
        technician,
        customUrlData,
      };
    } catch (error) {
      console.error('Erreur lors de la récupération du réparateur:', error);
      return null;
    }
  }

  // Créer une nouvelle demande de devis
  static async createQuoteRequest(requestData: any): Promise<any> {
    try {
      // Générer un numéro de demande unique
      const { data: requestNumber, error: numberError } = await supabase
        .rpc('generate_quote_request_number');

      if (numberError) {
        console.error('Erreur génération numéro:', numberError);
        return null;
      }

      const { data, error } = await supabase
        .from('quote_requests')
        .insert({
          request_number: requestNumber,
          custom_url: requestData.customUrl,
          technician_id: requestData.technicianId,
          client_first_name: requestData.clientFirstName,
          client_last_name: requestData.clientLastName,
          client_email: requestData.clientEmail,
          client_phone: requestData.clientPhone,
          description: requestData.description,
          device_type: requestData.deviceType,
          device_brand: requestData.deviceBrand,
          device_model: requestData.deviceModel,
          issue_description: requestData.issueDescription,
          urgency: requestData.urgency,
          status: requestData.status || 'pending',
          priority: requestData.priority || 'medium',
          source: requestData.source || 'website',
          ip_address: requestData.ipAddress || null,
          user_agent: requestData.userAgent,
          // Nouveaux champs client
          company: requestData.company,
          vat_number: requestData.vatNumber,
          siren_number: requestData.sirenNumber,
          // Nouveaux champs adresse
          address: requestData.address,
          address_complement: requestData.addressComplement,
          city: requestData.city,
          postal_code: requestData.postalCode,
          region: requestData.region,
          // Nouveaux champs appareil
          device_id: requestData.deviceId,
          color: requestData.color,
          accessories: requestData.accessories,
          device_remarks: requestData.deviceRemarks,
        })
        .select()
        .single();

      if (error) {
        console.error('Erreur création demande:', error);
        return null;
      }

      return {
        id: data.id,
        requestNumber: data.request_number,
        customUrl: data.custom_url,
        technicianId: data.technician_id,
        clientFirstName: data.client_first_name,
        clientLastName: data.client_last_name,
        clientEmail: data.client_email,
        clientPhone: data.client_phone,
        description: data.description,
        deviceType: data.device_type,
        deviceBrand: data.device_brand,
        deviceModel: data.device_model,
        issueDescription: data.issue_description,
        urgency: data.urgency,
        attachments: [],
        status: data.status,
        priority: data.priority,
        response: data.response,
        estimatedPrice: data.estimated_price,
        estimatedDuration: data.estimated_duration,
        responseDate: data.response_date,
        ipAddress: data.ip_address,
        userAgent: data.user_agent,
        source: data.source,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at),
      };
    } catch (error) {
      console.error('Erreur lors de la création de la demande:', error);
      return null;
    }
  }

  // Récupérer les demandes de devis d'un réparateur
  static async getQuoteRequestsByTechnician(technicianId: string): Promise<any[]> {
    try {
      // Vérifier que l'utilisateur est authentifié
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        console.error('Utilisateur non authentifié:', authError);
        return [];
      }

      const { data, error } = await supabase
        .from('quote_requests')
        .select(`
          *,
          quote_request_attachments (*)
        `)
        .eq('technician_id', user.id) // Utiliser l'ID de l'utilisateur authentifié
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Erreur récupération demandes:', error);
        return [];
      }

      return data.map(item => ({
        id: item.id,
        requestNumber: item.request_number,
        customUrl: item.custom_url,
        technicianId: item.technician_id,
        clientFirstName: item.client_first_name,
        clientLastName: item.client_last_name,
        clientEmail: item.client_email,
        clientPhone: item.client_phone,
        description: item.description,
        deviceType: item.device_type,
        deviceBrand: item.device_brand,
        deviceModel: item.device_model,
        issueDescription: item.issue_description,
        urgency: item.urgency,
        attachments: item.quote_request_attachments || [],
        status: item.status,
        priority: item.priority,
        response: item.response,
        estimatedPrice: item.estimated_price,
        estimatedDuration: item.estimated_duration,
        responseDate: item.response_date,
        ipAddress: item.ip_address,
        userAgent: item.user_agent,
        source: item.source,
        createdAt: new Date(item.created_at),
        updatedAt: new Date(item.updated_at),
        // Nouveaux champs client
        company: item.company,
        vatNumber: item.vat_number,
        sirenNumber: item.siren_number,
        // Nouveaux champs adresse
        address: item.address,
        addressComplement: item.address_complement,
        city: item.city,
        postalCode: item.postal_code,
        region: item.region,
        // Nouveaux champs appareil
        deviceId: item.device_id,
        color: item.color,
        accessories: item.accessories,
        deviceRemarks: item.device_remarks,
      }));
    } catch (error) {
      console.error('Erreur lors de la récupération des demandes:', error);
      return [];
    }
  }

  // Récupérer les statistiques des demandes
  static async getQuoteRequestStats(technicianId: string): Promise<any> {
    try {
      // Vérifier que l'utilisateur est authentifié
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        console.error('Utilisateur non authentifié:', authError);
        return this.getDefaultStats();
      }

      const { data, error } = await supabase
        .rpc('get_quote_request_stats', { technician_uuid: user.id });

      if (error) {
        console.error('Erreur récupération stats:', error);
        // Fallback: calculer les stats manuellement
        return await this.calculateStatsManually(user.id);
      }

      return data || this.getDefaultStats();
    } catch (error) {
      console.error('Erreur lors de la récupération des statistiques:', error);
      return this.getDefaultStats();
    }
  }

  // Calculer les statistiques manuellement (fallback)
  private static async calculateStatsManually(technicianId: string): Promise<any> {
    try {
      const { data, error } = await supabase
        .from('quote_requests')
        .select('status, urgency, created_at')
        .eq('technician_id', technicianId);

      if (error) {
        console.error('Erreur calcul stats manuel:', error);
        return this.getDefaultStats();
      }

      const requests = data || [];
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay()));
      const startOfDay = new Date(now.setHours(0, 0, 0, 0));

      const stats = {
        total: requests.length,
        pending: requests.filter(r => r.status === 'pending').length,
        inReview: requests.filter(r => r.status === 'in_review').length,
        quoted: requests.filter(r => r.status === 'quoted').length,
        accepted: requests.filter(r => r.status === 'accepted').length,
        rejected: requests.filter(r => r.status === 'rejected').length,
        byUrgency: {
          low: requests.filter(r => r.urgency === 'low').length,
          medium: requests.filter(r => r.urgency === 'medium').length,
          high: requests.filter(r => r.urgency === 'high').length,
        },
        byStatus: {
          pending: requests.filter(r => r.status === 'pending').length,
          in_review: requests.filter(r => r.status === 'in_review').length,
          quoted: requests.filter(r => r.status === 'quoted').length,
          accepted: requests.filter(r => r.status === 'accepted').length,
          rejected: requests.filter(r => r.status === 'rejected').length,
          completed: requests.filter(r => r.status === 'completed').length,
          cancelled: requests.filter(r => r.status === 'cancelled').length,
        },
        monthly: requests.filter(r => new Date(r.created_at) >= startOfMonth).length,
        weekly: requests.filter(r => new Date(r.created_at) >= startOfWeek).length,
        daily: requests.filter(r => new Date(r.created_at) >= startOfDay).length,
      };

      return stats;
    } catch (error) {
      console.error('Erreur calcul stats manuel:', error);
      return this.getDefaultStats();
    }
  }

  // Statistiques par défaut
  private static getDefaultStats(): any {
    return {
      total: 0,
      pending: 0,
      inReview: 0,
      quoted: 0,
      accepted: 0,
      rejected: 0,
      byUrgency: { low: 0, medium: 0, high: 0 },
      byStatus: {
        pending: 0,
        in_review: 0,
        quoted: 0,
        accepted: 0,
        rejected: 0,
        completed: 0,
        cancelled: 0,
      },
      monthly: 0,
      weekly: 0,
      daily: 0,
    };
  }

  // Gérer les URLs personnalisées
  static async getCustomUrls(technicianId: string): Promise<any[]> {
    try {
      // Vérifier que l'utilisateur est authentifié
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        console.error('Utilisateur non authentifié:', authError);
        return [];
      }

      const { data, error } = await supabase
        .from('technician_custom_urls')
        .select('*')
        .eq('technician_id', user.id)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Erreur récupération URLs:', error);
        // Si la table n'existe pas, retourner une liste vide
        if (error.code === 'PGRST205') {
          console.warn('Table technician_custom_urls n\'existe pas encore. Utilisez le script SQL fourni.');
          return [];
        }
        return [];
      }

      return data?.map(item => ({
        id: item.id,
        technicianId: item.technician_id,
        customUrl: item.custom_url,
        isActive: item.is_active,
        createdAt: new Date(item.created_at),
        updatedAt: new Date(item.updated_at),
      })) || [];
    } catch (error) {
      console.error('Erreur lors de la récupération des URLs:', error);
      return [];
    }
  }

  static async createCustomUrl(technicianId: string, customUrl: string): Promise<any> {
    try {
      // Vérifier que l'utilisateur est authentifié
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        console.error('Utilisateur non authentifié:', authError);
        return null;
      }

      // Utiliser l'ID de l'utilisateur authentifié au lieu de celui passé en paramètre
      const { data, error } = await supabase
        .from('technician_custom_urls')
        .insert({
          technician_id: user.id, // Utiliser l'ID de l'utilisateur authentifié
          custom_url: customUrl,
          is_active: true,
        })
        .select()
        .single();

      if (error) {
        console.error('Erreur création URL:', error);
        return null;
      }

      return {
        id: data.id,
        technicianId: data.technician_id,
        customUrl: data.custom_url,
        isActive: data.is_active,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at),
      };
    } catch (error) {
      console.error('Erreur lors de la création de l\'URL:', error);
      return null;
    }
  }

  static async updateCustomUrlStatus(urlId: string, isActive: boolean): Promise<boolean> {
    try {
      const { error } = await supabase
        .from('technician_custom_urls')
        .update({ is_active: isActive })
        .eq('id', urlId);

      if (error) {
        console.error('Erreur mise à jour URL:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Erreur lors de la mise à jour de l\'URL:', error);
      return false;
    }
  }

  static async updateCustomUrl(urlId: string, newCustomUrl: string): Promise<boolean> {
    try {
      // Vérifier que la nouvelle URL n'est pas déjà utilisée
      const { data: existingUrl, error: checkError } = await supabase
        .from('technician_custom_urls')
        .select('id')
        .eq('custom_url', newCustomUrl)
        .neq('id', urlId)
        .single();

      if (existingUrl) {
        console.error('URL déjà utilisée');
        return false;
      }

      if (checkError && checkError.code !== 'PGRST116') {
        console.error('Erreur vérification URL:', checkError);
        return false;
      }

      // Mettre à jour l'URL
      const { error } = await supabase
        .from('technician_custom_urls')
        .update({ 
          custom_url: newCustomUrl,
          updated_at: new Date().toISOString()
        })
        .eq('id', urlId);

      if (error) {
        console.error('Erreur mise à jour URL:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Erreur lors de la mise à jour de l\'URL:', error);
      return false;
    }
  }

  static async deleteCustomUrl(urlId: string): Promise<boolean> {
    try {
      // Vérifier s'il y a des demandes associées à cette URL
      const { data: requests, error: checkError } = await supabase
        .from('quote_requests')
        .select('id')
        .eq('custom_url', (await supabase
          .from('technician_custom_urls')
          .select('custom_url')
          .eq('id', urlId)
          .single()
        ).data?.custom_url)
        .limit(1);

      if (checkError) {
        console.error('Erreur vérification demandes:', checkError);
        return false;
      }

      if (requests && requests.length > 0) {
        console.error('Impossible de supprimer: des demandes sont associées à cette URL');
        return false;
      }

      // Supprimer l'URL
      const { error } = await supabase
        .from('technician_custom_urls')
        .delete()
        .eq('id', urlId);

      if (error) {
        console.error('Erreur suppression URL:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Erreur lors de la suppression de l\'URL:', error);
      return false;
    }
  }

  static async getCustomUrlByUrl(customUrl: string): Promise<{ data: any; error: any }> {
    try {
      const { data, error } = await supabase
        .from('technician_custom_urls')
        .select('*')
        .eq('custom_url', customUrl)
        .eq('is_active', true)
        .single();

      return { data, error };
    } catch (error) {
      console.error('Erreur lors de la récupération de l\'URL personnalisée:', error);
      return { data: null, error };
    }
  }

  static async updateQuoteRequestStatus(requestId: string, newStatus: string): Promise<boolean> {
    try {
      const { error } = await supabase
        .from('quote_requests')
        .update({ 
          status: newStatus,
          updated_at: new Date().toISOString()
        })
        .eq('id', requestId);

      if (error) {
        console.error('Erreur lors de la mise à jour du statut:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Erreur lors de la mise à jour du statut:', error);
      return false;
    }
  }
}

export const quoteRequestServiceReal = QuoteRequestServiceReal;
