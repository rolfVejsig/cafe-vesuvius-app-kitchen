import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../widgets/order_card.dart';
import '../services/api_service.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  List<Order> orders = [];
  String error = '';
  bool loading = false;
  Timer? _refreshTimer;
  final refreshInterval = const Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _refreshTimer = Timer.periodic(refreshInterval, (_) => _loadOrders());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => loading = true);
    try {
      final fetchedOrders = await ApiService.fetchOrders();
      fetchedOrders.sort((a, b) => a.placedAt.compareTo(b.placedAt));
      setState(() {
        orders = fetchedOrders;
        error = '';
      });
    } catch (e) {
      setState(() => error = 'Kan ikke hente ordrer fra serveren');
      debugPrint('❌ $_loadOrders error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _updateStatus(String orderId, OrderStatus newStatus) async {
    debugPrint('\n🔄 === STATUS UPDATE DETAILED DEBUG ===');
    debugPrint('� Order ID: "$orderId"');
    debugPrint('🎯 Target Status: ${newStatus.label} (${newStatus.name})');
    debugPrint('� Current orders in memory: ${orders.length}');
    
    // Find the current order
    final currentOrder = orders.where((o) => o.id == orderId).firstOrNull;
    if (currentOrder != null) {
      debugPrint('📄 Found order - Current status: ${currentOrder.status.label}');
      debugPrint('📄 Order table: ${currentOrder.table}');
    } else {
      debugPrint('❌ Order not found in current orders list!');
    }
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final snack = SnackBar(
      content: Row(children: [
        const CircularProgressIndicator(strokeWidth: 2),
        const SizedBox(width: 12),
        Text('Skifter til ${newStatus.label}...')
      ]),
      duration: const Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);

    try {
      debugPrint('🌐 Starting API call to update status...');
      final updatedOrder = await ApiService.updateOrderStatus(orderId, newStatus);
      debugPrint('✅ API call successful!');
      debugPrint('📋 Updated order ID: ${updatedOrder.id}');
      debugPrint('🎯 Updated order status: ${updatedOrder.status.label}');
      
      debugPrint('🔄 Reloading all orders from server...');
      await _loadOrders();
      debugPrint('✅ Orders reloaded - New count: ${orders.length}');
      
      // Verify the update worked
      final verifyOrder = orders.where((o) => o.id == orderId).firstOrNull;
      if (verifyOrder != null) {
        debugPrint('✅ Verification: Order now has status: ${verifyOrder.status.label}');
      } else {
        debugPrint('⚠️ Verification: Order not found after reload!');
      }
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Ordre #$orderId ændret til ${newStatus.label}'),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 3),
      ));
      
      debugPrint('🎉 Status update completed successfully!\n');
    } catch (e, stackTrace) {
      debugPrint('❌ === STATUS UPDATE FAILED ===');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Error message: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('❌ Kunne ikke skifte til ${newStatus.label}'),
            Text('Fejl: $e', style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 6),
      ));
      debugPrint('❌ === END ERROR DEBUG ===\n');
    }
  }

  String _timeSince(DateTime placedAt) {
    final diff = DateTime.now().difference(placedAt).inMinutes;
    if (diff == 0) return 'Nu';
    if (diff < 60) return '${diff}m';
    final hours = diff ~/ 60;
    return '${hours}h';
  }

  Color _urgencyColor(Order order) {
    final diff = DateTime.now().difference(order.placedAt).inMinutes;
    if (diff < 5) return const Color(0xFF1B4020);
    if (diff < 15) return const Color(0xFF8C6A00);
    return const Color(0xFF5A0A0A);
  }

  @override
  Widget build(BuildContext context) {
    final statuses = OrderStatus.values;
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200 ? 4 : width > 800 ? 2 : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Køkken Dashboard'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (loading)
              Container(
                height: 4,
                child: LinearProgressIndicator(
                  color: Theme.of(context).primaryColor,
                  backgroundColor: Colors.grey[900],
                ),
              ),
            if (error.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadOrders,
                color: Theme.of(context).primaryColor,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      padding: const EdgeInsets.all(2),
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: constraints.maxWidth > 1200
                          ? 0.75
                          : constraints.maxWidth > 800
                              ? 0.65
                              : 0.8,
                      children: statuses.map((status) {
                        final filtered = orders.where((o) => o.status == status).toList();
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: status.color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 60,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: status.color,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        status.icon,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        status.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          maxWidth: 40,
                                          minHeight: 24,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${filtered.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: filtered.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.inbox_outlined,
                                                size: 32,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Ingen ordrer',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        itemCount: filtered.length,
                                        itemBuilder: (context, idx) {
                                          final order = filtered[idx];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: OrderCard(
                                              order: order,
                                              statuses: statuses,
                                              onChangeStatus: _updateStatus,
                                              timeSinceLabel: _timeSince(order.placedAt),
                                              urgencyColor: _urgencyColor(order),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
