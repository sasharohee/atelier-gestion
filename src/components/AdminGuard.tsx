import React from 'react';
import { Navigate } from 'react-router-dom';
import { Box, Card, CardContent, Typography, CircularProgress } from '@mui/material';
import { AdminPanelSettings as AdminIcon } from '@mui/icons-material';
import { useAuth } from '../hooks/useAuth';

interface AdminGuardProps {
  children: React.ReactNode;
}

const AdminGuard: React.FC<AdminGuardProps> = ({ children }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  // Vérifier si l'utilisateur est connecté et a le rôle d'administrateur
  const isAdmin = user && (user as any).user_metadata?.role === 'admin';

  if (!user) {
    // Rediriger vers la page d'authentification si non connecté
    return <Navigate to="/auth" replace />;
  }

  if (!isAdmin) {
    // Afficher une page d'accès refusé si l'utilisateur n'est pas administrateur
    return (
      <Box sx={{ p: 3, textAlign: 'center' }}>
        <Card>
          <CardContent>
            <AdminIcon sx={{ fontSize: 64, color: 'error.main', mb: 2 }} />
            <Typography variant="h5" gutterBottom color="error.main">
              Accès Refusé
            </Typography>
            <Typography variant="body1" color="text.secondary" gutterBottom>
              Cette page est réservée aux administrateurs uniquement.
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Veuillez contacter un administrateur si vous pensez que c'est une erreur.
            </Typography>
          </CardContent>
        </Card>
      </Box>
    );
  }

  // Si l'utilisateur est administrateur, afficher le contenu
  return <>{children}</>;
};

export default AdminGuard;
