import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import 'jspdf-autotable';
import { 
  AccountingTransaction, 
  FinancialSummary, 
  Invoice, 
  ExpenseSummary,
  ExportOptions,
  ExcelExportData,
  PDFExportData,
  FinancialReport
} from '../types/accounting';

// Extend jsPDF type to include autoTable
declare module 'jspdf' {
  interface jsPDF {
    autoTable: (options: any) => jsPDF;
  }
}

export const exportService = {
  /**
   * Exporter des données en Excel
   */
  async exportToExcel(data: any[], filename: string, options?: { sheetName?: string; headers?: string[] }): Promise<void> {
    try {
      const workbook = XLSX.utils.book_new();
      
      // Préparer les données
      let exportData = data;
      if (options?.headers && data.length > 0) {
        // Utiliser les en-têtes personnalisés
        const headers = options.headers;
        const rows = data.map(item => 
          headers.map(header => {
            const keys = header.split('.');
            let value = item;
            for (const key of keys) {
              value = value?.[key];
            }
            return value ?? '';
          })
        );
        exportData = [headers, ...rows];
      } else if (data.length > 0) {
        // Générer automatiquement les en-têtes
        const headers = Object.keys(data[0]);
        const rows = data.map(item => headers.map(header => item[header] ?? ''));
        exportData = [headers, ...rows];
      }

      // Créer la feuille de calcul
      const worksheet = XLSX.utils.aoa_to_sheet(exportData);
      
      // Ajuster la largeur des colonnes
      const colWidths = this.calculateColumnWidths(exportData);
      worksheet['!cols'] = colWidths;

      // Ajouter la feuille au classeur
      XLSX.utils.book_append_sheet(workbook, worksheet, options?.sheetName || 'Données');

      // Télécharger le fichier
      XLSX.writeFile(workbook, `${filename}.xlsx`);
    } catch (error) {
      console.error('Erreur lors de l\'export Excel:', error);
      throw new Error('Erreur lors de l\'export Excel');
    }
  },

  /**
   * Exporter des données en PDF
   */
  async exportToPDF(data: any[], filename: string, title: string, options?: { headers?: string[] }): Promise<void> {
    try {
      const doc = new jsPDF();
      
      // Ajouter le titre
      doc.setFontSize(20);
      doc.text(title, 14, 22);
      
      // Ajouter la date
      doc.setFontSize(10);
      doc.text(`Généré le ${new Date().toLocaleDateString('fr-FR')}`, 14, 30);

      if (data.length === 0) {
        doc.setFontSize(12);
        doc.text('Aucune donnée à exporter', 14, 50);
        doc.save(`${filename}.pdf`);
        return;
      }

      // Préparer les données pour le tableau
      let tableData: any[][] = [];
      let headers: string[] = [];

      if (options?.headers) {
        headers = options.headers;
        tableData = data.map(item => 
          headers.map(header => {
            const keys = header.split('.');
            let value = item;
            for (const key of keys) {
              value = value?.[key];
            }
            return this.formatValueForPDF(value);
          })
        );
      } else {
        headers = Object.keys(data[0]);
        tableData = data.map(item => 
          headers.map(header => this.formatValueForPDF(item[header]))
        );
      }

      // Ajouter le tableau
      (doc as any).autoTable({
        head: [headers],
        body: tableData,
        startY: 40,
        styles: {
          fontSize: 8,
          cellPadding: 3,
        },
        headStyles: {
          fillColor: [66, 139, 202],
          textColor: 255,
          fontStyle: 'bold',
        },
        alternateRowStyles: {
          fillColor: [245, 245, 245],
        },
        margin: { top: 40 },
      });

      // Ajouter le nombre total d'éléments
      const finalY = (doc as any).lastAutoTable.finalY || 50;
      doc.setFontSize(10);
      doc.text(`Total: ${data.length} éléments`, 14, finalY + 10);

      doc.save(`${filename}.pdf`);
    } catch (error) {
      console.error('Erreur lors de l\'export PDF:', error);
      throw new Error('Erreur lors de l\'export PDF');
    }
  },

  /**
   * Exporter un rapport financier complet
   */
  async exportFinancialReport(
    transactions: AccountingTransaction[],
    summary: FinancialSummary,
    expenses: ExpenseSummary,
    options: ExportOptions
  ): Promise<void> {
    try {
      if (options.format === 'excel') {
        await exportService.exportFinancialReportExcel(transactions, summary, expenses, options);
      } else {
        await exportService.exportFinancialReportPDF(transactions, summary, expenses, options);
      }
    } catch (error) {
      console.error('Erreur lors de l\'export du rapport financier:', error);
      throw new Error('Erreur lors de l\'export du rapport financier');
    }
  },

  /**
   * Exporter un rapport financier en Excel
   */
  async exportFinancialReportExcel(
    transactions: AccountingTransaction[],
    summary: FinancialSummary,
    expenses: ExpenseSummary,
    options: ExportOptions
  ): Promise<void> {
    const workbook = XLSX.utils.book_new();
    const filename = `rapport_financier_${this.getDateString(options.startDate)}_${this.getDateString(options.endDate)}`;

    // Feuille 1: Résumé
    const summaryData = [
      ['RÉSUMÉ FINANCIER'],
      [''],
      ['Revenus totaux', this.formatCurrency(summary.totalRevenue)],
      ['Dépenses totales', this.formatCurrency(summary.totalExpenses)],
      ['Bénéfice net', this.formatCurrency(summary.netProfit)],
      ['Marge bénéficiaire', `${((summary.netProfit / summary.totalRevenue) * 100).toFixed(2)}%`],
      [''],
      ['Revenus mensuels', this.formatCurrency(summary.monthlyRevenue)],
      ['Dépenses mensuelles', this.formatCurrency(summary.monthlyExpenses)],
      ['Bénéfice mensuel', this.formatCurrency(summary.monthlyProfit)],
      [''],
      ['Nombre de transactions', summary.transactionCount],
      ['Transactions payées', summary.paidTransactions],
      ['Transactions en attente', summary.pendingTransactions],
      ['Valeur moyenne des transactions', this.formatCurrency(summary.averageTransactionValue)],
    ];

    const summarySheet = XLSX.utils.aoa_to_sheet(summaryData);
    XLSX.utils.book_append_sheet(workbook, summarySheet, 'Résumé');

    // Feuille 2: Transactions
    const transactionHeaders = [
      'Date', 'Type', 'Client', 'Montant', 'Statut', 'Méthode de paiement'
    ];
    const transactionData = transactions.map(t => [
      t.date.toLocaleDateString('fr-FR'),
      t.type === 'sale' ? 'Vente' : 'Réparation',
      t.clientName,
      t.amount,
      t.isPaid ? 'Payé' : 'En attente',
      t.paymentMethod || 'N/A'
    ]);

    const transactionSheet = XLSX.utils.aoa_to_sheet([
      transactionHeaders,
      ...transactionData
    ]);
    XLSX.utils.book_append_sheet(workbook, transactionSheet, 'Transactions');

    // Feuille 3: Dépenses
    const expenseHeaders = ['Total des dépenses', 'Dépenses mensuelles', 'Nombre de dépenses'];
    const expenseData = [
      [this.formatCurrency(expenses.totalExpenses)],
      [this.formatCurrency(expenses.monthlyExpenses)],
      [expenses.expenseCount]
    ];

    const expenseSheet = XLSX.utils.aoa_to_sheet([
      expenseHeaders,
      ...expenseData
    ]);
    XLSX.utils.book_append_sheet(workbook, expenseSheet, 'Dépenses');

    XLSX.writeFile(workbook, `${filename}.xlsx`);
  },

  /**
   * Exporter un rapport financier en PDF
   */
  async exportFinancialReportPDF(
    transactions: AccountingTransaction[],
    summary: FinancialSummary,
    expenses: ExpenseSummary,
    options: ExportOptions
  ): Promise<void> {
    const doc = new jsPDF();
    const filename = `rapport_financier_${this.getDateString(options.startDate)}_${this.getDateString(options.endDate)}`;

    // Titre
    doc.setFontSize(20);
    doc.text('RAPPORT FINANCIER', 14, 22);

    // Période
    doc.setFontSize(12);
    const periodText = options.startDate && options.endDate 
      ? `Période: ${options.startDate.toLocaleDateString('fr-FR')} - ${options.endDate.toLocaleDateString('fr-FR')}`
      : 'Période: Toutes les données';
    doc.text(periodText, 14, 30);

    // Date de génération
    doc.setFontSize(10);
    doc.text(`Généré le ${new Date().toLocaleDateString('fr-FR')}`, 14, 38);

    let currentY = 50;

    // Résumé financier
    doc.setFontSize(14);
    doc.text('RÉSUMÉ FINANCIER', 14, currentY);
    currentY += 10;

    const summaryData = [
      ['Revenus totaux', this.formatCurrency(summary.totalRevenue)],
      ['Dépenses totales', this.formatCurrency(summary.totalExpenses)],
      ['Bénéfice net', this.formatCurrency(summary.netProfit)],
      ['Marge bénéficiaire', `${((summary.netProfit / summary.totalRevenue) * 100).toFixed(2)}%`],
    ];

    (doc as any).autoTable({
      head: [['Indicateur', 'Valeur']],
      body: summaryData,
      startY: currentY,
      styles: { fontSize: 10 },
      headStyles: { fillColor: [66, 139, 202], textColor: 255 },
    });

    currentY = (doc as any).lastAutoTable.finalY + 20;

    // Transactions récentes
    if (transactions.length > 0) {
      doc.setFontSize(14);
      doc.text('TRANSACTIONS RÉCENTES', 14, currentY);
      currentY += 10;

      const recentTransactions = transactions.slice(0, 20); // Limiter à 20 transactions
      const transactionData = recentTransactions.map(t => [
        t.date.toLocaleDateString('fr-FR'),
        t.type === 'sale' ? 'Vente' : 'Réparation',
        t.clientName,
        this.formatCurrency(t.amount),
        t.isPaid ? 'Payé' : 'En attente'
      ]);

      (doc as any).autoTable({
        head: [['Date', 'Type', 'Client', 'Montant', 'Statut']],
        body: transactionData,
        startY: currentY,
        styles: { fontSize: 8 },
        headStyles: { fillColor: [66, 139, 202], textColor: 255 },
      });
    }

    doc.save(`${filename}.pdf`);
  },

  /**
   * Exporter toutes les transactions
   */
  async exportAllTransactions(transactions: AccountingTransaction[], filename: string): Promise<void> {
    const headers = [
      'Date',
      'Type',
      'Client',
      'Montant',
      'Statut',
      'Méthode de paiement',
      'Date de création'
    ];

    const data = transactions.map(t => [
      t.date.toLocaleDateString('fr-FR'),
      t.type === 'sale' ? 'Vente' : 'Réparation',
      t.clientName,
      t.amount,
      t.isPaid ? 'Payé' : 'En attente',
      t.paymentMethod || 'N/A',
      t.createdAt.toLocaleDateString('fr-FR')
    ]);

    await this.exportToExcel(data, filename, { headers });
  },

  /**
   * Exporter les factures
   */
  async exportInvoices(invoices: Invoice[], filename: string): Promise<void> {
    const headers = [
      'Numéro de facture',
      'Type',
      'Client',
      'Montant HT',
      'TVA',
      'Montant TTC',
      'Statut',
      'Date d\'émission',
      'Date d\'échéance',
      'Date de paiement'
    ];

    const data = invoices.map(i => [
      i.invoiceNumber,
      i.type === 'sale' ? 'Vente' : 'Réparation',
      i.clientName,
      i.amount,
      i.tax,
      i.total,
      i.status,
      i.issueDate.toLocaleDateString('fr-FR'),
      i.dueDate.toLocaleDateString('fr-FR'),
      i.paidDate?.toLocaleDateString('fr-FR') || 'N/A'
    ]);

    await this.exportToExcel(data, filename, { headers });
  },

  /**
   * Utilitaires
   */
  calculateColumnWidths(data: any[][]): Array<{ wch: number }> {
    if (data.length === 0) return [];
    
    const widths: number[] = [];
    const maxCols = Math.max(...data.map(row => row.length));
    
    for (let col = 0; col < maxCols; col++) {
      let maxWidth = 10; // Largeur minimale
      for (let row = 0; row < data.length; row++) {
        if (data[row][col] !== undefined) {
          const cellLength = String(data[row][col]).length;
          maxWidth = Math.max(maxWidth, cellLength);
        }
      }
      widths.push(Math.min(maxWidth + 2, 50)); // Largeur maximale de 50
    }
    
    return widths.map(w => ({ wch: w }));
  },

  formatValueForPDF(value: any): string {
    if (value === null || value === undefined) return '';
    if (typeof value === 'number') {
      return value.toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }
    if (value instanceof Date) {
      return value.toLocaleDateString('fr-FR');
    }
    return String(value);
  },

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount);
  },

  getDateString(date?: Date): string {
    if (!date) return 'all';
    return date.toISOString().split('T')[0];
  }
};
