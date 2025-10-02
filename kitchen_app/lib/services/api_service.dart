import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class ApiService {
  static const String baseUrl = "http://100.115.199.103:3000/api"; 

  // Hent ordrer
  
  static Future<List<Order>> fetchOrders() async {
    final response = await http.get(Uri.parse("$baseUrl/orders"));
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List data = responseData['orders'] ?? responseData['data'] ?? [];
      return data.map((o) => Order(
        id: o['id']?.toString() ?? '',
        table: 'Bord ${o['tableNumber'] ?? o['tableName'] ?? o['table'] ?? 'Ukendt'}',
        status: _mapStatusFromBackend(o['status']),
        items: (o['items'] ?? []).map<OrderItem>((i) {
          if (i is Map) {
            return OrderItem(
              qty: i['quantity'] ?? i['qty'] ?? 1, 
              name: i['name'] ?? i['menuItem']?['name'] ?? '',
              notes: i['notes'] as String?,
            );
          } else {
            return OrderItem(qty: 1, name: i.toString());
          }
        }).toList(),
        placedAt: DateTime.tryParse(o['createdAt'] ?? o['placedAt'] ?? '') ?? DateTime.now(),
      )).toList();
    } else {
      throw Exception("Kunne ikke hente ordrer");
    }
  }

  static OrderStatus _mapStatusFromBackend(dynamic status) {
    switch (status?.toString().toUpperCase()) {
      case 'ORDERED':
      case 'CONFIRMED':
        return OrderStatus.queued;
      case 'PREPARING':
      case 'IN_PREPARATION':
        return OrderStatus.inProgress;
      case 'READY':
        return OrderStatus.ready;
      case 'SERVED':
      case 'COMPLETED':
      case 'CANCELLED':
        return OrderStatus.complications;
      default:
        return OrderStatus.queued;
    }
  }

  // Opdater ordrestatus
  static Future<Order> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final backendStatus = _mapStatusToBackend(newStatus);
    final response = await http.patch(
      Uri.parse("$baseUrl/orders/$orderId/status"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": backendStatus}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final o = responseData['order'] ?? responseData;
      return Order(
        id: o['id']?.toString() ?? '',
        table: 'Bord ${o['tableNumber'] ?? o['tableName'] ?? o['table'] ?? 'Ukendt'}',
        status: _mapStatusFromBackend(o['status']),
        items: (o['items'] ?? []).map<OrderItem>((i) {
          if (i is Map) {
            return OrderItem(
              qty: i['quantity'] ?? i['qty'] ?? 1, 
              name: i['name'] ?? i['menuItem']?['name'] ?? '',
              notes: i['notes'] as String?,
            );
          } else {
            return OrderItem(qty: 1, name: i.toString());
          }
        }).toList(),
        placedAt: DateTime.tryParse(o['createdAt'] ?? o['placedAt'] ?? '') ?? DateTime.now(),
      );
    } else {
      throw Exception("Kunne ikke opdatere ordrestatus");
    }
  }

  static String _mapStatusToBackend(OrderStatus status) {
    switch (status) {
      case OrderStatus.queued:
        return 'ORDERED';
      case OrderStatus.inProgress:
        return 'PREPARING';
      case OrderStatus.ready:
        return 'READY';
      case OrderStatus.complications:
        return 'CANCELLED';
    }
  }
}
