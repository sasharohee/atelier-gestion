import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Tabs,
  Tab,
  Grid,
  Chip,
  Divider,
  List,
  ListItem,
  ListItemText,
  Avatar,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
} from '@mui/material';
import {
  Close as CloseIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Build as BuildIcon,
  Euro as EuroIcon,
  AccessTime as AccessTimeIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Repair, Client, Device, User, Part, Service } from '../../types';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`repair-tabpanel-${index}`}
      aria-labelledby={`repair-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ py: 3 }}>{children}</Box>}
    </div>
  );
}

interface RepairDetailsDialogProps {
  open: boolean;
  onClose: () => void;
  repair: Repair;
  client: Client;
  device: Device | null;
  technician?: User | null;
  parts: Part[];
  services: Service[];
}

export const RepairDetailsDialog: React.FC<RepairDetailsDialogProps> = ({
  open,
  onClose,
  repair,
  client,
  device,
  technician,
  parts,
  services,
}) => {
  const [currentTab, setCurrentTab] = useState(0);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setCurrentTab(newValue);
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Box>
            <Typography variant="h6">
              Détails de la réparation
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {repair.repairNumber || `#${repair.id.slice(0, 8)}`}
            </Typography>
          </Box>
          <IconButton onClick={onClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>

      <Divider />

      <DialogContent sx={{ p: 0 }}>
        <Tabs value={currentTab} onChange={handleTabChange} variant="scrollable" scrollButtons="auto">
          <Tab label="Général" />
          <Tab label="Client & Appareil" />
          <Tab label="Notes" />
        </Tabs>

        {/* Onglet Général */}
        <TabPanel value={currentTab} index={0}>
          <Box sx={{ px: 3 }}>
            <Grid container spacing={3}>
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  Statut
                </Typography>
                <Chip label={repair.status} color="primary" size="small" sx={{ mb: 2 }} />

                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  Description
                </Typography>
                <Typography variant="body2" sx={{ mb: 2 }}>
                  {repair.description}
                </Typography>

                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  Problème
                </Typography>
                <Typography variant="body2" sx={{ mb: 2 }}>
                  {repair.issue || 'Non spécifié'}
                </Typography>

                {repair.notes && (
                  <>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      Notes
                    </Typography>
                    <Typography variant="body2" sx={{ mb: 2 }}>
                      {repair.notes}
                    </Typography>
                  </>
                )}
              </Grid>

              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  Dates
                </Typography>
                <List dense>
                  <ListItem>
                    <ListItemText
                      primary="Date de création"
                      secondary={format(new Date(repair.createdAt), 'dd MMMM yyyy à HH:mm', { locale: fr })}
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemText
                      primary="Date limite"
                      secondary={format(new Date(repair.dueDate), 'dd MMMM yyyy', { locale: fr })}
                    />
                  </ListItem>
                  {repair.startDate && (
                    <ListItem>
                      <ListItemText
                        primary="Date de début"
                        secondary={format(new Date(repair.startDate), 'dd MMMM yyyy à HH:mm', { locale: fr })}
                      />
                    </ListItem>
                  )}
                  {repair.endDate && (
                    <ListItem>
                      <ListItemText
                        primary="Date de fin"
                        secondary={format(new Date(repair.endDate), 'dd MMMM yyyy à HH:mm', { locale: fr })}
                      />
                    </ListItem>
                  )}
                </List>

                <Typography variant="subtitle2" color="text.secondary" gutterBottom sx={{ mt: 2 }}>
                  Durée
                </Typography>
                <List dense>
                  <ListItem>
                    <ListItemText
                      primary="Durée estimée"
                      secondary={`${repair.estimatedDuration} minutes`}
                    />
                  </ListItem>
                  {repair.actualDuration && (
                    <ListItem>
                      <ListItemText
                        primary="Durée réelle"
                        secondary={`${repair.actualDuration} minutes`}
                      />
                    </ListItem>
                  )}
                </List>

                <Box sx={{ display: 'flex', gap: 1, mt: 2 }}>
                  {repair.isUrgent && (
                    <Chip icon={<WarningIcon />} label="Urgent" color="error" size="small" />
                  )}
                  {repair.isPaid && (
                    <Chip icon={<CheckCircleIcon />} label="Payé" color="success" size="small" />
                  )}
                </Box>
              </Grid>
            </Grid>
          </Box>
        </TabPanel>

        {/* Onglet Client & Appareil */}
        <TabPanel value={currentTab} index={1}>
          <Box sx={{ px: 3 }}>
            <Grid container spacing={3}>
              {/* Informations client */}
              <Grid item xs={12} md={6}>
                <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <PersonIcon /> Client
                </Typography>
                <List>
                  <ListItem>
                    <ListItemText
                      primary="Nom complet"
                      secondary={`${client.firstName} ${client.lastName}`}
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemText
                      primary={<Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}><EmailIcon fontSize="small" /> Email</Box>}
                      secondary={client.email}
                    />
                  </ListItem>
                  {client.phone && (
                    <ListItem>
                      <ListItemText
                        primary={<Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}><PhoneIcon fontSize="small" /> Téléphone</Box>}
                        secondary={client.phone}
                      />
                    </ListItem>
                  )}
                  {client.address && (
                    <ListItem>
                      <ListItemText
                        primary="Adresse"
                        secondary={client.address}
                      />
                    </ListItem>
                  )}
                </List>
              </Grid>

              {/* Informations appareil */}
              <Grid item xs={12} md={6}>
                <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <BuildIcon /> Appareil
                </Typography>
                {device ? (
                  <List>
                    <ListItem>
                      <ListItemText
                        primary="Marque"
                        secondary={device.brand}
                      />
                    </ListItem>
                    <ListItem>
                      <ListItemText
                        primary="Modèle"
                        secondary={device.model}
                      />
                    </ListItem>
                    <ListItem>
                      <ListItemText
                        primary="Type"
                        secondary={device.type}
                      />
                    </ListItem>
                    {device.serialNumber && (
                      <ListItem>
                        <ListItemText
                          primary="Numéro de série"
                          secondary={device.serialNumber}
                        />
                      </ListItem>
                    )}
                  </List>
                ) : (
                  <Typography variant="body2" color="text.secondary">
                    Aucune information d'appareil disponible
                  </Typography>
                )}

                {/* Technicien assigné */}
                {technician && (
                  <Box sx={{ mt: 3 }}>
                    <Typography variant="h6" gutterBottom>
                      Technicien assigné
                    </Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Avatar sx={{ bgcolor: '#6366f1' }}>
                        {technician.firstName[0]}{technician.lastName[0]}
                      </Avatar>
                      <Box>
                        <Typography variant="body1">
                          {technician.firstName} {technician.lastName}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {technician.email}
                        </Typography>
                      </Box>
                    </Box>
                  </Box>
                )}
              </Grid>
            </Grid>
          </Box>
        </TabPanel>


        {/* Onglet Notes */}
        <TabPanel value={currentTab} index={2}>
          <Box sx={{ px: 3 }}>
            <Typography variant="h6" gutterBottom>
              Notes et historique
            </Typography>
            {repair.notes ? (
              <Paper variant="outlined" sx={{ p: 2 }}>
                <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>
                  {repair.notes}
                </Typography>
              </Paper>
            ) : (
              <Typography variant="body2" color="text.secondary">
                Aucune note disponible
              </Typography>
            )}
          </Box>
        </TabPanel>
      </DialogContent>

      <Divider />

      <DialogActions sx={{ p: 2 }}>
        <Button onClick={onClose} variant="contained">
          Fermer
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default RepairDetailsDialog;







