import { Order, OrderItem } from '../types/order';
import { supabase } from '../lib/supabase';

class OrderService {
  // Récupérer toutes les commandes de l'utilisateur connecté
  async getAllOrders(): Promise<Order[]> {
    try {
      console.log('🔄 Chargement des commandes...');
      
      // Récupérer l'utilisateur connecté
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        console.log('⚠️ Aucun utilisateur connecté');
        return [];
      }
      
      console.log('👤 Utilisateur connecté:', user.id);
      
      // Récupérer les commandes de l'utilisateur connecté uniquement
      const { data, error } = await supabase
        .from('orders')
        .select('*')
        .eq('created_by', user.id) // Filtrer par l'utilisateur connecté
        .order('created_at', { ascending: false });

      if (error) {
        console.error('❌ Erreur Supabase:', error);
        return [];
      }

      console.log('✅ Commandes chargées pour l\'utilisateur:', data?.length || 0);
      
      // Transformer les données Supabase en objets Order
      const orders: Order[] = (data || []).map(order => ({
        id: order.id,
        orderNumber: order.order_number,
        supplierName: order.supplier_name,
        supplierEmail: order.supplier_email,
        supplierPhone: order.supplier_phone,
        orderDate: order.order_date,
        expectedDeliveryDate: order.expected_delivery_date,
        actualDeliveryDate: order.actual_delivery_date,
        status: order.status,
        totalAmount: order.total_amount,
        trackingNumber: order.tracking_number,
        notes: order.notes,
        items: [] // Pour l'instant, on ne charge pas les items
      }));
      
      return orders;
    } catch (error) {
      console.error('❌ Erreur lors du chargement des commandes:', error);
      return [];
    }
  }

  // Récupérer une commande par ID (de l'utilisateur connecté uniquement)
  async getOrderById(id: string): Promise<Order | null> {
    try {
      console.log('🔄 Chargement de la commande:', id);
      
      // Récupérer l'utilisateur connecté
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        console.log('⚠️ Aucun utilisateur connecté');
        return null;
      }
      
      // Récupérer la commande de l'utilisateur connecté uniquement
      const { data: order, error } = await supabase
        .from('orders')
        .select('*')
        .eq('id', id)
        .eq('created_by', user.id) // Filtrer par l'utilisateur connecté
        .single();

      if (error) {
        console.error('❌ Erreur récupération commande:', error);
        return null;
      }

      if (!order) {
        console.log('⚠️ Commande non trouvée ou non autorisée');
        return null;
      }

      return {
        id: order.id,
        orderNumber: order.order_number,
        supplierName: order.supplier_name,
        supplierEmail: order.supplier_email,
        supplierPhone: order.supplier_phone,
        orderDate: order.order_date,
        expectedDeliveryDate: order.expected_delivery_date,
        actualDeliveryDate: order.actual_delivery_date,
        status: order.status,
        totalAmount: order.total_amount,
        trackingNumber: order.tracking_number,
        notes: order.notes,
        items: []
      };
    } catch (error) {
      console.error('❌ Erreur lors du chargement de la commande:', error);
      return null;
    }
  }

  // Créer une nouvelle commande
  async createOrder(order: Omit<Order, 'id'>): Promise<Order> {
    try {
      console.log('🔄 Création de commande:', order.orderNumber);
      
      // Récupérer l'utilisateur connecté
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        throw new Error('Aucun utilisateur connecté');
      }
      
      const orderData = {
        order_number: order.orderNumber,
        supplier_name: order.supplierName,
        supplier_email: order.supplierEmail,
        supplier_phone: order.supplierPhone,
        order_date: order.orderDate || null,
        expected_delivery_date: order.expectedDeliveryDate || null,
        actual_delivery_date: order.actualDeliveryDate || null,
        status: order.status,
        total_amount: order.totalAmount || 0,
        tracking_number: order.trackingNumber || null,
        notes: order.notes || null,
        created_by: user.id // Ajouter l'utilisateur connecté
      };

      const { data: newOrder, error } = await supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single();

      if (error) {
        console.error('❌ Erreur création commande:', error);
        throw error;
      }

      console.log('✅ Commande créée:', newOrder?.id);
      
      return {
        id: newOrder.id,
        orderNumber: newOrder.order_number,
        supplierName: newOrder.supplier_name,
        supplierEmail: newOrder.supplier_email,
        supplierPhone: newOrder.supplier_phone,
        orderDate: newOrder.order_date,
        expectedDeliveryDate: newOrder.expected_delivery_date,
        actualDeliveryDate: newOrder.actual_delivery_date,
        status: newOrder.status,
        totalAmount: newOrder.total_amount,
        trackingNumber: newOrder.tracking_number,
        notes: newOrder.notes,
        items: order.items || []
      };
    } catch (error) {
      console.error('❌ Erreur lors de la création de la commande:', error);
      throw error;
    }
  }

  // Mettre à jour une commande
  async updateOrder(id: string, order: Order): Promise<Order | null> {
    try {
      console.log('🔄 Mise à jour de la commande:', id);
      
      // Récupérer l'utilisateur connecté
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        throw new Error('Aucun utilisateur connecté');
      }
      
      const orderData = {
        order_number: order.orderNumber,
        supplier_name: order.supplierName,
        supplier_email: order.supplierEmail,
        supplier_phone: order.supplierPhone,
        order_date: order.orderDate || null,
        expected_delivery_date: order.expectedDeliveryDate || null,
        actual_delivery_date: order.actualDeliveryDate || null,
        status: order.status,
        total_amount: order.totalAmount || 0,
        tracking_number: order.trackingNumber || null,
        notes: order.notes || null
      };

      // Mettre à jour la commande de l'utilisateur connecté uniquement
      const { data: updatedOrder, error } = await supabase
        .from('orders')
        .update(orderData)
        .eq('id', id)
        .eq('created_by', user.id) // Filtrer par l'utilisateur connecté
        .select()
        .single();

      if (error) {
        console.error('❌ Erreur mise à jour commande:', error);
        return null;
      }

      if (!updatedOrder) {
        console.log('⚠️ Commande non trouvée ou non autorisée');
        return null;
      }

      console.log('✅ Commande mise à jour:', updatedOrder.id);
      
      return {
        id: updatedOrder.id,
        orderNumber: updatedOrder.order_number,
        supplierName: updatedOrder.supplier_name,
        supplierEmail: updatedOrder.supplier_email,
        supplierPhone: updatedOrder.supplier_phone,
        orderDate: updatedOrder.order_date,
        expectedDeliveryDate: updatedOrder.expected_delivery_date,
        actualDeliveryDate: updatedOrder.actual_delivery_date,
        status: updatedOrder.status,
        totalAmount: updatedOrder.total_amount,
        trackingNumber: updatedOrder.tracking_number,
        notes: updatedOrder.notes,
        items: order.items || []
      };
    } catch (error) {
      console.error('❌ Erreur lors de la mise à jour de la commande:', error);
      return null;
    }
  }

  // Supprimer une commande
  async deleteOrder(id: string): Promise<boolean> {
    try {
      console.log('🔄 Suppression de la commande:', id);
      
      // Récupérer l'utilisateur connecté
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        throw new Error('Aucun utilisateur connecté');
      }
      
      // Supprimer la commande de l'utilisateur connecté uniquement
      const { error } = await supabase
        .from('orders')
        .delete()
        .eq('id', id)
        .eq('created_by', user.id); // Filtrer par l'utilisateur connecté

      if (error) {
        console.error('❌ Erreur suppression commande:', error);
        return false;
      }

      console.log('✅ Commande supprimée:', id);
      return true;
    } catch (error) {
      console.error('❌ Erreur lors de la suppression de la commande:', error);
      return false;
    }
  }

  // Récupérer les statistiques des commandes de l'utilisateur connecté
  async getOrderStats(): Promise<{
    total: number;
    pending: number;
    confirmed: number;
    shipped: number;
    delivered: number;
    cancelled: number;
    totalAmount: number;
  }> {
    try {
      console.log('🔄 Chargement statistiques...');
      
      // Récupérer l'utilisateur connecté
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        console.log('⚠️ Aucun utilisateur connecté');
        return {
          total: 0,
          pending: 0,
          confirmed: 0,
          shipped: 0,
          delivered: 0,
          cancelled: 0,
          totalAmount: 0
        };
      }
      
      // Récupérer toutes les commandes de l'utilisateur connecté
      const { data: orders, error } = await supabase
        .from('orders')
        .select('status, total_amount')
        .eq('created_by', user.id); // Filtrer par l'utilisateur connecté

      if (error) {
        console.error('❌ Erreur statistiques:', error);
        return {
          total: 0,
          pending: 0,
          confirmed: 0,
          shipped: 0,
          delivered: 0,
          cancelled: 0,
          totalAmount: 0
        };
      }

      // Calculer les statistiques
      const stats = {
        total: orders.length,
        pending: orders.filter(o => o.status === 'pending').length,
        confirmed: orders.filter(o => o.status === 'confirmed').length,
        shipped: orders.filter(o => o.status === 'shipped').length,
        delivered: orders.filter(o => o.status === 'delivered').length,
        cancelled: orders.filter(o => o.status === 'cancelled').length,
        totalAmount: orders.reduce((sum, o) => sum + (o.total_amount || 0), 0)
      };

      console.log('✅ Statistiques calculées:', stats);
      return stats;
    } catch (error) {
      console.error('❌ Erreur lors du calcul des statistiques:', error);
      return {
        total: 0,
        pending: 0,
        confirmed: 0,
        shipped: 0,
        delivered: 0,
        cancelled: 0,
        totalAmount: 0
      };
    }
  }

  // Vérifier la compatibilité des données (fonction existante)
  async checkDataCompatibility(): Promise<{
    hasOldData: boolean;
    recommendations: string[];
  }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { hasOldData: false, recommendations: [] };
      }
      
      // Vérifier s'il y a des commandes sans created_by
      const { data: ordersWithoutUser, error } = await supabase
        .from('orders')
        .select('id')
        .is('created_by', null)
        .limit(1);

      if (error) {
        console.error('❌ Erreur vérification compatibilité:', error);
        return { hasOldData: false, recommendations: [] };
      }

      const hasOldData = ordersWithoutUser && ordersWithoutUser.length > 0;
      
      return {
        hasOldData,
        recommendations: hasOldData 
          ? ['Des commandes existent sans utilisateur assigné. Nettoyage recommandé.'] 
          : []
      };
    } catch (error) {
      console.error('❌ Erreur lors de la vérification de compatibilité:', error);
      return { hasOldData: false, recommendations: [] };
    }
  }

  // Nettoyer les anciennes données (fonction existante)
  async cleanupOldData(): Promise<void> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        console.log('⚠️ Aucun utilisateur connecté pour le nettoyage');
        return;
      }
      
      // Assigner les commandes sans created_by à l'utilisateur connecté
      const { error } = await supabase
        .from('orders')
        .update({ created_by: user.id })
        .is('created_by', null);

      if (error) {
        console.error('❌ Erreur nettoyage données:', error);
      } else {
        console.log('✅ Nettoyage des données terminé');
      }
    } catch (error) {
      console.error('❌ Erreur lors du nettoyage des données:', error);
    }
  }
}

export default new OrderService();
