import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _emailController = TextEditingController();
  final _birthDateDisplayController = TextEditingController();
  DateTime? _birthDate;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _lastCheckedUsername;
  String? _usernameCheckError;

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_handleUsernameFocusChange);
    _usernameController.addListener(_handleUsernameChanged);
  }

  @override
  void dispose() {
    _usernameFocusNode.removeListener(_handleUsernameFocusChange);
    _usernameController.removeListener(_handleUsernameChanged);
    _nameController.dispose();
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    _emailController.dispose();
    _birthDateDisplayController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _hasUpperCase(String value) {
    return value.contains(RegExp(r'[A-Z]'));
  }

  bool _hasSpecialChar(String value) {
    return value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  int _ageInYears(DateTime birth, DateTime today) {
    var age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? now.subtract(const Duration(days: 365 * 18));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
        _birthDateDisplayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String _normalizeUsername(String value) {
    return value.trim().replaceAll('@', '').replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  void _handleUsernameChanged() {
    final normalized = _normalizeUsername(_usernameController.text);
    if (_lastCheckedUsername == null) return;
    if (normalized != _lastCheckedUsername) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameCheckError = null;
      });
    }
  }

  void _handleUsernameFocusChange() {
    if (!_usernameFocusNode.hasFocus) {
      _checkUsernameAvailability();
    }
  }

  Future<bool?> _checkUsernameAvailability() async {
    final normalized = _normalizeUsername(_usernameController.text);
    final isValidForLookup =
        normalized.length >= 3 && RegExp(r'^[a-z0-9._]+$').hasMatch(normalized);

    if (!isValidForLookup) {
      if (!mounted) return false;
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _lastCheckedUsername = null;
        _usernameCheckError = null;
      });
      return null;
    }

    if (_lastCheckedUsername == normalized && _isUsernameAvailable != null) {
      return _isUsernameAvailable!;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        _isCheckingUsername = true;
      });
    }

    try {
      final available = await authProvider.isUsernameAvailable(normalized);
      if (!mounted) return available;
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = available;
        _lastCheckedUsername = normalized;
        _usernameCheckError = null;
      });
      _formKey.currentState?.validate();
      return available;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _lastCheckedUsername = normalized;
        _usernameCheckError = 'Não foi possível verificar o @ agora.';
      });
      return null;
    }
  }

  void _handleCreateAccount() async {
    if (_formKey.currentState!.validate() && _acceptedTerms) {
      final usernameAvailable = await _checkUsernameAvailability();
      if (!mounted) return;
      if (usernameAvailable == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível validar o @ agora. Verifique sua conexão e tente novamente.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (!usernameAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esse @ já está em uso. Escolha outro username.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final normalizedUsername = _normalizeUsername(_usernameController.text);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.createAccountInFirebase(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        username: normalizedUsername,
        birthDate: _birthDate!,
      );

      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Erro ao criar conta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa aceitar os termos de uso'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://www.gimie.site/privacy');
    try {
      final openedExternal = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (openedExternal) return;

      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a política de privacidade'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final h = MediaQuery.sizeOf(context).height;
    final titleSize = h < 600 ? 26.0 : 32.0;
    final topGap = h < 600 ? 20.0 : 32.0;
    final beforeSubmitGap = h < 600 ? 24.0 : 32.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B2C5C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Criar Conta',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: titleSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B2C5C),
                          ),
                        ),
                      ),
                      SizedBox(height: topGap),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '@ no app',
                    prefixIcon: Icon(Icons.alternate_email),
                    hintText: 'ex: brunaalvares',
                  ),
                  validator: (value) {
                    final normalized = _normalizeUsername(value ?? '');
                    if (normalized.isEmpty) {
                      return 'Por favor, insira seu @';
                    }
                    if (normalized.length < 3) {
                      return 'Seu @ deve ter pelo menos 3 caracteres';
                    }
                    if (!RegExp(r'^[a-z0-9._]+$').hasMatch(normalized)) {
                      return 'Use apenas letras, números, ponto ou underscore';
                    }
                    if (_isUsernameAvailable == false &&
                        normalized == _lastCheckedUsername) {
                      return 'Esse @ já está em uso';
                    }
                    return null;
                  },
                ),
                if (_isCheckingUsername)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Verificando disponibilidade do @...',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_usernameCheckError != null &&
                    _lastCheckedUsername == _normalizeUsername(_usernameController.text))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _usernameCheckError!,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  )
                else if (_isUsernameAvailable != null &&
                    _lastCheckedUsername == _normalizeUsername(_usernameController.text))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _isUsernameAvailable!
                          ? '@ disponível'
                          : '@ já está em uso',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: _isUsernameAvailable! ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthDateDisplayController,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  decoration: InputDecoration(
                    labelText: 'Data de nascimento',
                    hintText: 'Toque para escolher',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixIcon: _birthDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _birthDate = null;
                                _birthDateDisplayController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  validator: (_) {
                    if (_birthDate == null) {
                      return 'Selecione sua data de nascimento';
                    }
                    final today = DateTime.now();
                    if (_birthDate!.isAfter(today)) {
                      return 'Data inválida';
                    }
                    if (_ageInYears(_birthDate!, today) < 13) {
                      return 'É necessário ter pelo menos 13 anos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    if (!_hasUpperCase(value)) {
                      return 'A senha deve conter pelo menos uma letra maiúscula';
                    }
                    if (!_hasSpecialChar(value)) {
                      return 'A senha deve conter pelo menos um caractere especial';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirme sua senha';
                    }
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF8B7FB8),
                    ),
                    Expanded(
                      child: Wrap(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _acceptedTerms = !_acceptedTerms;
                              });
                            },
                            child: const Text(
                              'Eu aceito os termos de uso e ',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _openPrivacyPolicy,
                            child: const Text(
                              'política de privacidade',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B2C5C),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: beforeSubmitGap),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleCreateAccount,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Criar Conta'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
          },
        ),
      ),
    );
  }
}
