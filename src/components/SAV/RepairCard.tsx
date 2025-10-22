import React, { useState, useEffect } from 'react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
  IconButton,
  Tooltip,
  Avatar,
  Stack,
  Badge,
} from '@mui/material';
import {
  Timer as TimerIcon,
  PlayArrow as PlayIcon,
  Pause as PauseIcon,
  Stop as StopIcon,
  Print as PrintIcon,
  Visibility as VisibilityIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Payment as PaymentIcon,
  AccessTime as AccessTimeIcon,
  Phone as PhoneIcon,
  Build as BuildIcon,
  Check as CheckIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Repair, Client, Device, User, RepairStatus } from '../../types';
import { savService } from '../../services/savService';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

// Fonction helper pour mapper les noms de statuts
const getDisplayStatusName = (statusName: string): string => {
  const name = statusName.toLowerCase();
  if (name.includes('new') || name.includes('nouvelle')) {
    return 'Prise en charge';
  }
  return statusName;
};

interface RepairCardProps {
  repair: Repair;
  client: Client;
  device: Device | null;
  technician?: User | null;
  repairStatus: RepairStatus;
  onViewDetails: (repair: Repair) => void;
  onPrint: (repair: Repair, type: 'label' | 'work_order' | 'deposit_receipt' | 'invoice' | 'complete_ticket') => void;
  onPrintCompleteTicket?: (repair: Repair) => void;
  onPaymentStatusChange?: (repair: Repair, isPaid: boolean) => void;
  onClick?: () => void;
}

