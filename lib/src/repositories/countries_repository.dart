import 'dart:convert';
import '../models/country.dart';
import '../models/poster.dart';
import '../models/media_item.dart';
import 'base_repository.dart';

class CountriesRepository extends BaseRepository {
  static const String _countriesEndpoint = '/countries';
  static const String _postersEndpoint = '/posters';
  
  /// Fetch all countries from the API
  Future<List<CountryModel>> getCountries() async {
    try {
      final url = '$_countriesEndpoint';
      final jsonData = await executeRequest(url);
      return parseCountries(jsonData);
    } catch (e) {
      throw Exception('Error fetching countries: $e');
    }
  }
  
  List<CountryModel> parseCountries(String jsonData) {
    final countries = <CountryModel>[];
    final jsonArray = json.decode(jsonData) as List;
    
    for (var item in jsonArray) {
      try {
        final countryObj = item as Map<String, dynamic>;
        final country = CountryModel.fromJson(countryObj);
        countries.add(country);
      } catch (e) {
        continue;
      }
    }
    
    return countries;
  }
  
  /// Fetch posters by country ID
  Future<List<Poster>> getPostersByCountry(int countryId, {int page = 0, FilterType filterType = FilterType.defaultFilter}) async {
    try {
      final url = '$_postersEndpoint?country=$countryId&filter=${filterType.apiValue}&page=$page';
      final jsonData = await executeRequest(url);
      return parsePosters(jsonData);
    } catch (e) {
      throw Exception('Error fetching posters for country $countryId: $e');
    }
  }
  
  List<Poster> parsePosters(String jsonData) {
    final posters = <Poster>[];
    final jsonArray = json.decode(jsonData) as List;
    
    for (var item in jsonArray) {
      try {
        final posterObj = item as Map<String, dynamic>;
        final poster = Poster.fromJson(posterObj);
        posters.add(poster);
      } catch (e) {
        continue;
      }
    }
    
    return posters;
  }
}