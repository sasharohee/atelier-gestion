import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Chip,
  Divider,
  Fade,
  IconButton,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Paper,
  Avatar,
} from '@mui/material';
import {
  Close as CloseIcon,
  NewReleases as NewReleasesIcon,
  CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import { WhatsNewItem, whatsNewItems, getCategoryInfo } from '../config/whatsNew';

interface WhatsNewModalProps {
  open: boolean;
  onClose: () => void;
  onMarkAllAsRead: () => void;
  unreadCount: number;
}

const WhatsNewModal: React.FC<WhatsNewModalProps> = ({
  open,
  onClose,
  onMarkAllAsRead,
  unreadCount,
}) => {
  const sortedItems = [...whatsNewItems].sort((a, b) => 
    new Date(b.date).getTime() - new Date(a.date).getTime()
  );

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: 3,
          boxShadow: '0 20px 40px rgba(0,0,0,0.15)',
          maxHeight: '80vh',
        },
      }}
    >
      <DialogTitle
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          pb: 1,
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          color: 'white',
          borderRadius: '12px 12px 0 0',
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Avatar
            sx={{
              backgroundColor: 'rgba(255,255,255,0.2)',
              backdropFilter: 'blur(10px)',
            }}
          >
            <NewReleasesIcon />
          </Avatar>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, mb: 0.5 }}>
              Dernières nouveautés
            </Typography>
            <Typography variant="body2" sx={{ opacity: 0.9 }}>
              Découvrez les dernières améliorations
            </Typography>
          </Box>
        </Box>
        <IconButton
          onClick={onClose}
          sx={{
            color: 'white',
            backgroundColor: 'rgba(255,255,255,0.1)',
            '&:hover': {
              backgroundColor: 'rgba(255,255,255,0.2)',
            },
          }}
        >
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent sx={{ p: 0 }}>
        <List sx={{ p: 0 }}>
          {sortedItems.map((item, index) => {
            const categoryInfo = getCategoryInfo(item.category);
            return (
              <Fade
                key={item.id}
                in={true}
                timeout={300 + index * 100}
                style={{ transitionDelay: `${index * 50}ms` }}
              >
                <Paper
                  elevation={0}
                  sx={{
                    mx: 2,
                    mt: index === 0 ? 2 : 1,
                    mb: index === sortedItems.length - 1 ? 2 : 0,
                    borderRadius: 2,
                    border: '1px solid',
                    borderColor: item.isNew ? 'primary.main' : 'divider',
                    backgroundColor: item.isNew ? 'primary.50' : 'background.paper',
                    position: 'relative',
                    overflow: 'hidden',
                    '&::before': item.isNew ? {
                      content: '""',
                      position: 'absolute',
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 3,
                      background: `linear-gradient(90deg, ${categoryInfo.color} 0%, ${categoryInfo.color}80 100%)`,
                    } : {},
                  }}
                >
                  <ListItem
                    sx={{
                      py: 2.5,
                      px: 3,
                      alignItems: 'flex-start',
                    }}
                  >
                    <ListItemIcon sx={{ mt: 0.5, minWidth: 40 }}>
                      <Avatar
                        sx={{
                          width: 32,
                          height: 32,
                          backgroundColor: categoryInfo.color,
                          fontSize: '0.9rem',
                        }}
                      >
                        {categoryInfo.icon}
                      </Avatar>
                    </ListItemIcon>
                    
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                          <Typography
                            variant="h6"
                            sx={{
                              fontWeight: 600,
                              color: 'text.primary',
                              fontSize: '1rem',
                            }}
                          >
                            {item.title}
                          </Typography>
                          {item.isNew && (
                            <Chip
                              label="Nouveau"
                              size="small"
                              sx={{
                                backgroundColor: 'primary.main',
                                color: 'white',
                                fontSize: '0.7rem',
                                height: 20,
                                fontWeight: 600,
                              }}
                            />
                          )}
                        </Box>
                      }
                      secondary={
                        <Box>
                          <Typography
                            variant="body2"
                            sx={{
                              color: 'text.secondary',
                              mb: 1,
                              lineHeight: 1.5,
                            }}
                          >
                            {item.description}
                          </Typography>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Chip
                              label={categoryInfo.label}
                              size="small"
                              sx={{
                                backgroundColor: `${categoryInfo.color}20`,
                                color: categoryInfo.color,
                                fontWeight: 500,
                                fontSize: '0.7rem',
                                height: 24,
                              }}
                            />
                            <Typography
                              variant="caption"
                              sx={{
                                color: 'text.secondary',
                                ml: 'auto',
                              }}
                            >
                              {new Date(item.date).toLocaleDateString('fr-FR', {
                                year: 'numeric',
                                month: 'long',
                                day: 'numeric',
                              })}
                            </Typography>
                          </Box>
                        </Box>
                      }
                    />
                  </ListItem>
                  
                  {index < sortedItems.length - 1 && (
                    <Divider sx={{ mx: 3 }} />
                  )}
                </Paper>
              </Fade>
            );
          })}
        </List>
      </DialogContent>

      <DialogActions
        sx={{
          p: 2,
          backgroundColor: 'grey.50',
          borderTop: '1px solid',
          borderColor: 'divider',
        }}
      >
        <Button
          onClick={onMarkAllAsRead}
          startIcon={<CheckCircleIcon />}
          variant="outlined"
          sx={{
            borderColor: 'primary.main',
            color: 'primary.main',
            '&:hover': {
              backgroundColor: 'primary.50',
              borderColor: 'primary.dark',
            },
          }}
        >
          Marquer tout comme lu
        </Button>
        <Button
          onClick={onClose}
          variant="contained"
          sx={{
            backgroundColor: 'primary.main',
            '&:hover': {
              backgroundColor: 'primary.dark',
            },
          }}
        >
          Fermer
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default WhatsNewModal;
