import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/fuel_record.dart';
import '../models/service_reminder.dart';

class MockData {
  static List<Vehicle> get vehicles => [
        Vehicle(
          id: 'v_vario160',
          name: 'Honda Vario 160 ABS',
          type: VehicleType.motorcycle,
          brand: 'Honda',
          model: 'Vario 160 ABS 2023',
          year: 2023,
          licensePlate: 'B 4589 SKM',
          currentOdometer: 14850,
          fuelType: 'Pertamax',
          color: 'Hitam Matte',
          notes: 'Motor harian kantor & operasional dalam kota.',
          createdAt: DateTime.now().subtract(const Duration(days: 360)),
        ),
        Vehicle(
          id: 'v_avanza',
          name: 'Toyota Avanza 1.5 G CVT',
          type: VehicleType.car,
          brand: 'Toyota',
          model: 'Avanza 1.5 G CVT',
          year: 2022,
          licensePlate: 'B 1842 KFL',
          currentOdometer: 42600,
          fuelType: 'Pertamax',
          color: 'Putih Mutiara',
          notes: 'Mobil keluarga untuk akhir pekan dan mudik.',
          createdAt: DateTime.now().subtract(const Duration(days: 500)),
        ),
      ];

  static List<MaintenanceRecord> get maintenanceRecords => [
        // Vario records
        MaintenanceRecord(
          id: 'mr_1',
          vehicleId: 'v_vario160',
          date: DateTime.now().subtract(const Duration(days: 65)),
          odometer: 12000,
          title: 'Ganti Oli Mesin SPX2 & Oli Gardan',
          categoryKey: 'oli_mesin',
          workshopName: 'AHASS 0712 Cawang',
          cost: 115000,
          notes: 'Ganti oli mesin AHM SPX 2 0.8L dan oli transmisi matic.',
          partsReplaced: ['Oli SPX 2 0.8L', 'Oli Transmisi Gardan AHM 120ml'],
          nextServiceOdometer: 15000,
          nextServiceDate: DateTime.now().add(const Duration(days: 15)),
        ),
        MaintenanceRecord(
          id: 'mr_2',
          vehicleId: 'v_vario160',
          date: DateTime.now().subtract(const Duration(days: 140)),
          odometer: 10000,
          title: 'Servis Berkala 10.000 KM & Ganti Busi',
          categoryKey: 'servis_rutin',
          workshopName: 'AHASS 0712 Cawang',
          cost: 185000,
          notes: 'Tune up injeksi, stel klep, ganti busi NGK, dan filter udara baru.',
          partsReplaced: ['Busi CPR9EA-9', 'Filter Udara Vario 160'],
          nextServiceOdometer: 14000,
        ),
        MaintenanceRecord(
          id: 'mr_3',
          vehicleId: 'v_vario160',
          date: DateTime.now().subtract(const Duration(days: 18)),
          odometer: 14200,
          title: 'Ganti Kampas Rem & Ban Belakang Maxxis',
          categoryKey: 'ban',
          workshopName: 'Planet Ban Kalimalang',
          cost: 395000,
          notes: 'Kampas rem depan orisinil + ban belakang Maxxis Victra 120/70-14 tubeless + isi nitrogen.',
          partsReplaced: ['Ban Maxxis Victra 120/70-14', 'Kampas Rem Depan Nissin'],
        ),

        // Avanza records
        MaintenanceRecord(
          id: 'mr_4',
          vehicleId: 'v_avanza',
          date: DateTime.now().subtract(const Duration(days: 80)),
          odometer: 40050,
          title: 'Servis Berkala 40.000 KM Mayor',
          categoryKey: 'servis_rutin',
          workshopName: 'Auto2000 Tebet Supomo',
          cost: 1450000,
          notes: 'Servis besar: ganti oli TMO 10W-40 4 liter, filter oli, filter kabin AC, busi 4 pcs, kuras minyak rem.',
          partsReplaced: [
            'Oli TMO 10W-40 4L',
            'Filter Oli Toyota',
            'Busi Denso Iridium (4 pcs)',
            'Filter Kabin AC'
          ],
          nextServiceOdometer: 45000,
          nextServiceDate: DateTime.now().add(const Duration(days: 45)),
        ),
        MaintenanceRecord(
          id: 'mr_5',
          vehicleId: 'v_avanza',
          date: DateTime.now().subtract(const Duration(days: 30)),
          odometer: 41500,
          title: 'Spooring, Balancing 4 Roda & Rotasi Ban',
          categoryKey: 'ban',
          workshopName: 'Nawilis Ban Radio Dalam',
          cost: 290000,
          notes: 'Koreksi chamber depan, balancing 4 roda, dan cek tekanan angin nitrogen.',
          partsReplaced: ['Pentil Karet Tubeless (4 pcs)'],
        ),
      ];

