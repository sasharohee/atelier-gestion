import React, { useState, useEffect } from 'react';
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Divider,
  Box,
  Typography,
  Badge,
  Avatar,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  ViewKanban as KanbanIcon,
  CalendarToday as CalendarIcon,
  Message as MessageIcon,
  Inventory as CatalogIcon,
  ShoppingCart as SalesIcon,
  BarChart as StatisticsIcon,
  AdminPanelSettings as AdminIcon,
  Settings as SettingsIcon,
  Notifications as NotificationsIcon,
  AccountCircle as AccountIcon,
  ChevronLeft as ChevronLeftIcon,
  Business as BusinessIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { GuideButton } from '../GuideButton';

const drawerWidth = 280;

const menuItems = [
  {
    text: 'Dashboard',
    icon: <DashboardIcon />,
    path: '/dashboard',
  },
  {
    text: 'Kanban',
    icon: <KanbanIcon />,
    path: '/kanban',
  },
  {
    text: 'Calendrier',
    icon: <CalendarIcon />,
    path: '/calendar',
  },
  {
    text: 'Messagerie',
    icon: <MessageIcon />,
    path: '/messaging',
  },
  {
    text: 'Catalogue',
    icon: <CatalogIcon />,
    path: '/catalog',
    subItems: [
      { text: 'Appareils', path: '/catalog/devices' },
      { text: 'Services', path: '/catalog/services' },
      { text: 'Pièces détachées', path: '/catalog/parts' },
      { text: 'Produits', path: '/catalog/products' },
      { text: 'Ruptures', path: '/catalog/out-of-stock' },
      { text: 'Clients', path: '/catalog/clients' },
    ],
  },
  {
    text: 'Ventes',
    icon: <SalesIcon />,
    path: '/sales',
  },
  {
    text: 'Statistiques',
    icon: <StatisticsIcon />,
    path: '/statistics',
  },
  {
    text: 'Administration',
    icon: <AdminIcon />,
    path: '/administration',
  },
];

const bottomMenuItems = [
  {
    text: 'Réglages',
    icon: <SettingsIcon />,
    path: '/settings',
  },
];

