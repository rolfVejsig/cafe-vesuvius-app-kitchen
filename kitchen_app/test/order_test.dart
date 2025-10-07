import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_app/models/order.dart';

void main() {
  test('Order creates with correct values', () {
    final item = OrderItem(qty: 2, name: 'Pizza', notes: 'Ekstra ost');
    final order = Order(
      id: '123',
      table: '5',
      status: OrderStatus.queued,
      items: [item],
      placedAt: DateTime(2025, 10, 7),
    );
    expect(order.id, '123');
    expect(order.table, '5');
    expect(order.status, OrderStatus.queued);
    expect(order.items.length, 1);
    expect(order.items.first.name, 'Pizza');
    expect(order.items.first.notes, 'Ekstra ost');
  });
}
