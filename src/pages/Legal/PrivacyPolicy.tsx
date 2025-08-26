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
  Chip
} from '@mui/material';
import { NavigateNext as NavigateNextIcon } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

const PrivacyPolicy: React.FC = () => {
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
          <Typography color="text.primary">Politique de Confidentialité</Typography>
        </Breadcrumbs>

        <Paper sx={{ p: 4, borderRadius: 2 }}>
          <Typography variant="h3" component="h1" sx={{ mb: 3, fontWeight: 700, color: '#2c3e50' }}>
            Politique de Confidentialité
          </Typography>
          
          <Typography variant="body1" sx={{ mb: 4, color: '#6c757d' }}>
            Dernière mise à jour : {new Date().toLocaleDateString('fr-FR')}
          </Typography>

          <Divider sx={{ mb: 4 }} />

          {/* Introduction */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              1. Introduction
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Atelier Gestion ("nous", "notre", "nos") s'engage à protéger votre vie privée. 
              Cette politique de confidentialité explique comment nous collectons, utilisons, 
              stockons et protégeons vos informations personnelles lorsque vous utilisez notre 
              plateforme de gestion d'atelier de réparation.
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              En utilisant notre service, vous acceptez les pratiques décrites dans cette politique 
              de confidentialité.
            </Typography>
          </Box>

          {/* Informations collectées */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              2. Informations que nous collectons
            </Typography>
            
            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              2.1 Informations que vous nous fournissez
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Informations de compte (nom, email, mot de passe)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Informations professionnelles (nom de l'entreprise, adresse, numéro de téléphone)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Données clients (noms, contacts, historique des réparations)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Informations de paiement (gérées par nos prestataires de paiement sécurisés)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>

            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              2.2 Informations collectées automatiquement
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Données de connexion (adresse IP, type de navigateur, système d'exploitation)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Données d'utilisation (pages visitées, temps passé, actions effectuées)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Cookies et technologies similaires"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Utilisation des informations */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              3. Comment nous utilisons vos informations
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Nous utilisons vos informations pour :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Fournir et maintenir notre service de gestion d'atelier"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Traiter vos paiements et gérer votre abonnement"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Communiquer avec vous concernant votre compte et nos services"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Améliorer nos services et développer de nouvelles fonctionnalités"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Assurer la sécurité de notre plateforme"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Partage des informations */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              4. Partage de vos informations
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Nous ne vendons, n'échangeons ni ne louons vos informations personnelles à des tiers. 
              Nous pouvons partager vos informations uniquement dans les cas suivants :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Avec votre consentement explicite"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Avec nos prestataires de services (hébergement, paiement, support)"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Pour respecter les obligations légales ou répondre à des demandes gouvernementales"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Pour protéger nos droits, notre propriété ou notre sécurité"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Sécurité */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              5. Sécurité de vos données
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Nous mettons en œuvre des mesures de sécurité techniques et organisationnelles 
              appropriées pour protéger vos informations personnelles contre :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Accès non autorisé"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Modification, divulgation ou destruction non autorisées"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Perte accidentelle"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Ces mesures incluent le chiffrement SSL, l'authentification à deux facteurs, 
              les sauvegardes régulières et l'accès restreint aux données.
            </Typography>
          </Box>

          {/* Vos droits */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              6. Vos droits
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Conformément au RGPD, vous disposez des droits suivants :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Droit d'accès à vos données personnelles"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Droit de rectification de vos données"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Droit à l'effacement de vos données"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Droit à la portabilité de vos données"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Droit d'opposition au traitement"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Pour exercer ces droits, contactez-nous à l'adresse email suivante : 
                              <Link href="mailto:contact.ateliergestion@gmail.com" sx={{ ml: 1 }}>
                  contact.ateliergestion@gmail.com
              </Link>
            </Typography>
          </Box>

          {/* Cookies */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              7. Cookies et technologies similaires
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Nous utilisons des cookies et des technologies similaires pour améliorer votre 
              expérience utilisateur, analyser l'utilisation de notre service et personnaliser 
              le contenu.
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Vous pouvez contrôler l'utilisation des cookies via les paramètres de votre navigateur. 
              Cependant, la désactivation de certains cookies peut affecter le fonctionnement 
              de notre service.
            </Typography>
          </Box>

          {/* Modifications */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              8. Modifications de cette politique
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Nous pouvons mettre à jour cette politique de confidentialité de temps à autre. 
              Nous vous informerons de tout changement important par email ou via une notification 
              dans notre application. La date de dernière mise à jour sera modifiée en conséquence.
            </Typography>
          </Box>

          {/* Contact */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              9. Nous contacter
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Si vous avez des questions concernant cette politique de confidentialité ou 
              nos pratiques de protection des données, contactez-nous :
            </Typography>
            <Box sx={{ p: 3, bgcolor: '#f8f9fa', borderRadius: 2 }}>
              <Typography variant="body1" sx={{ mb: 1 }}>
                <strong>Email :</strong> contact.ateliergestion@gmail.com
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
              label="Politique de confidentialité mise à jour" 
              color="primary" 
              variant="outlined"
            />
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default PrivacyPolicy;
