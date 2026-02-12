import { supabase, handleSupabaseError, handleSupabaseSuccess } from '../lib/supabase';
import { useAppStore } from '../store';

export interface AccountingKPIs {
  totalRevenue: number;
  totalExpenses: number;
  netProfit: number;
  revenueLast30Days: number;
  expensesLast30Days: number;
  profitLast30Days: number;
  revenueByMonth: { month: string; amount: number }[];
  expensesByMonth: { month: string; amount: number }[];
  topSellingServices: { name: string; amount: number }[];
  topSellingProducts: { name: string; amount: number }[];
  topExpensesCategories: { category: string; amount: number }[];
}

export interface Transaction {
  id: string;
  type: 'sale' | 'repair' | 'expense';
  date: Date;
  description: string;
  amount: number;
  clientName?: string;
  status?: string;
}

export const accountingDataServiceSimple = {
  /**
   * Récupérer les KPIs comptables (version simplifiée)
   */
  async getAccountingKPIs(userId: string): Promise<{ success: boolean; data?: AccountingKPIs; error?: Error }> {
    try {
      // Récupérer les ventes
      const { data: sales, error: salesError } = await supabase
        .from('sales')
        .select('total, created_at')
        .eq('user_id', userId)
        .eq('status', 'completed');

      if (salesError) {
        console.warn('Erreur lors de la récupération des ventes:', salesError);
      }

      // Récupérer les réparations payées
      const { data: repairs, error: repairsError } = await supabase
        .from('repairs')
        .select('total_price, created_at')
        .eq('user_id', userId)
        .eq('is_paid', true);

      if (repairsError) {
        console.warn('Erreur lors de la récupération des réparations:', repairsError);
      }

      // Récupérer les dépenses
      const { data: expenses, error: expensesError } = await supabase
        .from('expenses')
        .select('amount, expense_date, tags')
        .eq('user_id', userId)
        .eq('status', 'paid');

      if (expensesError) {
        console.warn('Erreur lors de la récupération des dépenses:', expensesError);
      }

      // Calculer les totaux
      const totalRevenue = (sales || []).reduce((sum, s) => sum + (s.total || 0), 0) +
                          (repairs || []).reduce((sum, r) => sum + (r.total_price || 0), 0);
      
      const totalExpenses = (expenses || []).reduce((sum, e) => sum + (e.amount || 0), 0);
      const netProfit = totalRevenue - totalExpenses;

      // Calculer les 30 derniers jours
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const revenueLast30Days = [
        ...(sales || []).filter(s => new Date(s.created_at) >= thirtyDaysAgo),
        ...(repairs || []).filter(r => new Date(r.created_at) >= thirtyDaysAgo)
      ].reduce((sum, item) => sum + (item.total || item.total_price || 0), 0);

      const expensesLast30Days = (expenses || [])
        .filter(e => new Date(e.expense_date) >= thirtyDaysAgo)
        .reduce((sum, e) => sum + (e.amount || 0), 0);

      const profitLast30Days = revenueLast30Days - expensesLast30Days;

      // Agrégation par mois
      const revenueByMonthMap = new Map<string, number>();
      const expensesByMonthMap = new Map<string, number>();

      [...(sales || []), ...(repairs || [])].forEach(item => {
        const date = new Date(item.created_at);
        const month = date.toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
        const amount = item.total || item.total_price || 0;
        revenueByMonthMap.set(month, (revenueByMonthMap.get(month) || 0) + amount);
      });

      (expenses || []).forEach(expense => {
        const date = new Date(expense.expense_date);
        const month = date.toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
        expensesByMonthMap.set(month, (expensesByMonthMap.get(month) || 0) + (expense.amount || 0));
      });

      const revenueByMonth = Array.from(revenueByMonthMap.entries()).map(([month, amount]) => ({ month, amount }));
      const expensesByMonth = Array.from(expensesByMonthMap.entries()).map(([month, amount]) => ({ month, amount }));

      // Top catégories de dépenses
      const expensesCategoriesMap = new Map<string, number>();
      (expenses || []).forEach(expense => {
        const category = expense.tags?.[0] || 'Général';
        expensesCategoriesMap.set(category, (expensesCategoriesMap.get(category) || 0) + (expense.amount || 0));
      });

      const topExpensesCategories = Array.from(expensesCategoriesMap.entries())
        .map(([category, amount]) => ({ category, amount }))
        .sort((a, b) => b.amount - a.amount)
        .slice(0, 5);

      const kpis: AccountingKPIs = {
        totalRevenue,
        totalExpenses,
        netProfit,
        revenueLast30Days,
        expensesLast30Days,
        profitLast30Days,
        revenueByMonth,
        expensesByMonth,
        topSellingServices: [], // TODO: Implémenter si nécessaire
        topSellingProducts: [], // TODO: Implémenter si nécessaire
        topExpensesCategories,
      };

      return handleSupabaseSuccess(kpis);
    } catch (err: any) {
      console.error('Erreur lors de la récupération des KPIs:', err);
      return handleSupabaseError(new Error(`Erreur lors de la récupération des KPIs: ${err.message}`));
    }
  },

  /**
   * Récupérer les transactions (version simplifiée)
   */
  async getTransactions(userId: string, filters?: any): Promise<{ success: boolean; data?: Transaction[]; error?: Error }> {
    try {
      const transactions: Transaction[] = [];

      // Récupérer les ventes
      const { data: sales, error: salesError } = await supabase
        .from('sales')
        .select('id, total, created_at, status, client_id')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (salesError) {
        console.warn('Erreur lors de la récupération des ventes:', salesError);
      }

      // Récupérer les réparations
      const { data: repairs, error: repairsError } = await supabase
        .from('repairs')
        .select('id, total_price, created_at, status, client_id')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (repairsError) {
        console.warn('Erreur lors de la récupération des réparations:', repairsError);
      }

      // Récupérer les dépenses
      const { data: expenses, error: expensesError } = await supabase
        .from('expenses')
        .select('id, amount, expense_date, title, status')
        .eq('user_id', userId)
        .order('expense_date', { ascending: false });

      if (expensesError) {
        console.warn('Erreur lors de la récupération des dépenses:', expensesError);
      }

      // Convertir en transactions
      (sales || []).forEach(sale => {
        transactions.push({
          id: sale.id,
          type: 'sale',
          date: new Date(sale.created_at),
          description: `Vente #${sale.id.substring(0, 8)}`,
          amount: sale.total || 0,
          status: sale.status,
        });
      });

      (repairs || []).forEach(repair => {
        transactions.push({
          id: repair.id,
          type: 'repair',
          date: new Date(repair.created_at),
          description: `Réparation #${repair.id.substring(0, 8)}`,
          amount: repair.total_price || 0,
          status: repair.status,
        });
      });

      (expenses || []).forEach(expense => {
        transactions.push({
          id: expense.id,
          type: 'expense',
          date: new Date(expense.expense_date),
          description: expense.title || 'Dépense',
          amount: -(expense.amount || 0), // Négatif pour les dépenses
          status: expense.status,
        });
      });

      // Trier par date
      transactions.sort((a, b) => b.date.getTime() - a.date.getTime());

      return handleSupabaseSuccess(transactions);
    } catch (err: any) {
      console.error('Erreur lors de la récupération des transactions:', err);
      return handleSupabaseError(new Error(`Erreur lors de la récupération des transactions: ${err.message}`));
    }
  },

  /**
   * Récupérer le tableau de bord comptable (version simplifiée)
   */
  async getAccountingDashboard(userId: string): Promise<{ success: boolean; data?: any; error?: Error }> {
    try {
      const [kpisResult, transactionsResult] = await Promise.all([
        this.getAccountingKPIs(userId),
        this.getTransactions(userId)
      ]);

      if (!kpisResult.success) {
        return handleSupabaseError(new Error('Erreur lors de la récupération des KPIs'));
      }

      if (!transactionsResult.success) {
        return handleSupabaseError(new Error('Erreur lors de la récupération des transactions'));
      }

      const dashboard = {
        kpis: kpisResult.data,
        transactions: transactionsResult.data,
        summary: {
          totalTransactions: transactionsResult.data?.length || 0,
          lastUpdated: new Date().toISOString(),
        }
      };

      return handleSupabaseSuccess(dashboard);
    } catch (err: any) {
      console.error('Erreur lors de la récupération du tableau de bord:', err);
      return handleSupabaseError(new Error(`Erreur lors de la récupération du tableau de bord: ${err.message}`));
    }
  },
};
