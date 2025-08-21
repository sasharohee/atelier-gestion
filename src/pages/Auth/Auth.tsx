import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Paper,
  TextField,
  Button,
  Typography,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  InputAdornment,
  IconButton,
  Divider,
  Link,
  useTheme,
  useMediaQuery
} from '@mui/material';
import {
  Visibility,
  VisibilityOff,
  Email,
  Lock,
  Person,
  Phone,
  Business,
  CheckCircle,
  Error
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { userService } from '../../services/supabaseService';
import { useAuth } from '../../hooks/useAuth';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`auth-tabpanel-${index}`}
      aria-labelledby={`auth-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ pt: 3 }}>{children}</Box>}
    </div>
  );
}

const Auth: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const navigate = useNavigate();
  const location = useLocation();
  const { isAuthenticated } = useAuth();
  
  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // Login form
  const [loginForm, setLoginForm] = useState({
    email: '',
    password: ''
  });

  // Register form
  const [registerForm, setRegisterForm] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    company: '',
    password: '',
    confirmPassword: ''
  });

  // Password validation
  const [passwordValidation, setPasswordValidation] = useState({
    length: false,
    uppercase: false,
    lowercase: false,
    number: false,
    special: false
  });

  useEffect(() => {
    // Rediriger si l'utilisateur est déjà connecté
    if (isAuthenticated) {
      const from = location.state?.from?.pathname || '/app/dashboard';
      navigate(from, { replace: true });
    }
  }, [isAuthenticated, navigate, location.state]);

  // Validation du mot de passe
  useEffect(() => {
    const password = registerForm.password;
    setPasswordValidation({
      length: password.length >= 8,
      uppercase: /[A-Z]/.test(password),
      lowercase: /[a-z]/.test(password),
      number: /\d/.test(password),
      special: /[!@#$%^&*(),.?":{}|<>]/.test(password)
    });
  }, [registerForm.password]);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
    setError(null);
    setSuccess(null);
  };

  const handleLoginChange = (field: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setLoginForm(prev => ({ ...prev, [field]: event.target.value }));
    setError(null);
  };

  const handleRegisterChange = (field: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setRegisterForm(prev => ({ ...prev, [field]: event.target.value }));
    setError(null);
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const result = await userService.signIn(loginForm.email, loginForm.password);
      
      if (result.success) {
        setSuccess('Connexion réussie ! Redirection...');
        const from = location.state?.from?.pathname || '/app/dashboard';
        setTimeout(() => {
          navigate(from, { replace: true });
        }, 1000);
      } else {
        setError('Erreur lors de la connexion');
      }
    } catch (err) {
      setError('Erreur lors de la connexion');
      console.error('Login error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    // Validation
    if (registerForm.password !== registerForm.confirmPassword) {
      setError('Les mots de passe ne correspondent pas');
      setLoading(false);
      return;
    }

    if (!Object.values(passwordValidation).every(Boolean)) {
      setError('Le mot de passe ne respecte pas les critères de sécurité');
      setLoading(false);
      return;
    }

    try {
      const result = await userService.signUp(
        registerForm.email,
        registerForm.password,
        {
          firstName: registerForm.firstName,
          lastName: registerForm.lastName,
          role: 'technician'
        }
      );

      if (result.success) {
        setSuccess('Inscription réussie ! Vérifiez votre email pour confirmer votre compte.');
        setRegisterForm({
          firstName: '',
          lastName: '',
          email: '',
          phone: '',
          company: '',
          password: '',
          confirmPassword: ''
        });
      } else {
        setError('Erreur lors de l\'inscription');
      }
    } catch (err) {
      setError('Erreur lors de l\'inscription');
      console.error('Register error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    if (!loginForm.email) {
      setError('Veuillez saisir votre adresse email');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const { error } = await supabase.auth.resetPasswordForEmail(loginForm.email, {
        redirectTo: `${window.location.origin}/auth?tab=reset`
      });

      if (error) {
        setError(error.message);
      } else {
        setSuccess('Un email de réinitialisation a été envoyé à votre adresse email');
      }
    } catch (err) {
      setError('Erreur lors de l\'envoi de l\'email de réinitialisation');
    } finally {
      setLoading(false);
    }
  };

  const isPasswordValid = Object.values(passwordValidation).every(Boolean);

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 50%, ${theme.palette.secondary.main} 100%)`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        p: 2
      }}
    >
      <Container maxWidth="sm">
        <Paper
          elevation={24}
          sx={{
            p: { xs: 3, md: 4 },
            borderRadius: 3,
            background: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(20px)',
            border: '1px solid rgba(255, 255, 255, 0.2)'
          }}
        >
          {/* Header */}
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <Typography
              variant="h4"
              component="h1"
              sx={{
                fontWeight: 700,
                color: theme.palette.primary.main,
                mb: 1
              }}
            >
              Atelier Gestion
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Connectez-vous à votre espace de travail
            </Typography>
          </Box>

          {/* Tabs */}
          <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
            <Tabs
              value={tabValue}
              onChange={handleTabChange}
              variant="fullWidth"
              sx={{
                '& .MuiTab-root': {
                  fontWeight: 600,
                  fontSize: '1rem'
                }
              }}
            >
              <Tab label="Connexion" />
              <Tab label="Inscription" />
            </Tabs>
          </Box>

          {/* Error/Success Messages */}
          {error && (
            <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
              {error}
            </Alert>
          )}
          {success && (
            <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccess(null)}>
              {success}
            </Alert>
          )}

          {/* Login Tab */}
          <TabPanel value={tabValue} index={0}>
            <Box component="form" onSubmit={handleLogin}>
              <TextField
                fullWidth
                label="Adresse email"
                type="email"
                value={loginForm.email}
                onChange={handleLoginChange('email')}
                required
                sx={{ mb: 3 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Email color="action" />
                    </InputAdornment>
                  )
                }}
              />
              
              <TextField
                fullWidth
                label="Mot de passe"
                type={showPassword ? 'text' : 'password'}
                value={loginForm.password}
                onChange={handleLoginChange('password')}
                required
                sx={{ mb: 2 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Lock color="action" />
                    </InputAdornment>
                  ),
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        onClick={() => setShowPassword(!showPassword)}
                        edge="end"
                      >
                        {showPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  )
                }}
              />

              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Link
                  component="button"
                  variant="body2"
                  onClick={handleForgotPassword}
                  sx={{ textDecoration: 'none' }}
                >
                  Mot de passe oublié ?
                </Link>
              </Box>

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={loading}
                sx={{
                  py: 1.5,
                  fontSize: '1.1rem',
                  fontWeight: 600,
                  borderRadius: 2,
                  mb: 3
                }}
              >
                {loading ? <CircularProgress size={24} /> : 'Se connecter'}
              </Button>

              <Divider sx={{ my: 3 }}>
                <Typography variant="body2" color="text.secondary">
                  ou
                </Typography>
              </Divider>

              <Button
                fullWidth
                variant="outlined"
                size="large"
                onClick={() => setTabValue(1)}
                sx={{
                  py: 1.5,
                  fontSize: '1.1rem',
                  fontWeight: 600,
                  borderRadius: 2
                }}
              >
                Créer un compte
              </Button>
            </Box>
          </TabPanel>

          {/* Register Tab */}
          <TabPanel value={tabValue} index={1}>
            <Box component="form" onSubmit={handleRegister}>
              <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
                <TextField
                  fullWidth
                  label="Prénom"
                  value={registerForm.firstName}
                  onChange={handleRegisterChange('firstName')}
                  required
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <Person color="action" />
                      </InputAdornment>
                    )
                  }}
                />
                <TextField
                  fullWidth
                  label="Nom"
                  value={registerForm.lastName}
                  onChange={handleRegisterChange('lastName')}
                  required
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <Person color="action" />
                      </InputAdornment>
                    )
                  }}
                />
              </Box>

              <TextField
                fullWidth
                label="Adresse email"
                type="email"
                value={registerForm.email}
                onChange={handleRegisterChange('email')}
                required
                sx={{ mb: 3 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Email color="action" />
                    </InputAdornment>
                  )
                }}
              />

              <TextField
                fullWidth
                label="Téléphone (optionnel)"
                value={registerForm.phone}
                onChange={handleRegisterChange('phone')}
                sx={{ mb: 3 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Phone color="action" />
                    </InputAdornment>
                  )
                }}
              />

              <TextField
                fullWidth
                label="Entreprise (optionnel)"
                value={registerForm.company}
                onChange={handleRegisterChange('company')}
                sx={{ mb: 3 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Business color="action" />
                    </InputAdornment>
                  )
                }}
              />

              <TextField
                fullWidth
                label="Mot de passe"
                type={showPassword ? 'text' : 'password'}
                value={registerForm.password}
                onChange={handleRegisterChange('password')}
                required
                sx={{ mb: 2 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Lock color="action" />
                    </InputAdornment>
                  ),
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        onClick={() => setShowPassword(!showPassword)}
                        edge="end"
                      >
                        {showPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  )
                }}
              />

              {/* Password validation */}
              <Box sx={{ mb: 2 }}>
                <Typography variant="caption" color="text.secondary" sx={{ mb: 1, display: 'block' }}>
                  Le mot de passe doit contenir :
                </Typography>
                {[
                  { key: 'length', label: 'Au moins 8 caractères' },
                  { key: 'uppercase', label: 'Une lettre majuscule' },
                  { key: 'lowercase', label: 'Une lettre minuscule' },
                  { key: 'number', label: 'Un chiffre' },
                  { key: 'special', label: 'Un caractère spécial' }
                ].map(({ key, label }) => (
                  <Box key={key} sx={{ display: 'flex', alignItems: 'center', mb: 0.5 }}>
                    {passwordValidation[key as keyof typeof passwordValidation] ? (
                      <CheckCircle sx={{ fontSize: 16, color: 'success.main', mr: 1 }} />
                    ) : (
                      <Error sx={{ fontSize: 16, color: 'error.main', mr: 1 }} />
                    )}
                    <Typography variant="caption" color="text.secondary">
                      {label}
                    </Typography>
                  </Box>
                ))}
              </Box>

              <TextField
                fullWidth
                label="Confirmer le mot de passe"
                type={showConfirmPassword ? 'text' : 'password'}
                value={registerForm.confirmPassword}
                onChange={handleRegisterChange('confirmPassword')}
                required
                sx={{ mb: 3 }}
                error={registerForm.confirmPassword !== '' && registerForm.password !== registerForm.confirmPassword}
                helperText={
                  registerForm.confirmPassword !== '' && registerForm.password !== registerForm.confirmPassword
                    ? 'Les mots de passe ne correspondent pas'
                    : ''
                }
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Lock color="action" />
                    </InputAdornment>
                  ),
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        edge="end"
                      >
                        {showConfirmPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  )
                }}
              />

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={loading || !isPasswordValid}
                sx={{
                  py: 1.5,
                  fontSize: '1.1rem',
                  fontWeight: 600,
                  borderRadius: 2,
                  mb: 3
                }}
              >
                {loading ? <CircularProgress size={24} /> : 'Créer mon compte'}
              </Button>

              <Divider sx={{ my: 3 }}>
                <Typography variant="body2" color="text.secondary">
                  ou
                </Typography>
              </Divider>

              <Button
                fullWidth
                variant="outlined"
                size="large"
                onClick={() => setTabValue(0)}
                sx={{
                  py: 1.5,
                  fontSize: '1.1rem',
                  fontWeight: 600,
                  borderRadius: 2
                }}
              >
                J'ai déjà un compte
              </Button>
            </Box>
          </TabPanel>
        </Paper>
      </Container>
    </Box>
  );
};

export default Auth;
