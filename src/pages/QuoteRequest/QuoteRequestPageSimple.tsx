import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
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

const QuoteRequestPageSimple: React.FC = () => {
  const { customUrl } = useParams<{ customUrl: string }>();
  
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isSuccess, setIsSuccess] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      if (!customUrl) {
        setError('URL invalide');
        setIsLoading(false);
        return;
      }

      try {
        setIsLoading(true);
        
        // Simuler le chargement
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Vérifier que l'URL est valide
        if (customUrl.length < 3) {
          setError('URL personnalisée invalide');
          return;
        }
        
        console.log('✅ URL personnalisée chargée:', customUrl);
        
      } catch (err) {
        console.error('Erreur lors du chargement:', err);
        setError('Erreur lors du chargement des données');
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, [customUrl]);

  const handleSuccess = () => {
    setIsSuccess(true);
    toast.success('Demande envoyée avec succès !');
  };

  if (isLoading) {
    return (
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        flexDirection: 'column',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
      }}>
        <CircularProgress size={60} sx={{ color: 'white', mb: 2 }} />
        <Typography variant="h6" sx={{ color: 'white' }}>
          Chargement de la page de demande de devis...
        </Typography>
        <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.8)', mt: 1 }}>
          URL: {customUrl}
        </Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        flexDirection: 'column',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
      }}>
        <Alert severity="error" sx={{ mb: 2, maxWidth: 500 }}>
          <Typography variant="h6">Erreur</Typography>
          <Typography>{error}</Typography>
        </Alert>
        <Button 
          variant="contained" 
          onClick={() => window.location.reload()}
          sx={{ bgcolor: 'white', color: '#667eea' }}
        >
          Réessayer
        </Button>
      </Box>
    );
  }

  if (isSuccess) {
    return (
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        flexDirection: 'column',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
      }}>
        <CheckCircleIcon sx={{ fontSize: 80, color: 'white', mb: 2 }} />
        <Typography variant="h4" sx={{ color: 'white', mb: 2, textAlign: 'center' }}>
          Demande envoyée !
        </Typography>
        <Typography variant="h6" sx={{ color: 'rgba(255,255,255,0.9)', textAlign: 'center', mb: 3 }}>
          Votre demande de devis a été transmise avec succès à Jean Dupont
        </Typography>
        <Typography variant="body1" sx={{ color: 'rgba(255,255,255,0.8)', textAlign: 'center' }}>
          Vous recevrez une réponse dans les plus brefs délais
        </Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ 
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      py: 4
    }}>
      <Container maxWidth="md">
        {/* Header avec informations du réparateur */}
        <Paper sx={{ 
          p: 4, 
          mb: 3, 
          borderRadius: 3,
          background: 'rgba(255,255,255,0.95)',
          backdropFilter: 'blur(10px)'
        }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
            <Box sx={{ 
              width: 60, 
              height: 60, 
              borderRadius: '50%', 
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontSize: 24
            }}>
              🔧
            </Box>
            <Box>
              <Typography variant="h4" sx={{ color: '#333', fontWeight: 600 }}>
                Atelier Réparation Express
              </Typography>
              <Typography variant="body1" sx={{ color: '#666' }}>
                Demande de devis en ligne
              </Typography>
            </Box>
            <Chip 
              label="Actif" 
              color="success" 
              sx={{ ml: 'auto' }}
            />
          </Box>
          
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3, mb: 2 }}>
            <Box>
              <Typography variant="body2" sx={{ color: '#666' }}>
                <strong>Réparateur:</strong> Jean Dupont
              </Typography>
            </Box>
            <Box>
              <Typography variant="body2" sx={{ color: '#666' }}>
                <strong>Téléphone:</strong> 01 23 45 67 89
              </Typography>
            </Box>
            <Box>
              <Typography variant="body2" sx={{ color: '#666' }}>
                <strong>URL:</strong> {customUrl}
              </Typography>
            </Box>
          </Box>
          
          <Typography variant="body2" sx={{ color: '#666' }}>
            Remplissez le formulaire ci-dessous pour obtenir un devis personnalisé pour votre réparation.
            Nous vous contacterons dans les plus brefs délais.
          </Typography>
        </Paper>

        {/* Formulaire de demande de devis */}
        <Paper sx={{ 
          borderRadius: 3,
          overflow: 'hidden',
          background: 'rgba(255,255,255,0.95)',
          backdropFilter: 'blur(10px)'
        }}>
          <Box sx={{ 
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white',
            p: 4,
            textAlign: 'center'
          }}>
            <Typography variant="h5" sx={{ mb: 1 }}>
              Demande de Devis
            </Typography>
            <Typography variant="body1" sx={{ opacity: 0.9 }}>
              Remplissez ce formulaire pour obtenir un devis personnalisé
            </Typography>
          </Box>

          <Box sx={{ p: 4 }}>
            <Alert severity="info" sx={{ mb: 3 }}>
              <Typography variant="body2">
                <strong>Page de test fonctionnelle !</strong><br/>
                URL personnalisée: <code>{customUrl}</code><br/>
                Cette page simule le formulaire de demande de devis.
              </Typography>
            </Alert>

            <Box sx={{ 
              border: '2px dashed #e0e0e0',
              borderRadius: 2,
              p: 4,
              textAlign: 'center',
              mb: 3
            }}>
              <BuildIcon sx={{ fontSize: 48, color: '#667eea', mb: 2 }} />
              <Typography variant="h6" sx={{ mb: 2 }}>
                Formulaire de Demande de Devis
              </Typography>
              <Typography variant="body2" sx={{ color: '#666', mb: 3 }}>
                Ici serait affiché le formulaire complet avec tous les champs :
                nom, email, téléphone, description du problème, upload de fichiers, etc.
              </Typography>
              
              <Button 
                variant="contained" 
                size="large"
                onClick={handleSuccess}
                sx={{ 
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  px: 4,
                  py: 1.5
                }}
              >
                📤 Simuler l'envoi de la demande
              </Button>
            </Box>

            <Box sx={{ 
              background: '#f8f9fa',
              borderRadius: 2,
              p: 3,
              border: '1px solid #e0e0e0'
            }}>
              <Typography variant="body2" sx={{ color: '#666' }}>
                <strong>Informations techniques :</strong><br/>
                • URL personnalisée : {customUrl}<br/>
                • Réparateur : Jean Dupont (ID: 123e4567-e89b-12d3-a456-426614174000)<br/>
                • Statut : Actif<br/>
                • Page générée dynamiquement
              </Typography>
            </Box>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default QuoteRequestPageSimple;

