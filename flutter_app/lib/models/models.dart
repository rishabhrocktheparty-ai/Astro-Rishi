// ── User Model ────────────────────────────────────────────
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String preferredLanguage;
  final String preferredTradition;
  final String timezone;
  final bool isAdmin;

  UserProfile({
    required this.id, required this.email, required this.displayName,
    this.avatarUrl, this.preferredLanguage = 'en',
    this.preferredTradition = 'parashara', this.timezone = 'Asia/Kolkata',
    this.isAdmin = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'], email: json['email'] ?? '',
    displayName: json['display_name'] ?? json['email']?.split('@')[0] ?? '',
    avatarUrl: json['avatar_url'], preferredLanguage: json['preferred_language'] ?? 'en',
    preferredTradition: json['preferred_tradition'] ?? 'parashara',
    timezone: json['timezone'] ?? 'Asia/Kolkata', isAdmin: json['is_admin'] ?? false,
  );
}

// ── Birth Data Model ─────────────────────────────────────
class BirthData {
  String name;
  String dateOfBirth;   // YYYY-MM-DD
  String timeOfBirth;   // HH:MM:SS
  double latitude;
  double longitude;
  String timezone;
  String placeName;
  String country;
  String ayanamsa;

  BirthData({
    this.name = '', this.dateOfBirth = '', this.timeOfBirth = '',
    this.latitude = 0, this.longitude = 0, this.timezone = 'Asia/Kolkata',
    this.placeName = '', this.country = '', this.ayanamsa = 'lahiri',
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'date_of_birth': dateOfBirth, 'time_of_birth': timeOfBirth,
    'latitude': latitude, 'longitude': longitude, 'timezone': timezone,
    'place_name': placeName, 'country': country, 'ayanamsa': ayanamsa,
  };
}

// ── Planet Position Model ────────────────────────────────
class PlanetPosition {
  final String planet;
  final double longitude;
  final String rashi;
  final double rashiDegree;
  final String nakshatra;
  final int nakshatraPada;
  final String nakshatraLord;
  final int houseNumber;
  final String dignity;
  final bool isRetrograde;

  PlanetPosition({
    required this.planet, required this.longitude, required this.rashi,
    required this.rashiDegree, required this.nakshatra, required this.nakshatraPada,
    required this.nakshatraLord, required this.houseNumber,
    this.dignity = 'neutral', this.isRetrograde = false,
  });

  factory PlanetPosition.fromJson(Map<String, dynamic> json) => PlanetPosition(
    planet: json['planet'] ?? '', longitude: (json['longitude'] ?? 0).toDouble(),
    rashi: json['rashi'] ?? '', rashiDegree: (json['rashi_degree'] ?? 0).toDouble(),
    nakshatra: json['nakshatra'] ?? '', nakshatraPada: json['nakshatra_pada'] ?? 1,
    nakshatraLord: json['nakshatra_lord'] ?? '', houseNumber: json['house_number'] ?? 1,
    dignity: json['dignity'] ?? 'neutral', isRetrograde: json['is_retrograde'] ?? false,
  );

  String get degreeStr => '${rashiDegree.toStringAsFixed(1)}°';
  String get shortLabel => '${planet[0].toUpperCase()}${planet.substring(1, 3)}';
}

// ── House Cusp Model ─────────────────────────────────────
class HouseCusp {
  final int houseNumber;
  final double cuspLongitude;
  final String rashi;
  final String lord;

  HouseCusp({required this.houseNumber, required this.cuspLongitude, required this.rashi, required this.lord});

  factory HouseCusp.fromJson(Map<String, dynamic> json) => HouseCusp(
    houseNumber: json['house_number'], cuspLongitude: (json['cusp_longitude'] ?? 0).toDouble(),
    rashi: json['rashi'] ?? '', lord: json['lord'] ?? '',
  );
}

// ── Yoga Model ───────────────────────────────────────────
class Yoga {
  final String yogaName;
  final String yogaType;
  final List<String> formingPlanets;
  final List<int> formingHouses;
  final double strength;
  final String description;
  final String? sourceTradition;
  final String? sourceText;

  Yoga({
    required this.yogaName, required this.yogaType, required this.formingPlanets,
    this.formingHouses = const [], this.strength = 0.5, this.description = '',
    this.sourceTradition, this.sourceText,
  });

  factory Yoga.fromJson(Map<String, dynamic> json) => Yoga(
    yogaName: json['yoga_name'] ?? '', yogaType: json['yoga_type'] ?? 'other',
    formingPlanets: List<String>.from(json['forming_planets'] ?? []),
    formingHouses: List<int>.from(json['forming_houses'] ?? []),
    strength: (json['strength'] ?? 0.5).toDouble(),
    description: json['description'] ?? '',
    sourceTradition: json['source_tradition'], sourceText: json['source_text'],
  );
}

// ── Dasha Model ──────────────────────────────────────────
class DashaPeriod {
  final String planet;
  final String level;
  final String? parentPlanet;
  final String startDate;
  final String endDate;
  final double durationYears;

