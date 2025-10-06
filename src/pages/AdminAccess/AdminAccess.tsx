import React from 'react';
import { Box, Typography, Container, AppBar, Toolbar } from '@mui/material';
import { Security as SecurityIcon } from '@mui/icons-material';
import UserAccessManagement from '../Administration/UserAccessManagement';

const AdminAccess: React.FC = () => {
  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'grey.50' }}>
      {/* Header */}
      <AppBar position="static" elevation={0}>
        <Toolbar>
          <SecurityIcon sx={{ mr: 2 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Gestion des Accès Utilisateurs
          </Typography>
          <Typography variant="body2" color="inherit">
            Interface d'administration
          </Typography>
        </Toolbar>
      </AppBar>

      <Container maxWidth="xl" sx={{ py: 0 }}>
        <UserAccessManagement />
      </Container>
    </Box>
  );
};

export default AdminAccess;