import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../service/database_service.dart';
import 'TowingServiceScreen.dart';
import '../models/mechanic_model.dart' as model;
import 'mechanic_recommendation.dart';
import 'genai.dart';
import '../service/geocoding_service.dart';
import '../service/location_pricing_service.dart';
import '../widgets/location_search_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _userName = "Ibrahim";
  final String _carModel = "Toyota Corolla Altis";
  final bool _isLoading = false;

  // Define the app's color scheme based on the image
  final Color _primaryColor = const Color(0xFF3A2A8B); // Dark purple
  final Color _cardColor = const Color(0xFF1F1B3C); // Darker purple for cards
  final Color _accentColor = const Color(
    0xFF5A45D2,
  ); // Lighter purple for accents
  final Color _backgroundColor = const Color(
    0xFF121025,
  ); // Very dark purple background

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style to match the dark theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // Show custom menu dialog when menu button is pressed
  void _showMenuOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuOption(
                  icon: Icons.engineering,
                  title: 'Register as Mechanic',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterAsMechanicScreen(),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white24, height: 1, thickness: 1),
                _buildMenuOption(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: _accentColor))
              : SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        _buildCarSection(),
                        _buildServiceGrid(),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentColor, _primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                onPressed: () {
                  _showMenuOptions(context);
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello,',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Welcome back $_userName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: const DecorationImage(
                    image: AssetImage('assets/image3.jpg'),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          Text(
            _carModel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: _cardColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(child: Image.asset('assets/image1.png', height: 300)),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGrid() {
    final List<Map<String, dynamic>> services = [
      {'title': 'Towing Service', 'icon': Icons.fire_truck_outlined},
      {'title': 'Mechanic Recommendation', 'icon': Icons.engineering},
      {'title': '3D Modeling', 'icon': Icons.view_in_ar},
      {'title': 'Gen AI', 'icon': Icons.bubble_chart},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(
          title: service['title'],
          icon: service['icon'],
        );
      },
    );
  }

  Widget _buildServiceCard({required String title, required IconData icon}) {
    return InkWell(
      onTap: () {
        if (title == 'Towing Service') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TowingServiceScreen(),
            ),
          );
        } else if (title == 'Mechanic Recommendation') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MechanicRecommendationScreen(),
            ),
          );
        } else if (title == 'Gen AI') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GenAIScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title screen not implemented yet')),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accentColor.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// RegisterAsMechanicScreen - This is the new screen for mechanic registration
// class RegisterAsMechanicScreen extends StatefulWidget {
//   const RegisterAsMechanicScreen({super.key});

//   @override
//   State<RegisterAsMechanicScreen> createState() =>
//       _RegisterAsMechanicScreenState();
// }

// class _RegisterAsMechanicScreenState extends State<RegisterAsMechanicScreen> {
//   // Form controllers
//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _experienceController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();

//   // Define colors to match the app's theme
//   final Color _primaryColor = const Color(0xFF3A2A8B); // Dark purple
//   final Color _cardColor = const Color(0xFF1F1B3C); // Darker purple for cards
//   final Color _accentColor = const Color(
//     0xFF5A45D2,
//   ); // Lighter purple for accents
//   final Color _backgroundColor = const Color(
//     0xFF121025,
//   ); // Very dark purple background

//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _addressController.dispose();
//     _experienceController.dispose();
//     _specialtyController.dispose();
//     super.dispose();
//   }

//   void _submitForm() {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       // Simulate API call with a delay
//       Future.delayed(const Duration(seconds: 2), () {
//         setState(() {
//           _isLoading = false;
//         });

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Registration submitted successfully')),
//         );

//         // Navigate back to dashboard
//         Navigator.pop(context);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _backgroundColor,
//       appBar: AppBar(
//         title: const Text(
//           'Register as Mechanic',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: _primaryColor,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body:
//           _isLoading
//               ? Center(child: CircularProgressIndicator(color: _accentColor))
//               : SafeArea(
//                 child: SingleChildScrollView(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Form(
//                       key: _formKey,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Form header
//                           Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [_accentColor, _primaryColor],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Text(
//                                   'Join Our Mechanic Network',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 22,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 SizedBox(height: 8),
//                                 Text(
//                                   'Fill in your details to register as a mechanic and start receiving service requests',
//                                   style: TextStyle(
//                                     color: Colors.white70,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           const SizedBox(height: 24),

//                           // Personal Information Section
//                           _buildSectionTitle('Personal Information'),
//                           const SizedBox(height: 16),

//                           // Name Field
//                           _buildTextField(
//                             controller: _nameController,
//                             label: 'Full Name',
//                             icon: Icons.person,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Please enter your name';
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: 16),

