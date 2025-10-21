import React from 'react';
import { Box, Typography, Alert } from '@mui/material';

const ExportsCenterSimple: React.FC = () => {
  return (
    <Box>
      <Typography variant="h5" gutterBottom sx={{ mb: 3, fontWeight: 'medium' }}>
        Centre d'Exports
      </Typography>
      
      <Alert severity="info">
        Fonctionnalité en cours de développement. 
        Les options d'export seront disponibles ici.
      </Alert>
    </Box>
  );
};

export default ExportsCenterSimple;
