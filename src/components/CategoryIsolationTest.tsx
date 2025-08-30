import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  TextField,
  Card,
  CardContent,
  List,
  ListItem,
  ListItemText,
  Alert,
  CircularProgress,
  Divider,
} from '@mui/material';
import { categoryService, ProductCategory } from '../services/categoryService';

const CategoryIsolationTest: React.FC = () => {
  const [categories, setCategories] = useState<ProductCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newCategoryName, setNewCategoryName] = useState('');
  const [creating, setCreating] = useState(false);

  // Charger les catégories
  const loadCategories = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const result = await categoryService.getAll();
      if (result.success && result.data) {
        setCategories(result.data);
        console.log('✅ Catégories chargées:', result.data.length);
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

  // Créer une nouvelle catégorie
  const createCategory = async () => {
    if (!newCategoryName.trim()) return;

    try {
      setCreating(true);
      setError(null);

      const result = await categoryService.create({
        name: newCategoryName,
        description: `Catégorie test: ${newCategoryName}`,
        icon: 'device_hub',
        color: '#1976d2',
      });

      if (result.success && result.data) {
        setNewCategoryName('');
        await loadCategories(); // Recharger les catégories
        console.log('✅ Catégorie créée:', result.data.name);
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

  // Supprimer une catégorie
  const deleteCategory = async (id: string) => {
    try {
      const result = await categoryService.delete(id);
      if (result.success) {
        await loadCategories(); // Recharger les catégories
        console.log('✅ Catégorie supprimée');
      } else {
        setError(result.error || 'Erreur lors de la suppression');
        console.error('❌ Erreur suppression:', result.error);
      }
    } catch (err) {
      setError('Erreur lors de la suppression');
      console.error('❌ Erreur suppression:', err);
    }
  };

  useEffect(() => {
    loadCategories();
  }, []);

  return (
    <Box sx={{ p: 3, maxWidth: 800, mx: 'auto' }}>
      <Typography variant="h4" gutterBottom>
        🔒 Test d'Isolation des Catégories
      </Typography>
      
      <Alert severity="info" sx={{ mb: 3 }}>
        Ce composant teste l'isolation des catégories. Chaque utilisateur ne doit voir que ses propres catégories.
      </Alert>

      {/* Création de catégorie */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Créer une nouvelle catégorie
          </Typography>
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <TextField
              label="Nom de la catégorie"
              value={newCategoryName}
              onChange={(e) => setNewCategoryName(e.target.value)}
              placeholder="Ex: Test Catégorie"
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

      {/* Liste des catégories */}
      <Card>
        <CardContent>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
            <Typography variant="h6">
              Catégories de l'utilisateur actuel
            </Typography>
            <Button onClick={loadCategories} disabled={loading}>
              {loading ? <CircularProgress size={20} /> : 'Actualiser'}
            </Button>
          </Box>

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
                      primary={category.name}
                      secondary={`${category.description} | ID: ${category.id} | User: ${category.user_id || 'N/A'}`}
                    />
                    <Button
                      variant="outlined"
                      color="error"
                      size="small"
                      onClick={() => deleteCategory(category.id)}
                    >
                      Supprimer
                    </Button>
                  </ListItem>
                  {index < categories.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          )}

          <Box sx={{ mt: 2 }}>
            <Typography variant="body2" color="text.secondary">
              Total: {categories.length} catégorie(s)
            </Typography>
          </Box>
        </CardContent>
      </Card>

      {/* Instructions de test */}
      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            🧪 Instructions de Test
          </Typography>
          <Typography variant="body2" paragraph>
            1. <strong>Créez une catégorie</strong> sur ce compte
          </Typography>
          <Typography variant="body2" paragraph>
            2. <strong>Connectez-vous avec un autre compte</strong> et vérifiez que la catégorie n'apparaît PAS
          </Typography>
          <Typography variant="body2" paragraph>
            3. <strong>Créez une catégorie</strong> sur l'autre compte
          </Typography>
          <Typography variant="body2" paragraph>
            4. <strong>Revenez sur ce compte</strong> et vérifiez que la catégorie de l'autre compte n'apparaît PAS
          </Typography>
          <Typography variant="body2" color="success.main">
            ✅ Si l'isolation fonctionne, chaque compte ne verra que ses propres catégories !
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default CategoryIsolationTest;
