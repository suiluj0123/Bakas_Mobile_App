import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/api_config.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'services/id_validation_service.dart';

class GlassRegisterUI extends StatefulWidget {
  const GlassRegisterUI({super.key});
  @override
  State<GlassRegisterUI> createState() => _GlassRegisterUIState();
}

class _GlassRegisterUIState extends State<GlassRegisterUI> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  final Map<String, String?> _fieldErrors = {};

  XFile? _idXFile;
  Uint8List? _idBytes;
  IdValidationResult? _validationResult;
  XFile? _selfieXFile;
  Uint8List? _selfieBytes;
  final _idValidationService = IdValidationService();
  final _picker = ImagePicker();

  String? _selectedIdType;
  final List<String> _idTypes = [
    'UMID',
    'PhilID (National ID)',
    "Driver's License",
    'Passport',
    'Postal ID',
    "Voter's ID",
    'Senior Citizen ID',
  ];


  Future<void> _handleRegister() async {
    setState(() {
      _errorText = null;
      _fieldErrors.clear();
      _isLoading = true;
    });
    try {
      final fn = _firstNameController.text.trim();
      final ln = _lastNameController.text.trim();
      final em = _emailController.text.trim();
      final bd = _birthdateController.text.trim();
      final pw = _passwordController.text;
      final cpw = _confirmController.text;

      if (pw != cpw) {
        setState(() {
          _fieldErrors['confirm'] = 'Passwords do not match.';
          _isLoading = false;
        });
        return;
      }

      if (_selectedIdType == null) {
        setState(() {
          _fieldErrors['idType'] = 'Please select a government ID type.';
          _isLoading = false;
        });
        return;
      }

      bool hasError = false;
      void checkEmpty(String val, String key, String msg) {
        if (val.isEmpty) {
          _fieldErrors[key] = msg;
          hasError = true;
        }
      }

      checkEmpty(fn, 'firstName', 'First name is required.');
      checkEmpty(ln, 'lastName', 'Last name is required.');
      checkEmpty(em, 'email', 'Email is required.');
      checkEmpty(bd, 'birthday', 'Birthday is required.');
      checkEmpty(pw, 'password', 'Password is required.');

      if (hasError) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_idBytes == null) {
        setState(() {
          _errorText = 'Please upload a valid PH Government ID.';
          _isLoading = false;
        });
        return;
      }

      if (_selfieBytes == null) {
        setState(() {
          _errorText = 'Please upload a selfie holding your ID.';
          _isLoading = false;
        });
        return;
      }

      if (!em.contains('@')) {
        setState(() {
          _fieldErrors['email'] = 'Please enter a valid email.';
          _isLoading = false;
        });
        return;
      }
        final uri = Uri.parse('${ApiConfig.baseUrl}/register');
        final request = http.MultipartRequest('POST', uri);

        request.fields['first_name'] = fn;
        request.fields['last_name'] = ln;
        request.fields['email'] = em;
        request.fields['birthdate'] = bd;
        request.fields['password'] = pw;
        request.fields['id_code'] = _selectedIdType ?? 'PH Government ID';

        if (_idBytes != null && _idXFile != null) {
          final fileName = _idXFile!.name.toLowerCase();
          MediaType contentType;
          if (fileName.endsWith('.png')) {
            contentType = MediaType('image', 'png');
          } else if (fileName.endsWith('.webp')) {
            contentType = MediaType('image', 'webp');
          } else {
            contentType = MediaType('image', 'jpeg'); 
          }

          final multipartFile = http.MultipartFile.fromBytes(
            'id_photo',
            _idBytes!,
            filename: _idXFile!.name,
            contentType: contentType,
          );
          request.files.add(multipartFile);
        }

        if (_selfieBytes != null && _selfieXFile != null) {
          final fileName = _selfieXFile!.name.toLowerCase();
          MediaType contentType;
          if (fileName.endsWith('.png')) {
            contentType = MediaType('image', 'png');
          } else if (fileName.endsWith('.webp')) {
            contentType = MediaType('image', 'webp');
          } else {
            contentType = MediaType('image', 'jpeg');
          }

          final multipartFile = http.MultipartFile.fromBytes(
            'selfie_photo',
            _selfieBytes!,
            filename: _selfieXFile!.name,
            contentType: contentType,
          );
          request.files.add(multipartFile);
        }

        final streamedResponse = await request.send();
        final res = await http.Response.fromStream(streamedResponse);

        final Map<String, dynamic> payload =
            (res.body.isNotEmpty ? (jsonDecode(res.body) as Map<String, dynamic>) : <String, dynamic>{});
        
        if (res.statusCode == 200 && payload['ok'] == true) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        setState(() {
          _errorText = (payload['message'] is String)
              ? payload['message'] as String
              : 'Registration failed.';
        });
      } catch (_) {
      setState(() {
        _errorText = 'Could not connect to server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthdateController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _idValidationService.dispose();
    super.dispose();
  }

  Future<void> _pickIdImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
          _errorText = null;
        });

        final bytes = await pickedFile.readAsBytes();
 
        IdValidationResult result = IdValidationResult(
          isValid: true, 
          message: "ID uploaded successfully",
          idType: _selectedIdType ?? "PH Government ID"
        );
     

        setState(() {
          _idXFile = pickedFile;
          _idBytes = bytes;
          _validationResult = result;
          _isLoading = false;
          if (!result.isValid) {
            _errorText = result.message;
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = "Error picking image: $e";
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.of(context).pop();
                _pickIdImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickIdImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSelfieImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
          _errorText = null;
        });

        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _selfieXFile = pickedFile;
          _selfieBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = "Error picking selfie: $e";
      });
    }
  }

  void _showSelfieSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.of(context).pop();
                _pickSelfieImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickSelfieImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      _birthdateController.text = picked.toIso8601String().split('T').first;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                color: const Color.fromARGB(255, 140, 0, 0),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: width * 0.9,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: Colors.grey.withOpacity(0.25)),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Let's Get Started",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Color.fromARGB(255, 148, 1, 1),
                            ),
                          ),
                          const SizedBox(height: 22),
                          GlassInput(
                            hint: "First Name",
                            icon: Icons.person_outline,
                            controller: _firstNameController,
                            errorText: _fieldErrors['firstName'],
                          ),
                          const SizedBox(height: 14),
                          GlassInput(
                            hint: "Last Name",
                            icon: Icons.person_2_outlined,
                            controller: _lastNameController,
                            errorText: _fieldErrors['lastName'],
                          ),
                          const SizedBox(height: 14),
                           GlassInput(
                            hint: "Email",
                            icon: Icons.email_outlined,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _fieldErrors['email'],
                          ),
                          const SizedBox(height: 14),
                          GlassInput(
                            hint: "Birthday",
                            icon: Icons.cake,
                            controller: _birthdateController,
                            readOnly: true,
                            onTap: _pickBirthdate,
                            errorText: _fieldErrors['birthday'],
                          ),
                          const SizedBox(height: 14),
                          GlassInput(
                            hint: "Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            controller: _passwordController,
                            errorText: _fieldErrors['password'],
                          ),
                          const SizedBox(height: 14),
                          GlassInput(
                            hint: "Confirm password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            controller: _confirmController,
                            errorText: _fieldErrors['confirm'],
                          ),
                          const SizedBox(height: 14),
                          // ID Type Selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: _fieldErrors['idType'] != null ? Colors.red.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: Text("Select ID Type", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                                value: _selectedIdType,
                                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700),
                                items: _idTypes.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type, style: const TextStyle(fontSize: 15)),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedIdType = newValue;
                                    _fieldErrors['idType'] = null;
                                  });
                                },
                              ),
                            ),
                          ),
                          if (_fieldErrors['idType'] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 4),
                              child: Text(
                                _fieldErrors['idType']!,
                                style: const TextStyle(color: Color.fromARGB(255, 120, 0, 0), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          const SizedBox(height: 18),
                          _buildIdUploadSection(),
                          const SizedBox(height: 18),
                          _buildSelfieUploadSection(),
                          const SizedBox(height: 14),
                          if (_errorText != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _errorText!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 140, 0, 0),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 150,
                            height: 35,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 140, 0, 0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      "Sign Up",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            "PH Government ID Photo",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 100, 100, 100),
            ),
          ),
        ),
        GestureDetector(
          onTap: _showImageSourceActionSheet,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _validationResult != null
                    ? (_validationResult!.isValid ? Colors.green : Colors.red)
                    : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: _idBytes != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          _idBytes!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      const Center(
                        child: Icon(Icons.edit, color: Colors.white, size: 30),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _idXFile = null;
                              _idBytes = null;
                              _validationResult = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "Tap to upload ID",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
          ),
        ),
        if (_idBytes != null && _validationResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 8.0),
            child: Row(
              children: [
                Icon(
                  _validationResult!.isValid ? Icons.check_circle : Icons.error,
                  color: _validationResult!.isValid ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _validationResult!.message,
                    style: TextStyle(
                      color: _validationResult!.isValid ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSelfieUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            "Selfie holding your ID",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 100, 100, 100),
            ),
          ),
        ),
        GestureDetector(
          onTap: _showSelfieSourceActionSheet,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selfieBytes != null ? Colors.green : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: _selfieBytes != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          _selfieBytes!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      const Center(
                        child: Icon(Icons.edit, color: Colors.white, size: 30),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selfieXFile = null;
                              _selfieBytes = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.face_retouching_natural_outlined, color: Colors.grey, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "Tap to take/upload selfie",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class GlassInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? errorText;

  const GlassInput({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.errorText,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.errorText != null ? Colors.red.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: TextField(
            obscureText: widget.isPassword ? _obscureText : false,
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(widget.icon, color: Colors.grey.shade700),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              border: InputBorder.none,
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Color.fromARGB(255, 120, 0, 0), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
