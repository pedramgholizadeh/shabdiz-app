import 'package:flutter/material.dart';
import '../models/tv_channel.dart';
import '../repositories/tv_repository.dart';

class TvProvider with ChangeNotifier {
  final TvRepository _repository = TvRepository();

  // Countries data
  Map<String, dynamic> _countriesMetadata = {};
  bool _isLoadingCountries = false;
  String? _countriesErrorMessage;

  // Channels data
  List<TvChannel> _channels = [];
  bool _isLoadingChannels = false;
  String? _channelsErrorMessage;

  // Getters for countries
  Map<String, dynamic> get countriesMetadata => _countriesMetadata;
  bool get isLoadingCountries => _isLoadingCountries;
  String? get countriesErrorMessage => _countriesErrorMessage;

  // Getters for channels
  List<TvChannel> get channels => _channels;
  bool get isLoadingChannels => _isLoadingChannels;
  String? get channelsErrorMessage => _channelsErrorMessage;

  /// Load countries metadata
  Future<void> loadCountriesMetadata() async {
    if (_isLoadingCountries) return;

    _isLoadingCountries = true;
    _countriesErrorMessage = null;
    notifyListeners();

    try {
      _countriesMetadata = await _repository.getCountriesMetadata();
    } catch (e) {
      _countriesErrorMessage = e.toString();
      _countriesMetadata = {};
    } finally {
      _isLoadingCountries = false;
      notifyListeners();
    }
  }

  /// Load channels for a specific country
  Future<void> loadChannelsByCountry(String countryCode) async {
    if (_isLoadingChannels) return;

    _isLoadingChannels = true;
    _channelsErrorMessage = null;
    _channels = [];
    notifyListeners();

    try {
      _channels = await _repository.getChannelsByCountry(countryCode);
    } catch (e) {
      _channelsErrorMessage = e.toString();
      _channels = [];
    } finally {
      _isLoadingChannels = false;
      notifyListeners();
    }
  }
}
