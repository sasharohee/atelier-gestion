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
  Alert
} from '@mui/material';
import { NavigateNext as NavigateNextIcon, Warning as WarningIcon } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

const TermsOfService: React.FC = () => {
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
          <Typography color="text.primary">Conditions d'Utilisation</Typography>
        </Breadcrumbs>

        <Paper sx={{ p: 4, borderRadius: 2 }}>
          <Typography variant="h3" component="h1" sx={{ mb: 3, fontWeight: 700, color: '#2c3e50' }}>
            Conditions d'Utilisation
          </Typography>
          
          <Typography variant="body1" sx={{ mb: 4, color: '#6c757d' }}>
            Dernière mise à jour : {new Date().toLocaleDateString('fr-FR')}
          </Typography>

          <Alert severity="info" sx={{ mb: 4 }}>
            <Typography variant="body2">
              En utilisant Atelier Gestion, vous acceptez d'être lié par ces conditions d'utilisation. 
              Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser notre service.
            </Typography>
          </Alert>

          <Divider sx={{ mb: 4 }} />

          {/* Introduction */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              1. Acceptation des conditions
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Les présentes conditions d'utilisation ("Conditions") régissent votre utilisation de la 
              plateforme Atelier Gestion ("Service"), un service de gestion d'atelier de réparation 
              d'appareils électroniques fourni par Atelier Gestion ("nous", "notre", "nos").
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              En créant un compte ou en utilisant notre Service, vous confirmez que vous avez lu, 
              compris et accepté d'être lié par ces Conditions.
            </Typography>
          </Box>

          {/* Description du service */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              2. Description du service
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Atelier Gestion est une plateforme SaaS qui offre les fonctionnalités suivantes :
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

          {/* Compte utilisateur */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              3. Compte utilisateur
            </Typography>
            
            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              3.1 Création de compte
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Pour utiliser notre Service, vous devez créer un compte en fournissant des informations 
              exactes, complètes et à jour. Vous êtes responsable de maintenir la confidentialité 
              de vos identifiants de connexion.
            </Typography>

            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              3.2 Responsabilité du compte
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Vous êtes entièrement responsable de toutes les activités qui se produisent sous votre 
              compte. Vous devez nous notifier immédiatement de toute utilisation non autorisée 
              de votre compte.
            </Typography>

            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              3.3 Âge minimum
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Vous devez avoir au moins 18 ans pour créer un compte et utiliser notre Service. 
              Si vous avez moins de 18 ans, vous devez avoir l'autorisation d'un parent ou tuteur légal.
            </Typography>
          </Box>

          {/* Utilisation acceptable */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              4. Utilisation acceptable
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Vous vous engagez à utiliser notre Service uniquement à des fins légales et conformément 
              à ces Conditions. Vous ne devez pas :
            </Typography>
            <List sx={{ mb: 2 }}>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Utiliser le Service pour des activités illégales ou frauduleuses"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Tenter d'accéder non autorisé à nos systèmes ou à d'autres comptes"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Transmettre des virus, logiciels malveillants ou tout autre code nuisible"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Interférer avec le fonctionnement du Service ou des serveurs"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
              <ListItem sx={{ py: 0.5 }}>
                <ListItemText 
                  primary="• Violer les droits de propriété intellectuelle d'autrui"
                  sx={{ '& .MuiListItemText-primary': { fontSize: '0.95rem' } }}
                />
              </ListItem>
            </List>
          </Box>

          {/* Paiements et abonnements */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              5. Paiements et abonnements
            </Typography>
            
            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              5.1 Tarification
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Notre Service est proposé selon un modèle d'abonnement mensuel au prix de 19,99€/mois. 
              Les prix peuvent être modifiés avec un préavis de 30 jours.
            </Typography>

            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              5.2 Paiement
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Les paiements sont prélevés automatiquement chaque mois. Vous devez fournir des 
              informations de paiement valides et autoriser les prélèvements automatiques.
            </Typography>

            <Typography variant="h6" sx={{ mb: 1, fontWeight: 600, color: '#495057' }}>
              5.3 Résiliation
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Vous pouvez résilier votre abonnement à tout moment. La résiliation prendra effet 
              à la fin de la période de facturation en cours. Aucun remboursement ne sera effectué 
              pour les périodes partiellement utilisées.
            </Typography>
          </Box>

          {/* Propriété intellectuelle */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              6. Propriété intellectuelle
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Le Service et son contenu, y compris mais sans s'y limiter, le code source, les 
              designs, les textes, les graphiques, les interfaces, les marques et les logos, 
              sont la propriété d'Atelier Gestion et sont protégés par les lois sur la propriété 
              intellectuelle.
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Nous vous accordons une licence limitée, non exclusive, non transférable et révocable 
              pour utiliser le Service conformément à ces Conditions.
            </Typography>
          </Box>

          {/* Confidentialité et données */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              7. Confidentialité et protection des données
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              La collecte, l'utilisation et la protection de vos données personnelles sont régies 
              par notre Politique de Confidentialité, qui fait partie intégrante de ces Conditions.
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Vous êtes responsable de la conformité de vos pratiques de traitement des données 
              avec les lois applicables, notamment le RGPD.
            </Typography>
          </Box>

          {/* Disponibilité du service */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              8. Disponibilité du service
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Nous nous efforçons de maintenir le Service disponible 24h/24 et 7j/7, mais nous 
              ne garantissons pas une disponibilité ininterrompue. Le Service peut être temporairement 
              indisponible pour maintenance, mises à jour ou pour des raisons techniques.
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Nous nous engageons à informer nos utilisateurs des interruptions planifiées 
              dans la mesure du possible.
            </Typography>
          </Box>

          {/* Limitation de responsabilité */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              9. Limitation de responsabilité
            </Typography>
            <Alert severity="warning" sx={{ mb: 2 }}>
              <Typography variant="body2">
                Dans toute la mesure permise par la loi applicable, Atelier Gestion ne sera pas 
                responsable des dommages indirects, accessoires, spéciaux, consécutifs ou punitifs 
                résultant de l'utilisation du Service.
              </Typography>
            </Alert>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Notre responsabilité totale envers vous pour tout dommage ne dépassera pas le montant 
              payé par vous pour le Service au cours des 12 mois précédant l'événement donnant 
              lieu à la responsabilité.
            </Typography>
          </Box>

          {/* Résiliation */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              10. Résiliation
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Nous pouvons résilier ou suspendre votre accès au Service immédiatement, sans préavis, 
              pour toute raison, y compris en cas de violation de ces Conditions.
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              À la résiliation, votre droit d'utiliser le Service cessera immédiatement. 
              Les dispositions de ces Conditions qui, par leur nature, doivent survivre à la 
              résiliation resteront en vigueur.
            </Typography>
          </Box>

          {/* Droit applicable */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              11. Droit applicable et juridiction
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Ces Conditions sont régies par le droit français. Tout litige découlant de ces 
              Conditions sera soumis à la compétence exclusive des tribunaux français.
            </Typography>
          </Box>

          {/* Modifications */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              12. Modifications des conditions
            </Typography>
            <Typography variant="body1" sx={{ lineHeight: 1.7 }}>
              Nous nous réservons le droit de modifier ces Conditions à tout moment. Les modifications 
              prendront effet immédiatement après leur publication. Votre utilisation continue du 
              Service après la publication des modifications constitue votre acceptation des nouvelles Conditions.
            </Typography>
          </Box>

          {/* Contact */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="h5" sx={{ mb: 2, fontWeight: 600, color: '#2c3e50' }}>
              13. Nous contacter
            </Typography>
            <Typography variant="body1" sx={{ mb: 2, lineHeight: 1.7 }}>
              Si vous avez des questions concernant ces Conditions d'utilisation, contactez-nous :
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
              label="Conditions d'utilisation mises à jour" 
              color="primary" 
              variant="outlined"
            />
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default TermsOfService;
