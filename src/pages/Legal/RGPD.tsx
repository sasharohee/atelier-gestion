import React from 'react';
import {
  Box,
  Container,
  Typography,
  Paper,
  Breadcrumbs,
  Link,
  Divider,
  List,
  ListItem,
  ListItemText,
  Chip,
  Alert,
  Accordion,
  AccordionSummary,
  AccordionDetails
} from '@mui/material';
import { 
  NavigateNext as NavigateNextIcon,
  ExpandMore as ExpandMoreIcon,
  Security as SecurityIcon,
  Person as PersonIcon,
  Storage as StorageIcon,
  Delete as DeleteIcon
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

const RGPD: React.FC = () => {
  const navigate = useNavigate();

  const handleBreadcrumbClick = () => {
    navigate('/');
  };

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
          <Typography color="text.primary">RGPD - Protection des Données</Typography>
        </Breadcrumbs>

        <Paper sx={{ p: 4, borderRadius: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
            <SecurityIcon sx={{ fontSize: 40, color: '#2c3e50', mr: 2 }} />
            <Typography variant="h3" component="h1" sx={{ fontWeight: 700, color: '#2c3e50' }}>
              Règlement Général sur la Protection des Données (RGPD)
            </Typography>
          </Box>
          
          <Typography variant="body1" sx={{ mb: 4, color: '#6c757d' }}>
            Dernière mise à jour : {new Date().toLocaleDateString('fr-FR')}
          </Typography>

          <Alert severity="info" sx={{ mb: 4 }}>
            <Typography variant="body2">
              Atelier Gestion s'engage à respecter le Règlement Général sur la Protection des Données (RGPD) 
              et à protéger vos données personnelles. Cette page détaille nos pratiques de conformité.
            </Typography>
          </Alert>

          <Divider sx={{ mb: 4 }} />

          {/* Introduction */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              1. Qu'est-ce que le RGPD ?
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Le Règlement Général sur la Protection des Données (RGPD) est un règlement européen 
              qui renforce et unifie la protection des données personnelles des citoyens de l'Union européenne. 
              Il s'applique à toutes les organisations qui traitent des données personnelles de résidents européens.
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Atelier Gestion, en tant que responsable du traitement, s'engage à respecter scrupuleusement 
              les principes et obligations du RGPD.
            </Typography>
          </Box>

          {/* Principes fondamentaux */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              2. Principes fondamentaux du RGPD
            </Typography>
            
            <Accordion sx={{ mb: 2 }}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Licéité, loyauté et transparence
                </Typography>
              </AccordionSummary>
              <AccordionDetails>
                <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
                  Nous traitons vos données de manière licite, loyale et transparente. 
                  Vous êtes informé de la finalité du traitement et de vos droits.
                </Typography>
              </AccordionDetails>
            </Accordion>

            <Accordion sx={{ mb: 2 }}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Limitation des finalités
                </Typography>
              </AccordionSummary>
              <AccordionDetails>
                <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
                  Vos données sont collectées pour des finalités déterminées, explicites et légitimes. 
                  Elles ne sont pas traitées ultérieurement de manière incompatible avec ces finalités.
                </Typography>
              </AccordionDetails>
            </Accordion>

            <Accordion sx={{ mb: 2 }}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Minimisation des données
                </Typography>
              </AccordionSummary>
              <AccordionDetails>
                <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
                  Nous ne collectons que les données strictement nécessaires à la réalisation 
                  des finalités pour lesquelles elles sont traitées.
                </Typography>
              </AccordionDetails>
            </Accordion>

            <Accordion sx={{ mb: 2 }}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Exactitude
                </Typography>
              </AccordionSummary>
              <AccordionDetails>
                <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
                  Nous nous efforçons de maintenir vos données exactes et à jour. 
                  Vous pouvez à tout moment corriger vos informations.
                </Typography>
              </AccordionDetails>
            </Accordion>

            <Accordion sx={{ mb: 2 }}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Limitation de la conservation
                </Typography>
              </AccordionSummary>
              <AccordionDetails>
                <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
                  Vos données sont conservées pendant une durée limitée, nécessaire aux finalités 
                  pour lesquelles elles sont traitées.
                </Typography>
              </AccordionDetails>
            </Accordion>

            <Accordion sx={{ mb: 2 }}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Typography variant="h6" sx={{ fontWeight: 600 }}>
                  Intégrité et confidentialité
                </Typography>
              </AccordionSummary>
              <AccordionDetails>
                <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
                  Nous mettons en œuvre des mesures techniques et organisationnelles appropriées 
                  pour assurer la sécurité de vos données.
                </Typography>
              </AccordionDetails>
            </Accordion>
          </Box>

          {/* Base légale */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              3. Base légale du traitement
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Le traitement de vos données personnelles est fondé sur les bases légales suivantes :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• L'exécution du contrat (fourniture de nos services)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• L'intérêt légitime (amélioration de nos services, sécurité)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Le consentement (pour les communications marketing)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• L'obligation légale (facturation, comptabilité)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Droits des utilisateurs */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              4. Vos droits RGPD
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Conformément au RGPD, vous disposez des droits suivants :
            </Typography>

            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2, mb: 3 }}>
              <Box sx={{ p: 2, bgcolor: '#f8f9fa', borderRadius: 2, border: '1px solid #dee2e6' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <PersonIcon sx={{ color: '#3498db', mr: 1 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600, color: '#2c3e50' }}>
                    Droit d'accès
                  </Typography>
                </Box>
                <Typography variant="body2" sx={{ lineHeight: 1.6 }}>
                  Vous pouvez demander une copie de toutes les données personnelles que nous détenons sur vous.
                </Typography>
              </Box>

              <Box sx={{ p: 2, bgcolor: '#f8f9fa', borderRadius: 2, border: '1px solid #dee2e6' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <PersonIcon sx={{ color: '#3498db', mr: 1 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600, color: '#2c3e50' }}>
                    Droit de rectification
                  </Typography>
                </Box>
                <Typography variant="body2" sx={{ lineHeight: 1.6 }}>
                  Vous pouvez corriger ou mettre à jour vos données personnelles inexactes.
                </Typography>
              </Box>

              <Box sx={{ p: 2, bgcolor: '#f8f9fa', borderRadius: 2, border: '1px solid #dee2e6' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <DeleteIcon sx={{ color: '#e74c3c', mr: 1 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600, color: '#2c3e50' }}>
                    Droit à l'effacement
                  </Typography>
                </Box>
                <Typography variant="body2" sx={{ lineHeight: 1.6 }}>
                  Vous pouvez demander la suppression de vos données personnelles ("droit à l'oubli").
                </Typography>
              </Box>

              <Box sx={{ p: 2, bgcolor: '#f8f9fa', borderRadius: 2, border: '1px solid #dee2e6' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <StorageIcon sx={{ color: '#27ae60', mr: 1 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600, color: '#2c3e50' }}>
                    Droit à la portabilité
                  </Typography>
                </Box>
                <Typography variant="body2" sx={{ lineHeight: 1.6 }}>
                  Vous pouvez recevoir vos données dans un format structuré et les transférer à un autre responsable.
                </Typography>
              </Box>

              <Box sx={{ p: 2, bgcolor: '#f8f9fa', borderRadius: 2, border: '1px solid #dee2e6' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <PersonIcon sx={{ color: '#f39c12', mr: 1 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600, color: '#2c3e50' }}>
                    Droit d'opposition
                  </Typography>
                </Box>
                <Typography variant="body2" sx={{ lineHeight: 1.6 }}>
                  Vous pouvez vous opposer au traitement de vos données pour certaines finalités.
                </Typography>
              </Box>

              <Box sx={{ p: 2, bgcolor: '#f8f9fa', borderRadius: 2, border: '1px solid #dee2e6' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <SecurityIcon sx={{ color: '#9b59b6', mr: 1 }} />
                  <Typography variant="h6" sx={{ fontWeight: 600, color: '#2c3e50' }}>
                    Droit à la limitation
                  </Typography>
                </Box>
                <Typography variant="body2" sx={{ lineHeight: 1.6 }}>
                  Vous pouvez demander la limitation du traitement de vos données dans certains cas.
                </Typography>
              </Box>
            </Box>

            <Alert severity="info" sx={{ mb: 2 }}>
              <Typography variant="body2">
                Pour exercer ces droits, contactez-nous à l'adresse email : 
                <Link href="mailto:contact.ateliergestion@gmail.com" sx={{ ml: 1 }}>
                  contact.ateliergestion@gmail.com
                </Link>
              </Typography>
            </Alert>
          </Box>

          {/* Mesures de sécurité */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              5. Mesures de sécurité
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Nous mettons en œuvre des mesures techniques et organisationnelles appropriées 
              pour protéger vos données personnelles :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Chiffrement SSL/TLS pour toutes les communications"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Authentification à deux facteurs pour les comptes administrateurs"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Sauvegardes chiffrées et régulières"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Accès restreint aux données personnelles"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Surveillance continue de la sécurité"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Formation du personnel à la protection des données"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Transferts de données */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              6. Transferts de données
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Vos données sont principalement traitées au sein de l'Union européenne. 
              En cas de transfert vers des pays tiers, nous nous assurons que :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Le pays bénéficie d'une décision d'adéquation de la Commission européenne"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Des garanties appropriées sont mises en place (clauses contractuelles types)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Des mécanismes de recours effectifs sont disponibles"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Durée de conservation */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              7. Durée de conservation des données
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Nous conservons vos données personnelles uniquement le temps nécessaire 
              à la réalisation des finalités pour lesquelles elles ont été collectées :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Données de compte : durée de l'abonnement + 30 jours"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Données de facturation : 10 ans (obligation légale)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Données de connexion : 12 mois"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Cookies : selon la durée définie dans notre politique cookies"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Délégué à la protection des données */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              8. Délégué à la protection des données (DPO)
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Atelier Gestion a désigné un délégué à la protection des données pour assurer 
              la conformité au RGPD et répondre à vos questions :
            </Typography>
            <Box sx={{ p: 3, bgcolor: '#f8f9fa', borderRadius: 2 }}>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Email :</strong> contact.ateliergestion@gmail.com
              </Typography>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Adresse :</strong> France
              </Typography>
              <Typography variant="body1">
                <strong>Fonction :</strong> Délégué à la protection des données
              </Typography>
            </Box>
          </Box>

          {/* Violations de données */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              9. Violations de données
            </Typography>
            <Alert severity="warning" sx={{ mb: 2 }}>
              <Typography variant="body2">
                En cas de violation de données personnelles susceptible d'engendrer un risque 
                pour vos droits et libertés, nous nous engageons à :
              </Typography>
            </Alert>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Notifier la CNIL dans les 72 heures"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Vous informer dans les meilleurs délais"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Documenter la violation et les mesures prises"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Contact et réclamations */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              10. Contact et réclamations
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Pour toute question concernant le traitement de vos données personnelles :
            </Typography>
            <Box sx={{ p: 3, bgcolor: '#f8f9fa', borderRadius: 2, mb: 2 }}>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Email général :</strong> contact.ateliergestion@gmail.com
              </Typography>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>DPO :</strong> contact.ateliergestion@gmail.com
              </Typography>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Téléphone :</strong> +33 1 23 45 67 89
              </Typography>
              <Typography variant="body1">
                <strong>Adresse :</strong> France
              </Typography>
            </Box>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Vous avez également le droit de déposer une réclamation auprès de la 
              <Link href="https://www.cnil.fr" target="_blank" sx={{ ml: 1 }}>
                Commission Nationale de l'Informatique et des Libertés (CNIL)
              </Link>.
            </Typography>
          </Box>

          <Divider sx={{ my: 4 }} />

          <Box sx={{ textAlign: 'center' }}>
            <Chip 
              label="Conformité RGPD" 
              color="success" 
              variant="outlined"
              icon={<SecurityIcon />}
            />
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default RGPD;
