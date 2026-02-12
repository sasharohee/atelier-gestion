// Types pour la page Comptabilité

export interface AccountingTransaction {
  id: string;
  type: 'sale' | 'repair';
  date: Date;
  clientName: string;
  clientId: string;
  amount: number;
  isPaid: boolean;
  paymentMethod?: 'cash' | 'card' | 'transfer' | 'check' | 'payment_link';
  invoiceNumber?: string;
  description?: string;
  status?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface FinancialSummary {
  totalRevenue: number;
  totalExpenses: number;
  netProfit: number;
  monthlyRevenue: number;
  monthlyExpenses: number;
  monthlyProfit: number;
  transactionCount: number;
  averageTransactionValue: number;
  paidTransactions: number;
  pendingTransactions: number;
  overdueTransactions: number;
}

export interface Invoice {
  id: string;
  invoiceNumber: string;
  type: 'sale' | 'repair';
  clientId: string;
  clientName: string;
  amount: number;
  tax: number;
  total: number;
  status: 'draft' | 'sent' | 'paid' | 'overdue' | 'cancelled';
  issueDate: Date;
  dueDate: Date;
  paidDate?: Date;
  paymentMethod?: string;
  description?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface ExpenseSummary {
  totalExpenses: number;
  monthlyExpenses: number;
  expenseCount: number;
  averageExpense: number;
  byCategory: Record<string, number>;
  byPaymentMethod: Record<string, number>;
  pendingExpenses: number;
  paidExpenses: number;
}

export interface AccountingFilters {
  startDate?: Date;
  endDate?: Date;
  type?: 'sale' | 'repair' | 'expense' | 'all';
  status?: 'paid' | 'pending' | 'overdue' | 'all';
  clientId?: string;
  paymentMethod?: string;
  amountMin?: number;
  amountMax?: number;
}

export interface ExportOptions {
  format: 'excel' | 'pdf';
  dataType: 'transactions' | 'invoices' | 'expenses' | 'financial_report' | 'all';
  startDate?: Date;
  endDate?: Date;
  includeCharts?: boolean;
  groupBy?: 'day' | 'week' | 'month' | 'year';
}

export interface FinancialReport {
  period: {
    start: Date;
    end: Date;
    label: string;
  };
  summary: FinancialSummary;
  revenue: {
    total: number;
    byType: Record<string, number>;
    byMonth: Array<{ month: string; amount: number }>;
    growth: number; // Pourcentage de croissance
  };
  expenses: {
    total: number;
    byCategory: Record<string, number>;
    byMonth: Array<{ month: string; amount: number }>;
    growth: number; // Pourcentage de croissance
  };
  profitability: {
    grossMargin: number; // Marge brute
    netMargin: number; // Marge nette
    roi: number; // Retour sur investissement
  };
  trends: {
    revenue: Array<{ date: string; value: number }>;
    expenses: Array<{ date: string; value: number }>;
    profit: Array<{ date: string; value: number }>;
  };
}

export interface AccountingKPIs {
  totalRevenue: number;
  totalExpenses: number;
  netProfit: number;
  profitMargin: number; // Pourcentage
  revenueGrowth: number; // Pourcentage de croissance
  expenseGrowth: number; // Pourcentage de croissance
  averageTransactionValue: number;
  totalTransactions: number;
  paidTransactions: number;
  pendingAmount: number;
  overdueAmount: number;
}

export interface ChartData {
  labels: string[];
  datasets: Array<{
    label: string;
    data: number[];
    backgroundColor?: string | string[];
    borderColor?: string | string[];
    borderWidth?: number;
  }>;
}

export interface AccountingDashboard {
  kpis: AccountingKPIs;
  revenueChart: ChartData;
  expensesChart: ChartData;
  profitChart: ChartData;
  recentTransactions: AccountingTransaction[];
  topClients: Array<{
    clientId: string;
    clientName: string;
    totalAmount: number;
    transactionCount: number;
  }>;
  monthlyComparison: {
    current: number;
    previous: number;
    growth: number;
  };
}

// Types pour les exports
export interface ExcelExportData {
  filename: string;
  sheets: Array<{
    name: string;
    data: any[][];
    headers: string[];
  }>;
}

export interface PDFExportData {
  filename: string;
  title: string;
  content: {
    summary?: any;
    transactions?: any[];
    charts?: any[];
  };
}

// Types pour les filtres avancés
export interface AdvancedFilters {
  dateRange: {
    start: Date;
    end: Date;
    preset?: 'today' | 'yesterday' | 'thisWeek' | 'lastWeek' | 'thisMonth' | 'lastMonth' | 'thisYear' | 'lastYear' | 'custom';
  };
  amountRange: {
    min: number;
    max: number;
  };
  status: string[];
  paymentMethods: string[];
  clients: string[];
  categories: string[];
}

// Types pour les statistiques
export interface AccountingStats {
  totalRevenue: number;
  totalExpenses: number;
  netProfit: number;
  transactionCount: number;
  averageTransactionValue: number;
  topRevenueSource: string;
  topExpenseCategory: string;
  profitMargin: number;
  revenueGrowth: number;
  expenseGrowth: number;
}
