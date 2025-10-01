import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Alert,
  CircularProgress,
  Container,
  Paper,
  InputAdornment,
  IconButton
} from '@mui/material';
import {
  Lock as LockIcon,
  Visibility,
  VisibilityOff,
  Security as SecurityIcon
} from '@mui/icons-material';

interface AdminPasswordGuardProps {
  children: React.ReactNode;
}

const AdminPasswordGuard: React.FC<AdminPasswordGuardProps> = ({ children }) => {
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [attempts, setAttempts] = useState(0);

  // Mot de passe admin sécurisé (utilise la variable d'environnement ou un fallback)
  const ADMIN_PASSWORD = import.meta.env.VITE_ADMIN_PASSWORD || 'At3l13r@dm1n#2024$ecur3!';

  // Vérifier si l'utilisateur est déjà authentifié (session locale)
  useEffect(() => {
    const isAdminAuthenticated = sessionStorage.getItem('admin_authenticated');
    if (isAdminAuthenticated === 'true') {
      setIsAuthenticated(true);
    }
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    // Simuler un délai de vérification
    await new Promise(resolve => setTimeout(resolve, 1000));

    if (password === ADMIN_PASSWORD) {
      setIsAuthenticated(true);
      sessionStorage.setItem('admin_authenticated', 'true');
      setPassword('');
      setAttempts(0);
    } else {
      setAttempts(prev => prev + 1);
      setError('Mot de passe incorrect');
      
      // Bloquer temporairement après 3 tentatives
      if (attempts >= 2) {
        setError('Trop de tentatives. Veuillez attendre 30 secondes avant de réessayer.');
        setTimeout(() => {
          setAttempts(0);
          setError(null);
        }, 30000);
      }
    }

    setIsLoading(false);
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    sessionStorage.removeItem('admin_authenticated');
    setPassword('');
    setError(null);
    setAttempts(0);
  };

  // Si authentifié, afficher le contenu protégé
  if (isAuthenticated) {
    return (
      <Box>
        {/* Barre de déconnexion */}
        <Box sx={{ 
          position: 'fixed', 
          top: 16, 
          right: 16, 
          zIndex: 1000,
          bgcolor: 'background.paper',
          borderRadius: 1,
          boxShadow: 2,
          p: 1
        }}>
          <Button
            variant="outlined"
            size="small"
            onClick={handleLogout}
            startIcon={<LockIcon />}
            color="error"
          >
            Déconnexion Admin
          </Button>
        </Box>
        {children}
      </Box>
    );
  }

  // Interface de connexion
  return (
    <Box sx={{ 
      minHeight: '100vh', 
      bgcolor: 'grey.50',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      p: 2
    }}>
      <Container maxWidth="sm">
        <Paper elevation={3} sx={{ p: 4 }}>
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <SecurityIcon sx={{ fontSize: 64, color: 'primary.main', mb: 2 }} />
            <Typography variant="h4" component="h1" gutterBottom>
              Accès Administrateur
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Cette page est protégée par un mot de passe
            </Typography>
          </Box>

          <Card variant="outlined">
            <CardContent>
              <form onSubmit={handleSubmit}>
                <TextField
                  fullWidth
                  label="Mot de passe administrateur"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={isLoading || attempts >= 3}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <LockIcon color="action" />
                      </InputAdornment>
                    ),
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton
                          onClick={() => setShowPassword(!showPassword)}
                          edge="end"
                          disabled={isLoading}
                        >
                          {showPassword ? <VisibilityOff /> : <Visibility />}
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                  sx={{ mb: 3 }}
                  autoFocus
                />

                {error && (
                  <Alert severity="error" sx={{ mb: 3 }}>
                    {error}
                  </Alert>
                )}

                <Button
                  type="submit"
                  fullWidth
                  variant="contained"
                  size="large"
                  disabled={isLoading || !password.trim() || attempts >= 3}
                  startIcon={isLoading ? <CircularProgress size={20} /> : <SecurityIcon />}
                >
                  {isLoading ? 'Vérification...' : 'Accéder à l\'administration'}
                </Button>
              </form>
            </CardContent>
          </Card>

          <Box sx={{ mt: 3, textAlign: 'center' }}>
            <Typography variant="caption" color="text.secondary">
              {attempts >= 3 ? 'Accès temporairement bloqué' : `${attempts}/3 tentatives`}
            </Typography>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default AdminPasswordGuard;
