import React from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Chip,
  Divider,
  Alert,
  Collapse,
  IconButton,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
} from '@mui/material';
import {
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  BatteryAlert as BatteryAlertIcon,
  ScreenLockPortrait as ScreenIcon,
  Build as BuildIcon,
  ShoppingBag as AccessoriesIcon,
  Security as WarrantyIcon,
  Lock as LockIcon,
} from '@mui/icons-material';
import { BuybackPricing } from '../types';
import { formatFromEUR } from '../utils/currencyUtils';

interface BuybackPriceBreakdownProps {
  pricing: BuybackPricing;
  currency?: string;
  showDetails?: boolean;
  compact?: boolean;
}

const BuybackPriceBreakdown: React.FC<BuybackPriceBreakdownProps> = ({
  pricing,
  currency = 'EUR',
  showDetails = true,
  compact = false
}) => {
  const [expanded, setExpanded] = React.useState(showDetails);

  const handleToggleExpanded = () => {
    setExpanded(!expanded);
  };

  const getConditionLabel = (condition: string) => {
    const labels: { [key: string]: string } = {
      'excellent': 'Excellent',
      'good': 'Bon',
      'fair': 'Correct',
      'poor': 'Mauvais',
      'broken': 'Cassé'
    };
    return labels[condition] || condition;
  };

  const getScreenConditionLabel = (condition: string) => {
    const labels: { [key: string]: string } = {
      'perfect': 'Parfait',
      'minor_scratches': 'Petites rayures',
      'major_scratches': 'Grosses rayures',
      'cracked': 'Fêlé',
      'broken': 'Cassé'
    };
    return labels[condition] || condition;
  };

  const formatPrice = (price: number) => formatFromEUR(price, currency);
  const formatPercentage = (value: number) => `${Math.round(value * 100)}%`;

  const breakdown = pricing.breakdown;
  const hasAdjustments = breakdown.batteryPenalty > 0 || 
                        breakdown.buttonPenalty > 0 || 
                        breakdown.functionalPenalty > 0 || 
                        breakdown.accessoriesBonus > 0 || 
                        breakdown.warrantyBonus > 0 || 
                        breakdown.lockPenalty > 0;

  if (compact) {
    return (
      <Box sx={{ p: 2, bgcolor: 'background.paper', borderRadius: 2 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
          <Typography variant="h6" color="primary">
            Estimation de prix
          </Typography>
          <Typography variant="h5" fontWeight="bold" color="success.main">
            {formatPrice(pricing.estimatedPrice)}
          </Typography>
        </Box>
        
        <Typography variant="body2" color="text.secondary">
          Prix de base: {formatPrice(pricing.basePrice)}
          {hasAdjustments && (
            <span> • Ajustements: {formatPrice(pricing.estimatedPrice - pricing.basePrice)}</span>
          )}
        </Typography>
        
        {hasAdjustments && (
          <IconButton 
            size="small" 
            onClick={handleToggleExpanded}
            sx={{ mt: 1 }}
          >
            {expanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
            <Typography variant="caption" sx={{ ml: 1 }}>
              {expanded ? 'Masquer' : 'Voir'} le détail
            </Typography>
          </IconButton>
        )}
        
        <Collapse in={expanded}>
          <Box sx={{ mt: 2 }}>
            {renderDetailedBreakdown()}
          </Box>
        </Collapse>
      </Box>
    );
  }

  function renderDetailedBreakdown() {
    return (
      <Grid container spacing={2}>
        {/* Prix de base */}
        <Grid item xs={12}>
          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom>
                💰 Prix de base du modèle
              </Typography>
              <Typography variant="h4" color="primary">
                {formatPrice(breakdown.basePrice)}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        {/* Ajustements */}
        {hasAdjustments && (
          <Grid item xs={12}>
            <Typography variant="h6" gutterBottom sx={{ mt: 2 }}>
              🔧 Ajustements appliqués
            </Typography>
            
            <Grid container spacing={2}>
              {/* État physique */}
              <Grid item xs={12} sm={6}>
                <Card variant="outlined" sx={{ height: '100%' }}>
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                      <TrendingUpIcon color="primary" sx={{ mr: 1 }} />
                      <Typography variant="subtitle1" fontWeight="bold">
                        État physique
                      </Typography>
                    </Box>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      Multiplicateur: {formatPercentage(breakdown.conditionMultiplier)}
                    </Typography>
                    <Typography variant="h6" color={breakdown.conditionMultiplier < 1 ? 'error.main' : 'success.main'}>
                      {formatPrice(breakdown.basePrice * breakdown.conditionMultiplier - breakdown.basePrice)}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>

              {/* État écran */}
              {breakdown.screenMultiplier !== 1 && (
                <Grid item xs={12} sm={6}>
                  <Card variant="outlined" sx={{ height: '100%' }}>
                    <CardContent>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                        <ScreenIcon color="primary" sx={{ mr: 1 }} />
                        <Typography variant="subtitle1" fontWeight="bold">
                          État écran
                        </Typography>
                      </Box>
                      <Typography variant="body2" color="text.secondary" gutterBottom>
                        Multiplicateur: {formatPercentage(breakdown.screenMultiplier)}
                      </Typography>
                      <Typography variant="h6" color={breakdown.screenMultiplier < 1 ? 'error.main' : 'success.main'}>
                        {formatPrice(breakdown.basePrice * breakdown.screenMultiplier - breakdown.basePrice)}
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
              )}

              {/* Déductions */}
              {(breakdown.batteryPenalty > 0 || breakdown.buttonPenalty > 0 || breakdown.functionalPenalty > 0) && (
                <Grid item xs={12}>
                  <Typography variant="subtitle1" fontWeight="bold" gutterBottom>
                    📉 Déductions
                  </Typography>
                  <List dense>
                    {breakdown.batteryPenalty > 0 && (
                      <ListItem>
                        <ListItemIcon>
                          <BatteryAlertIcon color="error" />
                        </ListItemIcon>
                        <ListItemText 
                          primary="Santé batterie" 
                          secondary={`-${formatPrice(breakdown.batteryPenalty)}`}
                        />
                      </ListItem>
                    )}
                    {breakdown.buttonPenalty > 0 && (
                      <ListItem>
                        <ListItemIcon>
                          <BuildIcon color="error" />
                        </ListItemIcon>
                        <ListItemText 
                          primary="État boutons" 
                          secondary={`-${formatPrice(breakdown.buttonPenalty)}`}
                        />
                      </ListItem>
                    )}
                    {breakdown.functionalPenalty > 0 && (
                      <ListItem>
                        <ListItemIcon>
                          <BuildIcon color="error" />
                        </ListItemIcon>
                        <ListItemText 
                          primary="Fonctionnalités défectueuses" 
                          secondary={`-${formatPrice(breakdown.functionalPenalty)}`}
                        />
                      </ListItem>
                    )}
                  </List>
                </Grid>
              )}

              {/* Bonus */}
              {(breakdown.accessoriesBonus > 0 || breakdown.warrantyBonus > 0) && (
                <Grid item xs={12}>
                  <Typography variant="subtitle1" fontWeight="bold" gutterBottom>
                    📈 Bonus
                  </Typography>
                  <List dense>
                    {breakdown.accessoriesBonus > 0 && (
                      <ListItem>
                        <ListItemIcon>
                          <AccessoriesIcon color="success" />
                        </ListItemIcon>
                        <ListItemText 
                          primary="Accessoires inclus" 
                          secondary={`+${formatPrice(breakdown.accessoriesBonus)}`}
                        />
                      </ListItem>
                    )}
                    {breakdown.warrantyBonus > 0 && (
                      <ListItem>
                        <ListItemIcon>
                          <WarrantyIcon color="success" />
                        </ListItemIcon>
                        <ListItemText 
                          primary="Garantie restante" 
                          secondary={`+${formatPrice(breakdown.warrantyBonus)}`}
                        />
                      </ListItem>
                    )}
                  </List>
                </Grid>
              )}

              {/* Pénalités blocages */}
              {breakdown.lockPenalty > 0 && (
                <Grid item xs={12}>
                  <Alert severity="warning" sx={{ mb: 2 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                      <LockIcon sx={{ mr: 1 }} />
                      <Typography variant="subtitle1" fontWeight="bold">
                        Blocages détectés
                      </Typography>
                    </Box>
                    <Typography variant="body2">
                      Pénalité appliquée: -{formatPrice(breakdown.lockPenalty)}
                    </Typography>
                  </Alert>
                </Grid>
              )}
            </Grid>
          </Grid>
        )}

        {/* Prix final */}
        <Grid item xs={12}>
          <Divider sx={{ my: 2 }} />
          <Card 
            variant="outlined" 
            sx={{ 
              bgcolor: 'success.light', 
              border: '2px solid',
              borderColor: 'success.main'
            }}
          >
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h5" fontWeight="bold">
                  💎 Prix estimé final
                </Typography>
                <Typography variant="h3" fontWeight="bold" color="success.dark">
                  {formatPrice(pricing.estimatedPrice)}
                </Typography>
              </Box>
              
              {hasAdjustments && (
                <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                  Différence avec le prix de base: {formatPrice(pricing.estimatedPrice - pricing.basePrice)}
                </Typography>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    );
  }

  return (
    <Box>
      {renderDetailedBreakdown()}
    </Box>
  );
};

export default BuybackPriceBreakdown;
