import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Alert,
  CircularProgress,
  InputAdornment,
  IconButton,
  FormControl,
  InputLabel,
  OutlinedInput,
  Link
} from '@mui/material';
import {
  Visibility,
  VisibilityOff,
  Lock,
  Email
} from '@mui/icons-material';
import { useAuth } from '../../hooks/useAuth';

const ResetPassword: React.FC = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { updatePassword, resetPassword, loading } = useAuth();
  
  const [mode, setMode] = useState<'request' | 'reset'>('request');
  const [message, setMessage] = useState<string>('');
  const [error, setError] = useState<string>('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  
  const [email, setEmail] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    const token = searchParams.get('token');
    const type = searchParams.get('type');
    
    if (token && type === 'recovery') {
      setMode('reset');
    }
  }, [searchParams]);

  const validateEmail = (email: string) => {
    return /\S+@\S+\.\S+/.test(email);
  };

  const validatePassword = (password: string) => {
    return password.length >= 8 && 
           /[A-Z]/.test(password) && 
           /[a-z]/.test(password) && 
           /\d/.test(password) && 
           /[!@#$%^&*(),.?":{}|<>]/.test(password);
  };

  const handleRequestReset = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setMessage('');

    if (!email) {
      setError('L\'email est requis');
      return;
    }

    if (!validateEmail(email)) {
      setError('L\'email n\'est pas valide');
      return;
    }

    const result = await resetPassword(email);
    
    if (result.success) {
      setMessage('Un email de réinitialisation a été envoyé à votre adresse email.');
    } else {
      setError(result.error || 'Erreur lors de l\'envoi de l\'email de réinitialisation');
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setMessage('');
    
    const errors: Record<string, string> = {};

    if (!newPassword) {
      errors.newPassword = 'Le nouveau mot de passe est requis';
    } else if (!validatePassword(newPassword)) {
      errors.newPassword = 'Le mot de passe ne respecte pas les critères de sécurité';
    }

    if (!confirmPassword) {
      errors.confirmPassword = 'La confirmation du mot de passe est requise';
    } else if (newPassword !== confirmPassword) {
      errors.confirmPassword = 'Les mots de passe ne correspondent pas';
    }

    setFormErrors(errors);

    if (Object.keys(errors).length > 0) {
      return;
    }

    const result = await updatePassword(newPassword);
    
    if (result.success) {
      setMessage('Votre mot de passe a été mis à jour avec succès ! Vous pouvez maintenant vous connecter.');
      setTimeout(() => {
        navigate('/auth');
      }, 3000);
    } else {
      setError(result.error || 'Erreur lors de la mise à jour du mot de passe');
    }
  };

  const getPasswordValidation = () => {
    if (!newPassword) return null;

    return {
      length: newPassword.length >= 8,
      uppercase: /[A-Z]/.test(newPassword),
      lowercase: /[a-z]/.test(newPassword),
      number: /\d/.test(newPassword),
      special: /[!@#$%^&*(),.?":{}|<>]/.test(newPassword)
    };
  };

  const passwordValidation = getPasswordValidation();

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        p: 2
      }}
    >
      <Card
        sx={{
          maxWidth: 500,
          width: '100%',
          boxShadow: '0 20px 40px rgba(0,0,0,0.1)',
          borderRadius: 3
        }}
      >
        <CardContent sx={{ p: 4 }}>
          {/* En-tête */}
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <Typography variant="h4" component="h1" gutterBottom color="primary" fontWeight="bold">
              {mode === 'request' ? 'Mot de passe oublié' : 'Nouveau mot de passe'}
            </Typography>
            <Typography variant="body1" color="text.secondary">
              {mode === 'request' 
                ? 'Entrez votre email pour recevoir un lien de réinitialisation'
                : 'Entrez votre nouveau mot de passe'
              }
            </Typography>
          </Box>

          {/* Messages */}
          {error && (
            <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError('')}>
              {error}
            </Alert>
          )}
          
          {message && (
            <Alert severity="success" sx={{ mb: 3 }} onClose={() => setMessage('')}>
              {message}
            </Alert>
          )}

          {/* Formulaire de demande de réinitialisation */}
          {mode === 'request' && (
            <Box component="form" onSubmit={handleRequestReset} sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Email color="action" />
                    </InputAdornment>
                  )
                }}
                disabled={loading}
              />

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={loading}
                sx={{ py: 1.5, fontSize: '1.1rem' }}
              >
                {loading ? <CircularProgress size={24} /> : 'Envoyer le lien de réinitialisation'}
              </Button>

              <Box sx={{ textAlign: 'center' }}>
                <Link
                  component="button"
                  variant="body2"
                  onClick={() => navigate('/auth')}
                  sx={{ textDecoration: 'none' }}
                >
                  Retour à la connexion
                </Link>
              </Box>
            </Box>
          )}

          {/* Formulaire de réinitialisation */}
          {mode === 'reset' && (
            <Box component="form" onSubmit={handleResetPassword} sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              <FormControl fullWidth error={!!formErrors.newPassword}>
                <InputLabel>Nouveau mot de passe</InputLabel>
                <OutlinedInput
                  type={showPassword ? 'text' : 'password'}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  endAdornment={
                    <InputAdornment position="end">
                      <IconButton
                        aria-label="toggle password visibility"
                        onClick={() => setShowPassword(!showPassword)}
                        edge="end"
                      >
                        {showPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  }
                  startAdornment={
                    <InputAdornment position="start">
                      <Lock color="action" />
                    </InputAdornment>
                  }
                  label="Nouveau mot de passe"
                  disabled={loading}
                />
                {formErrors.newPassword && (
                  <Typography variant="caption" color="error" sx={{ mt: 1, ml: 2 }}>
                    {formErrors.newPassword}
                  </Typography>
                )}
              </FormControl>

              {/* Critères de validation du mot de passe */}
              {newPassword && passwordValidation && (
                <Box sx={{ p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
                  <Typography variant="caption" color="text.secondary" display="block" gutterBottom>
                    Critères du mot de passe :
                  </Typography>
                  <Typography variant="caption" color={passwordValidation.length ? 'success.main' : 'error.main'} display="block">
                    • Au moins 8 caractères
                  </Typography>
                  <Typography variant="caption" color={passwordValidation.uppercase ? 'success.main' : 'error.main'} display="block">
                    • Une majuscule
                  </Typography>
                  <Typography variant="caption" color={passwordValidation.lowercase ? 'success.main' : 'error.main'} display="block">
                    • Une minuscule
                  </Typography>
                  <Typography variant="caption" color={passwordValidation.number ? 'success.main' : 'error.main'} display="block">
                    • Un chiffre
                  </Typography>
                  <Typography variant="caption" color={passwordValidation.special ? 'success.main' : 'error.main'} display="block">
                    • Un caractère spécial
                  </Typography>
                </Box>
              )}

              <FormControl fullWidth error={!!formErrors.confirmPassword}>
                <InputLabel>Confirmer le nouveau mot de passe</InputLabel>
                <OutlinedInput
                  type={showConfirmPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  endAdornment={
                    <InputAdornment position="end">
                      <IconButton
                        aria-label="toggle confirm password visibility"
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        edge="end"
                      >
                        {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  }
                  startAdornment={
                    <InputAdornment position="start">
                      <Lock color="action" />
                    </InputAdornment>
                  }
                  label="Confirmer le nouveau mot de passe"
                  disabled={loading}
                />
                {formErrors.confirmPassword && (
                  <Typography variant="caption" color="error" sx={{ mt: 1, ml: 2 }}>
                    {formErrors.confirmPassword}
                  </Typography>
                )}
              </FormControl>

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={loading || (passwordValidation && !Object.values(passwordValidation).every(Boolean))}
                sx={{ py: 1.5, fontSize: '1.1rem' }}
              >
                {loading ? <CircularProgress size={24} /> : 'Mettre à jour le mot de passe'}
              </Button>

              <Box sx={{ textAlign: 'center' }}>
                <Link
                  component="button"
                  variant="body2"
                  onClick={() => navigate('/auth')}
                  sx={{ textDecoration: 'none' }}
                >
                  Retour à la connexion
                </Link>
              </Box>
            </Box>
          )}
        </CardContent>
      </Card>
    </Box>
  );
};

export default ResetPassword;
