/// A daily water-saving challenge. The text lives in lib/l10n under
/// the key `challenge<id>` (English + Tamil).
class Challenge {
  const Challenge(this.id, this.litres);

  final int id;

  /// Estimated litres saved by doing it once.
  final double litres;

  String get textKey => 'challenge$id';
}

/// All 30 challenges, one per day (rotated by day of year).
const List<Challenge> allChallenges = [
  Challenge(1, 6), // Turn off the tap while brushing
  Challenge(2, 150), // Bucket instead of hose for bike
  Challenge(3, 10), // Reuse RO reject water for mopping
  Challenge(4, 30), // 5-minute shower
  Challenge(5, 20), // Full loads in washing machine
  Challenge(6, 10), // Wash vegetables in a bowl
  Challenge(7, 5), // Reuse vegetable-wash water for plants
  Challenge(8, 15), // Check toilet for leaks
  Challenge(9, 2), // Drink water you take, don't waste glass
  Challenge(10, 10), // Close the tap while soaping hands/dishes
  Challenge(11, 20), // Water plants early morning / evening
  Challenge(12, 20), // Bucket bath instead of shower
  Challenge(13, 6), // Put a bottle in the flush tank
  Challenge(14, 20), // Sweep the floor/yard instead of washing
  Challenge(15, 10), // Fix or report one dripping tap
  Challenge(16, 15), // Soak dishes before washing
  Challenge(17, 5), // Collect AC water for plants
  Challenge(18, 10), // Use half flush
  Challenge(19, 8), // Defrost food in fridge, not under running water
  Challenge(20, 10), // Reuse cooking water (rice/dal) for plants
  Challenge(21, 100), // Wash the car with a bucket
  Challenge(22, 30), // Check overhead tank overflow pipe
  Challenge(23, 5), // Turn off tap while shaving
  Challenge(24, 10), // Mulch plant pots to keep soil moist
  Challenge(25, 50), // Collect rainwater
  Challenge(26, 20), // Run the dishwasher/washer only when full
  Challenge(27, 10), // Teach a family member one water tip
  Challenge(28, 15), // Rinse clothes in a bucket
  Challenge(29, 20), // Reuse washing machine rinse water for floor
  Challenge(30, 40), // Use Motor Guard every time
];
