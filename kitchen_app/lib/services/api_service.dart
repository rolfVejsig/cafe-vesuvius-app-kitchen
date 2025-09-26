import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = "http://localhost:3000"; 

  // Hent ingredienser
  static Future<List<Ingredient>> fetchIngredients() async {
    final response = await http.get(Uri.parse("$baseUrl/ingredients"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Ingredient(
        name: e['name'],
        quantity: e['quantity'],
        unit: e['unit'],
      )).toList();
    } else {
      throw Exception("Kunne ikke hente ingredienser");
    }
  }

  // Hent opskrifter
  static Future<List<Recipe>> fetchRecipes() async {
    final response = await http.get(Uri.parse("$baseUrl/recipes"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Recipe(
        id: e['id'],
        name: e['name'],
        description: e['description'],
        preparationTime: e['preparationTime'],
        ingredients: (e['ingredients'] as List).map((ing) =>
          RecipeIngredient(
            name: ing['name'],
            requiredQuantity: ing['requiredQuantity'],
            unit: ing['unit'],
          )
        ).toList(),
        isAvailable: e['isAvailable'] ?? false,
      )).toList();
    } else {
      throw Exception("Kunne ikke hente opskrifter");
    }
  }

  // Hent ordrer
  static Future<List<Order>> fetchOrders() async {
    final response = await http.get(Uri.parse("$baseUrl/orders"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((o) => Order(
        id: o['id'],
        table: o['table'],
        status: OrderStatus.values.firstWhere(
          (s) => s.toString().split('.').last == o['status'],
        ),
        items: (o['items'] as List).map((i) => OrderItem(
          qty: i['qty'],
          name: i['name'],
        )).toList(),
        placedAt: DateTime.parse(o['placedAt']),
      )).toList();
    } else {
      throw Exception("Kunne ikke hente ordrer");
    }
  }

  // Opdater ordrestatus
  static Future<Order> updateOrderStatus(int orderId, OrderStatus newStatus) async {
    final response = await http.put(
      Uri.parse("$baseUrl/orders/$orderId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": newStatus.toString().split('.').last}),
    );

    if (response.statusCode == 200) {
      final o = jsonDecode(response.body);
      return Order(
        id: o['id'],
        table: o['table'],
        status: OrderStatus.values.firstWhere(
          (s) => s.toString().split('.').last == o['status'],
        ),
        items: (o['items'] as List).map((i) => OrderItem(
          qty: i['qty'],
          name: i['name'],
        )).toList(),
        placedAt: DateTime.parse(o['placedAt']),
      );
    } else {
      throw Exception("Kunne ikke opdatere ordrestatus");
    }
  }

  // Tilføj ingrediens
  static Future<void> addIngredient(String name, int quantity, String unit) async {
    final response = await http.post(
      Uri.parse("$baseUrl/ingredients"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "quantity": quantity,
        "unit": unit,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Kunne ikke tilføje ingrediens");
    }
  }
}