export const RepairCard: React.FC<RepairCardProps> = ({
  repair,
  client,
  device,
  technician,
  repairStatus,
  onViewDetails,
  onPrint,
  onPrintCompleteTicket,
  onPaymentStatusChange,
  onClick,
}) => {
  const { workshopSettings } = useWorkshopSettings();
  
  // Valeur par défaut pour éviter les erreurs
  const currency = workshopSettings?.currency || 'EUR';
  
  const [timer, setTimer] = useState(savService.getTimer(repair.id));
  const [currentTime, setCurrentTime] = useState(Date.now());

  // Mettre à jour le timer toutes les secondes
  useEffect(() => {
    const interval = setInterval(() => {
      const updatedTimer = savService.getTimer(repair.id);
      setTimer(updatedTimer);
      setCurrentTime(Date.now());
    }, 1000);

    return () => clearInterval(interval);
  }, [repair.id]);

  // Gestion du timer
  const handleStartTimer = (e: React.MouseEvent) => {
    e.stopPropagation();
    const newTimer = savService.startTimer(repair.id);
    setTimer(newTimer);
  };

  const handlePauseTimer = (e: React.MouseEvent) => {
    e.stopPropagation();
    const pausedTimer = savService.pauseTimer(repair.id);
    setTimer(pausedTimer);
  };

  const handleResumeTimer = (e: React.MouseEvent) => {
    e.stopPropagation();
    const resumedTimer = savService.resumeTimer(repair.id);
    setTimer(resumedTimer);
  };

  const handleStopTimer = (e: React.MouseEvent) => {
    e.stopPropagation();
    const stoppedTimer = savService.stopTimer(repair.id);
    setTimer(stoppedTimer);
  };

  // Calculer si la réparation est en retard
  const timeRemaining = savService.getTimeRemaining(repair.dueDate);
  const isOverdue = timeRemaining.isOverdue;

  // Obtenir la couleur du statut
  const getStatusColor = () => {
    return repairStatus.color || '#6b7280';
  };

  return (
    <Card
      sx={{
        mb: 2,
        cursor: onClick ? 'pointer' : 'default',
        transition: 'all 0.2s',
        border: repair.isUrgent ? '2px solid #ef4444' : '1px solid #e5e7eb',
        '&:hover': {
          transform: onClick ? 'translateY(-2px)' : 'none',
          boxShadow: onClick ? 4 : 1,
        },
      }}
      onClick={onClick}
    >
      <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
        {/* En-tête avec numéro et statut */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1.5 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flex: 1 }}>
            <Typography variant="subtitle2" fontWeight="bold" sx={{ color: '#1f2937' }}>
              {repair.repairNumber || `#${repair.id.slice(0, 8)}`}
            </Typography>
            {repair.isUrgent && (
              <Tooltip title="Réparation urgente">
                <WarningIcon sx={{ fontSize: 18, color: '#ef4444' }} />
              </Tooltip>
            )}
          </Box>
          <Chip
            label={getDisplayStatusName(repairStatus.name)}
            size="small"
            sx={{
              backgroundColor: getStatusColor(),
              color: '#fff',
              fontWeight: 600,
              fontSize: '0.7rem',
              height: 22,
            }}
          />
        </Box>

        {/* Client et appareil */}
        <Box sx={{ mb: 1.5 }}>
          <Typography variant="body2" sx={{ fontWeight: 600, color: '#374151', mb: 0.5 }}>
            {client.firstName} {client.lastName}
          </Typography>
          {device && (
            <Typography variant="caption" sx={{ color: '#6b7280', display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <BuildIcon sx={{ fontSize: 14 }} />
              {device.brand} {device.model}
            </Typography>
          )}
        </Box>

        {/* Description */}
        <Typography
          variant="body2"
          sx={{
            color: '#6b7280',
            mb: 1.5,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            display: '-webkit-box',
            WebkitLineClamp: 2,
            WebkitBoxOrient: 'vertical',
          }}
        >
          {repair.description}
        </Typography>

        {/* Date limite et timer */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1.5 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <AccessTimeIcon sx={{ fontSize: 16, color: isOverdue ? '#ef4444' : '#6b7280' }} />
            <Typography
              variant="caption"
              sx={{
                color: isOverdue ? '#ef4444' : '#6b7280',
                fontWeight: isOverdue ? 600 : 400,
              }}
            >
              {isOverdue ? 'Retard: ' : 'Reste: '}
              {timeRemaining.days > 0 && `${timeRemaining.days}j `}
              {timeRemaining.hours}h {timeRemaining.minutes}m
            </Typography>
          </Box>

          {/* Affichage du timer actif */}
          {timer && timer.isActive && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <TimerIcon sx={{ fontSize: 16, color: timer.isPaused ? '#f59e0b' : '#10b981' }} />
              <Typography
                variant="caption"
                sx={{
                  color: timer.isPaused ? '#f59e0b' : '#10b981',
                  fontWeight: 600,
                  fontFamily: 'monospace',
                }}
              >
                {savService.formatDuration(timer.totalDuration)}
              </Typography>
            </Box>
          )}
        </Box>

        {/* Technicien assigné */}
        {technician && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1.5 }}>
            <Avatar
              sx={{
                width: 24,
                height: 24,
                fontSize: '0.7rem',
                bgcolor: '#6366f1',
              }}
            >
              {technician.firstName[0]}{technician.lastName[0]}
            </Avatar>
            <Typography variant="caption" sx={{ color: '#6b7280' }}>
              {technician.firstName} {technician.lastName}
            </Typography>
          </Box>
        )}

        {/* Prix et statut de paiement */}
        {repair.totalPrice && repair.totalPrice > 0 && (
          <Box sx={{ 
            display: 'flex', 
            justifyContent: 'space-between', 
            alignItems: 'center', 
            mb: 1.5,
            p: 1,
            backgroundColor: repair.isPaid ? '#f0fdf4' : '#fef2f2',
            borderRadius: 1,
            border: `1px solid ${repair.isPaid ? '#10b981' : '#ef4444'}`,
          }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <PaymentIcon sx={{ 
                fontSize: 18, 
                color: repair.isPaid ? '#10b981' : '#ef4444' 
              }} />
              <Typography 
                variant="body2" 
                sx={{ 
                  fontWeight: 600,
                  color: repair.isPaid ? '#10b981' : '#ef4444',
                }}
              >
                {formatFromEUR(repair.totalPrice, currency)}
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {repair.isPaid ? (
                <>
                  <CheckCircleIcon sx={{ fontSize: 16, color: '#10b981' }} />
                  <Typography 
                    variant="caption" 
                    sx={{ 
                      color: '#10b981',
                      fontWeight: 600,
                    }}
                  >
                    PAYÉ
                  </Typography>
                </>
              ) : (
                <>
                  <CloseIcon sx={{ fontSize: 16, color: '#ef4444' }} />
                  <Typography 
                    variant="caption" 
                    sx={{ 
                      color: '#ef4444',
                      fontWeight: 600,
                    }}
                  >
                    NON PAYÉ
                  </Typography>
                </>
              )}
            </Box>
          </Box>
        )}

        {/* Actions rapides */}
        <Stack direction="row" spacing={0.5} justifyContent="flex-end">
          {/* Contrôles du timer */}
          {!timer || !timer.isActive ? (
            <Tooltip title="Démarrer le timer">
              <IconButton size="small" onClick={handleStartTimer} sx={{ color: '#10b981' }}>
                <PlayIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          ) : timer.isPaused ? (
            <>
              <Tooltip title="Reprendre">
                <IconButton size="small" onClick={handleResumeTimer} sx={{ color: '#10b981' }}>
                  <PlayIcon fontSize="small" />
                </IconButton>
              </Tooltip>
              <Tooltip title="Arrêter">
                <IconButton size="small" onClick={handleStopTimer} sx={{ color: '#ef4444' }}>
                  <StopIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </>
          ) : (
            <>
              <Tooltip title="Pause">
                <IconButton size="small" onClick={handlePauseTimer} sx={{ color: '#f59e0b' }}>
                  <PauseIcon fontSize="small" />
                </IconButton>
              </Tooltip>
              <Tooltip title="Arrêter">
                <IconButton size="small" onClick={handleStopTimer} sx={{ color: '#ef4444' }}>
                  <StopIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </>
          )}

          {/* Boutons de paiement */}
          {onPaymentStatusChange && (
            <>
              {!repair.isPaid && (
                <Tooltip title="Marquer comme payé">
                  <IconButton
                    size="small"
                    onClick={(e) => {
                      e.stopPropagation();
                      onPaymentStatusChange(repair, true);
                    }}
                    sx={{ color: '#16a34a' }}
                  >
                    <CheckIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              )}
              {repair.isPaid && (
                <Tooltip title="Marquer comme non payé">
                  <IconButton
                    size="small"
                    onClick={(e) => {
                      e.stopPropagation();
                      onPaymentStatusChange(repair, false);
                    }}
                    sx={{ color: '#dc2626' }}
                  >
                    <CloseIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              )}
            </>
          )}

          {/* Actions d'impression */}

          {/* Ticket complet */}
          <Tooltip title="Ticket SAV complet">
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                if (typeof onPrintCompleteTicket === 'function') {
                  onPrintCompleteTicket(repair);
                } else {
                  onPrint(repair, 'complete_ticket');
                }
              }}
              sx={{ color: '#16a34a' }}
            >
              <BuildIcon fontSize="small" />
            </IconButton>
          </Tooltip>

          {/* Voir détails */}
          <Tooltip title="Voir détails">
            <IconButton
              size="small"
              onClick={(e) => {
                e.stopPropagation();
                onViewDetails(repair);
              }}
              sx={{ color: '#3b82f6' }}
            >
              <VisibilityIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Stack>
      </CardContent>
    </Card>
  );
};

export default RepairCard;

