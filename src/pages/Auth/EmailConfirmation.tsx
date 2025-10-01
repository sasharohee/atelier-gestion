import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Alert,
  Button,
  CircularProgress,
  Link
} from '@mui/material';
import { CheckCircle, Error, Email } from '@mui/icons-material';
import { useAuth } from '../../hooks/useAuth';

const EmailConfirmation: React.FC = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { resendConfirmation, loading } = useAuth();
  
  const [status, setStatus] = useState<'loading' | 'success' | 'error' | 'expired'>('loading');
  const [message, setMessage] = useState<string>('');
  const [email, setEmail] = useState<string>('');

  useEffect(() => {
    const token = searchParams.get('token');
    const email = searchParams.get('email');
    
    if (email) {
      setEmail(email);
    }

    if (!token) {
      setStatus('error');
      setMessage('Token de confirmation manquant ou invalide');
      return;
    }

    // Simuler la vérification du token
    // Dans un vrai projet, vous feriez un appel API pour vérifier le token
    setTimeout(() => {
      // Pour la démo, on simule un succès
      setStatus('success');
      setMessage('Votre email a été confirmé avec succès ! Vous pouvez maintenant vous connecter.');
    }, 2000);
  }, [searchParams]);

  const handleResendConfirmation = async () => {
    if (!email) {
      setMessage('Impossible de renvoyer l\'email : adresse email manquante');
      return;
    }

    const result = await resendConfirmation(email);
    if (result.success) {
      setMessage('Un nouvel email de confirmation a été envoyé.');
    } else {
      setMessage(result.error || 'Erreur lors du renvoi de l\'email');
    }
  };

  const handleGoToLogin = () => {
    navigate('/auth');
  };

  const getStatusIcon = () => {
    switch (status) {
      case 'loading':
        return <CircularProgress size={60} />;
      case 'success':
        return <CheckCircle sx={{ fontSize: 60, color: 'success.main' }} />;
      case 'error':
      case 'expired':
        return <Error sx={{ fontSize: 60, color: 'error.main' }} />;
      default:
        return <Email sx={{ fontSize: 60, color: 'primary.main' }} />;
    }
  };

  const getStatusColor = () => {
    switch (status) {
      case 'success':
        return 'success';
      case 'error':
      case 'expired':
        return 'error';
      default:
        return 'info';
    }
  };

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
        <CardContent sx={{ p: 4, textAlign: 'center' }}>
          {/* Icône de statut */}
          <Box sx={{ mb: 3 }}>
            {getStatusIcon()}
          </Box>

          {/* Titre */}
          <Typography variant="h4" component="h1" gutterBottom color="primary" fontWeight="bold">
            Confirmation d'Email
          </Typography>

          {/* Message */}
          {message && (
            <Alert severity={getStatusColor()} sx={{ mb: 3 }}>
              {message}
            </Alert>
          )}

          {/* Actions selon le statut */}
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {status === 'success' && (
              <Button
                variant="contained"
                size="large"
                onClick={handleGoToLogin}
                sx={{ py: 1.5 }}
              >
                Aller à la connexion
              </Button>
            )}

            {(status === 'error' || status === 'expired') && (
              <>
                <Button
                  variant="contained"
                  size="large"
                  onClick={handleResendConfirmation}
                  disabled={loading || !email}
                  sx={{ py: 1.5 }}
                >
                  {loading ? <CircularProgress size={24} /> : 'Renvoyer l\'email'}
                </Button>
                <Button
                  variant="outlined"
                  size="large"
                  onClick={handleGoToLogin}
                  sx={{ py: 1.5 }}
                >
                  Retour à la connexion
                </Button>
              </>
            )}

            {status === 'loading' && (
              <Typography variant="body1" color="text.secondary">
                Vérification en cours...
              </Typography>
            )}
          </Box>

          {/* Liens utiles */}
          <Box sx={{ mt: 4, pt: 3, borderTop: 1, borderColor: 'divider' }}>
            <Link
              component="button"
              variant="body2"
              onClick={() => navigate('/')}
              sx={{ textDecoration: 'none', mr: 2 }}
            >
              Retour à l'accueil
            </Link>
            <Link
              component="button"
              variant="body2"
              onClick={() => navigate('/auth')}
              sx={{ textDecoration: 'none' }}
            >
              Page de connexion
            </Link>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
};

export default EmailConfirmation;