import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  IconButton,
  Avatar,
  Alert,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Grid,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

const Clients: React.FC = () => {
  const { clients, loadClients, addClient } = useAppStore();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    address: '',
    notes: '',
  });

  useEffect(() => {
    const loadClientsData = async () => {
      if (clients.length === 0) {
        setIsLoading(true);
        setError(null);
        try {
          await loadClients();
        } catch (err) {
          setError('Erreur lors du chargement des clients');
          console.error('Erreur lors du chargement des clients:', err);
        } finally {
          setIsLoading(false);
        }
      }
    };

    loadClientsData();
  }, [clients.length, loadClients]);

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Clients
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Base de données clients
        </Typography>
      </Box>

      <Box sx={{ mb: 3, display: 'flex', gap: 2, alignItems: 'center' }}>
        <Button variant="contained" startIcon={<AddIcon />}>
          Nouveau client
        </Button>
        <Button 
          variant="outlined" 
          startIcon={<RefreshIcon />}
          onClick={async () => {
            setIsLoading(true);
            setError(null);
            try {
              await loadClients();
            } catch (err) {
              setError('Erreur lors du rechargement des clients');
            } finally {
              setIsLoading(false);
            }
          }}
          disabled={isLoading}
        >
          Actualiser
        </Button>
        <Button 
          variant="outlined" 
          onClick={() => {
            console.log('État des clients:', clients);
            console.log('Nombre de clients:', clients.length);
            alert(`Nombre de clients chargés: ${clients.length}`);
          }}
        >
          Debug
        </Button>
        {isLoading && <CircularProgress size={20} />}
      </Box>

      {/* Affichage des erreurs */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      <Card>
        <CardContent>
          {isLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : (
            <TableContainer component={Paper} variant="outlined">
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Client</TableCell>
                    <TableCell>Contact</TableCell>
                    <TableCell>Adresse</TableCell>
                    <TableCell>Notes</TableCell>
                    <TableCell>Date d'inscription</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {clients.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} sx={{ textAlign: 'center', py: 4 }}>
                        <Typography variant="body2" color="text.secondary">
                          Aucun client trouvé
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ) : (
                    clients.map((client) => (
                      <TableRow key={client.id}>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <Avatar sx={{ mr: 2 }}>
                              {client.firstName.charAt(0)}
                            </Avatar>
                            <Box>
                              <Typography variant="body2" sx={{ fontWeight: 600 }}>
                                {client.firstName} {client.lastName}
                              </Typography>
                            </Box>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Box>
                            <Box sx={{ display: 'flex', alignItems: 'center', mb: 0.5 }}>
                              <EmailIcon fontSize="small" sx={{ mr: 1, color: 'text.secondary' }} />
                              <Typography variant="body2">
                                {client.email}
                              </Typography>
                            </Box>
                            <Box sx={{ display: 'flex', alignItems: 'center' }}>
                              <PhoneIcon fontSize="small" sx={{ mr: 1, color: 'text.secondary' }} />
                              <Typography variant="body2">
                                {client.phone}
                              </Typography>
                            </Box>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" color="text.secondary">
                            {client.address || '-'}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" color="text.secondary">
                            {client.notes || '-'}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          {new Date(client.createdAt).toLocaleDateString('fr-FR')}
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', gap: 1 }}>
                            <IconButton size="small" title="Modifier">
                              <EditIcon fontSize="small" />
                            </IconButton>
                            <IconButton size="small" title="Supprimer" color="error">
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Box>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>
    </Box>
  );
};

export default Clients;
