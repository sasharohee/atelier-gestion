import React, { useState } from 'react';
import {
  Button,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Typography,
  Box,
  Alert
} from '@mui/material';
import {
  Help,
  Refresh,
  Warning
} from '@mui/icons-material';
import { OnboardingGuide } from './OnboardingGuide';

interface GuideButtonProps {
  variant?: 'text' | 'outlined' | 'contained';
  size?: 'small' | 'medium' | 'large';
  color?: 'primary' | 'secondary' | 'error' | 'info' | 'success' | 'warning';
}

export const GuideButton: React.FC<GuideButtonProps> = ({ 
  variant = 'outlined', 
  size = 'medium',
  color = 'primary'
}) => {
  const [showGuide, setShowGuide] = useState(false);
  const [showResetDialog, setShowResetDialog] = useState(false);

  const handleOpenGuide = () => {
    setShowGuide(true);
  };

  const handleCloseGuide = () => {
    setShowGuide(false);
  };

  const handleResetGuide = () => {
    setShowResetDialog(true);
  };

  const handleConfirmReset = () => {
    // Réinitialiser le guide
    localStorage.removeItem('onboarding-completed');
    setShowResetDialog(false);
    setShowGuide(true);
  };

  const handleCancelReset = () => {
    setShowResetDialog(false);
  };

  return (
    <>
      <Tooltip title="Relancer le guide d'intégration">
        <Button
          variant={variant}
          size={size}
          color={color}
          startIcon={<Help />}
          onClick={handleOpenGuide}
          sx={{ minWidth: 'auto' }}
        >
          Guide
        </Button>
      </Tooltip>

      {/* Dialog de confirmation pour réinitialiser le guide */}
      <Dialog
        open={showResetDialog}
        onClose={handleCancelReset}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Warning color="warning" />
            <Typography variant="h6">
              Relancer le guide d'intégration
            </Typography>
          </Box>
        </DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            <Typography variant="body2">
              Attention : Relancer le guide va ajouter à nouveau toutes les données de démonstration.
            </Typography>
          </Alert>
          <Typography paragraph>
            Cela va ajouter :
          </Typography>
          <Box component="ul" sx={{ pl: 2 }}>
            <Typography component="li">1 client de démonstration</Typography>
            <Typography component="li">3 appareils différents</Typography>
            <Typography component="li">5 services de réparation</Typography>
            <Typography component="li">10 pièces détachées</Typography>
            <Typography component="li">5 produits en vente</Typography>
            <Typography component="li">2 réparations d'exemple</Typography>
            <Typography component="li">1 vente de démonstration</Typography>
          </Box>
          <Typography variant="body2" color="text.secondary">
            Les données existantes ne seront pas supprimées, mais de nouvelles données seront ajoutées.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCancelReset}>
            Annuler
          </Button>
          <Button 
            onClick={handleConfirmReset}
            variant="contained"
            color="primary"
            startIcon={<Refresh />}
          >
            Relancer le guide
          </Button>
        </DialogActions>
      </Dialog>

      {/* Guide d'intégration */}
      <OnboardingGuide 
        open={showGuide} 
        onClose={handleCloseGuide} 
      />
    </>
  );
};
