import 'package:flutter/foundation.dart';
import '../models/statistics_model.dart';
import '../services/statistics_service.dart';

class StatisticsProvider extends ChangeNotifier {
  final StatisticsService _service = StatisticsService();

  SalesSummaryModel? _summary;
  List<BestSellerItem> _bestSellers = [];
  List<PeakHourItem> _peakHours = [];
  bool _isLoading = false;
  String? _errorMessage;

  SalesSummaryModel? get summary => _summary;
  List<BestSellerItem> get bestSellers => _bestSellers;
  List<PeakHourItem> get peakHours => _peakHours;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Jam dengan transaksi terbanyak, ditampilkan sebagai highlight
  PeakHourItem? get busiestHour {
    if (_peakHours.isEmpty) return null;
    return _peakHours.reduce((a, b) => a.count >= b.count ? a : b);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadSummary(String sellerId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _summary = await _service.getSummary(sellerId);
    } catch (e) {
      _errorMessage = 'Gagal memuat statistik: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadBestSellers(String sellerId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _bestSellers = await _service.getBestSellers(sellerId);
    } catch (e) {
      _errorMessage = 'Gagal memuat menu terlaris: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPeakHours(String sellerId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _peakHours = await _service.getPeakHours(sellerId);
    } catch (e) {
      _errorMessage = 'Gagal memuat analisis jam ramai: $e';
    } finally {
      _setLoading(false);
    }
  }
}
