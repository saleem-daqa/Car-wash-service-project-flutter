class WashService {
  final String name;
  final String description;
  final double priceCar;
  final double priceBus;
  final double priceMotorcycle;

  WashService({
    required this.name,
    required this.description,
    required this.priceCar,
    required this.priceBus,
    required this.priceMotorcycle,
  });

  double getPrice(String vehicleType) {
    switch (vehicleType) {
      case 'Car/Sedan':
        return priceCar;
      case 'Bus/Truck':
        return priceBus;
      case 'Motorcycle/Scooter':
        return priceMotorcycle;
      default:
        return priceCar;
    }
  }
}
