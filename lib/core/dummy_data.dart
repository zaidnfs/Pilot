import '../models/store.dart';
import '../models/profile.dart';
import '../models/order.dart';

/// Static dummy data for UI visualization and testing.
class DummyData {
  DummyData._();

  static final List<Store> stores = [
    Store(
      id: 1,
      ownerId: 'owner-1',
      name: 'Sharma General Store',
      description: 'Daily groceries, snacks, and staples',
      phone: '+919876543210',
      address: '10/2 Kursi Road, Dashauli',
      lat: 26.9124,
      lng: 80.9412,
      category: 'kirana',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Store(
      id: 2,
      ownerId: 'owner-2',
      name: 'City Pharmacy',
      description: 'All medicines available',
      phone: '+919876543211',
      address: 'Opposite Metro Station, Kursi Road',
      lat: 26.9150,
      lng: 80.9400,
      category: 'pharmacy',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Store(
      id: 3,
      ownerId: 'owner-3',
      name: 'Mittal Bakers',
      description: 'Fresh bread, cakes, and dairy',
      phone: '+919876543212',
      address: 'Near Crossing, Dashauli',
      lat: 26.9110,
      lng: 80.9450,
      category: 'bakery',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  static final profileRequester = Profile(
    id: 'req-1',
    phone: '+919800000001',
    fullName: 'Rahul Singh',
    aadhaarVerified: true,
    aadhaarMaskedName: 'Ra***',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final profileTraveler = Profile(
    id: 'trav-1',
    phone: '+919800000002',
    fullName: 'Anjali Gupta',
    aadhaarVerified: true,
    aadhaarMaskedName: 'An***',
    aadhaarPhotoUrl: 'https://i.pravatar.cc/150?u=anjali',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final List<Order> availableOrders = [
    Order(
      id: 101,
      requesterId: profileRequester.id,
      storeId: 1,
      status: OrderStatus.requested,
      deliveryMode: DeliveryMode.standard,
      itemsDescription: '2 packets Aashirvaad Atta 5kg, 1L Amul Gold Milk',
      itemsEstimatedCost: 450.0,
      bounty: 25.0,
      requesterLat: 26.9200,
      requesterLng: 80.9500,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      updatedAt: DateTime.now(),
      store: stores[0],
      requester: profileRequester,
    ),
    Order(
      id: 102,
      requesterId: 'req-2',
      storeId: 2,
      status: OrderStatus.requested,
      deliveryMode: DeliveryMode.express,
      itemsDescription: 'Crocin Pain Relief, Band-aids',
      itemsEstimatedCost: 120.0,
      bounty: 40.0,
      requesterLat: 26.9190,
      requesterLng: 80.9550,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      updatedAt: DateTime.now(),
      store: stores[1],
    ),
  ];

  static final trackingOrder = Order(
    id: 99,
    requesterId: profileRequester.id,
    travelerId: profileTraveler.id,
    storeId: 3,
    status: OrderStatus.pickedUp,
    deliveryMode: DeliveryMode.standard,
    itemsDescription: '1 loaf Brown Bread, 6 Eggs',
    itemsEstimatedCost: 90.0,
    bounty: 15.0,
    otpCode: '4821',
    requesterLat: 26.9200,
    requesterLng: 80.9500,
    pickupAt: DateTime.now().subtract(const Duration(minutes: 10)),
    createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    updatedAt: DateTime.now(),
    store: stores[2],
    traveler: profileTraveler,
  );

  static final activeDelivery = Order(
    id: 99,
    requesterId: profileRequester.id,
    travelerId: profileTraveler.id,
    storeId: 3,
    status: OrderStatus.accepted,
    deliveryMode: DeliveryMode.standard,
    itemsDescription: '1 loaf Brown Bread, 6 Eggs',
    itemsEstimatedCost: 90.0,
    bounty: 15.0,
    requesterLat: 26.9200,
    requesterLng: 80.9500,
    createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    updatedAt: DateTime.now(),
    store: stores[2],
    requester: profileRequester,
  );
}
