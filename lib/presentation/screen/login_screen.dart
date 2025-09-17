import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/api/ThreadApi.dart';
import '../../core/constants.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Hàm gọi API chung
  Future<void> _sendLoginRequest(Map<String, dynamic> payload) async {
    try {
      debugPrint("Payload gửi lên: ${jsonEncode(payload)}");

      final response = await http.post(
        Uri.parse("${AppConstants.baseUrl}auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _handleLoginSuccess(data);
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['detail'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      _showError("Lỗi kết nối: $e");
    }
  }

  /// Đăng nhập bằng Email + Password
  Future<void> loginWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = {
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
      };
      await _sendLoginRequest(payload);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Lấy Google ID Token
  Future<String?> _signInWithGoogleAccount() async {
    try {
      await _googleSignIn.signOut(); // clear session cũ
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      return googleAuth.idToken;
    } catch (e) {
      debugPrint("Lỗi đăng nhập Google: $e");
      return null;
    }
  }

  /// Đăng nhập bằng Google
  Future<void> loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final googleIdToken = await _signInWithGoogleAccount();
      if (googleIdToken == null || googleIdToken.isEmpty) {
        _showError("Đăng nhập Google thất bại");
        return;
      }

      // Gửi lên đúng endpoint /auth/google
      final response = await http.post(
        Uri.parse("${AppConstants.baseUrl}auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"googleIdToken": googleIdToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _handleLoginSuccess(data);
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['detail'] ?? "Đăng nhập Google thất bại");
      }
    } catch (e) {
      _showError("Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  /// Xử lý login thành công
  Future<void> _handleLoginSuccess(Map<String, dynamic> data) async {
    try {
      final token = data["access_token"];
      final user = (data["user"] as Map?) ?? {};
      final userName = user["name"]?.toString() ?? "";
      final userEmail = user["email"]?.toString() ?? "";
      final userAvatar = user["avatar"]?.toString() ?? "";

      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);
        await prefs.setString("user_name", userName);
        await prefs.setString("user_email", userEmail);
        await prefs.setString("user_avatar", userAvatar);

        // Tạo thread patient_dental
        try {
          final thread = await ThreadApi.createThread("Cuộc trò chuyện mới");
          if (thread.id != null) {
            await prefs.setString("thread_id", thread.id!);
            debugPrint("✅ Tạo thread patient_dental thành công: ${thread.id}");
          }
        } catch (e) {
          debugPrint("⚠️ Lỗi tạo thread: $e");
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.chat);
      } else {
        _showError("Không tìm thấy token trong response");
      }
    } catch (e) {
      _showError("Lỗi xử lý dữ liệu đăng nhập: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage("assets/logo_yd.png"),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "RHM Chatbot",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Đăng nhập vào tài khoản của bạn",
                    style: TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  /// Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  /// Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Mật khẩu",
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 24),

                  /// Nút đăng nhập Email
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : loginWithEmailPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.blue.shade300,
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
                          : const Text(
                        "Đăng nhập",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Nút đăng nhập Google
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGoogleLoading ? null : loginWithGoogle,
                      icon: _isGoogleLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Image.asset(
                        "assets/google_logo.png",
                        height: 20,
                        width: 20,
                      ),
                      label: Text(
                        _isGoogleLoading
                            ? "Đang đăng nhập..."
                            : "Đăng nhập bằng Google",
                        style: const TextStyle(color: Colors.black87),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black12),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
