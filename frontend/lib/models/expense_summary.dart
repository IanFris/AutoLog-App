class ExpenseCategory {
  final String name;
  final String icon;
  final double cost;
  final int count;
  final double percentage;

  ExpenseCategory({
    required this.name,
    required this.icon,
    required this.cost,
    required this.count,
    required this.percentage,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'build',
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MonthlyExpenseTrend {
  final String monthKey;
  final String monthLabel;
  final double totalCost;

  MonthlyExpenseTrend({
    required this.monthKey,
    required this.monthLabel,
    required this.totalCost,
  });

  factory MonthlyExpenseTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyExpenseTrend(
      monthKey: json['month_key'] as String? ?? '',
      monthLabel: json['month_label'] as String? ?? '',
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseSummary {
  final double totalAllTime;
  final double totalThisMonth;
  final double totalThisYear;
  final int serviceCount;
  final double costPerKm;
  final List<ExpenseCategory> categoryBreakdown;
  final List<MonthlyExpenseTrend> monthlyTrends;

  ExpenseSummary({
    required this.totalAllTime,
    required this.totalThisMonth,
    required this.totalThisYear,
    required this.serviceCount,
    required this.costPerKm,
    required this.categoryBreakdown,
    required this.monthlyTrends,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    final catList = (json['category_breakdown'] as List<dynamic>?)
            ?.map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final trendList = (json['monthly_trends'] as List<dynamic>?)
            ?.map((e) => MonthlyExpenseTrend.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ExpenseSummary(
      totalAllTime: (json['total_all_time'] as num?)?.toDouble() ?? 0.0,
      totalThisMonth: (json['total_this_month'] as num?)?.toDouble() ?? 0.0,
      totalThisYear: (json['total_this_year'] as num?)?.toDouble() ?? 0.0,
      serviceCount: (json['service_count'] as num?)?.toInt() ?? 0,
      costPerKm: (json['cost_per_km'] as num?)?.toDouble() ?? 0.0,
      categoryBreakdown: catList,
      monthlyTrends: trendList,
    );
  }
}
