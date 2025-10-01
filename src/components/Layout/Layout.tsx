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
  Fade,
  Tooltip,
} from '@mui/material';
import {
  Menu as MenuIcon,

  AccountCircle as AccountIcon,
  Settings as SettingsIcon,
  Logout as LogoutIcon,
  Help as HelpIcon,
  Home as HomeIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAppStore } from '../../store';
import ConnectionStatus from '../ConnectionStatus';
import Sidebar from './Sidebar';

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
  } = useAppStore();

  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);

  const handleProfileMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
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
      '/app/kanban': 'Suivi des Réparations',
      '/app/calendar': 'Calendrier',
  
      '/app/catalog': 'Catalogue',
      '/app/catalog/device-management': 'Gestion des Appareils',
      '/app/catalog/services': 'Services',
      '/app/catalog/parts': 'Pièces détachées',
      '/app/catalog/products': 'Produits',
      '/app/catalog/out-of-stock': 'Ruptures de stock',
      '/app/transaction': 'Transaction',
      '/app/transaction/clients': 'Clients',
      '/app/transaction/devices': 'Appareils',
      '/app/transaction/sales': 'Ventes',
      '/app/transaction/quotes': 'Devis',
      '/app/transaction/orders': 'Suivi Commandes',
      '/app/sales': 'Ventes',
      '/app/statistics': 'Statistiques',
      '/app/loyalty': 'Points de Fidélité',
      '/app/expenses': 'Dépenses',
      '/app/administration': 'Administration',
      '/app/settings': 'Réglages',
    };
    return titles[path] || 'Page';
  };

  const getBreadcrumbs = () => {
    const path = location.pathname;
    const breadcrumbs = [];

    // Ajouter le lien vers le dashboard
    breadcrumbs.push(
      <Link
        key="home"
        color="inherit"
        href="/app/dashboard"
        onClick={(e) => {
          e.preventDefault();
          navigate('/app/dashboard');
        }}
        sx={{ 
          textDecoration: 'none',
          display: 'flex',
          alignItems: 'center',
          gap: 0.5,
          color: 'text.secondary',
          '&:hover': {
            color: 'text.primary',
          },
          transition: 'color 0.2s ease-in-out',
        }}
      >
        <HomeIcon sx={{ fontSize: '1rem' }} />
        Dashboard
      </Link>
    );

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
          sx={{ 
            textDecoration: 'none',
            color: 'text.secondary',
            '&:hover': {
              color: 'text.primary',
            },
            transition: 'color 0.2s ease-in-out',
          }}
        >
          Catalogue
        </Link>
      );
      
      const subPath = path.replace('/app/catalog/', '');
      const subTitles: Record<string, string> = {
        'device-management': 'Gestion des Appareils',
        'services': 'Services',
        'parts': 'Pièces détachées',
        'products': 'Produits',
        'out-of-stock': 'Ruptures de stock',
      };
      
      if (subTitles[subPath]) {
        breadcrumbs.push(
          <Typography key="sub" sx={{ color: 'text.primary', fontWeight: 500 }}>
            {subTitles[subPath]}
          </Typography>
        );
      }
    } else if (path.startsWith('/app/transaction/')) {
      breadcrumbs.push(
        <Link
          key="transaction"
          color="inherit"
          href="/app/transaction"
          onClick={(e) => {
            e.preventDefault();
            navigate('/app/transaction');
          }}
          sx={{ 
            textDecoration: 'none',
            color: 'text.secondary',
            '&:hover': {
              color: 'text.primary',
            },
            transition: 'color 0.2s ease-in-out',
          }}
        >
          Transaction
        </Link>
      );
      
      const subPath = path.replace('/app/transaction/', '');
      const subTitles: Record<string, string> = {
        'clients': 'Clients',
        'devices': 'Appareils',
        'sales': 'Ventes',
        'quotes': 'Devis',
        'orders': 'Suivi Commandes',
      };
      
      if (subTitles[subPath]) {
        breadcrumbs.push(
          <Typography key="sub" sx={{ color: 'text.primary', fontWeight: 500 }}>
            {subTitles[subPath]}
          </Typography>
        );
      }
    } else if (path !== '/app/dashboard') {
      breadcrumbs.push(
        <Typography key="current" sx={{ color: 'text.primary', fontWeight: 500 }}>
          {getPageTitle()}
        </Typography>
      );
    }

    return breadcrumbs;
  };

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <Sidebar />
      
      {/* Contenu principal */}
      <Box sx={{ display: 'flex', flexDirection: 'column', flexGrow: 1 }}>
        {/* Barre de navigation supérieure avec design moderne */}
        <AppBar
          position="static"
          elevation={0}
          sx={{
            background: 'white',
            borderBottom: '1px solid rgba(0, 0, 0, 0.08)',
            color: 'text.primary',
            position: 'relative',
          }}
        >
          <Toolbar sx={{ minHeight: 70, position: 'relative', zIndex: 1 }}>
            {/* Titre et breadcrumbs avec design amélioré */}
            <Box sx={{ flexGrow: 1 }}>
              <Typography 
                variant="h6" 
                component="div" 
                sx={{ 
                  fontWeight: 700,
                  color: 'text.primary',
                  fontSize: '1.25rem',
                  letterSpacing: '0.5px',
                }}
              >
                {getPageTitle()}
              </Typography>
              <Breadcrumbs 
                aria-label="breadcrumb" 
                sx={{ 
                  mt: 0.5,
                  '& .MuiBreadcrumbs-separator': {
                    color: 'text.secondary',
                  },
                }}
              >
                {getBreadcrumbs()}
              </Breadcrumbs>
            </Box>

            {/* Actions de droite avec design amélioré */}
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              {/* Statut de connexion */}
              <ConnectionStatus />
              
              {/* Profil utilisateur avec redirection vers réglages */}
              <Tooltip title="Réglages" arrow>
                <IconButton
                  color="inherit"
                  size="large"
                  onClick={() => navigate('/app/settings')}
                  sx={{
                    backgroundColor: 'rgba(0,0,0,0.04)',
                    color: 'text.primary',
                    '&:hover': {
                      backgroundColor: 'rgba(0,0,0,0.08)',
                      transform: 'scale(1.05)',
                    },
                    transition: 'all 0.2s ease-in-out',
                  }}
                >
                  <Avatar
                    src={currentUser?.avatar}
                    sx={{ 
                      width: 32, 
                      height: 32,
                      border: '2px solid rgba(0,0,0,0.1)',
                      boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                    }}
                  >
                    {currentUser?.firstName?.charAt(0)}
                  </Avatar>
                </IconButton>
              </Tooltip>
            </Box>
          </Toolbar>
        </AppBar>

        {/* Contenu principal avec padding ajusté */}
        <Box
          component="main"
          sx={{
            flexGrow: 1,
            overflow: 'auto',
            backgroundColor: 'background.default',
            p: 3,
            background: 'linear-gradient(135deg, #f9fafb 0%, #f3f4f6 100%)',
            minHeight: 'calc(100vh - 70px)',
          }}
        >
          {children}
        </Box>
      </Box>

      {/* Menu profil avec design amélioré */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
        PaperProps={{
          sx: {
            mt: 1,
            minWidth: 250,
            borderRadius: 2,
            boxShadow: '0 8px 32px rgba(0,0,0,0.15)',
            border: '1px solid rgba(255,255,255,0.2)',
            backdropFilter: 'blur(10px)',
            background: 'rgba(255,255,255,0.95)',
          },
        }}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        <Box sx={{ p: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600, color: 'text.primary' }}>
            {currentUser ? `${currentUser.firstName} ${currentUser.lastName}` : ''}
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
            {currentUser?.email}
          </Typography>
          <Chip
            label={currentUser?.role}
            size="small"
            color="primary"
            sx={{ 
              backgroundColor: 'primary.main',
              color: 'white',
              fontWeight: 600,
            }}
          />
        </Box>
        <MenuItem 
          onClick={() => { handleMenuClose(); navigate('/app/settings'); }}
          sx={{
            '&:hover': {
              backgroundColor: 'primary.light',
              color: 'primary.contrastText',
            },
            transition: 'all 0.2s ease-in-out',
          }}
        >
          <SettingsIcon sx={{ mr: 2, color: 'primary.main' }} />
          Réglages
        </MenuItem>
        <MenuItem 
          onClick={handleMenuClose}
          sx={{
            '&:hover': {
              backgroundColor: 'info.light',
              color: 'info.contrastText',
            },
            transition: 'all 0.2s ease-in-out',
          }}
        >
          <HelpIcon sx={{ mr: 2, color: 'info.main' }} />
          Aide
        </MenuItem>
        <Divider />
        <MenuItem 
          onClick={handleLogout}
          sx={{
            '&:hover': {
              backgroundColor: 'error.light',
              color: 'error.contrastText',
            },
            transition: 'all 0.2s ease-in-out',
          }}
        >
          <LogoutIcon sx={{ mr: 2, color: 'error.main' }} />
          Déconnexion
        </MenuItem>
      </Menu>
    </Box>
  );
};

export default Layout;
