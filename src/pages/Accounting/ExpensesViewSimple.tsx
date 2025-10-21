import React from 'react';
import { Box, Typography, Alert } from '@mui/material';

const ExpensesViewSimple: React.FC = () => {
  return (
    <Box>
      <Typography variant="h5" gutterBottom sx={{ mb: 3, fontWeight: 'medium' }}>
        Visualisation des Dépenses
      </Typography>
      
      <Alert severity="info">
        Fonctionnalité en cours de développement. 
        Les dépenses seront affichées ici.
      </Alert>
    </Box>
  );
};

export default ExpensesViewSimple;
