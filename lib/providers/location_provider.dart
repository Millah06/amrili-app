
import '../features/marketPlace/models/order_model.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class LocationProvider extends ChangeNotifier {
  final ApiService api;
  LocationProvider({required this.api});

  // Step 1 — state
  LocationState? selectedState;
  List<LocationState> states = [];

  // Step 2 — lga
  LocationLga? selectedLga;
  List<LocationLga> lgas = [];

  bool loadingLocation = false;

  String? error;
  OrderModel? placedOrder;

  Future<void> loadStates() async {
    loadingLocation = true;
    notifyListeners();
    try {
      final data = await api.get('/location/states') as List;
      states = data.map((s) => LocationState.fromJson(s)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loadingLocation = false;
      notifyListeners();
    }
  }

  Future<void> pickState(LocationState state) async {
    selectedState = state;
    selectedLga = null;

    lgas = [];

    notifyListeners();

    try {
      final data = await api.get('/location/lgas/${state.id}') as List;
      lgas = data.map((l) => LocationLga.fromJson(l)).toList();
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> pickLga(LocationLga lga) async {
    selectedLga = lga;


    notifyListeners();
    try {

    } catch (e) {
      error = e.toString();
    } finally {

      notifyListeners();
    }
  }

}