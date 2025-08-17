import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  TextField,
  Button,
  Avatar,
  Divider,
  Switch,
  FormControlLabel,
  FormGroup,
} from '@mui/material';
import {
  AccountCircle as AccountIcon,
  Notifications as NotificationsIcon,
  Security as SecurityIcon,
  Palette as PaletteIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

const Settings: React.FC = () => {
  const { currentUser } = useAppStore();
  const [notifications, setNotifications] = useState({
    email: true,
    push: true,
    sms: false,
  });

  const [theme, setTheme] = useState({
    darkMode: false,
    compactMode: false,
  });

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Réglages
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Paramètres de votre compte et préférences
        </Typography>
      </Box>

      <Grid container spacing={3}>
        {/* Profil utilisateur */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <AccountIcon sx={{ mr: 2, color: 'primary.main' }} />
                <Typography variant="h6">Profil utilisateur</Typography>
              </Box>
              
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <Avatar
                  src={currentUser?.avatar}
                  sx={{ width: 80, height: 80, mr: 3 }}
                >
                  {currentUser?.name?.charAt(0)}
                </Avatar>
                <Button variant="outlined" size="small">
                  Changer l'avatar
                </Button>
              </Box>

              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Prénom"
                    defaultValue={currentUser?.name?.split(' ')[0] || ''}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label="Nom"
                    defaultValue={currentUser?.name?.split(' ')[1] || ''}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Email"
                    type="email"
                    defaultValue={currentUser?.email || ''}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Téléphone"
                    defaultValue=""
                  />
                </Grid>
              </Grid>

              <Box sx={{ mt: 3 }}>
                <Button variant="contained">
                  Sauvegarder les modifications
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Sécurité */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <SecurityIcon sx={{ mr: 2, color: 'primary.main' }} />
                <Typography variant="h6">Sécurité</Typography>
              </Box>

              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Ancien mot de passe"
                    type="password"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Nouveau mot de passe"
                    type="password"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Confirmer le nouveau mot de passe"
                    type="password"
                  />
                </Grid>
              </Grid>

              <Box sx={{ mt: 3 }}>
                <Button variant="contained">
                  Changer le mot de passe
                </Button>
              </Box>

              <Divider sx={{ my: 3 }} />

              <FormGroup>
                <FormControlLabel
                  control={<Switch defaultChecked />}
                  label="Authentification à deux facteurs"
                />
                <FormControlLabel
                  control={<Switch />}
                  label="Sessions multiples"
                />
              </FormGroup>
            </CardContent>
          </Card>
        </Grid>

        {/* Notifications */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <NotificationsIcon sx={{ mr: 2, color: 'primary.main' }} />
                <Typography variant="h6">Notifications</Typography>
              </Box>

              <FormGroup>
                <FormControlLabel
                  control={
                    <Switch
                      checked={notifications.email}
                      onChange={(e) => setNotifications({ ...notifications, email: e.target.checked })}
                    />
                  }
                  label="Notifications par email"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={notifications.push}
                      onChange={(e) => setNotifications({ ...notifications, push: e.target.checked })}
                    />
                  }
                  label="Notifications push"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={notifications.sms}
                      onChange={(e) => setNotifications({ ...notifications, sms: e.target.checked })}
                    />
                  }
                  label="Notifications SMS"
                />
              </FormGroup>

              <Divider sx={{ my: 3 }} />

              <Typography variant="subtitle2" gutterBottom>
                Types de notifications
              </Typography>
              <FormGroup>
                <FormControlLabel
                  control={<Switch defaultChecked />}
                  label="Nouvelles réparations"
                />
                <FormControlLabel
                  control={<Switch defaultChecked />}
                  label="Mise à jour du statut"
                />
                <FormControlLabel
                  control={<Switch defaultChecked />}
                  label="Alertes de stock"
                />
                <FormControlLabel
                  control={<Switch />}
                  label="Rapports quotidiens"
                />
              </FormGroup>
            </CardContent>
          </Card>
        </Grid>

        {/* Apparence */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
                <PaletteIcon sx={{ mr: 2, color: 'primary.main' }} />
                <Typography variant="h6">Apparence</Typography>
              </Box>

              <FormGroup>
                <FormControlLabel
                  control={
                    <Switch
                      checked={theme.darkMode}
                      onChange={(e) => setTheme({ ...theme, darkMode: e.target.checked })}
                    />
                  }
                  label="Mode sombre"
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={theme.compactMode}
                      onChange={(e) => setTheme({ ...theme, compactMode: e.target.checked })}
                    />
                  }
                  label="Mode compact"
                />
              </FormGroup>

              <Divider sx={{ my: 3 }} />

              <Typography variant="subtitle2" gutterBottom>
                Langue
              </Typography>
              <TextField
                select
                fullWidth
                defaultValue="fr"
                label="Langue"
              >
                <option value="fr">Français</option>
                <option value="en">English</option>
                <option value="es">Español</option>
              </TextField>

              <Box sx={{ mt: 3 }}>
                <Button variant="contained">
                  Appliquer les changements
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Settings;
