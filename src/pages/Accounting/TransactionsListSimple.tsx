import React from 'react';
import { Box, Typography, Alert } from '@mui/material';

const TransactionsListSimple: React.FC = () => {
  return (
    <Box>
      <Typography variant="h5" gutterBottom sx={{ mb: 3, fontWeight: 'medium' }}>
        Liste des Transactions
      </Typography>
      
      <Alert severity="info">
        Fonctionnalité en cours de développement. 
        Les transactions seront affichées ici une fois les données configurées.
      </Alert>
    </Box>
  );
};

export default TransactionsListSimple;
