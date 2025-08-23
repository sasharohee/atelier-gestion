import { supabase, handleSupabaseError, handleSupabaseSuccess } from '../lib/supabase';
import {
  User,
  Client,
  Device,
  Service,
  Part,
  Product,
  Repair,
  Message,
  Appointment,
  Sale,
  StockAlert,
  Notification,
  DashboardStats
} from '../types';

// Service pour les paramètres système
export const systemSettingsService = {
  async getAll() {
    console.log('🔍 systemSettingsService.getAll() appelé');
    try {
      // Récupérer l'utilisateur actuel
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        console.log('❌ Aucun utilisateur connecté');
        return handleSupabaseSuccess([]);
      }

      const { data, error } = await supabase
        .from('system_settings')
        .select('*')
        .eq('user_id', user.id)
        .order('category', { ascending: true })
        .order('key', { ascending: true });
      
      console.log('📊 Résultat Supabase:', { data, error });
      
      if (error) {
        console.error('❌ Erreur Supabase:', error);
        return handleSupabaseError(error);
      }
      
      console.log('✅ Données récupérées:', data);
      return handleSupabaseSuccess(data || []);
    } catch (err) {
      console.error('💥 Exception dans getAll:', err);
      return handleSupabaseSuccess([]);
    }
  },

  async getByCategory(category: string) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseSuccess([]);
      }

      const { data, error } = await supabase
        .from('system_settings')
        .select('*')
        .eq('user_id', user.id)
        .eq('category', category)
        .order('key', { ascending: true });
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(data || []);
    } catch (err) {
      return handleSupabaseSuccess([]);
    }
  },

  async getByKey(key: string) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { data, error } = await supabase
        .from('system_settings')
        .select('*')
        .eq('user_id', user.id)
        .eq('key', key)
        .single();
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(data);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async update(key: string, value: string) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { data, error } = await supabase
        .from('system_settings')
        .update({ value, updated_at: new Date().toISOString() })
        .eq('user_id', user.id)
        .eq('key', key)
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(data);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async updateMultiple(settings: Array<{ key: string; value: string }>) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const updates = settings.map(setting => ({
        user_id: user.id,
        key: setting.key,
        value: setting.value,
        updated_at: new Date().toISOString()
      }));

      const { data, error } = await supabase
        .from('system_settings')
        .upsert(updates, { onConflict: 'user_id,key' })
        .select();
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(data || []);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async create(setting: { key: string; value: string; description?: string; category?: string }) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { data, error } = await supabase
        .from('system_settings')
        .insert([{
          user_id: user.id,
          key: setting.key,
          value: setting.value,
          description: setting.description,
          category: setting.category || 'general'
        }])
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(data);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async delete(key: string) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { error } = await supabase
        .from('system_settings')
        .delete()
        .eq('user_id', user.id)
        .eq('key', key);
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(true);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  }
};

