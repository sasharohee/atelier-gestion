import React, { useState } from 'react';
import {
  Box,
  Tabs,
  Tab,
  Typography,
  Paper,
  Container
} from '@mui/material';
import {
  Settings as SettingsIcon,
  Dashboard as DashboardIcon,
  History as HistoryIcon,
  Star as StarIcon,
  Tune as TuneIcon
} from '@mui/icons-material';
import LoyaltyManagement from '../../components/LoyaltyManagement/LoyaltyManagement';
import LoyaltyHistory from '../../components/LoyaltyHistory/LoyaltyHistory';
import LoyaltySettings from '../../components/LoyaltyManagement/LoyaltySettings';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`loyalty-tabpanel-${index}`}
      aria-labelledby={`loyalty-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ p: 3 }}>
          {children}
        </Box>
      )}
    </div>
  );
}

function a11yProps(index: number) {
  return {
    id: `loyalty-tab-${index}`,
    'aria-controls': `loyalty-tabpanel-${index}`,
  };
}

const LoyaltyPage: React.FC = () => {
  const [tabValue, setTabValue] = useState(0);
  const [selectedClientId, setSelectedClientId] = useState<string>('');
  const [selectedClientName, setSelectedClientName] = useState<string>('');

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const openClientHistory = (clientId: string, clientName: string) => {
    setSelectedClientId(clientId);
    setSelectedClientName(clientName);
    setTabValue(3); // Aller à l'onglet historique (décalé d'un cran)
  };

  return (
    <Container maxWidth="xl">
      <Box sx={{ width: '100%' }}>
        <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
          <Typography variant="h4" gutterBottom sx={{ mt: 2, mb: 1 }}>
            🏆 Système de Fidélité
          </Typography>
          <Typography variant="body1" color="textSecondary" sx={{ mb: 2 }}>
            Gérez automatiquement les points de fidélité de vos clients basés sur leurs dépenses
          </Typography>
          
          <Tabs 
            value={tabValue} 
            onChange={handleTabChange} 
            aria-label="loyalty tabs"
            variant="scrollable"
            scrollButtons="auto"
          >
            <Tab 
              label="Gestion" 
              icon={<SettingsIcon />} 
              iconPosition="start"
              {...a11yProps(0)} 
            />
            <Tab 
              label="Tableau de Bord" 
              icon={<DashboardIcon />} 
              iconPosition="start"
              {...a11yProps(1)} 
            />
            <Tab 
              label="Paramètres" 
              icon={<TuneIcon />} 
              iconPosition="start"
              {...a11yProps(2)} 
            />
            <Tab 
              label="Historique Client" 
              icon={<HistoryIcon />} 
              iconPosition="start"
              {...a11yProps(3)} 
            />
            <Tab 
              label="Niveaux & Avantages" 
              icon={<StarIcon />} 
              iconPosition="start"
              {...a11yProps(4)} 
            />
          </Tabs>
        </Box>

        <TabPanel value={tabValue} index={0}>
          <LoyaltyManagement />
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h5" gutterBottom>
              📊 Tableau de Bord de Fidélité
            </Typography>
            <Typography variant="body1" color="textSecondary" paragraph>
              Vue d'ensemble de tous les clients et leurs points de fidélité
            </Typography>
            
            {/* Ici on pourrait ajouter un composant de tableau de bord plus détaillé */}
            <Box textAlign="center" py={4}>
              <Typography variant="h6" color="textSecondary">
                Utilisez l'onglet "Gestion" pour voir le tableau de bord complet
              </Typography>
            </Box>
          </Paper>
        </TabPanel>

        <TabPanel value={tabValue} index={2}>
          <LoyaltySettings />
        </TabPanel>

        <TabPanel value={tabValue} index={3}>
          {selectedClientId ? (
            <LoyaltyHistory
              open={true}
              onClose={() => setSelectedClientId('')}
              clientId={selectedClientId}
              clientName={selectedClientName}
            />
          ) : (
            <Paper sx={{ p: 3 }}>
              <Typography variant="h5" gutterBottom>
                📋 Historique des Points de Fidélité
              </Typography>
              <Typography variant="body1" color="textSecondary" paragraph>
                Sélectionnez un client depuis le tableau de bord pour voir son historique détaillé
              </Typography>
              
              <Box textAlign="center" py={4}>
                <Typography variant="h6" color="textSecondary">
                  Aucun client sélectionné
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Retournez à l'onglet "Gestion" et cliquez sur un client pour voir son historique
                </Typography>
              </Box>
            </Paper>
          )}
        </TabPanel>

        <TabPanel value={tabValue} index={4}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h5" gutterBottom>
              ⭐ Niveaux de Fidélité & Avantages
            </Typography>
            <Typography variant="body1" color="textSecondary" paragraph>
              Découvrez les différents niveaux de fidélité et leurs avantages
            </Typography>
            
            <Box sx={{ mt: 3 }}>
              <Typography variant="h6" gutterBottom>
                🥉 Niveau Bronze (0-99 points)
              </Typography>
              <Typography variant="body2" paragraph>
                Niveau de base pour tous les nouveaux clients. Accès aux promotions de base.
              </Typography>

              <Typography variant="h6" gutterBottom>
                🥈 Niveau Argent (100-499 points)
              </Typography>
              <Typography variant="body2" paragraph>
                Client régulier avec 5% de réduction et accès aux promotions exclusives.
              </Typography>

              <Typography variant="h6" gutterBottom>
                🥇 Niveau Or (500-999 points)
              </Typography>
              <Typography variant="body2" paragraph>
                Client fidèle avec 10% de réduction, service prioritaire et garantie étendue.
              </Typography>

              <Typography variant="h6" gutterBottom>
                💎 Niveau Platine (1000-1999 points)
              </Typography>
              <Typography variant="body2" paragraph>
                Client VIP avec 15% de réduction, service VIP, garantie étendue et rendez-vous prioritaires.
              </Typography>

              <Typography variant="h6" gutterBottom>
                🔮 Niveau Diamant (2000+ points)
              </Typography>
              <Typography variant="body2" paragraph>
                Client Premium avec 20% de réduction, service Premium, garantie étendue, rendez-vous prioritaires et support dédié.
              </Typography>
            </Box>

            <Box sx={{ mt: 4, p: 3, bgcolor: 'info.light', borderRadius: 2 }}>
              <Typography variant="h6" gutterBottom>
                💡 Comment gagner des points ?
              </Typography>
              <Typography variant="body2">
                • <strong>1€ dépensé = 1 point de base</strong><br/>
                • <strong>Bonus de 10%</strong> pour les achats de 50€ et plus<br/>
                • <strong>Bonus de 20%</strong> pour les achats de 100€ et plus<br/>
                • <strong>Bonus de 30%</strong> pour les achats de 200€ et plus<br/>
                • <strong>Seuil minimum :</strong> 5€ pour commencer à gagner des points
              </Typography>
            </Box>
          </Paper>
        </TabPanel>
      </Box>
    </Container>
  );
};

export default LoyaltyPage;
