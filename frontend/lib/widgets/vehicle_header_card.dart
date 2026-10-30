import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/currency_formatter.dart';
import 'update_odometer_dialog.dart';

class VehicleHeaderCard extends StatelessWidget {
  final Vehicle? vehicle;
  final List<Vehicle> allVehicles;
  final Function(Vehicle) onVehicleChanged;
  final Function(int newOdometer) onOdometerUpdated;
  final VoidCallback onAddVehicle;

  const VehicleHeaderCard({
    super.key,
    required this.vehicle,
    required this.allVehicles,
    required this.onVehicleChanged,
    required this.onOdometerUpdated,
    required this.onAddVehicle,
  });

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F766E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.no_crash, size: 48, color: Colors.white70),
            const SizedBox(height: 12),
            const Text(
              'Belum Ada Kendaraan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tambahkan motor atau mobil Anda untuk memantau status pemeliharaan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F766E),
              ),
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kendaraan'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E), // Teal 700
            Color(0xFF134E4A), // Teal 900
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Switcher & Plate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PopupMenuButton<dynamic>(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (val) {
                  if (val == '__add__') {
                    onAddVehicle();
                  } else if (val is Vehicle) {
                    onVehicleChanged(val);
                  }
                },
                itemBuilder: (ctx) => [
                  ...allVehicles.map(
                    (v) => PopupMenuItem<Vehicle>(
                      value: v,
                      child: Row(
                        children: [
                          Icon(
                            v.type.icon,
                            size: 18,
                            color: v.id == vehicle!.id
                                ? const Color(0xFF0D9488)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              v.brandModel,
                              style: TextStyle(
                                fontWeight: v.id == vehicle!.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: v.id == vehicle!.id
                                    ? const Color(0xFF0D9488)
                                    : null,
                              ),
                            ),
                          ),
                          if (v.id == vehicle!.id)
                            const Icon(Icons.check,
                                size: 16, color: Color(0xFF0D9488)),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: '__add__',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 18, color: Color(0xFF0D9488)),
                        SizedBox(width: 10),
                        Text(
                          'Tambah Kendaraan Baru',
                          style: TextStyle(
                            color: Color(0xFF0D9488),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(vehicle!.type.icon, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        vehicle!.type.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down,
                          size: 18, color: Colors.white70),
                    ],
                  ),
                ),
              ),

              // License Plate Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30, width: 1),
                ),
                child: Text(
                  vehicle!.licensePlate.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Vehicle Name
          Text(
            vehicle!.brandModel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 14),

          // Odometer Row & Update KM button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL ODOMETER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        CurrencyFormatter.formatNumber(
                            vehicle!.currentOdometer),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'KM',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  UpdateOdometerDialog.show(
                    context,
                    vehicleName: vehicle!.brandModel,
                    currentOdometer: vehicle!.currentOdometer,
                    onSaved: onOdometerUpdated,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Update KM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

