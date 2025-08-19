import React, { useState, useEffect } from 'react';
import {
  Alert,
  AlertTitle,
  Box,
  Button,
  Collapse,
  IconButton,
  Typography
} from '@mui/material';
import {
  Close as CloseIcon,
  Help as HelpIcon,
  CheckCircle as CheckCircleIcon
} from '@mui/icons-material';
import { demoDataService } from '../services/demoDataService';

interface OnboardingNotificationProps {
  onShowGuide: () => void;
}

export const OnboardingNotification: React.FC<OnboardingNotificationProps> = ({ onShowGuide }) => {
  const [show, setShow] = useState(false);
  const [isCompleted, setIsCompleted] = useState(false);

  useEffect(() => {
    // Vérifier si le guide a été complété
    const completed = demoDataService.isOnboardingCompleted();
    setIsCompleted(completed);
    
    // Afficher la notification si le guide n'a pas été complété
    if (!completed) {
      setShow(true);
    }
  }, []);

  const handleClose = () => {
    setShow(false);
  };

  const handleShowGuide = () => {
    onShowGuide();
    setShow(false);
  };

  if (!show) {
    return null;
  }

  return (
    <Collapse in={show}>
      <Box sx={{ position: 'fixed', top: 20, right: 20, zIndex: 1300, maxWidth: 400 }}>
        <Alert
          severity="info"
          action={
            <IconButton
              aria-label="close"
              color="inherit"
              size="small"
              onClick={handleClose}
            >
              <CloseIcon fontSize="inherit" />
            </IconButton>
          }
          icon={<HelpIcon />}
          sx={{
            boxShadow: 3,
            borderRadius: 2,
            '& .MuiAlert-message': {
              width: '100%'
            }
          }}
        >
          <AlertTitle>
            Bienvenue dans votre atelier !
          </AlertTitle>
          <Typography variant="body2" sx={{ mb: 2 }}>
            Pour commencer à utiliser votre atelier de gestion, nous vous recommandons de suivre le guide d'intégration qui vous présentera toutes les fonctionnalités avec des données de démonstration.
          </Typography>
          <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
            <Button
              size="small"
              variant="contained"
              startIcon={<HelpIcon />}
              onClick={handleShowGuide}
            >
              Commencer le guide
            </Button>
            <Button
              size="small"
              variant="outlined"
              onClick={handleClose}
            >
              Plus tard
            </Button>
          </Box>
        </Alert>
      </Box>
    </Collapse>
  );
};
