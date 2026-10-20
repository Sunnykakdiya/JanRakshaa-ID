import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/hospital_model.dart';
import '../models/user_model.dart';
import '../services/hospital_service.dart';

class HospitalProvider extends ChangeNotifier {
  Position? _currentPosition;
  String _selectedType = HospitalService.emergencyTypes.first;
  bool _isLocating = false;
  bool _isSearching = false;
  HospitalFinderResult? _result;
  String? _error;

  Position? get currentPosition => _currentPosition;
  String get selectedType => _selectedType;
  bool get isLocating => _isLocating;
  bool get isSearching => _isSearching;
  HospitalFinderResult? get result => _result;
  String? get error => _error;

  void setEmergencyType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    _isLocating = true;
    _error = null;
    notifyListeners();

    try {
      _currentPosition = await HospitalService.getCurrentLocation();
      if (_currentPosition == null) {
        _error = 'Location permission denied or GPS is turned off.';
      }
    } catch (_) {
      _error = 'Could not fetch GPS coordinates.';
    }

    _isLocating = false;
    notifyListeners();
  }

  Future<void> findHospitals({UserModel? user}) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _currentPosition ??= await HospitalService.getCurrentLocation();
      _result = await HospitalService.findEmergencyFacilities(
        position: _currentPosition,
        emergencyType: _selectedType,
        user: user,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isSearching = false;
    notifyListeners();
  }
}