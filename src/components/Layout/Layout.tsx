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
  alpha,
} from '@mui/material';
import {
  SettingsOutlined as SettingsIcon,
  LogoutOutlined as LogoutIcon,
  HelpOutlineOutlined as HelpIcon,
  HomeOutlined as HomeIcon,
  NavigateNext as NavigateNextIcon,
  SearchOutlined as SearchIcon,
  NotificationsNoneOutlined as NotificationsIcon,
  KeyboardArrowDownOutlined as ArrowDownIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAppStore } from '../../store';
import ConnectionStatus from '../ConnectionStatus';
import Sidebar from './Sidebar';
import WhatsNewButton from '../WhatsNewButton';

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
      '/app/quote-requests': 'Demandes de Devis',
      '/app/buyback': 'Rachat d\'appareils',
      '/app/administration': 'Administration',
      '/app/settings': 'Réglages',
      '/app/subscription': 'Abonnement',
    };
    return titles[path] || 'Page';
  };

  const getBreadcrumbs = () => {
    const path = location.pathname;
    const breadcrumbs = [];

    breadcrumbs.push(
      <Link
        key="home"
        color="inherit"
        href="/app/dashboard"
        onClick={(e) => {
          e.preventDefault();
          navigate('/app/dashboard');
        }}
        underline="none"
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 0.5,
          color: '#94a3b8',
          fontSize: '0.78rem',
          fontWeight: 500,
          '&:hover': {
            color: '#475569',
          },
          transition: 'color 0.15s ease-out',
        }}
      >
        <HomeIcon sx={{ fontSize: '0.9rem' }} />
        Accueil
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
          underline="none"
          sx={{
            color: '#94a3b8',
            fontSize: '0.78rem',
            fontWeight: 500,
            '&:hover': { color: '#475569' },
            transition: 'color 0.15s ease-out',
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
          <Typography key="sub" sx={{ color: '#334155', fontWeight: 600, fontSize: '0.78rem' }}>
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
          underline="none"
          sx={{
            color: '#94a3b8',
            fontSize: '0.78rem',
            fontWeight: 500,
            '&:hover': { color: '#475569' },
            transition: 'color 0.15s ease-out',
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
          <Typography key="sub" sx={{ color: '#334155', fontWeight: 600, fontSize: '0.78rem' }}>
            {subTitles[subPath]}
          </Typography>
        );
      }
    } else if (path !== '/app/dashboard') {
      breadcrumbs.push(
        <Typography key="current" sx={{ color: '#334155', fontWeight: 600, fontSize: '0.78rem' }}>
          {getPageTitle()}
        </Typography>
      );
    }

    return breadcrumbs;
  };

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', background: '#f8fafc' }}>
      <Sidebar />

      <Box sx={{ display: 'flex', flexDirection: 'column', flexGrow: 1, minWidth: 0 }}>
        {/* Top Bar */}
        <Box
          component="header"
          sx={{
            position: 'sticky',
            top: 0,
            zIndex: 1100,
            background: 'rgba(255, 255, 255, 0.72)',
            backdropFilter: 'blur(16px) saturate(180%)',
            WebkitBackdropFilter: 'blur(16px) saturate(180%)',
            borderBottom: '1px solid rgba(0, 0, 0, 0.05)',
          }}
        >
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              px: { xs: 2, sm: 3 },
              height: 60,
            }}
          >
            {/* Gauche : breadcrumbs uniquement */}
            <Box sx={{ minWidth: 0 }}>
              <Breadcrumbs
                aria-label="breadcrumb"
                separator={
                  <NavigateNextIcon sx={{ fontSize: '0.8rem', color: '#cbd5e1' }} />
                }
                sx={{
                  '& .MuiBreadcrumbs-ol': {
                    flexWrap: 'nowrap',
                  },
                }}
              >
                {getBreadcrumbs()}
              </Breadcrumbs>
            </Box>

            {/* Droite : actions */}
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {/* Connexion */}
              <ConnectionStatus />

              {/* Nouveautés */}
              <WhatsNewButton />

              {/* Séparateur */}
              <Box sx={{
                width: 1,
                height: 20,
                backgroundColor: 'rgba(0,0,0,0.06)',
                mx: 0.8,
                borderRadius: 1,
              }} />

              {/* Profil cliquable */}
              <Box
                onClick={handleProfileMenuOpen}
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 1,
                  pl: 0.5,
                  pr: 1,
                  py: 0.5,
                  borderRadius: '10px',
                  cursor: 'pointer',
                  transition: 'all 0.15s ease-out',
                  '&:hover': {
                    backgroundColor: 'rgba(0,0,0,0.04)',
                  },
                }}
              >
                <Avatar
                  src={currentUser?.avatar}
                  sx={{
                    width: 32,
                    height: 32,
                    fontSize: '0.8rem',
                    fontWeight: 700,
                    background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
                    border: '2px solid rgba(99, 102, 241, 0.15)',
                  }}
                >
                  {currentUser?.firstName?.charAt(0)}
                </Avatar>
                <Box sx={{ display: { xs: 'none', md: 'block' }, minWidth: 0 }}>
                  <Typography sx={{
                    fontSize: '0.78rem',
                    fontWeight: 600,
                    color: '#1e293b',
                    lineHeight: 1.2,
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    maxWidth: 120,
                  }}>
                    {currentUser ? `${currentUser.firstName} ${currentUser.lastName}` : ''}
                  </Typography>
                  <Typography sx={{
                    fontSize: '0.68rem',
                    color: '#94a3b8',
                    fontWeight: 500,
                    lineHeight: 1.2,
                    textTransform: 'capitalize',
                  }}>
                    {currentUser?.role}
                  </Typography>
                </Box>
                <ArrowDownIcon sx={{
                  fontSize: '1rem',
                  color: '#94a3b8',
                  display: { xs: 'none', md: 'block' },
                }} />
              </Box>
            </Box>
          </Box>

          {/* Titre de page */}
          <Box sx={{
            px: { xs: 2, sm: 3 },
            pb: 1.5,
          }}>
            <Typography
              component="h1"
              sx={{
                fontWeight: 700,
                color: '#0f172a',
                fontSize: '1.35rem',
                letterSpacing: '-0.02em',
                lineHeight: 1,
              }}
            >
              {getPageTitle()}
            </Typography>
          </Box>
        </Box>

        {/* Contenu principal */}
        <Box
          component="main"
          sx={{
            flexGrow: 1,
            overflow: 'auto',
            p: 3,
            background: '#f8fafc',
            minHeight: 'calc(100vh - 96px)',
          }}
        >
          {children}
        </Box>
      </Box>

      {/* Menu profil dropdown */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
        PaperProps={{
          sx: {
            mt: 1,
            minWidth: 220,
            borderRadius: '12px',
            boxShadow: '0 8px 40px rgba(0,0,0,0.12), 0 0 0 1px rgba(0,0,0,0.04)',
            border: 'none',
            overflow: 'hidden',
          },
        }}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        {/* En-tête profil */}
        <Box sx={{
          px: 2,
          pt: 2,
          pb: 1.5,
          background: 'linear-gradient(135deg, rgba(99,102,241,0.06) 0%, rgba(139,92,246,0.04) 100%)',
          borderBottom: '1px solid rgba(0,0,0,0.05)',
        }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.2, mb: 1.2 }}>
            <Avatar
              src={currentUser?.avatar}
              sx={{
                width: 38,
                height: 38,
                fontSize: '0.9rem',
                fontWeight: 700,
                background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
              }}
            >
              {currentUser?.firstName?.charAt(0)}
            </Avatar>
            <Box sx={{ minWidth: 0 }}>
              <Typography sx={{ fontWeight: 600, color: '#1e293b', fontSize: '0.85rem', lineHeight: 1.3 }}>
                {currentUser ? `${currentUser.firstName} ${currentUser.lastName}` : ''}
              </Typography>
              <Typography sx={{ color: '#94a3b8', fontSize: '0.72rem', fontWeight: 500 }}>
                {currentUser?.email}
              </Typography>
            </Box>
          </Box>
          <Chip
            label={currentUser?.role}
            size="small"
            sx={{
              background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
              color: 'white',
              fontWeight: 600,
              fontSize: '0.65rem',
              height: 22,
              textTransform: 'capitalize',
            }}
          />
        </Box>

        {/* Actions */}
        <Box sx={{ py: 0.5 }}>
          <MenuItem
            onClick={() => { handleMenuClose(); navigate('/app/settings'); }}
            sx={{
              fontSize: '0.82rem',
              fontWeight: 500,
              color: '#475569',
              borderRadius: '8px',
              mx: 0.5,
              py: 1,
              gap: 1.2,
              '&:hover': {
                backgroundColor: 'rgba(99, 102, 241, 0.06)',
                color: '#6366f1',
                '& .menu-icon': { color: '#6366f1' },
              },
              transition: 'all 0.12s ease-out',
            }}
          >
            <SettingsIcon className="menu-icon" sx={{ fontSize: '1.15rem', color: '#94a3b8', transition: 'color 0.12s ease-out' }} />
            Réglages
          </MenuItem>
          <MenuItem
            onClick={handleMenuClose}
            sx={{
              fontSize: '0.82rem',
              fontWeight: 500,
              color: '#475569',
              borderRadius: '8px',
              mx: 0.5,
              py: 1,
              gap: 1.2,
              '&:hover': {
                backgroundColor: 'rgba(99, 102, 241, 0.06)',
                color: '#6366f1',
                '& .menu-icon': { color: '#6366f1' },
              },
              transition: 'all 0.12s ease-out',
            }}
          >
            <HelpIcon className="menu-icon" sx={{ fontSize: '1.15rem', color: '#94a3b8', transition: 'color 0.12s ease-out' }} />
            Centre d'aide
          </MenuItem>
        </Box>

        <Divider sx={{ mx: 1.5, borderColor: 'rgba(0,0,0,0.05)' }} />

        <Box sx={{ py: 0.5 }}>
          <MenuItem
            onClick={handleLogout}
            sx={{
              fontSize: '0.82rem',
              fontWeight: 500,
              color: '#ef4444',
              borderRadius: '8px',
              mx: 0.5,
              py: 1,
              gap: 1.2,
              '&:hover': {
                backgroundColor: 'rgba(239, 68, 68, 0.06)',
              },
              transition: 'all 0.12s ease-out',
            }}
          >
            <LogoutIcon sx={{ fontSize: '1.15rem' }} />
            Déconnexion
          </MenuItem>
        </Box>
      </Menu>
    </Box>
  );
};

export default Layout;
