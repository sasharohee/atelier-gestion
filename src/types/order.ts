export interface OrderItem {
  id: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  description: string;
}

export interface Order {
  id: string;
  orderNumber: string;
  supplierName: string;
  supplierEmail: string;
  supplierPhone: string;
  orderDate: string;
  expectedDeliveryDate: string;
  status: 'pending' | 'confirmed' | 'shipped' | 'delivered' | 'cancelled';
  totalAmount: number;
  items: OrderItem[];
  notes: string;
  trackingNumber?: string;
  actualDeliveryDate?: string;
}

export interface OrderFilters {
  searchTerm: string;
  statusFilter: string;
  dateFrom?: string;
  dateTo?: string;
  supplierFilter?: string;
}

