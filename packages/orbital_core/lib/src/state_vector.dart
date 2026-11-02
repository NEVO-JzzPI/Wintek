/// Cartesian vector: components x, y and z along the axes of one frame.
final class CartesianVector {
  const CartesianVector(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

/// State vector: position in km and velocity in km/s, in the same frame.
final class StateVector {
  const StateVector({required this.positionKm, required this.velocityKmS});

  final CartesianVector positionKm;
  final CartesianVector velocityKmS;
}
