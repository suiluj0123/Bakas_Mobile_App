import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_drawer.dart';
import '/widgets/BakasHeader.dart';
import '/widgets/WhiteContainer.dart';
import '/widgets/backgroundRed.dart';

class settingPage extends StatefulWidget {
  final String? firstName;
  final int? playerId;
  const settingPage({super.key, this.firstName, this.playerId});

  @override
  State<settingPage> createState() => _settingPageState();
}

class _settingPageState extends State<settingPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  // PH Locations Data
  List<dynamic> _regions = [];
  List<dynamic> _provinces = [];
  List<dynamic> _cities = [];
  List<dynamic> _barangays = [];

  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;

  final List<String> _idTypes = [
    'UMID',
    'PhilID (National ID)',
    "Driver's License",
    'Passport',
    'Postal ID',
    "Voter's ID",
    'Senior Citizen ID',
  ];

  Future<void> _fetchRegions() async {
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/settings/regions'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (mounted) setState(() => _regions = payload['data'] ?? []);
      } else {
        _showLocError('Failed to load regions: ${res.statusCode}');
      }
    } catch (e) {
      _showLocError('Connection error (Regions): $e');
    }
  }

  void _showLocError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _fetchProvinces(String regionCode) async {
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/settings/provinces/$regionCode'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        setState(() {
          _provinces = payload['data'];
          _selectedProvince = null;
          _selectedCity = null;
          _selectedBarangay = null;
          _cities = [];
          _barangays = [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching provinces: $e');
    }
  }

  Future<void> _fetchCities(String provinceCode) async {
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/settings/cities/$provinceCode'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        setState(() {
          _cities = payload['data'];
          _selectedCity = null;
          _selectedBarangay = null;
          _barangays = [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
    }
  }

  Future<void> _fetchBarangays(String cityCode) async {
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/settings/barangays/$cityCode'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        setState(() {
          _barangays = payload['data'];
          _selectedBarangay = null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching barangays: $e');
    }
  }

  // Controllers for editing
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _contactNumController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  final _idTypeController = TextEditingController();
  final _idNumberController = TextEditingController();

  String _apiBaseUrl() {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  @override
  void initState() {
    super.initState();
    debugPrint('SettingPage initState: playerId=${widget.playerId}');
    _fetchProfile();
    _fetchRegions();
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _contactNumController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _idTypeController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    if (widget.playerId == null) {
       setState(() => _isLoading = false);
       return;
    }
    try {
      final res = await http.get(Uri.parse('${_apiBaseUrl()}/api/settings/profile/${widget.playerId}'));
      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          setState(() {
            _profileData = payload['data'];
            // Initialize controllers
            _lastNameController.text = _profileData?['last_name'] ?? '';
            _firstNameController.text = _profileData?['first_name'] ?? '';
            _middleNameController.text = _profileData?['middle_name'] ?? '';
            _contactNumController.text = _profileData?['contact_num'] ?? '';
            _emailController.text = _profileData?['email'] ?? '';
            _streetController.text = _profileData?['address'] ?? '';
            _idTypeController.text = _profileData?['id_code'] ?? '';
            _idNumberController.text = _profileData?['id_number'] ?? '';

            _selectedRegion = _profileData?['region_code']?.toString();
            _selectedProvince = _profileData?['provincial_code']?.toString();
            _selectedCity = _profileData?['city_code']?.toString();
            _selectedBarangay = _profileData?['barangay_code']?.toString();
          });

          if (_selectedRegion != null) _fetchProvinces(_selectedRegion!);
          if (_selectedProvince != null) _fetchCities(_selectedProvince!);
          if (_selectedCity != null) _fetchBarangays(_selectedCity!);
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      final res = await http.put(
        Uri.parse('${_apiBaseUrl()}/api/settings/profileUpdate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'playerId': widget.playerId,
          'last_name': _lastNameController.text,
          'first_name': _firstNameController.text,
          'middle_name': _middleNameController.text,
          'contact_num': _contactNumController.text,
          'email': _emailController.text,
          'region_code': _selectedRegion,
          'provincial_code': _selectedProvince,
          'city_code': _selectedCity,
          'barangay_code': _selectedBarangay,
          'address': _streetController.text,
          'id_code': _idTypeController.text,
          'id_number': _idNumberController.text,
        }),
      );

      if (res.statusCode == 200) {
        final payload = jsonDecode(res.body);
        if (payload['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          _fetchProfile(); // Refresh
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  void showModalProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF5F5F5),
          title: const Text('Edit Profile'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: (_profileData?['picture'] != null && _profileData!['picture'].isNotEmpty)
                        ? NetworkImage(_profileData!['picture'])
                        : null,
                    child: (_profileData?['picture'] == null || _profileData!['picture'].isEmpty)
                        ? const Icon(Icons.camera_alt, size: 30)
                        : null,
                   ),
                  TextButton(
                    onPressed: () {},
                    child: const Text("Attach Profile Pic"),
                  ),
                  const SizedBox(height: 10),
                  editTextTemplate("Last Name", _lastNameController),
                  editTextTemplate("First Name", _firstNameController),
                  editTextTemplate("Middle Name", _middleNameController),
                  editTextTemplate(
                    "Mobile Number",
                    _contactNumController,
                    keyboardType: TextInputType.phone,
                  ),
                  editTextTemplate(
                    "Email",
                    _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const Divider(),
                  const Text(
                    "Address Information",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                                    const SizedBox(height: 10),
                      if (_regions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        DropdownButtonFormField<String>(
                          value: (_selectedRegion != null && _regions.any((r) => r['code'].toString() == _selectedRegion.toString())) ? _selectedRegion.toString() : null,
                          decoration: const InputDecoration(labelText: 'Region', border: OutlineInputBorder()),
                          items: _regions.fold<List<dynamic>>([], (list, item) {
                            if (!list.any((e) => e['code'].toString() == item['code'].toString())) list.add(item);
                            return list;
                          }).map((r) => DropdownMenuItem(value: r['code'].toString(), child: Text(r['name']))).toList(),
                          onChanged: (val) {
                            setModalState(() => _selectedRegion = val);
                            if (val != null) {
                              _fetchProvinces(val).then((_) {
                                setModalState(() {});
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: (_selectedProvince != null && _provinces.any((p) => p['code'].toString() == _selectedProvince.toString())) ? _selectedProvince.toString() : null,
                          decoration: const InputDecoration(labelText: 'Province', border: OutlineInputBorder()),
                          items: _provinces.fold<List<dynamic>>([], (list, item) {
                            if (!list.any((e) => e['code'].toString() == item['code'].toString())) list.add(item);
                            return list;
                          }).map((p) => DropdownMenuItem(value: p['code'].toString(), child: Text(p['name']))).toList(),
                          onChanged: (val) {
                            setModalState(() => _selectedProvince = val);
                            if (val != null) {
                              _fetchCities(val).then((_) {
                                setModalState(() {});
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: (_selectedCity != null && _cities.any((c) => c['code'].toString() == _selectedCity.toString())) ? _selectedCity.toString() : null,
                          decoration: const InputDecoration(labelText: 'City/Municipality', border: OutlineInputBorder()),
                          items: _cities.fold<List<dynamic>>([], (list, item) {
                            if (!list.any((e) => e['code'].toString() == item['code'].toString())) list.add(item);
                            return list;
                          }).map((c) => DropdownMenuItem(value: c['code'].toString(), child: Text(c['name']))).toList(),
                          onChanged: (val) {
                            setModalState(() => _selectedCity = val);
                            if (val != null) {
                              _fetchBarangays(val).then((_) {
                                setModalState(() {});
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: (_selectedBarangay != null && _barangays.any((b) => b['code'].toString() == _selectedBarangay.toString())) ? _selectedBarangay.toString() : null,
                          decoration: const InputDecoration(labelText: 'Barangay', border: OutlineInputBorder()),
                          items: _barangays.fold<List<dynamic>>([], (list, item) {
                            if (!list.any((e) => e['code'].toString() == item['code'].toString())) list.add(item);
                            return list;
                          }).map((b) => DropdownMenuItem(value: b['code'].toString(), child: Text(b['name']))).toList(),
                          onChanged: (val) => setModalState(() => _selectedBarangay = val),
                        ),
                      ],
                   const SizedBox(height: 10),
                  editTextTemplate("Street/Address Details", _streetController),
                  const Divider(),
                  const Text(
                    "Identification",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: (_idTypeController.text.isNotEmpty && _idTypes.contains(_idTypeController.text)) ? _idTypeController.text : null,
                    decoration: const InputDecoration(labelText: 'ID Type', border: OutlineInputBorder()),
                    items: _idTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (val) {
                      setModalState(() => _idTypeController.text = val ?? '');
                    },
                  ),
                  const SizedBox(height: 10),
                  editTextTemplate("ID Number", _idNumberController),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload ID Photo"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                _updateProfile();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
            );
          },
        );
      },
    );
  }

  Widget editTextTemplate(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  String _getNameByCode(List<dynamic> list, dynamic code) {
    if (code == null) return '';
    final String codeStr = code.toString();
    final item = list.firstWhere((element) => element['code'].toString() == codeStr, orElse: () => null);
    return item != null ? item['name'].toString() : codeStr;
  }

  @override
  Widget build(BuildContext context) {
    return backgroundRed(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: myAppBar('Setting'),
        drawer: AppDrawer(
          firstName: widget.firstName,
          playerId: widget.playerId,
        ),
        body: SafeArea(
          bottom: false,
          child: WhiteContainer(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _navButton('Profile', '/setting'),
                            _navButton('Wallet', '/wallet'),
                            _navButton('Security', '/security'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFD66D6D), Color(0xFF912A2A)],
                            ),
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: InkWell(
                                  onTap: () => showModalProfile(context),
                                  child: const Icon(
                                    Icons.edit_document,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                ),
                              ),
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: const Color(0xFFFFD152),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: (_profileData?['picture'] != null && _profileData!['picture'].isNotEmpty)
                                      ? NetworkImage(_profileData!['picture'])
                                      : null,
                                  child: (_profileData?['picture'] == null || _profileData!['picture'].isEmpty)
                                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "${_profileData?['first_name'] ?? ''} ${_profileData?['last_name'] ?? ''}".trim().isEmpty 
                                   ? (widget.firstName ?? "User") 
                                   : "${_profileData?['first_name'] ?? ''} ${_profileData?['last_name'] ?? ''}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Divider(color: Colors.white24, height: 1),
                              ),
                              if ((_profileData?['contact_num'] ?? "").isNotEmpty)
                                infoRow("Mobile Number", _profileData?['contact_num'] ?? ""),
                              if ((_profileData?['email'] ?? "").isNotEmpty)
                                infoRow("Email", _profileData?['email'] ?? ""),
                              if ((_profileData?['region_code'] ?? "").isNotEmpty)
                                infoRow("Region", _getNameByCode(_regions, _profileData?['region_code'])),
                              if ((_profileData?['provincial_code'] ?? "").isNotEmpty)
                                infoRow("Province", _getNameByCode(_provinces, _profileData?['provincial_code'])),
                              if ((_profileData?['city_code'] ?? "").isNotEmpty)
                                infoRow("City", _getNameByCode(_cities, _profileData?['city_code'])),
                              if ((_profileData?['barangay_code'] ?? "").isNotEmpty)
                                infoRow("Barangay", _getNameByCode(_barangays, _profileData?['barangay_code'])),
                              if ((_profileData?['address'] ?? "").isNotEmpty)
                                infoRow("Address", _profileData?['address'] ?? ""),
                              if ((_profileData?['id_code'] ?? "").isNotEmpty)
                                infoRow("ID Type", _profileData?['id_code'] ?? ""),
                              if ((_profileData?['id_number'] ?? "").isNotEmpty)
                                infoRow("ID Number", _profileData?['id_number'] ?? ""),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(String label, String route) {
    final bool isCurrent = ModalRoute.of(context)?.settings.name == route;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton(
        onPressed: isCurrent
            ? null
            : () {
                Navigator.pop(context);
                Navigator.pushNamed(context, route, arguments: {
                  'firstName': widget.firstName,
                  'playerId': widget.playerId,
                });
              },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: isCurrent ? Colors.red : Colors.black87,
          side: isCurrent ? const BorderSide(color: Colors.red) : null,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              "$label:",
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
