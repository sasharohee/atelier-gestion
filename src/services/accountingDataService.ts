import { supabase } from '../lib/supabase';
import { handleSupabaseError, handleSupabaseSuccess } from '../lib/supabase';
import { 
  AccountingTransaction, 
  FinancialSummary, 
  Invoice, 
  ExpenseSummary,
  AccountingFilters,
  AccountingKPIs,
  AccountingDashboard,
  FinancialReport
} from '../types/accounting';

export const accountingDataService = {
  /**
   * Récupérer toutes les transactions (ventes + réparations payées)
   */
  async getAllTransactions(filters?: AccountingFilters): Promise<{ success: boolean; data?: AccountingTransaction[]; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      let query = supabase
        .from('sales')
        .select(`
          id,
          client_id,
          subtotal,
          tax,
          total,
          payment_method,
          status,
          created_at,
          updated_at,
          clients!inner(first_name, last_name)
        `)
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      // Appliquer les filtres
      if (filters?.startDate) {
        query = query.gte('created_at', filters.startDate.toISOString());
      }
      if (filters?.endDate) {
        query = query.lte('created_at', filters.endDate.toISOString());
      }
      if (filters?.status && filters.status !== 'all') {
        query = query.eq('status', filters.status);
      }
      if (filters?.paymentMethod) {
        query = query.eq('payment_method', filters.paymentMethod);
      }

      const { data: sales, error: salesError } = await query;

      if (salesError) {
        return handleSupabaseError(salesError);
      }

      // Récupérer les réparations payées
      let repairsQuery = supabase
        .from('repairs')
        .select(`
          id,
          client_id,
          total_price,
          is_paid,
          created_at,
          updated_at,
          clients!inner(first_name, last_name)
        `)
        .eq('user_id', user.id)
        .eq('is_paid', true)
        .order('created_at', { ascending: false });

      // Appliquer les mêmes filtres aux réparations
      if (filters?.startDate) {
        repairsQuery = repairsQuery.gte('created_at', filters.startDate.toISOString());
      }
      if (filters?.endDate) {
        repairsQuery = repairsQuery.lte('created_at', filters.endDate.toISOString());
      }

      const { data: repairs, error: repairsError } = await repairsQuery;

      if (repairsError) {
        return handleSupabaseError(repairsError);
      }

      // Convertir les ventes en transactions
      const salesTransactions: AccountingTransaction[] = (sales || []).map(sale => ({
        id: sale.id,
        type: 'sale' as const,
        date: new Date(sale.created_at),
        clientName: `${sale.clients.first_name} ${sale.clients.last_name}`,
        clientId: sale.client_id,
        amount: sale.total,
        isPaid: sale.status === 'completed',
        paymentMethod: sale.payment_method,
        status: sale.status,
        createdAt: new Date(sale.created_at),
        updatedAt: new Date(sale.updated_at)
      }));

      // Convertir les réparations en transactions
      const repairsTransactions: AccountingTransaction[] = (repairs || []).map(repair => ({
        id: repair.id,
        type: 'repair' as const,
        date: new Date(repair.created_at),
        clientName: `${repair.clients.first_name} ${repair.clients.last_name}`,
        clientId: repair.client_id,
        amount: repair.total_price,
        isPaid: repair.is_paid,
        status: 'completed',
        createdAt: new Date(repair.created_at),
        updatedAt: new Date(repair.updated_at)
      }));

      // Combiner et trier toutes les transactions
      const allTransactions = [...salesTransactions, ...repairsTransactions]
        .sort((a, b) => b.date.getTime() - a.date.getTime());

      return handleSupabaseSuccess(allTransactions);
    } catch (err) {
      console.error('Erreur lors de la récupération des transactions:', err);
      return handleSupabaseError(err instanceof Error ? err : new Error('Erreur inconnue'));
    }
  },

  /**
   * Récupérer le résumé financier
   */
  async getFinancialSummary(filters?: AccountingFilters): Promise<{ success: boolean; data?: FinancialSummary; error?: string }> {
    try {
      const transactionsResult = await this.getAllTransactions(filters);
      if (!transactionsResult.success || !transactionsResult.data) {
        return handleSupabaseError(new Error('Impossible de récupérer les transactions'));
      }

      const transactions = transactionsResult.data;
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

      // Calculer les totaux
      const totalRevenue = transactions
        .filter(t => t.isPaid)
        .reduce((sum, t) => sum + t.amount, 0);

      const monthlyTransactions = transactions.filter(t => 
        t.date >= startOfMonth && t.isPaid
      );
      const monthlyRevenue = monthlyTransactions.reduce((sum, t) => sum + t.amount, 0);

      // Récupérer les dépenses
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      let expensesQuery = supabase
        .from('expenses')
        .select('amount, status, created_at')
        .eq('user_id', user.id);

      if (filters?.startDate) {
        expensesQuery = expensesQuery.gte('created_at', filters.startDate.toISOString());
      }
      if (filters?.endDate) {
        expensesQuery = expensesQuery.lte('created_at', filters.endDate.toISOString());
      }

      const { data: expenses, error: expensesError } = await expensesQuery;

      if (expensesError) {
        return handleSupabaseError(expensesError);
      }

      const totalExpenses = (expenses || [])
        .filter(e => e.status === 'paid')
        .reduce((sum, e) => sum + e.amount, 0);

      const monthlyExpenses = (expenses || [])
        .filter(e => e.status === 'paid' && new Date(e.created_at) >= startOfMonth)
        .reduce((sum, e) => sum + e.amount, 0);

      const summary: FinancialSummary = {
        totalRevenue,
        totalExpenses,
        netProfit: totalRevenue - totalExpenses,
        monthlyRevenue,
        monthlyExpenses,
        monthlyProfit: monthlyRevenue - monthlyExpenses,
        transactionCount: transactions.length,
        averageTransactionValue: transactions.length > 0 ? totalRevenue / transactions.length : 0,
        paidTransactions: transactions.filter(t => t.isPaid).length,
        pendingTransactions: transactions.filter(t => !t.isPaid).length,
        overdueTransactions: 0 // À implémenter selon la logique métier
      };

      return handleSupabaseSuccess(summary);
    } catch (err) {
      console.error('Erreur lors du calcul du résumé financier:', err);
      return handleSupabaseError(err instanceof Error ? err : new Error('Erreur inconnue'));
    }
  },

  /**
   * Récupérer les factures
   */
  async getInvoices(filters?: AccountingFilters): Promise<{ success: boolean; data?: Invoice[]; error?: string }> {
    try {
      const transactionsResult = await this.getAllTransactions(filters);
      if (!transactionsResult.success || !transactionsResult.data) {
        return handleSupabaseError(new Error('Impossible de récupérer les transactions'));
      }

      const transactions = transactionsResult.data;
      
      // Convertir les transactions en factures
      const invoices: Invoice[] = transactions.map((transaction, index) => ({
        id: transaction.id,
        invoiceNumber: `FACT-${new Date().getFullYear()}-${String(index + 1).padStart(4, '0')}`,
        type: transaction.type,
        clientId: transaction.clientId,
        clientName: transaction.clientName,
        amount: transaction.amount,
        tax: transaction.amount * 0.2, // TVA à 20% - à adapter selon les paramètres
        total: transaction.amount * 1.2,
        status: transaction.isPaid ? 'paid' : 'sent',
        issueDate: transaction.date,
        dueDate: new Date(transaction.date.getTime() + 30 * 24 * 60 * 60 * 1000), // 30 jours
        paidDate: transaction.isPaid ? transaction.date : undefined,
        paymentMethod: transaction.paymentMethod,
        description: `Facture ${transaction.type === 'sale' ? 'de vente' : 'de réparation'}`,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt
      }));

      return handleSupabaseSuccess(invoices);
    } catch (err) {
      console.error('Erreur lors de la récupération des factures:', err);
      return handleSupabaseError(err instanceof Error ? err : new Error('Erreur inconnue'));
    }
  },

  /**
   * Récupérer le résumé des dépenses
   */
  async getExpenseSummary(filters?: AccountingFilters): Promise<{ success: boolean; data?: ExpenseSummary; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return handleSupabaseError(new Error('Utilisateur non connecté'));
      }

      let query = supabase
        .from('expenses')
        .select('amount, status, payment_method, created_at')
        .eq('user_id', user.id);

      if (filters?.startDate) {
        query = query.gte('created_at', filters.startDate.toISOString());
      }
      if (filters?.endDate) {
        query = query.lte('created_at', filters.endDate.toISOString());
      }

      const { data: expenses, error } = await query;

      if (error) {
        return handleSupabaseError(error);
      }

      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

      const totalExpenses = (expenses || [])
        .filter(e => e.status === 'paid')
        .reduce((sum, e) => sum + e.amount, 0);

      const monthlyExpenses = (expenses || [])
        .filter(e => e.status === 'paid' && new Date(e.created_at) >= startOfMonth)
        .reduce((sum, e) => sum + e.amount, 0);

      const expenseCount = expenses?.length || 0;
      const paidExpenses = expenses?.filter(e => e.status === 'paid').length || 0;
      const pendingExpenses = expenses?.filter(e => e.status === 'pending').length || 0;

      // Grouper par méthode de paiement
      const byPaymentMethod: Record<string, number> = {};
      expenses?.forEach(expense => {
        if (expense.status === 'paid') {
          byPaymentMethod[expense.payment_method] = (byPaymentMethod[expense.payment_method] || 0) + expense.amount;
        }
      });

      const summary: ExpenseSummary = {
        totalExpenses,
        monthlyExpenses,
        expenseCount,
        averageExpense: expenseCount > 0 ? totalExpenses / expenseCount : 0,
        byCategory: {}, // À implémenter si des catégories sont ajoutées
        byPaymentMethod,
        pendingExpenses,
        paidExpenses
      };

      return handleSupabaseSuccess(summary);
    } catch (err) {
      console.error('Erreur lors du calcul du résumé des dépenses:', err);
      return handleSupabaseError(err instanceof Error ? err : new Error('Erreur inconnue'));
    }
  },

  /**
   * Récupérer les KPIs comptables
   */
  async getAccountingKPIs(filters?: AccountingFilters): Promise<{ success: boolean; data?: AccountingKPIs; error?: string }> {
    try {
      const [summaryResult, expenseResult] = await Promise.all([
        this.getFinancialSummary(filters),
        this.getExpenseSummary(filters)
      ]);

      if (!summaryResult.success || !summaryResult.data || !expenseResult.success || !expenseResult.data) {
        return handleSupabaseError(new Error('Impossible de récupérer les données'));
      }

      const summary = summaryResult.data;
      const expenses = expenseResult.data;

      const kpis: AccountingKPIs = {
        totalRevenue: summary.totalRevenue,
        totalExpenses: summary.totalExpenses,
        netProfit: summary.netProfit,
        profitMargin: summary.totalRevenue > 0 ? (summary.netProfit / summary.totalRevenue) * 100 : 0,
        revenueGrowth: 0, // À calculer avec les données précédentes
        expenseGrowth: 0, // À calculer avec les données précédentes
        averageTransactionValue: summary.averageTransactionValue,
        totalTransactions: summary.transactionCount,
        paidTransactions: summary.paidTransactions,
        pendingAmount: summary.pendingTransactions * summary.averageTransactionValue,
        overdueAmount: summary.overdueTransactions * summary.averageTransactionValue
      };

      return handleSupabaseSuccess(kpis);
    } catch (err) {
      console.error('Erreur lors du calcul des KPIs:', err);
      return handleSupabaseError(err instanceof Error ? err : new Error('Erreur inconnue'));
    }
  },

  /**
   * Récupérer le tableau de bord comptable
   */
  async getAccountingDashboard(filters?: AccountingFilters): Promise<{ success: boolean; data?: AccountingDashboard; error?: string }> {
    try {
      const [kpisResult, transactionsResult] = await Promise.all([
        this.getAccountingKPIs(filters),
        this.getAllTransactions(filters)
      ]);

      if (!kpisResult.success || !kpisResult.data || !transactionsResult.success || !transactionsResult.data) {
        return handleSupabaseError(new Error('Impossible de récupérer les données'));
      }

      const kpis = kpisResult.data;
      const transactions = transactionsResult.data;

      // Créer les données de graphiques
      const revenueChart = {
        labels: ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun'],
        datasets: [{
          label: 'Revenus',
          data: [0, 0, 0, 0, 0, 0], // À remplacer par les vraies données
          backgroundColor: 'rgba(34, 197, 94, 0.2)',
          borderColor: 'rgba(34, 197, 94, 1)',
          borderWidth: 2
        }]
      };

      const expensesChart = {
        labels: ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun'],
        datasets: [{
          label: 'Dépenses',
          data: [0, 0, 0, 0, 0, 0], // À remplacer par les vraies données
          backgroundColor: 'rgba(239, 68, 68, 0.2)',
          borderColor: 'rgba(239, 68, 68, 1)',
          borderWidth: 2
        }]
      };

      const profitChart = {
        labels: ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun'],
        datasets: [{
          label: 'Bénéfices',
          data: [0, 0, 0, 0, 0, 0], // À remplacer par les vraies données
          backgroundColor: 'rgba(59, 130, 246, 0.2)',
          borderColor: 'rgba(59, 130, 246, 1)',
          borderWidth: 2
        }]
      };

      // Top clients
      const clientTotals: Record<string, { name: string; amount: number; count: number }> = {};
      transactions.forEach(transaction => {
        if (transaction.isPaid) {
          if (!clientTotals[transaction.clientId]) {
            clientTotals[transaction.clientId] = {
              name: transaction.clientName,
              amount: 0,
              count: 0
            };
          }
          clientTotals[transaction.clientId].amount += transaction.amount;
          clientTotals[transaction.clientId].count += 1;
        }
      });

      const topClients = Object.values(clientTotals)
        .sort((a, b) => b.amount - a.amount)
        .slice(0, 5);

      const dashboard: AccountingDashboard = {
        kpis,
        revenueChart,
        expensesChart,
        profitChart,
        recentTransactions: transactions.slice(0, 10),
        topClients,
        monthlyComparison: {
          current: kpis.totalRevenue,
          previous: 0, // À calculer avec les données précédentes
          growth: 0
        }
      };

      return handleSupabaseSuccess(dashboard);
    } catch (err) {
      console.error('Erreur lors de la récupération du tableau de bord:', err);
      return handleSupabaseError(err instanceof Error ? err : new Error('Erreur inconnue'));
    }
  }
};