//                           // Phone Field
//                           _buildTextField(
//                             controller: _phoneController,
//                             label: 'Phone Number',
//                             icon: Icons.phone,
//                             keyboardType: TextInputType.phone,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Please enter your phone number';
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: 16),

//                           // Email Field
//                           _buildTextField(
//                             controller: _emailController,
//                             label: 'Email Address',
//                             icon: Icons.email,
//                             keyboardType: TextInputType.emailAddress,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Please enter your email';
//                               } else if (!RegExp(
//                                 r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                               ).hasMatch(value)) {
//                                 return 'Please enter a valid email';
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: 16),

//                           // Address Field
//                           _buildTextField(
//                             controller: _addressController,
//                             label: 'Workshop Address',
//                             icon: Icons.location_on,
//                             maxLines: 2,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Please enter your workshop address';
//                               }
//                               return null;
//                             },
//                           ),

//                           const SizedBox(height: 24),

//                           // Professional Information Section
//                           _buildSectionTitle('Professional Information'),
//                           const SizedBox(height: 16),

//                           // Experience Field
//                           _buildTextField(
//                             controller: _experienceController,
//                             label: 'Years of Experience',
//                             icon: Icons.work,
//                             keyboardType: TextInputType.number,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Please enter your experience';
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: 16),

//                           // Specialty Field
//                           _buildTextField(
//                             controller: _specialtyController,
//                             label: 'Specialty/Expertise',
//                             icon: Icons.build,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Please enter your specialty';
//                               }
//                               return null;
//                             },
//                           ),

//                           const SizedBox(height: 32),

//                           // Submit Button
//                           Container(
//                             width: double.infinity,
//                             height: 55,
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [_accentColor, _primaryColor],
//                                 begin: Alignment.centerLeft,
//                                 end: Alignment.centerRight,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: ElevatedButton(
//                               onPressed: _submitForm,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.transparent,
//                                 shadowColor: Colors.transparent,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               child: const Text(
//                                 'SUBMIT APPLICATION',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),

//                           const SizedBox(height: 24),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         color: _accentColor,
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//     int maxLines = 1,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       style: const TextStyle(color: Colors.white),
//       keyboardType: keyboardType,
//       maxLines: maxLines,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: Colors.white70),
//         prefixIcon: Icon(icon, color: _accentColor),
//         filled: true,
//         fillColor: _cardColor,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide.none,
//         ),
//         contentPadding: const EdgeInsets.symmetric(
//           vertical: 16,
//           horizontal: 20,
//         ),
//       ),
//       validator: validator,
//     );
//   }
// }

// This is the updated RegisterAsMechanicScreen class to integrate with Neon DB
// Replace your existing RegisterAsMechanicScreen class with this one

class RegisterAsMechanicScreen extends StatefulWidget {
  const RegisterAsMechanicScreen({super.key});

  @override
  State<RegisterAsMechanicScreen> createState() =>
      _RegisterAsMechanicScreenState();
}

class _RegisterAsMechanicScreenState extends State<RegisterAsMechanicScreen> {
  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController();
  final _customSpecialtyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Define colors to match the app's theme
  final Color _primaryColor = const Color(0xFF3A2A8B); // Dark purple
  final Color _cardColor = const Color(0xFF1F1B3C); // Darker purple for cards
  final Color _accentColor = const Color(
    0xFF5A45D2,
  ); // Lighter purple for accents
  final Color _backgroundColor = const Color(
    0xFF121025,
  ); // Very dark purple background

  bool _isLoading = false;
  final DatabaseService _databaseService = DatabaseService();
  final LocationPricingService _locationService = LocationPricingService();
  final GeocodingService _geocodingService = GeocodingService();

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _locationDisplayLabel;
  bool _isResolvingLocation = false;

  final List<String> _specialtyOptions = [
    'Brake specialist',
    'Engine specialist',
    'Electrician',
    'Puncture specialist',
    'Hybrid car mechanic',
    'Diesel engine mechanic',
    'Motorcycle specialist',
    'Truck specialist',
  ];
  final Set<String> _selectedSpecialties = {};
  String? _specialtyError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _locationController.dispose();
    _customSpecialtyController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLatitude == null || _selectedLongitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your workshop location on the map'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final List<String> specialties = [..._selectedSpecialties];
      if (_customSpecialtyController.text.trim().isNotEmpty) {
        specialties.add(_customSpecialtyController.text.trim());
      }

