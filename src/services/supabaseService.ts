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
      const { data, error } = await supabase
        .from('system_settings')
        .select('*')
        .order('category', { ascending: true })
        .order('key', { ascending: true });
      
      console.log('📊 Résultat Supabase:', { data, error });
      
      if (error) {
        console.error('❌ Erreur Supabase:', error);
        return handleSupabaseError(error);
      }
      
      console.log('✅ Données récupérées:', data);
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('💥 Exception dans getAll:', err);
      throw err;
    }
  },

  async getByCategory(category: string) {
    const { data, error } = await supabase
      .from('system_settings')
      .select('*')
      .eq('category', category)
      .order('key', { ascending: true });
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async getByKey(key: string) {
    const { data, error } = await supabase
      .from('system_settings')
      .select('*')
      .eq('key', key)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(key: string, value: string) {
    const { data, error } = await supabase
      .from('system_settings')
      .update({ value, updated_at: new Date().toISOString() })
      .eq('key', key)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async updateMultiple(settings: Array<{ key: string; value: string }>) {
    const updates = settings.map(setting => ({
      key: setting.key,
      value: setting.value,
      updated_at: new Date().toISOString()
    }));

    const { data, error } = await supabase
      .from('system_settings')
      .upsert(updates, { onConflict: 'key' })
      .select();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(setting: { key: string; value: string; description?: string; category?: string }) {
    const { data, error } = await supabase
      .from('system_settings')
      .insert([{
        key: setting.key,
        value: setting.value,
        description: setting.description,
        category: setting.category || 'general'
      }])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(key: string) {
    const { error } = await supabase
      .from('system_settings')
      .delete()
      .eq('key', key);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les utilisateurs
export const userService = {
  async getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(user);
  },

  async getAllUsers() {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(user => ({
      id: user.id,
      firstName: user.first_name,
      lastName: user.last_name,
      email: user.email,
      role: user.role,
      avatar: user.avatar,
      createdAt: user.created_at,
      updatedAt: user.updated_at
    })) || [];
    
    return handleSupabaseSuccess(convertedData);
  },

  async createUser(userData: Omit<User, 'id' | 'createdAt' | 'updatedAt'>) {
    // Créer l'utilisateur dans Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: userData.email,
      password: 'tempPassword123!',
      email_confirm: true,
      user_metadata: {
        firstName: userData.firstName,
        lastName: userData.lastName,
        role: userData.role
      }
    });

    if (authError) return handleSupabaseError(authError);

    // Créer l'enregistrement dans la table users
    const userRecord = {
      id: authData.user.id,
      first_name: userData.firstName,
      last_name: userData.lastName,
      email: userData.email,
      role: userData.role,
      avatar: userData.avatar,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('users')
      .insert([userRecord])
      .select()
      .single();

    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async updateUser(id: string, updates: Partial<User>) {
    // Mettre à jour les métadonnées utilisateur dans Auth
    if (updates.firstName || updates.lastName || updates.role) {
      const { error: authError } = await supabase.auth.admin.updateUserById(id, {
        user_metadata: {
          firstName: updates.firstName,
          lastName: updates.lastName,
          role: updates.role
        }
      });

      if (authError) return handleSupabaseError(authError);
    }

    // Mettre à jour l'enregistrement dans la table users
    const updateData: any = {
      updated_at: new Date().toISOString()
    };

    if (updates.firstName) updateData.first_name = updates.firstName;
    if (updates.lastName) updateData.last_name = updates.lastName;
    if (updates.role) updateData.role = updates.role;
    if (updates.avatar) updateData.avatar = updates.avatar;

    const { data, error } = await supabase
      .from('users')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async deleteUser(id: string) {
    // Supprimer l'utilisateur de Supabase Auth
    const { error: authError } = await supabase.auth.admin.deleteUser(id);
    if (authError) return handleSupabaseError(authError);

    // Supprimer l'enregistrement de la table users
    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', id);

    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
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
        data: userData
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

// Service pour les clients
export const clientService = {
  async getAll() {
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
    
    return handleSupabaseSuccess(convertedData);
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(client: Omit<Client, 'id' | 'createdAt' | 'updatedAt'>) {
    // Convertir les noms de propriétés camelCase vers snake_case
    const clientData = {
      first_name: client.firstName,
      last_name: client.lastName,
      email: client.email,
      phone: client.phone,
      address: client.address,
      notes: client.notes,
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
    const { data, error } = await supabase
      .from('clients')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('clients')
      .delete()
      .eq('id', id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les appareils
export const deviceService = {
  async getAll() {
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
    
    return handleSupabaseSuccess(convertedData);
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('devices')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(device: Omit<Device, 'id' | 'createdAt' | 'updatedAt'>) {
    // Convertir les noms de propriétés camelCase vers snake_case
    const deviceData = {
      brand: device.brand,
      model: device.model,
      serial_number: device.serialNumber,
      type: device.type,
      specifications: device.specifications,
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
    const { data, error } = await supabase
      .from('devices')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('devices')
      .delete()
      .eq('id', id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les réparations
export const repairService = {
  async getAll() {
    const { data, error } = await supabase
      .from('repairs')
      .select('*')
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
    const { data, error } = await supabase
      .from('repairs')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(repair: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'>) {
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
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('repairs')
      .delete()
      .eq('id', id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  },

  async getByStatus(status: string) {
    const { data, error } = await supabase
      .from('repairs')
      .select('*')
      .eq('status', status)
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  }
};

// Service pour les pièces
export const partService = {
  async getAll() {
    const { data, error } = await supabase
      .from('parts')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('parts')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(part: Omit<Part, 'id' | 'createdAt' | 'updatedAt'>) {
    const { data, error } = await supabase
      .from('parts')
      .insert([part])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Part>) {
    const { data, error } = await supabase
      .from('parts')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('parts')
      .delete()
      .eq('id', id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  },

  async getLowStock() {
    const { data, error } = await supabase
      .from('parts')
      .select('*')
      .lte('quantity', 5)
      .order('quantity', { ascending: true });
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  }
};

// Service pour les produits
export const productService = {
  async getAll() {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async create(product: Omit<Product, 'id' | 'createdAt' | 'updatedAt'>) {
    const { data, error } = await supabase
      .from('products')
      .insert([product])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Product>) {
    const { data, error } = await supabase
      .from('products')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les ventes
export const saleService = {
  async getAll() {
    const { data, error } = await supabase
      .from('sales')
      .select('*')
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
    // Convertir les noms de propriétés camelCase vers snake_case
    const saleData = {
      client_id: sale.clientId,
      items: sale.items,
      subtotal: sale.subtotal,
      tax: sale.tax,
      total: sale.total,
      payment_method: sale.paymentMethod,
      status: sale.status,
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

// Service pour les rendez-vous
export const appointmentService = {
  async getAll() {
    const { data, error } = await supabase
      .from('appointments')
      .select('*')
      .order('start_date', { ascending: true });
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(appointment => ({
      id: appointment.id,
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
    // Convertir les noms de propriétés camelCase vers snake_case
    // Gérer les valeurs vides en les convertissant en null
    const appointmentData = {
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

export default {
  userService,
  systemSettingsService,
  userSettingsService,
};
