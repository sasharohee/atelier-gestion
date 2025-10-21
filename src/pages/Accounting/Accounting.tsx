import React, { useState, useEffect } from 'react';
import {
  Box,
  Tabs,
  Tab,
  Typography,
  Paper,
  Container,
  Alert,
  CircularProgress,
  Fade,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  Receipt as ReceiptIcon,
  Description as InvoiceIcon,
  AttachMoney as ExpenseIcon,
  FileDownload as ExportIcon,
  Assessment as ReportIcon,
} from '@mui/icons-material';
import { theme } from '../../theme';

// Import des composants des onglets
import AccountingOverview from './AccountingOverviewSimple';
import TransactionsList from './TransactionsListFixed';
import InvoicesManagement from './InvoicesManagementFixed';
import ExpensesView from './ExpensesViewFixed';
import ExportsCenter from './ExportsCenterFixed';
import FinancialReports from './FinancialReportsFixed';

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
      id={`accounting-tabpanel-${index}`}
      aria-labelledby={`accounting-tab-${index}`}
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

const Accounting: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Simuler un chargement initial
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 1000);

    return () => clearTimeout(timer);
  }, []);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue);
  };

  const tabs = [
    {
      label: 'Vue d\'ensemble',
      icon: <DashboardIcon />,
      component: <AccountingOverview />
    },
    {
      label: 'Transactions',
      icon: <ReceiptIcon />,
      component: <TransactionsList />
    },
    {
      label: 'Factures',
      icon: <InvoiceIcon />,
      component: <InvoicesManagement />
    },
    {
      label: 'Dépenses',
      icon: <ExpenseIcon />,
      component: <ExpensesView />
    },
    {
      label: 'Exports',
      icon: <ExportIcon />,
      component: <ExportsCenter />
    },
    {
      label: 'Rapports',
      icon: <ReportIcon />,
      component: <FinancialReports />
    }
  ];

  if (isLoading) {
    return (
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '50vh',
        flexDirection: 'column',
        gap: 2
      }}>
        <CircularProgress size={40} />
        <Typography variant="h6" color="text.secondary">
          Chargement de la Comptabilité...
        </Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4 }}>
        <Alert severity="error" sx={{ mb: 2 }}>
          <Typography variant="h6" gutterBottom>
            Erreur de chargement
          </Typography>
          <Typography>
            {error}
          </Typography>
        </Alert>
      </Container>
    );
  }

  return (
    <Box sx={{ 
      backgroundColor: theme.palette.background.default,
      minHeight: '100vh',
      pb: 4
    }}>
      {/* En-tête */}
      <Box sx={{
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        color: 'white',
        py: 4,
        mb: 3
      }}>
        <Container maxWidth="lg">
          <Fade in timeout={600}>
            <Box>
              <Typography variant="h3" sx={{ 
                fontWeight: 700, 
                mb: 1,
                textShadow: '0 2px 4px rgba(0,0,0,0.3)'
              }}>
                📊 Comptabilité
              </Typography>
              <Typography variant="h6" sx={{ 
                opacity: 0.9,
                fontWeight: 400
              }}>
                Gestion financière et rapports de votre atelier
              </Typography>
            </Box>
          </Fade>
        </Container>
      </Box>

      <Container maxWidth="lg">
        {/* Message de prévention Bêta */}
        <Alert severity="warning" sx={{ mb: 3 }}>
          <Typography variant="body2">
            <strong>⚠️ Version Bêta :</strong> Cette page de comptabilité est encore en développement et peut comporter des erreurs de calculs. 
            Si vous constatez des incohérences ou des erreurs, merci de nous les signaler pour que nous puissions les corriger.
          </Typography>
        </Alert>

        <Paper sx={{ 
          borderRadius: 3,
          overflow: 'hidden',
          boxShadow: theme.shadows[4],
          border: '1px solid rgba(0,0,0,0.1)'
        }}>
          {/* Navigation par onglets */}
          <Box sx={{ 
            borderBottom: 1, 
            borderColor: 'divider',
            backgroundColor: theme.palette.background.paper
          }}>
            <Tabs
              value={activeTab}
              onChange={handleTabChange}
              variant="scrollable"
              scrollButtons="auto"
              sx={{
                '& .MuiTab-root': {
                  minHeight: 64,
                  textTransform: 'none',
                  fontSize: '0.95rem',
                  fontWeight: 500,
                  color: theme.palette.text.secondary,
                  '&.Mui-selected': {
                    color: theme.palette.primary.main,
                    fontWeight: 600,
                  },
                  '&:hover': {
                    backgroundColor: 'rgba(102, 126, 234, 0.04)',
                  }
                },
                '& .MuiTabs-indicator': {
                  height: 3,
                  borderRadius: '3px 3px 0 0',
                  backgroundColor: theme.palette.primary.main,
                }
              }}
            >
              {tabs.map((tab, index) => (
                <Tab
                  key={index}
                  label={
                    <Box sx={{ 
                      display: 'flex', 
                      alignItems: 'center', 
                      gap: 1,
                      px: 1
                    }}>
                      {tab.icon}
                      <span>{tab.label}</span>
                    </Box>
                  }
                  id={`accounting-tab-${index}`}
                  aria-controls={`accounting-tabpanel-${index}`}
                />
              ))}
            </Tabs>
          </Box>

          {/* Contenu des onglets */}
          <Box sx={{ backgroundColor: theme.palette.background.default }}>
            {tabs.map((tab, index) => (
              <TabPanel key={index} value={activeTab} index={index}>
                <Fade in={activeTab === index} timeout={300}>
                  <Box>
                    {tab.component}
                  </Box>
                </Fade>
              </TabPanel>
            ))}
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default Accounting;
