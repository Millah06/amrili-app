import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';
import '../../../services/dio_client.dart';
import '../../../services/vendorService/vendor_repository.dart';
import '../../social/services/social_api_service.dart';
import '../models/order_model.dart';
import '../models/vendor_model.dart';

// ─── VENDOR CENTER PROVIDER ───────────────────────────────────────────────────

class VendorCenterProvider extends ChangeNotifier {
  final ApiService api;
  VendorCenterProvider({required this.api});

  VendorModel? myVendor;
  VendorMetrics? metrics;
  List<MenuItemModel> menuItems = [];
  bool loading = false;
  String? error;

  bool get isApprovedVendor => myVendor?.status == 'approved';

  bool get isPending => myVendor?.status == 'pending';
  bool get isRejected => myVendor?.status == 'rejected';
  String? get rejectionMessage => myVendor?.rejectionMessage;

  bool get vendorIsVisible => myVendor!.isVisible;
  bool get vendorAllowsPod => myVendor!.vendorAllowsPod;
  bool updatingProductItem = false;

  Future<void> init() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await api.get('/vendor/me');
      print('❤️$data');
      myVendor = VendorModel.fromJson(data);
      if (isApprovedVendor) {
        final m = await api.get('/vendor/metrics');
        metrics = VendorMetrics.fromJson(m);
        if (myVendor!.branches.isNotEmpty) {
          await loadMenuForBranch();
        }
      }
    } catch (_) {
      myVendor = null; // not a vendor
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? advancedMetrics;

  Future<void> loadAdvancedMetrics() async {
    try {
      final data = await api.get('/vendor/metrics/advanced?vendorId=${myVendor!.id}');
      advancedMetrics = data;
      notifyListeners();
    } catch (_) {} // silently fail for non-main branch managers
  }

  Future<void> loadMenuForBranch() async {
    try {
      final data = await api.get('/menu/manager/branches') as List;
      menuItems = data.map((m) => MenuItemModel.fromJson(m)).toList();
      notifyListeners();
    } catch (e) { error = e.toString(); notifyListeners(); }
  }

  Future<bool> addMenuItem(String branchId, Map<String, dynamic> item) async {
    try {
      final data = await api.post('/menu/$branchId/add', item);
      menuItems.add(MenuItemModel.fromJson(data));
      notifyListeners();
      return true;
    } catch (e) { error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> appealOrder(String orderId, String reason) async {
    try {
      final data = await api.post('/order/$orderId/appeal', {'reason': reason});
      // _replace(OrderModel.fromJson(data));
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Vendor cancels their own appeal (or buyer cancels theirs from vendor context).
  Future<bool> cancelAppeal(String orderId) async {
    try {
      await api.post('/order/$orderId/cancel-appeal', {});
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Vendor concedes a buyer's appeal — funds go back to buyer.
  Future<bool> concedeAppeal(String orderId) async {
    try {
      await api.post('/order/$orderId/concede-appeal', {});
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Advances order to 'delivered' AND uploads proof images to chat.
  /// Returns (success, List<uploadedUrls>).
  Future<(bool, List<String>)> markDeliveredWithProof(
      String orderId,
      List<XFile> proofImages,
      ) async {
    try {
      // 1. Upload images — uses the same uploadPostImages you already have
      final SocialApiService apiService = SocialApiService();

      final urls = await apiService.uploadPostImages(proofImages);

      // 2. Advance status to delivered
      await api.put('/order/$orderId/status', {'status': 'delivered'});

      return (true, urls);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return (false, <String>[]);
    }
  }

  /// Submit a review for a vendor after order completion.
  Future<bool> submitReview(
      String vendorId, {
        required double rating,
        required String comment,
        required String userName,
        required String orderId,
      }) async {
    try {
      await api.post('/vendor/$vendorId/review', {
        'rating': rating,
        'comment': comment,
        'userName': userName,
        'orderId': orderId
      });
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Check if the current user has already reviewed this vendor.
  /// Returns {hasReviewed: bool}.
  Future<bool> checkHasReviewed(String vendorId) async {
    try {
      final data = await api.get('/vendor/$vendorId/reviews');
      return data['hasReviewed'] ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMenuItem(String itemId, Map<String, dynamic> updates) async {
    try {
      updatingProductItem = true;
      final data = await api.put('/menu/$itemId/update', updates);
      final updated = MenuItemModel.fromJson(data);
      final i = menuItems.indexWhere((m) => m.id == itemId);
      if (i != -1) { menuItems[i] = updated; notifyListeners(); }
      return true;
    } catch (e) { error = e.toString(); notifyListeners(); return false; }
    finally {
      updatingProductItem = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMenuItem(String itemId) async {
    try {
      await api.delete('/menu/$itemId/delete');
      menuItems.removeWhere((m) => m.id == itemId);
      notifyListeners();
      return true;
    } catch (e) { error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> toggleVisibility() async {
    if (myVendor == null) return false;

    // instant UI update
    final newValue = !vendorIsVisible;
    print(newValue);

    myVendor = myVendor!.copyWith(isVisible: newValue);

    notifyListeners();

    try {
      await api.put('/vendor/visibility', {});
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  Future<bool> togglePod() async {
    if (myVendor == null) return false;

    // instant UI update
    final newValue = !vendorAllowsPod;
    print(newValue);

    myVendor = myVendor!.copyWith(allowsPod: newValue);

    notifyListeners();

    try {
      await api.put('/vendor/pod-toggle', {});
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  Future<bool> applyAsVendor(Map<String, dynamic> application) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await api.post('/vendor/apply', application);
      await init();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addBranch(Map<String, dynamic> application) async {
    // state, lga, area, street, estimatedDeliveryTime
    loading = true;
    error = null;
    notifyListeners();
    try {
      await api.post('/branch/add', application);
      await init();
      return true;
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadLogo(File imageFile, String fileCategory) async {
    print('the inner is also called');
    try {
      print('I will start upload');
      final url = await api.upload('vendor/upload/logo', imageFile, fileCategory);
      print(url);
      if (myVendor != null) {
        // myVendor = VendorModel.fromJson({...myVendor!.toJson(), 'logo': url});
        myVendor = myVendor!.copyWith(logo: url);
        notifyListeners();
      }
      return true;
    } catch (e) { error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> uploadImages(String itemId, List<XFile> images) async {
    final formData = FormData();

    for (final image in images) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(
          image.path,
          filename: image.name,
        ),
      ));
    }
    final Dio dio = DioClient.instance.dio;
    try {
      print('hey🚩🔥');
      final res = await dio.post(
        'menu/$itemId/upload-images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      print('hey🚩🔥${res.data}');
      await loadMenuForBranch();
      return true;
    }
    catch (e) {
      print('${e.toString()}');
      error = e.toString(); notifyListeners(); return false;
    }
  }

  Future<void> deleteVendor () async {
    try {
      final data = api.delete("/vendor/delete");
      await init();
    }
    catch (e) {
      rethrow;
    }

  }
}

