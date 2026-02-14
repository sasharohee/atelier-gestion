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
  alpha,
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

const CARD_BASE = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
  transition: 'all 0.3s cubic-bezier(0.4,0,0.2,1)',
  '&:hover': {
    boxShadow: '0 8px 32px rgba(0,0,0,0.10)',
    transform: 'translateY(-2px)',
  },
} as const;

const TABLE_HEAD_SX = {
  '& th': {
    borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600,
    fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
} as const;

function KpiMini({ icon, iconColor, label, value }: {
  icon: React.ReactNode; iconColor: string; label: string; value: string | number;
}) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '16px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{
            width: 40, height: 40, borderRadius: '12px', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
            color: '#fff', flexShrink: 0,
            boxShadow: `0 4px 14px ${alpha(iconColor, 0.3)}`,
          }}>
            {icon}
          </Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: '1.1rem' }}>
              {value}
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, fontSize: '0.7rem' }}>
              {label}
            </Typography>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

const Administration: React.FC = () => {
  const navigate = useNavigate();
  const {
    users, systemSettings, currentUser,
    addUser, updateUser, deleteUser, loadUsers,
    loadSystemSettings, updateSystemSetting, updateMultipleSystemSettings,
    loading, error, setError,
  } = useAppStore();

  const { user: authUser, loading: authLoading, isAuthenticated, refreshAuth } = useAuth();

  const [newUserDialogOpen, setNewUserDialogOpen] = useState(false);
  const [editUserDialogOpen, setEditUserDialogOpen] = useState(false);
  const [deleteUserDialogOpen, setDeleteUserDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
  const [forceRender, setForceRender] = useState(0);

  const [newUserForm, setNewUserForm] = useState({
    firstName: '', lastName: '', email: '', password: '',
    role: 'technician' as 'admin' | 'technician' | 'manager',
  });

  const [editUserForm, setEditUserForm] = useState({
    firstName: '', lastName: '', email: '',
    role: 'technician' as 'admin' | 'technician' | 'manager',
  });

  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [localSettings, setLocalSettings] = useState<Record<string, string>>({});

  // --- Business logic (inchangé) ---

  const ensureAdminUserExists = async () => {
    if (authLoading) {
      setSnackbar({ open: true, message: 'Chargement de l\'authentification...', severity: 'success' });
      return;
    }
    const userToUse = authUser || currentUser;
    if (!userToUse || !isAuthenticated) {
      setSnackbar({ open: true, message: 'Aucun utilisateur connecté. Veuillez vous connecter d\'abord.', severity: 'error' });
      return;
    }
    try {
      let { data, error } = await supabase.rpc('create_simple_admin_user', { p_email: userToUse.email });
      if (error && error.message.includes('function') && error.message.includes('does not exist')) {
        const result = await supabase.rpc('create_admin_user_auto', {
          p_email: userToUse.email,
          p_first_name: (userToUse as any).firstName || (userToUse as any).user_metadata?.firstName || null,
          p_last_name: (userToUse as any).lastName || (userToUse as any).user_metadata?.lastName || null,
        });
        data = result.data;
        error = result.error;
      }
      if (error) { await ensureAdminUserExistsFallback(); return; }
      if (data && data.success) {
        setSnackbar({ open: true, message: data.message || 'Compte administrateur configuré avec succès !', severity: 'success' });
        await loadUsers();
      } else {
        setSnackbar({ open: true, message: data?.message || 'Erreur lors de la création du compte administrateur', severity: 'error' });
      }
    } catch (err) {
      setSnackbar({ open: true, message: `Erreur lors de la création du compte administrateur: ${err}`, severity: 'error' });
    }
  };

  const ensureAdminUserExistsFallback = async () => {
    try {
      const userToUse = authUser || currentUser;
      if (!userToUse) return;
      const { data: existingUser, error: checkError } = await supabase
        .from('users').select('*').eq('email', userToUse.email).single();
      if (checkError && checkError.code !== 'PGRST116') return;
      if (existingUser) {
        if (existingUser.role !== 'admin') {
          await updateUser(existingUser.id, { role: 'admin' });
          setSnackbar({ open: true, message: 'Votre compte a été promu administrateur avec succès', severity: 'success' });
        }
        return;
      }
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
      await addUser({ firstName: firstName || 'Utilisateur', lastName: lastName || 'Administrateur', email: userToUse.email || '', role: 'admin', password: 'admin123' });
      setSnackbar({ open: true, message: 'Compte administrateur créé avec succès !', severity: 'success' });
      await loadUsers();
    } catch {
      setSnackbar({ open: true, message: 'Erreur lors de la création du compte administrateur', severity: 'error' });
    }
  };

  useEffect(() => {
    loadSystemSettings();
    const loadUsersSafely = async () => { try { await loadUsers(); } catch { /* ignore */ } };
    loadUsersSafely();
    const makeUserAdmin = async () => {
      if (isAuthenticated && authUser && !authLoading) {
        try {
          const { data, error } = await supabase.rpc('create_simple_admin_user', { p_email: authUser.email });
          if (error && error.message.includes('function') && error.message.includes('does not exist')) {
            await ensureAdminUserExistsFallback();
          } else if (data && data.success) {
            setSnackbar({ open: true, message: 'Vous avez été automatiquement promu administrateur !', severity: 'success' });
            await loadUsers();
          }
        } catch { /* ignore */ }
      }
    };
    const adminTimer = setTimeout(() => { makeUserAdmin(); }, 1500);
    return () => { clearTimeout(adminTimer); };
  }, [isAuthenticated, authUser, authLoading]);

  useEffect(() => {
    if (users.length > 0 && !isAuthenticated && !authLoading) {
      const timer = setTimeout(() => { refreshAuth(); }, 1000);
      return () => clearTimeout(timer);
    }
  }, [users.length, isAuthenticated, authLoading, refreshAuth]);

  useEffect(() => {
    const timer = setTimeout(() => {
      if (!isAuthenticated && !authLoading) {
        refreshAuth().then(() => { setForceRender(prev => prev + 1); });
      }
    }, 500);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    setForceRender(prev => prev + 1);
  }, [isAuthenticated, authUser]);

  const validateForm = (form: any, isEdit = false) => {
    const errors: Record<string, string> = {};
    if (!form.firstName.trim()) errors.firstName = 'Le prénom est requis';
    if (!form.lastName.trim()) errors.lastName = 'Le nom est requis';
    if (!form.email.trim()) errors.email = 'L\'email est requis';
    else if (!/\S+@\S+\.\S+/.test(form.email)) errors.email = 'L\'email n\'est pas valide';
    if (!isEdit && !form.password.trim()) errors.password = 'Le mot de passe est requis';
    else if (!isEdit && form.password.length < 6) errors.password = 'Le mot de passe doit contenir au moins 6 caractères';
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleCreateUser = async () => {
    if (!validateForm(newUserForm)) return;
    try {
      await addUser(newUserForm);
      setSnackbar({ open: true, message: 'Utilisateur créé avec succès', severity: 'success' });
      setNewUserDialogOpen(false);
      setNewUserForm({ firstName: '', lastName: '', email: '', password: '', role: 'technician' });
    } catch (error: any) {
      let errorMessage = 'Erreur lors de la création';
      if (error.message) errorMessage = error.message;
      else if (error.code === '23505') errorMessage = 'Cet email est déjà utilisé par un autre utilisateur.';
      else if (error.code === 'EMAIL_EXISTS') errorMessage = error.message;
      setSnackbar({ open: true, message: errorMessage, severity: 'error' });
    }
  };

  const handleEditUser = async () => {
    if (!validateForm(editUserForm, true)) return;
    try {
      if (selectedUser.id === authUser?.id) {
        const { error: updateError } = await supabase.auth.updateUser({
          data: { firstName: editUserForm.firstName, lastName: editUserForm.lastName, role: editUserForm.role },
        });
        if (updateError) throw new Error(`Erreur lors de la mise à jour des métadonnées: ${updateError.message}`);
        try { await updateUser(selectedUser.id, editUserForm); } catch {
          await addUser({ firstName: editUserForm.firstName, lastName: editUserForm.lastName, email: editUserForm.email, role: editUserForm.role, password: 'temp_password' });
        }
        setSnackbar({ open: true, message: 'Vos informations ont été mises à jour avec succès', severity: 'success' });
      } else {
        await updateUser(selectedUser.id, editUserForm);
        setSnackbar({ open: true, message: 'Utilisateur modifié avec succès', severity: 'success' });
      }
      setEditUserDialogOpen(false);
      setSelectedUser(null);
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
      if (systemSettings.length === 0) {
        setSnackbar({ open: true, message: 'Aucun paramètre à sauvegarder.', severity: 'error' });
        return;
      }
      const settingsToUpdate = systemSettings
        .filter(setting => setting.category === category)
        .map(setting => ({ key: setting.key, value: localSettings[setting.key] !== undefined ? localSettings[setting.key] : setting.value }));
      if (settingsToUpdate.length > 0) {
        await updateMultipleSystemSettings(settingsToUpdate);
        const newLocalSettings = { ...localSettings };
        settingsToUpdate.forEach(setting => { delete newLocalSettings[setting.key]; });
        setLocalSettings(newLocalSettings);
        setSnackbar({ open: true, message: 'Paramètres sauvegardés avec succès', severity: 'success' });
      } else {
        setSnackbar({ open: true, message: 'Aucun paramètre à sauvegarder', severity: 'success' });
      }
    } catch (error: any) {
      setSnackbar({ open: true, message: error.message || 'Erreur lors de la sauvegarde', severity: 'error' });
    }
  };

  const openEditDialog = (user: any) => {
    setSelectedUser(user);
    setEditUserForm({ firstName: user.firstName || '', lastName: user.lastName || '', email: user.email || '', role: user.role || 'technician' });
    setEditUserDialogOpen(true);
  };

  const openDeleteDialog = (user: any) => { setSelectedUser(user); setDeleteUserDialogOpen(true); };

  const getRoleChip = (role: string) => {
    const map: Record<string, { label: string; color: string }> = {
      admin: { label: 'Administrateur', color: '#ef4444' },
      manager: { label: 'Gérant', color: '#f59e0b' },
      technician: { label: 'Technicien', color: '#6366f1' },
    };
    const c = map[role] || { label: role, color: '#6b7280' };
    return (
      <Chip label={c.label} size="small" sx={{
        fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
        bgcolor: alpha(c.color, 0.1), color: c.color,
      }} />
    );
  };

  const getSettingValue = (key: string, defaultValue: string = '') => {
    if (localSettings[key] !== undefined) return localSettings[key];
    const setting = systemSettings.find(s => s.key === key);
    return setting?.value || defaultValue;
  };

  const isSettingsLoaded = systemSettings.length > 0;

  const updateLocalSetting = (key: string, value: string) => {
    setLocalSettings(prev => ({ ...prev, [key]: value }));
  };

  // Combiner utilisateurs store + utilisateur connecté
  const allUsers = (() => {
    const list = [...users];
    if (isAuthenticated && authUser && !list.some(u => u.id === authUser.id)) {
      list.unshift({
        id: authUser.id,
        firstName: (authUser as any).user_metadata?.firstName || authUser.email?.split('@')[0] || 'Utilisateur',
        lastName: (authUser as any).user_metadata?.lastName || 'Connecté',
        email: authUser.email || '',
        role: (authUser as any).user_metadata?.role || 'technician',
        avatar: (authUser as any).user_metadata?.avatar,
        createdAt: new Date(authUser.created_at),
        updatedAt: new Date(authUser.updated_at || authUser.created_at),
      });
    }
    return list;
  })();

  const totalUsers = allUsers.length;
  const adminCount = allUsers.filter(u => u.role === 'admin').length;
  const techCount = allUsers.filter(u => u.role === 'technician').length;
  const managerCount = allUsers.filter(u => u.role === 'manager').length;

  // --- Render ---

  const DIALOG_SX = {
    '& .MuiDialog-paper': { borderRadius: '16px', boxShadow: '0 24px 48px rgba(0,0,0,0.12)' },
  };

  const INPUT_SX = { '& .MuiOutlinedInput-root': { borderRadius: '10px' } };

  return (
    <Box sx={{ maxWidth: 1400, mx: 'auto' }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700, letterSpacing: '-0.02em' }}>
          Administration
        </Typography>
        <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
          Gestion des utilisateurs et paramètres système
        </Typography>
      </Box>

      {/* Auth status alerts */}
      {!isAuthenticated && !authLoading && (
        <Alert
          severity="warning"
          sx={{ mb: 3, borderRadius: '12px', border: '1px solid', borderColor: alpha('#f59e0b', 0.2), bgcolor: alpha('#f59e0b', 0.04), '& .MuiAlert-icon': { color: '#f59e0b' } }}
          action={
            <Button color="inherit" size="small" onClick={() => { window.location.href = '/auth'; }}
              sx={{ borderRadius: '8px', textTransform: 'none', fontWeight: 600 }}>
              Se connecter
            </Button>
          }
        >
          <Typography variant="body2" sx={{ fontWeight: 500 }}>
            Vous devez être connecté pour accéder à l'Administration.
          </Typography>
        </Alert>
      )}

      {isAuthenticated && authUser && (
        <Card sx={{ ...CARD_BASE, mb: 3, border: `1px solid ${alpha('#6366f1', 0.15)}`, bgcolor: alpha('#6366f1', 0.02) }}>
          <CardContent sx={{ p: '16px !important', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <Avatar sx={{
                width: 44, height: 44, fontWeight: 700, fontSize: '1rem',
                background: `linear-gradient(135deg, #6366f1, ${alpha('#6366f1', 0.7)})`,
                boxShadow: `0 4px 14px ${alpha('#6366f1', 0.3)}`,
              }}>
                {authUser.email?.charAt(0).toUpperCase()}
              </Avatar>
              <Box>
                <Typography variant="body2" sx={{ fontWeight: 700 }}>
                  {(authUser as any).user_metadata?.firstName || authUser.email?.split('@')[0]} {(authUser as any).user_metadata?.lastName || ''}
                </Typography>
                <Typography variant="caption" color="text.disabled" sx={{ fontSize: '0.7rem' }}>
                  {authUser.email} • Connecté depuis le {new Date(authUser.created_at).toLocaleDateString('fr-FR')}
                </Typography>
              </Box>
            </Box>
            <Box sx={{ display: 'flex', gap: 1 }}>
              <Button
                variant="outlined"
                size="small"
                startIcon={<RefreshIcon sx={{ fontSize: 16 }} />}
                onClick={loadUsers}
                disabled={loading}
                sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'divider', color: 'text.secondary', '&:hover': { bgcolor: 'grey.50', borderColor: 'grey.400' } }}
              >
                Actualiser
              </Button>
              <Button
                variant="contained"
                size="small"
                startIcon={<AddIcon sx={{ fontSize: 16 }} />}
                onClick={() => setNewUserDialogOpen(true)}
                sx={{
                  borderRadius: '10px', textTransform: 'none', fontWeight: 600,
                  bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
                  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
                }}
              >
                Nouvel utilisateur
              </Button>
            </Box>
          </CardContent>
        </Card>
      )}

      {/* KPI cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<PeopleIcon sx={{ fontSize: 20 }} />} iconColor="#6366f1" label="Total utilisateurs" value={totalUsers} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<SecurityIcon sx={{ fontSize: 20 }} />} iconColor="#ef4444" label="Administrateurs" value={adminCount} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<SettingsIcon sx={{ fontSize: 20 }} />} iconColor="#8b5cf6" label="Techniciens" value={techCount} />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini icon={<PeopleIcon sx={{ fontSize: 20 }} />} iconColor="#22c55e" label="Gérants" value={managerCount} />
        </Grid>
      </Grid>

      {/* Users table */}
      <Card sx={{ borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)', mb: 3 }}>
        <Box sx={{ p: 2.5, pb: 0, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.secondary', textTransform: 'uppercase', fontSize: '0.7rem', letterSpacing: '0.05em' }}>
            Gestion des utilisateurs
          </Typography>
          {loading && <CircularProgress size={16} sx={{ color: '#6366f1' }} />}
        </Box>

        {error && (
          <Box sx={{ px: 2.5, pt: 1.5 }}>
            <Alert severity="error" sx={{ borderRadius: '10px' }} onClose={() => setError(null)}>{error}</Alert>
          </Box>
        )}

        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={TABLE_HEAD_SX}>
                <TableCell>Utilisateur</TableCell>
                <TableCell>Email</TableCell>
                <TableCell>Rôle</TableCell>
                <TableCell>Créé le</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {allUsers.map((user) => (
                <TableRow key={user.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                      <Avatar
                        src={user.avatar}
                        sx={{
                          width: 36, height: 36, fontSize: '0.85rem', fontWeight: 600,
                          bgcolor: alpha('#6366f1', 0.1), color: '#6366f1',
                        }}
                      >
                        {user.firstName?.charAt(0) || user.email?.charAt(0) || 'U'}
                      </Avatar>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {`${user.firstName || ''} ${user.lastName || ''}`.trim() || user.email || 'Utilisateur'}
                        </Typography>
                        {(user.id === currentUser?.id || user.id === authUser?.id) && (
                          <Chip label="Vous" size="small" sx={{
                            height: 18, fontSize: '0.6rem', fontWeight: 700, borderRadius: '6px',
                            bgcolor: alpha('#6366f1', 0.1), color: '#6366f1',
                          }} />
                        )}
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">{user.email}</Typography>
                  </TableCell>
                  <TableCell>{getRoleChip(user.role)}</TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                      {new Date(user.createdAt).toLocaleDateString('fr-FR')}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                      <Tooltip title="Modifier">
                        <IconButton size="small" onClick={() => openEditDialog(user)}
                          sx={{ width: 32, height: 32, borderRadius: '8px', bgcolor: alpha('#6366f1', 0.1), color: '#6366f1', '&:hover': { bgcolor: alpha('#6366f1', 0.2) } }}>
                          <EditIcon sx={{ fontSize: 16 }} />
                        </IconButton>
                      </Tooltip>
                      {user.id !== authUser?.id && (
                        <Tooltip title="Supprimer">
                          <IconButton size="small" onClick={() => openDeleteDialog(user)}
                            sx={{ width: 32, height: 32, borderRadius: '8px', bgcolor: alpha('#ef4444', 0.1), color: '#ef4444', '&:hover': { bgcolor: alpha('#ef4444', 0.2) } }}>
                            <DeleteIcon sx={{ fontSize: 16 }} />
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

        {allUsers.length === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', py: 6 }}>
            <PeopleIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} />
            <Typography variant="body2" color="text.disabled">Aucun utilisateur trouvé</Typography>
          </Box>
        )}
      </Card>

      {/* Settings */}
      <Grid container spacing={3}>
        {/* General settings */}
        <Grid item xs={12} md={6}>
          <Card sx={CARD_BASE}>
            <CardContent sx={{ p: '20px !important' }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2.5 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <Box sx={{
                    width: 36, height: 36, borderRadius: '10px', display: 'flex',
                    alignItems: 'center', justifyContent: 'center',
                    background: `linear-gradient(135deg, #6366f1, ${alpha('#6366f1', 0.7)})`,
                    color: '#fff', boxShadow: `0 4px 14px ${alpha('#6366f1', 0.3)}`,
                  }}>
                    <SettingsIcon sx={{ fontSize: 18 }} />
                  </Box>
                  <Typography variant="body1" sx={{ fontWeight: 700 }}>Paramètres généraux</Typography>
                </Box>
                <Button
                  variant="contained" size="small" startIcon={<SaveIcon sx={{ fontSize: 14 }} />}
                  onClick={() => handleSaveSettings('general')} disabled={!isSettingsLoaded}
                  sx={{
                    borderRadius: '10px', textTransform: 'none', fontWeight: 600, fontSize: '0.75rem',
                    bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
                    boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
                  }}
                >
                  Sauvegarder
                </Button>
              </Box>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField fullWidth label="Nom de l'atelier" size="small" sx={INPUT_SX}
                  value={getSettingValue('workshop_name', 'Atelier de réparation')}
                  onChange={(e) => updateLocalSetting('workshop_name', e.target.value)} />
                <TextField fullWidth label="Adresse" multiline rows={2} size="small" sx={INPUT_SX}
                  value={getSettingValue('workshop_address', '123 Rue de la Paix, 75001 Paris')}
                  onChange={(e) => updateLocalSetting('workshop_address', e.target.value)} />
                <TextField fullWidth label="Téléphone" size="small" sx={INPUT_SX}
                  value={getSettingValue('workshop_phone', '07 59 23 91 70')}
                  onChange={(e) => updateLocalSetting('workshop_phone', e.target.value)} />
                <TextField fullWidth label="Email" size="small" sx={INPUT_SX}
                  value={getSettingValue('workshop_email', 'contact.ateliergestion@gmail.com')}
                  onChange={(e) => updateLocalSetting('workshop_email', e.target.value)} />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Billing settings */}
        <Grid item xs={12} md={6}>
          <Card sx={CARD_BASE}>
            <CardContent sx={{ p: '20px !important' }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2.5 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <Box sx={{
                    width: 36, height: 36, borderRadius: '10px', display: 'flex',
                    alignItems: 'center', justifyContent: 'center',
                    background: `linear-gradient(135deg, #22c55e, ${alpha('#22c55e', 0.7)})`,
                    color: '#fff', boxShadow: `0 4px 14px ${alpha('#22c55e', 0.3)}`,
                  }}>
                    <LockIcon sx={{ fontSize: 18 }} />
                  </Box>
                  <Typography variant="body1" sx={{ fontWeight: 700 }}>Paramètres de facturation</Typography>
                </Box>
                <Button
                  variant="contained" size="small" startIcon={<SaveIcon sx={{ fontSize: 14 }} />}
                  onClick={() => handleSaveSettings('billing')} disabled={!isSettingsLoaded}
                  sx={{
                    borderRadius: '10px', textTransform: 'none', fontWeight: 600, fontSize: '0.75rem',
                    bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
                    boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
                  }}
                >
                  Sauvegarder
                </Button>
              </Box>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField fullWidth label="TVA (%)" type="number" size="small" sx={INPUT_SX}
                  value={getSettingValue('vat_rate', '20')}
                  onChange={(e) => updateLocalSetting('vat_rate', e.target.value)} />
                <FormControl fullWidth size="small">
                  <InputLabel>Devise</InputLabel>
                  <Select value={getSettingValue('currency', 'EUR')} label="Devise"
                    onChange={(e) => updateLocalSetting('currency', e.target.value)}
                    sx={{ borderRadius: '10px' }}>
                    <MenuItem value="EUR">EUR (€)</MenuItem>
                    <MenuItem value="USD">USD ($)</MenuItem>
                    <MenuItem value="GBP">GBP (£)</MenuItem>
                    <MenuItem value="CHF">CHF (CHF)</MenuItem>
                  </Select>
                </FormControl>
                <TextField fullWidth label="Préfixe facture" size="small" sx={INPUT_SX}
                  value={getSettingValue('invoice_prefix', 'FACT-')}
                  onChange={(e) => updateLocalSetting('invoice_prefix', e.target.value)} />
                <FormControl fullWidth size="small">
                  <InputLabel>Format de date</InputLabel>
                  <Select value={getSettingValue('date_format', 'dd/MM/yyyy')} label="Format de date"
                    onChange={(e) => updateLocalSetting('date_format', e.target.value)}
                    sx={{ borderRadius: '10px' }}>
                    <MenuItem value="dd/MM/yyyy">dd/MM/yyyy</MenuItem>
                    <MenuItem value="MM/dd/yyyy">MM/dd/yyyy</MenuItem>
                    <MenuItem value="yyyy-MM-dd">yyyy-MM-dd</MenuItem>
                  </Select>
                </FormControl>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* System settings */}
        <Grid item xs={12}>
          <Card sx={CARD_BASE}>
            <CardContent sx={{ p: '20px !important' }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2.5 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <Box sx={{
                    width: 36, height: 36, borderRadius: '10px', display: 'flex',
                    alignItems: 'center', justifyContent: 'center',
                    background: `linear-gradient(135deg, #f59e0b, ${alpha('#f59e0b', 0.7)})`,
                    color: '#fff', boxShadow: `0 4px 14px ${alpha('#f59e0b', 0.3)}`,
                  }}>
                    <SecurityIcon sx={{ fontSize: 18 }} />
                  </Box>
                  <Typography variant="body1" sx={{ fontWeight: 700 }}>Paramètres système</Typography>
                </Box>
                <Button
                  variant="contained" size="small" startIcon={<SaveIcon sx={{ fontSize: 14 }} />}
                  onClick={() => handleSaveSettings('system')} disabled={!isSettingsLoaded}
                  sx={{
                    borderRadius: '10px', textTransform: 'none', fontWeight: 600, fontSize: '0.75rem',
                    bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
                    boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
                  }}
                >
                  Sauvegarder
                </Button>
              </Box>
              <Grid container spacing={3}>
                <Grid item xs={12} sm={6}>
                  <Box sx={{
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                    p: 2, borderRadius: '12px', bgcolor: 'grey.50',
                  }}>
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>Sauvegarde automatique</Typography>
                      <Typography variant="caption" color="text.disabled">Sauvegarder les données automatiquement</Typography>
                    </Box>
                    <Switch
                      checked={getSettingValue('auto_backup', 'true') === 'true'}
                      onChange={(e) => updateLocalSetting('auto_backup', e.target.checked.toString())}
                      sx={{ '& .MuiSwitch-switchBase.Mui-checked': { color: '#6366f1' }, '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': { bgcolor: '#6366f1' } }}
                    />
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box sx={{
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                    p: 2, borderRadius: '12px', bgcolor: 'grey.50',
                  }}>
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>Notifications</Typography>
                      <Typography variant="caption" color="text.disabled">Activer les notifications système</Typography>
                    </Box>
                    <Switch
                      checked={getSettingValue('notifications', 'true') === 'true'}
                      onChange={(e) => updateLocalSetting('notifications', e.target.checked.toString())}
                      sx={{ '& .MuiSwitch-switchBase.Mui-checked': { color: '#6366f1' }, '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': { bgcolor: '#6366f1' } }}
                    />
                  </Box>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Dialog nouvel utilisateur */}
      <Dialog open={newUserDialogOpen} onClose={() => setNewUserDialogOpen(false)} maxWidth="sm" fullWidth sx={DIALOG_SX}>
        <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>Nouvel utilisateur</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="Prénom" size="small" sx={INPUT_SX}
                value={newUserForm.firstName} onChange={(e) => setNewUserForm({ ...newUserForm, firstName: e.target.value })}
                error={!!formErrors.firstName} helperText={formErrors.firstName} />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="Nom" size="small" sx={INPUT_SX}
                value={newUserForm.lastName} onChange={(e) => setNewUserForm({ ...newUserForm, lastName: e.target.value })}
                error={!!formErrors.lastName} helperText={formErrors.lastName} />
            </Grid>
            <Grid item xs={12}>
              <TextField fullWidth label="Email" type="email" size="small" sx={INPUT_SX}
                value={newUserForm.email} onChange={(e) => setNewUserForm({ ...newUserForm, email: e.target.value })}
                error={!!formErrors.email} helperText={formErrors.email} />
            </Grid>
            <Grid item xs={12}>
              <TextField fullWidth label="Mot de passe" type="password" size="small" sx={INPUT_SX}
                value={newUserForm.password} onChange={(e) => setNewUserForm({ ...newUserForm, password: e.target.value })}
                error={!!formErrors.password} helperText={formErrors.password} />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth size="small">
                <InputLabel>Rôle</InputLabel>
                <Select value={newUserForm.role} label="Rôle"
                  onChange={(e) => setNewUserForm({ ...newUserForm, role: e.target.value as any })}
                  sx={{ borderRadius: '10px' }}>
                  <MenuItem value="admin">Administrateur</MenuItem>
                  <MenuItem value="manager">Gérant</MenuItem>
                  <MenuItem value="technician">Technicien</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 1 }}>
          <Button onClick={() => setNewUserDialogOpen(false)}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            Annuler
          </Button>
          <Button variant="contained" onClick={handleCreateUser} disabled={loading}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' }, boxShadow: '0 2px 8px rgba(17,24,39,0.25)' }}>
            {loading ? <CircularProgress size={18} sx={{ color: '#fff' }} /> : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog modification utilisateur */}
      <Dialog open={editUserDialogOpen} onClose={() => setEditUserDialogOpen(false)} maxWidth="sm" fullWidth sx={DIALOG_SX}>
        <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>Modifier l'utilisateur</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="Prénom" size="small" sx={INPUT_SX}
                value={editUserForm.firstName} onChange={(e) => setEditUserForm({ ...editUserForm, firstName: e.target.value })}
                error={!!formErrors.firstName} helperText={formErrors.firstName} />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="Nom" size="small" sx={INPUT_SX}
                value={editUserForm.lastName} onChange={(e) => setEditUserForm({ ...editUserForm, lastName: e.target.value })}
                error={!!formErrors.lastName} helperText={formErrors.lastName} />
            </Grid>
            <Grid item xs={12}>
              <TextField fullWidth label="Email" type="email" size="small" sx={INPUT_SX}
                value={editUserForm.email} onChange={(e) => setEditUserForm({ ...editUserForm, email: e.target.value })}
                error={!!formErrors.email} helperText={formErrors.email} />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth size="small">
                <InputLabel>Rôle</InputLabel>
                <Select value={editUserForm.role} label="Rôle"
                  onChange={(e) => setEditUserForm({ ...editUserForm, role: e.target.value as any })}
                  sx={{ borderRadius: '10px' }}>
                  <MenuItem value="admin">Administrateur</MenuItem>
                  <MenuItem value="manager">Gérant</MenuItem>
                  <MenuItem value="technician">Technicien</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 1 }}>
          <Button onClick={() => setEditUserDialogOpen(false)}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            Annuler
          </Button>
          <Button variant="contained" onClick={handleEditUser} disabled={loading}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' }, boxShadow: '0 2px 8px rgba(17,24,39,0.25)' }}>
            {loading ? <CircularProgress size={18} sx={{ color: '#fff' }} /> : 'Modifier'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog confirmation suppression */}
      <Dialog open={deleteUserDialogOpen} onClose={() => setDeleteUserDialogOpen(false)} maxWidth="xs" fullWidth sx={DIALOG_SX}>
        <DialogTitle sx={{ fontWeight: 700, pb: 1 }}>Confirmer la suppression</DialogTitle>
        <DialogContent>
          <Typography variant="body2">
            Êtes-vous sûr de vouloir supprimer l'utilisateur{' '}
            <strong>{selectedUser?.firstName || ''} {selectedUser?.lastName || ''}</strong> ?
          </Typography>
          <Typography variant="caption" color="text.disabled" sx={{ mt: 1, display: 'block' }}>
            Cette action est irréversible.
          </Typography>
        </DialogContent>
        <DialogActions sx={{ p: 2.5, pt: 1 }}>
          <Button onClick={() => setDeleteUserDialogOpen(false)}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, color: 'text.secondary' }}>
            Annuler
          </Button>
          <Button variant="contained" onClick={handleDeleteUser} disabled={loading}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, bgcolor: '#ef4444', '&:hover': { bgcolor: '#dc2626' }, boxShadow: '0 2px 8px rgba(239,68,68,0.25)' }}>
            {loading ? <CircularProgress size={18} sx={{ color: '#fff' }} /> : 'Supprimer'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar open={snackbar.open} autoHideDuration={6000} onClose={() => setSnackbar({ ...snackbar, open: false })}>
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity}
          sx={{ borderRadius: '12px', fontWeight: 500 }}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Administration;
