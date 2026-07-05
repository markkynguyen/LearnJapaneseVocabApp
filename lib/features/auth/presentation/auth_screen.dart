import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';

String friendlyAuthError(Object? error) {
  final rawMessage = error is AuthException
      ? error.message
      : error?.toString() ?? 'Đã xảy ra lỗi không xác định.';
  final message = rawMessage.toLowerCase();

  if ((message.contains('provider') &&
          (message.contains('disabled') ||
              message.contains('not enabled') ||
              message.contains('unsupported'))) ||
      message.contains('provider is not supported')) {
    return 'Đăng nhập Google chưa được bật. Vui lòng liên hệ quản trị viên.';
  }
  if (message.contains('redirect') || message.contains('callback')) {
    return 'Đường dẫn quay lại ứng dụng chưa đúng. Vui lòng liên hệ quản trị viên.';
  }
  if (message.contains('network') ||
      message.contains('connection') ||
      message.contains('socket') ||
      message.contains('failed to fetch') ||
      message.contains('clientexception')) {
    return 'Không thể kết nối đến máy chủ. Hãy kiểm tra mạng và thử lại.';
  }
  if (message.contains('launch') || message.contains('trình duyệt')) {
    return 'Không thể mở trình duyệt để đăng nhập bằng Google.';
  }
  return rawMessage.replaceFirst(RegExp(r'^(Exception|AuthException):\s*'), '');
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _register = false;
  bool _obscure = true;
  bool _googleLaunching = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.cloud_done_rounded,
                          size: 52,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _register
                              ? 'Tạo tài khoản Nana'
                              : 'Chào mừng trở lại',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dữ liệu học được lưu an toàn trên cloud và cần kết nối mạng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          key: const Key('google-auth-button'),
                          onPressed: auth.isLoading ? null : _signInWithGoogle,
                          icon: _googleLaunching
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/google_g.png',
                                  width: 20,
                                  height: 20,
                                ),
                          label: const Text('Tiếp tục với Google'),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'hoặc',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) => value != null &&
                                  value.contains('@') &&
                                  value.contains('.')
                              ? null
                              : 'Email không hợp lệ.',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => (value?.length ?? 0) >= 8
                              ? null
                              : 'Mật khẩu cần ít nhất 8 ký tự.',
                        ),
                        if (auth.hasError) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Không thể xác thực: ${friendlyAuthError(auth.error)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: auth.isLoading ? null : _submit,
                          child: auth.isLoading && !_googleLaunching
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_register ? 'Đăng ký' : 'Đăng nhập'),
                        ),
                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => setState(() => _register = !_register),
                          child: Text(
                            _register
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Chưa có tài khoản? Đăng ký',
                          ),
                        ),
                        if (!_register)
                          TextButton(
                            onPressed: auth.isLoading ? null : _forgotPassword,
                            child: const Text('Quên mật khẩu?'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLaunching = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } finally {
      if (mounted) setState(() => _googleLaunching = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_register) {
      final confirmation = await ref
          .read(authControllerProvider.notifier)
          .signUp(_email.text, _password.text);
      if (mounted && confirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hãy kiểm tra email để xác nhận tài khoản.'),
          ),
        );
      }
    } else {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(_email.text, _password.text);
    }
  }

  Future<void> _forgotPassword() async {
    if (!_email.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhập email trước khi yêu cầu đặt lại mật khẩu.'),
        ),
      );
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text);
    if (mounted && !ref.read(authControllerProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi liên kết đặt lại mật khẩu.')),
      );
    }
  }
}
