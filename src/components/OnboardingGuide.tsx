import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Stepper,
  Step,
  StepLabel,
  Card,
  CardContent,
  Grid,
  Chip,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
  Alert,
  LinearProgress
} from '@mui/material';
import {
  CheckCircle,
  Person,
  Phone,
  Build,
  Inventory,
  ShoppingCart,
  Assignment,
  Star,
  Info
} from '@mui/icons-material';
import { useAppStore } from '../store';
import { demoDataService } from '../services/demoDataService';

interface OnboardingStep {
  title: string;
  description: string;
  content: React.ReactNode;
  icon: React.ReactNode;
}

interface OnboardingGuideProps {
  open: boolean;
  onClose: () => void;
}

export const OnboardingGuide: React.FC<OnboardingGuideProps> = ({ open, onClose }) => {
  const [activeStep, setActiveStep] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  
  const {
    addClient,
    addDevice,
    addService,
    addPart,
    addProduct,
    addSale,
    addRepair,
    loadClients,
    loadDevices,
    loadServices,
    loadParts,
    loadProducts,
    loadRepairs,
    loadSales,
    loadAppointments,
    clients,
    devices,
    services,
    parts,
    products,
    sales,
    repairs
  } = useAppStore();

  const handleNext = () => {
    setActiveStep((prevStep) => prevStep + 1);
  };

  const handleBack = () => {
    setActiveStep((prevStep) => prevStep - 1);
  };

  const handleFinish = async () => {
    setIsLoading(true);
    setProgress(0);
    
    try {
      // Ajouter directement les données à Supabase
      setProgress(10);
      await demoDataService.addDemoDataToSupabase();
      
      setProgress(100);
      
      // Marquer le guide comme terminé
      localStorage.setItem('onboarding-completed', 'true');
      
      // Recharger les données depuis Supabase
      await Promise.all([
        loadClients(),
        loadDevices(),
        loadServices(),
        loadParts(),
        loadProducts(),
        loadRepairs(),
        loadSales(),
        loadAppointments(),
      ]);
      
      setTimeout(() => {
        setIsLoading(false);
        onClose();
      }, 1000);
      
    } catch (error) {
      console.error('Erreur lors de l\'ajout des données de démonstration:', error);
      setIsLoading(false);
    }
  };

  const steps: OnboardingStep[] = [
    {
      title: 'Bienvenue dans votre atelier',
      description: 'Découvrez votre nouvel espace de gestion',
      icon: <Star color="primary" />,
      content: (
        <Box>
          <Typography variant="h6" gutterBottom>
            🎉 Félicitations ! Votre atelier est maintenant configuré
          </Typography>
          <Typography paragraph>
            Nous avons préparé un environnement de démonstration complet pour vous permettre de découvrir toutes les fonctionnalités de votre atelier de gestion.
          </Typography>
          <Alert severity="info" sx={{ mb: 2 }}>
            <Typography variant="body2">
              Ce guide vous présentera les données de démonstration qui seront ajoutées à votre atelier.
            </Typography>
          </Alert>
          <Typography variant="h6" gutterBottom>
            Ce que vous allez découvrir :
          </Typography>
          <List>
            <ListItem>
              <ListItemIcon><Person /></ListItemIcon>
              <ListItemText primary="1 client de démonstration" />
            </ListItem>
            <ListItem>
              <ListItemIcon><Phone /></ListItemIcon>
              <ListItemText primary="3 appareils différents" />
            </ListItem>
            <ListItem>
              <ListItemIcon><Build /></ListItemIcon>
              <ListItemText primary="5 services de réparation" />
            </ListItem>
            <ListItem>
              <ListItemIcon><Inventory /></ListItemIcon>
              <ListItemText primary="10 pièces détachées" />
            </ListItem>
            <ListItem>
              <ListItemIcon><ShoppingCart /></ListItemIcon>
              <ListItemText primary="5 produits en vente" />
            </ListItem>
            <ListItem>
              <ListItemIcon><Assignment /></ListItemIcon>
              <ListItemText primary="2 réparations d'exemple" />
            </ListItem>
          </List>
        </Box>
      )
    },
    {
      title: 'Client de démonstration',
      description: 'Un client test pour commencer',
      icon: <Person color="primary" />,
      content: (
        <Box>
          <Typography variant="h6" gutterBottom>
            Client de démonstration
          </Typography>
          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" color="primary">
                Jean Dupont
              </Typography>
              <Typography color="text.secondary" gutterBottom>
                jean.dupont@email.com
              </Typography>
              <Typography variant="body2">
                📞 06 12 34 56 78
              </Typography>
              <Typography variant="body2">
                📍 123 Rue de la Paix, 75001 Paris
              </Typography>
              <Box sx={{ mt: 2 }}>
                <Chip 
                  label="Client fidèle" 
                  color="success" 
                  size="small" 
                  icon={<Star />}
                />
              </Box>
            </CardContent>
          </Card>
          <Typography variant="body2" sx={{ mt: 2, fontStyle: 'italic' }}>
            Ce client vous permettra de tester toutes les fonctionnalités liées à la gestion des clients.
          </Typography>
        </Box>
      )
    },
    {
      title: 'Appareils de démonstration',
      description: 'Différents types d\'appareils',
      icon: <Phone color="primary" />,
      content: (
        <Box>
          <Typography variant="h6" gutterBottom>
            Appareils de démonstration
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={4}>
              <Card variant="outlined">
                <CardContent>
                  <Typography variant="h6" color="primary">
                    iPhone 13 Pro
                  </Typography>
                  <Typography color="text.secondary">
                    Apple
                  </Typography>
                  <Typography variant="body2">
                    📱 Smartphone
                  </Typography>
                  <Typography variant="body2">
                    🔢 SN: IP13P001
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} md={4}>
              <Card variant="outlined">
                <CardContent>
                  <Typography variant="h6" color="primary">
                    MacBook Pro 14"
                  </Typography>
                  <Typography color="text.secondary">
                    Apple
                  </Typography>
                  <Typography variant="body2">
                    💻 Laptop
                  </Typography>
                  <Typography variant="body2">
                    🔢 SN: MBP14001
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} md={4}>
              <Card variant="outlined">
                <CardContent>
                  <Typography variant="h6" color="primary">
                    Samsung Galaxy S21
                  </Typography>
                  <Typography color="text.secondary">
                    Samsung
                  </Typography>
                  <Typography variant="body2">
                    📱 Smartphone
                  </Typography>
                  <Typography variant="body2">
                    🔢 SN: SGS21001
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Box>
      )
    },
    {
      title: 'Services de réparation',
      description: 'Services couramment proposés',
      icon: <Build color="primary" />,
      content: (
        <Box>
          <Typography variant="h6" gutterBottom>
            Services de réparation
          </Typography>
          <Grid container spacing={2}>
            {[
              { name: 'Remplacement écran', price: 89, duration: 60 },
              { name: 'Remplacement batterie', price: 49, duration: 45 },
              { name: 'Nettoyage logiciel', price: 29, duration: 30 },
              { name: 'Récupération données', price: 79, duration: 120 },
              { name: 'Diagnostic complet', price: 19, duration: 20 }
            ].map((service, index) => (
              <Grid item xs={12} md={6} key={index}>
                <Card variant="outlined">
                  <CardContent>
                    <Typography variant="h6" color="primary">
                      {service.name}
                    </Typography>
                    <Typography variant="h5" color="success.main" gutterBottom>
                      {service.price}€
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      ⏱️ {service.duration} minutes
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      )
    },
    {
      title: 'Pièces détachées',
      description: 'Stock de pièces disponibles',
      icon: <Inventory color="primary" />,
      content: (
        <Box>
          <Typography variant="h6" gutterBottom>
            Pièces détachées en stock
          </Typography>
          <Grid container spacing={2}>
            {[
              { name: 'Écran iPhone 13', stock: 5, price: 89 },
              { name: 'Batterie iPhone', stock: 12, price: 29 },
              { name: 'Écran MacBook', stock: 3, price: 299 },
              { name: 'Clavier MacBook', stock: 8, price: 89 },
              { name: 'Câble USB-C', stock: 25, price: 9 },
              { name: 'Coque iPhone', stock: 15, price: 19 }
            ].map((part, index) => (
              <Grid item xs={12} md={6} key={index}>
                <Card variant="outlined">
                  <CardContent>
                    <Typography variant="h6" color="primary">
                      {part.name}
                    </Typography>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <Typography variant="h6" color="success.main">
                        {part.price}€
                      </Typography>
                      <Chip 
                        label={`Stock: ${part.stock}`} 
                        color={part.stock > 5 ? "success" : "warning"}
                        size="small"
                      />
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      )
    },
    {
      title: 'Produits en vente',
      description: 'Produits accessoires disponibles',
      icon: <ShoppingCart color="primary" />,
      content: (
        <Box>
          <Typography variant="h6" gutterBottom>
            Produits en vente
          </Typography>
          <Grid container spacing={2}>
            {[
              { name: 'Coque iPhone Premium', price: 29, stock: 20 },
              { name: 'Chargeur sans fil', price: 39, stock: 15 },
              { name: 'Écouteurs Bluetooth', price: 49, stock: 12 },
              { name: 'Support téléphone', price: 19, stock: 25 },
              { name: 'Câble Lightning', price: 15, stock: 30 }
            ].map((product, index) => (
              <Grid item xs={12} md={6} key={index}>
                <Card variant="outlined">
                  <CardContent>
                    <Typography variant="h6" color="primary">
                      {product.name}
                    </Typography>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <Typography variant="h6" color="success.main">
                        {product.price}€
                      </Typography>
                      <Chip 
                        label={`Stock: ${product.stock}`} 
                        color="success"
                        size="small"
                      />
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      )
    },
    {
      title: 'Réparations d\'exemple',
      description: 'Réparations pour tester le workflow',
      icon: <Assignment color="primary" />,
      content: (
        <Box>
          <Typography variant="h6" gutterBottom>
            Réparations d'exemple
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <Card variant="outlined">
                <CardContent>
                  <Typography variant="h6" color="primary">
                    Remplacement écran iPhone 13
                  </Typography>
                  <Typography color="text.secondary" gutterBottom>
                    Client: Jean Dupont
                  </Typography>
                  <Typography variant="body2">
                    📱 iPhone 13 Pro
                  </Typography>
                  <Typography variant="body2">
                    💰 89€
                  </Typography>
                  <Box sx={{ mt: 1 }}>
                    <Chip 
                      label="En cours" 
                      color="warning" 
                      size="small"
                    />
                  </Box>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} md={6}>
              <Card variant="outlined">
                <CardContent>
                  <Typography variant="h6" color="primary">
                    Remplacement batterie MacBook
                  </Typography>
                  <Typography color="text.secondary" gutterBottom>
                    Client: Jean Dupont
                  </Typography>
                  <Typography variant="body2">
                    💻 MacBook Pro 14"
                  </Typography>
                  <Typography variant="body2">
                    💰 149€
                  </Typography>
                  <Box sx={{ mt: 1 }}>
                    <Chip 
                      label="Terminée" 
                      color="success" 
                      size="small"
                    />
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Box>
      )
    },
    {
      title: 'Prêt à commencer !',
      description: 'Votre atelier est configuré',
      icon: <CheckCircle color="primary" />,
      content: (
        <Box textAlign="center">
          <CheckCircle color="success" sx={{ fontSize: 80, mb: 2 }} />
          <Typography variant="h4" gutterBottom>
            🎉 Votre atelier est prêt !
          </Typography>
          <Typography variant="h6" color="text.secondary" paragraph>
            Toutes les données de démonstration vont être ajoutées à votre atelier.
          </Typography>
          <Typography paragraph>
            Vous pouvez maintenant explorer toutes les fonctionnalités avec des données réalistes.
          </Typography>
          <Alert severity="info" sx={{ mb: 2 }}>
            <Typography variant="body2">
              💡 Conseil : Commencez par explorer le tableau de bord pour voir un aperçu de votre activité.
            </Typography>
          </Alert>
          {isLoading && (
            <Box sx={{ mt: 2 }}>
              <Typography variant="body2" gutterBottom>
                Ajout des données de démonstration...
              </Typography>
              <LinearProgress variant="determinate" value={progress} sx={{ height: 8, borderRadius: 4 }} />
              <Typography variant="body2" sx={{ mt: 1 }}>
                {progress}% terminé
              </Typography>
            </Box>
          )}
        </Box>
      )
    }
  ];

  return (
    <Dialog 
      open={open} 
      onClose={onClose}
      maxWidth="md"
      fullWidth
      disableEscapeKeyDown={isLoading}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Info color="primary" />
          <Typography variant="h6">
            Guide d'intégration - Votre atelier de gestion
          </Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <Stepper activeStep={activeStep} sx={{ mb: 3 }}>
          {steps.map((step, index) => (
            <Step key={index}>
              <StepLabel>{step.title}</StepLabel>
            </Step>
          ))}
        </Stepper>
        
        <Divider sx={{ mb: 3 }} />
        
        {steps[activeStep]?.content}
      </DialogContent>
      
      <DialogActions sx={{ p: 3 }}>
        <Button 
          onClick={handleBack} 
          disabled={activeStep === 0 || isLoading}
        >
          Précédent
        </Button>
        
        {activeStep === steps.length - 1 ? (
          <Button 
            onClick={handleFinish}
            variant="contained"
            disabled={isLoading}
          >
            {isLoading ? 'Configuration...' : 'Terminer la configuration'}
          </Button>
        ) : (
          <Button 
            onClick={handleNext}
            variant="contained"
            disabled={isLoading}
          >
            Suivant
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};
