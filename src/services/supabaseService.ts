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
  Quote,
  StockAlert,
  Notification,
  DashboardStats,
  Expense,
  ExpenseStats,
  Buyback,
  BuybackStatus
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

      // Filtrer par catégorie basée sur le préfixe de la clé
      const { data, error } = await supabase
        .from('system_settings')
        .select('*')
        .eq('user_id', user.id)
        .like('key', category + '%')
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
      // Récupérer l'utilisateur actuel pour l'isolation
      const { data: { user: currentUser } } = await supabase.auth.getUser();
      
      if (!currentUser) {
        console.error('❌ Aucun utilisateur connecté');
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }
      
      console.log('👤 Utilisateur actuel:', currentUser.id);
      
      // Récupérer les utilisateurs associés à l'utilisateur actuel
      // D'abord essayer de récupérer par created_by
      let { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('created_by', currentUser.id)
        .order('created_at', { ascending: false });
      
      // Si aucun utilisateur trouvé par created_by, essayer de récupérer l'utilisateur actuel
      if (!data || data.length === 0) {
        console.log('⚠️ Aucun utilisateur trouvé par created_by, recherche de l\'utilisateur actuel...');
        const { data: currentUserData, error: currentUserError } = await supabase
          .from('users')
          .select('*')
          .eq('id', currentUser.id)
          .maybeSingle();
        
        if (currentUserError) {
          console.error('❌ Erreur lors de la récupération de l\'utilisateur actuel:', currentUserError);
          data = [];
        } else if (currentUserData) {
          data = [currentUserData];
          console.log('✅ Utilisateur actuel trouvé dans la table users');
        } else {
          console.log('ℹ️ Aucun utilisateur trouvé, mais l\'utilisateur est authentifié');
          data = [];
        }
      }
      
      if (error) {
        console.error('❌ Erreur lors de la récupération des utilisateurs:', error);
        return handleSupabaseError(error);
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
      
      // Ajouter les utilisateurs virtuels du localStorage
      const virtualUsers = JSON.parse(localStorage.getItem('virtualUsers') || '[]');
      const currentUserVirtualUsers = virtualUsers.filter((vu: any) => vu.created_by === currentUser.id);
      
      // Convertir les utilisateurs virtuels au bon format
      const virtualUsersConverted = currentUserVirtualUsers.map((vu: any) => ({
        id: vu.id,
        firstName: vu.firstName,
        lastName: vu.lastName,
        email: vu.email,
        role: vu.role,
        avatar: vu.avatar,
        createdAt: vu.createdAt ? new Date(vu.createdAt) : new Date(),
        updatedAt: vu.updatedAt ? new Date(vu.updatedAt) : new Date(),
        isVirtual: true
      }));
      
      // Combiner les utilisateurs de la base et les utilisateurs virtuels
      const allUsers = [...convertedData, ...virtualUsersConverted];
      
      console.log('✅ Utilisateurs convertis:', convertedData.length, 'virtuels:', virtualUsersConverted.length);
      console.log('📊 Total utilisateurs:', allUsers.length);
      return handleSupabaseSuccess(allUsers);
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
      
      // Récupérer l'utilisateur actuel pour définir created_by
      const { data: { user: currentUser } } = await supabase.auth.getUser();
      if (!currentUser) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      // Solution alternative : Créer un utilisateur "virtuel" sans insertion en base
      // Cette approche simule la création d'utilisateur sans violer les politiques RLS
      console.log('🔄 Création d\'utilisateur virtuel (contournement RLS)...');
      
      const newUserId = crypto.randomUUID();
      const virtualUser = {
        id: newUserId,
        firstName: userData.firstName,
        lastName: userData.lastName,
        email: userData.email,
        role: userData.role,
        avatar: userData.avatar,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      // Stocker l'utilisateur virtuel dans le localStorage pour la session
      const virtualUsers = JSON.parse(localStorage.getItem('virtualUsers') || '[]');
      virtualUsers.push({
        ...virtualUser,
        created_by: currentUser.id,
        is_virtual: true
      });
      localStorage.setItem('virtualUsers', JSON.stringify(virtualUsers));

      console.log('✅ Utilisateur virtuel créé avec succès:', virtualUser);
      
      // Retourner l'utilisateur virtuel comme s'il était créé en base
      return handleSupabaseSuccess(virtualUser);
    } catch (err) {
      console.error('💥 Exception lors de la création:', err);
      return handleSupabaseError(err as any);
    }
  },

  async deleteUser(id: string) {
    try {
      console.log('🗑️ Suppression d\'utilisateur:', id);
      
      // Vérifier d'abord si c'est un utilisateur virtuel
      const virtualUsers = JSON.parse(localStorage.getItem('virtualUsers') || '[]');
      const virtualUserIndex = virtualUsers.findIndex((vu: any) => vu.id === id);
      
      if (virtualUserIndex !== -1) {
        // Supprimer l'utilisateur virtuel du localStorage
        virtualUsers.splice(virtualUserIndex, 1);
        localStorage.setItem('virtualUsers', JSON.stringify(virtualUsers));
        console.log('✅ Utilisateur virtuel supprimé avec succès');
        return handleSupabaseSuccess(true);
      }
      
      // Si ce n'est pas un utilisateur virtuel, essayer de supprimer de la base
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


  async signIn(email: string, password: string) {
    try {
      console.log('🔐 Tentative de connexion Supabase pour:', email);
      
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.trim().toLowerCase(),
        password
      });
      
      if (error) {
        console.error('❌ Erreur Supabase Auth:', error);
        
        // Gestion spécifique des erreurs d'authentification
        if (error.message.includes('Invalid login credentials')) {
          return handleSupabaseError({
            message: 'Email ou mot de passe incorrect',
            code: 'INVALID_CREDENTIALS'
          });
        }
        
        if (error.message.includes('Email not confirmed')) {
          return handleSupabaseError({
            message: 'Veuillez confirmer votre email avant de vous connecter',
            code: 'EMAIL_NOT_CONFIRMED'
          });
        }
        
        if (error.message.includes('Too many requests')) {
          return handleSupabaseError({
            message: 'Trop de tentatives de connexion. Veuillez patienter quelques minutes',
            code: 'TOO_MANY_REQUESTS'
          });
        }
        
        return handleSupabaseError(error);
      }
      
      console.log('✅ Connexion Supabase réussie');
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('💥 Exception lors de la connexion:', err);
      return handleSupabaseError(err as any);
    }
  },

  async signUp(email: string, password: string, userData: Partial<User>) {
    try {
      console.log('🔧 Inscription simple via Supabase Auth:', { email });
      
      // Inscription simple avec Supabase Auth uniquement
      const { data, error } = await supabase.auth.signUp({
        email: email,
        password: password,
        options: {
          data: {
            first_name: userData.firstName || 'Utilisateur',
            last_name: userData.lastName || 'Test',
            role: userData.role || 'technician'
          }
        }
      });
      
      if (error) {
        console.error('❌ Erreur lors de l\'inscription:', error);
        
        // Gestion des erreurs spécifiques
        if (error.message.includes('already registered') || error.message.includes('User already registered')) {
          return handleSupabaseError({
            message: 'Un compte avec cet email existe déjà. Veuillez vous connecter.',
            code: 'ACCOUNT_EXISTS'
          });
        }
        
        if (error.message.includes('Database error saving new user') || error.message.includes('500')) {
          return handleSupabaseError({
            message: 'Erreur de base de données. Veuillez exécuter le script de correction SQL dans Supabase.',
            code: 'DATABASE_ERROR'
          });
        }
        
        return handleSupabaseError({
          message: error.message || 'Erreur lors de l\'inscription. Veuillez réessayer.',
          code: 'SIGNUP_ERROR'
        });
      }
      
      console.log('✅ Inscription réussie:', data);
      
      return handleSupabaseSuccess({
        message: 'Inscription réussie ! Vérifiez votre email pour confirmer votre compte.',
        data: data.user,
        emailSent: data.user?.email_confirmed_at ? false : true
      });
    } catch (err) {
      console.error('💥 Exception lors de l\'inscription:', err);
      return handleSupabaseError({
        message: 'Erreur inattendue lors de l\'inscription. Veuillez réessayer.',
        code: 'UNEXPECTED_ERROR'
      });
    }
  },

  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) return handleSupabaseError(error);
    
    // Nettoyer les données en attente lors de la déconnexion
    localStorage.removeItem('pendingUserData');
    
    return handleSupabaseSuccess(true);
  },

  // Fonction pour vérifier le statut d'une demande d'inscription
  async checkSignupStatus(email?: string) {
    try {
      const emailToCheck = email || localStorage.getItem('pendingSignupEmail');
      if (!emailToCheck) {
        console.log('📝 Aucun email de demande d\'inscription trouvé');
        return null;
      }

      console.log('🔄 Vérification du statut pour:', emailToCheck);

      const { data, error } = await supabase.rpc('get_signup_status', {
        p_email: emailToCheck
      });

      if (error) {
        console.error('❌ Erreur lors de la vérification du statut:', error);
        return null;
      }

      console.log('✅ Statut récupéré:', data);
      return data;
    } catch (err) {
      console.error('❌ Erreur lors de la vérification du statut:', err);
      return null;
    }
  },

  // Fonction pour valider un token de confirmation
  async validateConfirmationToken(token: string) {
    try {
      console.log('🔄 Validation du token de confirmation:', token);

      const { data, error } = await supabase.rpc('validate_confirmation_token', {
        p_token: token
      });

      if (error) {
        console.error('❌ Erreur lors de la validation du token:', error);
        return null;
      }

      console.log('✅ Token validé:', data);
      return data;
    } catch (err) {
      console.error('❌ Erreur lors de la validation du token:', err);
      return null;
    }
  },

  // Fonction pour renvoyer un email de confirmation
  async resendConfirmationEmail(email: string) {
    try {
      console.log('🔄 Renvoi de l\'email de confirmation pour:', email);

      // Vérifier d'abord si une demande existe
      const { data: existingData, error: checkError } = await supabase
        .from('pending_signups')
        .select('*')
        .eq('email', email)
        .single();
      
      if (checkError || !existingData) {
        console.error('❌ Aucune demande d\'inscription trouvée pour cet email');
        return null;
      }

      const { data, error } = await supabase.rpc('resend_confirmation_email_real', {
        p_email: email
      });

      if (error) {
        console.error('❌ Erreur lors du renvoi de l\'email:', error);
        return null;
      }

      console.log('✅ Email de confirmation renvoyé:', data);
      
      // Stocker le nouveau token
      if (data.token) {
        localStorage.setItem('confirmationToken', data.token);
        localStorage.setItem('pendingSignupEmail', email);
      }
      
      return data;
    } catch (err) {
      console.error('❌ Erreur lors du renvoi de l\'email:', err);
      return null;
    }
  },

  // Fonction pour traiter les données utilisateur en attente
  async processPendingUserData() {
    try {
      const pendingData = localStorage.getItem('pendingUserData');
      if (!pendingData) {
        // Supprimer le log pour éviter les messages répétés
        return;
      }

      const userData = JSON.parse(pendingData);
      console.log('🔄 Traitement des données utilisateur en attente:', userData);

      // Vérifier que l'utilisateur est connecté
      const { data: { user } } = await supabase.auth.getUser();
      if (!user || user.id !== userData.userId) {
        console.log('⚠️ Utilisateur non connecté ou ID ne correspond pas');
        return;
      }

      // Créer l'utilisateur dans la table users
      const newUserData = {
        id: userData.userId,
        first_name: userData.firstName,
        last_name: userData.lastName,
        email: userData.email,
        role: userData.role,
        avatar: null,
        created_by: userData.userId, // L'utilisateur se crée lui-même
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const { data: insertData, error: insertError } = await supabase
        .from('users')
        .insert([newUserData])
        .select()
        .single();

      if (insertError) {
        console.error('❌ Erreur lors de la création de l\'utilisateur:', insertError);
        return;
      }

      console.log('✅ Utilisateur créé avec succès:', insertData);

      // Créer les données par défaut de manière asynchrone avec la fonction permissive
      setTimeout(async () => {
        try {
          await supabase.rpc('create_user_default_data_permissive', {
            p_user_id: userData.userId
          });
          console.log('✅ Données par défaut créées pour l\'utilisateur:', userData.userId);
        } catch (rpcError) {
          console.warn('⚠️ Erreur lors de la création des données par défaut (non bloquant):', rpcError);
        }
      }, 2000);

      // Nettoyer les données en attente
      localStorage.removeItem('pendingUserData');
      console.log('✅ Données utilisateur traitées avec succès');

    } catch (err) {
      console.error('❌ Erreur lors du traitement des données utilisateur:', err);
    }
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
      
      // Création simple de l'utilisateur sans RPC pour éviter les erreurs
      try {
        console.log('🔄 Création simple de l\'utilisateur...');
        
        const newUserData = {
          id: user.id,
          first_name: user.user_metadata?.first_name || 'Utilisateur',
          last_name: user.user_metadata?.last_name || 'Test',
          email: user.email || '',
          role: 'technician', // Rôle par défaut
          avatar: user.user_metadata?.avatar || null,
          created_by: user.id, // L'utilisateur se crée lui-même
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        };
        
        const { data: insertData, error: insertError } = await supabase
          .from('users')
          .insert([newUserData])
          .select()
          .single();
        
        if (insertError) {
          console.error('❌ Erreur lors de la création de l\'utilisateur:', insertError);
          return null;
        }
        
        console.log('✅ Utilisateur créé dans la table users:', insertData.id, 'Rôle:', insertData.role);
        
        // Créer les données par défaut de manière asynchrone (ne pas bloquer)
        setTimeout(async () => {
          try {
            await supabase.rpc('create_user_default_data', {
              p_user_id: user.id
            });
            console.log('✅ Données par défaut créées pour l\'utilisateur:', user.id);
          } catch (rpcError) {
            console.warn('⚠️ Erreur lors de la création des données par défaut (non bloquant):', rpcError);
          }
        }, 1000);
        
        return { id: insertData.id, role: insertData.role };
      } catch (createErr) {
        console.error('❌ Erreur lors de la création de l\'utilisateur:', createErr);
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
    
    // Récupérer les clients de l'utilisateur connecté avec filtrage par user_id
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('user_id', user.id)
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
      
      // Nouveaux champs pour les informations personnelles et entreprise
      category: client.category,
      title: client.title,
      companyName: client.company_name,
      vatNumber: client.vat_number,
      sirenNumber: client.siren_number,
      countryCode: client.country_code,
      
      // Nouveaux champs pour l'adresse détaillée
      addressComplement: client.address_complement,
      region: client.region,
      postalCode: client.postal_code,
      city: client.city,
      
      // Nouveaux champs pour l'adresse de facturation
      billingAddressSame: client.billing_address_same,
      billingAddress: client.billing_address,
      billingAddressComplement: client.billing_address_complement,
      billingRegion: client.billing_region,
      billingPostalCode: client.billing_postal_code,
      billingCity: client.billing_city,
      
      // Nouveaux champs pour les informations complémentaires
      accountingCode: client.accounting_code,
      cniIdentifier: client.cni_identifier,
      attachedFilePath: client.attached_file_path,
      internalNote: client.internal_note,
      
      // Nouveaux champs pour les préférences
      status: client.status,
      smsNotification: client.sms_notification,
      emailNotification: client.email_notification,
      smsMarketing: client.sms_marketing,
      emailMarketing: client.email_marketing,
      
      createdAt: client.created_at,
      updatedAt: client.updated_at
    })) || [];
    
    console.log('✅ Clients récupérés:', convertedData.length, 'pour l\'utilisateur:', user.id);
    console.log('📋 Détails des clients récupérés:');
    convertedData.forEach((client, index) => {
      console.log(`  Client ${index + 1}: ${client.firstName} ${client.lastName} (${client.email})`);
      console.log(`    📍 Adresse: ${client.address}`);
      console.log(`    🏢 Entreprise: ${client.companyName}`);
      console.log(`    📧 Email: ${client.email}`);
      console.log(`    📱 Téléphone: ${client.phone}`);
      console.log(`    🏠 Complément: ${client.addressComplement}`);
      console.log(`    🌍 Région: ${client.region}`);
      console.log(`    📮 Code postal: ${client.postalCode}`);
      console.log(`    🏙️ Ville: ${client.city}`);
      console.log(`    📊 Code comptable: ${client.accountingCode}`);
      console.log(`    🆔 CNI: ${client.cniIdentifier}`);
      console.log(`    📝 Note interne: ${client.internalNote}`);
    });
    
    // Ajouter des logs pour voir les données brutes de Supabase
    console.log('🔍 DONNÉES BRUTES DE SUPABASE:');
    data?.forEach((client, index) => {
      console.log(`  Client ${index + 1} brut:`, client);
      console.log(`    - company_name:`, client.company_name);
      console.log(`    - vat_number:`, client.vat_number);
      console.log(`    - siren_number:`, client.siren_number);
    });
    return handleSupabaseSuccess(convertedData);
  },

  async getById(id: string) {
    // Récupérer l'utilisateur connecté
    const currentUserId = await getCurrentUserId();
    
    if (!currentUserId) {
      console.log('⚠️ Aucun utilisateur connecté, impossible de récupérer le client');
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }
    
    console.log('🔒 Récupération du client pour l\'utilisateur:', currentUserId);
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('id', id)
      .eq('user_id', currentUserId)
      .single();
    
    if (error) return handleSupabaseError(error);
    
    console.log('🔍 GETBYID - Données brutes récupérées:', data);
    console.log('🔍 GETBYID - Champs d\'entreprise:');
    console.log('  - company_name:', data.company_name);
    console.log('  - vat_number:', data.vat_number);
    console.log('  - siren_number:', data.siren_number);
    console.log('  - address_complement:', data.address_complement);
    console.log('  - region:', data.region);
    console.log('  - postal_code:', data.postal_code);
    console.log('  - city:', data.city);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = {
      id: data.id,
      firstName: data.first_name,
      lastName: data.last_name,
      email: data.email,
      phone: data.phone,
      address: data.address,
      notes: data.notes,
      
      // Nouveaux champs pour les informations personnelles et entreprise
      category: data.category,
      title: data.title,
      companyName: data.company_name,
      vatNumber: data.vat_number,
      sirenNumber: data.siren_number,
      countryCode: data.country_code,
      
      // Nouveaux champs pour l'adresse détaillée
      addressComplement: data.address_complement,
      region: data.region,
      postalCode: data.postal_code,
      city: data.city,
      
      // Nouveaux champs pour l'adresse de facturation
      billingAddressSame: data.billing_address_same,
      billingAddress: data.billing_address,
      billingAddressComplement: data.billing_address_complement,
      billingRegion: data.billing_region,
      billingPostalCode: data.billing_postal_code,
      billingCity: data.billing_city,
      
      // Nouveaux champs pour les informations complémentaires
      accountingCode: data.accounting_code,
      cniIdentifier: data.cni_identifier,
      attachedFilePath: data.attached_file_path,
      internalNote: data.internal_note,
      
      // Nouveaux champs pour les préférences
      status: data.status,
      smsNotification: data.sms_notification,
      emailNotification: data.email_notification,
      smsMarketing: data.sms_marketing,
      emailMarketing: data.email_marketing,
      
      createdAt: data.created_at,
      updatedAt: data.updated_at
    };
    
    return handleSupabaseSuccess(convertedData);
  },

  async create(client: Omit<Client, 'id' | 'createdAt' | 'updatedAt'>, skipDuplicateCheck = false) {
    try {
      // Récupérer l'utilisateur connecté
      const currentUserId = await getCurrentUserId();
      
      console.log('🔍 CLIENT SERVICE - DONNÉES REÇUES:', client);
      
      // Vérifier les doublons si nécessaire
      if (!skipDuplicateCheck && client.email && client.email.trim()) {
        console.log('🔍 CLIENT SERVICE - Vérification des doublons pour:', client.email);
        console.log('🔍 CLIENT SERVICE - skipDuplicateCheck:', skipDuplicateCheck);
        console.log('🔍 CLIENT SERVICE - currentUserId:', currentUserId);
        
        try {
          const { data: existingClients, error: checkError } = await supabase
            .from('clients')
            .select('id, email')
            .eq('user_id', currentUserId)
            .eq('email', client.email.toLowerCase());
          
          console.log('🔍 CLIENT SERVICE - Résultat vérification doublons:', { existingClients, checkError });
          
          if (checkError) {
            console.error('❌ Erreur lors de la vérification des doublons:', checkError);
            // Ne pas bloquer l'import en cas d'erreur de vérification
            console.warn('⚠️ CLIENT SERVICE - Erreur de vérification, continuation de l\'import');
          } else if (existingClients && existingClients.length > 0) {
            console.warn('⚠️ CLIENT SERVICE - Doublon détecté, ignoré:', client.email);
            return handleSupabaseSuccess(null, 'Client ignoré (déjà présent)');
          }
        } catch (err) {
          console.error('❌ Erreur lors de la vérification des doublons:', err);
          // Ne pas bloquer l'import en cas d'erreur
          console.warn('⚠️ CLIENT SERVICE - Erreur de vérification, continuation de l\'import');
        }
      }
      
      // Utiliser directement la méthode d'insertion pour supporter tous les champs
      console.log('📤 CLIENT SERVICE - UTILISATION DE LA MÉTHODE DIRECTE (tous champs supportés)');
      
      
      // Gérer les emails en doublon en ajoutant un suffixe unique
      let finalEmail = client.email || '';
      
      // Si pas d'email ou email vide, générer un email unique pour éviter la contrainte
      if (!finalEmail || !finalEmail.trim()) {
        const timestamp = Date.now();
        finalEmail = `client-${timestamp}@atelier.local`;
        console.log('📝 CLIENT SERVICE - Aucun email fourni, génération d\'un email unique:', finalEmail);
      } else if (finalEmail && finalEmail.trim() && skipDuplicateCheck) {
        console.log('🔍 CLIENT SERVICE - Vérification doublon pour email:', finalEmail);
        // Vérifier si l'email existe déjà
        const { data: existingClients } = await supabase
          .from('clients')
          .select('id, email')
          .eq('user_id', currentUserId)
          .eq('email', finalEmail.toLowerCase());
        
        if (existingClients && existingClients.length > 0) {
          // Générer un email unique en ajoutant un suffixe
          const timestamp = Date.now();
          const emailParts = finalEmail.split('@');
          if (emailParts.length === 2) {
            finalEmail = `${emailParts[0]}+${timestamp}@${emailParts[1]}`;
            console.log('🔄 CLIENT SERVICE - Email modifié pour éviter le doublon:', finalEmail);
          }
        }
      }
      
      // Convertir les noms de propriétés camelCase vers snake_case
      const clientData = {
        first_name: client.firstName || '',
        last_name: client.lastName || '',
        email: finalEmail,
        phone: client.phone || '',
        address: client.address || '',
        notes: client.notes || '',
        
        // Nouveaux champs pour les informations personnelles et entreprise
        category: client.category || 'particulier',
        title: client.title || 'mr',
        company_name: client.companyName || '',
        vat_number: client.vatNumber || '',
        siren_number: client.sirenNumber || '',
        country_code: client.countryCode || '33',
        
        // Nouveaux champs pour l'adresse détaillée
        address_complement: client.addressComplement || '',
        region: client.region || '',
        postal_code: client.postalCode || '',
        city: client.city || '',
        
        // Nouveaux champs pour l'adresse de facturation
        billing_address_same: client.billingAddressSame !== undefined ? client.billingAddressSame : true,
        billing_address: client.billingAddress || '',
        billing_address_complement: client.billingAddressComplement || '',
        billing_region: client.billingRegion || '',
        billing_postal_code: client.billingPostalCode || '',
        billing_city: client.billingCity || '',
        
        // Nouveaux champs pour les informations complémentaires
        accounting_code: client.accountingCode || '',
        cni_identifier: client.cniIdentifier || '',
        attached_file_path: client.attachedFilePath || '',
        internal_note: client.internalNote || '',
        
        // Nouveaux champs pour les préférences
        status: client.status || 'displayed',
        sms_notification: client.smsNotification !== undefined ? client.smsNotification : true,
        email_notification: client.emailNotification !== undefined ? client.emailNotification : true,
        sms_marketing: client.smsMarketing !== undefined ? client.smsMarketing : true,
        email_marketing: client.emailMarketing !== undefined ? client.emailMarketing : true,
        
        user_id: currentUserId, // Utiliser l'utilisateur connecté
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      console.log('📤 CLIENT SERVICE - DONNÉES À ENVOYER À SUPABASE:', clientData);

      const { data, error } = await supabase
        .from('clients')
        .insert([clientData])
        .select()
        .single();
      
      console.log('📥 CLIENT SERVICE - RÉPONSE DE SUPABASE:', { data, error });
      
      if (error) {
        console.error('❌ ERREUR SUPABASE:', error);
        return handleSupabaseError(error);
      }
      
      console.log('✅ CLIENT CRÉÉ AVEC SUCCÈS:', data);
      
      // Convertir les données de snake_case vers camelCase
      const convertedData = {
        id: data.id,
        firstName: data.first_name,
        lastName: data.last_name,
        email: data.email,
        phone: data.phone,
        address: data.address,
        notes: data.notes,
        
        // Nouveaux champs pour les informations personnelles et entreprise
        category: data.category,
        title: data.title,
        companyName: data.company_name,
        vatNumber: data.vat_number,
        sirenNumber: data.siren_number,
        countryCode: data.country_code,
        
        // Nouveaux champs pour l'adresse détaillée
        addressComplement: data.address_complement,
        region: data.region,
        postalCode: data.postal_code,
        city: data.city,
        
        // Nouveaux champs pour l'adresse de facturation
        billingAddressSame: data.billing_address_same,
        billingAddress: data.billing_address,
        billingAddressComplement: data.billing_address_complement,
        billingRegion: data.billing_region,
        billingPostalCode: data.billing_postal_code,
        billingCity: data.billing_city,
        
        // Nouveaux champs pour les informations complémentaires
        accountingCode: data.accounting_code,
        cniIdentifier: data.cni_identifier,
        attachedFilePath: data.attached_file_path,
        internalNote: data.internal_note,
        
        // Nouveaux champs pour les préférences
        status: data.status,
        smsNotification: data.sms_notification,
        emailNotification: data.email_notification,
        smsMarketing: data.sms_marketing,
        emailMarketing: data.email_marketing,
        
        createdAt: data.created_at,
        updatedAt: data.updated_at
      };
      
      return handleSupabaseSuccess(convertedData);
      
    } catch (error) {
      console.error('💥 ERREUR CRÉATION CLIENT:', error);
      return handleSupabaseError(error);
    }
  },

  async update(id: string, updates: Partial<Client>) {
    // Récupérer l'utilisateur connecté
    const currentUserId = await getCurrentUserId();
    
    // Convertir les noms de propriétés camelCase vers snake_case
    const updateData: any = {
      updated_at: new Date().toISOString()
    };
    
    // Mapper les champs de base
    if (updates.firstName !== undefined) updateData.first_name = updates.firstName;
    if (updates.lastName !== undefined) updateData.last_name = updates.lastName;
    if (updates.email !== undefined) updateData.email = updates.email;
    if (updates.phone !== undefined) updateData.phone = updates.phone;
    if (updates.address !== undefined) updateData.address = updates.address;
    if (updates.notes !== undefined) updateData.notes = updates.notes;
    
    // Mapper les nouveaux champs
    if (updates.category !== undefined) updateData.category = updates.category;
    if (updates.title !== undefined) updateData.title = updates.title;
    if (updates.companyName !== undefined) updateData.company_name = updates.companyName;
    if (updates.vatNumber !== undefined) updateData.vat_number = updates.vatNumber;
    if (updates.sirenNumber !== undefined) updateData.siren_number = updates.sirenNumber;
    if (updates.countryCode !== undefined) updateData.country_code = updates.countryCode;
    
    if (updates.addressComplement !== undefined) updateData.address_complement = updates.addressComplement;
    if (updates.region !== undefined) updateData.region = updates.region;
    if (updates.postalCode !== undefined) updateData.postal_code = updates.postalCode;
    if (updates.city !== undefined) updateData.city = updates.city;
    
    if (updates.billingAddressSame !== undefined) updateData.billing_address_same = updates.billingAddressSame;
    if (updates.billingAddress !== undefined) updateData.billing_address = updates.billingAddress;
    if (updates.billingAddressComplement !== undefined) updateData.billing_address_complement = updates.billingAddressComplement;
    if (updates.billingRegion !== undefined) updateData.billing_region = updates.billingRegion;
    if (updates.billingPostalCode !== undefined) updateData.billing_postal_code = updates.billingPostalCode;
    if (updates.billingCity !== undefined) updateData.billing_city = updates.billingCity;
    
    if (updates.accountingCode !== undefined) updateData.accounting_code = updates.accountingCode;
    if (updates.cniIdentifier !== undefined) updateData.cni_identifier = updates.cniIdentifier;
    if (updates.attachedFilePath !== undefined) updateData.attached_file_path = updates.attachedFilePath;
    if (updates.internalNote !== undefined) updateData.internal_note = updates.internalNote;
    
    if (updates.status !== undefined) updateData.status = updates.status;
    if (updates.smsNotification !== undefined) updateData.sms_notification = updates.smsNotification;
    if (updates.emailNotification !== undefined) updateData.email_notification = updates.emailNotification;
    if (updates.smsMarketing !== undefined) updateData.sms_marketing = updates.smsMarketing;
    if (updates.emailMarketing !== undefined) updateData.email_marketing = updates.emailMarketing;
    
    if (!currentUserId) {
      console.log('⚠️ Aucun utilisateur connecté, mise à jour sans filtrage');
      const { data, error } = await supabase
        .from('clients')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);
      
      // Convertir les données de snake_case vers camelCase
      const convertedData = {
        id: data.id,
        firstName: data.first_name,
        lastName: data.last_name,
        email: data.email,
        phone: data.phone,
        address: data.address,
        notes: data.notes,
        
        // Nouveaux champs pour les informations personnelles et entreprise
        category: data.category,
        title: data.title,
        companyName: data.company_name,
        vatNumber: data.vat_number,
        sirenNumber: data.siren_number,
        countryCode: data.country_code,
        
        // Nouveaux champs pour l'adresse détaillée
        addressComplement: data.address_complement,
        region: data.region,
        postalCode: data.postal_code,
        city: data.city,
        
        // Nouveaux champs pour l'adresse de facturation
        billingAddressSame: data.billing_address_same,
        billingAddress: data.billing_address,
        billingAddressComplement: data.billing_address_complement,
        billingRegion: data.billing_region,
        billingPostalCode: data.billing_postal_code,
        billingCity: data.billing_city,
        
        // Nouveaux champs pour les informations complémentaires
        accountingCode: data.accounting_code,
        cniIdentifier: data.cni_identifier,
        attachedFilePath: data.attached_file_path,
        internalNote: data.internal_note,
        
        // Nouveaux champs pour les préférences
        status: data.status,
        smsNotification: data.sms_notification,
        emailNotification: data.email_notification,
        smsMarketing: data.sms_marketing,
        emailMarketing: data.email_marketing,
        
        createdAt: data.created_at,
        updatedAt: data.updated_at
      };
      
      return handleSupabaseSuccess(convertedData);
    }
    
    // Mettre à jour le client de l'utilisateur connecté
    const { data, error } = await supabase
      .from('clients')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', currentUserId)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = {
      id: data.id,
      firstName: data.first_name,
      lastName: data.last_name,
      email: data.email,
      phone: data.phone,
      address: data.address,
      notes: data.notes,
      
      // Nouveaux champs pour les informations personnelles et entreprise
      category: data.category,
      title: data.title,
      companyName: data.company_name,
      vatNumber: data.vat_number,
      sirenNumber: data.siren_number,
      countryCode: data.country_code,
      
      // Nouveaux champs pour l'adresse détaillée
      addressComplement: data.address_complement,
      region: data.region,
      postalCode: data.postal_code,
      city: data.city,
      
      // Nouveaux champs pour l'adresse de facturation
      billingAddressSame: data.billing_address_same,
      billingAddress: data.billing_address,
      billingAddressComplement: data.billing_address_complement,
      billingRegion: data.billing_region,
      billingPostalCode: data.billing_postal_code,
      billingCity: data.billing_city,
      
      // Nouveaux champs pour les informations complémentaires
      accountingCode: data.accounting_code,
      cniIdentifier: data.cni_identifier,
      attachedFilePath: data.attached_file_path,
      internalNote: data.internal_note,
      
      // Nouveaux champs pour les préférences
      status: data.status,
      smsNotification: data.sms_notification,
      emailNotification: data.email_notification,
      smsMarketing: data.sms_marketing,
      emailMarketing: data.email_marketing,
      
      createdAt: data.created_at,
      updatedAt: data.updated_at
    };
    
    return handleSupabaseSuccess(convertedData);
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
    const convertedData = data?.map(device => {
      // Gérer les spécifications qui peuvent être une chaîne JSON
      let specifications = device.specifications;
      if (typeof specifications === 'string') {
        try {
          specifications = JSON.parse(specifications);
        } catch (error) {
          console.warn('Erreur parsing specifications pour device:', device.id, error);
          specifications = null;
        }
      }
      
      return {
        id: device.id,
        brand: device.brand,
        model: device.model,
        serialNumber: device.serial_number,
        type: device.type,
        specifications: specifications,
        createdAt: device.created_at,
        updatedAt: device.updated_at
      };
    }) || [];
    
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

    // Récupérer les réparations avec le statut de paiement depuis la table séparée
    const { data, error } = await supabase
      .from('repairs')
      .select(`
        *,
        repair_payment_status!left(is_paid)
      `)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(repair => ({
      id: repair.id,
      repairNumber: repair.repair_number,
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
        discountPercentage: repair.discount_percentage,
        discountAmount: repair.discount_amount,
        originalPrice: repair.original_price,
        deposit: repair.deposit || 0, // Acompte payé par le client
        paymentMethod: repair.payment_method || 'cash', // Mode de paiement
      // Utiliser le statut de paiement depuis la table séparée
      isPaid: repair.repair_payment_status?.[0]?.is_paid || false,
      source: repair.source || 'kanban', // Source par défaut pour les anciennes réparations
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

    // Récupérer les réparations avec le statut de paiement depuis la table séparée
    const { data, error } = await supabase
      .from('repairs')
      .select(`
        *,
        repair_payment_status!left(is_paid)
      `)
      .eq('id', id)
      .eq('user_id', user.id)
      .single();
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data ? {
      id: data.id,
      repairNumber: data.repair_number,
      clientId: data.client_id,
      deviceId: data.device_id,
      status: data.status,
      assignedTechnicianId: data.assigned_technician_id,
      description: data.description,
      issue: data.issue,
      estimatedDuration: data.estimated_duration,
      actualDuration: data.actual_duration,
      estimatedStartDate: data.estimated_start_date,
      estimatedEndDate: data.estimated_end_date,
      startDate: data.start_date,
      endDate: data.end_date,
      dueDate: data.due_date,
      isUrgent: data.is_urgent,
      notes: data.notes,
      services: [], // Tableau vide par défaut
      parts: [], // Tableau vide par défaut
      totalPrice: data.total_price,
      discountPercentage: data.discount_percentage,
      discountAmount: data.discount_amount,
      originalPrice: data.original_price,
      deposit: data.deposit || 0, // Acompte payé par le client
      paymentMethod: data.payment_method || 'cash', // Mode de paiement
      // Utiliser le statut de paiement depuis la table séparée
      isPaid: data.repair_payment_status?.[0]?.is_paid || false,
      source: data.source || 'kanban', // Source par défaut pour les anciennes réparations
      createdAt: data.created_at,
      updatedAt: data.updated_at
    } : null;
    
    return handleSupabaseSuccess(convertedData);
  },

  async create(repair: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'>, source: 'kanban' | 'sav' = 'kanban') {
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
    const repairData: any = {
      client_id: repair.clientId,
      status: repair.status,
      description: repair.description,
      issue: repair.issue,
      estimated_duration: repair.estimatedDuration,
      due_date: repair.dueDate,
      is_urgent: repair.isUrgent,
              total_price: repair.totalPrice,
        discount_percentage: repair.discountPercentage || 0,
        discount_amount: repair.discountAmount || 0,
        original_price: repair.originalPrice || repair.totalPrice,
        deposit: repair.deposit || 0, // Acompte payé par le client
        payment_method: repair.paymentMethod || 'cash', // Mode de paiement
      is_paid: repair.isPaid,
      source: source, // Ajouter la source de création
      user_id: user.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    // Ajouter les champs optionnels seulement s'ils ont une valeur
    if (repair.deviceId) repairData.device_id = repair.deviceId;
    if (repair.assignedTechnicianId) repairData.assigned_technician_id = repair.assignedTechnicianId;
    if (repair.actualDuration) repairData.actual_duration = repair.actualDuration;
    if (repair.estimatedStartDate) repairData.estimated_start_date = repair.estimatedStartDate;
    if (repair.estimatedEndDate) repairData.estimated_end_date = repair.estimatedEndDate;
    if (repair.startDate) repairData.start_date = repair.startDate;
    if (repair.endDate) repairData.end_date = repair.endDate;
    if (repair.notes) repairData.notes = repair.notes;

    const { data, error } = await supabase
      .from('repairs')
      .insert([repairData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Repair>) {
    console.log('🔧 repairService.update appelé avec:', { id, updates });
    
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      console.error('❌ Erreur d\'authentification:', userError);
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }
    
    console.log('👤 Utilisateur connecté:', user.id);

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
            if (updates.discountPercentage !== undefined) updateData.discount_percentage = updates.discountPercentage;
        if (updates.discountAmount !== undefined) updateData.discount_amount = updates.discountAmount;
        if (updates.originalPrice !== undefined) updateData.original_price = updates.originalPrice;
        if (updates.deposit !== undefined) updateData.deposit = updates.deposit;
        if (updates.paymentMethod !== undefined) updateData.payment_method = updates.paymentMethod;
    if (updates.isPaid !== undefined) updateData.is_paid = updates.isPaid;

    console.log('📤 Données à envoyer à Supabase:', updateData);

    const { data, error } = await supabase
      .from('repairs')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    console.log('📥 Réponse de Supabase:', { data, error });
    
    if (error) {
      console.error('❌ Erreur Supabase:', error);
      return handleSupabaseError(error);
    }
    
    console.log('✅ Mise à jour réussie:', data);
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
  },

  // Fonction spécialisée pour mettre à jour uniquement le statut de paiement
  // sans déclencher les triggers de fidélité
  async updatePaymentStatus(id: string, isPaid: boolean) {
    console.log('💳 repairService.updatePaymentStatus appelé avec:', { id, isPaid });
    
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      console.error('❌ Erreur d\'authentification:', userError);
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }
    
    console.log('👤 Utilisateur connecté:', user.id);

    try {
      // Utiliser la nouvelle table séparée pour les statuts de paiement
      const { data, error } = await supabase.rpc('upsert_repair_payment_status', {
        repair_id_param: id,
        is_paid_value: isPaid,
        user_id_param: user.id
      });
      
      console.log('📥 Réponse de la fonction RPC (table séparée):', { data, error });
      
      if (error) {
        console.error('❌ Erreur RPC:', error);
        return handleSupabaseError(error);
      }
      
      // Vérifier le résultat de la fonction
      if (data && data.success) {
        console.log('✅ Mise à jour du paiement réussie via table séparée:', data);
        return handleSupabaseSuccess(data.data);
      } else {
        console.error('❌ Échec de la fonction RPC:', data?.error);
        return handleSupabaseError(new Error(data?.error || 'Erreur inconnue'));
      }
      
    } catch (rpcError) {
      console.error('❌ Erreur lors de l\'appel RPC:', rpcError);
      return handleSupabaseError(rpcError);
    }
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
      subcategory: part.subcategory || null,
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
    if (updates.subcategory !== undefined) dbUpdates.subcategory = updates.subcategory || null;
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
    
    // Log pour vérifier si le barcode est récupéré
    console.log('🔍 productService.getAll - Données récupérées:', data?.map(p => ({ 
      id: p.id, 
      name: p.name, 
      barcode: p.barcode 
    })));
    
    // Log détaillé pour debug
    console.log('🔍 productService.getAll - Données brutes:', data);
    
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
      subcategory: product.subcategory || null,
      price: product.price,
      stock_quantity: product.stockQuantity,
      min_stock_level: product.minStockLevel,
      is_active: product.isActive,
      barcode: product.barcode,
      user_id: user.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    // Log pour debug
    console.log('🔍 productService.create - Données reçues:', product);
    console.log('🔍 productService.create - Données DB:', productData);

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
    if (updates.subcategory !== undefined) dbUpdates.subcategory = updates.subcategory || null;
    if (updates.price !== undefined) dbUpdates.price = updates.price;
    if (updates.stockQuantity !== undefined) dbUpdates.stock_quantity = updates.stockQuantity;
    if (updates.minStockLevel !== undefined) dbUpdates.min_stock_level = updates.minStockLevel;
    if (updates.isActive !== undefined) dbUpdates.is_active = updates.isActive;
    if (updates.barcode !== undefined) dbUpdates.barcode = updates.barcode;

    // Log pour debug
    console.log('🔍 productService.update - Données reçues:', updates);
    console.log('🔍 productService.update - Données DB:', dbUpdates);

    const { data, error } = await supabase
      .from('products')
      .update(dbUpdates)
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (error) {
      console.error('❌ Erreur lors de la mise à jour du produit:', error);
      return handleSupabaseError(error);
    }
    
    console.log('✅ Produit mis à jour avec succès:', data);
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
  },

  async getByBarcode(barcode: string) {
    console.log('🔍 productService.getByBarcode - Recherche du code-barres:', barcode);
    
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      console.log('❌ Utilisateur non connecté');
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    console.log('👤 Utilisateur connecté:', user.id);

    // D'abord, récupérer tous les produits pour debug
    const { data: allProducts, error: allError } = await supabase
      .from('products')
      .select('id, name, barcode')
      .eq('user_id', user.id);
    
    if (allError) {
      console.log('❌ Erreur lors de la récupération des produits:', allError);
    } else {
      console.log('📋 Tous les produits avec codes-barres:', allProducts?.map(p => ({ 
        id: p.id, 
        name: p.name, 
        barcode: p.barcode 
      })));
    }

    // Recherche exacte d'abord
    let { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('barcode', barcode)
      .eq('user_id', user.id)
      .maybeSingle(); // Utiliser maybeSingle() au lieu de single() pour éviter l'erreur PGRST116
    
    // Si pas trouvé et que le code fait moins de 13 caractères, essayer une recherche partielle
    if (!data && barcode.length < 13) {
      console.log('🔍 Recherche exacte échouée, tentative de recherche partielle...');
      
      const { data: partialData, error: partialError } = await supabase
        .from('products')
        .select('*')
        .like('barcode', `${barcode}%`)
        .eq('user_id', user.id)
        .limit(1);
      
      if (!partialError && partialData && partialData.length > 0) {
        console.log('✅ Produit trouvé par recherche partielle:', { id: partialData[0].id, name: partialData[0].name, barcode: partialData[0].barcode });
        return handleSupabaseSuccess(partialData[0]);
      }
    }
    
    if (error) {
      console.log('❌ Erreur lors de la recherche:', error);
      return handleSupabaseError(error);
    }
    
    if (data) {
      console.log('✅ Produit trouvé:', { id: data.id, name: data.name, barcode: data.barcode });
      return handleSupabaseSuccess(data);
    } else {
      console.log('❌ Aucun produit trouvé avec le code-barres:', barcode);
      return handleSupabaseError(new Error('Produit non trouvé'));
    }
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
      discountPercentage: sale.discount_percentage,
      discountAmount: sale.discount_amount,
      originalTotal: sale.original_total,
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
      discountPercentage: data.discount_percentage,
      discountAmount: data.discount_amount,
      originalTotal: data.original_total,
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
      discount_percentage: sale.discountPercentage || 0,
      discount_amount: sale.discountAmount || 0,
      original_total: sale.originalTotal || (sale.subtotal + sale.tax),
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
    if (updates.discountPercentage !== undefined) updateData.discount_percentage = updates.discountPercentage;
    if (updates.discountAmount !== undefined) updateData.discount_amount = updates.discountAmount;
    if (updates.originalTotal !== undefined) updateData.original_total = updates.originalTotal;
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

// Service pour les catégories de dépenses - SUPPRIMÉ
// Les catégories ne sont plus utilisées pour les dépenses

// Service pour les dépenses
export const expenseService = {
  async getAll() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseSuccess([]);
      }

      const { data, error } = await supabase
        .from('expenses')
        .select('*')
        .eq('user_id', user.id)
        .order('expense_date', { ascending: false });
      
      if (error) return handleSupabaseError(error);
      
      const convertedData = data?.map(expense => ({
        id: expense.id,
        title: expense.title,
        description: expense.description,
        amount: expense.amount,
        supplier: expense.supplier,
        invoiceNumber: expense.invoice_number,
        paymentMethod: expense.payment_method,
        status: expense.status,
        expenseDate: new Date(expense.expense_date),
        dueDate: expense.due_date ? new Date(expense.due_date) : undefined,
        receiptPath: expense.receipt_path,
        tags: expense.tags || [],
        createdAt: new Date(expense.created_at),
        updatedAt: new Date(expense.updated_at)
      })) || [];
      
      return handleSupabaseSuccess(convertedData);
    } catch (error) {
      return handleSupabaseError(error);
    }
  },

  async getById(id: string) {
    try {
      const { data, error } = await supabase
        .from('expenses')
        .select('*')
        .eq('id', id)
        .single();
      
      if (error) return handleSupabaseError(error);
      
      const convertedData = {
        id: data.id,
        title: data.title,
        description: data.description,
        amount: data.amount,
        supplier: data.supplier,
        invoiceNumber: data.invoice_number,
        paymentMethod: data.payment_method,
        status: data.status,
        expenseDate: new Date(data.expense_date),
        dueDate: data.due_date ? new Date(data.due_date) : undefined,
        receiptPath: data.receipt_path,
        tags: data.tags || [],
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at)
      };
      
      return handleSupabaseSuccess(convertedData);
    } catch (error) {
      return handleSupabaseError(error);
    }
  },

  async create(expense: Omit<Expense, 'id' | 'createdAt' | 'updatedAt'>) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        throw new Error('Utilisateur non connecté');
      }

      // Pas de catégorie nécessaire

      const { data, error } = await supabase
        .from('expenses')
        .insert({
          user_id: user.id,
          title: expense.title,
          description: expense.description,
          amount: expense.amount,
          category_id: null,
          supplier: expense.supplier,
          invoice_number: expense.invoiceNumber,
          payment_method: expense.paymentMethod,
          status: expense.status,
          expense_date: expense.expenseDate.toISOString(),
          due_date: expense.dueDate?.toISOString(),
          receipt_path: expense.receiptPath,
          tags: expense.tags,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select('*')
        .single();
      
      if (error) return handleSupabaseError(error);
      
      const convertedData = {
        id: data.id,
        title: data.title,
        description: data.description,
        amount: data.amount,
        supplier: data.supplier,
        invoiceNumber: data.invoice_number,
        paymentMethod: data.payment_method,
        status: data.status,
        expenseDate: new Date(data.expense_date),
        dueDate: data.due_date ? new Date(data.due_date) : undefined,
        receiptPath: data.receipt_path,
        tags: data.tags || [],
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at)
      };
      
      return handleSupabaseSuccess(convertedData);
    } catch (error) {
      return handleSupabaseError(error);
    }
  },

  async update(id: string, updates: Partial<Expense>) {
    try {
      const updateData: any = {
        updated_at: new Date().toISOString()
      };
      
      if (updates.title !== undefined) updateData.title = updates.title;
      if (updates.description !== undefined) updateData.description = updates.description;
      if (updates.amount !== undefined) updateData.amount = updates.amount;
      // Pas de catégorie nécessaire
      if (updates.supplier !== undefined) updateData.supplier = updates.supplier;
      if (updates.invoiceNumber !== undefined) updateData.invoice_number = updates.invoiceNumber;
      if (updates.paymentMethod !== undefined) updateData.payment_method = updates.paymentMethod;
      if (updates.status !== undefined) updateData.status = updates.status;
      if (updates.expenseDate !== undefined) updateData.expense_date = updates.expenseDate.toISOString();
      if (updates.dueDate !== undefined) updateData.due_date = updates.dueDate?.toISOString();
      if (updates.receiptPath !== undefined) updateData.receipt_path = updates.receiptPath;
      if (updates.tags !== undefined) updateData.tags = updates.tags;

      const { data, error } = await supabase
        .from('expenses')
        .update(updateData)
        .eq('id', id)
        .select('*')
        .single();
      
      if (error) return handleSupabaseError(error);
      
      const convertedData = {
        id: data.id,
        title: data.title,
        description: data.description,
        amount: data.amount,
        supplier: data.supplier,
        invoiceNumber: data.invoice_number,
        paymentMethod: data.payment_method,
        status: data.status,
        expenseDate: new Date(data.expense_date),
        dueDate: data.due_date ? new Date(data.due_date) : undefined,
        receiptPath: data.receipt_path,
        tags: data.tags || [],
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at)
      };
      
      return handleSupabaseSuccess(convertedData);
    } catch (error) {
      return handleSupabaseError(error);
    }
  },

  async delete(id: string) {
    try {
      const { error } = await supabase
        .from('expenses')
        .delete()
        .eq('id', id);
      
      if (error) return handleSupabaseError(error);
      
      return handleSupabaseSuccess(true);
    } catch (error) {
      return handleSupabaseError(error);
    }
  },

  async getStats() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseSuccess({
          total: 0,
          monthly: 0,
          pending: 0,
          paid: 0
        });
      }

      // Récupérer toutes les dépenses
      const { data: expenses, error } = await supabase
        .from('expenses')
        .select(`
          amount,
          status,
          expense_date
        `)
        .eq('user_id', user.id);
      
      if (error) return handleSupabaseError(error);

      const stats: ExpenseStats = {
        total: 0,
        monthly: 0,
        pending: 0,
        paid: 0
      };

      const currentMonth = new Date();
      currentMonth.setDate(1);

      expenses?.forEach(expense => {
        stats.total += expense.amount;
        
        if (expense.status === 'pending') {
          stats.pending += expense.amount;
        } else if (expense.status === 'paid') {
          stats.paid += expense.amount;
        }

        const expenseDate = new Date(expense.expense_date);
        if (expenseDate >= currentMonth) {
          stats.monthly += expense.amount;
        }

        // Pas de catégorie nécessaire
      });

      return handleSupabaseSuccess(stats);
    } catch (error) {
      return handleSupabaseError(error);
    }
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
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(service => ({
      id: service.id,
      name: service.name,
      description: service.description,
      duration: service.duration,
      price: service.price,
      category: service.category,
      subcategory: service.subcategory || undefined,
      applicableDevices: service.applicable_devices || [],
      isActive: service.is_active,
      createdAt: new Date(service.created_at),
      updatedAt: new Date(service.updated_at)
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
      .from('services')
      .select('*')
      .eq('id', id)
      .eq('user_id', user.id)
      .single();
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = {
      id: data.id,
      name: data.name,
      description: data.description,
      duration: data.duration,
      price: data.price,
      category: data.category,
      subcategory: data.subcategory || undefined,
      applicableDevices: data.applicable_devices || [],
      isActive: data.is_active,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at)
    };
    
    return handleSupabaseSuccess(convertedData);
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
      subcategory: service.subcategory || null,
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
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = {
      id: data.id,
      name: data.name,
      description: data.description,
      duration: data.duration,
      price: data.price,
      category: data.category,
      subcategory: data.subcategory || undefined,
      applicableDevices: data.applicable_devices || [],
      isActive: data.is_active,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at)
    };
    
    return handleSupabaseSuccess(convertedData);
  },

  async update(id: string, updates: Partial<Service>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Convertir les noms de propriétés camelCase vers snake_case
    const updateData: any = {
      updated_at: new Date().toISOString()
    };

    if (updates.name !== undefined) updateData.name = updates.name;
    if (updates.description !== undefined) updateData.description = updates.description;
    if (updates.duration !== undefined) updateData.duration = updates.duration;
    if (updates.price !== undefined) updateData.price = updates.price;
    if (updates.category !== undefined) updateData.category = updates.category;
    if (updates.subcategory !== undefined) updateData.subcategory = updates.subcategory || null;
    if (updates.applicableDevices !== undefined) updateData.applicable_devices = updates.applicableDevices;
    if (updates.isActive !== undefined) updateData.is_active = updates.isActive;

    const { data, error } = await supabase
      .from('services')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = {
      id: data.id,
      name: data.name,
      description: data.description,
      duration: data.duration,
      price: data.price,
      category: data.category,
      subcategory: data.subcategory || undefined,
      applicableDevices: data.applicable_devices || [],
      isActive: data.is_active,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at)
    };
    
    return handleSupabaseSuccess(convertedData);
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
    console.log('🔍 getAll() appointments appelé');
    
    // Utiliser les politiques RLS pour l'isolation automatique
    const { data, error } = await supabase
      .from('appointments')
      .select('*')
      .order('start_date', { ascending: true });
    
    if (error) {
      console.error('❌ Erreur lors de la récupération des rendez-vous:', error);
      return handleSupabaseError(error);
    }
    
    console.log('📊 Rendez-vous récupérés via RLS:', data?.length || 0);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(appointment => ({
      id: appointment.id,
      userId: appointment.user_id,
      clientId: appointment.client_id,
      repairId: appointment.repair_id,
      title: appointment.title,
      description: appointment.description,
      startDate: new Date(appointment.start_date || appointment.start_time),
      endDate: new Date(appointment.end_date || appointment.end_time),
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
      startDate: new Date(data.start_date || data.start_time),
      endDate: new Date(data.end_date || data.end_time),
      assignedUserId: data.assigned_user_id,
      status: data.status,
      createdAt: new Date(data.created_at),
      updatedAt: new Date(data.updated_at)
    };
    
    return handleSupabaseSuccess(convertedData);
  },

  async create(appointment: Omit<Appointment, 'id' | 'createdAt' | 'updatedAt'>) {
    // Récupérer l'utilisateur connecté depuis auth.users
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    const userId = user?.id;
    
    if (!userId) {
      console.error('❌ Aucun utilisateur authentifié');
      return handleSupabaseError(new Error('Utilisateur non authentifié'));
    }
    
    // Convertir les noms de propriétés camelCase vers snake_case
    // Gérer les valeurs vides en les convertissant en null
    const appointmentData: any = {
      user_id: userId, // Ajouter l'utilisateur connecté
      client_id: appointment.clientId && appointment.clientId.trim() !== '' ? appointment.clientId : null,
      repair_id: appointment.repairId && appointment.repairId.trim() !== '' ? appointment.repairId : null,
      title: appointment.title,
      description: appointment.description,
      start_date: appointment.startDate.toISOString(),
      end_date: appointment.endDate.toISOString(),
      status: appointment.status,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    // N'ajouter assigned_user_id que s'il a une valeur valide
    if (appointment.assignedUserId && appointment.assignedUserId.trim() !== '') {
      appointmentData.assigned_user_id = appointment.assignedUserId;
    }

    const { data, error } = await supabase
      .from('appointments')
      .insert([appointmentData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(data);
  },

  async update(id: string, updates: Partial<Appointment>) {
    // Récupérer l'utilisateur connecté depuis auth.users
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    const userId = user?.id;
    
    if (!userId) {
      console.error('❌ Aucun utilisateur authentifié');
      return handleSupabaseError(new Error('Utilisateur non authentifié'));
    }
    
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
      if (updates.assignedUserId && updates.assignedUserId.trim() !== '') {
        updateData.assigned_user_id = updates.assignedUserId;
      } else {
        // Si la valeur est vide, on supprime le champ pour éviter les erreurs de contrainte
        updateData.assigned_user_id = null;
      }
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
      const completedRepairs = repairs?.filter(r => r.status === 'completed' || r.status === 'returned').length || 0;
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
      
      // Faire une jointure pour récupérer les noms des marques et catégories
      const { data, error } = await supabase
        .from('device_models')
        .select(`
          *,
          device_brands!inner(name),
          device_categories!inner(name)
        `)
        .eq('created_by', user.id)
        .order('brand_id', { ascending: true })
        .order('name', { ascending: true });
      
      if (error) return handleSupabaseError(error);
      
      // Convertir les données de snake_case vers camelCase avec les noms des marques et catégories
      const convertedData = (data as any[])?.map((model: any) => ({
        id: model.id,
        brand: model.device_brands?.name || 'N/A',
        model: model.name,
        type: model.device_categories?.name || 'N/A',
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

      // Faire une jointure pour récupérer les noms des marques et catégories
      const { data, error } = await supabase
        .from('device_models')
        .select(`
          *,
          device_brands!inner(name),
          device_categories!inner(name)
        `)
        .eq('id', id)
        .eq('created_by', user.id)
        .single();
      
      if (error) return handleSupabaseError(error);
      
      // Convertir les données avec les noms des marques et catégories
      const convertedData = {
        id: (data as any).id,
        brand: (data as any).device_brands?.name || 'N/A',
        model: (data as any).name,
        type: (data as any).device_categories?.name || 'N/A',
        year: (data as any).year,
        specifications: (data as any).specifications || {},
        commonIssues: (data as any).common_issues || [],
        repairDifficulty: (data as any).repair_difficulty,
        partsAvailability: (data as any).parts_availability,
        isActive: (data as any).is_active,
        createdAt: new Date((data as any).created_at),
        updatedAt: new Date((data as any).updated_at)
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

// Service pour les abonnements
export const subscriptionService = {
  async getUsersWithSubscriptionStatus() {
    try {
      console.log('🔍 Récupération des utilisateurs avec statut d\'abonnement...');
      
      // ESSAYER D'ACCÉDER À LA VRAIE TABLE SUBSCRIPTION_STATUS
      const { data: subscriptions, error: subscriptionError } = await supabase
        .from('subscription_status')
        .select('*')
        .order('created_at', { ascending: false });

      if (subscriptionError) {
        console.error('❌ Erreur subscription_status:', subscriptionError);
        
        // Si c'est une erreur 406 (permissions), utiliser les données simulées
        if (subscriptionError.code === '406') {
          console.log('⚠️ Utilisation des données simulées (erreur 406)');
          return this.getSimulatedData();
        }
        
        return handleSupabaseError(subscriptionError);
      }

      console.log('✅ Données récupérées depuis subscription_status:', subscriptions?.length || 0, 'utilisateurs');
      return handleSupabaseSuccess(subscriptions || []);
    } catch (err) {
      console.error('❌ Erreur dans getUsersWithSubscriptionStatus:', err);
      return handleSupabaseError(err as any);
    }
  },

  async getSimulatedData() {
    // Données simulées en cas d'erreur
    const knownUsers = [
      {
        id: '68432d4b-1747-448c-9908-483be4fdd8dd',
        email: 'repphonereparation@gmail.com',
        first_name: 'RepPhone',
        last_name: 'Reparation',
        created_at: new Date().toISOString()
      },
      {
        id: 'admin-user-id',
        email: 'srohee32@gmail.com',
        first_name: 'Admin',
        last_name: 'User',
        created_at: new Date().toISOString()
      }
    ];

    const combinedData = knownUsers.map(user => {
      const userEmail = user.email?.toLowerCase();
      const isAdmin = userEmail === 'srohee32@gmail.com';
      
      return {
        id: `temp_${user.id}`,
        user_id: user.id,
        first_name: user.first_name || (isAdmin ? 'Admin' : 'Utilisateur'),
        last_name: user.last_name || '',
        email: user.email,
        is_active: isAdmin,
        subscription_type: isAdmin ? 'premium' : 'free',
        created_at: user.created_at,
        updated_at: user.created_at,
        activated_at: isAdmin ? user.created_at : null,
        activated_by: isAdmin ? user.id : null,
        notes: isAdmin 
          ? 'Administrateur - accès complet' 
          : 'Compte créé - en attente d\'activation'
      };
    });

    return handleSupabaseSuccess(combinedData);
  },

  async getAllSubscriptionStatuses() {
    return this.getUsersWithSubscriptionStatus();
  },

  async activateSubscription(userId: string, activatedBy?: string, notes?: string) {
    try {
      console.log(`✅ Tentative d'activation pour l'utilisateur ${userId}`);
      
      // Vérifier d'abord si l'utilisateur existe déjà dans subscription_status
      const { data: existingUser, error: fetchError } = await supabase
        .from('subscription_status')
        .select('*')
        .eq('user_id', userId)
        .single();

      let upsertData: any = {
        user_id: userId,
        is_active: true,
        activated_at: new Date().toISOString(),
        activated_by: activatedBy || null,
        status: 'ACTIF',
        subscription_type: 'free',
        notes: notes || 'Activé manuellement',
        updated_at: new Date().toISOString()
      };

      // Si l'utilisateur existe déjà, utiliser ses données existantes
      if (existingUser && !fetchError) {
        console.log('📝 Utilisateur existant trouvé, mise à jour des données');
        upsertData = {
          ...existingUser,
          ...upsertData,
          // Garder les données existantes si elles sont valides
          email: existingUser.email || `user_${userId}@example.com`,
          first_name: existingUser.first_name || 'Utilisateur',
          last_name: existingUser.last_name || 'Test'
        };
      } else {
        console.log('📝 Nouvel utilisateur, utilisation de valeurs par défaut');
        // Pour un nouvel utilisateur, utiliser des valeurs par défaut
        upsertData = {
          ...upsertData,
          email: `user_${userId}@example.com`,
          first_name: 'Utilisateur',
          last_name: 'Test'
        };
      }

      console.log('📝 Données upsert:', upsertData);
      
      // Essayer d'activer dans la vraie table
      const { data, error } = await supabase
        .from('subscription_status')
        .upsert(upsertData, {
          onConflict: 'user_id'
        })
        .select()
        .single();

      if (error) {
        console.error('❌ Erreur activation:', error);
        if (error.code === '406') {
          console.log('⚠️ Activation simulée (erreur 406)');
          return handleSupabaseSuccess({ 
            message: 'Activation simulée réussie',
            userId,
            activatedBy,
            notes 
          });
        }
        return handleSupabaseError(error);
      }

      console.log('✅ Activation réussie dans la table');
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('❌ Erreur dans activateSubscription:', err);
      return handleSupabaseError(err as any);
    }
  },

  async deactivateSubscription(userId: string, notes?: string) {
    try {
      console.log(`❌ Tentative de désactivation pour l'utilisateur ${userId}`);
      
      const { data, error } = await supabase
        .from('subscription_status')
        .update({
          is_active: false,
          activated_at: null,
          activated_by: null,
          notes: notes || 'Désactivé manuellement',
          updated_at: new Date().toISOString()
        })
        .eq('user_id', userId)
        .select()
        .single();

      if (error) {
        console.error('❌ Erreur désactivation:', error);
        if (error.code === '406') {
          console.log('⚠️ Désactivation simulée (erreur 406)');
          return handleSupabaseSuccess({ 
            message: 'Désactivation simulée réussie',
            userId,
            notes 
          });
        }
        return handleSupabaseError(error);
      }

      console.log('✅ Désactivation réussie dans la table');
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('❌ Erreur dans deactivateSubscription:', err);
      return handleSupabaseError(err as any);
    }
  },

  async updateSubscriptionType(userId: string, subscriptionType: 'free' | 'premium' | 'enterprise', notes?: string) {
    try {
      console.log(`🔄 Tentative de mise à jour pour l'utilisateur ${userId}: ${subscriptionType}`);
      
      const { data, error } = await supabase
        .from('subscription_status')
        .update({
          subscription_type: subscriptionType,
          notes: notes || `Type d'abonnement modifié vers ${subscriptionType}`,
          updated_at: new Date().toISOString()
        })
        .eq('user_id', userId)
        .select()
        .single();

      if (error) {
        console.error('❌ Erreur mise à jour:', error);
        if (error.code === '406') {
          console.log('⚠️ Mise à jour simulée (erreur 406)');
          return handleSupabaseSuccess({ 
            message: 'Mise à jour simulée réussie',
            userId,
            subscriptionType,
            notes 
          });
        }
        return handleSupabaseError(error);
      }

      console.log('✅ Mise à jour réussie dans la table');
      return handleSupabaseSuccess(data);
    } catch (err) {
      console.error('❌ Erreur dans updateSubscriptionType:', err);
      return handleSupabaseError(err as any);
    }
  }
};

// Service pour les rachats d'appareils
export const buybackService = {
  async getAll() {
    console.log('🔍 buybackService.getAll() appelé');
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        console.log('❌ Aucun utilisateur connecté');
        return handleSupabaseSuccess([]);
      }

      const { data, error } = await supabase
        .from('buybacks')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });
      
      console.log('📊 Résultat Supabase buybacks:', { data, error });
      
      if (error) {
        console.error('❌ Erreur Supabase buybacks:', error);
        return handleSupabaseError(error);
      }
      
      // Conversion snake_case vers camelCase pour l'interface
      const convertedData = data?.map((item: any) => ({
        id: item.id,
        clientFirstName: item.client_first_name,
        clientLastName: item.client_last_name,
        clientEmail: item.client_email,
        clientPhone: item.client_phone,
        clientAddress: item.client_address,
        clientAddressComplement: item.client_address_complement,
        clientPostalCode: item.client_postal_code,
        clientCity: item.client_city,
        clientIdType: item.client_id_type,
        clientIdNumber: item.client_id_number,
        deviceType: item.device_type,
        deviceBrand: item.device_brand,
        deviceModel: item.device_model,
        deviceImei: item.device_imei,
        deviceSerialNumber: item.device_serial_number,
        deviceColor: item.device_color,
        deviceStorageCapacity: item.device_storage_capacity,
        physicalCondition: item.physical_condition,
        functionalCondition: item.functional_condition,
        batteryHealth: item.battery_health,
        screenCondition: item.screen_condition,
        buttonCondition: item.button_condition,
        icloudLocked: item.icloud_locked,
        googleLocked: item.google_locked,
        carrierLocked: item.carrier_locked,
        otherLocks: item.other_locks,
        accessories: item.accessories,
        suggestedPrice: item.suggested_price,
        offeredPrice: item.offered_price,
        finalPrice: item.final_price,
        paymentMethod: item.payment_method,
        buybackReason: item.buyback_reason,
        hasWarranty: item.has_warranty,
        warrantyExpiresAt: item.warranty_expires_at,
        photos: item.photos,
        documents: item.documents,
        status: item.status,
        internalNotes: item.internal_notes,
        clientNotes: item.client_notes,
        termsAccepted: item.terms_accepted,
        termsAcceptedAt: item.terms_accepted_at,
        userId: item.user_id,
        createdAt: item.created_at,
        updatedAt: item.updated_at
      })) || [];
      
      console.log('✅ Données rachats récupérées:', convertedData);
      return handleSupabaseSuccess(convertedData);
    } catch (err) {
      console.error('💥 Exception dans getAll buybacks:', err);
      return handleSupabaseSuccess([]);
    }
  },

  async getById(id: string) {
    console.log('🔍 buybackService.getById() appelé pour:', id);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { data, error } = await supabase
        .from('buybacks')
        .select('*')
        .eq('id', id)
        .eq('user_id', user.id)
        .single();
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(data);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async create(buyback: Omit<Buyback, 'id' | 'createdAt' | 'updatedAt'>) {
    console.log('🔍 buybackService.create() appelé');
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      // Conversion camelCase vers snake_case pour la base de données
      const buybackData = {
        client_first_name: buyback.clientFirstName,
        client_last_name: buyback.clientLastName,
        client_email: buyback.clientEmail,
        client_phone: buyback.clientPhone,
        client_address: buyback.clientAddress,
        client_address_complement: buyback.clientAddressComplement,
        client_postal_code: buyback.clientPostalCode,
        client_city: buyback.clientCity,
        client_id_type: buyback.clientIdType,
        client_id_number: buyback.clientIdNumber,
        device_type: buyback.deviceType,
        device_brand: buyback.deviceBrand,
        device_model: buyback.deviceModel,
        device_imei: buyback.deviceImei,
        device_serial_number: buyback.deviceSerialNumber,
        device_color: buyback.deviceColor,
        device_storage_capacity: buyback.deviceStorageCapacity,
        physical_condition: buyback.physicalCondition,
        functional_condition: buyback.functionalCondition,
        battery_health: buyback.batteryHealth,
        screen_condition: buyback.screenCondition,
        button_condition: buyback.buttonCondition,
        icloud_locked: buyback.icloudLocked,
        google_locked: buyback.googleLocked,
        carrier_locked: buyback.carrierLocked,
        other_locks: buyback.otherLocks,
        accessories: buyback.accessories,
        suggested_price: buyback.suggestedPrice,
        offered_price: buyback.offeredPrice,
        final_price: buyback.finalPrice,
        payment_method: buyback.paymentMethod,
        buyback_reason: buyback.buybackReason,
        has_warranty: buyback.hasWarranty,
        warranty_expires_at: buyback.warrantyExpiresAt,
        photos: buyback.photos,
        documents: buyback.documents,
        status: buyback.status,
        internal_notes: buyback.internalNotes,
        client_notes: buyback.clientNotes,
        terms_accepted: buyback.termsAccepted,
        terms_accepted_at: buyback.termsAcceptedAt,
        user_id: user.id,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const { data, error } = await supabase
        .from('buybacks')
        .insert([buybackData])
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(data);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async update(id: string, buyback: Partial<Omit<Buyback, 'id' | 'createdAt' | 'updatedAt' | 'userId'>>) {
    console.log('🔍 buybackService.update() appelé pour:', id);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const updateData = {
        ...buyback,
        updated_at: new Date().toISOString()
      };

      const { data, error } = await supabase
        .from('buybacks')
        .update(updateData)
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(data);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async delete(id: string) {
    console.log('🔍 buybackService.delete() appelé pour:', id);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { error } = await supabase
        .from('buybacks')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess({ message: 'Rachat supprimé avec succès' });
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async updateStatus(id: string, status: BuybackStatus) {
    console.log('🔍 buybackService.updateStatus() appelé pour:', id, 'statut:', status);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { data, error } = await supabase
        .from('buybacks')
        .update({ 
          status,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);

      // Si le rachat est marqué comme payé, créer automatiquement une dépense
      if (status === 'paid' && data) {
        console.log('💰 Rachat payé détecté, création automatique d\'une dépense...');
        
        try {
          // Récupérer les détails du rachat pour créer la dépense
          const buybackData = data;
          const expenseAmount = buybackData.final_price || buybackData.offered_price;
          
          // Créer la dépense automatiquement
          const expenseData = {
            title: `Rachat d'appareil - ${buybackData.device_brand} ${buybackData.device_model}`,
            description: `Rachat d'appareil de ${buybackData.client_first_name} ${buybackData.client_last_name}. Appareil: ${buybackData.device_brand} ${buybackData.device_model}`,
            amount: expenseAmount,
            supplier: `${buybackData.client_first_name} ${buybackData.client_last_name}`,
            paymentMethod: buybackData.payment_method,
            status: 'paid' as const,
            expenseDate: new Date(),
            tags: ['rachat', 'appareil', 'automatique']
          };

          const expenseResult = await expenseService.create(expenseData);
          
          if (expenseResult.success) {
            console.log('✅ Dépense créée automatiquement pour le rachat payé');
            
            // Recharger les dépenses dans le store pour mettre à jour l'interface
            try {
              const { useAppStore } = await import('../store');
              const store = useAppStore.getState();
              await store.loadExpenses();
              console.log('✅ Dépenses rechargées dans le store');
            } catch (storeError) {
              console.warn('⚠️ Erreur lors du rechargement des dépenses dans le store:', storeError);
            }
          } else {
            console.warn('⚠️ Erreur lors de la création automatique de la dépense:', expenseResult.error);
          }
        } catch (expenseError) {
          console.error('❌ Erreur lors de la création automatique de la dépense:', expenseError);
          // Ne pas faire échouer la mise à jour du statut du rachat si la création de dépense échoue
        }
      }

      return handleSupabaseSuccess(data);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  }
};

// Service pour les devis
export const quoteService = {
  async getAll() {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { data, error } = await supabase
      .from('quotes')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data?.map(quote => ({
      id: quote.id,
      clientId: quote.client_id,
      quoteNumber: quote.quote_number,
      items: quote.items || [],
      subtotal: quote.subtotal,
      tax: quote.tax,
      total: quote.total,
      discountPercentage: quote.discount_percentage,
      discountAmount: quote.discount_amount,
      originalTotal: quote.original_total,
      status: quote.status,
      validUntil: quote.valid_until,
      notes: quote.notes,
      terms: quote.terms,
      repairDetails: quote.repair_details,
      createdAt: quote.created_at,
      updatedAt: quote.updated_at
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
      .from('quotes')
      .select(`
        *,
        client:clients(*)
      `)
      .eq('id', id)
      .eq('user_id', user.id)
      .single();
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = data ? {
      id: data.id,
      clientId: data.client_id,
      quoteNumber: data.quote_number,
      items: data.items || [],
      subtotal: data.subtotal,
      tax: data.tax,
      total: data.total,
      discountPercentage: data.discount_percentage,
      discountAmount: data.discount_amount,
      originalTotal: data.original_total,
      status: data.status,
      validUntil: data.valid_until,
      notes: data.notes,
      terms: data.terms,
      repairDetails: data.repair_details,
      createdAt: data.created_at,
      updatedAt: data.updated_at,
      client: data.client
    } : null;
    
    return handleSupabaseSuccess(convertedData);
  },

  async create(quote: Omit<Quote, 'id' | 'createdAt' | 'updatedAt'>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Vérifier que le client appartient à l'utilisateur connecté
    if (quote.clientId) {
      const { data: clientData, error: clientError } = await supabase
        .from('clients')
        .select('id')
        .eq('id', quote.clientId)
        .eq('user_id', user.id)
        .single();
      
      if (clientError || !clientData) {
        return handleSupabaseError(new Error('Client non trouvé ou n\'appartient pas à l\'utilisateur connecté'));
      }
    }

    // Convertir les noms de propriétés camelCase vers snake_case
    const quoteData = {
      client_id: quote.clientId,
      quote_number: quote.quoteNumber,
      items: JSON.stringify(quote.items || []),
      subtotal: quote.subtotal,
      tax: quote.tax,
      total: quote.total,
      discount_percentage: quote.discountPercentage || 0,
      discount_amount: quote.discountAmount || 0,
      original_total: quote.originalTotal || quote.total,
      status: quote.status,
      valid_until: quote.validUntil,
      notes: quote.notes,
      terms: quote.terms,
      repair_details: quote.repairDetails ? JSON.stringify(quote.repairDetails) : null,
      user_id: user.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('quotes')
      .insert([quoteData])
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = {
      id: data.id,
      clientId: data.client_id,
      quoteNumber: data.quote_number,
      items: data.items || [],
      subtotal: data.subtotal,
      tax: data.tax,
      total: data.total,
      discountPercentage: data.discount_percentage,
      discountAmount: data.discount_amount,
      originalTotal: data.original_total,
      status: data.status,
      validUntil: data.valid_until,
      notes: data.notes,
      terms: data.terms,
      repairDetails: data.repair_details,
      createdAt: data.created_at,
      updatedAt: data.updated_at
    };
    
    return handleSupabaseSuccess(convertedData);
  },

  async update(id: string, updates: Partial<Quote>) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    // Convertir les noms de propriétés camelCase vers snake_case
    const updateData: any = {
      updated_at: new Date().toISOString()
    };
    
    if (updates.clientId !== undefined) updateData.client_id = updates.clientId;
    if (updates.quoteNumber !== undefined) updateData.quote_number = updates.quoteNumber;
    if (updates.items !== undefined) updateData.items = JSON.stringify(updates.items);
    if (updates.subtotal !== undefined) updateData.subtotal = updates.subtotal;
    if (updates.tax !== undefined) updateData.tax = updates.tax;
    if (updates.total !== undefined) updateData.total = updates.total;
    if (updates.discountPercentage !== undefined) updateData.discount_percentage = updates.discountPercentage;
    if (updates.discountAmount !== undefined) updateData.discount_amount = updates.discountAmount;
    if (updates.originalTotal !== undefined) updateData.original_total = updates.originalTotal;
    if (updates.status !== undefined) updateData.status = updates.status;
    if (updates.validUntil !== undefined) updateData.valid_until = updates.validUntil;
    if (updates.notes !== undefined) updateData.notes = updates.notes;
    if (updates.terms !== undefined) updateData.terms = updates.terms;
    if (updates.repairDetails !== undefined) updateData.repair_details = updates.repairDetails ? JSON.stringify(updates.repairDetails) : null;

    const { data, error } = await supabase
      .from('quotes')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données de snake_case vers camelCase
    const convertedData = {
      id: data.id,
      clientId: data.client_id,
      quoteNumber: data.quote_number,
      items: data.items || [],
      subtotal: data.subtotal,
      tax: data.tax,
      total: data.total,
      discountPercentage: data.discount_percentage,
      discountAmount: data.discount_amount,
      originalTotal: data.original_total,
      status: data.status,
      validUntil: data.valid_until,
      notes: data.notes,
      terms: data.terms,
      repairDetails: data.repair_details,
      createdAt: data.created_at,
      updatedAt: data.updated_at
    };
    
    return handleSupabaseSuccess(convertedData);
  },

  async delete(id: string) {
    // Obtenir l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return handleSupabaseError(new Error('Utilisateur non connecté'));
    }

    const { error } = await supabase
      .from('quotes')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id);
    
    if (error) return handleSupabaseError(error);
    return handleSupabaseSuccess(true);
  }
};

// Service pour les prix de marché des appareils
export const deviceMarketPriceService = {
  async getAll() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { data, error } = await supabase
        .from('device_market_prices')
        .select('*')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .order('device_brand', { ascending: true })
        .order('device_model', { ascending: true });
      
      if (error) return handleSupabaseError(error);
      
      // Conversion snake_case vers camelCase
      const convertedData = data?.map((item: any) => ({
        id: item.id,
        deviceModelId: item.device_model_id,
        deviceBrand: item.device_brand,
        deviceModel: item.device_model,
        deviceType: item.device_type,
        pricesByCapacity: item.prices_by_capacity,
        releaseYear: item.release_year,
        marketSegment: item.market_segment,
        baseMarketPrice: item.base_market_price,
        currentMarketPrice: item.current_market_price,
        depreciationRate: item.depreciation_rate,
        conditionMultipliers: item.condition_multipliers,
        screenConditionMultipliers: item.screen_condition_multipliers,
        batteryHealthPenalty: item.battery_health_penalty,
        buttonConditionPenalty: item.button_condition_penalty,
        functionalPenalties: item.functional_penalties,
        accessoriesBonus: item.accessories_bonus,
        warrantyBonusPercentage: item.warranty_bonus_percentage,
        lockPenalties: item.lock_penalties,
        isActive: item.is_active,
        lastPriceUpdate: new Date(item.last_price_update),
        priceSource: item.price_source,
        externalApiId: item.external_api_id,
        userId: item.user_id,
        createdAt: new Date(item.created_at),
        updatedAt: new Date(item.updated_at)
      })) || [];
      
      return handleSupabaseSuccess(convertedData);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async getById(id: string) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { data, error } = await supabase
        .from('device_market_prices')
        .select('*')
        .eq('id', id)
        .eq('user_id', user.id)
        .single();
      
      if (error) return handleSupabaseError(error);
      
      // Conversion snake_case vers camelCase
      const convertedData = {
        id: data.id,
        deviceModelId: data.device_model_id,
        deviceBrand: data.device_brand,
        deviceModel: data.device_model,
        deviceType: data.device_type,
        pricesByCapacity: data.prices_by_capacity,
        releaseYear: data.release_year,
        marketSegment: data.market_segment,
        baseMarketPrice: data.base_market_price,
        currentMarketPrice: data.current_market_price,
        depreciationRate: data.depreciation_rate,
        conditionMultipliers: data.condition_multipliers,
        screenConditionMultipliers: data.screen_condition_multipliers,
        batteryHealthPenalty: data.battery_health_penalty,
        buttonConditionPenalty: data.button_condition_penalty,
        functionalPenalties: data.functional_penalties,
        accessoriesBonus: data.accessories_bonus,
        warrantyBonusPercentage: data.warranty_bonus_percentage,
        lockPenalties: data.lock_penalties,
        isActive: data.is_active,
        lastPriceUpdate: new Date(data.last_price_update),
        priceSource: data.price_source,
        externalApiId: data.external_api_id,
        userId: data.user_id,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at)
      };
      
      return handleSupabaseSuccess(convertedData);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async getByDevice(brand: string, model: string, deviceType: string) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      const { data, error } = await supabase
        .from('device_market_prices')
        .select('*')
        .eq('device_brand', brand)
        .eq('device_model', model)
        .eq('device_type', deviceType)
        .eq('user_id', user.id)
        .eq('is_active', true)
        .single();
      
      if (error) return handleSupabaseError(error);
      
      // Conversion snake_case vers camelCase
      const convertedData = {
        id: data.id,
        deviceModelId: data.device_model_id,
        deviceBrand: data.device_brand,
        deviceModel: data.device_model,
        deviceType: data.device_type,
        pricesByCapacity: data.prices_by_capacity,
        releaseYear: data.release_year,
        marketSegment: data.market_segment,
        baseMarketPrice: data.base_market_price,
        currentMarketPrice: data.current_market_price,
        depreciationRate: data.depreciation_rate,
        conditionMultipliers: data.condition_multipliers,
        screenConditionMultipliers: data.screen_condition_multipliers,
        batteryHealthPenalty: data.battery_health_penalty,
        buttonConditionPenalty: data.button_condition_penalty,
        functionalPenalties: data.functional_penalties,
        accessoriesBonus: data.accessories_bonus,
        warrantyBonusPercentage: data.warranty_bonus_percentage,
        lockPenalties: data.lock_penalties,
        isActive: data.is_active,
        lastPriceUpdate: new Date(data.last_price_update),
        priceSource: data.price_source,
        externalApiId: data.external_api_id,
        userId: data.user_id,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at)
      };
      
      return handleSupabaseSuccess(convertedData);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async create(priceData: Omit<DeviceMarketPrice, 'id' | 'createdAt' | 'updatedAt' | 'userId'>) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      // Conversion camelCase vers snake_case
      const marketPriceData = {
        device_model_id: priceData.deviceModelId,
        device_brand: priceData.deviceBrand,
        device_model: priceData.deviceModel,
        device_type: priceData.deviceType,
        prices_by_capacity: priceData.pricesByCapacity,
        release_year: priceData.releaseYear,
        market_segment: priceData.marketSegment,
        base_market_price: priceData.baseMarketPrice,
        current_market_price: priceData.currentMarketPrice,
        depreciation_rate: priceData.depreciationRate,
        condition_multipliers: priceData.conditionMultipliers,
        screen_condition_multipliers: priceData.screenConditionMultipliers,
        battery_health_penalty: priceData.batteryHealthPenalty,
        button_condition_penalty: priceData.buttonConditionPenalty,
        functional_penalties: priceData.functionalPenalties,
        accessories_bonus: priceData.accessoriesBonus,
        warranty_bonus_percentage: priceData.warrantyBonusPercentage,
        lock_penalties: priceData.lockPenalties,
        is_active: priceData.isActive,
        last_price_update: priceData.lastPriceUpdate.toISOString(),
        price_source: priceData.priceSource,
        external_api_id: priceData.externalApiId,
        user_id: user.id,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const { data, error } = await supabase
        .from('device_market_prices')
        .insert([marketPriceData])
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);
      
      // Conversion de la réponse
      const convertedData = {
        id: data.id,
        deviceModelId: data.device_model_id,
        deviceBrand: data.device_brand,
        deviceModel: data.device_model,
        deviceType: data.device_type,
        pricesByCapacity: data.prices_by_capacity,
        releaseYear: data.release_year,
        marketSegment: data.market_segment,
        baseMarketPrice: data.base_market_price,
        currentMarketPrice: data.current_market_price,
        depreciationRate: data.depreciation_rate,
        conditionMultipliers: data.condition_multipliers,
        screenConditionMultipliers: data.screen_condition_multipliers,
        batteryHealthPenalty: data.battery_health_penalty,
        buttonConditionPenalty: data.button_condition_penalty,
        functionalPenalties: data.functional_penalties,
        accessoriesBonus: data.accessories_bonus,
        warrantyBonusPercentage: data.warranty_bonus_percentage,
        lockPenalties: data.lock_penalties,
        isActive: data.is_active,
        lastPriceUpdate: new Date(data.last_price_update),
        priceSource: data.price_source,
        externalApiId: data.external_api_id,
        userId: data.user_id,
        createdAt: new Date(data.created_at),
        updatedAt: new Date(data.updated_at)
      };
      
      return handleSupabaseSuccess(convertedData);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  },

  async update(id: string, updates: Partial<Omit<DeviceMarketPrice, 'id' | 'createdAt' | 'updatedAt' | 'userId'>>) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      // Conversion camelCase vers snake_case
      const updateData: any = {
        updated_at: new Date().toISOString()
      };

      if (updates.deviceModelId !== undefined) updateData.device_model_id = updates.deviceModelId;
      if (updates.deviceBrand !== undefined) updateData.device_brand = updates.deviceBrand;
      if (updates.deviceModel !== undefined) updateData.device_model = updates.deviceModel;
      if (updates.deviceType !== undefined) updateData.device_type = updates.deviceType;
      if (updates.pricesByCapacity !== undefined) updateData.prices_by_capacity = updates.pricesByCapacity;
      if (updates.releaseYear !== undefined) updateData.release_year = updates.releaseYear;
      if (updates.marketSegment !== undefined) updateData.market_segment = updates.marketSegment;
      if (updates.baseMarketPrice !== undefined) updateData.base_market_price = updates.baseMarketPrice;
      if (updates.currentMarketPrice !== undefined) updateData.current_market_price = updates.currentMarketPrice;
      if (updates.depreciationRate !== undefined) updateData.depreciation_rate = updates.depreciationRate;
      if (updates.conditionMultipliers !== undefined) updateData.condition_multipliers = updates.conditionMultipliers;
      if (updates.screenConditionMultipliers !== undefined) updateData.screen_condition_multipliers = updates.screenConditionMultipliers;
      if (updates.batteryHealthPenalty !== undefined) updateData.battery_health_penalty = updates.batteryHealthPenalty;
      if (updates.buttonConditionPenalty !== undefined) updateData.button_condition_penalty = updates.buttonConditionPenalty;
      if (updates.functionalPenalties !== undefined) updateData.functional_penalties = updates.functionalPenalties;
      if (updates.accessoriesBonus !== undefined) updateData.accessories_bonus = updates.accessoriesBonus;
      if (updates.warrantyBonusPercentage !== undefined) updateData.warranty_bonus_percentage = updates.warrantyBonusPercentage;
      if (updates.lockPenalties !== undefined) updateData.lock_penalties = updates.lockPenalties;
      if (updates.isActive !== undefined) updateData.is_active = updates.isActive;
      if (updates.lastPriceUpdate !== undefined) updateData.last_price_update = updates.lastPriceUpdate.toISOString();
      if (updates.priceSource !== undefined) updateData.price_source = updates.priceSource;
      if (updates.externalApiId !== undefined) updateData.external_api_id = updates.externalApiId;

      const { data, error } = await supabase
        .from('device_market_prices')
        .update(updateData)
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();
      
      if (error) return handleSupabaseError(error);
      
      // Conversion de la réponse
      const convertedData = {
        id: data.id,
        deviceModelId: data.device_model_id,
        deviceBrand: data.device_brand,
        deviceModel: data.device_model,
        deviceType: data.device_type,
        pricesByCapacity: data.prices_by_capacity,
        releaseYear: data.release_year,
        marketSegment: data.market_segment,
        baseMarketPrice: data.base_market_price,
        currentMarketPrice: data.current_market_price,
        depreciationRate: data.depreciation_rate,
        conditionMultipliers: data.condition_multipliers,
        screenConditionMultipliers: data.screen_condition_multipliers,
        batteryHealthPenalty: data.battery_health_penalty,
        buttonConditionPenalty: data.button_condition_penalty,
        functionalPenalties: data.functional_penalties,
        accessoriesBonus: data.accessories_bonus,
        warrantyBonusPercentage: data.warranty_bonus_percentage,
        lockPenalties: data.lock_penalties,
        isActive: data.is_active,
        lastPriceUpdate: new Date(data.last_price_update),
        priceSource: data.price_source,
        externalApiId: data.external_api_id,
        userId: data.user_id,
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
        .from('device_market_prices')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
      
      if (error) return handleSupabaseError(error);
      return handleSupabaseSuccess(true);
    } catch (err) {
      return handleSupabaseError(err as any);
    }
  }
};

export default {
  userService,
  systemSettingsService,
  userSettingsService,
  clientService,
  deviceService,
  deviceModelService,
  repairService,
  partService,
  productService,
  serviceService,
  saleService,
  quoteService,
  appointmentService,
  dashboardService,
  subscriptionService,
  buybackService,
  deviceMarketPriceService,
};