  DashaPeriod({
    required this.planet, required this.level, this.parentPlanet,
    required this.startDate, required this.endDate, required this.durationYears,
  });

  factory DashaPeriod.fromJson(Map<String, dynamic> json) => DashaPeriod(
    planet: json['planet'] ?? '', level: json['level'] ?? 'maha',
    parentPlanet: json['parent_planet'], startDate: json['start_date'] ?? '',
    endDate: json['end_date'] ?? '', durationYears: (json['duration_years'] ?? 0).toDouble(),
  );

  bool get isCurrent {
    final now = DateTime.now();
    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(endDate);
    if (start == null || end == null) return false;
    return now.isAfter(start) && now.isBefore(end);
  }
}

// ── Kundali Model ────────────────────────────────────────
class Kundali {
  final String id;
  final String? name;
  final String? dateOfBirth;
  final String? placeName;
  final String ascendantRashi;
  final String ascendantNakshatra;
  final int ascendantPada;
  final double ascendantLongitude;
  final Map<String, PlanetPosition> planets;
  final List<HouseCusp> houses;
  final List<Yoga> yogas;
  final List<DashaPeriod> dashas;
  final Map<String, dynamic> divisionalCharts;
  final String computedAt;

  Kundali({
    required this.id, this.name, this.dateOfBirth, this.placeName,
    required this.ascendantRashi, required this.ascendantNakshatra,
    this.ascendantPada = 1, this.ascendantLongitude = 0,
    required this.planets, required this.houses, required this.yogas,
    required this.dashas, this.divisionalCharts = const {}, this.computedAt = '',
  });

  factory Kundali.fromApiResponse(Map<String, dynamic> json) {
    final chart = json['chart'] ?? json;
    final ascendant = chart['ascendant'] ?? {};
    final planetMap = <String, PlanetPosition>{};
    final planetsData = chart['planets'] ?? {};
    planetsData.forEach((key, value) {
      planetMap[key] = PlanetPosition.fromJson(value is Map<String, dynamic> ? value : {});
    });

    return Kundali(
      id: json['kundali_id'] ?? json['id'] ?? '',
      name: json['birth_data']?['name'],
      dateOfBirth: json['birth_data']?['date_of_birth'],
      placeName: json['birth_data']?['place_name'],
      ascendantRashi: ascendant['rashi'] ?? '',
      ascendantNakshatra: ascendant['nakshatra'] ?? '',
      ascendantPada: ascendant['nakshatra_pada'] ?? 1,
      ascendantLongitude: (ascendant['longitude'] ?? 0).toDouble(),
      planets: planetMap,
      houses: (chart['houses'] as List? ?? []).map((h) => HouseCusp.fromJson(h)).toList(),
      yogas: (chart['yogas'] as List? ?? []).map((y) => Yoga.fromJson(y)).toList(),
      dashas: (chart['dashas'] as List? ?? []).map((d) => DashaPeriod.fromJson(d)).toList(),
      divisionalCharts: chart['divisional_charts'] ?? {},
      computedAt: json['computed_at'] ?? '',
    );
  }

  DashaPeriod? get currentMahaDasha =>
      dashas.where((d) => d.level == 'maha' && d.isCurrent).firstOrNull;

  DashaPeriod? get currentAntarDasha =>
      dashas.where((d) => d.level == 'antar' && d.isCurrent).firstOrNull;

  List<DashaPeriod> get mahaDashas => dashas.where((d) => d.level == 'maha').toList();
}

// ── AI Message Model ─────────────────────────────────────
class AIMessage {
  final String id;
  final String role;
  final String content;
  final List<dynamic> sources;
  final String? traditionUsed;
  final DateTime createdAt;

  AIMessage({
    required this.id, required this.role, required this.content,
    this.sources = const [], this.traditionUsed, DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AIMessage.fromJson(Map<String, dynamic> json) => AIMessage(
    id: json['id'] ?? json['message_id'] ?? '',
    role: json['role'] ?? 'assistant', content: json['content'] ?? json['message'] ?? '',
    sources: json['sources'] ?? [], traditionUsed: json['tradition_used'],
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

// ── Book Model ───────────────────────────────────────────
class Book {
  final String id;
  final String title;
  final String? originalTitle;
  final String? author;
  final String? language;
  final String processingStatus;
  final double processingProgress;
  final String? traditionName;
  final String createdAt;

  Book({
    required this.id, required this.title, this.originalTitle, this.author,
    this.language, this.processingStatus = 'pending', this.processingProgress = 0,
    this.traditionName, this.createdAt = '',
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'], title: json['title'] ?? '', originalTitle: json['original_title'],
    author: json['author'], language: json['language'],
    processingStatus: json['processing_status'] ?? 'pending',
    processingProgress: (json['processing_progress'] ?? 0).toDouble(),
    traditionName: json['traditions']?['name'], createdAt: json['created_at'] ?? '',
  );

  bool get isCompleted => processingStatus == 'completed';
  bool get isProcessing => processingStatus == 'processing' || processingStatus == 'extracting' || processingStatus == 'embedding';
}
