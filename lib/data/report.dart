import '../models/product.dart' show dateOnly;
import '../models/transaction.dart';

/// Senin dari minggu yang memuat tanggal [d].
DateTime weekStartOf(DateTime d) {
  final day = dateOnly(d);
  return DateTime(day.year, day.month, day.day - (day.weekday - 1));
}

class DayStat {
  final DateTime day;
  int sales = 0;
  int cost = 0;
  int trx = 0;
  DayStat(this.day);

  int get profit => sales - cost;
}

class TopItem {
  final String name;
  int qty = 0;
  int sales = 0;
  int profit = 0;
  TopItem(this.name);
}

class WeekReport {
  final DateTime start;
  final List<DayStat> days; // Senin..Minggu
  final List<TopItem> top;
  final int itemsSold;
  final bool incompleteCost; // ada transaksi tanpa data modal
  final int prevProfit;
  final bool hasPrevData;

  WeekReport({
    required this.start,
    required this.days,
    required this.top,
    required this.itemsSold,
    required this.incompleteCost,
    required this.prevProfit,
    required this.hasPrevData,
  });

  DateTime get end => DateTime(start.year, start.month, start.day + 6);
  int get sales => days.fold(0, (a, d) => a + d.sales);
  int get cost => days.fold(0, (a, d) => a + d.cost);
  int get profit => sales - cost;
  int get trxCount => days.fold(0, (a, d) => a + d.trx);
  double get margin => sales == 0 ? 0 : profit / sales * 100;

  /// Perubahan profit dibanding minggu lalu (persen). null = tidak bisa dibandingkan.
  double? get changePct => (!hasPrevData || prevProfit <= 0)
      ? null
      : (profit - prevProfit) / prevProfit * 100;

  int get bestDayIndex {
    var best = 0;
    for (var i = 1; i < days.length; i++) {
      if (days[i].sales > days[best].sales) best = i;
    }
    return best;
  }
}

class _Collected {
  final List<DayStat> days;
  final Map<String, TopItem> top;
  int itemsSold = 0;
  bool incomplete = false;
  _Collected(this.days, this.top);
}

_Collected _collect(List<TrxItem> all, DateTime start) {
  final days = List.generate(
      7, (i) => DayStat(DateTime(start.year, start.month, start.day + i)));
  final c = _Collected(days, {});

  for (final t in all) {
    if (t.status != TrxStatus.berhasil) continue;
    final idx = dateOnly(t.time).difference(start).inDays;
    if (idx < 0 || idx > 6) continue;

    final d = days[idx];
    d.trx += 1;
    d.sales += t.amount;

    if (t.lines.isEmpty) {
      c.incomplete = true; // tidak ada rincian, modal tidak diketahui
      continue;
    }
    for (final l in t.lines) {
      if (l.cost == null) c.incomplete = true;
      d.cost += l.costTotal;
      c.itemsSold += l.qty;
      final item = c.top.putIfAbsent(l.name, () => TopItem(l.name));
      item.qty += l.qty;
      item.sales += l.subtotal;
      item.profit += l.subtotal - l.costTotal;
    }
  }
  return c;
}

WeekReport buildWeekReport(List<TrxItem> all, DateTime anyDayInWeek) {
  final start = weekStartOf(anyDayInWeek);
  final cur = _collect(all, start);
  final prev =
      _collect(all, DateTime(start.year, start.month, start.day - 7));

  final prevProfit = prev.days.fold<int>(0, (a, d) => a + d.profit);
  final hasPrev = prev.days.any((d) => d.trx > 0);

  final top = cur.top.values.toList()..sort((a, b) => b.qty.compareTo(a.qty));

  return WeekReport(
    start: start,
    days: cur.days,
    top: top.take(3).toList(),
    itemsSold: cur.itemsSold,
    incompleteCost: cur.incomplete,
    prevProfit: prevProfit,
    hasPrevData: hasPrev,
  );
}
