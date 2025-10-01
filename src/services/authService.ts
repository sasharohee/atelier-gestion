import { supabase } from '../lib/supabase';
import { User, Session, AuthError } from '@supabase/supabase-js';

// Types pour les réponses du service d'authentification
export interface AuthResponse {
  success: boolean;
  user?: User | null;
  session?: Session | null;
  error?: string | null;
  message?: string;
  needsEmailConfirmation?: boolean;
}

export interface SignUpData {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  role?: string;
}

export interface SignInData {
  email: string;
  password: string;
}

// Service d'authentification simplifié et robuste
export const authService = {
  /**
   * Inscription d'un nouvel utilisateur
   */
  async signUp(data: SignUpData): Promise<AuthResponse> {
    try {
      console.log('🔐 Tentative d\'inscription pour:', data.email);

      // Essayer d'abord la méthode standard Supabase
      const { data: authData, error } = await supabase.auth.signUp({
        email: data.email,
        password: data.password,
        options: {
          data: {
            firstName: data.firstName,
            lastName: data.lastName,
            role: data.role || 'technician'
          }
        }
      });

      if (error) {
        console.error('❌ Erreur avec la méthode standard:', error);
        
        // Si c'est une erreur 500, essayer la méthode bypass
        if (error.message.includes('Database error') || error.message.includes('500')) {
          console.log('🔄 Tentative avec la méthode bypass...');
          
          const { data: bypassData, error: bypassError } = await supabase.rpc('signup_user_complete', {
            user_email: data.email,
            user_password: data.password,
            user_first_name: data.firstName,
            user_last_name: data.lastName,
            user_role: data.role || 'technician'
          });

          if (bypassError) {
            console.error('❌ Erreur avec la méthode bypass:', bypassError);
            return {
              success: false,
              error: bypassError.message || 'Erreur lors de l\'inscription',
              message: 'Erreur d\'inscription'
            };
          }

          if (bypassData?.success) {
            console.log('✅ Inscription réussie avec la méthode bypass pour:', data.email);
            
            // Essayer de se connecter automatiquement après l'inscription
            try {
              const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
                email: data.email,
                password: data.password
              });

              if (signInError) {
                console.warn('⚠️ Connexion automatique échouée:', signInError);
                
                // Si c'est à cause de l'email non confirmé, c'est normal
                if (signInError.message.includes('Email not confirmed')) {
                  return {
                    success: true,
                    user: {
                      id: bypassData.user_id,
                      email: bypassData.email,
                      email_confirmed_at: null
                    } as any,
                    session: null,
                    message: 'Inscription réussie ! Veuillez confirmer votre email puis vous connecter.',
                    needsEmailConfirmation: true,
                    needsManualSignIn: true
                  };
                }
                
                // Autres erreurs de connexion
                return {
                  success: true,
                  user: {
                    id: bypassData.user_id,
                    email: bypassData.email,
                    email_confirmed_at: null
                  } as any,
                  session: null,
                  message: 'Inscription réussie ! Veuillez vous connecter avec vos identifiants.',
                  needsEmailConfirmation: true,
                  needsManualSignIn: true
                };
              }

              // Connexion automatique réussie
              console.log('✅ Connexion automatique réussie après inscription');
              return {
                success: true,
                user: signInData.user,
                session: signInData.session,
                message: 'Inscription et connexion réussies !',
                needsEmailConfirmation: false
              };

            } catch (signInErr) {
              console.warn('⚠️ Erreur lors de la connexion automatique:', signInErr);
              return {
                success: true,
                user: {
                  id: bypassData.user_id,
                  email: bypassData.email,
                  email_confirmed_at: null
                } as any,
                session: null,
                message: 'Inscription réussie ! Veuillez vous connecter avec vos identifiants.',
                needsEmailConfirmation: true,
                needsManualSignIn: true
              };
            }
          } else {
            return {
              success: false,
              error: bypassData?.error || 'Erreur lors de l\'inscription',
              message: 'Erreur d\'inscription'
            };
          }
        }
        
        // Gestion des erreurs spécifiques pour la méthode standard
        if (error.message.includes('already registered') || 
            error.message.includes('already exists') ||
            error.message.includes('User already registered')) {
          return {
            success: false,
            error: 'Un compte avec cet email existe déjà. Veuillez vous connecter.',
            message: 'Compte existant'
          };
        }

        if (error.message.includes('Password should be at least')) {
          return {
            success: false,
            error: 'Le mot de passe doit contenir au moins 6 caractères.',
            message: 'Mot de passe trop court'
          };
        }

        return {
          success: false,
          error: error.message || 'Erreur lors de l\'inscription',
          message: 'Erreur d\'inscription'
        };
      }

      // Succès avec la méthode standard
      console.log('✅ Inscription réussie pour:', data.email);
      
      return {
        success: true,
        user: authData.user,
        session: authData.session,
        message: 'Inscription réussie ! Vérifiez votre email pour confirmer votre compte.',
        needsEmailConfirmation: !authData.session // Si pas de session, email confirmation requise
      };

    } catch (error) {
      console.error('💥 Exception lors de l\'inscription:', error);
      return {
        success: false,
        error: 'Erreur inattendue lors de l\'inscription',
        message: 'Erreur système'
      };
    }
  },

  /**
   * Connexion d'un utilisateur
   */
  async signIn(data: SignInData): Promise<AuthResponse> {
    try {
      console.log('🔐 Tentative de connexion pour:', data.email);

      const { data: authData, error } = await supabase.auth.signInWithPassword({
        email: data.email,
        password: data.password
      });

      if (error) {
        console.error('❌ Erreur lors de la connexion:', error);
        
        // Si c'est une erreur de base de données, essayer la méthode bypass
        if (error.message.includes('Database error') || error.message.includes('500')) {
          console.log('🔄 Tentative avec la méthode bypass pour la connexion...');
          
          const { data: bypassData, error: bypassError } = await supabase.rpc('login_user_complete', {
            user_email: data.email,
            user_password: data.password
          });

          if (bypassError) {
            console.error('❌ Erreur avec la méthode bypass de connexion:', bypassError);
            return {
              success: false,
              error: 'Erreur lors de la connexion',
              message: 'Impossible de se connecter'
            };
          }

          if (bypassData?.success) {
            console.log('✅ Connexion réussie avec la méthode bypass pour:', data.email);
            
            // Essayer de récupérer l'utilisateur depuis Supabase Auth
            const { data: { user }, error: getUserError } = await supabase.auth.getUser();
            
            return {
              success: true,
              user: user || {
                id: bypassData.user_id,
                email: bypassData.email,
                user_metadata: {
                  firstName: bypassData.firstName,
                  lastName: bypassData.lastName,
                  role: bypassData.role
                }
              } as any,
              session: null, // Pas de session avec la méthode bypass
              message: 'Connexion réussie !',
              needsSessionRefresh: true
            };
          }
        }
        
        // Gestion des erreurs spécifiques
        if (error.message.includes('Invalid login credentials') ||
            error.message.includes('invalid_credentials')) {
          return {
            success: false,
            error: 'Email ou mot de passe incorrect.',
            message: 'Identifiants invalides'
          };
        }

        if (error.message.includes('Email not confirmed')) {
          return {
            success: false,
            error: 'Veuillez confirmer votre email avant de vous connecter.',
            message: 'Email non confirmé'
          };
        }

        return {
          success: false,
          error: error.message || 'Erreur lors de la connexion',
          message: 'Erreur de connexion'
        };
      }

      // Succès avec la méthode standard
      console.log('✅ Connexion réussie pour:', data.email);
      
      return {
        success: true,
        user: authData.user,
        session: authData.session,
        message: 'Connexion réussie !'
      };

    } catch (error) {
      console.error('💥 Exception lors de la connexion:', error);
      return {
        success: false,
        error: 'Erreur inattendue lors de la connexion',
        message: 'Erreur système'
      };
    }
  },

  /**
   * Déconnexion de l'utilisateur
   */
  async signOut(): Promise<AuthResponse> {
    try {
      console.log('🔐 Déconnexion en cours...');

      const { error } = await supabase.auth.signOut();

      if (error) {
        console.error('❌ Erreur lors de la déconnexion:', error);
        return {
          success: false,
          error: error.message || 'Erreur lors de la déconnexion',
          message: 'Erreur de déconnexion'
        };
      }

      // Nettoyer le localStorage
      localStorage.removeItem('user');
      localStorage.removeItem('session');

      console.log('✅ Déconnexion réussie');
      
      return {
        success: true,
        user: null,
        session: null,
        message: 'Déconnexion réussie'
      };

    } catch (error) {
      console.error('💥 Exception lors de la déconnexion:', error);
      return {
        success: false,
        error: 'Erreur inattendue lors de la déconnexion',
        message: 'Erreur système'
      };
    }
  },

  /**
   * Récupération de l'utilisateur actuel
   */
  async getCurrentUser(): Promise<AuthResponse> {
    try {
      const { data: { user }, error } = await supabase.auth.getUser();

      if (error) {
        console.error('❌ Erreur lors de la récupération de l\'utilisateur:', error);
        return {
          success: false,
          user: null,
          error: error.message || 'Erreur lors de la récupération de l\'utilisateur',
          message: 'Erreur d\'authentification'
        };
      }

      return {
        success: true,
        user,
        message: user ? 'Utilisateur récupéré' : 'Aucun utilisateur connecté'
      };

    } catch (error) {
      console.error('💥 Exception lors de la récupération de l\'utilisateur:', error);
      return {
        success: false,
        user: null,
        error: 'Erreur inattendue',
        message: 'Erreur système'
      };
    }
  },

  /**
   * Récupération de la session actuelle
   */
  async getCurrentSession(): Promise<AuthResponse> {
    try {
      const { data: { session }, error } = await supabase.auth.getSession();

      if (error) {
        console.error('❌ Erreur lors de la récupération de la session:', error);
        return {
          success: false,
          session: null,
          error: error.message || 'Erreur lors de la récupération de la session',
          message: 'Erreur de session'
        };
      }

      return {
        success: true,
        session,
        user: session?.user || null,
        message: session ? 'Session active' : 'Aucune session active'
      };

    } catch (error) {
      console.error('💥 Exception lors de la récupération de la session:', error);
      return {
        success: false,
        session: null,
        error: 'Erreur inattendue',
        message: 'Erreur système'
      };
    }
  },

  /**
   * Envoi d'un email de confirmation
   */
  async resendConfirmation(email: string): Promise<AuthResponse> {
    try {
      console.log('📧 Renvoi d\'email de confirmation pour:', email);

      const { error } = await supabase.auth.resend({
        type: 'signup',
        email
      });

      if (error) {
        console.error('❌ Erreur lors du renvoi d\'email:', error);
        return {
          success: false,
          error: error.message || 'Erreur lors du renvoi d\'email',
          message: 'Erreur d\'envoi'
        };
      }

      console.log('✅ Email de confirmation renvoyé');
      
      return {
        success: true,
        message: 'Email de confirmation renvoyé avec succès'
      };

    } catch (error) {
      console.error('💥 Exception lors du renvoi d\'email:', error);
      return {
        success: false,
        error: 'Erreur inattendue lors du renvoi d\'email',
        message: 'Erreur système'
      };
    }
  },

  /**
   * Réinitialisation de mot de passe
   */
  async resetPassword(email: string): Promise<AuthResponse> {
    try {
      console.log('🔑 Demande de réinitialisation de mot de passe pour:', email);

      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/auth/reset-password`
      });

      if (error) {
        console.error('❌ Erreur lors de la demande de réinitialisation:', error);
        return {
          success: false,
          error: error.message || 'Erreur lors de la demande de réinitialisation',
          message: 'Erreur de réinitialisation'
        };
      }

      console.log('✅ Email de réinitialisation envoyé');
      
      return {
        success: true,
        message: 'Email de réinitialisation envoyé avec succès'
      };

    } catch (error) {
      console.error('💥 Exception lors de la demande de réinitialisation:', error);
      return {
        success: false,
        error: 'Erreur inattendue lors de la demande de réinitialisation',
        message: 'Erreur système'
      };
    }
  },

  /**
   * Mise à jour du mot de passe
   */
  async updatePassword(newPassword: string): Promise<AuthResponse> {
    try {
      console.log('🔑 Mise à jour du mot de passe');

      const { error } = await supabase.auth.updateUser({
        password: newPassword
      });

      if (error) {
        console.error('❌ Erreur lors de la mise à jour du mot de passe:', error);
        return {
          success: false,
          error: error.message || 'Erreur lors de la mise à jour du mot de passe',
          message: 'Erreur de mise à jour'
        };
      }

      console.log('✅ Mot de passe mis à jour avec succès');
      
      return {
        success: true,
        message: 'Mot de passe mis à jour avec succès'
      };

    } catch (error) {
      console.error('💥 Exception lors de la mise à jour du mot de passe:', error);
      return {
        success: false,
        error: 'Erreur inattendue lors de la mise à jour du mot de passe',
        message: 'Erreur système'
      };
    }
  }
};

// Export par défaut
export default authService;
