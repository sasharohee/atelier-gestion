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
  Collapse,
  Fade,
  Chip,
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
  AccountCircle as AccountIcon,
  ChevronLeft as ChevronLeftIcon,
  Business as BusinessIcon,
  Logout as LogoutIcon,
  ExpandLess as ExpandLessIcon,
  ExpandMore as ExpandMoreIcon,
  People as PeopleIcon,
  Phone as PhoneIcon,
  Receipt as ReceiptIcon,
  DeviceHub as DeviceHubIcon,
  Build as BuildIcon,
  Memory as MemoryIcon,
  Inventory2 as Inventory2Icon,
  Warning as WarningIcon,
  Handyman as HandymanIcon,
  Archive as ArchiveIcon,
  Description as DescriptionIcon,
  Star as StarIcon,
  LocalShipping as ShippingIcon,
  AttachMoney as ExpensesIcon,
  RequestQuote as RequestQuoteIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
// import { GuideButton } from '../GuideButton'; // MASQUÉ
import { userService } from '../../services/supabaseService';

const drawerWidth = 280;

const menuItems = [
  {
    text: 'Dashboard',
    icon: <DashboardIcon />,
    path: '/app/dashboard',
    color: '#6366f1',
  },
  {
    text: 'Suivi des Réparations',
    icon: <KanbanIcon />,
    path: '/app/kanban',
    color: '#06b6d4',
  },
  {
    text: 'SAV',
    icon: <HandymanIcon />,
    path: '/app/sav',
    color: '#16a34a',
  },
  {
    text: 'Calendrier',
    icon: <CalendarIcon />,
    path: '/app/calendar',
    color: '#10b981',
  },

  {
    text: 'Catalogue',
    icon: <CatalogIcon />,
    path: '/app/catalog',
    color: '#8b5cf6',
    subItems: [
      { text: 'Gestion des Appareils', path: '/app/catalog/device-management', icon: <DeviceHubIcon /> },
      { text: 'Services', path: '/app/catalog/services', icon: <BuildIcon /> },
      { text: 'Pièces détachées', path: '/app/catalog/parts', icon: <MemoryIcon /> },
      { text: 'Produits', path: '/app/catalog/products', icon: <Inventory2Icon /> },
      { text: 'Ruptures', path: '/app/catalog/out-of-stock', icon: <WarningIcon /> },
    ],
  },
  {
    text: 'Transaction',
    icon: <ReceiptIcon />,
    path: '/app/transaction',
    color: '#f59e0b',
    subItems: [
      { text: 'Clients', path: '/app/transaction/clients', icon: <PeopleIcon /> },
      { text: 'Ventes', path: '/app/transaction/sales', icon: <SalesIcon /> },
      { text: 'Devis', path: '/app/transaction/quotes', icon: <DescriptionIcon /> },
      { text: 'Suivi Commandes', path: '/app/transaction/orders', icon: <ShippingIcon /> },
    ],
  },
  {
    text: 'Statistiques',
    icon: <StatisticsIcon />,
    path: '/app/statistics',
    color: '#ef4444',
  },
  {
    text: 'Archives',
    icon: <ArchiveIcon />,
    path: '/app/archive',
    color: '#3b82f6',
  },
  {
    text: 'Points de Fidélité',
    icon: <StarIcon />,
    path: '/app/loyalty',
    color: '#f59e0b',
  },
  {
    text: 'Dépenses',
    icon: <ExpensesIcon />,
    path: '/app/expenses',
    color: '#dc2626',
  },
  {
    text: 'Demandes de Devis',
    icon: <RequestQuoteIcon />,
    path: '/app/quote-requests',
    color: '#7c3aed',
  },
  {
    text: 'Administration',
    icon: <AdminIcon />,
    path: '/app/administration',
    color: '#6b7280',
  },
];

