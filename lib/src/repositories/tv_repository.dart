import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tv_channel.dart';

class TvRepository {
  static const String _countriesMetadataUrl =
      'https://raw.githubusercontent.com/TVGarden/tv-garden-channel-list/refs/heads/main/channels/raw/countries_metadata.json';

  /// Fetch all countries metadata
  Future<Map<String, dynamic>> getCountriesMetadata() async {
    try {
      final response = await http.get(Uri.parse(_countriesMetadataUrl));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load countries metadata: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching countries metadata: $e');
    }
  }

  /// Fetch channels for a specific country
  Future<List<TvChannel>> getChannelsByCountry(String countryCode) async {
    try {
      final url =
          'https://raw.githubusercontent.com/TVGarden/tv-garden-channel-list/refs/heads/main/channels/raw/countries/${countryCode.toLowerCase()}.json';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => TvChannel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Failed to load channels for country $countryCode: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching channels for country $countryCode: $e');
    }
  }
}
