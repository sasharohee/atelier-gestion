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
  alpha,
} from '@mui/material';
import {
  SpaceDashboardOutlined as DashboardIcon,
  ViewKanbanOutlined as KanbanIcon,
  CalendarMonthOutlined as CalendarIcon,
  ChatBubbleOutlineOutlined as MessageIcon,
  CategoryOutlined as CatalogIcon,
  StorefrontOutlined as SalesIcon,
  InsightsOutlined as StatisticsIcon,
  TuneOutlined as AdminIcon,
  SettingsOutlined as SettingsIcon,
  PersonOutlineOutlined as AccountIcon,
  ChevronLeft as ChevronLeftIcon,
  BusinessOutlined as BusinessIcon,
  LogoutOutlined as LogoutIcon,
  ExpandLess as ExpandLessIcon,
  ExpandMore as ExpandMoreIcon,
  PeopleAltOutlined as PeopleIcon,
  PhoneOutlined as PhoneIcon,
  ReceiptLongOutlined as ReceiptIcon,
  DevicesOutlined as DeviceHubIcon,
  HomeRepairServiceOutlined as BuildIcon,
  ExtensionOutlined as MemoryIcon,
  Inventory2Outlined as Inventory2Icon,
  ReportGmailerrorredOutlined as WarningIcon,
  ConstructionOutlined as HandymanIcon,
  ArchiveOutlined as ArchiveIcon,
  DescriptionOutlined as DescriptionIcon,
  WorkspacePremiumOutlined as StarIcon,
  LocalShippingOutlined as ShippingIcon,
  AccountBalanceWalletOutlined as ExpensesIcon,
  RequestQuoteOutlined as RequestQuoteIcon,
  SwapHorizOutlined as BuybackIcon,
  AccountBalanceOutlined as AccountingIcon,
  FiberManualRecord as DotIcon,
  AutoAwesomeOutlined as SubscriptionIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
// import { GuideButton } from '../GuideButton'; // MASQUÉ
import { userService } from '../../services/supabaseService';

const drawerWidth = 272;
const collapsedWidth = 76;

interface MenuSection {
  label: string;
  items: MenuItem[];
}

interface MenuItem {
  text: string;
  icon: React.ReactNode;
  path: string;
  color: string;
  badge?: number;
  subItems?: SubMenuItem[];
}

interface SubMenuItem {
  text: string;
  path: string;
  icon: React.ReactNode;
}

const menuSections: MenuSection[] = [
  {
    label: 'Principal',
    items: [
      {
        text: 'Dashboard',
        icon: <DashboardIcon />,
        path: '/app/dashboard',
        color: '#6366f1',
      },
      {
        text: 'Suivi Réparations',
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
    ],
  },
  {
    label: 'Gestion',
    items: [
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
    ],
  },
  {
    label: 'Finances',
    items: [
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
        text: 'Rachat',
        icon: <BuybackIcon />,
        path: '/app/buyback',
        color: '#10b981',
      },
      {
        text: 'Comptabilité',
        icon: <AccountingIcon />,
        path: '/app/accounting',
        color: '#0ea5e9',
      },
    ],
  },
  {
    label: 'Autres',
    items: [
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
        text: 'Administration',
        icon: <AdminIcon />,
        path: '/app/administration',
        color: '#6b7280',
      },
    ],
  },
];

