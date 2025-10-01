import { supabase } from '../lib/supabase';
import { QuoteRequest, QuoteRequestAttachment, TechnicianCustomUrl, QuoteRequestStats } from '../types';

export class QuoteRequestService {
  // Récupérer les informations d'un réparateur par son URL personnalisée
  static async getTechnicianByCustomUrl(customUrl: string): Promise<{
    technician: any;
    customUrlData: TechnicianCustomUrl;
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
  static async createQuoteRequest(requestData: Omit<QuoteRequest, 'id' | 'requestNumber' | 'createdAt' | 'updatedAt'>): Promise<QuoteRequest | null> {
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
          status: requestData.status,
          priority: requestData.priority,
          source: requestData.source,
          ip_address: requestData.ipAddress,
          user_agent: requestData.userAgent,
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
  static async getQuoteRequestsByTechnician(technicianId: string): Promise<QuoteRequest[]> {
    try {
      const { data, error } = await supabase
        .from('quote_requests')
        .select(`
          *,
          quote_request_attachments (*)
        `)
        .eq('technician_id', technicianId)
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
      }));
    } catch (error) {
      console.error('Erreur lors de la récupération des demandes:', error);
      return [];
    }
  }

  // Mettre à jour le statut d'une demande
  static async updateQuoteRequestStatus(
    requestId: string, 
    status: string, 
    response?: string,
    estimatedPrice?: number,
    estimatedDuration?: number
  ): Promise<boolean> {
    try {
      const updateData: any = {
        status,
        updated_at: new Date().toISOString(),
      };

      if (response) updateData.response = response;
      if (estimatedPrice) updateData.estimated_price = estimatedPrice;
      if (estimatedDuration) updateData.estimated_duration = estimatedDuration;
      if (status === 'quoted') updateData.response_date = new Date().toISOString();

      const { error } = await supabase
        .from('quote_requests')
        .update(updateData)
        .eq('id', requestId);

      if (error) {
        console.error('Erreur mise à jour statut:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Erreur lors de la mise à jour:', error);
      return false;
    }
  }

  // Récupérer les statistiques des demandes
  static async getQuoteRequestStats(technicianId: string): Promise<QuoteRequestStats | null> {
    try {
      const { data, error } = await supabase
        .rpc('get_quote_request_stats', { technician_uuid: technicianId });

      if (error) {
        console.error('Erreur récupération stats:', error);
        return null;
      }

      return data;
    } catch (error) {
      console.error('Erreur lors de la récupération des statistiques:', error);
      return null;
    }
  }

  // Gérer les URLs personnalisées
  static async getCustomUrls(technicianId: string): Promise<TechnicianCustomUrl[]> {
    try {
      const { data, error } = await supabase
        .from('technician_custom_urls')
        .select('*')
        .eq('technician_id', technicianId)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Erreur récupération URLs:', error);
        return [];
      }

      return data.map(item => ({
        id: item.id,
        technicianId: item.technician_id,
        customUrl: item.custom_url,
        isActive: item.is_active,
        createdAt: new Date(item.created_at),
        updatedAt: new Date(item.updated_at),
      }));
    } catch (error) {
      console.error('Erreur lors de la récupération des URLs:', error);
      return [];
    }
  }

  static async createCustomUrl(technicianId: string, customUrl: string): Promise<TechnicianCustomUrl | null> {
    try {
      const { data, error } = await supabase
        .from('technician_custom_urls')
        .insert({
          technician_id: technicianId,
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

  // Upload de fichiers
  static async uploadAttachment(
    file: File, 
    quoteRequestId: string
  ): Promise<QuoteRequestAttachment | null> {
    try {
      // Générer un nom de fichier unique
      const fileExt = file.name.split('.').pop();
      const fileName = `${crypto.randomUUID()}.${fileExt}`;
      const filePath = `quote-requests/${quoteRequestId}/${fileName}`;

      // Upload du fichier vers Supabase Storage
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('attachments')
        .upload(filePath, file, {
          cacheControl: '3600',
          upsert: false,
        });

      if (uploadError) {
        console.error('Erreur upload fichier:', uploadError);
        return null;
      }

      // Enregistrer les métadonnées en base
      const { data, error } = await supabase
        .from('quote_request_attachments')
        .insert({
          quote_request_id: quoteRequestId,
          file_name: fileName,
          original_name: file.name,
          file_size: file.size,
          mime_type: file.type,
          file_path: filePath,
        })
        .select()
        .single();

      if (error) {
        console.error('Erreur enregistrement métadonnées:', error);
        return null;
      }

      return {
        id: data.id,
        quoteRequestId: data.quote_request_id,
        fileName: data.file_name,
        originalName: data.original_name,
        fileSize: data.file_size,
        mimeType: data.mime_type,
        filePath: data.file_path,
        uploadedAt: new Date(data.uploaded_at),
      };
    } catch (error) {
      console.error('Erreur lors de l\'upload:', error);
      return null;
    }
  }

  // Récupérer l'URL de téléchargement d'un fichier
  static async getAttachmentUrl(filePath: string): Promise<string | null> {
    try {
      const { data, error } = await supabase.storage
        .from('attachments')
        .createSignedUrl(filePath, 3600); // URL valide 1 heure

      if (error) {
        console.error('Erreur génération URL:', error);
        return null;
      }

      return data.signedUrl;
    } catch (error) {
      console.error('Erreur lors de la génération de l\'URL:', error);
      return null;
    }
  }

  // Supprimer un fichier joint
  static async deleteAttachment(attachmentId: string): Promise<boolean> {
    try {
      // Récupérer les informations du fichier
      const { data: attachment, error: fetchError } = await supabase
        .from('quote_request_attachments')
        .select('file_path')
        .eq('id', attachmentId)
        .single();

      if (fetchError || !attachment) {
        console.error('Fichier non trouvé:', fetchError);
        return false;
      }

      // Supprimer le fichier du storage
      const { error: deleteError } = await supabase.storage
        .from('attachments')
        .remove([attachment.file_path]);

      if (deleteError) {
        console.error('Erreur suppression fichier:', deleteError);
      }

      // Supprimer l'enregistrement en base
      const { error: dbError } = await supabase
        .from('quote_request_attachments')
        .delete()
        .eq('id', attachmentId);

      if (dbError) {
        console.error('Erreur suppression enregistrement:', dbError);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Erreur lors de la suppression:', error);
      return false;
    }
  }

  // Valider une URL personnalisée
  static async validateCustomUrl(customUrl: string): Promise<{ isValid: boolean; message?: string }> {
    try {
      // Vérifier le format
      if (!/^[a-zA-Z0-9-]+$/.test(customUrl)) {
        return { isValid: false, message: 'L\'URL ne peut contenir que des lettres, chiffres et tirets' };
      }

      if (customUrl.length < 3 || customUrl.length > 50) {
        return { isValid: false, message: 'L\'URL doit contenir entre 3 et 50 caractères' };
      }

      if (customUrl.startsWith('-') || customUrl.endsWith('-')) {
        return { isValid: false, message: 'L\'URL ne peut pas commencer ou finir par un tiret' };
      }

      // Vérifier l'unicité
      const { data, error } = await supabase
        .from('technician_custom_urls')
        .select('id')
        .eq('custom_url', customUrl)
        .single();

      if (data) {
        return { isValid: false, message: 'Cette URL est déjà utilisée' };
      }

      if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
        console.error('Erreur vérification unicité:', error);
        return { isValid: false, message: 'Erreur lors de la vérification' };
      }

      return { isValid: true };
    } catch (error) {
      console.error('Erreur lors de la validation:', error);
      return { isValid: false, message: 'Erreur lors de la validation' };
    }
  }
}

export const quoteRequestService = QuoteRequestService;
