import React from 'react';
import { Box, Typography, Alert } from '@mui/material';

const InvoicesManagementSimple: React.FC = () => {
  return (
    <Box>
      <Typography variant="h5" gutterBottom sx={{ mb: 3, fontWeight: 'medium' }}>
        Gestion des Factures
      </Typography>
      
      <Alert severity="info">
        Fonctionnalité en cours de développement. 
        La gestion des factures sera disponible ici.
      </Alert>
    </Box>
  );
};

export default InvoicesManagementSimple;
