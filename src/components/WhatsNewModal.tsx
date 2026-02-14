import React from 'react';
import {
  Dialog,
  DialogContent,
  Button,
  Typography,
  Box,
  Chip,
  IconButton,
  alpha,
} from '@mui/material';
import {
  CloseOutlined as CloseIcon,
  AutoAwesomeOutlined as SparkleIcon,
  BoltOutlined as BoltIcon,
  BuildOutlined as WrenchIcon,
  CheckOutlined as CheckIcon,
  ArrowForwardOutlined as ArrowIcon,
} from '@mui/icons-material';
import { WhatsNewItem, whatsNewItems, getCategoryInfo } from '../config/whatsNew';

interface WhatsNewModalProps {
  open: boolean;
  onClose: () => void;
  onMarkAllAsRead: () => void;
  unreadCount: number;
}

const CategoryIcon: React.FC<{ icon: string; color: string }> = ({ icon, color }) => {
  const iconMap: Record<string, React.ReactNode> = {
    sparkles: <SparkleIcon sx={{ fontSize: '1rem', color }} />,
    bolt: <BoltIcon sx={{ fontSize: '1rem', color }} />,
    wrench: <WrenchIcon sx={{ fontSize: '1rem', color }} />,
  };
  return <>{iconMap[icon] || iconMap.sparkles}</>;
};

