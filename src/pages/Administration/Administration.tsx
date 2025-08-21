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
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { supabase } from '../../lib/supabase';

const Administration: React.FC = () => {
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

  // États locaux
  const [newUserDialogOpen, setNewUserDialogOpen] = useState(false);
  const [editUserDialogOpen, setEditUserDialogOpen] = useState(false);
  const [deleteUserDialogOpen, setDeleteUserDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
  
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
    
    // Forcer le rechargement des paramètres après 2 secondes si pas encore chargés
    const timer = setTimeout(() => {
      if (systemSettings.length === 0) {
        console.log('⏰ Timeout - Forcer le rechargement des paramètres');
        loadSystemSettings();
      }
    }, 2000);
    
    return () => clearTimeout(timer);
  }, [loadUsers, loadSystemSettings, systemSettings.length]);

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
      setSnackbar({ open: true, message: error.message || 'Erreur lors de la création', severity: 'error' });
    }
  };

  const handleEditUser = async () => {
    if (!validateForm(editUserForm, true)) return;
    
    try {
      await updateUser(selectedUser.id, editUserForm);
      setSnackbar({ open: true, message: 'Utilisateur modifié avec succès', severity: 'success' });
      setEditUserDialogOpen(false);
      setSelectedUser(null);
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
        setSnackbar({ open: true, message: 'Aucun paramètre à sauvegarder', severity: 'info' });
      }
    } catch (error: any) {
      console.error('❌ Erreur lors de la sauvegarde:', error);
      setSnackbar({ open: true, message: error.message || 'Erreur lors de la sauvegarde', severity: 'error' });
    }
  };

  const openEditDialog = (user: any) => {
    setSelectedUser(user);
    setEditUserForm({
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      role: user.role,
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
      </Box>

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
          startIcon={<RefreshIcon />}
          onClick={loadSystemSettings}
          disabled={loading}
        >
          Recharger paramètres
        </Button>
        <Button
          variant="outlined"
          onClick={async () => {
            console.log('🧪 Test de connexion Supabase...');
            try {
              const { data, error } = await supabase.from('system_settings').select('count');
              console.log('📊 Test direct Supabase:', { data, error });
              if (error) {
                setSnackbar({ open: true, message: `Erreur: ${error.message}`, severity: 'error' });
              } else {
                setSnackbar({ open: true, message: `Connexion OK: ${data?.length || 0} paramètres`, severity: 'success' });
              }
            } catch (err) {
              console.error('💥 Erreur test:', err);
              setSnackbar({ open: true, message: `Erreur: ${err}`, severity: 'error' });
            }
          }}
        >
          Test connexion
        </Button>
        <Button
          variant="contained"
          color="secondary"
          onClick={() => {
            console.log('🔄 Rechargement forcé des paramètres');
            loadSystemSettings();
            setSnackbar({ open: true, message: 'Rechargement des paramètres...', severity: 'info' });
          }}
        >
          Recharger paramètres
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
                    {users.length}
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
                    {users.filter(u => u.role === 'admin').length}
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
                    {users.filter(u => u.role === 'technician').length}
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
                    {users.filter(u => u.role === 'manager').length}
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
                {users.map((user) => (
                  <TableRow key={user.id}>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Avatar src={user.avatar} sx={{ mr: 2 }}>
                          {user.firstName.charAt(0)}
                        </Avatar>
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {`${user.firstName} ${user.lastName}`}
                          </Typography>
                          {user.id === currentUser?.id && (
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
                            disabled={user.id === currentUser?.id}
                          >
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        {user.id !== currentUser?.id && (
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
                ))}
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
                  value={getSettingValue('workshop_phone', '01 23 45 67 89')}
                  onChange={(e) => updateLocalSetting('workshop_phone', e.target.value)}
                />
                <TextField
                  fullWidth
                  label="Email"
                  value={getSettingValue('workshop_email', 'contact@atelier.fr')}
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
                <TextField
                  fullWidth
                  label="Devise"
                  value={getSettingValue('currency', 'EUR')}
                  onChange={(e) => updateLocalSetting('currency', e.target.value)}
                />
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
            <strong>{selectedUser?.firstName} {selectedUser?.lastName}</strong> ?
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
