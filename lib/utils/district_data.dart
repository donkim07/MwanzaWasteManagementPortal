// lib/utils/district_data.dart

// Models for type safety
class Ward {
  final String name;
  final int population;

  const Ward({
    required this.name,
    required this.population,
  });
}

class District {
  final String name;
  final List<Ward> wards;

  const District({
    required this.name, 
    required this.wards,
  });
}

// District data
class DistrictData {
  static const Map<String, List<Ward>> _districtWards = {
    'Ilemela': [
      Ward(name: 'Bugogwa', population: 35633),
      Ward(name: 'Buswelu', population: 42614),
      Ward(name: 'Buzuruga', population: 25338),
      Ward(name: 'Ibungilo', population: 24295),
      Ward(name: 'Ilemela', population: 26091),
      Ward(name: 'Kahama', population: 21816),
      Ward(name: 'Kawekamo', population: 26670),
      Ward(name: 'Kayenze', population: 17201),
      Ward(name: 'Kirumba', population: 32364),
      Ward(name: 'Kiseke', population: 30664),
      Ward(name: 'Kitangiri', population: 23642),
      Ward(name: 'Mecco', population: 23294),
      Ward(name: 'Nyakato', population: 29560),
      Ward(name: 'Nyamanoro', population: 24624),
      Ward(name: 'Nyamhongolo', population: 29277),
      Ward(name: 'Nyasaka', population: 41897),
      Ward(name: 'Pasiansi', population: 16274),
      Ward(name: 'Sangabuye', population: 13004),
      Ward(name: 'Shibula', population: 25429),
    ],
    'Nyamagana': [
      Ward(name: 'Buhongwa', population: 67254),
      Ward(name: 'Butimba', population: 36069),
      Ward(name: 'Igogo', population: 25515),
      Ward(name: 'Igoma', population: 57263),
      Ward(name: 'Isamilo', population: 27881),
      Ward(name: 'Kishili', population: 63054),
      Ward(name: 'Luchelele', population: 18889),
      Ward(name: 'Lwanhima', population: 28109),
      Ward(name: 'Mabatini', population: 24458),
      Ward(name: 'Mahina', population: 57260),
      Ward(name: 'Mbugani', population: 18395),
      Ward(name: 'Mhandu', population: 43440),
      Ward(name: 'Mikuyuni', population: 20492),
      Ward(name: 'Mirongo', population: 2141),
      Ward(name: 'Mkolani', population: 48102),
      Ward(name: 'Nyamagana', population: 5033),
      Ward(name: 'Nyegezi', population: 28454),
      Ward(name: 'Pamba', population: 23025),
    ],
  };

  // Get list of all districts
  static List<String> getDistricts() {
    return _districtWards.keys.toList();
  }

  // Get list of wards for a specific district
  static List<String> getWardsForDistrict(String district) {
    return _districtWards[district]?.map((ward) => ward.name).toList() ?? [];
  }

  // Get population for a specific ward in a district
  static int? getWardPopulation(String district, String wardName) {
    final ward = _districtWards[district]?.firstWhere(
      (ward) => ward.name == wardName,
      orElse: () => Ward(name: '', population: 0),
    );
    return ward?.population;
  }

  // Get ward details including population
  static Ward? getWardDetails(String district, String wardName) {
    return _districtWards[district]?.firstWhere(
      (ward) => ward.name == wardName,
      orElse: () => Ward(name: '', population: 0),
    );
  }

  // Get total population for a district
  static int getDistrictPopulation(String district) {
    return _districtWards[district]?.fold(
      0,
      (sum, ward) => sum! + ward.population,
    ) ?? 0;
  }

  // Search for wards by name across all districts
  static List<Ward> searchWards(String query) {
    final results = <Ward>[];
    for (final district in _districtWards.values) {
      results.addAll(
        district.where(
          (ward) => ward.name.toLowerCase().contains(query.toLowerCase()),
        ),
      );
    }
    return results;
  }

  // Check if a district exists
  static bool districtExists(String district) {
    return _districtWards.containsKey(district);
  }

  // Check if a ward exists in a district
  static bool wardExistsInDistrict(String district, String wardName) {
    return _districtWards[district]?.any(
      (ward) => ward.name == wardName,
    ) ?? false;
  }
}