const WhatsNewModal: React.FC<WhatsNewModalProps> = ({
  open,
  onClose,
  onMarkAllAsRead,
  unreadCount,
}) => {
  const sortedItems = [...whatsNewItems].sort((a, b) =>
    new Date(b.date).getTime() - new Date(a.date).getTime()
  );

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    const now = new Date();
    const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return "Aujourd'hui";
    if (diffDays === 1) return 'Hier';
    if (diffDays < 7) return `Il y a ${diffDays} jours`;

    return date.toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'short',
      year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined,
    });
  };

  // Grouper par mois/année
  const grouped = sortedItems.reduce<Record<string, WhatsNewItem[]>>((acc, item) => {
    const date = new Date(item.date);
    const now = new Date();
    const key = date.getFullYear() === now.getFullYear()
      ? date.toLocaleDateString('fr-FR', { month: 'long' })
      : String(date.getFullYear());
    if (!acc[key]) acc[key] = [];
    acc[key].push(item);
    return acc;
  }, {});

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: '16px',
          boxShadow: '0 24px 80px rgba(0,0,0,0.16), 0 0 0 1px rgba(0,0,0,0.04)',
          maxHeight: '85vh',
          overflow: 'hidden',
        },
      }}
    >
      {/* Header */}
      <Box sx={{
        px: 3,
        pt: 3,
        pb: 2,
        display: 'flex',
        alignItems: 'flex-start',
        justifyContent: 'space-between',
      }}>
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
            <Box sx={{
              width: 32,
              height: 32,
              borderRadius: '10px',
              background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              boxShadow: '0 0 16px rgba(99, 102, 241, 0.2)',
            }}>
              <SparkleIcon sx={{ fontSize: '1.1rem', color: 'white' }} />
            </Box>
            <Typography sx={{
              fontWeight: 700,
              color: '#0f172a',
              fontSize: '1.15rem',
              letterSpacing: '-0.01em',
            }}>
              Nouveautés
            </Typography>
            {unreadCount > 0 && (
              <Chip
                label={`${unreadCount} nouveau${unreadCount > 1 ? 'x' : ''}`}
                size="small"
                sx={{
                  background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
                  color: 'white',
                  fontWeight: 600,
                  fontSize: '0.65rem',
                  height: 22,
                }}
              />
            )}
          </Box>
          <Typography sx={{
            color: '#94a3b8',
            fontSize: '0.8rem',
            fontWeight: 450,
            pl: 5.5,
          }}>
            Les dernières mises à jour de votre atelier
          </Typography>
        </Box>
        <IconButton
          onClick={onClose}
          size="small"
          sx={{
            width: 32,
            height: 32,
            color: '#94a3b8',
            '&:hover': {
              color: '#475569',
              backgroundColor: 'rgba(0,0,0,0.04)',
            },
            transition: 'all 0.12s ease-out',
          }}
        >
          <CloseIcon sx={{ fontSize: '1.1rem' }} />
        </IconButton>
      </Box>

      {/* Contenu */}
      <DialogContent sx={{
        px: 3,
        py: 0,
        pb: 2,
        '&::-webkit-scrollbar': { width: 5 },
        '&::-webkit-scrollbar-track': { background: 'transparent' },
        '&::-webkit-scrollbar-thumb': { background: 'rgba(0,0,0,0.08)', borderRadius: 4 },
        '&::-webkit-scrollbar-thumb:hover': { background: 'rgba(0,0,0,0.15)' },
      }}>
        {Object.entries(grouped).map(([monthLabel, items], groupIndex) => (
          <Box key={monthLabel} sx={{ mb: 2 }}>
            {/* Label du mois */}
            <Box sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1.5,
              mb: 1.5,
              mt: groupIndex === 0 ? 0 : 1,
            }}>
              <Typography sx={{
                fontSize: '0.68rem',
                fontWeight: 600,
                color: '#94a3b8',
                textTransform: 'uppercase',
                letterSpacing: '0.08em',
                whiteSpace: 'nowrap',
              }}>
                {monthLabel}
              </Typography>
              <Box sx={{
                flexGrow: 1,
                height: 1,
                backgroundColor: 'rgba(0,0,0,0.05)',
              }} />
            </Box>

            {/* Items */}
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
              {items.map((item) => {
                const catInfo = getCategoryInfo(item.category);
                return (
                  <Box
                    key={item.id}
                    sx={{
                      position: 'relative',
                      p: 2,
                      borderRadius: '12px',
                      border: '1px solid',
                      borderColor: item.isNew
                        ? alpha(catInfo.color, 0.2)
                        : 'rgba(0,0,0,0.05)',
                      background: item.isNew
                        ? alpha(catInfo.color, 0.03)
                        : 'white',
                      transition: 'all 0.15s ease-out',
                      '&:hover': {
                        borderColor: alpha(catInfo.color, 0.25),
                        background: alpha(catInfo.color, 0.04),
                        boxShadow: `0 2px 12px ${alpha(catInfo.color, 0.08)}`,
                      },
                    }}
                  >
                    {/* Top row : icon + catégorie + date */}
                    <Box sx={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      mb: 1,
                    }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Box sx={{
                          width: 26,
                          height: 26,
                          borderRadius: '8px',
                          backgroundColor: catInfo.bgColor,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          flexShrink: 0,
                        }}>
                          <CategoryIcon icon={catInfo.icon} color={catInfo.color} />
                        </Box>
                        <Chip
                          label={catInfo.label}
                          size="small"
                          sx={{
                            backgroundColor: catInfo.bgColor,
                            color: catInfo.color,
                            fontWeight: 600,
                            fontSize: '0.65rem',
                            height: 22,
                            border: `1px solid ${alpha(catInfo.color, 0.12)}`,
                            '& .MuiChip-label': { px: 1 },
                          }}
                        />
                        {item.isNew && (
                          <Box sx={{
                            width: 6,
                            height: 6,
                            borderRadius: '50%',
                            backgroundColor: catInfo.color,
                            boxShadow: `0 0 6px ${alpha(catInfo.color, 0.4)}`,
                            flexShrink: 0,
                          }} />
                        )}
                      </Box>
                      <Typography sx={{
                        fontSize: '0.7rem',
                        color: '#94a3b8',
                        fontWeight: 500,
                        whiteSpace: 'nowrap',
                      }}>
                        {formatDate(item.date)}
                      </Typography>
                    </Box>

                    {/* Titre */}
                    <Typography sx={{
                      fontWeight: 650,
                      color: '#1e293b',
                      fontSize: '0.88rem',
                      lineHeight: 1.3,
                      mb: 0.5,
                      letterSpacing: '-0.005em',
                    }}>
                      {item.title}
                    </Typography>

                    {/* Description */}
                    <Typography sx={{
                      color: '#64748b',
                      fontSize: '0.8rem',
                      lineHeight: 1.55,
                      fontWeight: 400,
                    }}>
                      {item.description}
                    </Typography>
                  </Box>
                );
              })}
            </Box>
          </Box>
        ))}
      </DialogContent>

      {/* Footer */}
      <Box sx={{
        px: 3,
        py: 2,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        borderTop: '1px solid rgba(0,0,0,0.05)',
        background: '#fafbfc',
      }}>
        {unreadCount > 0 ? (
          <Button
            onClick={onMarkAllAsRead}
            startIcon={<CheckIcon sx={{ fontSize: '1rem !important' }} />}
            size="small"
            sx={{
              color: '#64748b',
              fontSize: '0.78rem',
              fontWeight: 500,
              textTransform: 'none',
              px: 1.5,
              '&:hover': {
                backgroundColor: 'rgba(0,0,0,0.04)',
                color: '#334155',
              },
              transition: 'all 0.12s ease-out',
            }}
          >
            Tout marquer comme lu
          </Button>
        ) : (
          <Typography sx={{ fontSize: '0.75rem', color: '#94a3b8', fontWeight: 500 }}>
            Tout est à jour
          </Typography>
        )}
        <Button
          onClick={onClose}
          size="small"
          sx={{
            background: '#0f172a',
            color: 'white',
            fontSize: '0.78rem',
            fontWeight: 600,
            textTransform: 'none',
            px: 2.5,
            py: 0.8,
            borderRadius: '8px',
            boxShadow: 'none',
            '&:hover': {
              background: '#1e293b',
              boxShadow: '0 2px 8px rgba(15, 23, 42, 0.2)',
            },
            transition: 'all 0.12s ease-out',
          }}
          variant="contained"
        >
          Fermer
        </Button>
      </Box>
    </Dialog>
  );
};

export default WhatsNewModal;
