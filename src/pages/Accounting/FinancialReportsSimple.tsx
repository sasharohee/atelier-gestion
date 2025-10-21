import React from 'react';
import { Box, Typography, Alert } from '@mui/material';

const FinancialReportsSimple: React.FC = () => {
  return (
    <Box>
      <Typography variant="h5" gutterBottom sx={{ mb: 3, fontWeight: 'medium' }}>
        Rapports Financiers
      </Typography>
      
      <Alert severity="info">
        Fonctionnalité en cours de développement. 
        Les rapports financiers seront générés ici.
      </Alert>
    </Box>
  );
};

export default FinancialReportsSimple;