const Sidebar: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const {
    sidebarOpen,
    toggleSidebar,
    currentUser,
    getUnreadMessagesCount,
    getUnreadNotificationsCount,
  } = useAppStore();

  const { workshopSettings } = useWorkshopSettings();

  const unreadMessages = getUnreadMessagesCount();
  const unreadNotifications = getUnreadNotificationsCount();

  const handleNavigation = (path: string) => {
    navigate(path);
  };

  const isActive = (path: string) => {
    return location.pathname === path || location.pathname.startsWith(path + '/');
  };

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: sidebarOpen ? drawerWidth : 70,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: sidebarOpen ? drawerWidth : 70,
          boxSizing: 'border-box',
          transition: 'width 0.2s ease-in-out',
          overflowX: 'hidden',
        },
      }}
    >
      <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
        {/* Header */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: sidebarOpen ? 'space-between' : 'center',
            p: 2,
            minHeight: 64,
            borderBottom: '1px solid',
            borderColor: 'divider',
          }}
        >
          {sidebarOpen && (
            <Typography variant="h6" sx={{ fontWeight: 600, color: 'primary.main' }}>
              Atelier Gestion
            </Typography>
          )}
          <IconButton onClick={toggleSidebar} size="small">
            <ChevronLeftIcon
              sx={{
                transform: sidebarOpen ? 'rotate(0deg)' : 'rotate(180deg)',
                transition: 'transform 0.2s ease-in-out',
              }}
            />
          </IconButton>
        </Box>

        {/* Navigation principale */}
        <List sx={{ flexGrow: 1, py: 1 }}>
          {menuItems.map((item) => (
            <ListItem key={item.text} disablePadding>
              <ListItemButton
                onClick={() => handleNavigation(item.path)}
                selected={isActive(item.path)}
                sx={{
                  minHeight: 48,
                  px: sidebarOpen ? 3 : 2.5,
                  '&.Mui-selected': {
                    backgroundColor: 'primary.light',
                    color: 'primary.contrastText',
                    '&:hover': {
                      backgroundColor: 'primary.main',
                    },
                  },
                }}
              >
                <ListItemIcon
                  sx={{
                    minWidth: 0,
                    mr: sidebarOpen ? 2 : 0,
                    color: 'inherit',
                  }}
                >
                  {item.text === 'Messagerie' ? (
                    <Badge badgeContent={unreadMessages} color="error">
                      {item.icon}
                    </Badge>
                  ) : (
                    item.icon
                  )}
                </ListItemIcon>
                {sidebarOpen && (
                  <ListItemText
                    primary={item.text}
                    primaryTypographyProps={{
                      fontSize: '0.875rem',
                      fontWeight: isActive(item.path) ? 600 : 400,
                    }}
                  />
                )}
              </ListItemButton>
            </ListItem>
          ))}
        </List>

        <Divider />

        {/* Menu du bas */}
        <List sx={{ py: 1 }}>
          {bottomMenuItems.map((item) => (
            <ListItem key={item.text} disablePadding>
              <ListItemButton
                onClick={() => handleNavigation(item.path)}
                selected={isActive(item.path)}
                sx={{
                  minHeight: 48,
                  px: sidebarOpen ? 3 : 2.5,
                  '&.Mui-selected': {
                    backgroundColor: 'primary.light',
                    color: 'primary.contrastText',
                    '&:hover': {
                      backgroundColor: 'primary.main',
                    },
                  },
                }}
              >
                <ListItemIcon
                  sx={{
                    minWidth: 0,
                    mr: sidebarOpen ? 2 : 0,
                    color: 'inherit',
                  }}
                >
                  {item.icon}
                </ListItemIcon>
                {sidebarOpen && (
                  <ListItemText
                    primary={item.text}
                    primaryTypographyProps={{
                      fontSize: '0.875rem',
                      fontWeight: isActive(item.path) ? 600 : 400,
                    }}
                  />
                )}
              </ListItemButton>
            </ListItem>
          ))}
          
          {/* Bouton Guide */}
          <ListItem disablePadding>
            <Box sx={{ px: sidebarOpen ? 3 : 2.5, py: 1, width: '100%' }}>
              <GuideButton 
                variant="outlined" 
                size="small" 
                color="info"
              />
            </Box>
          </ListItem>
        </List>

        {/* Nom de l'atelier */}
        <Box
          sx={{
            p: 2,
            borderTop: '1px solid',
            borderColor: 'divider',
            backgroundColor: 'grey.50',
          }}
        >
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: sidebarOpen ? 'flex-start' : 'center',
            }}
          >
            <BusinessIcon 
              sx={{ 
                fontSize: sidebarOpen ? '1.2rem' : '1.5rem',
                color: 'primary.main',
                mr: sidebarOpen ? 1 : 0
              }} 
            />
            {sidebarOpen && (
              <Typography
                variant="body2"
                sx={{
                  fontWeight: 500,
                  color: 'primary.main',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                  fontSize: '0.875rem',
                }}
              >
                {workshopSettings.name}
              </Typography>
            )}
          </Box>
        </Box>

        {/* Profil utilisateur */}
        <Box
          sx={{
            p: 2,
            borderTop: '1px solid',
            borderColor: 'divider',
          }}
        >
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: sidebarOpen ? 'space-between' : 'center',
            }}
          >
            {sidebarOpen && (
              <Box sx={{ display: 'flex', alignItems: 'center', flexGrow: 1 }}>
                <Avatar
                  src={currentUser?.avatar}
                  sx={{ width: 32, height: 32, mr: 1 }}
                >
                  {currentUser?.firstName?.charAt(0)}
                </Avatar>
                <Box sx={{ minWidth: 0, flexGrow: 1 }}>
                  <Typography
                    variant="body2"
                    sx={{
                      fontWeight: 500,
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    {currentUser ? `${currentUser.firstName} ${currentUser.lastName}` : ''}
                  </Typography>
                  <Typography
                    variant="caption"
                    sx={{
                      color: 'text.secondary',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    {currentUser?.role}
                  </Typography>
                </Box>
              </Box>
            )}
            <Box sx={{ display: 'flex', gap: 0.5 }}>
              <Tooltip title="Notifications">
                <IconButton size="small">
                  <Badge badgeContent={unreadNotifications} color="error">
                    <NotificationsIcon fontSize="small" />
                  </Badge>
                </IconButton>
              </Tooltip>
              {sidebarOpen && (
                <Tooltip title="Mon compte">
                  <IconButton size="small">
                    <AccountIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              )}
            </Box>
          </Box>
        </Box>
      </Box>
    </Drawer>
  );
};

export default Sidebar;
