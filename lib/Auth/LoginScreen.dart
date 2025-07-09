
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_tracking_app/Auth/registerScreen.dart';
import 'package:fitness_tracking_app/BottomBar/mainScreen.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:fitness_tracking_app/Auth/profilCompletionScreen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final FirebaseFirestore? firestore;
  LoginPage({Key? key, this.title, this.firestore}) : super(key: key);
  final String? title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formSignInKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool rememberPassword = false;
  String? emailReset;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmailPassword();
  }

  void _loadUserEmailPassword() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var email = prefs.getString("email") ?? "";
      var password = prefs.getString("password") ?? "";
      var rememberMe = prefs.getBool("remember_me") ?? false;

      if (rememberMe) {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
          rememberPassword = rememberMe;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<bool> passwordResetWithMail({required String mail}) async {
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: mail)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: mail);
        return true;
      }
      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  void _login() async {
    if (_formSignInKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Remember password if selected
        if (rememberPassword) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', _emailController.text);
          await prefs.setString('password', _passwordController.text);
          await prefs.setBool('remember_me', rememberPassword);
        } else {
          // Clear saved credentials if not remembered
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('email');
          await prefs.remove('password');
          await prefs.setBool('remember_me', false);
        }

        // Get user info from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        UserModel user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);

        setState(() {
          _isLoading = false;
        });

        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          dismissOnTouchOutside: false,
          animType: AnimType.bottomSlide,
          title: 'Giriş Başarılı',
          desc: 'Tekrar hoşgeldiniz!',
          btnOkOnPress: () {
            if (user.height == 0.0 || user.weight == 0.0 || user.gender.isEmpty) {
              // Redirect to profile completion
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileCompletionScreen(user: user),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainScreen(user: user),
                ),
              );
            }
          },
          btnOkText: 'Devam',
          btnOkColor: Color(0xFF5046E5),
        ).show();
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Giriş başarısız';
        if (e.code == 'user-not-found') {
          errorMessage = 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Yanlış şifre girdiniz.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Geçersiz e-posta adresi.';
        }

        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.scale,
          title: 'Giriş Başarısız',
          desc: errorMessage,
          btnOkOnPress: () {},
          btnOkText: 'Tamam',
          btnOkColor: Colors.red[400],
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    final horizontalPadding = screenWidth * 0.06;
    final verticalPadding = screenHeight * 0.02;
    final inputHeight = screenHeight * 0.06;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.05),

                // App Logo Container
                Container(
                  margin: EdgeInsets.only(top: screenHeight * 0.02),
                  width: screenWidth * 0.22,
                  height: screenWidth * 0.22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF5046E5).withOpacity(0.15),
                        blurRadius: 15,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: screenWidth * 0.12,
                      color: Color(0xFF5046E5),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),


                Text(
                  'Tekrar Hoşgeldiniz!',
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Poppins',
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                Text(
                  'Fitness yolculuğunuza devam etmek için giriş yapın',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

                // Login Form
                Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E-posta',
                        style: TextStyle(
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                          fontFamily: 'Poppins',
                        ),
                      ),

                      SizedBox(height: 8),

                      Container(
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
                          controller: _emailController,
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: 'E-posta adresinizi girin',
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'Poppins',
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Color(0xFF5046E5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Lütfen e-posta adresinizi girin";
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: verticalPadding * 1.5),

                      Text(
                        'Şifre',
                        style: TextStyle(
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                          fontFamily: 'Poppins',
                        ),
                      ),

                      SizedBox(height: 8),

                      Container(
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
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Şifrenizi girin',
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'Poppins',
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(0xFF5046E5),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Color(0xFF6B7280),
                                size: screenWidth * 0.05,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Lütfen şifrenizi girin";
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: verticalPadding),

                      // Remember me & Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Remember me
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                rememberPassword = !rememberPassword;
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: screenWidth * 0.05,
                                  height: screenWidth * 0.05,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: rememberPassword ? Color(0xFF5046E5) : Color(0xFFD1D5DB),
                                      width: 1.5,
                                    ),
                                    color: rememberPassword ? Color(0xFF5046E5) : Colors.white,
                                  ),
                                  child: rememberPassword
                                      ? Icon(
                                    Icons.check,
                                    size: screenWidth * 0.035,
                                    color: Colors.white,
                                  )
                                      : null,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Beni hatırla',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: screenWidth * 0.035,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Forgot password
                          TextButton(
                            onPressed: () => _showForgotPasswordModal(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(10, 10),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Şifremi Unuttum?',
                              style: TextStyle(
                                color: Color(0xFF5046E5),
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: verticalPadding * 3),

                      // Login Button
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
                          onPressed: _isLoading ? null : _login,
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
                            'GİRİŞ YAP',
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

                SizedBox(height: screenHeight * 0.05),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hesabınız yok mu? ',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: screenWidth * 0.04,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: RegisterScreen(),
                            duration: const Duration(milliseconds: 400),
                          ),
                        );
                      },
                      child: Text(
                        'Kaydol',
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

                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Forgot password modal
  void _showForgotPasswordModal(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.06),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Şifre Sıfırlama',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFF6B7280),
                        size: screenWidth * 0.05,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Şifre sıfırlama bağlantısı almak için e-posta adresinizi girin',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: screenWidth * 0.04,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Email input label
              Text(
                'E-posta',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                  fontFamily: 'Poppins',
                ),
              ),

              SizedBox(height: 8),

              Container(
                height: screenHeight * 0.07,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: TextField(
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'E-posta adresinizi girin',
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'Poppins',
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Color(0xFF5046E5),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (mail) {
                    emailReset = mail;
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Container(
                width: double.infinity,
                height: screenHeight * 0.07,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    if (emailReset != null && emailReset!.isNotEmpty) {
                      bool success = await passwordResetWithMail(mail: emailReset!);
                      Navigator.pop(context);

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi'),
                            backgroundColor: Color(0xFF5046E5),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bu e-posta ile kayıtlı kullanıcı bulunamadı. Lütfen önce kaydolun.'),
                            backgroundColor: Colors.red[400],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'ŞİFREMİ SIFIRLA',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
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
    );
  }
}