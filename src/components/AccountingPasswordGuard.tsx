import React, { useState, useEffect, ReactNode } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Typography,
  Box,
  Alert,
  CircularProgress,
  IconButton,
  InputAdornment,
  Divider,
  Card,
  CardContent,
} from '@mui/material';
import {
  Visibility,
  VisibilityOff,
  Lock,
  Security,
  CheckCircle,
  Error as ErrorIcon,
} from '@mui/icons-material';
import { accountingPasswordServiceFallback as accountingPasswordService } from '../services/accountingPasswordServiceFallback';

interface AccountingPasswordGuardProps {
  children: ReactNode;
}

const AccountingPasswordGuard: React.FC<AccountingPasswordGuardProps> = ({ children }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isCreatingPassword, setIsCreatingPassword] = useState(false);
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [hasAccess, setHasAccess] = useState(false);
  const [needsPassword, setNeedsPassword] = useState(false);

  useEffect(() => {
    checkAccess();
  }, []);

  const checkAccess = async () => {
    try {
      // Vérifier d'abord si la session est active
      if (accountingPasswordService.isSessionActive()) {
        setHasAccess(true);
        return;
      }

      const result = await accountingPasswordService.checkAccess();
      
      if (result.hasAccess) {
        setHasAccess(true);
        return;
      }
      
      if (result.needsPassword) {
        setNeedsPassword(true);
        setIsOpen(true);
      } else {
        // Aucun mot de passe défini, proposer d'en créer un
        setIsCreatingPassword(true);
        setIsOpen(true);
      }
    } catch (err) {
      console.error('Erreur lors de la vérification de l\'accès:', err);
      setError('Erreur lors de la vérification de l\'accès');
      setIsOpen(true);
    }
  };

  const handlePasswordSubmit = async () => {
    if (!password.trim()) {
      setError('Veuillez saisir un mot de passe');
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const result = await accountingPasswordService.verifyPassword(password);
      
      if (result.success && result.data) {
        accountingPasswordService.setSessionActive();
        setHasAccess(true);
        setIsOpen(false);
        setPassword('');
      } else {
        setError(result.error || 'Mot de passe incorrect');
      }
    } catch (err) {
      console.error('Erreur lors de la vérification:', err);
      setError('Erreur lors de la vérification du mot de passe');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreatePassword = async () => {
    if (!newPassword.trim()) {
      setError('Veuillez saisir un mot de passe');
      return;
    }

    if (newPassword.length < 6) {
      setError('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('Les mots de passe ne correspondent pas');
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const result = await accountingPasswordService.setPassword(newPassword);
      
      if (result.success) {
        accountingPasswordService.setSessionActive();
        setHasAccess(true);
        setIsOpen(false);
        setNewPassword('');
        setConfirmPassword('');
        setIsCreatingPassword(false);
      } else {
        setError(result.error || 'Erreur lors de la création du mot de passe');
      }
    } catch (err) {
      console.error('Erreur lors de la création:', err);
      setError('Erreur lors de la création du mot de passe');
    } finally {
      setIsLoading(false);
    }
  };

  const handleTogglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  const handleToggleNewPasswordVisibility = () => {
    setShowNewPassword(!showNewPassword);
  };

  const handleToggleConfirmPasswordVisibility = () => {
    setShowConfirmPassword(!showConfirmPassword);
  };

  const handleSwitchToLogin = () => {
    setIsCreatingPassword(false);
    setNewPassword('');
    setConfirmPassword('');
    setError(null);
  };

  const handleSwitchToCreate = () => {
    setIsCreatingPassword(true);
    setPassword('');
    setError(null);
  };

  if (hasAccess) {
    return <>{children}</>;
  }

  return (
    <Dialog 
      open={isOpen} 
      maxWidth="sm" 
      fullWidth
      disableEscapeKeyDown
      disableBackdropClick
    >
      <DialogTitle sx={{ 
        textAlign: 'center', 
        pb: 1,
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        color: 'white'
      }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 1 }}>
          <Security sx={{ fontSize: 28 }} />
          <Typography variant="h5" sx={{ fontWeight: 600 }}>
            {isCreatingPassword ? 'Créer un mot de passe comptable' : 'Accès Comptabilité'}
          </Typography>
        </Box>
      </DialogTitle>

      <DialogContent sx={{ p: 3 }}>
        {error && (
          <Alert severity="error" sx={{ mb: 2, display: 'flex', alignItems: 'center' }}>
            <ErrorIcon sx={{ mr: 1 }} />
            {error}
          </Alert>
        )}

        {isCreatingPassword ? (
          <Box>
            <Card sx={{ mb: 3, border: '1px solid #e0e0e0' }}>
              <CardContent sx={{ p: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <Lock sx={{ color: '#1976d2', mr: 1 }} />
                  <Typography variant="h6" sx={{ color: '#1976d2', fontWeight: 600 }}>
                    Configuration initiale
                  </Typography>
                </Box>
                <Typography variant="body2" color="text.secondary">
                  Créez un mot de passe sécurisé pour accéder à la page Comptabilité. 
                  Ce mot de passe sera demandé à chaque accès pour protéger vos données financières.
                </Typography>
              </CardContent>
            </Card>

            <TextField
              fullWidth
              label="Nouveau mot de passe"
              type={showNewPassword ? 'text' : 'password'}
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              margin="normal"
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      onClick={handleToggleNewPasswordVisibility}
                      edge="end"
                    >
                      {showNewPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
              helperText="Minimum 6 caractères"
            />

            <TextField
              fullWidth
              label="Confirmer le mot de passe"
              type={showConfirmPassword ? 'text' : 'password'}
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              margin="normal"
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      onClick={handleToggleConfirmPasswordVisibility}
                      edge="end"
                    >
                      {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />

            <Box sx={{ mt: 2, p: 2, backgroundColor: '#f5f5f5', borderRadius: 1 }}>
              <Typography variant="body2" color="text.secondary">
                <strong>Conseils de sécurité :</strong>
                <br />• Utilisez au moins 8 caractères
                <br />• Combinez lettres, chiffres et symboles
                <br />• Évitez les mots de passe courants
                <br />• Ne partagez jamais ce mot de passe
              </Typography>
            </Box>
          </Box>
        ) : (
          <Box>
            <Card sx={{ mb: 3, border: '1px solid #e0e0e0' }}>
              <CardContent sx={{ p: 2 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <Lock sx={{ color: '#1976d2', mr: 1 }} />
                  <Typography variant="h6" sx={{ color: '#1976d2', fontWeight: 600 }}>
                    Accès sécurisé
                  </Typography>
                </Box>
                <Typography variant="body2" color="text.secondary">
                  Saisissez votre mot de passe comptable pour accéder aux données financières.
                </Typography>
              </CardContent>
            </Card>

            <TextField
              fullWidth
              label="Mot de passe comptable"
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              margin="normal"
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton
                      onClick={handleTogglePasswordVisibility}
                      edge="end"
                    >
                      {showPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                ),
              }}
              onKeyPress={(e) => {
                if (e.key === 'Enter') {
                  handlePasswordSubmit();
                }
              }}
            />
          </Box>
        )}
      </DialogContent>

      <Divider />

      <DialogActions sx={{ p: 3, gap: 1 }}>
        {isCreatingPassword ? (
          <>
            <Button
              onClick={handleSwitchToLogin}
              color="secondary"
              disabled={isLoading}
            >
              J'ai déjà un mot de passe
            </Button>
            <Button
              onClick={handleCreatePassword}
              variant="contained"
              disabled={isLoading || !newPassword || !confirmPassword}
              startIcon={isLoading ? <CircularProgress size={20} /> : <CheckCircle />}
              sx={{ 
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                '&:hover': {
                  background: 'linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)',
                }
              }}
            >
              {isLoading ? 'Création...' : 'Créer le mot de passe'}
            </Button>
          </>
        ) : (
          <>
            {needsPassword && (
              <Button
                onClick={handleSwitchToCreate}
                color="secondary"
                disabled={isLoading}
              >
                Créer un mot de passe
              </Button>
            )}
            <Button
              onClick={handlePasswordSubmit}
              variant="contained"
              disabled={isLoading || !password}
              startIcon={isLoading ? <CircularProgress size={20} /> : <CheckCircle />}
              sx={{ 
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                '&:hover': {
                  background: 'linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)',
                }
              }}
            >
              {isLoading ? 'Vérification...' : 'Accéder à la Comptabilité'}
            </Button>
          </>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default AccountingPasswordGuard;
