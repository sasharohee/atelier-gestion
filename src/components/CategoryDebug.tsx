import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  TextField,
  Alert,
  CircularProgress,
  List,
  ListItem,
  ListItemText,
  Divider,
  Chip,
} from '@mui/material';
import { categoryService, ProductCategory } from '../services/categoryService';

const CategoryDebug: React.FC = () => {
  const [categories, setCategories] = useState<ProductCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newCategoryName, setNewCategoryName] = useState('');
  const [creating, setCreating] = useState(false);
  const [debugInfo, setDebugInfo] = useState<any>({});

  // Charger les catégories avec debug
  const loadCategories = async () => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔍 Début du chargement des catégories...');
      
      const result = await categoryService.getAll();
      console.log('🔍 Résultat du service:', result);
      
      if (result.success && result.data) {
        setCategories(result.data);
        console.log('✅ Catégories chargées:', result.data.length);
        console.log('📋 Détails des catégories:', result.data);
        
        // Debug info
        setDebugInfo({
          totalCategories: result.data.length,
          categories: result.data.map(cat => ({
            id: cat.id,
            name: cat.name,
            user_id: cat.user_id,
            is_active: cat.is_active,
            created_at: cat.created_at
          }))
        });
      } else {
        setError(result.error || 'Erreur lors du chargement');
        console.error('❌ Erreur:', result.error);
      }
    } catch (err) {
      setError('Erreur lors du chargement des catégories');
      console.error('❌ Erreur:', err);
    } finally {
      setLoading(false);
    }
  };

  // Créer une nouvelle catégorie avec debug
  const createCategory = async () => {
    if (!newCategoryName.trim()) return;

    try {
      setCreating(true);
      setError(null);

      console.log('🔍 Création de catégorie:', newCategoryName);

      const result = await categoryService.create({
        name: newCategoryName,
        description: `Catégorie debug: ${newCategoryName}`,
        icon: 'debug',
        color: '#ff0000',
      });

      console.log('🔍 Résultat création:', result);

      if (result.success && result.data) {
        console.log('✅ Catégorie créée:', result.data);
        setNewCategoryName('');
        
        // Recharger immédiatement
        await loadCategories();
      } else {
        setError(result.error || 'Erreur lors de la création');
        console.error('❌ Erreur création:', result.error);
      }
    } catch (err) {
      setError('Erreur lors de la création de la catégorie');
      console.error('❌ Erreur création:', err);
    } finally {
      setCreating(false);
    }
  };

  useEffect(() => {
    loadCategories();
  }, []);

  return (
    <Box sx={{ p: 3, maxWidth: 1000, mx: 'auto' }}>
      <Typography variant="h4" gutterBottom>
        🔍 Debug - Isolation des Catégories
      </Typography>
      
      <Alert severity="info" sx={{ mb: 3 }}>
        Ce composant affiche les détails complets des catégories pour diagnostiquer les problèmes d'affichage.
      </Alert>

      {/* Création de catégorie */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Créer une nouvelle catégorie (Debug)
          </Typography>
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <TextField
              label="Nom de la catégorie"
              value={newCategoryName}
              onChange={(e) => setNewCategoryName(e.target.value)}
              placeholder="Ex: Debug Catégorie"
              disabled={creating}
              sx={{ flexGrow: 1 }}
            />
            <Button
              variant="contained"
              onClick={createCategory}
              disabled={!newCategoryName.trim() || creating}
            >
              {creating ? <CircularProgress size={20} /> : 'Créer'}
            </Button>
          </Box>
        </CardContent>
      </Card>

      {/* Affichage des erreurs */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Informations de debug */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            📊 Informations de Debug
          </Typography>
          <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
            <Button onClick={loadCategories} disabled={loading}>
              {loading ? <CircularProgress size={20} /> : 'Actualiser'}
            </Button>
            <Chip 
              label={`Total: ${categories.length} catégorie(s)`} 
              color={categories.length > 0 ? 'success' : 'warning'} 
            />
          </Box>
          
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            <strong>État actuel:</strong> {loading ? 'Chargement...' : 'Chargé'}
          </Typography>
          
          {debugInfo.totalCategories !== undefined && (
            <Typography variant="body2" color="text.secondary">
              <strong>Dernière récupération:</strong> {debugInfo.totalCategories} catégorie(s)
            </Typography>
          )}
        </CardContent>
      </Card>

      {/* Liste des catégories avec détails */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            📋 Catégories de l'utilisateur actuel (Détails complets)
          </Typography>

          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
              <CircularProgress />
            </Box>
          ) : categories.length === 0 ? (
            <Alert severity="warning">
              Aucune catégorie trouvée. Créez votre première catégorie !
            </Alert>
          ) : (
            <List>
              {categories.map((category, index) => (
                <React.Fragment key={category.id}>
                  <ListItem>
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography variant="h6">{category.name}</Typography>
                          <Chip 
                            label={category.is_active ? 'Actif' : 'Inactif'} 
                            size="small" 
                            color={category.is_active ? 'success' : 'default'} 
                          />
                        </Box>
                      }
                      secondary={
                        <Box sx={{ mt: 1 }}>
                          <Typography variant="body2">
                            <strong>ID:</strong> {category.id}
                          </Typography>
                          <Typography variant="body2">
                            <strong>Description:</strong> {category.description}
                          </Typography>
                          <Typography variant="body2">
                            <strong>User ID:</strong> {category.user_id}
                          </Typography>
                          <Typography variant="body2">
                            <strong>Icon:</strong> {category.icon}
                          </Typography>
                          <Typography variant="body2">
                            <strong>Couleur:</strong> {category.color}
                          </Typography>
                          <Typography variant="body2">
                            <strong>Créé le:</strong> {new Date(category.created_at).toLocaleString()}
                          </Typography>
                          <Typography variant="body2">
                            <strong>Modifié le:</strong> {new Date(category.updated_at).toLocaleString()}
                          </Typography>
                        </Box>
                      }
                    />
                  </ListItem>
                  {index < categories.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          )}
        </CardContent>
      </Card>

      {/* Instructions de test */}
      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            🧪 Instructions de Test Debug
          </Typography>
          <Typography variant="body2" paragraph>
            1. <strong>Créez une catégorie</strong> et observez les logs dans la console
          </Typography>
          <Typography variant="body2" paragraph>
            2. <strong>Vérifiez</strong> que la catégorie apparaît dans la liste ci-dessus
          </Typography>
          <Typography variant="body2" paragraph>
            3. <strong>Connectez-vous avec un autre compte</strong> et vérifiez l'isolation
          </Typography>
          <Typography variant="body2" color="success.main">
            ✅ Si l'isolation fonctionne, chaque compte ne verra que ses propres catégories !
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default CategoryDebug;





















