import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider } from '@mui/material/styles';
import { CssBaseline, Box } from '@mui/material';
import { Toaster } from 'react-hot-toast';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { fr } from 'date-fns/locale';

import { theme } from './theme';
import { useAppStore } from './store';
import {
  mockUsers,
  mockClients,
  mockDevices,
  mockServices,
  mockParts,
  mockProducts,
  mockRepairStatuses,
  mockRepairs,
  mockMessages,
  mockAppointments,
  mockSales,
  mockStockAlerts,
  mockNotifications,
  mockDashboardStats,
} from './data/mockData';

// Composants de layout
import Layout from './components/Layout/Layout';
import Sidebar from './components/Layout/Sidebar';

// Pages
import Dashboard from './pages/Dashboard/Dashboard';
import Kanban from './pages/Kanban/Kanban';
import Calendar from './pages/Calendar/Calendar';
import Messaging from './pages/Messaging/Messaging';
import Catalog from './pages/Catalog/Catalog';
import Sales from './pages/Sales/Sales';
import Statistics from './pages/Statistics/Statistics';
import Administration from './pages/Administration/Administration';
import Settings from './pages/Settings/Settings';

function App() {
  const {
    setCurrentUser,
    setAuthenticated,
    addClient,
    addDevice,
    addService,
    addPart,
    addProduct,
    addRepair,
    addMessage,
    addAppointment,
    addSale,
    setDashboardStats,
  } = useAppStore();

  // Initialisation des données de démonstration
  useEffect(() => {
    // Simuler une authentification
    setCurrentUser(mockUsers[0]);
    setAuthenticated(true);

    // Charger les données de démonstration
    mockClients.forEach(addClient);
    mockDevices.forEach(addDevice);
    mockServices.forEach(addService);
    mockParts.forEach(addPart);
    mockProducts.forEach(addProduct);
    mockRepairs.forEach(addRepair);
    mockMessages.forEach(addMessage);
    mockAppointments.forEach(addAppointment);
    mockSales.forEach(addSale);
    setDashboardStats(mockDashboardStats);
  }, []);

  return (
    <ThemeProvider theme={theme}>
      <LocalizationProvider dateAdapter={AdapterDateFns} adapterLocale={fr}>
        <CssBaseline />
        <Router>
          <Box sx={{ display: 'flex', height: '100vh' }}>
            <Sidebar />
            <Box sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
              <Layout>
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/dashboard" element={<Dashboard />} />
                  <Route path="/kanban" element={<Kanban />} />
                  <Route path="/calendar" element={<Calendar />} />
                  <Route path="/messaging" element={<Messaging />} />
                  <Route path="/catalog/*" element={<Catalog />} />
                  <Route path="/sales" element={<Sales />} />
                  <Route path="/statistics" element={<Statistics />} />
                  <Route path="/administration" element={<Administration />} />
                  <Route path="/settings" element={<Settings />} />
                </Routes>
              </Layout>
            </Box>
          </Box>
        </Router>
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: '#363636',
              color: '#fff',
            },
            success: {
              duration: 3000,
              iconTheme: {
                primary: '#4caf50',
                secondary: '#fff',
              },
            },
            error: {
              duration: 5000,
              iconTheme: {
                primary: '#f44336',
                secondary: '#fff',
              },
            },
          }}
        />
      </LocalizationProvider>
    </ThemeProvider>
  );
}

export default App;
