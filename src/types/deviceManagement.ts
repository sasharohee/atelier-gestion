export interface DeviceCategory {
  id: string;
  name: string;
  description: string;
  icon: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface DeviceBrand {
  id: string;
  name: string;
  categoryId: string;
  description: string;
  logo?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface DeviceModel {
  id: string;
  name: string;
  model: string;
  description: string;
  brandId: string;
  categoryId: string;
  brandName: string;
  categoryName: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

