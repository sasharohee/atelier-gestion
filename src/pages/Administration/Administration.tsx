import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Grid,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Avatar,
  Alert,
  Snackbar,
  CircularProgress,
  Switch,
  FormControlLabel,
  Divider,
  Tooltip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Security as SecurityIcon,
  Settings as SettingsIcon,
  People as PeopleIcon,
  Save as SaveIcon,
  Refresh as RefreshIcon,
  Lock as LockIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { useNavigate } from 'react-router-dom';

const Administration: React.FC = () => {
  const navigate = useNavigate();
  const {
    users,
    systemSettings,
    currentUser,
    addUser,
    updateUser,
    deleteUser,
    loadUsers,
    loadSystemSettings,
    updateSystemSetting,
    updateMultipleSystemSettings,
    loading,
    error,
    setError,
  } = useAppStore();

  // Hook d'authentification
  const { user: authUser, loading: authLoading, isAuthenticated, refreshAuth } = useAuth();

  // États locaux
  const [newUserDialogOpen, setNewUserDialogOpen] = useState(false);
  const [editUserDialogOpen, setEditUserDialogOpen] = useState(false);
  const [deleteUserDialogOpen, setDeleteUserDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
  const [forceRender, setForceRender] = useState(0);
  
  // États des formulaires
  const [newUserForm, setNewUserForm] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    role: 'technician' as 'admin' | 'technician' | 'manager',
  });
  
  const [editUserForm, setEditUserForm] = useState({
    firstName: '',
    lastName: '',
    email: '',
    role: 'technician' as 'admin' | 'technician' | 'manager',
  });

  // Validation
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  
  // État local pour les modifications des paramètres
  const [localSettings, setLocalSettings] = useState<Record<string, string>>({});

  // Fonction pour créer automatiquement l'utilisateur administrateur
  const ensureAdminUserExists = async () => {
    console.log('🚀 Début de ensureAdminUserExists');
    console.log('👤 Utilisateur actuel (store):', currentUser);
    console.log('👤 Utilisateur authentifié (auth):', authUser);
    console.log('🔐 Authentifié:', isAuthenticated);
    console.log('⏳ Chargement auth:', authLoading);
    
    // Attendre que l'authentification soit chargée
    if (authLoading) {
      console.log('⏳ En attente du chargement de l\'authentification...');
      setSnackbar({ 
        open: true, 
        message: 'Chargement de l\'authentification...', 
        severity: 'success' 
      });
      return;
    }
    
    // Utiliser l'utilisateur authentifié ou l'utilisateur du store
    const userToUse = authUser || currentUser;
    
    if (!userToUse || !isAuthenticated) {
      console.log('❌ Aucun utilisateur connecté');
      setSnackbar({ 
        open: true, 
        message: 'Aucun utilisateur connecté. Veuillez vous connecter d\'abord.', 
        severity: 'error' 
      });
      return;
    }

    try {
      console.log('🔍 Vérification et création de l\'utilisateur administrateur...');
      console.log('📧 Email:', userToUse.email);
      console.log('👤 Prénom:', (userToUse as any).firstName || (userToUse as any).user_metadata?.firstName);
      console.log('👤 Nom:', (userToUse as any).lastName || (userToUse as any).user_metadata?.lastName);
      
              // Essayer d'abord la fonction simplifiée
        console.log('📞 Appel de la fonction RPC create_simple_admin_user...');
        let { data, error } = await supabase.rpc('create_simple_admin_user', {
          p_email: userToUse.email
        });

        // Si la fonction simplifiée n'existe pas, essayer la fonction complète
        if (error && error.message.includes('function') && error.message.includes('does not exist')) {
          console.log('⚠️ Fonction simplifiée non disponible, essai avec la fonction complète...');
          const result = await supabase.rpc('create_admin_user_auto', {
            p_email: userToUse.email,
            p_first_name: (userToUse as any).firstName || (userToUse as any).user_metadata?.firstName || null,
            p_last_name: (userToUse as any).lastName || (userToUse as any).user_metadata?.lastName || null
          });
          data = result.data;
          error = result.error;
        }

      console.log('📊 Réponse RPC:', { data, error });

      if (error) {
        console.error('❌ Erreur lors de l\'appel RPC:', error);
        
        // Fallback vers l'ancienne méthode si la fonction RPC n'existe pas
        console.log('⚠️ Fonction RPC non disponible, utilisation de la méthode de fallback...');
        await ensureAdminUserExistsFallback();
        return;
      }

      if (data && data.success) {
        console.log('✅ Utilisateur administrateur géré avec succès:', data);
        setSnackbar({ 
          open: true, 
          message: data.message || 'Compte administrateur configuré avec succès !', 
          severity: 'success' 
        });
        
        // Recharger la liste des utilisateurs
        console.log('🔄 Rechargement de la liste des utilisateurs...');
        await loadUsers();
      } else {
        console.error('❌ Erreur lors de la création:', data?.message);
        setSnackbar({ 
          open: true, 
          message: data?.message || 'Erreur lors de la création du compte administrateur', 
          severity: 'error' 
        });
      }

    } catch (error) {
      console.error('❌ Erreur lors de la création de l\'utilisateur administrateur:', error);
      setSnackbar({ 
        open: true, 
        message: `Erreur lors de la création du compte administrateur: ${error}`, 
        severity: 'error' 
      });
    }
  };

  // Méthode de fallback si la fonction RPC n'existe pas
  const ensureAdminUserExistsFallback = async () => {
    try {
      console.log('🔄 Utilisation de la méthode de fallback...');
      
      const userToUse = authUser || currentUser;
      if (!userToUse) {
        console.log('❌ Aucun utilisateur disponible pour le fallback');
        return;
      }
      
      // Vérifier si l'utilisateur existe déjà dans la table users
      const { data: existingUser, error: checkError } = await supabase
        .from('users')
        .select('*')
        .eq('email', userToUse.email)
        .single();

      if (checkError && checkError.code !== 'PGRST116') {
        console.error('❌ Erreur lors de la vérification:', checkError);
        return;
      }

      if (existingUser) {
        console.log('✅ Utilisateur administrateur existe déjà:', existingUser);
        
        // Vérifier si le rôle est bien 'admin', sinon le mettre à jour
        if (existingUser.role !== 'admin') {
          console.log('🔄 Mise à jour du rôle vers administrateur...');
          await updateUser(existingUser.id, { role: 'admin' });
          setSnackbar({ 
            open: true, 
            message: 'Votre compte a été promu administrateur avec succès', 
            severity: 'success' 
          });
        }
        return;
      }

      // L'utilisateur n'existe pas, le créer avec le rôle d'administrateur
      console.log('🆕 Création de l\'utilisateur administrateur...');
      
      // Extraire le prénom et nom de l'email si pas disponibles
      let firstName = (userToUse as any).firstName || (userToUse as any).user_metadata?.firstName;
      let lastName = (userToUse as any).lastName || (userToUse as any).user_metadata?.lastName;
      
      if (!firstName || !lastName) {
        const emailParts = userToUse.email?.split('@')[0] || '';
        const nameParts = emailParts.split('.');
        if (nameParts.length >= 2) {
          firstName = nameParts[0].charAt(0).toUpperCase() + nameParts[0].slice(1);
          lastName = nameParts[1].charAt(0).toUpperCase() + nameParts[1].slice(1);
        } else {
          firstName = emailParts.charAt(0).toUpperCase() + emailParts.slice(1);
          lastName = 'Administrateur';
        }
      }

      // Créer l'utilisateur avec le rôle d'administrateur
      await addUser({
        firstName: firstName || 'Utilisateur',
        lastName: lastName || 'Administrateur',
        email: userToUse.email || '',
        role: 'admin',
        password: 'admin123', // Mot de passe temporaire
      });

      setSnackbar({ 
        open: true, 
        message: 'Compte administrateur créé avec succès ! Vous pouvez maintenant gérer les utilisateurs.', 
        severity: 'success' 
      });

      // Recharger la liste des utilisateurs
      await loadUsers();

    } catch (error) {
      console.error('❌ Erreur lors de la création de l\'utilisateur administrateur (fallback):', error);
      setSnackbar({ 
        open: true, 
        message: 'Erreur lors de la création du compte administrateur', 
        severity: 'error' 
      });
    }
  };

  // Charger les utilisateurs et paramètres système au montage
  useEffect(() => {
    // Charger les paramètres système d'abord
    loadSystemSettings();
    
    // Charger les utilisateurs avec gestion d'erreur
    const loadUsersSafely = async () => {
      try {
        await loadUsers();
      } catch (error) {
        console.error('Erreur lors du chargement des utilisateurs:', error);
        // Ne pas bloquer l'interface si les utilisateurs ne peuvent pas être chargés
      }
    };
    
    loadUsersSafely();
    
    // Rendre automatiquement l'utilisateur connecté administrateur
    const makeUserAdmin = async () => {
      if (isAuthenticated && authUser && !authLoading) {
        console.log('🔄 Promotion automatique en administrateur...');
        try {
          // Utiliser la fonction RPC pour promouvoir l'utilisateur
          const { data, error } = await supabase.rpc('create_simple_admin_user', {
            p_email: authUser.email
          });

          if (error && error.message.includes('function') && error.message.includes('does not exist')) {
            console.log('⚠️ Fonction RPC non disponible, utilisation de la méthode de fallback...');
            await ensureAdminUserExistsFallback();
          } else if (data && data.success) {
            console.log('✅ Utilisateur promu administrateur avec succès:', data);
            setSnackbar({ 
              open: true, 
              message: 'Vous avez été automatiquement promu administrateur !', 
              severity: 'success' 
            });
            // Recharger la liste des utilisateurs
            await loadUsers();
          }
        } catch (error) {
          console.error('❌ Erreur lors de la promotion automatique:', error);
        }
      }
    };
    
    // Attendre que l'authentification soit chargée puis promouvoir
    const adminTimer = setTimeout(() => {
      makeUserAdmin();
    }, 1500);
    
    return () => {
      clearTimeout(adminTimer);
    };
  }, [isAuthenticated, authUser, authLoading]); // Suppression de systemSettings.length pour éviter la boucle infinie

  // Effet pour forcer le rechargement de l'authentification si nécessaire
  useEffect(() => {
    // Si on a des utilisateurs mais pas d'authentification, forcer le rechargement
    if (users.length > 0 && !isAuthenticated && !authLoading) {
      console.log('🔄 Détection d\'incohérence: utilisateurs présents mais pas d\'authentification');
      const timer = setTimeout(() => {
        refreshAuth();
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [users.length, isAuthenticated, authLoading, refreshAuth]);

  // Effet pour forcer le rechargement immédiat au chargement de la page
  useEffect(() => {
    // Forcer le rechargement de l'authentification au chargement de la page
    const timer = setTimeout(() => {
      if (!isAuthenticated && !authLoading) {
        console.log('🔄 Rechargement automatique de l\'authentification au chargement de la page');
        refreshAuth().then(() => {
          // Forcer un re-render après le rechargement
          setForceRender(prev => prev + 1);
        });
      }
    }, 500);
    
    return () => clearTimeout(timer);
  }, []); // Exécuté une seule fois au montage

  // Effet pour forcer le re-render quand l'authentification change
  useEffect(() => {
    console.log('🔄 État d\'authentification mis à jour:', { isAuthenticated, authUser: authUser?.email });
    setForceRender(prev => prev + 1);
  }, [isAuthenticated, authUser]);

  // Validation du formulaire
  const validateForm = (form: any, isEdit = false) => {
    const errors: Record<string, string> = {};
    
    if (!form.firstName.trim()) {
      errors.firstName = 'Le prénom est requis';
    }
    
    if (!form.lastName.trim()) {
      errors.lastName = 'Le nom est requis';
    }
    
    if (!form.email.trim()) {
      errors.email = 'L\'email est requis';
    } else if (!/\S+@\S+\.\S+/.test(form.email)) {
      errors.email = 'L\'email n\'est pas valide';
    }
    
    if (!isEdit && !form.password.trim()) {
      errors.password = 'Le mot de passe est requis';
    } else if (!isEdit && form.password.length < 6) {
      errors.password = 'Le mot de passe doit contenir au moins 6 caractères';
    }
    
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  // Gestionnaires d'événements
  const handleCreateUser = async () => {
    if (!validateForm(newUserForm)) return;
    
    try {
      await addUser(newUserForm);
      setSnackbar({ open: true, message: 'Utilisateur créé avec succès', severity: 'success' });
      setNewUserDialogOpen(false);
      setNewUserForm({
        firstName: '',
        lastName: '',
        email: '',
        password: '',
        role: 'technician',
      });
    } catch (error: any) {
      // Gestion spécifique des erreurs
      let errorMessage = 'Erreur lors de la création';
      
      if (error.message) {
        errorMessage = error.message;
      } else if (error.code === '23505') {
        errorMessage = 'Cet email est déjà utilisé par un autre utilisateur.';
      } else if (error.code === 'EMAIL_EXISTS') {
        errorMessage = error.message;
      }
      
      setSnackbar({ open: true, message: errorMessage, severity: 'error' });
    }
  };

  const handleEditUser = async () => {
    if (!validateForm(editUserForm, true)) return;
    
    try {
      // Si c'est l'utilisateur connecté, mettre à jour les métadonnées Supabase
      if (selectedUser.id === authUser?.id) {
        console.log('🔄 Mise à jour de l\'utilisateur connecté...');
        
        // Mettre à jour les métadonnées utilisateur dans Supabase Auth
        const { error: updateError } = await supabase.auth.updateUser({
          data: {
            firstName: editUserForm.firstName,
            lastName: editUserForm.lastName,
            role: editUserForm.role
          }
        });
        
        if (updateError) {
          throw new Error(`Erreur lors de la mise à jour des métadonnées: ${updateError.message}`);
        }
        
        // Mettre à jour aussi dans la table users si l'utilisateur existe
        try {
          await updateUser(selectedUser.id, editUserForm);
        } catch (tableError) {
          console.log('⚠️ Utilisateur non trouvé dans la table, création...');
          // Créer l'utilisateur dans la table si il n'existe pas
          await addUser({
            firstName: editUserForm.firstName,
            lastName: editUserForm.lastName,
            email: editUserForm.email,
            role: editUserForm.role,
            password: 'temp_password' // Mot de passe temporaire
          });
        }
        
        setSnackbar({ 
          open: true, 
          message: 'Vos informations ont été mises à jour avec succès', 
          severity: 'success' 
        });
      } else {
        // Mise à jour normale pour les autres utilisateurs
        await updateUser(selectedUser.id, editUserForm);
        setSnackbar({ open: true, message: 'Utilisateur modifié avec succès', severity: 'success' });
      }
      
      setEditUserDialogOpen(false);
      setSelectedUser(null);
      
      // Recharger les utilisateurs pour mettre à jour l'affichage
      await loadUsers();
      
    } catch (error: any) {
      setSnackbar({ open: true, message: error.message || 'Erreur lors de la modification', severity: 'error' });
    }
  };

  const handleDeleteUser = async () => {
    try {
      await deleteUser(selectedUser.id);
      setSnackbar({ open: true, message: 'Utilisateur supprimé avec succès', severity: 'success' });
      setDeleteUserDialogOpen(false);
      setSelectedUser(null);
    } catch (error: any) {
      setSnackbar({ open: true, message: error.message || 'Erreur lors de la suppression', severity: 'error' });
    }
  };

  const handleSaveSettings = async (category: string) => {
    try {
      console.log('💾 Sauvegarde des paramètres pour la catégorie:', category);
      console.log('📊 Paramètres système chargés:', systemSettings.length);
      console.log('🔧 Modifications locales:', localSettings);

      // Si les paramètres ne sont pas encore chargés, afficher un message
      if (systemSettings.length === 0) {
        setSnackbar({ open: true, message: 'Aucun paramètre à sauvegarder. Veuillez d\'abord exécuter le script de correction.', severity: 'error' });
        return;
      }

      // Récupérer tous les paramètres de la catégorie avec leurs valeurs actuelles
      const settingsToUpdate = systemSettings
        .filter(setting => setting.category === category)
        .map(setting => ({ 
          key: setting.key, 
          value: localSettings[setting.key] !== undefined ? localSettings[setting.key] : setting.value
        }));

      console.log('📝 Paramètres à mettre à jour:', settingsToUpdate);

      if (settingsToUpdate.length > 0) {
        await updateMultipleSystemSettings(settingsToUpdate);
        // Vider les modifications locales pour cette catégorie
        const newLocalSettings = { ...localSettings };
        settingsToUpdate.forEach(setting => {
          delete newLocalSettings[setting.key];
        });
        setLocalSettings(newLocalSettings);
        setSnackbar({ open: true, message: 'Paramètres sauvegardés avec succès', severity: 'success' });
      } else {
        setSnackbar({ open: true, message: 'Aucun paramètre à sauvegarder', severity: 'success' });
      }
    } catch (error: any) {
      console.error('❌ Erreur lors de la sauvegarde:', error);
      setSnackbar({ open: true, message: error.message || 'Erreur lors de la sauvegarde', severity: 'error' });
    }
  };

  const openEditDialog = (user: any) => {
    setSelectedUser(user);
    setEditUserForm({
      firstName: user.firstName || '',
      lastName: user.lastName || '',
      email: user.email || '',
      role: user.role || 'technician',
    });
    setEditUserDialogOpen(true);
  };

  const openDeleteDialog = (user: any) => {
    setSelectedUser(user);
    setDeleteUserDialogOpen(true);
  };

  const getRoleLabel = (role: string) => {
    const labels = {
      admin: 'Administrateur',
      manager: 'Gérant',
      technician: 'Technicien',
    };
    return labels[role as keyof typeof labels] || role;
  };

  const getRoleColor = (role: string) => {
    const colors = {
      admin: 'error',
      manager: 'warning',
      technician: 'info',
    };
    return colors[role as keyof typeof colors] || 'default';
  };

  // Fonctions utilitaires pour les paramètres système
  const getSettingValue = (key: string, defaultValue: string = '') => {
    // Vérifier d'abord l'état local (modifications non sauvegardées)
    if (localSettings[key] !== undefined) {
      return localSettings[key];
    }
    // Sinon, utiliser la valeur du store
    const setting = systemSettings.find(s => s.key === key);
    return setting?.value || defaultValue;
  };

  // Vérifier si les paramètres sont chargés
  const isSettingsLoaded = systemSettings.length > 0;

  const updateLocalSetting = (key: string, value: string) => {
    // Mettre à jour l'état local
    setLocalSettings(prev => ({ ...prev, [key]: value }));
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Administration
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gestion des utilisateurs et paramètres système
        </Typography>
        
        {/* Informations de l'utilisateur connecté */}
        {isAuthenticated && authUser && (
          <Box sx={{ mt: 2, p: 2, bgcolor: 'background.paper', borderRadius: 1, border: 1, borderColor: 'divider' }}>
            <Typography variant="h6" gutterBottom sx={{ fontWeight: 600, color: 'primary.main' }}>
              👤 Utilisateur connecté
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  <strong>Email :</strong> {authUser.email}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  <strong>ID :</strong> {authUser.id}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  <strong>Rôle :</strong> {(authUser as any).user_metadata?.role || 'Non défini'}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  <strong>Connecté depuis :</strong> {new Date(authUser.created_at).toLocaleDateString('fr-FR')}
                </Typography>
              </Grid>
            </Grid>
          </Box>
        )}
        
        {/* Informations de l'utilisateur depuis le store (si différent) */}
        {currentUser && currentUser.id !== authUser?.id && (
          <Box sx={{ mt: 2, p: 2, bgcolor: 'background.paper', borderRadius: 1, border: 1, borderColor: 'warning.main' }}>
            <Typography variant="h6" gutterBottom sx={{ fontWeight: 600, color: 'warning.main' }}>
              ⚠️ Utilisateur du store (différent de l'authentification)
            </Typography>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  <strong>Email :</strong> {currentUser.email}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  <strong>ID :</strong> {currentUser.id}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  <strong>Prénom :</strong> {currentUser.firstName || 'Non défini'}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  <strong>Nom :</strong> {currentUser.lastName || 'Non défini'}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  <strong>Rôle :</strong> {currentUser.role}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="body2" color="text.secondary">
                  <strong>Créé le :</strong> {new Date(currentUser.createdAt).toLocaleDateString('fr-FR')}
                </Typography>
              </Grid>
            </Grid>
          </Box>
        )}
        
        {/* État de connexion */}
        {authLoading && (
          <Box sx={{ mt: 2, p: 2, bgcolor: 'info.light', borderRadius: 1 }}>
            <Typography variant="body2" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <CircularProgress size={16} />
              Chargement des informations utilisateur...
            </Typography>
          </Box>
        )}
        
        {!isAuthenticated && !authLoading && (
          <Box sx={{ mt: 2, p: 2, bgcolor: 'warning.light', borderRadius: 1 }}>
            <Typography variant="body2" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              ⚠️ Aucun utilisateur connecté
            </Typography>
          </Box>
        )}
        
      </Box>

      {/* Bannière d'avertissement */}
      <Alert 
        severity="warning" 
        sx={{ mb: 3 }}
        action={
          <Button 
            color="inherit" 
            size="small"
            onClick={() => {
              // Navigation vers la page Réglages
              window.location.href = '/settings';
            }}
          >
            Aller aux Réglages
          </Button>
        }
      >
        <Typography variant="body2" sx={{ fontWeight: 500 }}>
          ⚠️ Important : Pour que la page Administration fonctionne parfaitement, 
          veuillez d'abord configurer les paramètres dans la page Réglages.
        </Typography>
        <Typography variant="body2" sx={{ mt: 0.5 }}>
          Cela garantit que tous les paramètres système sont correctement initialisés.
        </Typography>
      </Alert>

      {/* Bannière d'information pour la création automatique d'administrateur */}
      {isAuthenticated && authUser && (
        <Alert 
          severity="info" 
          sx={{ mb: 3 }}
          action={
            <Button 
              color="inherit" 
              size="small"
              onClick={ensureAdminUserExists}
              disabled={loading || authLoading}
            >
              Créer maintenant
            </Button>
          }
        >
          <Typography variant="body2" sx={{ fontWeight: 500 }}>
            ℹ️ Bienvenue dans l'Administration ! 
          </Typography>
          <Typography variant="body2" sx={{ mt: 0.5 }}>
            Vous avez été automatiquement promu administrateur ! Votre email ({authUser.email}) 
            a maintenant les privilèges d'administration. Vous pouvez modifier vos informations en utilisant le bouton d'édition.
          </Typography>
        </Alert>
      )}

      {/* Bannière d'avertissement si non connecté */}
      {!isAuthenticated && !authLoading && (
        <Alert 
          severity="warning" 
          sx={{ mb: 3 }}
          action={
            <Button 
              color="inherit" 
              size="small"
              onClick={() => {
                // Navigation vers la page d'authentification
                window.location.href = '/auth';
              }}
            >
              Se connecter
            </Button>
          }
        >
          <Typography variant="body2" sx={{ fontWeight: 500 }}>
            ⚠️ Vous devez être connecté pour accéder à l'Administration
          </Typography>
          <Typography variant="body2" sx={{ mt: 0.5 }}>
            Veuillez vous connecter pour pouvoir créer votre compte administrateur et gérer les utilisateurs.
          </Typography>
        </Alert>
      )}

      {/* Actions */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setNewUserDialogOpen(true)}
        >
          Nouvel utilisateur
        </Button>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={loadUsers}
          disabled={loading}
        >
          Actualiser
        </Button>
        <Button
          variant="outlined"
          color="primary"
          onClick={ensureAdminUserExists}
          disabled={loading || authLoading || !isAuthenticated}
        >
          {authLoading ? 'Chargement...' : !isAuthenticated ? 'Connectez-vous d\'abord' : 'Promouvoir en admin'}
        </Button>
        <Button
          variant="outlined"
          color="secondary"
          onClick={async () => {
            console.log('🔄 Synchronisation des données utilisateur...');
            try {
              // Recharger les données utilisateur depuis le store
              await loadUsers();
              setSnackbar({ 
                open: true, 
                message: 'Données utilisateur synchronisées', 
                severity: 'success' 
              });
            } catch (error) {
              console.error('❌ Erreur lors de la synchronisation:', error);
              setSnackbar({ 
                open: true, 
                message: 'Erreur lors de la synchronisation', 
                severity: 'error' 
              });
            }
          }}
          disabled={loading}
        >
          Synchroniser données
        </Button>
      </Box>

      {/* Statistiques rapides */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <PeopleIcon sx={{ mr: 2, color: 'primary.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Total utilisateurs
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {(() => {
                      const totalUsers = users.length;
                      const connectedUserIncluded = isAuthenticated && authUser && !users.some(user => user.id === authUser.id);
                      return totalUsers + (connectedUserIncluded ? 1 : 0);
                    })()}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <SecurityIcon sx={{ mr: 2, color: 'warning.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Administrateurs
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {(() => {
                      const adminUsers = users.filter(u => u.role === 'admin').length;
                      const connectedUserIsAdmin = isAuthenticated && authUser && 
                        ((authUser as any).user_metadata?.role === 'admin') && 
                        !users.some(user => user.id === authUser.id);
                      return adminUsers + (connectedUserIsAdmin ? 1 : 0);
                    })()}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <SettingsIcon sx={{ mr: 2, color: 'info.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Techniciens
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {(() => {
                      const technicianUsers = users.filter(u => u.role === 'technician').length;
                      const connectedUserIsTechnician = isAuthenticated && authUser && 
                        ((authUser as any).user_metadata?.role === 'technician') && 
                        !users.some(user => user.id === authUser.id);
                      return technicianUsers + (connectedUserIsTechnician ? 1 : 0);
                    })()}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <PeopleIcon sx={{ mr: 2, color: 'success.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Gérants
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {(() => {
                      const managerUsers = users.filter(u => u.role === 'manager').length;
                      const connectedUserIsManager = isAuthenticated && authUser && 
                        ((authUser as any).user_metadata?.role === 'manager') && 
                        !users.some(user => user.id === authUser.id);
                      return managerUsers + (connectedUserIsManager ? 1 : 0);
                    })()}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Liste des utilisateurs */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
            <Typography variant="h6">
              Gestion des utilisateurs
            </Typography>
            {loading && <CircularProgress size={20} />}
          </Box>
          
          {error && (
            <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
              {error}
            </Alert>
          )}
          
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Utilisateur</TableCell>
                  <TableCell>Email</TableCell>
                  <TableCell>Rôle</TableCell>
                  <TableCell>Date de création</TableCell>
                  <TableCell align="center">Actions</TableCell>
                </TableRow>
              </TableHead>
                            <TableBody>
                {/* Créer une liste combinée des utilisateurs du store et de l'utilisateur connecté */}
                {(() => {
                  const allUsers = [...users];
                  
                  // Ajouter l'utilisateur connecté s'il n'est pas déjà dans la liste
                  if (isAuthenticated && authUser) {
                    const userExists = allUsers.some(user => user.id === authUser.id);
                    if (!userExists) {
                      const connectedUser = {
                        id: authUser.id,
                        firstName: (authUser as any).user_metadata?.firstName || authUser.email?.split('@')[0] || 'Utilisateur',
                        lastName: (authUser as any).user_metadata?.lastName || 'Connecté',
                        email: authUser.email || '',
                        role: (authUser as any).user_metadata?.role || 'technician',
                        avatar: (authUser as any).user_metadata?.avatar,
                        createdAt: new Date(authUser.created_at),
                        updatedAt: new Date(authUser.updated_at || authUser.created_at)
                      };
                      allUsers.unshift(connectedUser); // Ajouter en premier
                    }
                  }
                  
                  return allUsers.map((user) => (
                    <TableRow key={user.id}>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <Avatar src={user.avatar} sx={{ mr: 2 }}>
                            {user.firstName?.charAt(0) || user.email?.charAt(0) || 'U'}
                          </Avatar>
                          <Box>
                            <Typography variant="body2" sx={{ fontWeight: 600 }}>
                              {`${user.firstName || ''} ${user.lastName || ''}`.trim() || user.email || 'Utilisateur'}
                            </Typography>
                            {(user.id === currentUser?.id || user.id === authUser?.id) && (
                              <Chip label="Vous" size="small" color="primary" />
                            )}
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell>{user.email}</TableCell>
                      <TableCell>
                        <Chip
                          label={getRoleLabel(user.role)}
                          color={getRoleColor(user.role) as any}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        {new Date(user.createdAt).toLocaleDateString('fr-FR')}
                      </TableCell>
                      <TableCell align="center">
                        <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center' }}>
                          <Tooltip title="Modifier">
                            <IconButton 
                              size="small" 
                              onClick={() => openEditDialog(user)}
                            >
                              <EditIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                          {user.id !== authUser?.id && (
                            <Tooltip title="Supprimer">
                              <IconButton 
                                size="small" 
                                color="error"
                                onClick={() => openDeleteDialog(user)}
                              >
                                <DeleteIcon fontSize="small" />
                              </IconButton>
                            </Tooltip>
                          )}
                        </Box>
                      </TableCell>
                    </TableRow>
                  ));
                })()}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Paramètres système */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6">
                  Paramètres généraux
                  {!isSettingsLoaded && (
                    <Chip 
                      label="Non chargés" 
                      size="small" 
                      color="warning" 
                      sx={{ ml: 1 }}
                    />
                  )}
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  {!isSettingsLoaded && <CircularProgress size={16} />}
                  <Button
                    variant="contained"
                    size="small"
                    startIcon={<SaveIcon />}
                    onClick={() => handleSaveSettings('general')}
                    disabled={!isSettingsLoaded}
                  >
                    Sauvegarder
                  </Button>
                </Box>
              </Box>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField
                  fullWidth
                  label="Nom de l'atelier"
                  value={getSettingValue('workshop_name', 'Atelier de réparation')}
                  onChange={(e) => updateLocalSetting('workshop_name', e.target.value)}
                />
                <TextField
                  fullWidth
                  label="Adresse"
                  multiline
                  rows={2}
                  value={getSettingValue('workshop_address', '123 Rue de la Paix, 75001 Paris')}
                  onChange={(e) => updateLocalSetting('workshop_address', e.target.value)}
                />
                <TextField
                  fullWidth
                  label="Téléphone"
                  value={getSettingValue('workshop_phone', '07 59 23 91 70')}
                  onChange={(e) => updateLocalSetting('workshop_phone', e.target.value)}
                />
                <TextField
                  fullWidth
                  label="Email"
                  value={getSettingValue('workshop_email', 'contact.ateliergestion@gmail.com')}
                  onChange={(e) => updateLocalSetting('workshop_email', e.target.value)}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6">
                  Paramètres de facturation
                  {!isSettingsLoaded && (
                    <Chip 
                      label="Non chargés" 
                      size="small" 
                      color="warning" 
                      sx={{ ml: 1 }}
                    />
                  )}
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  {!isSettingsLoaded && <CircularProgress size={16} />}
                  <Button
                    variant="contained"
                    size="small"
                    startIcon={<SaveIcon />}
                    onClick={() => handleSaveSettings('billing')}
                    disabled={!isSettingsLoaded}
                  >
                    Sauvegarder
                  </Button>
                </Box>
              </Box>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField
                  fullWidth
                  label="TVA (%)"
                  type="number"
                  value={getSettingValue('vat_rate', '20')}
                  onChange={(e) => updateLocalSetting('vat_rate', e.target.value)}
                />
                <FormControl fullWidth>
                  <InputLabel>Devise</InputLabel>
                  <Select 
                    value={getSettingValue('currency', 'EUR')} 
                    label="Devise"
                    onChange={(e) => updateLocalSetting('currency', e.target.value)}
                  >
                    <MenuItem value="EUR">EUR (€)</MenuItem>
                    <MenuItem value="USD">USD ($)</MenuItem>
                    <MenuItem value="GBP">GBP (£)</MenuItem>
                    <MenuItem value="CHF">CHF (CHF)</MenuItem>
                  </Select>
                </FormControl>
                <TextField
                  fullWidth
                  label="Préfixe facture"
                  value={getSettingValue('invoice_prefix', 'FACT-')}
                  onChange={(e) => updateLocalSetting('invoice_prefix', e.target.value)}
                />
                <FormControl fullWidth>
                  <InputLabel>Format de date</InputLabel>
                  <Select 
                    value={getSettingValue('date_format', 'dd/MM/yyyy')} 
                    label="Format de date"
                    onChange={(e) => updateLocalSetting('date_format', e.target.value)}
                  >
                    <MenuItem value="dd/MM/yyyy">dd/MM/yyyy</MenuItem>
                    <MenuItem value="MM/dd/yyyy">MM/dd/yyyy</MenuItem>
                    <MenuItem value="yyyy-MM-dd">yyyy-MM-dd</MenuItem>
                  </Select>
                </FormControl>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6">
                  Paramètres système
                  {!isSettingsLoaded && (
                    <Chip 
                      label="Non chargés" 
                      size="small" 
                      color="warning" 
                      sx={{ ml: 1 }}
                    />
                  )}
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  {!isSettingsLoaded && <CircularProgress size={16} />}
                  <Button
                    variant="contained"
                    size="small"
                    startIcon={<SaveIcon />}
                    onClick={() => handleSaveSettings('system')}
                    disabled={!isSettingsLoaded}
                  >
                    Sauvegarder
                  </Button>
                </Box>
              </Box>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={getSettingValue('auto_backup', 'true') === 'true'}
                        onChange={(e) => updateLocalSetting('auto_backup', e.target.checked.toString())}
                      />
                    }
                    label="Sauvegarde automatique"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={getSettingValue('notifications', 'true') === 'true'}
                        onChange={(e) => updateLocalSetting('notifications', e.target.checked.toString())}
                      />
                    }
                    label="Notifications"
                  />
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Dialog nouvel utilisateur */}
      <Dialog open={newUserDialogOpen} onClose={() => setNewUserDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nouvel utilisateur</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Prénom"
                value={newUserForm.firstName}
                onChange={(e) => setNewUserForm({ ...newUserForm, firstName: e.target.value })}
                error={!!formErrors.firstName}
                helperText={formErrors.firstName}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Nom"
                value={newUserForm.lastName}
                onChange={(e) => setNewUserForm({ ...newUserForm, lastName: e.target.value })}
                error={!!formErrors.lastName}
                helperText={formErrors.lastName}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={newUserForm.email}
                onChange={(e) => setNewUserForm({ ...newUserForm, email: e.target.value })}
                error={!!formErrors.email}
                helperText={formErrors.email}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Mot de passe"
                type="password"
                value={newUserForm.password}
                onChange={(e) => setNewUserForm({ ...newUserForm, password: e.target.value })}
                error={!!formErrors.password}
                helperText={formErrors.password}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Rôle</InputLabel>
                <Select 
                  value={newUserForm.role} 
                  label="Rôle"
                  onChange={(e) => setNewUserForm({ ...newUserForm, role: e.target.value as any })}
                >
                  <MenuItem value="admin">Administrateur</MenuItem>
                  <MenuItem value="manager">Gérant</MenuItem>
                  <MenuItem value="technician">Technicien</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewUserDialogOpen(false)}>Annuler</Button>
          <Button variant="contained" onClick={handleCreateUser} disabled={loading}>
            {loading ? <CircularProgress size={20} /> : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog modification utilisateur */}
      <Dialog open={editUserDialogOpen} onClose={() => setEditUserDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Modifier l'utilisateur</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Prénom"
                value={editUserForm.firstName}
                onChange={(e) => setEditUserForm({ ...editUserForm, firstName: e.target.value })}
                error={!!formErrors.firstName}
                helperText={formErrors.firstName}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Nom"
                value={editUserForm.lastName}
                onChange={(e) => setEditUserForm({ ...editUserForm, lastName: e.target.value })}
                error={!!formErrors.lastName}
                helperText={formErrors.lastName}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={editUserForm.email}
                onChange={(e) => setEditUserForm({ ...editUserForm, email: e.target.value })}
                error={!!formErrors.email}
                helperText={formErrors.email}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Rôle</InputLabel>
                <Select 
                  value={editUserForm.role} 
                  label="Rôle"
                  onChange={(e) => setEditUserForm({ ...editUserForm, role: e.target.value as any })}
                >
                  <MenuItem value="admin">Administrateur</MenuItem>
                  <MenuItem value="manager">Gérant</MenuItem>
                  <MenuItem value="technician">Technicien</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditUserDialogOpen(false)}>Annuler</Button>
          <Button variant="contained" onClick={handleEditUser} disabled={loading}>
            {loading ? <CircularProgress size={20} /> : 'Modifier'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog confirmation suppression */}
      <Dialog open={deleteUserDialogOpen} onClose={() => setDeleteUserDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Confirmer la suppression</DialogTitle>
        <DialogContent>
          <Typography>
            Êtes-vous sûr de vouloir supprimer l'utilisateur{' '}
            <strong>{selectedUser?.firstName || ''} {selectedUser?.lastName || ''}</strong> ?
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
            Cette action est irréversible.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteUserDialogOpen(false)}>Annuler</Button>
          <Button variant="contained" color="error" onClick={handleDeleteUser} disabled={loading}>
            {loading ? <CircularProgress size={20} /> : 'Supprimer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar pour les notifications */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Administration;
