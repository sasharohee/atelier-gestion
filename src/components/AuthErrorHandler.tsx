import React from 'react';
import { 
  Alert, 
  AlertTitle, 
  Button, 
  Box, 
  Typography,
  Paper
} from '@mui/material';
import { Refresh, Login, Clear } from '@mui/icons-material';
import { useAuth } from '../hooks/useAuth';

interface AuthErrorHandlerProps {
  children: React.ReactNode;
}

export const AuthErrorHandler: React.FC<AuthErrorHandlerProps> = ({ children }) => {
  const { authError, resetAuth, loading } = useAuth();

  if (!authError) {
    return <>{children}</>;
  }

  const handleReset = async () => {
    await resetAuth();
  };

  const handleClearError = () => {
    // Recharger la page pour nettoyer l'erreur
    window.location.reload();
  };

  const isTokenError = authError.includes('Invalid Refresh Token') || 
                      authError.includes('Refresh Token Not Found') ||
                      authError.includes('Session expirée');

  return (
    <Box
      sx={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 9999,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
        p: 2
      }}
    >
      <Paper
        elevation={24}
        sx={{
          p: 4,
          maxWidth: 500,
          width: '100%',
          borderRadius: 3,
          textAlign: 'center'
        }}
      >
        <Alert 
          severity="error" 
          sx={{ mb: 3 }}
          action={
            <Button
              color="inherit"
              size="small"
              onClick={handleClearError}
              startIcon={<Clear />}
            >
              Ignorer
            </Button>
          }
        >
          <AlertTitle>Erreur d'Authentification</AlertTitle>
          {authError}
        </Alert>

        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
          {isTokenError 
            ? "Votre session a expiré ou est invalide. Veuillez vous reconnecter."
            : "Une erreur s'est produite lors de l'authentification."
          }
        </Typography>

        <Box sx={{ display: 'flex', gap: 2, justifyContent: 'center', flexWrap: 'wrap' }}>
          <Button
            variant="contained"
            color="primary"
            onClick={handleReset}
            disabled={loading}
            startIcon={<Refresh />}
            sx={{ minWidth: 150 }}
          >
            {loading ? 'Réinitialisation...' : 'Réinitialiser'}
          </Button>

          <Button
            variant="outlined"
            color="primary"
            onClick={() => window.location.href = '/auth'}
            startIcon={<Login />}
            sx={{ minWidth: 150 }}
          >
            Se Connecter
          </Button>
        </Box>

        <Typography variant="caption" color="text.secondary" sx={{ mt: 2, display: 'block' }}>
          Si le problème persiste, essayez de vider le cache de votre navigateur.
        </Typography>
      </Paper>
    </Box>
  );
};
