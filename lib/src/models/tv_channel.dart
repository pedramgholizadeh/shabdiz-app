class TvChannel {
  final String nanoid;
  final String name;
  final List<String> iptvUrls;
  final List<String> youtubeUrls;
  final String language;
  final String country;
  final bool isGeoBlocked;

  TvChannel({
    required this.nanoid,
    required this.name,
    required this.iptvUrls,
    required this.youtubeUrls,
    required this.language,
    required this.country,
    required this.isGeoBlocked,
  });

  factory TvChannel.fromJson(Map<String, dynamic> json) {
    return TvChannel(
      nanoid: json['nanoid'] as String,
      name: json['name'] as String,
      iptvUrls: List<String>.from(json['iptv_urls'] ?? []),
      youtubeUrls: List<String>.from(json['youtube_urls'] ?? []),
      language: json['language'] as String,
      country: json['country'] as String,
      isGeoBlocked: json['isGeoBlocked'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nanoid': nanoid,
      'name': name,
      'iptv_urls': iptvUrls,
      'youtube_urls': youtubeUrls,
      'language': language,
      'country': country,
      'isGeoBlocked': isGeoBlocked,
    };
  }

  bool get hasIptv => iptvUrls.isNotEmpty;
  bool get hasYoutube => youtubeUrls.isNotEmpty;
  bool get hasBoth => hasIptv && hasYoutube;
}