const bottomMenuItems = [
  {
    text: 'Abonnement',
    icon: <SubscriptionIcon />,
    path: '/app/subscription',
    color: '#f59e0b',
  },
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

  const renderMenuItem = (item: MenuItem, sectionColor?: string) => (
    <React.Fragment key={item.text}>
      <ListItem disablePadding sx={{ mb: 0.3 }}>
        <Tooltip title={!sidebarOpen ? item.text : ''} placement="right" arrow>
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
              minHeight: 44,
              px: sidebarOpen ? 1.5 : 1.5,
              py: 0.8,
              borderRadius: '10px',
              mx: 0.5,
              position: 'relative',
              '&.Mui-selected': {
                background: `linear-gradient(135deg, ${alpha(item.color, 0.15)} 0%, ${alpha(item.color, 0.08)} 100%)`,
                '&:hover': {
                  background: `linear-gradient(135deg, ${alpha(item.color, 0.2)} 0%, ${alpha(item.color, 0.12)} 100%)`,
                },
                '& .MuiListItemIcon-root': {
                  color: item.color,
                },
                '& .nav-item-text': {
                  color: 'white',
                  fontWeight: 600,
                },
              },
              '&:hover': {
                background: 'rgba(255,255,255,0.06)',
              },
              transition: 'all 0.15s ease-out',
            }}
          >
            <ListItemIcon
              sx={{
                minWidth: 0,
                mr: sidebarOpen ? 1.5 : 0,
                justifyContent: 'center',
                color: isActive(item.path) ? item.color : 'rgba(255,255,255,0.55)',
                transition: 'color 0.15s ease-out',
                '& .MuiSvgIcon-root': {
                  fontSize: '1.25rem',
                },
              }}
            >
              {item.text === 'Messagerie' ? (
                <Badge
                  badgeContent={unreadMessages}
                  color="error"
                  sx={{
                    '& .MuiBadge-badge': {
                      backgroundColor: '#ef4444',
                      color: 'white',
                      fontWeight: 600,
                      fontSize: '0.65rem',
                      minWidth: 16,
                      height: 16,
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
                  className="nav-item-text"
                  primaryTypographyProps={{
                    fontSize: '0.82rem',
                    fontWeight: isActive(item.path) ? 600 : 450,
                    color: isActive(item.path) ? 'white' : 'rgba(255,255,255,0.75)',
                    letterSpacing: '0.01em',
                    noWrap: true,
                  }}
                />
                {item.subItems && (
                  <Box sx={{
                    color: 'rgba(255,255,255,0.4)',
                    display: 'flex',
                    alignItems: 'center',
                    '& .MuiSvgIcon-root': { fontSize: '1.1rem' },
                  }}>
                    {openSubMenus[item.text] ? <ExpandLessIcon /> : <ExpandMoreIcon />}
                  </Box>
                )}
              </>
            )}
          </ListItemButton>
        </Tooltip>
      </ListItem>

      {/* Sous-menus */}
      {item.subItems && (
        <Collapse in={openSubMenus[item.text]} timeout={200} unmountOnExit>
          <List component="div" disablePadding sx={{ pl: sidebarOpen ? 1 : 0, pb: 0.5 }}>
            {item.subItems.map((subItem) => (
              <ListItem key={subItem.text} disablePadding sx={{ mb: 0.2 }}>
                <Tooltip title={!sidebarOpen ? subItem.text : ''} placement="right" arrow>
                  <ListItemButton
                    onClick={() => handleNavigation(subItem.path)}
                    selected={isActive(subItem.path)}
                    sx={{
                      minHeight: 36,
                      pl: sidebarOpen ? 3 : 1.5,
                      pr: sidebarOpen ? 2 : 1.5,
                      borderRadius: '8px',
                      mx: 0.5,
                      '&.Mui-selected': {
                        background: `linear-gradient(135deg, ${alpha(item.color, 0.12)} 0%, ${alpha(item.color, 0.06)} 100%)`,
                        '&:hover': {
                          background: `linear-gradient(135deg, ${alpha(item.color, 0.18)} 0%, ${alpha(item.color, 0.1)} 100%)`,
                        },
                        '& .MuiListItemIcon-root': {
                          color: item.color,
                        },
                      },
                      '&:hover': {
                        background: 'rgba(255,255,255,0.04)',
                      },
                      transition: 'all 0.15s ease-out',
                    }}
                  >
                    <ListItemIcon
                      sx={{
                        minWidth: 0,
                        mr: sidebarOpen ? 1.2 : 0,
                        color: isActive(subItem.path) ? item.color : 'rgba(255,255,255,0.4)',
                        '& .MuiSvgIcon-root': {
                          fontSize: '1rem',
                        },
                      }}
                    >
                      {subItem.icon}
                    </ListItemIcon>
                    {sidebarOpen && (
                      <ListItemText
                        primary={subItem.text}
                        primaryTypographyProps={{
                          fontSize: '0.78rem',
                          fontWeight: isActive(subItem.path) ? 600 : 400,
                          color: isActive(subItem.path) ? 'white' : 'rgba(255,255,255,0.6)',
                          noWrap: true,
                        }}
                      />
                    )}
                  </ListItemButton>
                </Tooltip>
              </ListItem>
            ))}
          </List>
        </Collapse>
      )}
    </React.Fragment>
  );

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: sidebarOpen ? drawerWidth : collapsedWidth,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: sidebarOpen ? drawerWidth : collapsedWidth,
          boxSizing: 'border-box',
          transition: 'width 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
          overflowX: 'hidden',
          background: '#0f172a',
          borderRight: '1px solid rgba(255,255,255,0.06)',
          boxShadow: 'none',
        },
      }}
    >
      <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
        {/* Header / Brand */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: sidebarOpen ? 'space-between' : 'center',
            px: sidebarOpen ? 2 : 1,
            py: 2,
            minHeight: 68,
          }}
        >
          {sidebarOpen && (
            <Fade in={sidebarOpen} timeout={200}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.2 }}>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: 36,
                    height: 36,
                    borderRadius: '10px',
                    background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
                    boxShadow: '0 0 20px rgba(99, 102, 241, 0.25)',
                  }}
                >
                  <HandymanIcon
                    sx={{
                      fontSize: '1.2rem',
                      color: 'white',
                    }}
                  />
                </Box>
                <Box sx={{ minWidth: 0 }}>
                  <Typography
                    sx={{
                      fontWeight: 700,
                      color: 'white',
                      fontSize: '0.95rem',
                      letterSpacing: '-0.01em',
                      lineHeight: 1.2,
                    }}
                  >
                    Atelier
                  </Typography>
                  <Typography
                    sx={{
                      color: 'rgba(255,255,255,0.4)',
                      fontSize: '0.65rem',
                      fontWeight: 500,
                      letterSpacing: '0.08em',
                      textTransform: 'uppercase',
                    }}
                  >
                    Gestion Pro
                  </Typography>
                </Box>
              </Box>
            </Fade>
          )}
          <IconButton
            onClick={toggleSidebar}
            size="small"
            sx={{
              color: 'rgba(255,255,255,0.4)',
              width: 30,
              height: 30,
              '&:hover': {
                color: 'rgba(255,255,255,0.8)',
                backgroundColor: 'rgba(255,255,255,0.06)',
              },
              transition: 'all 0.15s ease-out',
            }}
          >
            <ChevronLeftIcon
              sx={{
                fontSize: '1.2rem',
                transform: sidebarOpen ? 'rotate(0deg)' : 'rotate(180deg)',
                transition: 'transform 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
              }}
            />
          </IconButton>
        </Box>

        {/* Navigation */}
        <Box
          sx={{
            flexGrow: 1,
            overflowY: 'auto',
            overflowX: 'hidden',
            px: 0.5,
            pb: 1,
            '&::-webkit-scrollbar': {
              width: 4,
            },
            '&::-webkit-scrollbar-track': {
              background: 'transparent',
            },
            '&::-webkit-scrollbar-thumb': {
              background: 'rgba(255,255,255,0.1)',
              borderRadius: 4,
            },
            '&::-webkit-scrollbar-thumb:hover': {
              background: 'rgba(255,255,255,0.2)',
            },
          }}
        >
          {menuSections.map((section, index) => (
            <Box key={section.label}>
              {sidebarOpen && (
                <Typography
                  sx={{
                    fontSize: '0.65rem',
                    fontWeight: 600,
                    color: 'rgba(255,255,255,0.3)',
                    textTransform: 'uppercase',
                    letterSpacing: '0.1em',
                    px: 2,
                    pt: index === 0 ? 0.5 : 2,
                    pb: 0.8,
                  }}
                >
                  {section.label}
                </Typography>
              )}
              {!sidebarOpen && index > 0 && (
                <Box sx={{
                  mx: 2,
                  my: 1,
                  borderTop: '1px solid rgba(255,255,255,0.06)',
                }} />
              )}
              <List disablePadding>
                {section.items.map((item) => renderMenuItem(item))}
              </List>
            </Box>
          ))}
        </Box>

        {/* Bottom section */}
        <Box sx={{
          borderTop: '1px solid rgba(255,255,255,0.06)',
          px: 0.5,
          pt: 0.5,
        }}>
          <List disablePadding>
            {bottomMenuItems.map((item) => (
              <ListItem key={item.text} disablePadding sx={{ mb: 0.3 }}>
                <Tooltip title={!sidebarOpen ? item.text : ''} placement="right" arrow>
                  <ListItemButton
                    onClick={() => handleNavigation(item.path)}
                    selected={isActive(item.path)}
                    sx={{
                      minHeight: 44,
                      px: 1.5,
                      py: 0.8,
                      borderRadius: '10px',
                      mx: 0.5,
                      '&.Mui-selected': {
                        background: `linear-gradient(135deg, ${alpha(item.color, 0.15)} 0%, ${alpha(item.color, 0.08)} 100%)`,
                        '&:hover': {
                          background: `linear-gradient(135deg, ${alpha(item.color, 0.2)} 0%, ${alpha(item.color, 0.12)} 100%)`,
                        },
                        '& .MuiListItemIcon-root': {
                          color: item.color,
                        },
                      },
                      '&:hover': {
                        background: 'rgba(255,255,255,0.06)',
                      },
                      transition: 'all 0.15s ease-out',
                    }}
                  >
                    <ListItemIcon
                      sx={{
                        minWidth: 0,
                        mr: sidebarOpen ? 1.5 : 0,
                        justifyContent: 'center',
                        color: isActive(item.path) ? item.color : 'rgba(255,255,255,0.55)',
                        '& .MuiSvgIcon-root': {
                          fontSize: '1.25rem',
                        },
                      }}
                    >
                      {item.icon}
                    </ListItemIcon>
                    {sidebarOpen && (
                      <ListItemText
                        primary={item.text}
                        primaryTypographyProps={{
                          fontSize: '0.82rem',
                          fontWeight: isActive(item.path) ? 600 : 450,
                          color: isActive(item.path) ? 'white' : 'rgba(255,255,255,0.75)',
                          letterSpacing: '0.01em',
                        }}
                      />
                    )}
                  </ListItemButton>
                </Tooltip>
              </ListItem>
            ))}
          </List>
        </Box>

        {/* Workshop info */}
        <Box
          sx={{
            mx: 1,
            mb: 1,
            mt: 0.5,
            p: sidebarOpen ? 1.5 : 1,
            borderRadius: '12px',
            background: 'rgba(255,255,255,0.03)',
            border: '1px solid rgba(255,255,255,0.06)',
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
                borderRadius: '8px',
                background: 'rgba(255,255,255,0.06)',
                mr: sidebarOpen ? 1.2 : 0,
                flexShrink: 0,
              }}
            >
              <HandymanIcon
                sx={{
                  fontSize: '1rem',
                  color: 'rgba(255,255,255,0.5)',
                }}
              />
            </Box>
            {sidebarOpen && (
              <Fade in={sidebarOpen} timeout={200}>
                <Box sx={{ minWidth: 0, flexGrow: 1 }}>
                  <Typography
                    sx={{
                      fontWeight: 600,
                      color: 'rgba(255,255,255,0.85)',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                      fontSize: '0.8rem',
                    }}
                  >
                    {workshopSettings.name}
                  </Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.3 }}>
                    <DotIcon sx={{ fontSize: 8, color: '#22c55e' }} />
                    <Typography
                      sx={{
                        color: '#22c55e',
                        fontSize: '0.65rem',
                        fontWeight: 500,
                      }}
                    >
                      Actif
                    </Typography>
                  </Box>
                </Box>
              </Fade>
            )}
          </Box>
        </Box>

        {/* User profile */}
        <Box
          sx={{
            mx: 1,
            mb: 1,
            p: sidebarOpen ? 1.5 : 1,
            borderRadius: '12px',
            background: 'rgba(255,255,255,0.03)',
            border: '1px solid rgba(255,255,255,0.06)',
            cursor: 'pointer',
            transition: 'all 0.15s ease-out',
            '&:hover': {
              background: 'rgba(255,255,255,0.06)',
            },
          }}
        >
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: sidebarOpen ? 'space-between' : 'center',
            }}
          >
            <Box sx={{
              display: 'flex',
              alignItems: 'center',
              minWidth: 0,
              flexGrow: 1,
              justifyContent: sidebarOpen ? 'flex-start' : 'center',
            }}>
              <Avatar
                src={currentUser?.avatar}
                sx={{
                  width: 32,
                  height: 32,
                  mr: sidebarOpen ? 1.2 : 0,
                  fontSize: '0.8rem',
                  fontWeight: 600,
                  background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
                  border: '2px solid rgba(255,255,255,0.1)',
                  flexShrink: 0,
                }}
              >
                {currentUser?.firstName?.charAt(0)}
              </Avatar>
              {sidebarOpen && (
                <Fade in={sidebarOpen} timeout={200}>
                  <Box sx={{ minWidth: 0, flexGrow: 1 }}>
                    <Typography
                      sx={{
                        fontWeight: 600,
                        color: 'rgba(255,255,255,0.85)',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                        fontSize: '0.8rem',
                        lineHeight: 1.3,
                      }}
                    >
                      {currentUser ? `${currentUser.firstName} ${currentUser.lastName}` : ''}
                    </Typography>
                    <Typography
                      sx={{
                        color: 'rgba(255,255,255,0.4)',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                        fontSize: '0.7rem',
                      }}
                    >
                      {currentUser?.role}
                    </Typography>
                  </Box>
                </Fade>
              )}
            </Box>
            {sidebarOpen && (
              <Tooltip title="Se déconnecter" arrow>
                <IconButton
                  size="small"
                  onClick={(e) => {
                    e.stopPropagation();
                    handleLogout();
                  }}
                  sx={{
                    color: 'rgba(255,255,255,0.35)',
                    width: 28,
                    height: 28,
                    '&:hover': {
                      color: '#ef4444',
                      backgroundColor: 'rgba(239, 68, 68, 0.1)',
                    },
                    transition: 'all 0.15s ease-out',
                  }}
                >
                  <LogoutIcon sx={{ fontSize: '1rem' }} />
                </IconButton>
              </Tooltip>
            )}
          </Box>
        </Box>
      </Box>
    </Drawer>
  );
};

export default Sidebar;
