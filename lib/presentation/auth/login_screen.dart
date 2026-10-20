import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../state/auth_provider.dart';
import '../main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nikController = TextEditingController();
  final FocusNode _nikFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();

  String _pinCode = '';
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Kolom NIK dikosongkan tanpa autofill agar user menginput manual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nikFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nikController.dispose();
    _nikFocusNode.dispose();
    _keyboardFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberTap(String number) {
    if (_isLoading) return;

    if (_nikController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan NIK terlebih dahulu.';
      });
      _nikFocusNode.requestFocus();
      return;
    }

    if (_pinCode.length < 6) {
      setState(() {
        _errorMessage = null;
        _pinCode += number;
      });

      // Automatically verify when 6 digits are reached
      if (_pinCode.length == 6) {
        _executeLogin(_pinCode);
      }
    }
  }

  void _onBackspaceTap() {
    if (_isLoading) return;
    if (_pinCode.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _pinCode = _pinCode.substring(0, _pinCode.length - 1);
      });
    }
  }

  Future<void> _executeLogin(String pin) async {
    final nik = _nikController.text.trim();
    if (nik.isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan NIK terlebih dahulu.';
        _pinCode = '';
      });
      _nikFocusNode.requestFocus();
      return;
    }

    setState(() => _isLoading = true);

    final authProv = context.read<AuthProvider>();
    final success = await authProv.login(nik, pin);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainShell(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      } else {
        _shakeController.forward(from: 0.0);
        setState(() {
          _errorMessage = authProv.loginError ?? 'NIK atau PIN tidak sesuai.';
          _pinCode = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && !_nikFocusNode.hasFocus) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.digit0 ||
                key == LogicalKeyboardKey.numpad0) {
              _onNumberTap('0');
            } else if (key == LogicalKeyboardKey.digit1 ||
                key == LogicalKeyboardKey.numpad1) {
              _onNumberTap('1');
            } else if (key == LogicalKeyboardKey.digit2 ||
                key == LogicalKeyboardKey.numpad2) {
              _onNumberTap('2');
            } else if (key == LogicalKeyboardKey.digit3 ||
                key == LogicalKeyboardKey.numpad3) {
              _onNumberTap('3');
            } else if (key == LogicalKeyboardKey.digit4 ||
                key == LogicalKeyboardKey.numpad4) {
              _onNumberTap('4');
            } else if (key == LogicalKeyboardKey.digit5 ||
                key == LogicalKeyboardKey.numpad5) {
              _onNumberTap('5');
            } else if (key == LogicalKeyboardKey.digit6 ||
                key == LogicalKeyboardKey.numpad6) {
              _onNumberTap('6');
            } else if (key == LogicalKeyboardKey.digit7 ||
                key == LogicalKeyboardKey.numpad7) {
              _onNumberTap('7');
            } else if (key == LogicalKeyboardKey.digit8 ||
                key == LogicalKeyboardKey.numpad8) {
              _onNumberTap('8');
            } else if (key == LogicalKeyboardKey.digit9 ||
                key == LogicalKeyboardKey.numpad9) {
              _onNumberTap('9');
            } else if (key == LogicalKeyboardKey.backspace) {
              _onBackspaceTap();
            }
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Logo & Title
                    Container(
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/favicon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.lock_rounded,
                            size: 30,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TIRTAFIELD',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.3,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Masukkan NIK dan PIN untuk masuk ke sistem',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1. KOLOM UNTUK MEMASUKKAN NIK
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'NIK',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nikController,
                      focusNode: _nikFocusNode,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (val) {
                        setState(() {
                          if (_errorMessage != null) _errorMessage = null;
                        });
                      },
                      onFieldSubmitted: (_) {
                        _nikFocusNode.unfocus();
                        _keyboardFocusNode.requestFocus();
                      },
                      decoration: InputDecoration(
                        hintText: 'Masukkan NIK anda',
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        suffixIcon: _nikController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _nikController.clear();
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.secondaryContainer,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. PIN SECTION & 6 DOTS
                    const Text(
                      'PIN Keamanan (6 Digit)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Animated 6 PIN Dots
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: _buildPinDots(),
                    ),
                    const SizedBox(height: 12),

                    // Error Message or Loading State
                    if (_isLoading)
                      const SizedBox(
                        height: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.secondaryContainer,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Memverifikasi kredensial...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      const SizedBox(height: 16),

                    // 3. KEYBOARD NUMERIK (HANYA ANGKA 1-9, 0, & HAPUS)
                    _buildPureNumericKeypad(),

                    const SizedBox(height: 18),

                    // 4. AKSES CEPAT DEMO ROLE (Karyawan, Direktur, Superadmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'PILIH AKUN LOGIN CEPAT (DEMO):',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickLoginChip(
                                  label: 'Karyawan',
                                  nik: 'P001',
                                  color: AppColors.roleKaryawan,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildQuickLoginChip(
                                  label: 'Direktur',
                                  nik: 'D001',
                                  color: AppColors.roleDirektur,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildQuickLoginChip(
                                  label: 'Superadmin',
                                  nik: 'P242101',
                                  color: AppColors.roleStaffIT,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLoginChip({
    required String label,
    required String nik,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _nikController.text = nik;
          _pinCode = '123456';
          _errorMessage = null;
        });
        _executeLogin('123456');
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              nik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6 Pin Dots Indicator (Filled / Empty)
  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < _pinCode.length;
        final hasError = _errorMessage != null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 7),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? AppColors.error
                : isFilled
                    ? AppColors.primary
                    : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : isFilled
                      ? AppColors.primary
                      : AppColors.outlineVariant,
              width: 2,
            ),
            boxShadow: isFilled && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // KEYBOARD NUMERIK (Hanya Tertulis Angka Murni)
  Widget _buildPureNumericKeypad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Ruang kosong bersih di kiri bawah (tanpa fingerprint)
              const SizedBox(width: 68, height: 68),

              // Angka 0
              _buildNumberKey('0'),

              // Tombol Hapus (Backspace)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onBackspaceTap,
                  borderRadius: BorderRadius.circular(36),
                  child: const SizedBox(
                    width: 68,
                    height: 68,
                    child: Center(
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 24,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildNumberKey(digit)).toList(),
    );
  }

  // Tombol Angka Bulat (Hanya angka murni yang tertulis)
  Widget _buildNumberKey(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberTap(digit),
        borderRadius: BorderRadius.circular(36),
        splashColor: AppColors.secondaryContainer.withValues(alpha: 0.15),
        highlightColor: AppColors.surfaceContainer,
        child: Ink(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
