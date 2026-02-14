import React from 'react';
import { Box, Tooltip, Typography, alpha, keyframes } from '@mui/material';
import {
  SignalWifi4BarOutlined as WifiIcon,
  SignalWifiOffOutlined as WifiOffIcon,
  SyncOutlined as SyncIcon,
} from '@mui/icons-material';
import { useSupabaseConnection } from '../hooks/useSupabaseConnection';

const pulse = keyframes`
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
`;

const spin = keyframes`
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
`;

const ConnectionStatus: React.FC = () => {
  const { isConnected, isLoading, error, health, lastChecked, retry } = useSupabaseConnection();

  const formatLastChecked = () => {
    if (!lastChecked) return 'Jamais';
    const now = new Date();
    const diff = now.getTime() - lastChecked.getTime();
    const seconds = Math.floor(diff / 1000);

    if (seconds < 60) return `Il y a ${seconds}s`;
    if (seconds < 3600) return `Il y a ${Math.floor(seconds / 60)}min`;
    return `Il y a ${Math.floor(seconds / 3600)}h`;
  };

  const getLatencyColor = (ms: number) => {
    if (ms < 100) return '#22c55e';
    if (ms < 300) return '#f59e0b';
    return '#ef4444';
  };

  const getLatencyLabel = (ms: number) => {
    if (ms < 100) return 'Excellent';
    if (ms < 300) return 'Correct';
    return 'Lent';
  };

  const dotColor = isLoading
    ? '#94a3b8'
    : isConnected
      ? '#22c55e'
      : '#ef4444';

  const responseTime = health?.responseTime;

  return (
    <Tooltip
      arrow
      title={
        <Box sx={{ p: 0.5 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.8 }}>
            <Box sx={{
              width: 8,
              height: 8,
              borderRadius: '50%',
              backgroundColor: dotColor,
              boxShadow: `0 0 6px ${alpha(dotColor, 0.5)}`,
            }} />
            <Typography sx={{ fontSize: '0.8rem', fontWeight: 600, color: 'white' }}>
              {isLoading ? 'Connexion en cours...' : isConnected ? 'Supabase connecté' : 'Supabase déconnecté'}
            </Typography>
          </Box>
          {responseTime != null && (
            <Typography sx={{ fontSize: '0.72rem', color: 'rgba(255,255,255,0.7)', mb: 0.3 }}>
              Latence : {responseTime}ms ({getLatencyLabel(responseTime)})
            </Typography>
          )}
          {error && (
            <Typography sx={{ fontSize: '0.72rem', color: '#fca5a5', mb: 0.3 }}>
              {error}
            </Typography>
          )}
          <Typography sx={{ fontSize: '0.68rem', color: 'rgba(255,255,255,0.5)' }}>
            {formatLastChecked()} · Cliquer pour actualiser
          </Typography>
        </Box>
      }
    >
      <Box
        onClick={retry}
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 0.8,
          px: 1.2,
          py: 0.5,
          borderRadius: '8px',
          cursor: 'pointer',
          border: '1px solid',
          borderColor: isLoading
            ? 'rgba(0,0,0,0.08)'
            : isConnected
              ? alpha('#22c55e', 0.15)
              : alpha('#ef4444', 0.2),
          background: isLoading
            ? 'rgba(0,0,0,0.02)'
            : isConnected
              ? alpha('#22c55e', 0.05)
              : alpha('#ef4444', 0.05),
          transition: 'all 0.2s ease-out',
          '&:hover': {
            background: isLoading
              ? 'rgba(0,0,0,0.04)'
              : isConnected
                ? alpha('#22c55e', 0.1)
                : alpha('#ef4444', 0.1),
            borderColor: isLoading
              ? 'rgba(0,0,0,0.12)'
              : isConnected
                ? alpha('#22c55e', 0.25)
                : alpha('#ef4444', 0.3),
          },
          userSelect: 'none',
        }}
      >
        {/* Icône */}
        {isLoading ? (
          <SyncIcon sx={{
            fontSize: '0.95rem',
            color: '#94a3b8',
            animation: `${spin} 1.2s linear infinite`,
          }} />
        ) : isConnected ? (
          <WifiIcon sx={{ fontSize: '0.95rem', color: '#22c55e' }} />
        ) : (
          <WifiOffIcon sx={{ fontSize: '0.95rem', color: '#ef4444' }} />
        )}

        {/* Dot status */}
        <Box sx={{
          width: 6,
          height: 6,
          borderRadius: '50%',
          backgroundColor: dotColor,
          boxShadow: `0 0 6px ${alpha(dotColor, 0.4)}`,
          animation: isLoading ? `${pulse} 1.5s ease-in-out infinite` : 'none',
          flexShrink: 0,
        }} />

        {/* Texte */}
        <Typography sx={{
          fontSize: '0.72rem',
          fontWeight: 600,
          color: isLoading
            ? '#94a3b8'
            : isConnected
              ? '#16a34a'
              : '#ef4444',
          letterSpacing: '0.01em',
          lineHeight: 1,
        }}>
          {isLoading ? 'Connexion' : isConnected ? 'Connecté' : 'Hors ligne'}
        </Typography>

        {/* Latence */}
        {!isLoading && responseTime != null && (
          <Box sx={{
            display: 'flex',
            alignItems: 'center',
            gap: 0.4,
            pl: 0.5,
            borderLeft: '1px solid rgba(0,0,0,0.08)',
          }}>
            <Box sx={{
              width: 4,
              height: 4,
              borderRadius: '50%',
              backgroundColor: getLatencyColor(responseTime),
            }} />
            <Typography sx={{
              fontSize: '0.68rem',
              fontWeight: 600,
              color: getLatencyColor(responseTime),
              letterSpacing: '0.02em',
              lineHeight: 1,
              fontVariantNumeric: 'tabular-nums',
            }}>
              {responseTime}ms
            </Typography>
          </Box>
        )}

        {/* Erreur réseau */}
        {!isLoading && error && !isConnected && (
          <Box sx={{
            pl: 0.5,
            borderLeft: '1px solid rgba(239, 68, 68, 0.15)',
          }}>
            <Typography sx={{
              fontSize: '0.68rem',
              fontWeight: 500,
              color: '#ef4444',
              lineHeight: 1,
            }}>
              Erreur
            </Typography>
          </Box>
        )}
      </Box>
    </Tooltip>
  );
};

export default ConnectionStatus;
