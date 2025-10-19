import React, { useState } from 'react';
import {
  SpeedDial,
  SpeedDialAction,
  SpeedDialIcon,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Box,
} from '@mui/material';
import {
  Edit as EditIcon,
  Print as PrintIcon,
  Receipt as ReceiptIcon,
  Description as DescriptionIcon,
  Notes as NotesIcon,
  Timer as TimerIcon,
  Payment as PaymentIcon,
} from '@mui/icons-material';
import { Repair } from '../../types';

interface QuickActionsProps {
  repair: Repair;
  onStatusChange: (repair: Repair, newStatus: string) => void;
  onAddNote: (repair: Repair, note: string) => void;
  onPrintWorkOrder: (repair: Repair) => void;
  onPrintReceipt: (repair: Repair) => void;
  onGenerateInvoice: (repair: Repair) => void;
  onPrintCompleteTicket?: (repair: Repair) => void;
  onPaymentStatusChange?: (repair: Repair, isPaid: boolean) => void;
}

export const QuickActions: React.FC<QuickActionsProps> = ({
  repair,
  onStatusChange,
  onAddNote,
  onPrintWorkOrder,
  onPrintReceipt,
  onGenerateInvoice,
  onPrintCompleteTicket,
  onPaymentStatusChange,
}) => {
  const [noteDialogOpen, setNoteDialogOpen] = useState(false);
  const [noteText, setNoteText] = useState('');

  const handleAddNote = () => {
    if (noteText.trim()) {
      onAddNote(repair, noteText);
      setNoteText('');
      setNoteDialogOpen(false);
    }
  };

  const actions = [
    {
      icon: <DescriptionIcon />,
      name: 'Bon de travail',
      onClick: () => onPrintWorkOrder(repair),
    },
    {
      icon: <ReceiptIcon />,
      name: 'Reçu de dépôt',
      onClick: () => onPrintReceipt(repair),
    },
    {
      icon: <PaymentIcon />,
      name: 'Facture',
      onClick: () => onGenerateInvoice(repair),
    },
    ...(onPrintCompleteTicket ? [{
      icon: <DescriptionIcon />,
      name: 'Ticket SAV complet',
      onClick: () => onPrintCompleteTicket(repair),
    }] : []),
    ...(onPaymentStatusChange ? [
      ...(repair.isPaid ? [{
        icon: <PaymentIcon />,
        name: 'Marquer non payé',
        onClick: () => onPaymentStatusChange(repair, false),
      }] : [{
        icon: <PaymentIcon />,
        name: 'Marquer payé',
        onClick: () => onPaymentStatusChange(repair, true),
      }])
    ] : []),
    {
      icon: <NotesIcon />,
      name: 'Ajouter note',
      onClick: () => setNoteDialogOpen(true),
    },
  ];

  return (
    <>
      <SpeedDial
        ariaLabel="Actions rapides"
        sx={{ position: 'fixed', bottom: 24, right: 24 }}
        icon={<SpeedDialIcon />}
      >
        {actions.map((action) => (
          <SpeedDialAction
            key={action.name}
            icon={action.icon}
            tooltipTitle={action.name}
            onClick={action.onClick}
          />
        ))}
      </SpeedDial>

      {/* Dialog pour ajouter une note */}
      <Dialog open={noteDialogOpen} onClose={() => setNoteDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Ajouter une note</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            <TextField
              fullWidth
              multiline
              rows={4}
              label="Note"
              value={noteText}
              onChange={(e) => setNoteText(e.target.value)}
              placeholder="Entrez votre note ici..."
              autoFocus
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNoteDialogOpen(false)}>Annuler</Button>
          <Button onClick={handleAddNote} variant="contained" disabled={!noteText.trim()}>
            Ajouter
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default QuickActions;







