import React, { useState } from 'react';
import {
  Box,
  Container,
  Typography,
  Paper,
  Breadcrumbs,
  Link,
  Divider,
  TextField,
  Button,
  Grid,
  Card,
  CardContent,
  Alert,
  Chip,
  List,
  ListItem,
  ListItemIcon,
  ListItemText
} from '@mui/material';
import { 
  NavigateNext as NavigateNextIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  LocationOn as LocationIcon,
  Send as SendIcon,
  Support as SupportIcon,
  Schedule as ScheduleIcon,
  CheckCircle as CheckCircleIcon
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

const Support: React.FC = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    subject: '',
    message: ''
  });
  const [isSubmitted, setIsSubmitted] = useState(false);

  const handleBreadcrumbClick = () => {
    navigate('/');
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Simulation d'envoi
    console.log('Formulaire soumis:', formData);
    setIsSubmitted(true);
    setFormData({ name: '', email: '', subject: '', message: '' });
  };

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f8f9fa', py: 4 }}>
      <Container maxWidth="lg">
        {/* Breadcrumbs */}
        <Breadcrumbs 
          separator={<NavigateNextIcon fontSize="small" />}
          sx={{ mb: 4 }}
        >
          <Link
            color="inherit"
            href="#"
            onClick={handleBreadcrumbClick}
            sx={{ cursor: 'pointer', '&:hover': { textDecoration: 'underline' } }}
          >
            Accueil
          </Link>
          <Typography color="text.primary">Support</Typography>
        </Breadcrumbs>

        <Typography variant="h3" component="h1" sx={{ mb: 4, fontWeight: 700, color: '#2c3e50', textAlign: 'center' }}>
          Support Client
        </Typography>

        <Typography variant="h6" sx={{ mb: 4, textAlign: 'center', color: '#6c757d', maxWidth: 600, mx: 'auto' }}>
          Notre équipe est là pour vous aider à tirer le meilleur parti d'Atelier Gestion. 
          Contactez-nous et nous vous répondrons dans les plus brefs délais.
        </Typography>

        <Grid container spacing={4}>
          {/* Informations de contact */}
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3, height: 'fit-content' }}>
              <Typography variant="h5" sx={{ mb: 3, fontWeight: 600, color: '#2c3e50' }}>
                Informations de Contact
              </Typography>
              
              <List>
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <EmailIcon sx={{ color: '#3498db' }} />
                  </ListItemIcon>
                  <ListItemText
                    primary="Email"
                    secondary="support@atelier-gestion.fr"
                    primaryTypographyProps={{ fontWeight: 600 }}
                    secondaryTypographyProps={{ color: '#6c757d' }}
                  />
                </ListItem>
                
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <PhoneIcon sx={{ color: '#3498db' }} />
                  </ListItemIcon>
                  <ListItemText
                    primary="Téléphone"
                    secondary="+33 1 23 45 67 89"
                    primaryTypographyProps={{ fontWeight: 600 }}
                    secondaryTypographyProps={{ color: '#6c757d' }}
                  />
                </ListItem>
                
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <LocationIcon sx={{ color: '#3498db' }} />
                  </ListItemIcon>
                  <ListItemText
                    primary="Adresse"
                    secondary="France"
                    primaryTypographyProps={{ fontWeight: 600 }}
                    secondaryTypographyProps={{ color: '#6c757d' }}
                  />
                </ListItem>
                
                <ListItem sx={{ px: 0 }}>
                  <ListItemIcon>
                    <ScheduleIcon sx={{ color: '#3498db' }} />
                  </ListItemIcon>
                  <ListItemText
                    primary="Horaires"
                    secondary="Lun-Ven: 9h-18h"
                    primaryTypographyProps={{ fontWeight: 600 }}
                    secondaryTypographyProps={{ color: '#6c757d' }}
                  />
                </ListItem>
              </List>

              <Divider sx={{ my: 3 }} />

              <Typography variant="h6" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
                Temps de réponse
              </Typography>
              
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <CheckCircleIcon sx={{ color: '#27ae60', mr: 1, fontSize: 20 }} />
                <Typography variant="body2" sx={{ color: '#6c757d' }}>
                  Email : 24h ouvrées
                </Typography>
              </Box>
              
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <CheckCircleIcon sx={{ color: '#27ae60', mr: 1, fontSize: 20 }} />
                <Typography variant="body2" sx={{ color: '#6c757d' }}>
                  Téléphone : Immédiat
                </Typography>
              </Box>
              
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <CheckCircleIcon sx={{ color: '#27ae60', mr: 1, fontSize: 20 }} />
                <Typography variant="body2" sx={{ color: '#6c757d' }}>
                  Urgences : 4h maximum
                </Typography>
              </Box>
            </Paper>
          </Grid>

          {/* Formulaire de contact */}
          <Grid item xs={12} md={8}>
            <Paper sx={{ p: 4 }}>
              <Typography variant="h5" sx={{ mb: 3, fontWeight: 600, color: '#2c3e50' }}>
                Formulaire de Contact
              </Typography>

              {isSubmitted && (
                <Alert severity="success" sx={{ mb: 3 }}>
                  Votre message a été envoyé avec succès ! Nous vous répondrons dans les plus brefs délais.
                </Alert>
              )}

              <form onSubmit={handleSubmit}>
                <Grid container spacing={3}>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="Nom complet"
                      name="name"
                      value={formData.name}
                      onChange={handleInputChange}
                      required
                      variant="outlined"
                    />
                  </Grid>
                  
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="Email"
                      name="email"
                      type="email"
                      value={formData.email}
                      onChange={handleInputChange}
                      required
                      variant="outlined"
                    />
                  </Grid>
                  
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Sujet"
                      name="subject"
                      value={formData.subject}
                      onChange={handleInputChange}
                      required
                      variant="outlined"
                    />
                  </Grid>
                  
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Message"
                      name="message"
                      value={formData.message}
                      onChange={handleInputChange}
                      required
                      multiline
                      rows={6}
                      variant="outlined"
                      placeholder="Décrivez votre problème ou votre question en détail..."
                    />
                  </Grid>
                  
                  <Grid item xs={12}>
                    <Button
                      type="submit"
                      variant="contained"
                      size="large"
                      startIcon={<SendIcon />}
                      sx={{
                        background: 'linear-gradient(45deg, #3498db, #2980b9)',
                        color: 'white',
                        px: 4,
                        py: 1.5,
                        fontSize: '1.1rem',
                        fontWeight: 600,
                        '&:hover': {
                          background: 'linear-gradient(45deg, #2980b9, #1f5f8b)'
                        }
                      }}
                    >
                      Envoyer le Message
                    </Button>
                  </Grid>
                </Grid>
              </form>
            </Paper>
          </Grid>
        </Grid>

        {/* Types de support */}
        <Box sx={{ mt: 6 }}>
          <Typography variant="h4" sx={{ mb: 4, fontWeight: 600, color: '#2c3e50', textAlign: 'center' }}>
            Types de Support
          </Typography>
          
          <Grid container spacing={3}>
            <Grid item xs={12} sm={6} md={3}>
              <Card sx={{ height: '100%', textAlign: 'center', p: 2 }}>
                <CardContent>
                  <SupportIcon sx={{ fontSize: 48, color: '#3498db', mb: 2 }} />
                  <Typography variant="h6" sx={{ mb: 1, fontWeight: 600 }}>
                    Support Technique
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Problèmes d'utilisation, bugs, questions techniques
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            
            <Grid item xs={12} sm={6} md={3}>
              <Card sx={{ height: '100%', textAlign: 'center', p: 2 }}>
                <CardContent>
                  <EmailIcon sx={{ fontSize: 48, color: '#e74c3c', mb: 2 }} />
                  <Typography variant="h6" sx={{ mb: 1, fontWeight: 600 }}>
                    Support Comptable
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Facturation, paiements, abonnements
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            
            <Grid item xs={12} sm={6} md={3}>
              <Card sx={{ height: '100%', textAlign: 'center', p: 2 }}>
                <CardContent>
                  <PhoneIcon sx={{ fontSize: 48, color: '#27ae60', mb: 2 }} />
                  <Typography variant="h6" sx={{ mb: 1, fontWeight: 600 }}>
                    Support Commercial
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Devis, fonctionnalités, améliorations
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            
            <Grid item xs={12} sm={6} md={3}>
              <Card sx={{ height: '100%', textAlign: 'center', p: 2 }}>
                <CardContent>
                  <LocationIcon sx={{ fontSize: 48, color: '#f39c12', mb: 2 }} />
                  <Typography variant="h6" sx={{ mb: 1, fontWeight: 600 }}>
                    Support RGPD
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Protection des données, confidentialité
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Box>

        {/* FAQ rapide */}
        <Box sx={{ mt: 6 }}>
          <Typography variant="h4" sx={{ mb: 4, fontWeight: 600, color: '#2c3e50', textAlign: 'center' }}>
            Questions Fréquentes
          </Typography>
          
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Card sx={{ p: 3 }}>
                <Typography variant="h6" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
                  Comment modifier mes informations de facturation ?
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Accédez à vos paramètres de compte dans la section "Réglages" de l'application.
                </Typography>
                <Chip label="Comptabilité" size="small" color="primary" />
              </Card>
            </Grid>
            
            <Grid item xs={12} md={6}>
              <Card sx={{ p: 3 }}>
                <Typography variant="h6" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
                  Comment exporter mes données ?
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Utilisez la fonction d'export dans la section "Réglages" pour télécharger vos données.
                </Typography>
                <Chip label="Données" size="small" color="secondary" />
              </Card>
            </Grid>
            
            <Grid item xs={12} md={6}>
              <Card sx={{ p: 3 }}>
                <Typography variant="h6" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
                  Comment résilier mon abonnement ?
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Contactez notre équipe support ou utilisez l'option de résiliation dans vos paramètres.
                </Typography>
                <Chip label="Abonnement" size="small" color="error" />
              </Card>
            </Grid>
            
            <Grid item xs={12} md={6}>
              <Card sx={{ p: 3 }}>
                <Typography variant="h6" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
                  Comment ajouter un nouvel utilisateur ?
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Les administrateurs peuvent ajouter des utilisateurs via la section "Administration".
                </Typography>
                <Chip label="Utilisateurs" size="small" color="success" />
              </Card>
            </Grid>
          </Grid>
          
          <Box sx={{ textAlign: 'center', mt: 4 }}>
            <Button
              variant="outlined"
              size="large"
              onClick={() => navigate('/faq')}
              sx={{
                borderColor: '#3498db',
                color: '#3498db',
                '&:hover': {
                  borderColor: '#2980b9',
                  backgroundColor: 'rgba(52, 152, 219, 0.04)'
                }
              }}
            >
              Voir toutes les FAQ
            </Button>
          </Box>
        </Box>
      </Container>
    </Box>
  );
};

export default Support;
