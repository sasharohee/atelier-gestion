import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Typography,
  Chip,
  Box,
  CircularProgress,
  Alert
} from '@mui/material';
import {
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  Star as StarIcon,
  History as HistoryIcon
} from '@mui/icons-material';
import { supabase } from '../../lib/supabase';

interface LoyaltyHistoryItem {
  id: string;
  points_change: number;
  points_type: 'earned' | 'used' | 'expired' | 'bonus';
  source_type: 'referral' | 'purchase' | 'manual' | 'bonus';
  description: string;
  created_at: string;
}

interface LoyaltyHistoryProps {
  open: boolean;
  onClose: () => void;
  clientId: string;
  clientName: string;
}

const LoyaltyHistory: React.FC<LoyaltyHistoryProps> = ({
  open,
  onClose,
  clientId,
  clientName
}) => {
  const [history, setHistory] = useState<LoyaltyHistoryItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open && clientId) {
      loadHistory();
    }
  }, [open, clientId]);

  const loadHistory = async () => {
    try {
      setLoading(true);
      setError(null);

      const { data, error } = await supabase
        .from('loyalty_points_history')
        .select('*')
        .eq('client_id', clientId)
        .order('created_at', { ascending: false })
        .limit(50);

      if (error) throw error;

      setHistory(data || []);
    } catch (err) {
      console.error('Erreur lors du chargement de l\'historique:', err);
      setError('Erreur lors du chargement de l\'historique');
    } finally {
      setLoading(false);
    }
  };

  const getPointsTypeIcon = (type: string) => {
    switch (type) {
      case 'earned':
      case 'bonus':
        return <TrendingUpIcon color="success" />;
      case 'used':
        return <TrendingDownIcon color="error" />;
      case 'expired':
        return <HistoryIcon color="warning" />;
      default:
        return <StarIcon />;
    }
  };

  const getPointsTypeColor = (type: string) => {
    switch (type) {
      case 'earned':
      case 'bonus':
        return 'success';
      case 'used':
        return 'error';
      case 'expired':
        return 'warning';
      default:
        return 'default';
    }
  };

  const getPointsTypeText = (type: string) => {
    switch (type) {
      case 'earned':
        return 'Gagnés';
      case 'used':
        return 'Utilisés';
      case 'expired':
        return 'Expirés';
      case 'bonus':
        return 'Bonus';
      default:
        return type;
    }
  };

  const getSourceTypeText = (type: string) => {
    switch (type) {
      case 'referral':
        return 'Parrainage';
      case 'purchase':
        return 'Achat';
      case 'manual':
        return 'Manuel';
      case 'bonus':
        return 'Bonus';
      default:
        return type;
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <StarIcon color="primary" />
          Historique des Points - {clientName}
        </Box>
      </DialogTitle>
      
      <DialogContent>
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
            <CircularProgress />
          </Box>
        ) : error ? (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        ) : history.length === 0 ? (
          <Alert severity="info">
            Aucun historique de points trouvé pour ce client.
          </Alert>
        ) : (
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Date</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell>Source</TableCell>
                  <TableCell align="right">Points</TableCell>
                  <TableCell>Description</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {history.map((item) => (
                  <TableRow key={item.id}>
                    <TableCell>
                      {new Date(item.created_at).toLocaleDateString('fr-FR', {
                        year: 'numeric',
                        month: 'short',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        {getPointsTypeIcon(item.points_type)}
                        <Chip
                          label={getPointsTypeText(item.points_type)}
                          color={getPointsTypeColor(item.points_type) as any}
                          size="small"
                        />
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={getSourceTypeText(item.source_type)}
                        variant="outlined"
                        size="small"
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Typography
                        variant="body2"
                        color={item.points_change > 0 ? 'success.main' : 'error.main'}
                        fontWeight="bold"
                      >
                        {item.points_change > 0 ? '+' : ''}{item.points_change}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" noWrap>
                        {item.description}
                      </Typography>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </DialogContent>
      
      <DialogActions>
        <Button onClick={onClose}>Fermer</Button>
      </DialogActions>
    </Dialog>
  );
};

export default LoyaltyHistory;
