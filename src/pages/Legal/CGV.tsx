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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow
} from '@mui/material';
import { NavigateNext as NavigateNextIcon } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

const CGV: React.FC = () => {
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
          <Typography color="text.primary">Conditions Générales de Vente</Typography>
        </Breadcrumbs>

        <Paper sx={{ p: 4, borderRadius: 2 }}>
          <Typography variant="h3" component="h1" sx={{ mb: 3, fontWeight: 700, color: '#2c3e50' }}>
            Conditions Générales de Vente
          </Typography>
          
          <Typography variant="body1" sx={{ mb: 4, color: '#6c757d' }}>
            Dernière mise à jour : {new Date().toLocaleDateString('fr-FR')}
          </Typography>

          <Alert severity="info" sx={{ mb: 4 }}>
            <Typography variant="body2">
              Ces conditions générales de vente s'appliquent à tous les services proposés par Atelier Gestion 
              et constituent le contrat entre Atelier Gestion et ses clients.
            </Typography>
          </Alert>

          <Divider sx={{ mb: 4 }} />

          {/* Informations sur l'éditeur */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              1. Informations sur l'éditeur
            </Typography>
            <Box sx={{ p: 3, bgcolor: '#f8f9fa', borderRadius: 2 }}>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Raison sociale :</strong> Atelier Gestion
              </Typography>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Adresse :</strong> France
              </Typography>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Email :</strong> contact@atelier-gestion.fr
              </Typography>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Téléphone :</strong> +33 1 23 45 67 89
              </Typography>
              <Typography variant="body1">
                <strong>Site web :</strong> https://atelier-gestion.fr
              </Typography>
            </Box>
          </Box>

          {/* Description des services */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              2. Description des services
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Atelier Gestion propose une plateforme SaaS de gestion d'atelier de réparation d'appareils 
              électroniques comprenant les fonctionnalités suivantes :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Gestion des réparations et suivi des appareils"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Calendrier et gestion des rendez-vous clients"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Base de données clients et historique des réparations"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Gestion de l'inventaire et des pièces détachées"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Rapports et statistiques de performance"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Tarification */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              3. Tarification
            </Typography>
            
            <TableContainer component={Paper} sx={{ mb: 3 }}>
              <Table>
                <TableHead>
                  <TableRow sx={{ bgcolor: '#f8f9fa' }}>
                    <TableCell sx={{ fontWeight: 600 }}>Service</TableCell>
                    <TableCell sx={{ fontWeight: 600 }}>Prix</TableCell>
                    <TableCell sx={{ fontWeight: 600 }}>Périodicité</TableCell>
                    <TableCell sx={{ fontWeight: 600 }}>Fonctionnalités</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  <TableRow>
                    <TableCell>Atelier Pro</TableCell>
                    <TableCell>19,99€</TableCell>
                    <TableCell>Mensuel</TableCell>
                    <TableCell>Toutes les fonctionnalités incluses</TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </TableContainer>

            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              <strong>Modalités de paiement :</strong>
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Paiement par carte bancaire via Stripe"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Prélèvement automatique mensuel"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Facturation en euros (EUR)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Commande et conclusion du contrat */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              4. Commande et conclusion du contrat
            </Typography>
            
            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              4.1 Processus de commande
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              La commande s'effectue en ligne sur notre site web. Le client doit :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Créer un compte utilisateur"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Remplir le formulaire d'inscription"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Fournir les informations de paiement"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Valider sa commande"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>

            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              4.2 Confirmation de commande
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Une confirmation de commande sera envoyée par email au client. Le contrat est conclu 
              dès réception de cette confirmation.
            </Typography>
          </Box>

          {/* Droit de rétractation */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              5. Droit de rétractation
            </Typography>
            <Alert severity="warning" sx={{ mb: 2 }}>
              <Typography variant="body2">
                Conformément à l'article L.221-18 du Code de la consommation, le client dispose 
                d'un délai de 14 jours à compter de la conclusion du contrat pour exercer son 
                droit de rétractation.
              </Typography>
            </Alert>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Pour exercer ce droit, le client doit nous notifier sa décision de rétractation 
              par email à l'adresse : retractation@atelier-gestion.fr
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              En cas de rétractation, le remboursement sera effectué dans un délai de 14 jours 
              à compter de la réception de la notification de rétractation.
            </Typography>
          </Box>

          {/* Exécution du service */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              6. Exécution du service
            </Typography>
            
            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              6.1 Mise à disposition
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Le service est mis à disposition immédiatement après validation du paiement. 
              L'accès est effectif 24h/24 et 7j/7, sous réserve des maintenances programmées.
            </Typography>

            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              6.2 Disponibilité
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Nous nous efforçons de maintenir une disponibilité de 99,5% du service. 
              Les maintenances programmées sont annoncées 48h à l'avance.
            </Typography>

            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              6.3 Support technique
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Un support technique est disponible par email à support@atelier-gestion.fr 
              avec un délai de réponse de 24h ouvrées.
            </Typography>
          </Box>

          {/* Garanties */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              7. Garanties
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Atelier Gestion s'engage à fournir un service conforme aux spécifications techniques 
              décrites sur le site web. Nous garantissons :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• La conformité du service aux spécifications"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• La sécurité des données utilisateur"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• La confidentialité des informations"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Responsabilité */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              8. Responsabilité
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              La responsabilité d'Atelier Gestion est limitée aux dommages directs prouvés 
              et ne pourra excéder le montant des sommes versées par le client au cours 
              des 12 mois précédant le dommage.
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Atelier Gestion ne saurait être tenu responsable des dommages indirects, 
              accessoires ou immatériels.
            </Typography>
          </Box>

          {/* Durée et résiliation */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              9. Durée et résiliation
            </Typography>
            
            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              9.1 Durée du contrat
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Le contrat est conclu pour une durée indéterminée à compter de la date de souscription. 
              Il se renouvelle automatiquement par périodes mensuelles.
            </Typography>

            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              9.2 Résiliation
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Chaque partie peut résilier le contrat à tout moment avec un préavis de 30 jours. 
              La résiliation s'effectue via l'interface utilisateur ou par email.
            </Typography>

            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              9.3 Effets de la résiliation
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              À la résiliation, l'accès au service sera suspendu à la fin de la période de facturation. 
              Les données du client seront conservées pendant 30 jours puis supprimées définitivement.
            </Typography>
          </Box>

          {/* Protection des données */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              10. Protection des données personnelles
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Le traitement des données personnelles est régi par notre Politique de Confidentialité 
              et conforme au Règlement Général sur la Protection des Données (RGPD).
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Le client dispose des droits d'accès, de rectification, d'effacement et d'opposition 
              sur ses données personnelles.
            </Typography>
          </Box>

          {/* Droit applicable et juridiction */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              11. Droit applicable et juridiction
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Les présentes CGV sont régies par le droit français. En cas de litige, les tribunaux 
              français seront seuls compétents, sauf pour les consommateurs qui pourront s'adresser 
              aux tribunaux de leur domicile.
            </Typography>
          </Box>

          {/* Contact */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              12. Contact
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Pour toute question concernant ces conditions générales de vente :
            </Typography>
            <Box sx={{ p: 3, bgcolor: '#f8f9fa', borderRadius: 2 }}>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Email :</strong> cgv@atelier-gestion.fr
              </Typography>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Téléphone :</strong> +33 1 23 45 67 89
              </Typography>
              <Typography variant="body1">
                <strong>Adresse :</strong> France
              </Typography>
            </Box>
          </Box>

          <Divider sx={{ my: 4 }} />

          <Box sx={{ textAlign: 'center' }}>
            <Chip 
              label="CGV mises à jour" 
              color="primary" 
              variant="outlined"
            />
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default CGV;
