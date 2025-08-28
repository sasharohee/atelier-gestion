import React, { useState } from 'react';
import {
  Box,
  Container,
  Typography,
  Paper,
  Breadcrumbs,
  Link,
  Divider,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip,
  TextField,
  InputAdornment,
  Grid,
  Card,
  CardContent,
  Button
} from '@mui/material';
import { 
  NavigateNext as NavigateNextIcon,
  ExpandMore as ExpandMoreIcon,
  Search as SearchIcon,
  Help as HelpIcon,
  AccountCircle as AccountIcon,
  Payment as PaymentIcon,
  Security as SecurityIcon,
  Settings as SettingsIcon,
  ArrowBack as ArrowBackIcon
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

const FAQ: React.FC = () => {
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');
  const [expanded, setExpanded] = useState<string | false>(false);

  const handleBreadcrumbClick = () => {
    navigate('/');
  };

  const handleChange = (panel: string) => (event: React.SyntheticEvent, isExpanded: boolean) => {
    setExpanded(isExpanded ? panel : false);
  };

  const faqData = [
    {
      category: 'Comptabilité',
      icon: <PaymentIcon />,
      color: '#e74c3c',
      questions: [
        {
          question: "Comment résilier mon abonnement ?",
          answer: "Vous pouvez résilier votre abonnement à tout moment via vos paramètres de compte ou en contactant notre équipe support. La résiliation prendra effet à la fin de la période de facturation en cours."
        },
        {
          question: "Y a-t-il des frais de résiliation ?",
          answer: "Non, il n'y a aucun frais de résiliation. Vous pouvez annuler votre abonnement à tout moment sans pénalité."
        }
      ]
    },
    {
      category: 'Compte et Utilisateurs',
      icon: <AccountIcon />,
      color: '#3498db',
      questions: [
        {
          question: "Comment ajouter un nouvel utilisateur ?",
          answer: "Les administrateurs peuvent ajouter des utilisateurs via la section 'Administration' > 'Gestion des accès utilisateurs'. Cliquez sur 'Ajouter un utilisateur' et remplissez les informations requises."
        },
        {
          question: "Comment modifier les permissions d'un utilisateur ?",
          answer: "Dans la section 'Administration' > 'Gestion des accès utilisateurs', cliquez sur l'utilisateur concerné et modifiez ses rôles et permissions selon vos besoins."
        },
        {
          question: "Comment réinitialiser mon mot de passe ?",
          answer: "Utilisez l'option 'Mot de passe oublié' sur la page de connexion. Un email de réinitialisation vous sera envoyé avec un lien sécurisé."
        },
        {
          question: "Comment activer l'authentification à deux facteurs ?",
          answer: "Accédez à vos paramètres de sécurité dans la section 'Réglages' et suivez les instructions pour configurer l'authentification à deux facteurs."
        }
      ]
    },
    {
      category: 'Données et Sécurité',
      icon: <SecurityIcon />,
      color: '#27ae60',
      questions: [
        {
          question: "Mes données sont-elles sécurisées ?",
          answer: "Oui, nous utilisons un chiffrement SSL/TLS pour toutes les communications et stockons vos données sur des serveurs sécurisés conformes au RGPD."
        },
        {
          question: "Comment supprimer définitivement mes données ?",
          answer: "Contactez notre équipe support pour demander la suppression complète de vos données. Cette action est irréversible et supprimera toutes vos informations."
        }
      ]
    },

    {
      category: 'Fonctionnalités',
      icon: <HelpIcon />,
      color: '#9b59b6',
      questions: [
        {
          question: "Comment créer un nouveau projet de réparation ?",
          answer: "Accédez à la section 'Suivi des Réparations' et cliquez sur 'Nouvelle réparation'. Remplissez les informations du client et de l'appareil à réparer."
        },
        {
          question: "Comment gérer mon inventaire ?",
          answer: "Utilisez la section 'Catalogue' > 'Inventaire' pour ajouter, modifier ou supprimer des pièces détachées et suivre vos stocks."
        },
        {
          question: "Comment planifier un rendez-vous ?",
          answer: "Dans la section 'Calendrier', cliquez sur une date et heure disponible pour créer un nouveau rendez-vous avec un client."
        },
        {
          question: "Comment générer des rapports ?",
          answer: "Accédez à la section 'Statistiques' pour générer des rapports sur vos performances, ventes, réparations et autres métriques importantes."
        }
      ]
    }
  ];

  const filteredFAQ = faqData.map(category => ({
    ...category,
    questions: category.questions.filter(q =>
      q.question.toLowerCase().includes(searchTerm.toLowerCase()) ||
      q.answer.toLowerCase().includes(searchTerm.toLowerCase())
    )
  })).filter(category => category.questions.length > 0);

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f8f9fa', py: 4 }}>
      <Container maxWidth="lg">
        {/* Breadcrumbs */}
        <Breadcrumbs 
          separator={<NavigateNextIcon fontSize="small" />}
          sx={{ mb: 4 }}
        >
          <Link
            color="inherit"
            href="#"
            onClick={handleBreadcrumbClick}
            sx={{ cursor: 'pointer', '&:hover': { textDecoration: 'underline' } }}
          >
            Accueil
          </Link>
          <Typography color="text.primary">FAQ</Typography>
        </Breadcrumbs>

        <Typography variant="h3" component="h1" sx={{ mb: 2, fontWeight: 700, color: '#2c3e50', textAlign: 'center' }}>
          Questions Fréquemment Posées
        </Typography>

        <Typography variant="h6" sx={{ mb: 4, textAlign: 'center', color: '#6c757d', maxWidth: 600, mx: 'auto' }}>
          Trouvez rapidement des réponses à vos questions sur Atelier Gestion
        </Typography>

        {/* Barre de recherche */}
        <Box sx={{ mb: 4, maxWidth: 500, mx: 'auto' }}>
          <TextField
            fullWidth
            placeholder="Rechercher dans les FAQ..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon sx={{ color: '#6c757d' }} />
                </InputAdornment>
              ),
            }}
            variant="outlined"
            sx={{
              '& .MuiOutlinedInput-root': {
                borderRadius: '25px',
                backgroundColor: 'white',
                '&:hover': {
                  '& .MuiOutlinedInput-notchedOutline': {
                    borderColor: '#3498db',
                  },
                },
              },
            }}
          />
        </Box>

        {/* Statistiques */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ textAlign: 'center', p: 2 }}>
              <CardContent>
                <Typography variant="h4" sx={{ color: '#3498db', fontWeight: 700 }}>
                  {faqData.reduce((total, category) => total + category.questions.length, 0)}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Questions disponibles
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ textAlign: 'center', p: 2 }}>
              <CardContent>
                <Typography variant="h4" sx={{ color: '#27ae60', fontWeight: 700 }}>
                  {faqData.length}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Catégories
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ textAlign: 'center', p: 2 }}>
              <CardContent>
                <Typography variant="h4" sx={{ color: '#f39c12', fontWeight: 700 }}>
                  24h
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Temps de réponse
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ textAlign: 'center', p: 2 }}>
              <CardContent>
                <Typography variant="h4" sx={{ color: '#e74c3c', fontWeight: 700 }}>
                  95%
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Satisfaction client
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* FAQ par catégories */}
        {filteredFAQ.map((category, categoryIndex) => (
          <Box key={categoryIndex} sx={{ mb: 4 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
              <Box sx={{ 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center',
                width: 50,
                height: 50,
                borderRadius: '50%',
                backgroundColor: `${category.color}20`,
                color: category.color,
                mr: 2
              }}>
                {category.icon}
              </Box>
              <Typography variant="h4" sx={{ fontWeight: 600, color: '#2c3e50' }}>
                {category.category}
              </Typography>
            </Box>

            <Paper sx={{ borderRadius: 2, overflow: 'hidden' }}>
              {category.questions.map((item, questionIndex) => (
                <Accordion
                  key={questionIndex}
                  expanded={expanded === `${categoryIndex}-${questionIndex}`}
                  onChange={handleChange(`${categoryIndex}-${questionIndex}`)}
                  sx={{
                    '&:before': {
                      display: 'none',
                    },
                    '&:not(:last-child)': {
                      borderBottom: '1px solid #e0e0e0',
                    },
                  }}
                >
                  <AccordionSummary
                    expandIcon={<ExpandMoreIcon />}
                    sx={{
                      backgroundColor: expanded === `${categoryIndex}-${questionIndex}` ? '#f8f9fa' : 'white',
                      '&:hover': {
                        backgroundColor: '#f8f9fa',
                      },
                    }}
                  >
                    <Typography variant="h6" sx={{ fontWeight: 500, color: '#2c3e50' }}>
                      {item.question}
                    </Typography>
                  </AccordionSummary>
                  <AccordionDetails sx={{ backgroundColor: '#f8f9fa', py: 3 }}>
                    <Typography variant="body1" sx={{ lineHeight: 1.7, color: '#495057' }}>
                      {item.answer}
                    </Typography>
                  </AccordionDetails>
                </Accordion>
              ))}
            </Paper>
          </Box>
        ))}

        {/* Message si aucune FAQ trouvée */}
        {filteredFAQ.length === 0 && searchTerm && (
          <Box sx={{ textAlign: 'center', py: 4 }}>
            <Typography variant="h6" sx={{ mb: 2, color: '#6c757d' }}>
              Aucune FAQ trouvée pour "{searchTerm}"
            </Typography>
            <Typography variant="body1" sx={{ mb: 3, color: '#6c757d' }}>
              Essayez avec d'autres mots-clés ou contactez notre équipe support.
            </Typography>
            <Button
              variant="outlined"
              onClick={() => setSearchTerm('')}
              sx={{ mr: 2 }}
            >
              Effacer la recherche
            </Button>
            <Button
              variant="contained"
              onClick={() => navigate('/support')}
              startIcon={<ArrowBackIcon />}
            >
              Contacter le Support
            </Button>
          </Box>
        )}

        {/* Section contact */}
        <Box sx={{ mt: 6, textAlign: 'center' }}>
          <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
            Vous n'avez pas trouvé votre réponse ?
          </Typography>
          <Typography variant="body1" sx={{ mb: 3, color: '#6c757d' }}>
            Notre équipe support est là pour vous aider
          </Typography>
          <Button
            variant="contained"
            size="large"
            onClick={() => navigate('/support')}
            sx={{
              background: 'linear-gradient(45deg, #3498db, #2980b9)',
              color: 'white',
              px: 4,
              py: 1.5,
              fontSize: '1.1rem',
              fontWeight: 600,
              '&:hover': {
                background: 'linear-gradient(45deg, #2980b9, #1f5f8b)'
              }
            }}
          >
            Contacter le Support
          </Button>
        </Box>
      </Container>
    </Box>
  );
};

export default FAQ;
