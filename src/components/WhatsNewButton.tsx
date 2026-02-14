import React, { useState, useEffect } from 'react';
import {
  IconButton,
  Badge,
  Tooltip,
  Box,
  alpha,
  keyframes,
} from '@mui/material';
import {
  AutoAwesomeOutlined as SparkleIcon,
} from '@mui/icons-material';
import WhatsNewModal from './WhatsNewModal';
import { whatsNewItems } from '../config/whatsNew';

const STORAGE_KEY = 'app-atelier-last-read-news';

const softPulse = keyframes`
  0%, 100% { box-shadow: 0 0 0 0 rgba(99, 102, 241, 0); }
  50% { box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.12); }
`;

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

  const hasUnread = unreadCount > 0;

  return (
    <>
      <Tooltip title="Nouveautés" arrow>
        <IconButton
          onClick={handleOpenModal}
          size="small"
          sx={{
            width: 34,
            height: 34,
            color: hasUnread ? '#6366f1' : '#94a3b8',
            backgroundColor: hasUnread ? alpha('#6366f1', 0.08) : 'transparent',
            border: '1px solid',
            borderColor: hasUnread ? alpha('#6366f1', 0.15) : 'transparent',
            animation: hasUnread ? `${softPulse} 3s ease-in-out infinite` : 'none',
            '&:hover': {
              backgroundColor: hasUnread ? alpha('#6366f1', 0.12) : 'rgba(0,0,0,0.04)',
              color: hasUnread ? '#6366f1' : '#475569',
            },
            transition: 'all 0.15s ease-out',
          }}
        >
          <Badge
            variant={hasUnread ? 'dot' : undefined}
            invisible={!hasUnread}
            sx={{
              '& .MuiBadge-badge': {
                backgroundColor: '#6366f1',
                width: 8,
                height: 8,
                minWidth: 8,
                border: '2px solid white',
                top: 2,
                right: 2,
              },
            }}
          >
            <SparkleIcon sx={{ fontSize: '1.15rem' }} />
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