      if (specialties.isEmpty) {
        setState(() {
          _specialtyError = 'Select at least one specialty';
        });
        return;
      } else {
        setState(() {
          _specialtyError = null;
        });
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Create a new Mechanic object from form data
        final mechanic = model.Mechanic(
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          address: _addressController.text,
          yearsOfExperience: int.parse(_experienceController.text),
          specialty: specialties.join(','),
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
        );

        // Insert mechanic into the database
        final mechanicId = await _databaseService.insertMechanic(mechanic);

        // Show success message with the mechanic ID
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful! Mechanic ID: $mechanicId'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to dashboard
        Navigator.pop(context);
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // Set loading state to false if still mounted
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      setState(() {
        _isResolvingLocation = true;
      });
      final position = await _locationService.getCurrentPosition();
      final reverse = await _geocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      _applyLocation(
        position.latitude,
        position.longitude,
        label:
            reverse?.displayName ??
            'Lat: ${position.latitude.toStringAsFixed(5)}, '
                'Lng: ${position.longitude.toStringAsFixed(5)}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to fetch current location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  void _applyLocation(double latitude, double longitude, {String? label}) {
    final prettyLabel =
        label ??
        'Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}';
    setState(() {
      _selectedLatitude = latitude;
      _selectedLongitude = longitude;
      _locationDisplayLabel = prettyLabel;
      _locationController.text = prettyLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Register as Mechanic',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: _accentColor))
              : SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Form header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_accentColor, _primaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Join Our Mechanic Network',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Fill in your details to register as a mechanic and start receiving service requests',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Personal Information Section
                          _buildSectionTitle('Personal Information'),
                          const SizedBox(height: 16),

                          // Name Field
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone Field
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              } else if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Address Field
                          _buildTextField(
                            controller: _addressController,
                            label: 'Workshop Address',
                            icon: Icons.location_on,
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your workshop address';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          _buildSectionTitle('Workshop Location'),
                          const SizedBox(height: 12),
                          LocationSearchWidget(
                            controller: _locationController,
                            hintText: 'Search your shop on map',
                            icon: Icons.map_outlined,
                            iconColor: _accentColor,
                            showCurrentLocationButton: false,
                            onLocationSelected: (result) {
                              _applyLocation(
                                result.latitude,
                                result.longitude,
                                label: result.displayName,
                              );
                            },
                            onCoordinatesSelected: (lat, lng) {
                              _applyLocation(lat, lng);
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isResolvingLocation
                                      ? null
                                      : _useCurrentLocation,
                              icon:
                                  _isResolvingLocation
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.my_location,
                                        color: Colors.white,
                                      ),
                              label: Text(
                                _isResolvingLocation
                                    ? 'Detecting location...'
                                    : 'Use Current Location',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(color: _accentColor),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),
                          if (_locationDisplayLabel != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _accentColor.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.place,
                                        color: _accentColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Selected Location',
                                        style: TextStyle(
                                          color: _accentColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _locationDisplayLabel!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (_selectedLatitude != null &&
                                      _selectedLongitude != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lat: ${_selectedLatitude!.toStringAsFixed(5)}, '
                                      'Lng: ${_selectedLongitude!.toStringAsFixed(5)}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Professional Information Section
                          _buildSectionTitle('Professional Information'),
                          const SizedBox(height: 16),

                          // Experience Field
                          _buildTextField(
                            controller: _experienceController,
                            label: 'Years of Experience',
                            icon: Icons.work,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your experience';
                              }
                              try {
                                int years = int.parse(value);
                                if (years < 0 || years > 100) {
                                  return 'Please enter a valid experience (0-100 years)';
                                }
                              } catch (e) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildSectionTitle('Specialties & Services'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _specialtyOptions.map((option) {
                                  final isSelected = _selectedSpecialties
                                      .contains(option);
                                  return FilterChip(
                                    label: Text(option),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedSpecialties.add(option);
                                        } else {
                                          _selectedSpecialties.remove(option);
                                        }
                                      });
                                    },
                                    selectedColor: _accentColor,
                                    backgroundColor: Colors.transparent,
                                    labelStyle: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                    ),
                                    side: BorderSide(
                                      color:
                                          isSelected
                                              ? Colors.transparent
                                              : Colors.white24,
                                    ),
                                  );
                                }).toList(),
                          ),
                          if (_specialtyError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _specialtyError!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _customSpecialtyController,
                            label: 'Add Custom Specialty (optional)',
                            icon: Icons.add,
                          ),

                          const SizedBox(height: 32),

                          // Submit Button
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_accentColor, _primaryColor],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'SUBMIT APPLICATION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _accentColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: _accentColor),
        filled: true,
        fillColor: _cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      validator: validator,
    );
  }
}
