// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<void> printGroceryListPdf(Map<String, dynamic> data) async {
  final items = data['items'] as List<dynamic>? ?? [];
  var planToBuyTotal = 0.0;
  var boughtTotal = 0.0;
  var alreadyHaveTotal = 0.0;
  var remainingTotal = 0.0;
  final rows = items.map((rawItem) {
    final item = Map<String, dynamic>.from(rawItem as Map);
    final status = _status(item);
    final cost = _moneyValue(item['estimated_cost']);
    if (status == 'have') {
      alreadyHaveTotal += cost;
    } else {
      planToBuyTotal += cost;
    }
    if (status == 'bought') {
      boughtTotal += cost;
    } else if (status == 'need_to_buy') {
      remainingTotal += cost;
    }
    final label = switch (status) {
      'have' => 'Already have',
      'bought' => 'Bought',
      _ => 'Need to buy',
    };
    return '''
      <tr>
        <td>
          <strong>${_escape(item['food_item']?.toString() ?? 'Item')}</strong>
        </td>
        <td>${_escape(item['quantity']?.toString() ?? '')}</td>
        <td>\$${_formatMoney(cost)}</td>
        <td><span class="$status">${_escape(label)}</span></td>
      </tr>
    ''';
  }).join();
  final createdAt = _escape(data['created_at']?.toString() ?? '');
  final listName = _escape(data['name']?.toString() ?? 'Grocery List');
  final document =
      '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>NutriAI Grocery List</title>
  <style>
    body { font-family: Arial, sans-serif; color: #17231f; margin: 40px; }
    h1 { margin: 0 0 6px; font-size: 28px; }
    h2 { margin: 0 0 12px; font-size: 18px; color: #0d6040; }
    .meta { color: #62716a; margin-bottom: 24px; }
    .summary { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 24px; }
    .stat { border: 1px solid #d9e5de; border-radius: 10px; padding: 14px; }
    .label { color: #62716a; font-size: 12px; font-weight: 700; }
    .value { margin-top: 6px; font-size: 18px; font-weight: 800; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border-bottom: 1px solid #d9e5de; padding: 12px; text-align: left; }
    th { background: #e7f6ec; color: #0c3b2e; }
    .bought, .need_to_buy, .have { border-radius: 999px; display: inline-block; font-size: 12px; font-weight: 800; padding: 6px 10px; }
    .bought { background: #ddf7ea; color: #047a46; }
    .need_to_buy { background: #fff4e5; color: #9a5b00; }
    .have { background: #e0efff; color: #15558d; }
    @media print { body { margin: 24px; } }
  </style>
</head>
<body>
  <h1>NutriAI Grocery List</h1>
  <h2>$listName</h2>
  <div class="meta">Ingredients generated from meal plans. Generated: $createdAt</div>
  <section class="summary">
    <div class="stat"><div class="label">Plan to buy</div><div class="value">\$${_formatMoney(planToBuyTotal)}</div></div>
    <div class="stat"><div class="label">Still need</div><div class="value">\$${_formatMoney(remainingTotal)}</div></div>
    <div class="stat"><div class="label">Bought cost</div><div class="value">\$${_formatMoney(boughtTotal)}</div></div>
    <div class="stat"><div class="label">Already have</div><div class="value">\$${_formatMoney(alreadyHaveTotal)}</div></div>
  </section>
  <table>
    <thead>
      <tr><th>Ingredient</th><th>Quantity</th><th>Estimated cost</th><th>Status</th></tr>
    </thead>
    <tbody>$rows</tbody>
  </table>
  <script>
    window.addEventListener('load', function () {
      setTimeout(function () { window.print(); }, 250);
    });
  </script>
</body>
</html>
''';
  final blob = html.Blob([document], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  Future<void>.delayed(const Duration(seconds: 5), () {
    html.Url.revokeObjectUrl(url);
  });
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

double _moneyValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _status(Map<String, dynamic> item) {
  final status = item['status']?.toString();
  if (status == 'need_to_buy' || status == 'have' || status == 'bought') {
    return status!;
  }
  return item['purchased'] == true ? 'bought' : 'need_to_buy';
}

String _formatMoney(num value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
