import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Alert,
  CircularProgress,
  Container,
  Paper,
  Chip,
  Button,
} from '@mui/material';
import {
  Build as BuildIcon,
  ArrowBack as ArrowBackIcon,
  CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import { toast } from 'react-hot-toast';
import QuoteRequestForm from '../../components/QuoteRequest/QuoteRequestForm';

interface TechnicianInfo {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  companyName?: string;
  address?: string;
}

interface CustomUrlData {
  id: string;
  technicianId: string;
  customUrl: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const QuoteRequestPage: React.FC = () => {
  const { customUrl } = useParams<{ customUrl: string }>();
  const navigate = useNavigate();
  
  const [technicianInfo, setTechnicianInfo] = useState<TechnicianInfo | null>(null);
  const [customUrlData, setCustomUrlData] = useState<CustomUrlData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isSuccess, setIsSuccess] = useState(false);

  useEffect(() => {
    const fetchTechnicianData = async () => {
      if (!customUrl) {
        setError('URL invalide');
        setIsLoading(false);
        return;
      }

      try {
        setIsLoading(true);
        
        // Simuler l'appel API pour récupérer les données du réparateur
        // À remplacer par l'appel réel à Supabase
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Données simulées - à remplacer par l'appel API réel
        const mockTechnicianInfo: TechnicianInfo = {
          id: '123e4567-e89b-12d3-a456-426614174000',
          firstName: 'Jean',
          lastName: 'Dupont',
          email: 'jean.dupont@atelier.com',
          phone: '01 23 45 67 89',
          companyName: 'Atelier Réparation Express',
          address: '123 Rue de la Réparation, 75001 Paris',
        };

        const mockCustomUrlData: CustomUrlData = {
          id: '123e4567-e89b-12d3-a456-426614174001',
          technicianId: mockTechnicianInfo.id,
          customUrl: customUrl,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        };

        setTechnicianInfo(mockTechnicianInfo);
        setCustomUrlData(mockCustomUrlData);
        
      } catch (err) {
        console.error('Erreur lors du chargement des données:', err);
        setError('Impossible de charger les informations du réparateur');
        toast.error('Erreur lors du chargement des données');
      } finally {
        setIsLoading(false);
      }
    };

    fetchTechnicianData();
  }, [customUrl]);

  const handleSuccess = (request: any) => {
    setIsSuccess(true);
    toast.success('Demande envoyée avec succès !');
  };

  const handleGoBack = () => {
    navigate(-1);
  };

  if (isLoading) {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        }}
      >
        <Box sx={{ textAlign: 'center', color: 'white' }}>
          <CircularProgress size={60} sx={{ color: 'white', mb: 2 }} />
          <Typography variant="h6">
            Chargement des informations...
          </Typography>
        </Box>
      </Box>
    );
  }

  if (error || !technicianInfo || !customUrlData) {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          p: 3,
        }}
      >
        <Container maxWidth="sm">
          <Paper
            sx={{
              p: 4,
              textAlign: 'center',
              borderRadius: 3,
              boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
            }}
          >
            <Alert severity="error" sx={{ mb: 3 }}>
              {error || 'Réparateur non trouvé'}
            </Alert>
            <Typography variant="h6" gutterBottom>
              URL invalide ou réparateur non disponible
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
              L'URL que vous avez utilisée n'est pas valide ou le réparateur n'est plus disponible.
            </Typography>
            <Button
              variant="contained"
              startIcon={<ArrowBackIcon />}
              onClick={handleGoBack}
            >
              Retour
            </Button>
          </Paper>
        </Container>
      </Box>
    );
  }

  if (isSuccess) {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          p: 3,
        }}
      >
        <Container maxWidth="sm">
          <Paper
            sx={{
              p: 4,
              textAlign: 'center',
              borderRadius: 3,
              boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
            }}
          >
            <CheckCircleIcon sx={{ fontSize: 80, color: 'success.main', mb: 2 }} />
            <Typography variant="h4" gutterBottom color="success.main">
              Demande envoyée !
            </Typography>
            <Typography variant="h6" color="text.secondary" sx={{ mb: 3 }}>
              Votre demande de devis a été transmise à {technicianInfo.firstName} {technicianInfo.lastName}
            </Typography>
            <Typography variant="body1" sx={{ mb: 3 }}>
              Vous recevrez une réponse dans les plus brefs délais. 
              Une confirmation vous a été envoyée par email.
            </Typography>
            <Button
              variant="contained"
              onClick={() => window.location.reload()}
              sx={{ mr: 2 }}
            >
              Faire une nouvelle demande
            </Button>
            <Button
              variant="outlined"
              onClick={handleGoBack}
            >
              Retour
            </Button>
          </Paper>
        </Container>
      </Box>
    );
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        p: 3,
      }}
    >
      <Container maxWidth="sm">
        <Paper
          sx={{
            p: 6,
            textAlign: 'center',
            borderRadius: 3,
            boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
            background: 'rgba(255,255,255,0.95)',
            backdropFilter: 'blur(10px)',
          }}
        >
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 80,
              height: 80,
              borderRadius: '50%',
              background: 'linear-gradient(135deg, #ff9800 0%, #f57c00 100%)',
              color: 'white',
              mx: 'auto',
              mb: 3,
            }}
          >
            <BuildIcon sx={{ fontSize: 40 }} />
          </Box>
          
          <Typography variant="h4" gutterBottom sx={{ fontWeight: 700, color: '#ff9800' }}>
            🚧 Page en cours de développement
          </Typography>
          
          <Typography variant="h6" color="text.secondary" sx={{ mb: 3 }}>
            La fonctionnalité de demande de devis est temporairement indisponible
          </Typography>
          
          <Alert severity="info" sx={{ mb: 4, textAlign: 'left' }}>
            <Typography variant="body1" sx={{ fontWeight: 500, mb: 1 }}>
              Nous travaillons actuellement sur l'amélioration de cette fonctionnalité.
            </Typography>
            <Typography variant="body2">
              Cette page sera bientôt disponible avec de nouvelles fonctionnalités pour faciliter vos demandes de devis.
            </Typography>
          </Alert>

          <Box sx={{ mb: 4 }}>
            <Typography variant="body1" sx={{ fontWeight: 500, mb: 2 }}>
              En attendant, vous pouvez :
            </Typography>
            <Box sx={{ textAlign: 'left', maxWidth: 400, mx: 'auto' }}>
              <Typography variant="body2" sx={{ mb: 1 }}>
                • Nous contacter directement par téléphone
              </Typography>
              <Typography variant="body2" sx={{ mb: 1 }}>
                • Envoyer un email avec vos besoins
              </Typography>
              <Typography variant="body2" sx={{ mb: 1 }}>
                • Visiter notre atelier en personne
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, alignItems: 'center' }}>
            <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
              Merci de votre compréhension
            </Typography>
            <Button
              variant="contained"
              startIcon={<ArrowBackIcon />}
              onClick={handleGoBack}
              sx={{ 
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                '&:hover': {
                  background: 'linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)',
                }
              }}
            >
              Retour
            </Button>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default QuoteRequestPage;