const bottomMenuItems = [
  {
    text: 'Réglages',
    icon: <SettingsIcon />,
    path: '/app/settings',
    color: '#ec4899',
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
  } = useAppStore();

  const [openSubMenus, setOpenSubMenus] = useState<{ [key: string]: boolean }>({});

  const { workshopSettings } = useWorkshopSettings();

  const unreadMessages = getUnreadMessagesCount();

  const handleNavigation = (path: string) => {
    navigate(path);
  };

  const handleLogout = async () => {
    try {
      await userService.signOut();
      navigate('/auth');
    } catch (error) {
      console.error('Erreur lors de la déconnexion:', error);
    }
  };

  const handleSubMenuToggle = (menuText: string) => {
    setOpenSubMenus(prev => ({
      ...prev,
      [menuText]: !prev[menuText]
    }));
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
          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
          overflowX: 'hidden',
          background: 'linear-gradient(180deg, #1f2937 0%, #374151 50%, #4b5563 100%)',
          borderRight: 'none',
          boxShadow: '4px 0 20px rgba(0, 0, 0, 0.15)',
          '&:hover': {
            boxShadow: '6px 0 25px rgba(0, 0, 0, 0.2)',
          },
        },
      }}
    >
      <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
        {/* Header avec gradient moderne */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: sidebarOpen ? 'space-between' : 'center',
            p: 2,
            minHeight: 70,
            background: 'linear-gradient(135deg, #374151 0%, #4b5563 100%)',
            position: 'relative',
            '&::before': {
              content: '""',
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background: 'linear-gradient(135deg, rgba(255,255,255,0.05) 0%, rgba(255,255,255,0.02) 100%)',
              pointerEvents: 'none',
            },
          }}
        >
          {sidebarOpen && (
            <Fade in={sidebarOpen} timeout={300}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: 40,
                    height: 40,
                    borderRadius: '12px',
                    background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
                    boxShadow: '0 4px 12px rgba(99, 102, 241, 0.3)',
                    border: '2px solid rgba(255,255,255,0.2)',
                  }}
                >
                  <HandymanIcon 
                    sx={{ 
                      fontSize: '1.4rem',
                      color: 'white',
                    }} 
                  />
                </Box>
                <Box>
                  <Typography 
                    variant="h6" 
                    sx={{ 
                      fontWeight: 700, 
                      color: 'white',
                      textShadow: '0 2px 4px rgba(0,0,0,0.3)',
                      fontSize: '1.1rem',
                      letterSpacing: '0.5px',
                      lineHeight: 1.2,
                    }}
                  >
                    Atelier De Gestion
                  </Typography>
                  <Typography 
                    variant="caption" 
                    sx={{ 
                      color: 'rgba(255,255,255,0.8)',
                      fontSize: '0.7rem',
                      fontWeight: 500,
                      letterSpacing: '0.5px',
                      textTransform: 'uppercase',
                    }}
                  >
                    Gestion intelligente
                  </Typography>
                </Box>
              </Box>
            </Fade>
          )}
          <IconButton 
            onClick={toggleSidebar} 
            size="small"
            sx={{
              color: 'white',
              backgroundColor: 'rgba(255,255,255,0.1)',
              backdropFilter: 'blur(10px)',
              border: '1px solid rgba(255,255,255,0.15)',
              '&:hover': {
                backgroundColor: 'rgba(255,255,255,0.15)',
                transform: 'scale(1.05)',
              },
              transition: 'all 0.2s ease-in-out',
            }}
          >
            <ChevronLeftIcon
              sx={{
                transform: sidebarOpen ? 'rotate(0deg)' : 'rotate(180deg)',
                transition: 'transform 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
              }}
            />
          </IconButton>
        </Box>

        {/* Navigation principale avec design amélioré */}
        <List sx={{ flexGrow: 1, py: 1, px: 1 }}>
          {menuItems.map((item) => (
            <React.Fragment key={item.text}>
              <ListItem disablePadding sx={{ mb: 0.5 }}>
                <ListItemButton
                  onClick={() => {
                    if (item.subItems) {
                      handleSubMenuToggle(item.text);
                    } else {
                      handleNavigation(item.path);
                    }
                  }}
                  selected={isActive(item.path)}
                  sx={{
                    minHeight: 52,
                    px: sidebarOpen ? 2.5 : 2,
                    borderRadius: 2,
                    mx: 0.5,
                    position: 'relative',
                    overflow: 'hidden',
                    '&::before': {
                      content: '""',
                      position: 'absolute',
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: isActive(item.path) ? 4 : 0,
                      backgroundColor: item.color,
                      transition: 'width 0.3s ease-in-out',
                    },
                    '&.Mui-selected': {
                      backgroundColor: 'rgba(255,255,255,0.1)',
                      color: 'white',
                      backdropFilter: 'blur(10px)',
                      border: '1px solid rgba(255,255,255,0.15)',
                      '&:hover': {
                        backgroundColor: 'rgba(255,255,255,0.15)',
                      },
                      '& .MuiListItemIcon-root': {
                        color: item.color,
                      },
                    },
                    '&:hover': {
                      backgroundColor: 'rgba(255,255,255,0.05)',
                      transform: 'translateX(4px)',
                    },
                    transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
                  }}
                >
                  <ListItemIcon
                    sx={{
                      minWidth: 0,
                      mr: sidebarOpen ? 2 : 0,
                      color: isActive(item.path) ? item.color : 'rgba(255,255,255,0.8)',
                      transition: 'all 0.2s ease-in-out',
                    }}
                  >
                    {item.text === 'Messagerie' ? (
                      <Badge 
                        badgeContent={unreadMessages} 
                        color="error"
                        sx={{
                          '& .MuiBadge-badge': {
                            backgroundColor: '#ff4757',
                            color: 'white',
                            fontWeight: 600,
                          }
                        }}
                      >
                        {item.icon}
                      </Badge>
                    ) : (
                      item.icon
                    )}
                  </ListItemIcon>
                  {sidebarOpen && (
                    <>
                      <ListItemText
                        primary={item.text}
                        primaryTypographyProps={{
                          fontSize: '0.875rem',
                          fontWeight: isActive(item.path) ? 600 : 500,
                          color: isActive(item.path) ? 'white' : 'rgba(255,255,255,0.9)',
                        }}
                      />
                      {item.subItems && (
                        <Box sx={{ 
                          color: isActive(item.path) ? item.color : 'rgba(255,255,255,0.7)',
                          transition: 'color 0.2s ease-in-out',
                        }}>
                          {openSubMenus[item.text] ? <ExpandLessIcon /> : <ExpandMoreIcon />}
                        </Box>
                      )}
                    </>
                  )}
                </ListItemButton>
              </ListItem>
              
              {/* Sous-menus avec design amélioré */}
              {item.subItems && (
                <Collapse in={openSubMenus[item.text]} timeout="auto" unmountOnExit>
                  <List component="div" disablePadding sx={{ pl: sidebarOpen ? 2 : 0 }}>
                    {item.subItems.map((subItem) => (
                      <ListItem key={subItem.text} disablePadding sx={{ mb: 0.5 }}>
                        <ListItemButton
                          onClick={() => handleNavigation(subItem.path)}
                          selected={isActive(subItem.path)}
                          sx={{
                            minHeight: 44,
                            pl: sidebarOpen ? 4 : 2,
                            pr: sidebarOpen ? 2.5 : 2,
                            borderRadius: 2,
                            mx: 0.5,
                            position: 'relative',
                            '&::before': {
                              content: '""',
                              position: 'absolute',
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: isActive(subItem.path) ? 3 : 0,
                              backgroundColor: item.color,
                              transition: 'width 0.3s ease-in-out',
                            },
                            '&.Mui-selected': {
                              backgroundColor: 'rgba(255,255,255,0.1)',
                              color: 'white',
                              '&:hover': {
                                backgroundColor: 'rgba(255,255,255,0.15)',
                              },
                              '& .MuiListItemIcon-root': {
                                color: item.color,
                              },
                            },
                            '&:hover': {
                              backgroundColor: 'rgba(255,255,255,0.05)',
                              transform: 'translateX(2px)',
                            },
                            transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
                          }}
                        >
                          <ListItemIcon
                            sx={{
                              minWidth: 0,
                              mr: sidebarOpen ? 1.5 : 0,
                              color: isActive(subItem.path) ? item.color : 'rgba(255,255,255,0.7)',
                              fontSize: '1.1rem',
                            }}
                          >
                            {subItem.icon}
                          </ListItemIcon>
                          {sidebarOpen && (
                            <ListItemText
                              primary={subItem.text}
                              primaryTypographyProps={{
                                fontSize: '0.8rem',
                                fontWeight: isActive(subItem.path) ? 600 : 400,
                                color: isActive(subItem.path) ? 'white' : 'rgba(255,255,255,0.8)',
                              }}
                            />
                          )}
                        </ListItemButton>
                      </ListItem>
                    ))}
                  </List>
                </Collapse>
              )}
            </React.Fragment>
          ))}
        </List>

        <Divider sx={{ borderColor: 'rgba(255,255,255,0.1)', mx: 2 }} />

        {/* Menu du bas avec design amélioré */}
        <List sx={{ py: 1, px: 1 }}>
          {bottomMenuItems.map((item) => (
            <ListItem key={item.text} disablePadding sx={{ mb: 0.5 }}>
              <ListItemButton
                onClick={() => handleNavigation(item.path)}
                selected={isActive(item.path)}
                sx={{
                  minHeight: 52,
                  px: sidebarOpen ? 2.5 : 2,
                  borderRadius: 2,
                  mx: 0.5,
                  position: 'relative',
                  '&::before': {
                    content: '""',
                    position: 'absolute',
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: isActive(item.path) ? 4 : 0,
                    backgroundColor: item.color,
                    transition: 'width 0.3s ease-in-out',
                  },
                  '&.Mui-selected': {
                    backgroundColor: 'rgba(255,255,255,0.15)',
                    color: 'white',
                    backdropFilter: 'blur(10px)',
                    border: '1px solid rgba(255,255,255,0.2)',
                    '&:hover': {
                      backgroundColor: 'rgba(255,255,255,0.2)',
                    },
                    '& .MuiListItemIcon-root': {
                      color: item.color,
                    },
                  },
                  '&:hover': {
                    backgroundColor: 'rgba(255,255,255,0.08)',
                    transform: 'translateX(4px)',
                  },
                  transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
                }}
              >
                <ListItemIcon
                  sx={{
                    minWidth: 0,
                    mr: sidebarOpen ? 2 : 0,
                    color: isActive(item.path) ? item.color : 'rgba(255,255,255,0.8)',
                    transition: 'all 0.2s ease-in-out',
                  }}
                >
                  {item.icon}
                </ListItemIcon>
                {sidebarOpen && (
                  <ListItemText
                    primary={item.text}
                    primaryTypographyProps={{
                      fontSize: '0.875rem',
                      fontWeight: isActive(item.path) ? 600 : 500,
                      color: isActive(item.path) ? 'white' : 'rgba(255,255,255,0.9)',
                    }}
                  />
                )}
              </ListItemButton>
            </ListItem>
          ))}
        </List>

        {/* Section atelier avec design moderne */}
        <Box
          sx={{
            p: 2,
            borderTop: '1px solid rgba(255,255,255,0.1)',
            background: 'rgba(255,255,255,0.03)',
            backdropFilter: 'blur(10px)',
          }}
        >
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: sidebarOpen ? 'flex-start' : 'center',
            }}
          >
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: 32,
                height: 32,
                borderRadius: '50%',
                background: 'linear-gradient(135deg, #374151 0%, #4b5563 100%)',
                mr: sidebarOpen ? 1.5 : 0,
                boxShadow: '0 2px 8px rgba(0,0,0,0.2)',
              }}
            >
              <HandymanIcon 
                sx={{ 
                  fontSize: '1.1rem',
                  color: 'white',
                }} 
              />
            </Box>
            {sidebarOpen && (
              <Fade in={sidebarOpen} timeout={300}>
                <Box sx={{ minWidth: 0, flexGrow: 1 }}>
                  <Typography
                    variant="body2"
                    sx={{
                      fontWeight: 600,
                      color: 'white',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                      fontSize: '0.875rem',
                      textShadow: '0 1px 2px rgba(0,0,0,0.3)',
                    }}
                  >
                    {workshopSettings.name}
                  </Typography>
                  <Chip
                    label="Actif"
                    size="small"
                    sx={{
                      backgroundColor: 'rgba(76, 175, 80, 0.2)',
                      color: '#4caf50',
                      fontSize: '0.7rem',
                      height: 20,
                      mt: 0.5,
                      '& .MuiChip-label': {
                        px: 1,
                      },
                    }}
                  />
                </Box>
              </Fade>
            )}
          </Box>
        </Box>

        {/* Profil utilisateur avec design moderne */}
        <Box
          sx={{
            p: 2,
            borderTop: '1px solid rgba(255,255,255,0.1)',
            background: 'rgba(0,0,0,0.1)',
            backdropFilter: 'blur(10px)',
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
              <Fade in={sidebarOpen} timeout={300}>
                <Box sx={{ display: 'flex', alignItems: 'center', flexGrow: 1 }}>
                  <Avatar
                    src={currentUser?.avatar}
                    sx={{ 
                      width: 36, 
                      height: 36, 
                      mr: 1.5,
                      border: '2px solid rgba(255,255,255,0.3)',
                      boxShadow: '0 2px 8px rgba(0,0,0,0.2)',
                    }}
                  >
                    {currentUser?.firstName?.charAt(0)}
                  </Avatar>
                  <Box sx={{ minWidth: 0, flexGrow: 1 }}>
                    <Typography
                      variant="body2"
                      sx={{
                        fontWeight: 600,
                        color: 'white',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                        fontSize: '0.875rem',
                        textShadow: '0 1px 2px rgba(0,0,0,0.3)',
                      }}
                    >
                      {currentUser ? `${currentUser.firstName} ${currentUser.lastName}` : ''}
                    </Typography>
                    <Typography
                      variant="caption"
                      sx={{
                        color: 'rgba(255,255,255,0.7)',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                        fontSize: '0.75rem',
                      }}
                    >
                      {currentUser?.role}
                    </Typography>
                  </Box>
                </Box>
              </Fade>
            )}
            <Box sx={{ display: 'flex', gap: 0.5 }}>
              {sidebarOpen && (
                <Tooltip title="Réglages" arrow>
                  <IconButton 
                    size="small"
                    onClick={() => navigate('/app/settings')}
                    sx={{
                      color: 'rgba(255,255,255,0.8)',
                      backgroundColor: 'rgba(255,255,255,0.1)',
                      '&:hover': {
                        backgroundColor: 'rgba(255,255,255,0.15)',
                        color: 'white',
                      },
                      transition: 'all 0.2s ease-in-out',
                    }}
                  >
                    <AccountIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              )}
              <Tooltip title="Se déconnecter" arrow>
                <IconButton 
                  size="small" 
                  onClick={handleLogout}
                  sx={{
                    color: 'rgba(255,255,255,0.8)',
                    backgroundColor: 'rgba(255,255,255,0.1)',
                    '&:hover': {
                      backgroundColor: 'rgba(239, 68, 68, 0.2)',
                      color: '#ef4444',
                    },
                    transition: 'all 0.2s ease-in-out',
                  }}
                >
                  <LogoutIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </Box>
          </Box>
        </Box>
      </Box>
    </Drawer>
  );
};

export default Sidebar;
