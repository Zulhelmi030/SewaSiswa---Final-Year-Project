import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finalyearproject/core/constants/app_colors.dart';
import 'package:finalyearproject/core/services/image_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  // UI State for toggles/chips
  String _selectedGender = 'Male';
  String? _selectedState;
  String? _selectedCity;
  Map<String, List<String>> _stateCityMap = {};
  final List<String> _selectedFacilities = [];
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  int _totalSlots = 1; // max tenants allowed

  // Geocoding result
  double? _latitude;
  double? _longitude;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _rulesController = TextEditingController();

  // ImageService — inject the current Supabase client
  late final ImageService _imageService;

  final List<String> _facilitiesList = [
    'WiFi',
    'AC',
    'Washing Machine',
    'Parking',
    'Water Heater',
    'Gym',
    'Kitchen',
  ];

  static const int _maxImages = 5;

  @override
  void initState() {
    super.initState();
    _imageService = ImageService(Supabase.instance.client);
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
    setState(() {
      _stateCityMap = map;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only add up to 5 photos.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
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

  /// Geocodes the full address string into lat/lng using the device's
  /// native geocoding engine (no API key required).
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
      // Geocoding failure is non-fatal — listing is still created without coords
      _latitude = null;
      _longitude = null;
    }
  }

  Future<void> _ensureLandlordRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final queryBuilder = Supabase.instance.client
        .from('users')
        .select('global_role')
        .eq('id', user.id);

    final response = await queryBuilder;
    final role = response.first['global_role'] as String?;

    if (role != "landlord") {
      await Supabase.instance.client
          .from('users')
          .update({'global_role': 'landlord'})
          .eq('id', user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onBackground),
        title: const Text(
          "Create New Listing",
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoUploadSection(),
            const SizedBox(height: 24),
            _buildFormSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPhotoUploadSection() {
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Property Photos",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add high-quality photos of your property. First photo will be the cover.",
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_selectedImages.length < _maxImages) _buildAddPhotoButton(),
                const SizedBox(width: 12),

                // Show actual selected images
                ..._selectedImages.asMap().entries.map((entry) {
                  int index = entry.key;
                  File imageFile = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildRealPhotoThumbnail(index, imageFile),
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
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: AppColors.primary, size: 32),
            SizedBox(height: 8),
            Text(
              "Add Photo",
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealPhotoThumbnail(int index, File imageFile) {
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
          padding: const EdgeInsets.all(4.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedImages.removeAt(index);
              });
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Property Details",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: "Property Title",
            placeholder: "e.g. Bilik Master Mutiara Bangi",
            controller: _titleController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: "Description",
            placeholder: "Describe your property...",
            maxLines: 4,
            controller: _descriptionController,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: "Address",
            placeholder: "Full street address",
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
                  label: "Postcode",
                  placeholder: "43650",
                  controller: _postcodeController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.surfaceVariant),
          const SizedBox(height: 24),
          const Text(
            "Pricing",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: "Monthly Rent",
                  placeholder: "0.00",
                  prefixText: "RM ",
                  controller: _rentController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: "Deposit",
                  placeholder: "0.00",
                  prefixText: "RM ",
                  controller: _depositController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.surfaceVariant),
          const SizedBox(height: 24),
          const Text(
            'Availability',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTenantCapacityStepper(),
          const SizedBox(height: 24),
          const Divider(color: AppColors.surfaceVariant),
          const SizedBox(height: 24),
          const Text(
            "Preferences & Rules",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildGenderPreference(),
          const SizedBox(height: 16),
          _buildTextField(
            label: "House Rules",
            placeholder: "e.g. No smoking, quiet hours after 11 PM",
            maxLines: 3,
            controller: _rulesController,
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.surfaceVariant),
          const SizedBox(height: 24),
          const Text(
            "Facilities",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFacilitiesSelector(),
        ],
      ),
    );
  }

  Widget _buildTenantCapacityStepper() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tenant Capacity',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Maximum number of tenants allowed',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildStepBtn(
              icon: Icons.remove,
              enabled: _totalSlots > 1,
              onTap: () => setState(() => _totalSlots--),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$_totalSlots',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _buildStepBtn(
              icon: Icons.add,
              enabled: _totalSlots < 20,
              onTap: () => setState(() => _totalSlots++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary
              : AppColors.outline.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : AppColors.outline,
        ),
      ),
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
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.textPrimary,
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
            hintStyle: const TextStyle(
              color: AppColors.outline,
              fontFamily: 'Inter',
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerHigh,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
        const Text(
          'State',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedState,
          hint: const Text(
            'Select a state',
            style: TextStyle(color: AppColors.outline, fontFamily: 'Inter'),
          ),
          items: _stateCityMap.keys
              .map(
                (state) => DropdownMenuItem(
                  value: state,
                  child: Text(
                    state,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              _selectedCity = null; // reset city when state changes
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerHigh,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          dropdownColor: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    final List<String> cities = _selectedState != null
        ? (_stateCityMap[_selectedState] ?? [])
        : [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _selectedCity,
          hint: Text(
            _selectedState == null ? 'Select state first' : 'Select a city',
            style: const TextStyle(
              color: AppColors.outline,
              fontFamily: 'Inter',
            ),
          ),
          items: cities
              .map(
                (city) => DropdownMenuItem(
                  value: city,
                  child: Text(
                    city,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: cities.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
          decoration: InputDecoration(
            filled: true,
            fillColor: cities.isEmpty
                ? AppColors.surfaceContainerHigh.withValues(alpha: 0.5)
                : AppColors.surfaceContainerHigh,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          dropdownColor: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPreference() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gender Preference",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Male', label: Text('Male')),
            ButtonSegment(value: 'Female', label: Text('Female')),
          ],
          selected: {_selectedGender},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedGender = newSelection.first;
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primaryContainer;
              }
              return AppColors.surfaceContainerHigh;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.onPrimary;
              }
              return AppColors.textPrimary;
            }),
          ),
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
          label: Text(
            facility,
            style: TextStyle(
              fontFamily: 'Inter',
              color: isSelected
                  ? AppColors.onPrimaryFixed
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedFacilities.add(facility);
              } else {
                _selectedFacilities.remove(facility);
              }
            });
          },
          backgroundColor: AppColors.surfaceContainerHigh,
          selectedColor: AppColors.primaryFixed,
          checkmarkColor: AppColors.onPrimaryFixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide.none,
          ),
        );
      }).toList(),
    );
  }

  /// Validates form, uploads images, then inserts the listing into Supabase.
  Future<void> _createListing() async {
    // --- Validation ---
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Please enter a property title.');
      return;
    }
    if (_selectedState == null || _selectedCity == null) {
      _showSnack('Please select a state and city.');
      return;
    }
    if (_postcodeController.text.trim().isEmpty) {
      _showSnack('Please enter a postcode.');
      return;
    }
    final rent = double.tryParse(_rentController.text.trim());
    if (rent == null || rent <= 0) {
      _showSnack('Please enter a valid monthly rent.');
      return;
    }
    if (_selectedImages.isEmpty) {
      _showSnack('Please add at least one photo.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1 — Upload images and collect URLs
      final List<String> imageUrls = await _imageService.uploadMultipleImages(
        _selectedImages,
      );

      if (imageUrls.isEmpty) {
        _showSnack('Image upload failed. Please try again.');
        return;
      }

      // Step 2 — Geocode the address (best-effort, non-fatal)
      await _geocodeAddress();
      final bool geocodeFailed = _latitude == null || _longitude == null;

      // Step 3 — Build the listing payload
      final payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _selectedCity,
        'state': _selectedState,
        'postcode': _postcodeController.text.trim(),
        'monthly_rent': rent,
        'deposit': double.tryParse(_depositController.text.trim()) ?? 0.0,
        'gender_preference': _selectedGender,
        'house_rules': _rulesController.text.trim(),
        'facilities': _selectedFacilities,
        'images': imageUrls,
        'owner_id': Supabase.instance.client.auth.currentUser!.id,
        'total_slots': _totalSlots,
        'occupied_slots': 0,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      };

      // Step 4 — Ensure user has landlord role, then Insert
      await _ensureLandlordRole();
      await Supabase.instance.client.from('listings').insert(payload);

      if (mounted) {
        if (geocodeFailed) {
          // Listing saved, but distance filter won't work for this listing
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Listing created, but location could not be determined. '
                'It will not appear in Distance filter results.',
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          _showSnack('Listing created successfully! 🎉');
        }
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error creating listing: $e');
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createListing,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.onPrimary,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  "Create Listing",
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
