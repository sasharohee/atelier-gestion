import React, { useState, useEffect } from 'react';
import {
  IconButton,
  Badge,
  Tooltip,
  Fade,
} from '@mui/material';
import {
  NewReleases as NewReleasesIcon,
} from '@mui/icons-material';
import WhatsNewModal from './WhatsNewModal';
import { whatsNewItems } from '../config/whatsNew';

const STORAGE_KEY = 'app-atelier-last-read-news';

const WhatsNewButton: React.FC = () => {
  const [modalOpen, setModalOpen] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);

  // Calculer le nombre de nouveautés non lues
  useEffect(() => {
    const calculateUnreadCount = () => {
      try {
        const lastReadDate = localStorage.getItem(STORAGE_KEY);
        if (!lastReadDate) {
          // Si aucune date stockée, toutes les nouveautés sont non lues
          setUnreadCount(whatsNewItems.length);
          return;
        }

        const lastRead = new Date(lastReadDate);
        const unreadItems = whatsNewItems.filter(item => 
          new Date(item.date) > lastRead
        );
        setUnreadCount(unreadItems.length);
      } catch (error) {
        console.error('Erreur lors du calcul des nouveautés non lues:', error);
        setUnreadCount(0);
      }
    };

    calculateUnreadCount();

    // Écouter l'événement personnalisé pour ouvrir la modal
    const handleOpenWhatsNew = () => {
      setModalOpen(true);
    };

    window.addEventListener('openWhatsNew', handleOpenWhatsNew);
    
    return () => {
      window.removeEventListener('openWhatsNew', handleOpenWhatsNew);
    };
  }, []);

  const handleOpenModal = () => {
    setModalOpen(true);
  };

  const handleCloseModal = () => {
    setModalOpen(false);
  };

  const handleMarkAllAsRead = () => {
    try {
      // Marquer toutes les nouveautés comme lues en stockant la date actuelle
      const currentDate = new Date().toISOString();
      localStorage.setItem(STORAGE_KEY, currentDate);
      setUnreadCount(0);
    } catch (error) {
      console.error('Erreur lors du marquage des nouveautés comme lues:', error);
    }
  };

  return (
    <>
      <Tooltip title="Dernières nouveautés" arrow>
        <IconButton
          onClick={handleOpenModal}
          sx={{
            backgroundColor: 'rgba(0,0,0,0.04)',
            color: 'text.primary',
            '&:hover': {
              backgroundColor: 'rgba(0,0,0,0.08)',
              transform: 'scale(1.05)',
            },
            transition: 'all 0.2s ease-in-out',
            position: 'relative',
          }}
        >
          <Badge
            badgeContent={unreadCount}
            color="error"
            sx={{
              '& .MuiBadge-badge': {
                backgroundColor: '#ff4757',
                color: 'white',
                fontWeight: 600,
                fontSize: '0.7rem',
                minWidth: 18,
                height: 18,
                borderRadius: '50%',
                boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
              },
            }}
          >
            <NewReleasesIcon />
          </Badge>
        </IconButton>
      </Tooltip>

      <WhatsNewModal
        open={modalOpen}
        onClose={handleCloseModal}
        onMarkAllAsRead={handleMarkAllAsRead}
        unreadCount={unreadCount}
      />
    </>
  );
};

export default WhatsNewButton;
