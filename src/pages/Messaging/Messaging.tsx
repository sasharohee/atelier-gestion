import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Avatar,
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
  Card,
  CardContent,
  Badge,
  Tooltip,
  Alert,
  InputAdornment,
} from '@mui/material';
import {
  Send as SendIcon,
  Search as SearchIcon,
  Add as AddIcon,
  Person as PersonIcon,
  Business as BusinessIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  AttachFile as AttachFileIcon,
  MoreVert as MoreVertIcon,
  Reply as ReplyIcon,
  Forward as ForwardIcon,
  Delete as DeleteIcon,
  MarkEmailRead as MarkEmailReadIcon,
  MarkEmailUnread as MarkEmailUnreadIcon,
} from '@mui/icons-material';
import { format, isToday, isYesterday } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useAppStore } from '../../store';
import { Message, Client, User, Repair } from '../../types';

const Messaging: React.FC = () => {
  const {
    messages,
    clients,
    users,
    repairs,
    addMessage,
    updateMessage,
    deleteMessage,
    getClientById,
    getUserById,
    getRepairById,
  } = useAppStore();

  const [selectedMessage, setSelectedMessage] = useState<Message | null>(null);
  const [newMessageDialog, setNewMessageDialog] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'unread' | 'sent' | 'received'>('all');
  const [selectedRecipient, setSelectedRecipient] = useState<string>('');
  const [messageText, setMessageText] = useState('');
  const [replyText, setReplyText] = useState('');
  const [recipientType, setRecipientType] = useState<'client' | 'user'>('client');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Filtrer les messages
  const filteredMessages = messages.filter(message => {
    const matchesSearch = message.subject.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         message.content.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesFilter = filterType === 'all' ||
                         (filterType === 'unread' && !message.isRead) ||
                         (filterType === 'sent' && message.senderId === 'current-user') ||
                         (filterType === 'received' && message.senderId !== 'current-user');
    
    return matchesSearch && matchesFilter;
  });

  // Grouper les messages par conversation
  const groupedMessages = filteredMessages.reduce((groups, message) => {
    const key = message.senderId === 'current-user' ? message.recipientId : message.senderId;
    if (!groups[key]) {
      groups[key] = [];
    }
    groups[key].push(message);
    return groups;
  }, {} as Record<string, Message[]>);

  // Obtenir les informations du destinataire
  const getRecipientInfo = (recipientId: string) => {
    const client = getClientById(recipientId);
    if (client) {
      return {
        name: `${client.firstName} ${client.lastName}`,
        type: 'client',
        avatar: client.firstName.charAt(0),
        email: client.email,
        phone: client.phone,
      };
    }
    
    const user = getUserById(recipientId);
    if (user) {
      return {
        name: `${user.firstName} ${user.lastName}`,
        type: 'user',
        avatar: user.firstName.charAt(0),
        email: user.email,
        role: user.role,
      };
    }
    
    return {
      name: 'Utilisateur inconnu',
      type: 'unknown',
      avatar: '?',
    };
  };

  // Obtenir les informations de l'expéditeur
  const getSenderInfo = (senderId: string) => {
    if (senderId === 'current-user') {
      return {
        name: 'Moi',
        type: 'current-user',
        avatar: 'M',
      };
    }
    return getRecipientInfo(senderId);
  };

  // Marquer un message comme lu
  const markAsRead = (messageId: string) => {
    updateMessage(messageId, { isRead: true });
  };

  // Envoyer un nouveau message
  const sendMessage = () => {
    if (!selectedRecipient || !messageText.trim()) return;

    const newMessage: Omit<Message, 'id'> = {
      subject: `Message de ${getRecipientInfo('current-user').name}`,
      content: messageText,
      senderId: 'current-user',
      recipientId: selectedRecipient,
      isRead: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    addMessage(newMessage);
    setNewMessageDialog(false);
    setSelectedRecipient('');
    setMessageText('');
  };

  // Répondre à un message
  const replyToMessage = () => {
    if (!selectedMessage || !replyText.trim()) return;

    const newMessage: Omit<Message, 'id'> = {
      subject: `Re: ${selectedMessage.subject}`,
      content: replyText,
      senderId: 'current-user',
      recipientId: selectedMessage.senderId === 'current-user' ? selectedMessage.recipientId : selectedMessage.senderId,
      isRead: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    addMessage(newMessage);
    setReplyText('');
  };

  // Formater la date
  const formatMessageDate = (date: Date) => {
    if (isToday(date)) {
      return format(date, 'HH:mm', { locale: fr });
    } else if (isYesterday(date)) {
      return 'Hier';
    } else {
      return format(date, 'dd/MM/yyyy', { locale: fr });
    }
  };

  // Scroll vers le bas automatiquement
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [selectedMessage]);

  return (
    <Box sx={{ p: 3, height: 'calc(100vh - 120px)' }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Messagerie
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setNewMessageDialog(true)}
        >
          Nouveau message
        </Button>
      </Box>

      <Grid container spacing={3} sx={{ height: 'calc(100% - 80px)' }}>
        {/* Liste des conversations */}
        <Grid item xs={12} md={4}>
          <Paper sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
            {/* Filtres et recherche */}
            <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider' }}>
              <TextField
                fullWidth
                placeholder="Rechercher dans les messages..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchIcon />
                    </InputAdornment>
                  ),
                }}
                sx={{ mb: 2 }}
              />
              <FormControl fullWidth size="small">
                <InputLabel>Filtrer</InputLabel>
                <Select
                  value={filterType}
                  onChange={(e) => setFilterType(e.target.value as any)}
                  label="Filtrer"
                >
                  <MenuItem value="all">Tous les messages</MenuItem>
                  <MenuItem value="unread">Non lus</MenuItem>
                  <MenuItem value="sent">Envoyés</MenuItem>
                  <MenuItem value="received">Reçus</MenuItem>
                </Select>
              </FormControl>
            </Box>

            {/* Liste des conversations */}
            <Box sx={{ flex: 1, overflow: 'auto' }}>
              {Object.entries(groupedMessages).map(([recipientId, conversationMessages]) => {
                const lastMessage = conversationMessages[conversationMessages.length - 1];
                const recipientInfo = getRecipientInfo(recipientId);
                const unreadCount = conversationMessages.filter(m => !m.isRead && m.senderId !== 'current-user').length;

                return (
                                     <ListItem
                     key={recipientId}
                     selected={!!(selectedMessage && 
                       (selectedMessage.senderId === recipientId || selectedMessage.recipientId === recipientId))}
                     onClick={() => {
                       setSelectedMessage(lastMessage);
                       if (lastMessage.senderId !== 'current-user') {
                         markAsRead(lastMessage.id);
                       }
                     }}
                     sx={{ borderBottom: 1, borderColor: 'divider', cursor: 'pointer' }}
                   >
                    <ListItemAvatar>
                      <Badge badgeContent={unreadCount} color="primary">
                        <Avatar>
                          {recipientInfo.avatar}
                        </Avatar>
                      </Badge>
                    </ListItemAvatar>
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Typography variant="subtitle2" fontWeight={unreadCount > 0 ? 'bold' : 'normal'}>
                            {recipientInfo.name}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {formatMessageDate(lastMessage.createdAt)}
                          </Typography>
                        </Box>
                      }
                      secondary={
                        <Typography
                          variant="body2"
                          color="text.secondary"
                          sx={{
                            fontWeight: unreadCount > 0 ? 'bold' : 'normal',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap',
                          }}
                        >
                          {lastMessage.content.substring(0, 50)}...
                        </Typography>
                      }
                    />
                  </ListItem>
                );
              })}
            </Box>
          </Paper>
        </Grid>

        {/* Détail du message */}
        <Grid item xs={12} md={8}>
          <Paper sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
            {selectedMessage ? (
              <>
                {/* En-tête du message */}
                <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider' }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <Box>
                      <Typography variant="h6" gutterBottom>
                        {selectedMessage.subject}
                      </Typography>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Avatar sx={{ width: 24, height: 24, fontSize: '0.75rem' }}>
                            {getSenderInfo(selectedMessage.senderId).avatar}
                          </Avatar>
                          <Typography variant="body2">
                            {getSenderInfo(selectedMessage.senderId).name}
                          </Typography>
                        </Box>
                        <Typography variant="caption" color="text.secondary">
                          {format(new Date(selectedMessage.createdAt), 'dd/MM/yyyy à HH:mm', { locale: fr })}
                        </Typography>
                        {!selectedMessage.isRead && selectedMessage.senderId !== 'current-user' && (
                          <Chip label="Non lu" size="small" color="primary" />
                        )}
                      </Box>
                    </Box>
                    <Box>
                      <IconButton onClick={() => setReplyText(`Re: ${selectedMessage.subject}\n\n${selectedMessage.content}`)}>
                        <ReplyIcon />
                      </IconButton>
                      <IconButton>
                        <ForwardIcon />
                      </IconButton>
                      <IconButton>
                        <DeleteIcon />
                      </IconButton>
                    </Box>
                  </Box>
                </Box>

                {/* Contenu du message */}
                <Box sx={{ flex: 1, p: 2, overflow: 'auto' }}>
                  <Typography variant="body1" sx={{ whiteSpace: 'pre-wrap' }}>
                    {selectedMessage.content}
                  </Typography>
                </Box>

                {/* Zone de réponse */}
                <Box sx={{ p: 2, borderTop: 1, borderColor: 'divider' }}>
                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    placeholder="Tapez votre réponse..."
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    sx={{ mb: 2 }}
                  />
                  <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 1 }}>
                    <Button
                      variant="outlined"
                      startIcon={<AttachFileIcon />}
                    >
                      Pièce jointe
                    </Button>
                    <Button
                      variant="contained"
                      startIcon={<SendIcon />}
                      onClick={replyToMessage}
                      disabled={!replyText.trim()}
                    >
                      Répondre
                    </Button>
                  </Box>
                </Box>
              </>
            ) : (
              <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="h6" color="text.secondary" gutterBottom>
                    Sélectionnez une conversation
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Choisissez une conversation dans la liste pour voir les messages
                  </Typography>
                </Box>
              </Box>
            )}
          </Paper>
        </Grid>
      </Grid>

      {/* Dialog nouveau message */}
      <Dialog open={newMessageDialog} onClose={() => setNewMessageDialog(false)} maxWidth="md" fullWidth>
        <DialogTitle>Nouveau message</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Type de destinataire</InputLabel>
                <Select
                  value={recipientType}
                  onChange={(e) => setRecipientType(e.target.value as 'client' | 'user')}
                  label="Type de destinataire"
                >
                  <MenuItem value="client">Client</MenuItem>
                  <MenuItem value="user">Utilisateur</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Destinataire</InputLabel>
                <Select
                  value={selectedRecipient}
                  onChange={(e) => setSelectedRecipient(e.target.value)}
                  label="Destinataire"
                >
                  {recipientType === 'client' ? (
                    clients.map((client) => (
                      <MenuItem key={client.id} value={client.id}>
                        {client.firstName} {client.lastName} - {client.email}
                      </MenuItem>
                    ))
                  ) : (
                    users.map((user) => (
                      <MenuItem key={user.id} value={user.id}>
                        {user.firstName} {user.lastName} ({user.role})
                      </MenuItem>
                    ))
                  )}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Sujet"
                placeholder="Sujet du message"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                multiline
                rows={6}
                label="Message"
                placeholder="Tapez votre message..."
                value={messageText}
                onChange={(e) => setMessageText(e.target.value)}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setNewMessageDialog(false)}>
            Annuler
          </Button>
          <Button
            variant="contained"
            startIcon={<SendIcon />}
            onClick={sendMessage}
            disabled={!selectedRecipient || !messageText.trim()}
          >
            Envoyer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Messaging;
