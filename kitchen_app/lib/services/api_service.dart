import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../config.dart';

class ApiService {
  static const String baseUrl = "$apiBaseUrl/api"; 

  static Future<List<Order>> fetchOrders() async {
    final response = await http.get(Uri.parse("$baseUrl/kitchen/orders"));
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List data = responseData['orders'] ?? responseData['data'] ?? [];
      return data.map((o) => Order(
        id: o['id']?.toString() ?? '',
        table: o['table'] ?? 'Bord ${o['tableNumber'] ?? o['tableName'] ?? 'Ukendt'}',
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
    final statusStr = status?.toString().toUpperCase().trim();
    print('🔄 Mapping backend status: "$statusStr"');
    
    switch (statusStr) {
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
        print('⚠️ Unknown status: "$statusStr", defaulting to queued');
        return OrderStatus.queued;
    }
  }

  static Future<Order> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final backendStatus = _mapStatusToBackend(newStatus);
    
    print('🌐 === API UPDATE STATUS DEBUG ===');
    print('🌐 Order ID: "$orderId"');
    print('🌐 Frontend Status: ${newStatus.label} (${newStatus.name})');
    print('🌐 Backend Status: "$backendStatus"');
    print('🌐 API URL: $baseUrl/kitchen/orders/$orderId/status');
    print('🌐 Full URL: $baseUrl/kitchen/orders/$orderId/status');
    
    final requestBody = {"status": backendStatus};
    final requestBodyJson = jsonEncode(requestBody);
    print('🌐 Request body: $requestBodyJson');
    
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/kitchen/orders/$orderId/status"),
        headers: {"Content-Type": "application/json"},
        body: requestBodyJson,
      ).timeout(const Duration(seconds: 10));

      print('🌐 Response status: ${response.statusCode}');
      print('🌐 Response headers: ${response.headers}');
      print('🌐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final o = responseData['order'] ?? responseData;
        
        print('✅ Successfully parsed response data');
        print('✅ Order data keys: ${o.keys}');
        
        return Order(
          id: o['id']?.toString() ?? '',
          table: o['table'] ?? 'Bord ${o['tableNumber'] ?? o['tableName'] ?? 'Ukendt'}',
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
        final errorMsg = "HTTP ${response.statusCode}: ${response.body}";
        print('❌ API Error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Network/API Exception: $e');
      rethrow;
    }
  }

  static String _mapStatusToBackend(OrderStatus status) {
    switch (status) {
      case OrderStatus.queued:
        return 'ORDERED';  
      case OrderStatus.inProgress:
        return 'IN_PREPARATION'; 
      case OrderStatus.ready:
        return 'READY';
      case OrderStatus.complications:
        return 'CANCELLED';
    }
  }
}
