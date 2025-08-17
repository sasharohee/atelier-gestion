import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Avatar,
  Button,
  TextField,
  Divider,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
} from '@mui/material';
import {
  Send as SendIcon,
  Add as AddIcon,
  Reply as ReplyIcon,
  Delete as DeleteIcon,
  Message as MessageIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';

const Messaging: React.FC = () => {
  const {
    messages,
    clients,
    users,
    getClientById,
    getUserById,
    markMessageAsRead,
  } = useAppStore();

  const [selectedMessage, setSelectedMessage] = useState<any>(null);
  const [newMessageDialogOpen, setNewMessageDialogOpen] = useState(false);
  const [replyText, setReplyText] = useState('');

  const handleMessageClick = (message: any) => {
    setSelectedMessage(message);
    if (!message.isRead) {
      markMessageAsRead(message.id);
    }
  };

  const handleSendReply = () => {
    // Logique d'envoi de réponse
    setReplyText('');
  };

  const getSenderName = (senderId: string) => {
    const user = getUserById(senderId);
    const client = getClientById(senderId);
    return user?.name || `${client?.firstName} ${client?.lastName}` || 'Inconnu';
  };

  const getSenderAvatar = (senderId: string) => {
    const user = getUserById(senderId);
    const client = getClientById(senderId);
    return user?.avatar || client?.firstName?.charAt(0) || '?';
  };

  return (
    <Box>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
          Messagerie
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Communication interne et avec les clients
        </Typography>
      </Box>

      {/* Actions */}
      <Box sx={{ mb: 3 }}>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setNewMessageDialogOpen(true)}
        >
          Nouveau message
        </Button>
      </Box>

      <Grid container spacing={3}>
        {/* Liste des messages */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Messages
              </Typography>
              <List>
                {messages
                  .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
                  .map((message, index) => (
                    <React.Fragment key={message.id}>
                      <ListItem
                        button
                        selected={selectedMessage?.id === message.id}
                        onClick={() => handleMessageClick(message)}
                        sx={{
                          backgroundColor: !message.isRead ? 'action.hover' : 'transparent',
                          '&.Mui-selected': {
                            backgroundColor: 'primary.light',
                            color: 'primary.contrastText',
                          },
                        }}
                      >
                        <ListItemAvatar>
                          <Avatar>
                            {getSenderAvatar(message.senderId)}
                          </Avatar>
                        </ListItemAvatar>
                        <ListItemText
                          primary={
                            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                              <Typography variant="subtitle2" sx={{ fontWeight: !message.isRead ? 600 : 400 }}>
                                {getSenderName(message.senderId)}
                              </Typography>
                              {!message.isRead && (
                                <Chip label="Nouveau" size="small" color="primary" />
                              )}
                            </Box>
                          }
                          secondary={
                            <Box>
                              <Typography variant="body2" sx={{ fontWeight: !message.isRead ? 600 : 400 }}>
                                {message.subject}
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                {format(new Date(message.createdAt), 'dd/MM/yyyy HH:mm', { locale: fr })}
                              </Typography>
                            </Box>
                          }
                        />
                      </ListItem>
                      {index < messages.length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Détail du message */}
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              {selectedMessage ? (
                <Box>
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                    <Typography variant="h6">
                      {selectedMessage.subject}
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 1 }}>
                      <IconButton size="small">
                        <ReplyIcon />
                      </IconButton>
                      <IconButton size="small">
                        <DeleteIcon />
                      </IconButton>
                    </Box>
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
                    <Avatar>
                      {getSenderAvatar(selectedMessage.senderId)}
                    </Avatar>
                    <Box>
                      <Typography variant="subtitle1">
                        {getSenderName(selectedMessage.senderId)}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {format(new Date(selectedMessage.createdAt), 'dd/MM/yyyy HH:mm', { locale: fr })}
                      </Typography>
                    </Box>
                  </Box>

                  <Typography variant="body1" sx={{ mb: 3 }}>
                    {selectedMessage.content}
                  </Typography>

                  <Divider sx={{ my: 3 }} />

                  {/* Zone de réponse */}
                  <Typography variant="h6" gutterBottom>
                    Répondre
                  </Typography>
                  <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-end' }}>
                    <TextField
                      fullWidth
                      multiline
                      rows={3}
                      placeholder="Tapez votre réponse..."
                      value={replyText}
                      onChange={(e) => setReplyText(e.target.value)}
                    />
                    <Button
                      variant="contained"
                      endIcon={<SendIcon />}
                      onClick={handleSendReply}
                      disabled={!replyText.trim()}
                    >
                      Envoyer
                    </Button>
                  </Box>
                </Box>
              ) : (
                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 400 }}>
                  <Box sx={{ textAlign: 'center' }}>
                    <MessageIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
                    <Typography variant="h6" color="text.secondary" gutterBottom>
                      Sélectionnez un message
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Choisissez un message dans la liste pour le consulter
                    </Typography>
                  </Box>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Dialog nouveau message */}
      <Dialog open={newMessageDialogOpen} onClose={() => setNewMessageDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nouveau message</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Destinataire"
                placeholder="Sélectionnez un destinataire"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Objet"
                placeholder="Objet du message"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Message"
                multiline
                rows={6}
                placeholder="Contenu du message"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewMessageDialogOpen(false)}>Annuler</Button>
          <Button variant="contained" endIcon={<SendIcon />}>
            Envoyer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Messaging;
