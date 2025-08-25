import React from 'react';
import { Box, Chip, Tooltip, Typography } from '@mui/material';
import { 
  CheckCircle as CheckIcon, 
  Error as ErrorIcon, 
  Wifi as WifiIcon,
  WifiOff as WifiOffIcon,
  Refresh as RefreshIcon
} from '@mui/icons-material';
import { useSupabaseConnection } from '../hooks/useSupabaseConnection';

const ConnectionStatus: React.FC = () => {
  const { isConnected, isLoading, error, health, lastChecked, retry } = useSupabaseConnection();

  const getStatusColor = () => {
    if (isLoading) return 'default';
    if (isConnected) return 'success';
    return 'error';
  };

  const getStatusIcon = () => {
    if (isLoading) return <RefreshIcon />;
    if (isConnected) return <CheckIcon />;
    return <ErrorIcon />;
  };

  const getStatusText = () => {
    if (isLoading) return 'Connexion...';
    if (isConnected) return 'Connecté';
    return 'Déconnecté';
  };

  const formatLastChecked = () => {
    if (!lastChecked) return 'Jamais';
    const now = new Date();
    const diff = now.getTime() - lastChecked.getTime();
    const seconds = Math.floor(diff / 1000);
    
    if (seconds < 60) return `Il y a ${seconds}s`;
    if (seconds < 3600) return `Il y a ${Math.floor(seconds / 60)}min`;
    return `Il y a ${Math.floor(seconds / 3600)}h`;
  };

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
      <Tooltip 
        title={
          <Box>
            <Typography variant="body2">
              <strong>Statut Supabase:</strong> {getStatusText()}
            </Typography>
            {health && (
              <Typography variant="body2">
                Temps de réponse: {health.responseTime}ms
              </Typography>
            )}
            {error && (
              <Typography variant="body2" color="error">
                Erreur: {error}
              </Typography>
            )}
            <Typography variant="body2">
              Dernière vérification: {formatLastChecked()}
            </Typography>
          </Box>
        }
      >
        <Chip
          icon={getStatusIcon()}
          label={getStatusText()}
          color={getStatusColor()}
          size="small"
          onClick={retry}
          sx={{ 
            cursor: 'pointer',
            ...(isConnected && {
              backgroundColor: 'success.main',
              color: 'white',
              '& .MuiChip-label': {
                color: 'white',
              },
              '& .MuiChip-icon': {
                color: 'white',
              },
            })
          }}
        />
      </Tooltip>
      
      {health && health.healthy && (
        <Chip
          icon={<WifiIcon />}
          label={`${health.responseTime}ms`}
          color="success"
          size="small"
          variant="outlined"
        />
      )}
      
      {error && (
        <Chip
          icon={<WifiOffIcon />}
          label="Erreur réseau"
          color="error"
          size="small"
          variant="outlined"
        />
      )}
    </Box>
  );
};

export default ConnectionStatus;
