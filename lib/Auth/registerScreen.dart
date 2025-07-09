

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_tracking_app/Auth/LoginScreen.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formSignUpKey = GlobalKey<FormState>();
  final TextEditingController _nameSurnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _truePassController = TextEditingController();

  bool _isPasswordVisible1 = false;
  bool _isPasswordVisible2 = false;
  bool confirmation = false;
  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _checkIfUserExists(String email) async {
    final QuerySnapshot emailSnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    return emailSnapshot.docs.isNotEmpty;
  }

  void _register() async {
    setState(() {
      // Onay kontrolü
      if (!confirmation) {
        _errorMessage = "Devam etmek için lütfen şartları kabul edin";
      } else {
        _errorMessage = null;
      }
    });

    // Form doğrulama
    if (_formSignUpKey.currentState!.validate() && confirmation) {
      setState(() {
        _isLoading = true;
      });

      String nameSurname = _nameSurnameController.text;
      String email = _emailController.text;
      String password = _passwordController.text;
      String confirmPassword = _truePassController.text;

      // Şifrelerin eşleşip eşleşmediğini kontrol et
      if (password != confirmPassword) {
        _showErrorDialog('Şifreler eşleşmiyor. Lütfen kontrol edip tekrar deneyiniz.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        // Kullanıcının zaten var olup olmadığını kontrol et
        bool userExists = await _checkIfUserExists(email);

        if (userExists) {
          _showErrorDialog('Bu e-posta adresi zaten kullanılıyor.');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // E-posta ve şifre ile kullanıcı oluştur
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Temel bilgilerle başlangıç UserModel oluştur
        UserModel newUser = UserModel(
          userId: userCredential.user!.uid,
          nameSurname: nameSurname,
          email: email,
          gender: '', // Profil tamamlamada ayarlanacak
          height: 0.0, // Profil tamamlamada ayarlanacak
          weight: 0.0, // Profil tamamlamada ayarlanacak
          poseErrors: [],
          likedForms: [],
          myForms: [],
          followers: [],
          following: [],
        );

        // Kullanıcıyı Firestore'a kaydet
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toJson());


        // Başarı diyaloğu göster
        _showSuccessDialog();
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Kayıt başarısız';

        if (e.code == 'weak-password') {
          errorMessage = 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Bu e-posta adresi zaten kullanılıyor.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Geçersiz e-posta adresi.';
        }

        _showErrorDialog(errorMessage);
      } catch (e) {
        _showErrorDialog('Bir hata oluştu. Lütfen tekrar deneyiniz.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Hata',
      desc: message,
      btnOkOnPress: () {},
      btnOkColor: Colors.redAccent,
      btnOkText: 'Tamam',
    ).show();
  }

  void _showSuccessDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.bottomSlide,
      dismissOnTouchOutside: false,
      title: 'Kayıt Başarılı',
      btnOkText: 'Giriş Yap',
      btnOkColor: Color(0xFF5046E5),
      btnOkOnPress: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
        );
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    final horizontalPadding = screenWidth * 0.06;
    final verticalPadding = screenHeight * 0.02;
    final inputHeight = screenHeight * 0.07;

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Hesap oluşturma başlığı ile dekoratif başlık
                Container(
                  margin: EdgeInsets.only(top: screenHeight * 0.02),
                  height: screenHeight * 0.2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF5046E5),
                        Color(0xFF6E8FFD),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF5046E5).withOpacity(0.2),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Dekoratif daireler
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: screenWidth * 0.25,
                          height: screenWidth * 0.25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -10,
                        child: Container(
                          width: screenWidth * 0.2,
                          height: screenWidth * 0.2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                      ),
                      Positioned(
                        top: screenHeight * 0.06,
                        right: screenWidth * 0.1,
                        child: Container(
                          width: screenWidth * 0.12,
                          height: screenWidth * 0.12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),

                      // İçerik
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hesap Oluştur',
                              style: TextStyle(
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Fitness yolculuğuna bugün başla',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.white.withOpacity(0.85),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Küçük profil simgesi
                      Positioned(
                        top: 24,
                        right: 24,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.person_add_rounded,
                            color: Color(0xFF5046E5),
                            size: screenWidth * 0.06,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Form
                Form(
                  key: _formSignUpKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tam İsim etiketi
                      _buildFieldLabel('Tam İsim'),

                      // İsim & Soyisim alanı
                      _buildTextField(
                        controller: _nameSurnameController,
                        hint: 'Tam adınızı girin',
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen adınızı girin';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: verticalPadding * 1.2),

                      // E-posta etiketi
                      _buildFieldLabel('E-posta Adresi'),

                      // E-posta alanı
                      _buildTextField(
                        controller: _emailController,
                        hint: 'E-posta adresinizi girin',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty || !value.contains('@')) {
                            return 'Lütfen geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: verticalPadding * 1.2),

                      // Şifre etiketi
                      _buildFieldLabel('Şifre'),

                      // Şifre alanı
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Bir şifre oluşturun',
                        icon: Icons.lock_outline_rounded,
                        obscure: !_isPasswordVisible1,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen bir şifre girin';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalıdır';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible1 ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            color: Color(0xFF6B7280),
                            size: screenWidth * 0.05,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible1 = !_isPasswordVisible1;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: verticalPadding * 1.2),

                      // Şifre Onaylama etiketi
                      _buildFieldLabel('Şifre Onayı'),

                      // Şifre Onaylama alanı
                      _buildTextField(
                        controller: _truePassController,
                        hint: 'Şifrenizi onaylayın',
                        icon: Icons.lock_outline_rounded,
                        obscure: !_isPasswordVisible2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifrenizi onaylayın';
                          }
                          if (value != _passwordController.text) {
                            return 'Şifreler eşleşmiyor';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible2 ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            color: Color(0xFF6B7280),
                            size: screenWidth * 0.05,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible2 = !_isPasswordVisible2;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: verticalPadding * 2),

                      // Koşullar & Şartlar Onay Kutusu
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            confirmation = !confirmation;
                            if (confirmation) _errorMessage = null;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.015,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _errorMessage != null
                                  ? Colors.redAccent.withOpacity(0.7)
                                  : Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: screenWidth * 0.05,
                                height: screenWidth * 0.05,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: confirmation ? Color(0xFF5046E5) : Color(0xFFD1D5DB),
                                    width: 1.5,
                                  ),
                                  color: confirmation
                                      ? Color(0xFF5046E5)
                                      : Colors.white,
                                ),
                                child: confirmation
                                    ? Icon(
                                  Icons.check,
                                  size: screenWidth * 0.035,
                                  color: Colors.white,
                                )
                                    : null,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Text(
                                  "Kullanım Koşulları ve Gizlilik Politikasını kabul ediyorum",
                                  style: TextStyle(
                                    color: _errorMessage != null
                                        ? Colors.redAccent.withOpacity(0.9)
                                        : Color(0xFF6B7280),
                                    fontSize: screenWidth * 0.035,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Hata mesajı
                      if (_errorMessage != null)
                        Padding(
                          padding: EdgeInsets.only(top: 8.0, left: 12.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: screenWidth * 0.035,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),

                      SizedBox(height: verticalPadding * 2),

                      // Kayıt Düğmesi
                      Container(
                        width: double.infinity,
                        height: inputHeight,
                        decoration: BoxDecoration(
                          color: Color(0xFF5046E5),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF5046E5).withOpacity(0.25),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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
                            'KAYIT OL',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: verticalPadding * 1.5),

                // Giriş linki
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Zaten hesabınız var mı? ',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: screenWidth * 0.04,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            PageTransition(
                              type: PageTransitionType.leftToRight,
                              child: LoginPage(),
                              duration: const Duration(milliseconds: 400),
                            ),
                          );
                        },
                        child: Text(
                          'Giriş Yap',
                          style: TextStyle(
                            color: Color(0xFF5046E5),
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.04,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Alan etiketleri oluşturmak için yardımcı metod
  Widget _buildFieldLabel(String label) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: screenWidth * 0.038,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  // Tutarlı stil için özel metin alanı oluşturucu
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final inputHeight = screenHeight * 0.06;

    return Container(
      height: inputHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: Color(0xFF1F2937),
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Color(0xFF9CA3AF),
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(icon, color: Color(0xFF5046E5)),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16),
          errorStyle: TextStyle(
            color: Colors.redAccent,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}