// Service pour les utilisateurs
export const userService = {
  async getCurrentUser() {
    try {
      // D'abord essayer de récupérer l'utilisateur depuis Supabase Auth
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError || !user) {
        console.log('⚠️ Aucun utilisateur authentifié via Supabase Auth');
        return handleSupabaseSuccess(null);
      }
      
      // Ensuite récupérer les détails complets depuis notre table users
      const { data: userData, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .single();
      
      if (userError) {
        console.log('⚠️ Utilisateur non trouvé dans la table users, utilisation des données auth');
        return handleSupabaseSuccess(user);
      }
      
      // Convertir les données de snake_case vers camelCase
      const convertedUser = {
        id: userData.id,
        firstName: userData.first_name || userData.firstName,
        lastName: userData.last_name || userData.lastName,
        email: userData.email,
        role: userData.role || 'technician',
        avatar: userData.avatar,
        createdAt: userData.created_at ? new Date(userData.created_at) : new Date(),
        updatedAt: userData.updated_at ? new Date(userData.updated_at) : new Date()
      };
      
      return handleSupabaseSuccess(convertedUser);
    } catch (err) {
      console.error('❌ Erreur dans getCurrentUser:', err);
      return handleSupabaseError(err as any);
    }
  },

  async getAllUsers() {
    console.log('🔍 getAllUsers() appelé');
    
    try {
      // Utiliser la fonction RPC pour récupérer seulement les utilisateurs créés par l'utilisateur actuel
      let { data, error } = await supabase.rpc('get_my_users');
      
      if (error) {
        console.error('❌ Erreur lors de la récupération des utilisateurs:', error);
        
        // Fallback vers la récupération normale si la fonction RPC n'existe pas
        console.log('⚠️ Fonction RPC non disponible, utilisation de la récupération normale...');
        const { data: fallbackData, error: fallbackError } = await supabase
          .from('users')
          .select('*')
          .order('created_at', { ascending: false });
        
        if (fallbackError) {
          console.error('❌ Erreur lors de la récupération de fallback:', fallbackError);
          return handleSupabaseError(fallbackError);
        }
        
        data = fallbackData;
      }
      
      console.log('📊 Données brutes récupérées:', data);
      
      // Convertir les données de snake_case vers camelCase
      const convertedData = data?.map((user: any) => ({
        id: user.id,
        firstName: user.first_name || user.firstName,
        lastName: user.last_name || user.lastName,
        email: user.email,
        role: user.role || 'technician',
        avatar: user.avatar,
        createdAt: user.created_at ? new Date(user.created_at) : new Date(),
        updatedAt: user.updated_at ? new Date(user.updated_at) : new Date()
      })) || [];
      
      console.log('✅ Utilisateurs convertis:', convertedData);
      return handleSupabaseSuccess(convertedData);
    } catch (err) {
      console.error('❌ Erreur inattendue dans getAllUsers:', err);
      return handleSupabaseError(err as any);
    }
  },

  async createUser(userData: Omit<User, 'id' | 'createdAt' | 'updatedAt'> & { password: string }) {
    try {
      console.log('🔧 Création d\'utilisateur:', userData);
      
      // Vérifier si l'email existe déjà (approche plus robuste)
      const { data: existingUsers, error: checkError } = await supabase
        .from('users')
        .select('id, email')
        .eq('email', userData.email);

      if (checkError) {
        console.error('❌ Erreur lors de la vérification de l\'email:', checkError);
        return handleSupabaseError(checkError);
      }

      if (existingUsers && existingUsers.length > 0) {
        console.error('❌ Email déjà utilisé:', userData.email);
        return handleSupabaseError({
          message: `L'email "${userData.email}" est déjà utilisé par un autre utilisateur.`,
          code: 'EMAIL_EXISTS'
        });
      }
      
      // Essayer d'abord la fonction RPC principale
      let rpcData, rpcError;
      
      try {
        const result = await supabase.rpc('create_user_with_email_check', {
          p_user_id: crypto.randomUUID(),
          p_first_name: userData.firstName,
          p_last_name: userData.lastName,
          p_email: userData.email,
          p_role: userData.role,
          p_avatar: userData.avatar
        });
        rpcData = result.data;
        rpcError = result.error;
      } catch (err) {
        console.log('⚠️ Fonction RPC principale non disponible, essai avec fallback...');
        rpcError = err;
      }

      // Si la fonction principale échoue, essayer la fonction de fallback
      if (rpcError) {
        try {
          const fallbackResult = await supabase.rpc('create_user_simple_fallback', {
            p_user_id: crypto.randomUUID(),
            p_first_name: userData.firstName,
            p_last_name: userData.lastName,
            p_email: userData.email,
            p_role: userData.role,
            p_avatar: userData.avatar
          });
          rpcData = fallbackResult.data;
          rpcError = fallbackResult.error;
        } catch (fallbackErr) {
          console.error('❌ Erreur lors de l\'appel RPC de fallback:', fallbackErr);
          rpcError = fallbackErr;
        }
      }

      if (rpcError) {
        console.error('❌ Erreur lors de l\'appel RPC:', rpcError);
        return handleSupabaseError(rpcError);
      }

      if (!rpcData || !rpcData.success) {
        console.error('❌ Erreur lors de la création:', rpcData?.error);
        return handleSupabaseError({ 
          message: rpcData?.error || 'Erreur lors de la création de l\'utilisateur',
          code: 'RPC_ERROR'
        });
      }

      console.log('✅ Utilisateur créé avec succès:', rpcData.data);
      return handleSupabaseSuccess(rpcData.data);
    } catch (err) {
      console.error('💥 Exception lors de la création:', err);
      return handleSupabaseError(err as any);
    }
  },

  async updateUser(id: string, updates: Partial<User>) {
    try {
      console.log('🔧 Mise à jour d\'utilisateur:', { id, updates });
      
      // Mettre à jour l'enregistrement dans la table users
      const updateData: any = {
        updated_at: new Date().toISOString()
      };

      if (updates.firstName) updateData.first_name = updates.firstName;
      if (updates.lastName) updateData.last_name = updates.lastName;
      if (updates.role) updateData.role = updates.role;
      if (updates.avatar) updateData.avatar = updates.avatar;

      console.log('📝 Données de mise à jour:', updateData);

      const { data, error } = await supabase
        .from('users')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

      if (error) {
        console.error('❌ Erreur lors de la mise à jour:', error);
        return handleSupabaseError(error);
      }
      
      console.log('✅ Utilisateur mis à jour avec succès:', data);
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('💥 Exception lors de la mise à jour:', err);
      return handleSupabaseError(err as any);
    }
  },

  async deleteUser(id: string) {
    try {
      console.log('🔧 Suppression d\'utilisateur:', id);
      
      // Supprimer l'enregistrement de la table users
      const { error } = await supabase
        .from('users')
        .delete()
        .eq('id', id);

      if (error) {
        console.error('❌ Erreur lors de la suppression:', error);
        return handleSupabaseError(error);
      }
      
      console.log('✅ Utilisateur supprimé avec succès');
      return handleSupabaseSuccess(true);
    } catch (err) {
      console.error('💥 Exception lors de la suppression:', err);
      return handleSupabaseError(err as any);
    }
  },

  async signIn(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async signUp(email: string, password: string, userData: Partial<User>) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: userData,
        emailRedirectTo: `${window.location.origin}/auth?tab=confirm`
      }
    });
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Fonction utilitaire pour récupérer l'utilisateur connecté avec son rôle
async function getCurrentUser(): Promise<{ id: string; role: string } | null> {
  try {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) {
      console.log('⚠️ Aucun utilisateur authentifié');
      return null;
    }
    
    // Récupérer tous les utilisateurs et filtrer côté client pour éviter les erreurs 406
    const { data: allUsers, error: userError } = await supabase
      .from('users')
      .select('*');
    
    if (userError) {
      console.log('⚠️ Erreur lors de la récupération des utilisateurs:', userError);
      return null;
    }
    
    // Chercher l'utilisateur connecté dans la liste
    const currentUser = allUsers?.find(u => u.id === user.id);
    
    if (!currentUser) {
      console.log('⚠️ Utilisateur non trouvé dans la table users:', user.id);
      
      // Tentative de création automatique de l'utilisateur via fonction RPC
      try {
        console.log('🔄 Tentative de création automatique de l\'utilisateur via fonction RPC...');
        
        // Essayer différents rôles dans l'ordre de priorité
        const rolesToTry = ['technician', 'manager', 'admin', 'user'];
        let newUser = null;
        let insertError = null;
        
        for (const role of rolesToTry) {
          try {
            const { data, error } = await supabase.rpc('create_user_automatically', {
              user_id: user.id,
              first_name: user.user_metadata?.first_name || 'Utilisateur',
              last_name: user.user_metadata?.last_name || 'Test',
              user_email: user.email,
              user_role: role
            });
            
            if (!error && data && data.success) {
              newUser = data.user;
              console.log('✅ Utilisateur créé automatiquement avec le rôle:', role);
              break;
            } else {
              console.log(`⚠️ Rôle '${role}' non autorisé, essai suivant...`);
              insertError = error || data?.error;
            }
          } catch (err) {
            console.log(`⚠️ Erreur avec le rôle '${role}':`, err);
            insertError = err;
          }
        }
        
        if (!newUser) {
          console.error('❌ Aucun rôle autorisé trouvé pour la création automatique:', insertError);
          return null;
        }
        
        console.log('✅ Utilisateur créé automatiquement dans la table users:', newUser.id, 'Rôle:', newUser.role);
        return { id: newUser.id, role: newUser.role };
      } catch (createErr) {
        console.error('❌ Erreur lors de la création automatique:', createErr);
        return null;
      }
    }
    
    console.log('✅ Utilisateur trouvé dans la table users:', currentUser.id, 'Rôle:', currentUser.role);
    return { id: currentUser.id, role: currentUser.role };
  } catch (err) {
    console.error('❌ Erreur lors de la récupération de l\'utilisateur:', err);
    return null;
  }
}

