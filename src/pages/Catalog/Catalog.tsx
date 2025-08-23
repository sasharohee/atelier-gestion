import React from 'react';
import { Routes, Route, useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  CardActionArea,
  Avatar,
} from '@mui/material';
import {
  DeviceHub as DeviceHubIcon,
  Build as BuildIcon,
  Inventory as InventoryIcon,
  ShoppingCart as ShoppingCartIcon,
  Warning as WarningIcon,
  People as PeopleIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

// Sous-pages du catalogue
import Models from './Models';
import Services from './Services';
import Parts from './Parts';
import Products from './Products';
import OutOfStock from './OutOfStock';
import Clients from './Clients';

const Catalog: React.FC = () => {
  const navigate = useNavigate();
  const { devices, services, parts, products, clients, getActiveStockAlerts } = useAppStore();

  const stockAlerts = getActiveStockAlerts();

  const catalogSections = [
    {
      title: 'Modèles',
      description: 'Gestion des modèles d\'appareils',
      icon: <DeviceHubIcon />,
      path: '/app/catalog/models',
      count: devices.length,
      color: '#2196f3',
    },
    {
      title: 'Services',
      description: 'Services de réparation proposés',
      icon: <BuildIcon />,
      path: '/app/catalog/services',
      count: services.length,
      color: '#ff9800',
    },
    {
      title: 'Pièces détachées',
      description: 'Stock des pièces détachées',
      icon: <InventoryIcon />,
      path: '/app/catalog/parts',
      count: parts.length,
      color: '#4caf50',
    },
    {
      title: 'Produits',
      description: 'Produits et accessoires',
      icon: <ShoppingCartIcon />,
      path: '/app/catalog/products',
      count: products.length,
      color: '#9c27b0',
    },
    {
      title: 'Ruptures de stock',
      description: 'Alertes et ruptures',
      icon: <WarningIcon />,
      path: '/app/catalog/out-of-stock',
      count: stockAlerts.length,
      color: '#f44336',
    },
    {
      title: 'Clients',
      description: 'Base de données clients',
      icon: <PeopleIcon />,
      path: '/app/catalog/clients',
      count: clients.length,
      color: '#607d8b',
    },
  ];

  const handleSectionClick = (path: string) => {
    navigate(path);
  };

  return (
    <Routes>
      <Route path="/" element={
        <Box>
          {/* En-tête */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
              Catalogue
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Gestion complète du catalogue de l'atelier
            </Typography>
          </Box>

          {/* Sections du catalogue */}
          <Grid container spacing={3}>
            {catalogSections.map((section) => (
              <Grid item xs={12} sm={6} md={4} key={section.title}>
                <Card>
                  <CardActionArea onClick={() => handleSectionClick(section.path)}>
                    <CardContent sx={{ p: 3 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                        <Avatar
                          sx={{
                            backgroundColor: section.color,
                            width: 56,
                            height: 56,
                            mr: 2,
                          }}
                        >
                          {section.icon}
                        </Avatar>
                        <Box>
                          <Typography variant="h6" sx={{ fontWeight: 600 }}>
                            {section.title}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {section.count} éléments
                          </Typography>
                        </Box>
                      </Box>
                      <Typography variant="body2" color="text.secondary">
                        {section.description}
                      </Typography>
                    </CardContent>
                  </CardActionArea>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      } />
      <Route path="/models" element={<Models />} />
      <Route path="/services" element={<Services />} />
      <Route path="/parts" element={<Parts />} />
      <Route path="/products" element={<Products />} />
      <Route path="/out-of-stock" element={<OutOfStock />} />
      <Route path="/clients" element={<Clients />} />
    </Routes>
  );
};

export default Catalog;
