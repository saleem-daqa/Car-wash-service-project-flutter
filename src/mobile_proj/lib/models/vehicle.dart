class Vehicle {
  final String type;
  final String brand;
  final String model;
  final String plate;
  final int? carId;

  Vehicle({
    required this.type,
    required this.brand,
    required this.model,
    required this.plate,
    this.carId,
  });

  static bool isValidModel(String model) {
    return RegExp(r'^\d+$').hasMatch(model.trim());
  }

  static bool isValidPlate(String plate) {
    return plate.trim().length >= 3 && plate.trim().length <= 15;
  }

  static bool isValidBrand(String brand) {
    return brand.trim().length >= 2 && brand.trim().length <= 50;
  }
}
