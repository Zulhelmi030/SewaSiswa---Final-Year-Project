import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finalyearproject/core/services/image_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class HousematePostScreen extends StatefulWidget {
  const HousematePostScreen({super.key});

  @override
  State<HousematePostScreen> createState() => _HousematePostScreenState();
}

class _HousematePostScreenState extends State<HousematePostScreen> {
  final _client = Supabase.instance.client;

  // UI State
  String _selectedGender = 'Any';
  String? _selectedState;
  String? _selectedCity;
  Map<String, List<String>> _stateCityMap = {};
  final List<String> _selectedFacilities = [];
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _includeAsTenant = false; // will the poster also live in this house?

  // Roommate slots
  int _totalSlots = 1;
  int _occupiedSlots = 0;

  // Geocoding
  double? _latitude;
  double? _longitude;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _rulesController = TextEditingController();

  late final ImageService _imageService;

  static const int _maxImages = 5;

  final List<String> _facilitiesList = [
    'WiFi',
    'AC',
    'Washing Machine',
    'Parking',
    'Water Heater',
    'Gym',
    'Kitchen',
  ];

  @override
  void initState() {
    super.initState();
    _imageService = ImageService(_client);
    _loadStateCityData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _loadStateCityData() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/malaysia_states_cities.json',
    );
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> states = jsonData['states'];
    final Map<String, List<String>> map = {};
    for (final state in states) {
      map[state['name'] as String] = List<String>.from(state['cities'] as List);
    }
    setState(() => _stateCityMap = map);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 5 photos.')),
      );
      return;
    }
    try {
      if (source == ImageSource.gallery) {
        // Multi-select from gallery
        final remaining = 5 - _selectedImages.length;
        final List<XFile> pickedFiles = await _picker.pickMultiImage(
          imageQuality: 80,
          limit: remaining,
        );
        if (pickedFiles.isNotEmpty) {
          setState(() {
            for (final f in pickedFiles) {
              if (_selectedImages.length < 5) {
                _selectedImages.add(File(f.path));
              }
            }
          });
        }
      } else {
        // Camera — single shot
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );
        if (pickedFile != null) {
          setState(() => _selectedImages.add(File(pickedFile.path)));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _geocodeAddress() async {
    final address = [
      _addressController.text.trim(),
      _selectedCity,
      _selectedState,
      _postcodeController.text.trim(),
      'Malaysia',
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        _latitude = locations.first.latitude;
        _longitude = locations.first.longitude;
      }
    } catch (e) {
      debugPrint('Geocoding failed (non-fatal): $e');
      _latitude = null;
      _longitude = null;
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final address = _addressController.text.trim();
    final rent = double.tryParse(_rentController.text.trim());

    if (title.isEmpty ||
        description.isEmpty ||
        address.isEmpty ||
        rent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Anyone who posts a listing becomes a landlord
      await _ensureLandlordRole();

      // Geocode the address
      await _geocodeAddress();

      // Upload images if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _imageService.uploadMultipleImages(_selectedImages);
      }

      // Insert the housemate listing
      final response = await _client
          .from('listings')
          .insert({
            'owner_id': user.id,
            'title': title,
            'description': description,
            'address': address,
            'city': _selectedCity,
            'state': _selectedState,
            'postcode': _postcodeController.text.trim().isEmpty
                ? null
                : _postcodeController.text.trim(),
            'latitude': _latitude ?? 0.0,
            'longitude': _longitude ?? 0.0,
            'monthly_rent': rent,
            'deposit': double.tryParse(_depositController.text.trim()),
            'house_rule': _rulesController.text.trim().isEmpty
                ? null
                : _rulesController.text.trim(),
            'gender_preference': _selectedGender,
            'facilities': _selectedFacilities.isEmpty
                ? null
                : _selectedFacilities,
            'post_type': 'housemate',
            'status': 'available',
            'total_slots': _totalSlots,
            'occupied_slots': _occupiedSlots,
          })
          .select()
          .single();

      final listingId = response['id'] as String;

      // Save photo URLs to listing_photos table
      if (imageUrls.isNotEmpty) {
        final photoRows = imageUrls
            .map((url) => {'listing_id': listingId, 'photo_url': url})
            .toList();
        await _client.from('listing_photos').insert(photoRows);
      }

      // Only add the creator as a tenant if they chose to live there
      if (_includeAsTenant) {
        await _client.from('rental_tenants').insert({
          'listing_id': listingId,
          'user_id': user.id,
          'status': 'active',
          'joined_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Housemate listing posted successfully! 🏠'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('Error posting housemate listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ensureLandlordRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final response = await Supabase.instance.client
        .from('users')
        .select('global_role')
        .eq('id', user.id);
    final role = response.first['global_role'] as String?;
    // Promote to landlord if not already — posting a listing = landlord
    if (role != 'landlord') {
      await Supabase.instance.client
          .from('users')
          .update({'global_role': 'landlord'})
          .eq('id', user.id);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: context.appColors.onSurface),
        title: Text(
          'Find a Housemate',
          style: context.appTextStyles.titleLarge.copyWith(
            color: context.appColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoUploadSection(),
            const SizedBox(height: 8),
            _buildFormSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Photo Upload ─────────────────────────────────────────────────────────────

  Widget _buildPhotoUploadSection() {
    return Container(
      color: context.appColors.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'House Photos',
            style: context.appTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add photos of the house. First photo will be the cover.',
            style: context.appTextStyles.bodySmall.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_selectedImages.length < _maxImages) _buildAddPhotoButton(),
                const SizedBox(width: 12),
                ..._selectedImages.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildPhotoThumbnail(entry.key, entry.value),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: context.appColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: context.appColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: context.appTextStyles.labelMedium.copyWith(
                color: context.appColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index, File imageFile) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: InkWell(
            onTap: () => setState(() => _selectedImages.removeAt(index)),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 20, color: context.appColors.error),
            ),
          ),
        ),
      ),
    );
  }

  // ── Main Form ────────────────────────────────────────────────────────────────

  Widget _buildFormSection() {
    return Container(
      color: context.appColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Roommate Slots ──────────────────────────────────────────────────
          _buildSectionHeader('Roommate Slots', Icons.people_rounded),
          const SizedBox(height: 16),
          _buildRoommateSlotsSection(),

          const SizedBox(height: 24),
          Divider(color: context.appColors.surfaceVariant),
          const SizedBox(height: 24),

          // ── Property Details ────────────────────────────────────────────────
          _buildSectionHeader('House Details', Icons.home_rounded),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Post Title',
            placeholder: 'e.g. Looking for 1 Roommate in Melaka Raya',
            controller: _titleController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Description',
            placeholder: 'Describe the house, your lifestyle, preferences...',
            maxLines: 4,
            controller: _descriptionController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Address',
            placeholder: 'Full street address',
            controller: _addressController,
          ),
          const SizedBox(height: 16),
          _buildStateDropdown(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildCityDropdown()),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Postcode',
                  placeholder: '75000',
                  controller: _postcodeController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: context.appColors.surfaceVariant),
          const SizedBox(height: 24),

          // ── Pricing ─────────────────────────────────────────────────────────
          _buildSectionHeader('Pricing', Icons.payments_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Monthly Rent (per person)',
                  placeholder: '0.00',
                  prefixText: 'RM ',
                  controller: _rentController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Deposit',
                  placeholder: '0.00',
                  prefixText: 'RM ',
                  controller: _depositController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: context.appColors.surfaceVariant),
          const SizedBox(height: 24),

          // ── Preferences & Rules ─────────────────────────────────────────────
          _buildSectionHeader('Preferences & Rules', Icons.rule_rounded),
          const SizedBox(height: 16),
          _buildGenderPreference(),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'House Rules',
            placeholder: 'e.g. No smoking, quiet hours after 11 PM',
            maxLines: 3,
            controller: _rulesController,
          ),

          const SizedBox(height: 24),
          Divider(color: context.appColors.surfaceVariant),
          const SizedBox(height: 24),

          // ── Facilities ──────────────────────────────────────────────────────
          _buildSectionHeader('Facilities', Icons.dashboard_rounded),
          const SizedBox(height: 16),
          _buildFacilitiesSelector(),

          const SizedBox(height: 24),
          Divider(color: context.appColors.surfaceVariant),
          const SizedBox(height: 24),

          // ── Tenancy Inclusion ───────────────────────────────────────────────
          _buildSectionHeader('Your Tenancy', Icons.person_pin_circle_rounded),
          const SizedBox(height: 12),
          _buildIncludeAsTenantToggle(),
        ],
      ),
    );
  }

  Widget _buildIncludeAsTenantToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _includeAsTenant
            ? context.appColors.primary.withValues(alpha: 0.08)
            : context.appColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _includeAsTenant
              ? context.appColors.primary.withValues(alpha: 0.4)
              : context.appColors.outlineVariant,
          width: 1.5,
        ),
      ),
      child: CheckboxListTile(
        value: _includeAsTenant,
        onChanged: (val) => setState(() => _includeAsTenant = val ?? false),
        activeColor: context.appColors.primary,
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        title: Text(
          'Include me as a tenant',
          style: context.appTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _includeAsTenant
              ? 'You will be listed as a tenant living in this house'
              : 'You are the house owner — you will not be listed as a tenant',
          style: context.appTextStyles.bodySmall.copyWith(
            color: _includeAsTenant
                ? context.appColors.primary
                : context.appColors.textSecondary,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // ── Roommate Slots ───────────────────────────────────────────────────────────

  Widget _buildRoommateSlotsSection() {
    final available = _totalSlots - _occupiedSlots;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.primaryFixed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Visual slot indicator
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_totalSlots, (index) {
              final isFilled = index < _occupiedSlots;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isFilled
                      ? context.appColors.primary
                      : context.appColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.appColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  isFilled ? Icons.person : Icons.person_outline,
                  size: 18,
                  color: isFilled ? Colors.white : context.appColors.primary,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            '$_occupiedSlots / $_totalSlots filled · Looking for $available more',
            style: context.appTextStyles.titleMedium.copyWith(
              color: context.appColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Total slots stepper
          _buildSlotStepper(
            label: 'Total rooms in house',
            value: _totalSlots,
            min: 1,
            max: 20,
            onDecrement: () {
              if (_totalSlots > 1 && _totalSlots > _occupiedSlots + 1) {
                setState(() => _totalSlots--);
              }
            },
            onIncrement: () => setState(() => _totalSlots++),
          ),
          const SizedBox(height: 12),

          // Occupied slots stepper
          _buildSlotStepper(
            label: 'Rooms already filled',
            value: _occupiedSlots,
            min: 0,
            max: _totalSlots - 1,
            onDecrement: () {
              if (_occupiedSlots > 0) setState(() => _occupiedSlots--);
            },
            onIncrement: () {
              if (_occupiedSlots < _totalSlots - 1) {
                setState(() => _occupiedSlots++);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlotStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.appTextStyles.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ),
        Row(
          children: [
            _stepperButton(
              icon: Icons.remove,
              onTap: value > min ? onDecrement : null,
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: context.appTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            _stepperButton(
              icon: Icons.add,
              onTap: value < max ? onIncrement : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepperButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? context.appColors.primary
              : context.appColors.outline.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? Colors.white : context.appColors.outline,
        ),
      ),
    );
  }

  // ── Reusable Form Widgets ────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.appColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: context.appColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: context.appTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String placeholder,
    int maxLines = 1,
    String? prefixText,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.appTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixText: prefixText,
            hintStyle: context.appTextStyles.bodyMedium.copyWith(
              color: context.appColors.outline,
            ),
            filled: true,
            fillColor: context.appColors.surfaceContainerHigh,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
          style: context.appTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedState,
          hint: Text(
            'Select a state',
            style: context.appTextStyles.bodyMedium.copyWith(color: context.appColors.outline),
          ),
          items: _stateCityMap.keys
              .map(
                (state) => DropdownMenuItem(
                  value: state,
                  child: Text(
                    state,
                    style: context.appTextStyles.bodyMedium.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              _selectedCity = null;
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: context.appColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    final cities = _selectedState != null
        ? (_stateCityMap[_selectedState] ?? [])
        : <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City',
          style: context.appTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCity,
          hint: Text(
            'Select a city',
            style: context.appTextStyles.bodyMedium.copyWith(color: context.appColors.outline),
          ),
          items: cities
              .map(
                (city) => DropdownMenuItem(
                  value: city,
                  child: Text(
                    city,
                    style: context.appTextStyles.bodyMedium.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: cities.isEmpty
              ? null
              : (value) => setState(() => _selectedCity = value),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.appColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPreference() {
    const options = ['Male', 'Female', 'Any'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender Preference',
          style: context.appTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            final isSelected = _selectedGender == option;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(option),
                selected: isSelected,
                selectedColor: context.appColors.primary,
                labelStyle: context.appTextStyles.labelMedium.copyWith(
                  color: isSelected ? Colors.white : context.appColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _selectedGender = option),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFacilitiesSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _facilitiesList.map((facility) {
        final isSelected = _selectedFacilities.contains(facility);
        return FilterChip(
          label: Text(facility),
          selected: isSelected,
          selectedColor: context.appColors.primary.withValues(alpha: 0.15),
          checkmarkColor: context.appColors.primary,
          labelStyle: context.appTextStyles.labelMedium.copyWith(
            color: isSelected ? context.appColors.primary : context.appColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? context.appColors.primary : context.appColors.outlineVariant,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedFacilities.add(facility);
              } else {
                _selectedFacilities.remove(facility);
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ── Bottom Bar ───────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: context.appColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Post Housemate Listing',
                    style: context.appTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