  static List<FuelRecord> get fuelRecords => [
        FuelRecord(
          id: 'fr_1',
          vehicleId: 'v_vario160',
          date: DateTime.now().subtract(const Duration(days: 4)),
          odometer: 14850,
          liters: 4.2,
          pricePerLiter: 12950,
          totalCost: 54390,
          fuelType: 'Pertamax',
          gasStation: 'SPBU Pertamina 34-13402 Cipinang',
          isFullTank: true,
        ),
        FuelRecord(
          id: 'fr_2',
          vehicleId: 'v_vario160',
          date: DateTime.now().subtract(const Duration(days: 10)),
          odometer: 14660,
          liters: 4.1,
          pricePerLiter: 12950,
          totalCost: 53095,
          fuelType: 'Pertamax',
          gasStation: 'SPBU Pertamina 34-12101 Tebet',
          isFullTank: true,
        ),
        FuelRecord(
          id: 'fr_3',
          vehicleId: 'v_avanza',
          date: DateTime.now().subtract(const Duration(days: 7)),
          odometer: 42600,
          liters: 35.0,
          pricePerLiter: 12950,
          totalCost: 453250,
          fuelType: 'Pertamax',
          gasStation: 'SPBU Pertamina Rest Area KM 19',
          isFullTank: true,
        ),
      ];

  static List<ServiceReminder> get serviceReminders => [
        ServiceReminder(
          id: 'rem_1',
          vehicleId: 'v_vario160',
          title: 'Ganti Oli Mesin Rutin (15.000 KM)',
          categoryKey: 'oli_mesin',
          targetOdometer: 15000, // Current: 14850 -> Sisa 150 KM (Mendekati!)
          targetDate: DateTime.now().add(const Duration(days: 5)),
          lastServiceOdometer: 12000,
          lastServiceDate: DateTime.now().subtract(const Duration(days: 65)),
          notes: 'Gunakan oli mesin AHM SPX 2 0.8 liter full sintetis.',
        ),
        ServiceReminder(
          id: 'rem_2',
          vehicleId: 'v_vario160',
          title: 'Servis CVT Belt & Roller (16.000 KM)',
          categoryKey: 'cvt_rantai',
          targetOdometer: 16000, // Sisa 1150 KM (Aman)
          targetDate: DateTime.now().add(const Duration(days: 45)),
          lastServiceOdometer: 10000,
          notes: 'Cek ketebalan v-belt, roller, dan bersihkan pulley CVT.',
        ),
        ServiceReminder(
          id: 'rem_3',
          vehicleId: 'v_vario160',
          title: 'Pajak Tahunan STNK (PKB)',
          categoryKey: 'pajak_stnk',
          targetDate: DateTime.now().add(const Duration(days: 55)),
          notes: 'Bayar via aplikasi Signal atau Samsat Keliling.',
        ),
        ServiceReminder(
          id: 'rem_4',
          vehicleId: 'v_avanza',
          title: 'Ganti Oli Mesin 45.000 KM',
          categoryKey: 'oli_mesin',
          targetOdometer: 45000,
          targetDate: DateTime.now().add(const Duration(days: 60)),
          lastServiceOdometer: 40050,
          notes: 'Gunakan TMO Synthetic 10W-40 atau 5W-30.',
        ),
        ServiceReminder(
          id: 'rem_5',
          vehicleId: 'v_avanza',
          title: 'Kuras Minyak Rem & Radiator (50.000 KM)',
          categoryKey: 'radiator',
          targetOdometer: 50000,
          targetDate: DateTime.now().add(const Duration(days: 150)),
          notes: 'Kuras coolant radiator Toyota Super Long Life Coolant.',
        ),
      ];
}

