import React from 'react';
import { Box, Typography, Button, Paper } from '@mui/material';
import { MonetizationOn as MonetizationOnIcon } from '@mui/icons-material';

const BuybackSimple: React.FC = () => {
  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <MonetizationOnIcon sx={{ color: '#10b981' }} />
        Rachat d'appareils
      </Typography>
      
      <Paper sx={{ p: 3, mt: 2 }}>
        <Typography variant="h6" gutterBottom>
          Page de rachat d'appareils
        </Typography>
        <Typography variant="body1" sx={{ mb: 3 }}>
          Cette page permet aux réparateurs de racheter des appareils auprès des clients.
          Fonctionnalités à venir :
        </Typography>
        <ul>
          <li>Formulaire complet de rachat d'appareils</li>
          <li>Gestion des informations clients</li>
          <li>Évaluation de l'état technique</li>
          <li>Génération de tickets de rachat</li>
          <li>Suivi des rachats</li>
        </ul>
        <Button 
          variant="contained" 
          sx={{ mt: 2, backgroundColor: '#10b981', '&:hover': { backgroundColor: '#059669' } }}
          disabled
        >
          Nouveau rachat (bientôt disponible)
        </Button>
      </Paper>
    </Box>
  );
};

export default BuybackSimple;
