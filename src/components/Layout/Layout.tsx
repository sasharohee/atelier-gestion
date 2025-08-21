import React from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Box,
  IconButton,
  Breadcrumbs,
  Link,
  Chip,
  Avatar,
  Menu,
  MenuItem,
  Divider,
  Badge,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Search as SearchIcon,
  Notifications as NotificationsIcon,
  AccountCircle as AccountIcon,
  Settings as SettingsIcon,
  Logout as LogoutIcon,
  Help as HelpIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAppStore } from '../../store';
import ConnectionStatus from '../ConnectionStatus';

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const {
    sidebarOpen,
    toggleSidebar,
    currentUser,
    getUnreadNotificationsCount,
    getActiveStockAlerts,
  } = useAppStore();

  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const [notificationAnchorEl, setNotificationAnchorEl] = React.useState<null | HTMLElement>(null);

  const unreadNotifications = getUnreadNotificationsCount();
  const stockAlerts = getActiveStockAlerts();

  const handleProfileMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleNotificationMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setNotificationAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setNotificationAnchorEl(null);
  };

  const handleLogout = () => {
    // Logique de déconnexion
    handleMenuClose();
    navigate('/auth');
  };

  const getPageTitle = () => {
    const path = location.pathname;
    const titles: Record<string, string> = {
      '/': 'Dashboard',
      '/app': 'Dashboard',
      '/app/dashboard': 'Dashboard',
      '/app/kanban': 'Tableau Kanban',
      '/app/calendar': 'Calendrier',
      '/app/messaging': 'Messagerie',
      '/app/catalog': 'Catalogue',
      '/app/catalog/devices': 'Appareils',
      '/app/catalog/services': 'Services',
      '/app/catalog/parts': 'Pièces détachées',
      '/app/catalog/products': 'Produits',
      '/app/catalog/out-of-stock': 'Ruptures de stock',
      '/app/catalog/clients': 'Clients',
      '/app/sales': 'Ventes',
      '/app/statistics': 'Statistiques',
      '/app/administration': 'Administration',
      '/app/settings': 'Réglages',
    };
    return titles[path] || 'Page';
  };

  const getBreadcrumbs = () => {
    const path = location.pathname;
    const breadcrumbs = [];

    if (path.startsWith('/app/catalog/')) {
      breadcrumbs.push(
        <Link
          key="catalog"
          color="inherit"
          href="/app/catalog"
          onClick={(e) => {
            e.preventDefault();
            navigate('/app/catalog');
          }}
          sx={{ textDecoration: 'none' }}
        >
          Catalogue
        </Link>
      );
      
      const subPath = path.replace('/app/catalog/', '');
      const subTitles: Record<string, string> = {
        'devices': 'Appareils',
        'services': 'Services',
        'parts': 'Pièces détachées',
        'products': 'Produits',
        'out-of-stock': 'Ruptures de stock',
        'clients': 'Clients',
      };
      
      if (subTitles[subPath]) {
        breadcrumbs.push(
          <Typography key="sub" color="text.primary">
            {subTitles[subPath]}
          </Typography>
        );
      }
    } else {
      breadcrumbs.push(
        <Typography key="current" color="text.primary">
          {getPageTitle()}
        </Typography>
      );
    }

    return breadcrumbs;
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Barre de navigation supérieure */}
      <AppBar
        position="static"
        elevation={0}
        sx={{
          backgroundColor: 'background.paper',
          borderBottom: '1px solid',
          borderColor: 'divider',
          color: 'text.primary',
        }}
      >
        <Toolbar sx={{ minHeight: 64 }}>
          {/* Bouton menu */}
          <IconButton
            edge="start"
            color="inherit"
            aria-label="menu"
            onClick={toggleSidebar}
            sx={{ mr: 2 }}
          >
            <MenuIcon />
          </IconButton>

          {/* Titre et breadcrumbs */}
          <Box sx={{ flexGrow: 1 }}>
            <Typography variant="h6" component="div" sx={{ fontWeight: 600 }}>
              {getPageTitle()}
            </Typography>
            <Breadcrumbs aria-label="breadcrumb" sx={{ mt: 0.5 }}>
              {getBreadcrumbs()}
            </Breadcrumbs>
          </Box>

          {/* Actions de droite */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            {/* Statut de connexion */}
            <ConnectionStatus />
            
            {/* Recherche */}
            <IconButton color="inherit" size="large">
              <SearchIcon />
            </IconButton>

            {/* Notifications */}
            <IconButton
              color="inherit"
              size="large"
              onClick={handleNotificationMenuOpen}
            >
              <Badge badgeContent={unreadNotifications} color="error">
                <NotificationsIcon />
              </Badge>
            </IconButton>

            {/* Profil utilisateur */}
            <IconButton
              color="inherit"
              size="large"
              onClick={handleProfileMenuOpen}
            >
              <Avatar
                src={currentUser?.avatar}
                sx={{ width: 32, height: 32 }}
              >
                {currentUser?.firstName?.charAt(0)}
              </Avatar>
            </IconButton>
          </Box>
        </Toolbar>
      </AppBar>

      {/* Contenu principal */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          overflow: 'auto',
          backgroundColor: 'background.default',
          p: 3,
        }}
      >
        {children}
      </Box>

      {/* Menu profil */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
        PaperProps={{
          sx: {
            mt: 1,
            minWidth: 200,
          },
        }}
      >
        <Box sx={{ p: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
            {currentUser ? `${currentUser.firstName} ${currentUser.lastName}` : ''}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {currentUser?.email}
          </Typography>
          <Chip
            label={currentUser?.role}
            size="small"
            color="primary"
            sx={{ mt: 1 }}
          />
        </Box>
        <MenuItem onClick={() => { handleMenuClose(); navigate('/app/settings'); }}>
          <SettingsIcon sx={{ mr: 2 }} />
          Réglages
        </MenuItem>
        <MenuItem onClick={handleMenuClose}>
          <HelpIcon sx={{ mr: 2 }} />
          Aide
        </MenuItem>
        <Divider />
        <MenuItem onClick={handleLogout}>
          <LogoutIcon sx={{ mr: 2 }} />
          Déconnexion
        </MenuItem>
      </Menu>

      {/* Menu notifications */}
      <Menu
        anchorEl={notificationAnchorEl}
        open={Boolean(notificationAnchorEl)}
        onClose={handleMenuClose}
        PaperProps={{
          sx: {
            mt: 1,
            minWidth: 300,
            maxHeight: 400,
          },
        }}
      >
        <Box sx={{ p: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
            Notifications
          </Typography>
        </Box>
        {unreadNotifications === 0 ? (
          <MenuItem disabled>
            <Typography variant="body2" color="text.secondary">
              Aucune nouvelle notification
            </Typography>
          </MenuItem>
        ) : (
          <>
            {stockAlerts.map((alert) => (
              <MenuItem key={alert.id} onClick={handleMenuClose}>
                <Box>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    Alerte stock
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {alert.message}
                  </Typography>
                </Box>
              </MenuItem>
            ))}
          </>
        )}
      </Menu>
    </Box>
  );
};

export default Layout;