// Fonction utilitaire pour récupérer l'utilisateur connecté (compatibilité)
async function getCurrentUserId(): Promise<string | null> {
  const user = await getCurrentUser();
  return user?.id || null;
}

// Service pour les clients
export const clientService = {
  async getAll() {
    // Utiliser directement l'authentification Supabase pour l'isolation
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError || !user) {
      console.log('⚠️ Aucun utilisateur connecté, retourner une liste vide');
      return handleSupabaseSuccess([]);
    }
    
    console.log('🔒 Récupération des clients pour l\'utilisateur:', user.id);
    
    // La politique RLS va automatiquement filtrer les données
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(client => ({
      id: client.id,
      firstName: client.first_name,
      lastName: client.last_name,
      email: client.email,
      phone: client.phone,
      address: client.address,
      notes: client.notes,
      createdAt: client.created_at,
      updatedAt: client.updated_at
    })) || [];
    
    console.log('✅ Clients récupérés:', convertedData.length, 'pour l\'utilisateur:', user.id);
    return handleSupabaseSuccess(convertedData);
  },

  async getById(id: string) {
    // Récupérer l'utilisateur connecté
    const currentUserId = await getCurrentUserId();
    
    if (!currentUserId) {
      console.log('⚠️ Aucun utilisateur connecté, récupération du client sans filtrage');
      const { data, error } = await supabase
        .from('clients')
        .select('*')
        .eq('id', id)
        .single();
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(data);
    }
    
    // Récupérer le client de l'utilisateur connecté
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('id', id)
      .eq('user_id', currentUserId)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(client: Omit<Client, 'id' | 'createdAt' | 'updatedAt'>) {
    // Récupérer l'utilisateur connecté
    const currentUserId = await getCurrentUserId();
    
    // Convertir les noms de propriétés camelCase vers snake_case
    const clientData = {
      first_name: client.firstName,
      last_name: client.lastName,
      email: client.email,
      phone: client.phone,
      address: client.address,
      notes: client.notes,
      user_id: currentUserId || '00000000-0000-0000-0000-000000000000', // Utiliser l'utilisateur système par défaut si non connecté
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('clients')
      .insert([clientData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Client>) {
    // Récupérer l'utilisateur connecté
    const currentUserId = await getCurrentUserId();
    
    if (!currentUserId) {
      console.log('⚠️ Aucun utilisateur connecté, mise à jour sans filtrage');
      const { data, error } = await supabase
        .from('clients')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(data);
    }
    
    // Mettre à jour le client de l'utilisateur connecté
    const { data, error } = await supabase
      .from('clients')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('user_id', currentUserId)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    // Récupérer l'utilisateur connecté
    const currentUserId = await getCurrentUserId();
    
    if (!currentUserId) {
      console.log('⚠️ Aucun utilisateur connecté, suppression sans filtrage');
      const { error } = await supabase
        .from('clients')
        .delete()
        .eq('id', id);
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(true);
    }
    
    // Supprimer le client de l'utilisateur connecté
    const { error } = await supabase
      .from('clients')
      .delete()
      .eq('id', id)
      .eq('user_id', currentUserId);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les appareils
export const deviceService = {
  async getAll() {
    // Utiliser directement l'authentification Supabase pour l'isolation
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError || !user) {
      console.log('⚠️ Aucun utilisateur connecté, retourner une liste vide');
      return handleSupabaseSuccess([]);
    }
    
    console.log('🔒 Récupération des appareils pour l\'utilisateur:', user.id);
    
    // La politique RLS va automatiquement filtrer les données
    const { data, error } = await supabase
      .from('devices')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(device => ({
      id: device.id,
      brand: device.brand,
      model: device.model,
      serialNumber: device.serial_number,
      type: device.type,
      specifications: device.specifications,
      createdAt: device.created_at,
      updatedAt: device.updated_at
    })) || [];
    
    console.log('✅ Appareils récupérés:', convertedData.length, 'pour l\'utilisateur:', user.id);
    return handleSupabaseSuccess(convertedData);
  },

  async getById(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('devices')
      .select('*')
      .eq('id', id)
      .eq('user_id', user.id)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(device: Omit<Device, 'id' | 'createdAt' | 'updatedAt'>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Convertir les noms de propriétés camelCase vers snake_case
    const deviceData = {
      brand: device.brand,
      model: device.model,
      serial_number: device.serialNumber,
      type: device.type,
      specifications: device.specifications,
      user_id: user.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('devices')
      .insert([deviceData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Device>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('devices')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { error } = await supabase
      .from('devices')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les réparations
export const repairService = {
  async getAll() {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('repairs')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(repair => ({
      id: repair.id,
      clientId: repair.client_id,
      deviceId: repair.device_id,
      status: repair.status,
      assignedTechnicianId: repair.assigned_technician_id,
      description: repair.description,
      issue: repair.issue,
      estimatedDuration: repair.estimated_duration,
      actualDuration: repair.actual_duration,
      estimatedStartDate: repair.estimated_start_date,
      estimatedEndDate: repair.estimated_end_date,
      startDate: repair.start_date,
      endDate: repair.end_date,
      dueDate: repair.due_date,
      isUrgent: repair.is_urgent,
      notes: repair.notes,
      services: [], // Tableau vide par défaut
      parts: [], // Tableau vide par défaut
      totalPrice: repair.total_price,
      isPaid: repair.is_paid,
      createdAt: repair.created_at,
      updatedAt: repair.updated_at
    })) || [];
    
    return handleSupabaseSuccess(convertedData);
  },

  async getById(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('repairs')
      .select('*')
      .eq('id', id)
      .eq('user_id', user.id)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(repair: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Vérifier que le client appartient à l'utilisateur connecté ou est un client système
    if (repair.clientId) {
      const { data: clientData, error: clientError } = await supabase
        .from('clients')
        .select('id')
        .eq('id', repair.clientId)
        .or(`user_id.eq.${user.id},user_id.eq.00000000-0000-0000-0000-000000000000`)
        .single();
      
      if (clientError || !clientData) {
        return handleSupabaseError(new Error('Client non trouvé ou n\'appartient pas à l\'utilisateur connecté'));
      }
    }

    // Vérifier que le device appartient à l'utilisateur connecté ou est un device système
    if (repair.deviceId) {
      const { data: deviceData, error: deviceError } = await supabase
        .from('devices')
        .select('id')
        .eq('id', repair.deviceId)
        .or(`user_id.eq.${user.id},user_id.eq.00000000-0000-0000-0000-000000000000`)
        .single();
      
      if (deviceError || !deviceData) {
        return handleSupabaseError(new Error('Appareil non trouvé ou n\'appartient pas à l\'utilisateur connecté'));
      }
    }

    // Convertir les noms de propriétés camelCase vers snake_case
    const repairData = {
      client_id: repair.clientId,
      device_id: repair.deviceId,
      status: repair.status,
      assigned_technician_id: repair.assignedTechnicianId,
      description: repair.description,
      issue: repair.issue,
      estimated_duration: repair.estimatedDuration,
      actual_duration: repair.actualDuration,
      estimated_start_date: repair.estimatedStartDate,
      estimated_end_date: repair.estimatedEndDate,
      start_date: repair.startDate,
      end_date: repair.endDate,
      due_date: repair.dueDate,
      is_urgent: repair.isUrgent,
      notes: repair.notes,
      total_price: repair.totalPrice,
      is_paid: repair.isPaid,
      user_id: user.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('repairs')
      .insert([repairData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Repair>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Convertir les noms de propriétés camelCase vers snake_case
    const updateData: any = { updated_at: new Date().toISOString() };
    
    if (updates.clientId !== undefined) updateData.client_id = updates.clientId;
    if (updates.deviceId !== undefined) updateData.device_id = updates.deviceId;
    if (updates.status !== undefined) updateData.status = updates.status;
    if (updates.assignedTechnicianId !== undefined) updateData.assigned_technician_id = updates.assignedTechnicianId;
    if (updates.description !== undefined) updateData.description = updates.description;
    if (updates.issue !== undefined) updateData.issue = updates.issue;
    if (updates.estimatedDuration !== undefined) updateData.estimated_duration = updates.estimatedDuration;
    if (updates.actualDuration !== undefined) updateData.actual_duration = updates.actualDuration;
    if (updates.estimatedStartDate !== undefined) updateData.estimated_start_date = updates.estimatedStartDate;
    if (updates.estimatedEndDate !== undefined) updateData.estimated_end_date = updates.estimatedEndDate;
    if (updates.startDate !== undefined) updateData.start_date = updates.startDate;
    if (updates.endDate !== undefined) updateData.end_date = updates.endDate;
    if (updates.dueDate !== undefined) updateData.due_date = updates.dueDate;
    if (updates.isUrgent !== undefined) updateData.is_urgent = updates.isUrgent;
    if (updates.notes !== undefined) updateData.notes = updates.notes;
    if (updates.totalPrice !== undefined) updateData.total_price = updates.totalPrice;
    if (updates.isPaid !== undefined) updateData.is_paid = updates.isPaid;

    const { data, error } = await supabase
      .from('repairs')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { error } = await supabase
      .from('repairs')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  },

  async getByStatus(status: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('repairs')
      .select('*')
      .eq('status', status)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  }
};

// Service pour les pièces
export const partService = {
  async getAll() {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('parts')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async getById(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('parts')
      .select('*')
      .eq('id', id)
      .eq('user_id', user.id)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(part: Omit<Part, 'id' | 'createdAt' | 'updatedAt'>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Convertir les noms de propriétés camelCase vers snake_case
    const partData = {
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
      user_id: user.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('parts')
      .insert([partData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Part>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Convertir les noms de colonnes de camelCase vers snake_case
    const dbUpdates: any = { updated_at: new Date().toISOString() };
    
    if (updates.name !== undefined) dbUpdates.name = updates.name;
    if (updates.description !== undefined) dbUpdates.description = updates.description;
    if (updates.partNumber !== undefined) dbUpdates.part_number = updates.partNumber;
    if (updates.brand !== undefined) dbUpdates.brand = updates.brand;
    if (updates.compatibleDevices !== undefined) dbUpdates.compatible_devices = updates.compatibleDevices;
    if (updates.stockQuantity !== undefined) dbUpdates.stock_quantity = updates.stockQuantity;
    if (updates.minStockLevel !== undefined) dbUpdates.min_stock_level = updates.minStockLevel;
    if (updates.price !== undefined) dbUpdates.price = updates.price;
    if (updates.supplier !== undefined) dbUpdates.supplier = updates.supplier;
    if (updates.isActive !== undefined) dbUpdates.is_active = updates.isActive;

    const { data, error } = await supabase
      .from('parts')
      .update(dbUpdates)
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { error } = await supabase
      .from('parts')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  },

  async getLowStock() {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('parts')
      .select('*')
      .eq('user_id', user.id)
      .lte('stock_quantity', 5)
      .order('stock_quantity', { ascending: true });
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  }
};

// Service pour les produits
export const productService = {
  async getAll() {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async getById(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .eq('user_id', user.id)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(product: Omit<Product, 'id' | 'createdAt' | 'updatedAt'>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Convertir les noms de propriétés camelCase vers snake_case
    const productData = {
      name: product.name,
      description: product.description,
      category: product.category,
      price: product.price,
      stock_quantity: product.stockQuantity,
      is_active: product.isActive,
      user_id: user.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('products')
      .insert([productData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Product>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Convertir les noms de colonnes de camelCase vers snake_case
    const dbUpdates: any = { updated_at: new Date().toISOString() };
    
    if (updates.name !== undefined) dbUpdates.name = updates.name;
    if (updates.description !== undefined) dbUpdates.description = updates.description;
    if (updates.category !== undefined) dbUpdates.category = updates.category;
    if (updates.price !== undefined) dbUpdates.price = updates.price;
    if (updates.stockQuantity !== undefined) dbUpdates.stock_quantity = updates.stockQuantity;
    if (updates.isActive !== undefined) dbUpdates.is_active = updates.isActive;

    const { data, error } = await supabase
      .from('products')
      .update(dbUpdates)
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les ventes
export const saleService = {
  async getAll() {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('sales')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(sale => ({
      id: sale.id,
      clientId: sale.client_id,
      items: sale.items || [],
      subtotal: sale.subtotal,
      tax: sale.tax,
      total: sale.total,
      paymentMethod: sale.payment_method,
      status: sale.status,
      createdAt: sale.created_at,
      updatedAt: sale.updated_at
    })) || [];
    
    return handleSupabaseSuccess(convertedData);
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('sales')
      .select(`
        *,
        client:clients(*),
        product:products(*)
      `)
      .eq('id', id)
      .single();
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data ? {
      id: data.id,
      clientId: data.client_id,
      items: data.items || [],
      subtotal: data.subtotal,
      tax: data.tax,
      total: data.total,
      paymentMethod: data.payment_method,
      status: data.status,
      createdAt: data.created_at,
      updatedAt: data.updated_at,
      client: data.client,
      product: data.product
    } : null;
    
    return handleSupabaseSuccess(convertedData);
  },

  async create(sale: Omit<Sale, 'id' | 'createdAt' | 'updatedAt'>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Vérifier que le client appartient à l'utilisateur connecté
    if (sale.clientId) {
      const { data: clientData, error: clientError } = await supabase
        .from('clients')
        .select('id')
        .eq('id', sale.clientId)
        .eq('user_id', user.id)
        .single();
      
      if (clientError || !clientData) {
        return handleSupabaseError(new Error('Client non trouvé ou n\'appartient pas à l\'utilisateur connecté'));
      }
    }

    // Convertir les noms de propriétés camelCase vers snake_case
    const saleData = {
      client_id: sale.clientId,
      items: JSON.stringify(sale.items || []),
      subtotal: sale.subtotal,
      tax: sale.tax,
      total: sale.total,
      payment_method: sale.paymentMethod,
      status: sale.status,
      user_id: user.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('sales')
      .insert([saleData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Sale>) {
    // Convertir les noms de propriétés camelCase vers snake_case
    const updateData: any = { updated_at: new Date().toISOString() };
    
    if (updates.clientId !== undefined) updateData.client_id = updates.clientId;
    if (updates.items !== undefined) updateData.items = updates.items;
    if (updates.subtotal !== undefined) updateData.subtotal = updates.subtotal;
    if (updates.tax !== undefined) updateData.tax = updates.tax;
    if (updates.total !== undefined) updateData.total = updates.total;
    if (updates.paymentMethod !== undefined) updateData.payment_method = updates.paymentMethod;
    if (updates.status !== undefined) updateData.status = updates.status;

    const { data, error } = await supabase
      .from('sales')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('sales')
      .delete()
      .eq('id', id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les services
export const serviceService = {
  async getAll() {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('services')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async getById(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('services')
      .select('*')
      .eq('id', id)
      .eq('user_id', user.id)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(service: Omit<Service, 'id' | 'createdAt' | 'updatedAt'>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Convertir les noms de propriétés camelCase vers snake_case
    const serviceData = {
      name: service.name,
      description: service.description,
      duration: service.duration,
      price: service.price,
      category: service.category,
      applicable_devices: service.applicableDevices,
      is_active: service.isActive,
      user_id: user.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('services')
      .insert([serviceData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Service>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('services')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { error } = await supabase
      .from('services')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les rendez-vous
export const appointmentService = {
  async getAll() {
    // Récupérer l'utilisateur connecté avec son rôle
    const currentUser = await getCurrentUser();
    
    if (!currentUser) {
      console.log('⚠️ Aucun utilisateur connecté, retourner une liste vide');
      return handleSupabaseSuccess([]);
    }
    
    // Si l'utilisateur est admin, récupérer tous les rendez-vous
    if (currentUser.role === 'admin') {
      console.log('🔧 Utilisateur admin, récupération de tous les rendez-vous');
      const { data, error } = await supabase
        .from('appointments')
        .select('*')
        .order('start_date', { ascending: true });
      
      if (error) return handleSupabaseError(error);
      
      const convertedData = data?.map(appointment => ({
        id: appointment.id,
        userId: appointment.user_id,
        clientId: appointment.client_id,
        repairId: appointment.repair_id,
        title: appointment.title,
        description: appointment.description,
        startDate: new Date(appointment.start_date),
        endDate: new Date(appointment.end_date),
        assignedUserId: appointment.assigned_user_id,
        status: appointment.status,
        createdAt: new Date(appointment.created_at),
        updatedAt: new Date(appointment.updated_at)
      })) || [];
      
      return handleSupabaseSuccess(convertedData);
    }
    
    // Sinon, récupérer les rendez-vous de l'utilisateur connecté ET les rendez-vous système
    console.log('🔒 Utilisateur normal, récupération de ses rendez-vous et rendez-vous système');
    const { data, error } = await supabase
      .from('appointments')
      .select('*')
      .or(`user_id.eq.${currentUser.id},user_id.eq.00000000-0000-0000-0000-000000000000`)
      .order('start_date', { ascending: true });
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(appointment => ({
      id: appointment.id,
      userId: appointment.user_id,
      clientId: appointment.client_id,
      repairId: appointment.repair_id,
      title: appointment.title,
      description: appointment.description,
      startDate: new Date(appointment.start_date),
      endDate: new Date(appointment.end_date),
      assignedUserId: appointment.assigned_user_id,
      status: appointment.status,
      createdAt: new Date(appointment.created_at),
      updatedAt: new Date(appointment.updated_at)
    })) || [];
    
    return handleSupabaseSuccess(convertedData);
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('appointments')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = {
      id: data.id,
      userId: data.user_id,
      clientId: data.client_id,
      repairId: data.repair_id,
      title: data.title,
      description: data.description,
      startDate: new Date(data.start_date),
      endDate: new Date(data.end_date),
      assignedUserId: data.assigned_user_id,
      status: data.status,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at)
    };
    
    return handleSupabaseSuccess(convertedData);
  },

  async create(appointment: Omit<Appointment, 'id' | 'createdAt' | 'updatedAt'>) {
    // Récupérer l'utilisateur connecté
    const currentUser = await getCurrentUser();
    const userId = currentUser?.id || '00000000-0000-0000-0000-000000000000';
    
    // Convertir les noms de propriétés camelCase vers snake_case
    // Gérer les valeurs vides en les convertissant en null
    const appointmentData = {
      user_id: userId, // Ajouter l'utilisateur connecté
      client_id: appointment.clientId && appointment.clientId.trim() !== '' ? appointment.clientId : null,
      repair_id: appointment.repairId && appointment.repairId.trim() !== '' ? appointment.repairId : null,
      title: appointment.title,
      description: appointment.description,
      start_date: appointment.startDate.toISOString(),
      end_date: appointment.endDate.toISOString(),
      assigned_user_id: appointment.assignedUserId && appointment.assignedUserId.trim() !== '' ? appointment.assignedUserId : null,
      status: appointment.status,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('appointments')
      .insert([appointmentData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Appointment>) {
    // Convertir les noms de propriétés camelCase vers snake_case
    const updateData: any = {
      updated_at: new Date().toISOString()
    };
    
    if (updates.clientId !== undefined) {
      updateData.client_id = updates.clientId && updates.clientId.trim() !== '' ? updates.clientId : null;
    }
    if (updates.repairId !== undefined) {
      updateData.repair_id = updates.repairId && updates.repairId.trim() !== '' ? updates.repairId : null;
    }
    if (updates.title !== undefined) updateData.title = updates.title;
    if (updates.description !== undefined) updateData.description = updates.description;
    if (updates.startDate !== undefined) updateData.start_date = updates.startDate.toISOString();
    if (updates.endDate !== undefined) updateData.end_date = updates.endDate.toISOString();
    if (updates.assignedUserId !== undefined) {
      updateData.assigned_user_id = updates.assignedUserId && updates.assignedUserId.trim() !== '' ? updates.assignedUserId : null;
    }
    if (updates.status !== undefined) updateData.status = updates.status;

    const { data, error } = await supabase
      .from('appointments')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('appointments')
      .delete()
      .eq('id', id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les statistiques du tableau de bord
export const dashboardService = {
  async getStats(): Promise<{ success: boolean; data?: DashboardStats; error?: string }> {
    try {
      // Récupérer les statistiques des réparations
      const { data: repairs, error: repairsError } = await supabase
        .from('repairs')
        .select('status, created_at');

      if (repairsError) return handleSupabaseError(repairsError);

      // Récupérer les statistiques des ventes
      const { data: sales, error: salesError } = await supabase
        .from('sales')
        .select('amount, created_at');

      if (salesError) return handleSupabaseError(salesError);

      // Récupérer les pièces en rupture de stock
      const { data: lowStockParts, error: lowStockError } = await supabase
        .from('parts')
        .select('*')
        .lte('quantity', 5);

      if (lowStockError) return handleSupabaseError(lowStockError);

      // Calculer les statistiques
      const totalRepairs = repairs?.length || 0;
      const completedRepairs = repairs?.filter(r => r.status === 'completed').length || 0;
      const totalSales = sales?.reduce((sum, sale) => sum + (sale.amount || 0), 0) || 0;
      const lowStockCount = lowStockParts?.length || 0;

      const stats: DashboardStats = {
        totalRepairs,
        activeRepairs: totalRepairs - completedRepairs,
        completedRepairs,
        overdueRepairs: 0,
        todayAppointments: 0,
        monthlyRevenue: 0,
        lowStockItems: lowStockCount,
        pendingMessages: 0
      };

      return handleSupabaseSuccess(stats);
    } catch (error) {
      return handleSupabaseError(error);
    }
  }
};

// Service pour les paramètres utilisateur
export const userSettingsService = {
  async getUserProfile(userId: string) {
    try {
      console.log('🔍 getUserProfile appelé pour userId:', userId);
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('user_id', userId)
        .single();
      
      console.log('📊 getUserProfile résultat:', { data, error });
      
      if (error) {
        console.log('⚠️ Erreur getUserProfile, création automatique...');
        // Créer automatiquement le profil s'il n'existe pas
        const { data: newData, error: createError } = await supabase
          .from('user_profiles')
          .upsert({
            user_id: userId,
            first_name: 'Utilisateur',
            last_name: '',
            email: 'user@example.com',
            phone: '',
          })
          .select()
          .single();
        
        console.log('📊 Création automatique profil:', { data: newData, error: createError });
        
        if (createError) {
          return handleSupabaseError(createError);
        }
        
        return handleSupabaseSuccess(newData);
      }
      
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('💥 Exception getUserProfile:', err);
      throw err;
    }
  },

  async updateUserProfile(userId: string, profile: any) {
    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .upsert({
          user_id: userId,
          ...profile,
          updated_at: new Date().toISOString(),
        })
        .select()
        .single();
      
      if (error) {
        return handleSupabaseError(error);
      }
      
      return handleSupabaseSuccess(data);
    } catch (err) {
      throw err;
    }
  },

  async getUserPreferences(userId: string) {
    try {
      console.log('🔍 getUserPreferences appelé pour userId:', userId);
      const { data, error } = await supabase
        .from('user_preferences')
        .select('*')
        .eq('user_id', userId)
        .single();
      
      console.log('📊 getUserPreferences résultat:', { data, error });
      
      if (error) {
        console.log('⚠️ Erreur getUserPreferences, création automatique...');
        // Créer automatiquement les préférences s'il n'existent pas
        const { data: newData, error: createError } = await supabase
          .from('user_preferences')
          .upsert({
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
          })
          .select()
          .single();
        
        console.log('📊 Création automatique préférences:', { data: newData, error: createError });
        
        if (createError) {
          return handleSupabaseError(createError);
        }
        
        return handleSupabaseSuccess(newData);
      }
      
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('💥 Exception getUserPreferences:', err);
      throw err;
    }
  },

  async updateUserPreferences(userId: string, preferences: any) {
    try {
      const { data, error } = await supabase
        .from('user_preferences')
        .upsert({
          user_id: userId,
          ...preferences,
          updated_at: new Date().toISOString(),
        })
        .select()
        .single();
      
      if (error) {
        return handleSupabaseError(error);
      }
      
      return handleSupabaseSuccess(data);
    } catch (err) {
      throw err;
    }
  },

  async changePassword(userId: string, oldPassword: string, newPassword: string) {
    try {
      const { data, error } = await supabase.auth.updateUser({
        password: newPassword
      });
      
      if (error) {
        return handleSupabaseError(error);
      }
      
      return handleSupabaseSuccess(data);
    } catch (err) {
      throw err;
    }
  },
};

// Service pour les modèles d'appareils
export const deviceModelService = {
  async getAll() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        console.log('⚠️ Aucun utilisateur connecté, retourner une liste vide');
        return handleSupabaseSuccess([]);
      }
      
      console.log('🔒 Récupération des modèles d\'appareils pour l\'utilisateur:', user.id);
      
      const { data, error } = await supabase
        .from('device_models')
        .select('*')
        .order('brand', { ascending: true })
        .order('model', { ascending: true });
      
      if (error) return handleSupabaseError(error);
      
      // Convertir les données de snake_case vers camelCase
      const convertedData = data?.map(model => ({
        id: model.id,
        brand: model.brand,
        model: model.model,
        type: model.type,
        year: model.year,
        specifications: model.specifications || {},
        commonIssues: model.common_issues || [],
        repairDifficulty: model.repair_difficulty,
        partsAvailability: model.parts_availability,
        isActive: model.is_active,
        createdAt: new Date(model.created_at),
        updatedAt: new Date(model.updated_at)
      })) || [];
      
      console.log('✅ Modèles récupérés:', convertedData.length);
      return handleSupabaseSuccess(convertedData);
    } catch (err) {
      console.error('💥 Exception dans deviceModelService.getAll:', err);
      return handleSupabaseSuccess([]);
    }
  },

  async getById(id: string) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { data, error } = await supabase
        .from('device_models')
        .select('*')
        .eq('id', id)
        .single();
      
      if (error) return handleSupabaseError(error);
      
      // Convertir les données
      const convertedData = {
        id: data.id,
        brand: data.brand,
        model: data.model,
        type: data.type,
        year: data.year,
        specifications: data.specifications || {},
        commonIssues: data.common_issues || [],
        repairDifficulty: data.repair_difficulty,
        partsAvailability: data.parts_availability,
        isActive: data.is_active,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at)
      };
      
      return handleSupabaseSuccess(convertedData);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async create(model: any) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      // Convertir les noms de propriétés camelCase vers snake_case
      // Le trigger s'occupe automatiquement de workshop_id, created_by, et timestamps
      const modelData = {
        brand: model.brand,
        model: model.model,
        type: model.type,
        year: model.year,
        specifications: model.specifications || {},
        common_issues: model.commonIssues || [],
        repair_difficulty: model.repairDifficulty,
        parts_availability: model.partsAvailability,
        is_active: model.isActive !== undefined ? model.isActive : true
      };

      const { data, error } = await supabase
        .from('device_models')
        .insert([modelData])
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);
      
      // Convertir la réponse
      const convertedData = {
        id: data.id,
        brand: data.brand,
        model: data.model,
        type: data.type,
        year: data.year,
        specifications: data.specifications || {},
        commonIssues: data.common_issues || [],
        repairDifficulty: data.repair_difficulty,
        partsAvailability: data.parts_availability,
        isActive: data.is_active,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at)
      };
      
      return handleSupabaseSuccess(convertedData);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async update(id: string, updates: any) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      // Convertir les mises à jour
      const updateData: any = {
        updated_at: new Date().toISOString()
      };

      if (updates.brand !== undefined) updateData.brand = updates.brand;
      if (updates.model !== undefined) updateData.model = updates.model;
      if (updates.type !== undefined) updateData.type = updates.type;
      if (updates.year !== undefined) updateData.year = updates.year;
      if (updates.specifications !== undefined) updateData.specifications = updates.specifications;
      if (updates.commonIssues !== undefined) updateData.common_issues = updates.commonIssues;
      if (updates.repairDifficulty !== undefined) updateData.repair_difficulty = updates.repairDifficulty;
      if (updates.partsAvailability !== undefined) updateData.parts_availability = updates.partsAvailability;
      if (updates.isActive !== undefined) updateData.is_active = updates.isActive;

      const { data, error } = await supabase
        .from('device_models')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);
      
      // Convertir la réponse
      const convertedData = {
        id: data.id,
        brand: data.brand,
        model: data.model,
        type: data.type,
        year: data.year,
        specifications: data.specifications || {},
        commonIssues: data.common_issues || [],
        repairDifficulty: data.repair_difficulty,
        partsAvailability: data.parts_availability,
        isActive: data.is_active,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at)
      };
      
      return handleSupabaseSuccess(convertedData);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async delete(id: string) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { error } = await supabase
        .from('device_models')
        .delete()
        .eq('id', id);
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess({ success: true });
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },
};

export default {
  userService,
  systemSettingsService,
  userSettingsService,
  deviceModelService,
};
