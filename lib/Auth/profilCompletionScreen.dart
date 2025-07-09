import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:fitness_tracking_app/BottomBar/mainScreen.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final UserModel user;

  const ProfileCompletionScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileCompletionScreenState createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _gender;
  late double _height;
  late double _weight;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Show initial information dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInformationDialog();
    });

    _gender = widget.user.gender;
    _height = widget.user.height;
    _weight = widget.user.weight;
  }

  void _showInformationDialog() {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF5046E5).withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF5046E5).withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Color(0xFF5046E5),
                    size: screenWidth * 0.1,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Please complete your profile to continue. You can update this information anytime from your profile settings.',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: screenWidth * 0.12,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5046E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateProfile() async {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      _formKey.currentState!.save();

      // Update user model
      UserModel updatedUser = widget.user.copyWith(
        gender: _gender,
        height: _height,
        weight: _weight,
      );

      try {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(updatedUser.userId)
            .update(updatedUser.toJson());

        // Show loading animation and then navigate directly to main screen
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Container(
              color: Colors.white,
              child: Center(
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  repeat: true,
                  onLoaded: (composition) {
                    // Navigate to main screen after a short delay
                    Future.delayed(Duration(milliseconds: 2500), () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainScreen(user: updatedUser),
                        ),
                      );
                    });
                  },
                ),
              ),
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating profile: $e',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(12),
          ),
        );
      }
    }
  }

  Widget _buildLoadingTransition(BuildContext context, Animation<double> animation, Widget child) {
    return Stack(
      children: [
        // Fade out the current screen
        FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(animation),
          child: child,
        ),
        // Loading overlay
        Container(
          color: Colors.white,
          child: Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Lottie.asset(
                'assets/animations/dumbell_loading.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                repeat: true,
                onLoaded: (composition) {
                  // Add a delay to show animation briefly, then proceed to main screen
                  Future.delayed(Duration(milliseconds: 2500), () {
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainScreen(user: widget.user),
                        ),
                      );
                    }
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Responsive values
    final horizontalPadding = screenWidth * 0.06;
    final verticalPadding = screenHeight * 0.02;
    final formPadding = screenWidth * 0.05;
    final inputHeight = screenHeight * 0.07;
    final spaceBetween = screenHeight * 0.025;

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: Color(0xFF5046E5),
              size: screenWidth * 0.04,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  margin: EdgeInsets.only(bottom: verticalPadding * 1.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: screenWidth * 0.075,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We need some information to personalize your experience',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

                // Illustration
                Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: verticalPadding * 1.5),
                    width: screenWidth * 0.5,
                    height: screenWidth * 0.5,
                    decoration: BoxDecoration(
                      color: Color(0xFF5046E5).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: screenWidth * 0.25,
                      color: Color(0xFF5046E5),
                    ),
                  ),
                ),

                // Form
                Container(
                  margin: EdgeInsets.only(top: verticalPadding, bottom: verticalPadding * 2),
                  padding: EdgeInsets.all(formPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Gender Dropdown
                        _buildFieldLabel('Gender'),
                        SizedBox(height: 8),
                        _buildDropdownField(
                          hint: 'Select your gender',
                          items: ['Male', 'Female', 'Other'],
                          value: _gender.isEmpty ? null : _gender,
                          onChanged: (value) {
                            setState(() {
                              _gender = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your gender';
                            }
                            return null;
                          },
                          height: inputHeight,
                        ),
                        SizedBox(height: spaceBetween),

                        // Height Input
                        _buildFieldLabel('Height (cm)'),
                        SizedBox(height: 8),
                        _buildNumberField(
                          initialValue: _height > 0 ? _height.toString() : '',
                          hintText: 'Enter your height',
                          height: inputHeight,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your height';
                            }
                            final height = double.tryParse(value);
                            if (height == null || height < 50 || height > 250) {
                              return 'Please enter a valid height (50-250 cm)';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _height = double.parse(value!);
                          },
                        ),
                        SizedBox(height: spaceBetween),

                        // Weight Input
                        _buildFieldLabel('Weight (kg)'),
                        SizedBox(height: 8),
                        _buildNumberField(
                          initialValue: _weight > 0 ? _weight.toString() : '',
                          hintText: 'Enter your weight',
                          height: inputHeight,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your weight';
                            }
                            final weight = double.tryParse(value);
                            if (weight == null || weight < 20 || weight > 300) {
                              return 'Please enter a valid weight (20-300 kg)';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _weight = double.parse(value!);
                          },
                        ),
                        SizedBox(height: spaceBetween * 1.5),

                        // Update Profile Button
                        Container(
                          height: inputHeight,
                          decoration: BoxDecoration(
                            color: Color(0xFF5046E5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF5046E5).withOpacity(0.25),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(
                              'COMPLETE PROFILE',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build field labels
  Widget _buildFieldLabel(String label) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Text(
      label,
      style: TextStyle(
        fontSize: screenWidth * 0.038,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
        fontFamily: 'Poppins',
      ),
    );
  }

  // Reusable dropdown field widget
  Widget _buildDropdownField({
    required String hint,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          hintStyle: TextStyle(
            color: Color(0xFF9CA3AF),
            fontFamily: 'Poppins',
          ),
        ),
        value: value,
        hint: Text(
          hint,
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontFamily: 'Poppins',
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
          ),
        ))
            .toList(),
        validator: validator,
        onChanged: onChanged,
        onSaved: onChanged,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF5046E5),
        ),
        isExpanded: true,
        dropdownColor: Colors.white,
      ),
    );
  }

  // Reusable number input field widget
  Widget _buildNumberField({
    required String initialValue,
    required String hintText,
    required double height,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Color(0xFF9CA3AF),
            fontFamily: 'Poppins',
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(
          color: Color(0xFF1F2937),
          fontFamily: 'Poppins',
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}