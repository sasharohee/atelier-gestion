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
  People as PeopleIcon,
  Receipt as ReceiptIcon,
  Description as DescriptionIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';

// Sous-pages de transaction
import Clients from '../Catalog/Clients';
import Sales from '../Sales/Sales';
import Quotes from '../Quotes/Quotes';

const Transaction: React.FC = () => {
  const navigate = useNavigate();
  const { clients, sales } = useAppStore();

  const transactionSections = [
    {
      title: 'Clients',
      description: 'Base de données clients',
      icon: <PeopleIcon />,
      path: '/app/transaction/clients',
      count: clients.length,
      color: '#607d8b',
    },

    {
      title: 'Ventes',
      description: 'Gestion des ventes et factures',
      icon: <ReceiptIcon />,
      path: '/app/transaction/sales',
      count: sales.length,
      color: '#4caf50',
    },
    {
      title: 'Devis',
      description: 'Gestion des devis et estimations',
      icon: <DescriptionIcon />,
      path: '/app/transaction/quotes',
      count: 0, // À remplacer par quotes.length quand le store sera mis à jour
      color: '#ff9800',
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
              Transaction
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Gestion des transactions et relations clients
            </Typography>
          </Box>

          {/* Sections de transaction */}
          <Grid container spacing={3}>
            {transactionSections.map((section) => (
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
      <Route path="/clients" element={<Clients />} />

      <Route path="/sales" element={<Sales />} />
      <Route path="/quotes" element={<Quotes />} />
    </Routes>
  );
};

export default Transaction;
