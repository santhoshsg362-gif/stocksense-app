import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_metrics.dart';

class MetricsProvider extends ChangeNotifier {

  // Store metrics per stock symbol
  // key = symbol, value = list of metrics
  Map<String, List<FundamentalMetric>>
    _fundamentalMetrics = {};
  Map<String, List<TechnicalMetric>>
    _technicalMetrics = {};

  List<FundamentalMetric> getFundamentals(
      String symbol) {
    return _fundamentalMetrics[symbol] ?? [];
  }

  List<TechnicalMetric> getTechnicals(
      String symbol) {
    return _technicalMetrics[symbol] ?? [];
  }

  void addFundamentalMetric(
      String symbol, FundamentalMetric metric) {
    if (!_fundamentalMetrics
        .containsKey(symbol)) {
      _fundamentalMetrics[symbol] = [];
    }
    _fundamentalMetrics[symbol]!.add(metric);
    _save();
    notifyListeners();
  }

  void updateFundamentalMetric(
      String symbol, int index,
      FundamentalMetric metric) {
    if (_fundamentalMetrics
        .containsKey(symbol)) {
      _fundamentalMetrics[symbol]![index] =
        metric;
      _save();
      notifyListeners();
    }
  }

  void removeFundamentalMetric(
      String symbol, int index) {
    if (_fundamentalMetrics
        .containsKey(symbol)) {
      _fundamentalMetrics[symbol]!
        .removeAt(index);
      _save();
      notifyListeners();
    }
  }

  void addTechnicalMetric(
      String symbol, TechnicalMetric metric) {
    if (!_technicalMetrics
        .containsKey(symbol)) {
      _technicalMetrics[symbol] = [];
    }
    _technicalMetrics[symbol]!.add(metric);
    _save();
    notifyListeners();
  }

  void updateTechnicalMetric(
      String symbol, int index,
      TechnicalMetric metric) {
    if (_technicalMetrics
        .containsKey(symbol)) {
      _technicalMetrics[symbol]![index] =
        metric;
      _save();
      notifyListeners();
    }
  }

  void removeTechnicalMetric(
      String symbol, int index) {
    if (_technicalMetrics
        .containsKey(symbol)) {
      _technicalMetrics[symbol]!
        .removeAt(index);
      _save();
      notifyListeners();
    }
  }

  // Total metric count for a stock
  int totalMetrics(String symbol) {
    return getFundamentals(symbol).length +
      getTechnicals(symbol).length;
  }

  // Save to SharedPreferences
  Future<void> _save() async {
    final prefs =
      await SharedPreferences.getInstance();

    // Save fundamentals
    final fundMap = <String, dynamic>{};
    _fundamentalMetrics.forEach((symbol, list) {
      fundMap[symbol] = list
        .map((m) => m.toJson())
        .toList();
    });
    await prefs.setString(
      'fundamental_metrics',
      jsonEncode(fundMap));

    // Save technicals
    final techMap = <String, dynamic>{};
    _technicalMetrics.forEach((symbol, list) {
      techMap[symbol] = list
        .map((m) => m.toJson())
        .toList();
    });
    await prefs.setString(
      'technical_metrics',
      jsonEncode(techMap));
  }

  // Load from SharedPreferences
  Future<void> load() async {
    final prefs =
      await SharedPreferences.getInstance();

    // Load fundamentals
    final fundStr = prefs.getString(
      'fundamental_metrics');
    if (fundStr != null) {
      final fundMap = jsonDecode(fundStr)
        as Map<String, dynamic>;
      fundMap.forEach((symbol, list) {
        _fundamentalMetrics[symbol] =
          (list as List).map((item) =>
            FundamentalMetric(
              name: item['name'],
              value: item['value'],
              description: item['description'],
            )
          ).toList();
      });
    }

    // Load technicals
    final techStr = prefs.getString(
      'technical_metrics');
    if (techStr != null) {
      final techMap = jsonDecode(techStr)
        as Map<String, dynamic>;
      techMap.forEach((symbol, list) {
        _technicalMetrics[symbol] =
          (list as List).map((item) =>
            TechnicalMetric(
              name: item['name'],
              value: item['value'],
              signal: item['signal'],
            )
          ).toList();
      });
    }

    notifyListeners();
  }
}