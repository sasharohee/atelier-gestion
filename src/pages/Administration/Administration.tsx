import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Grid,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Avatar,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Security as SecurityIcon,
  Settings as SettingsIcon,
  People as PeopleIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

const Administration: React.FC = () => {
  const {
    users,
    currentUser,
  } = useAppStore();

  const [newUserDialogOpen, setNewUserDialogOpen] = useState(false);

  const getRoleLabel = (role: string) => {
    const labels = {
      admin: 'Administrateur',
      manager: 'Gérant',
      technician: 'Technicien',
    };
    return labels[role as keyof typeof labels] || role;
  };

  const getRoleColor = (role: string) => {
    const colors = {
      admin: 'error',
      manager: 'warning',
      technician: 'info',
    };
    return colors[role as keyof typeof colors] || 'default';
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Administration
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Gestion des utilisateurs et paramètres système
        </Typography>
      </Box>

      {/* Actions */}
      <Box sx={{ mb: 3 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setNewUserDialogOpen(true)}
        >
          Nouvel utilisateur
        </Button>
      </Box>

      {/* Statistiques rapides */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <PeopleIcon sx={{ mr: 2, color: 'primary.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Total utilisateurs
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {users.length}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <SecurityIcon sx={{ mr: 2, color: 'warning.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Administrateurs
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {users.filter(u => u.role === 'admin').length}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <SettingsIcon sx={{ mr: 2, color: 'info.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Techniciens
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {users.filter(u => u.role === 'technician').length}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <PeopleIcon sx={{ mr: 2, color: 'success.main' }} />
                <Box>
                  <Typography color="text.secondary" gutterBottom>
                    Utilisateurs actifs
                  </Typography>
                  <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    {users.length}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Liste des utilisateurs */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Gestion des utilisateurs
          </Typography>
          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Utilisateur</TableCell>
                  <TableCell>Email</TableCell>
                  <TableCell>Rôle</TableCell>
                  <TableCell>Date de création</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {users.map((user) => (
                  <TableRow key={user.id}>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Avatar src={user.avatar} sx={{ mr: 2 }}>
                          {user.name.charAt(0)}
                        </Avatar>
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>
                            {user.name}
                          </Typography>
                          {user.id === currentUser?.id && (
                            <Chip label="Vous" size="small" color="primary" />
                          )}
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>{user.email}</TableCell>
                    <TableCell>
                      <Chip
                        label={getRoleLabel(user.role)}
                        color={getRoleColor(user.role) as any}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      {new Date(user.createdAt).toLocaleDateString('fr-FR')}
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', gap: 1 }}>
                        <IconButton size="small" title="Modifier">
                          <EditIcon fontSize="small" />
                        </IconButton>
                        {user.id !== currentUser?.id && (
                          <IconButton size="small" title="Supprimer" color="error">
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        )}
                      </Box>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Paramètres système */}
      <Grid container spacing={3} sx={{ mt: 3 }}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Paramètres généraux
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField
                  fullWidth
                  label="Nom de l'atelier"
                  defaultValue="Atelier de réparation"
                />
                <TextField
                  fullWidth
                  label="Adresse"
                  multiline
                  rows={2}
                  defaultValue="123 Rue de la Paix, 75001 Paris"
                />
                <TextField
                  fullWidth
                  label="Téléphone"
                  defaultValue="01 23 45 67 89"
                />
                <TextField
                  fullWidth
                  label="Email"
                  defaultValue="contact@atelier.fr"
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Paramètres de facturation
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField
                  fullWidth
                  label="TVA (%)"
                  type="number"
                  defaultValue="20"
                />
                <TextField
                  fullWidth
                  label="Devise"
                  defaultValue="EUR"
                />
                <TextField
                  fullWidth
                  label="Préfixe facture"
                  defaultValue="FACT-"
                />
                <FormControl fullWidth>
                  <InputLabel>Format de date</InputLabel>
                  <Select defaultValue="dd/MM/yyyy" label="Format de date">
                    <MenuItem value="dd/MM/yyyy">dd/MM/yyyy</MenuItem>
                    <MenuItem value="MM/dd/yyyy">MM/dd/yyyy</MenuItem>
                    <MenuItem value="yyyy-MM-dd">yyyy-MM-dd</MenuItem>
                  </Select>
                </FormControl>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Dialog nouvel utilisateur */}
      <Dialog open={newUserDialogOpen} onClose={() => setNewUserDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nouvel utilisateur</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Nom complet"
                placeholder="Prénom Nom"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                placeholder="email@atelier.fr"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Mot de passe"
                type="password"
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Rôle</InputLabel>
                <Select label="Rôle">
                  <MenuItem value="admin">Administrateur</MenuItem>
                  <MenuItem value="manager">Gérant</MenuItem>
                  <MenuItem value="technician">Technicien</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewUserDialogOpen(false)}>Annuler</Button>
          <Button variant="contained">Créer</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Administration;
