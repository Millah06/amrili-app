import 'dart:io';

import 'package:everywhere/components/swicht.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../../../shared/widgets/image_editor.dart';
import '../../social/services/social_api_service.dart';
import '../models/vendor_model.dart';
import '../widgets/shared_widgets.dart';

class AddMenuItemPage extends StatefulWidget {
  /// Pass an existing item to edit, or null to add new
  final MenuItemModel? existingItem;
  const AddMenuItemPage({super.key, this.existingItem});

  @override
  State<AddMenuItemPage> createState() => _AddMenuItemPageState();
}

class _AddMenuItemPageState extends State<AddMenuItemPage> {

  final SocialApiService _apiService = SocialApiService();

  // Images newly picked from gallery (always XFile)
  List<XFile> _pickedImages = [];

  final _name  = TextEditingController();
  final _desc  = TextEditingController();
  final _price = TextEditingController();

  String? _selectedBranchId;

  bool _isAvailable = true;
  bool _loading = false;
  String? _error;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.existingItem!;
      _name.text  = item.name;
      _desc.text  = item.description;
      _price.text = item.price.toStringAsFixed(0);
      _isAvailable = item.isAvailable;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Item' : 'Add Menu Item',
            style: const TextStyle(
                color: VendorTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
      ),
      body: Consumer<VendorCenterProvider>(
        builder: (context, p, _) {
          final branches = p.myVendor?.branches.where((branch) {
           return branch.managerId == context.read<UserProvider>().user!.userId;
          }).toList() ?? [];
          _selectedBranchId ??= branches.isNotEmpty ? branches.first.id : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Image picker
              // _buildImageSection(),
              AppImagePicker(
                existingImages: _isEditing ? widget.existingItem?.images ?? [] : [],
                onChanged: (List<String> keptUrls, List<XFile> newImages) {

                  _pickedImages = newImages;

                },
              ),

              const SizedBox(height: 20),
              // Branch selector (only for new items)
              if (!_isEditing) ...[
                const Text('Add to Branch',
                    style: TextStyle(
                        color: VendorTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (branches.isEmpty)
                  const Text('No branches — add a branch first',
                      style: TextStyle(color: VendorTheme.error, fontSize: 13))
                else
                  _BranchSelector(
                    branches: branches,
                    selectedId: _selectedBranchId,
                    onSelect: (id) => setState(() => _selectedBranchId = id),
                  ),
                const SizedBox(height: 20),
              ],
              // Item details
              const Text('Item Details',
                  style: TextStyle(
                      color: VendorTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              VTextField(controller: _name, label: 'Item Name'),
              const SizedBox(height: 10),
              VTextField(
                controller: _desc,
                label: 'Description',
                hint: 'What is it made of? Any highlights?',
                maxLines: 5,
              ),
              const SizedBox(height: 10),
              VTextField(
                controller: _price,
                label: 'Price (₦)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              // Available toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: VendorTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: VendorTheme.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: VendorTheme.textMuted, size: 18),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Available for ordering',
                          style: TextStyle(
                              color: VendorTheme.textPrimary, fontSize: 14)),
                    ),
                    TinySwitch(
                      value: _isAvailable,
                      onChanged: (v) => setState(() => _isAvailable = v),

                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: VendorTheme.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              VButton(
                label: _isEditing ? 'Save Changes' : 'Add Item',
                loading: _loading,
                onTap: _submit,
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _submit() async {
    if (_name.text.isEmpty || _price.text.isEmpty) {
      setState(() => _error = 'Name and price are required');
      return;
    }
    if (!_isEditing && _selectedBranchId == null) {
      setState(() => _error = 'Please select a branch');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final p = context.read<VendorCenterProvider>();

      if (_isEditing) {

        List<String>? imageUrls;

        if (_pickedImages.isNotEmpty) {
          imageUrls = await _apiService.uploadPostImages(_pickedImages);
        }

        await p.updateMenuItem(widget.existingItem!.id, {
          'name': _name.text.trim(),
          'description': _desc.text.trim(),
          'price': double.tryParse(_price.text.trim()) ?? 0,
          'isAvailable': _isAvailable,
          'imageUrls': imageUrls,
        });

      } else {

        List<String>? imageUrls;

        if (_pickedImages.isNotEmpty) {
          imageUrls = await _apiService.uploadPostImages(_pickedImages);
        }

        await p.addMenuItem(_selectedBranchId!, {
          'name': _name.text.trim(),
          'description': _desc.text.trim(),
          'price': double.tryParse(_price.text.trim()) ?? 0,
          'isAvailable': _isAvailable,
          'imageUrls': imageUrls,
        });

      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Item updated!' : 'Item added!'),
            backgroundColor: VendorTheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

}

// ─── Branch Selector ──────────────────────────────────────────────────────────

class _BranchSelector extends StatelessWidget {
  final List<BranchModel> branches;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _BranchSelector({
    required this.branches,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: branches.map((b) {
        final sel = selectedId == b.id;
        return GestureDetector(
          onTap: () => onSelect(b.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? VendorTheme.primary.withOpacity(0.15) : VendorTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? VendorTheme.primary : VendorTheme.divider,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${b.area}, ${b.lga}',
                    style: TextStyle(
                        color: sel ? VendorTheme.primary : VendorTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(b.state,
                    style: const TextStyle(
                        color: VendorTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}