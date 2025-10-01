import React from 'react';
import { Box, Typography, Button } from '@mui/material';

const QuoteRequestsManagementTest: React.FC = () => {
  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Test - Demandes de Devis
      </Typography>
      <Typography variant="body1" sx={{ mb: 3 }}>
        Page de test pour vérifier que le problème vient du fichier principal.
      </Typography>
      <Button variant="contained" color="primary">
        Bouton de test
      </Button>
    </Box>
  );
};

export default QuoteRequestsManagementTest;
