import 'package:flutter/material.dart';

/// Shared visual design for the auth screens (login / signup / forgot / reset),
/// from the "Let's get Started" design: dark wash with a purple top glow,
/// title-case heading + subtitle, focus-purple fields, a gradient CTA with an
/// arrow, an OR divider, side-by-side social buttons, and a pinned footer link.
class AuthColors {
  static const bg          = Color(0xFF0A0A0B);
  static const field       = Color(0xFF17151D);
  static const fieldBorder = Color(0xFF2A2733);
  static const purple      = Color(0xFF8A3DF0);
  static const purpleLight = Color(0xFFB06BFF);
  static const text        = Color(0xFFFFFFFF);
  static const sub         = Color(0xFFB6ABC8);
  static const hint        = Color(0xFF6E6780);
}

/// Page shell: dark gradient + purple top glow, optional back chevron, heading,
/// subtitle, the form [children], and a pinned [footer].
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;
  final VoidCallback? onBack;
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(fit: StackFit.expand, children: [
        // dark wash with purple haze up top
        const DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF100A18), Color(0xFF0A0A0B), Color(0xFF0C0911)], stops: [0.0, 0.4, 1.0]))),
        const Align(alignment: Alignment(0, -1.0), child: SizedBox(width: 460, height: 300,
          child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(radius: 0.7,
            colors: [Color(0x408A3DF0), Color(0x000C0A12)]))))),

        SafeArea(child: Column(children: [
          Expanded(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (onBack != null) ...[
                GestureDetector(onTap: onBack,
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: AuthColors.purpleLight, size: 22)),
                const SizedBox(height: 18),
              ] else const SizedBox(height: 6),
              Text(title, style: const TextStyle(color: AuthColors.text, fontSize: 38,
                fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.8)),
              const SizedBox(height: 10),
              Text(subtitle, style: const TextStyle(color: AuthColors.sub, fontSize: 16, height: 1.4)),
              const SizedBox(height: 30),
              ...children,
            ]),
          )),
          if (footer != null) Padding(padding: const EdgeInsets.only(bottom: 14, top: 6), child: footer!),
        ])),
      ]),
    );
  }
}

/// Dark rounded field; border turns purple on focus. [isPassword] adds the eye toggle.
class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onSubmitted,
  });
  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  final _focus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focus.requestFocus(),
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 58,
      decoration: BoxDecoration(
        color: AuthColors.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: focused ? AuthColors.purpleLight : AuthColors.fieldBorder, width: focused ? 1.5 : 1),
      ),
      child: Row(children: [
        const SizedBox(width: 18),
        Expanded(child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          obscureText: widget.isPassword && _obscure,
          style: const TextStyle(color: AuthColors.text, fontSize: 15),
          cursorColor: AuthColors.purpleLight,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AuthColors.hint, fontSize: 15),
            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
        )),
        if (widget.isPassword)
          GestureDetector(onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AuthColors.hint, size: 20)),
        const SizedBox(width: 18),
      ]),
    ));
  }
}

/// Gradient pill CTA with an optional trailing arrow and a loading state.
class AuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool showArrow;
  final VoidCallback? onTap;
  const AuthButton({super.key, required this.label, this.loading = false, this.showArrow = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 58, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [AuthColors.purpleLight, AuthColors.purple],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          boxShadow: const [BoxShadow(color: Color(0x73842BD2), blurRadius: 26, offset: Offset(0, 12))],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                if (showArrow) ...[const SizedBox(width: 9),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20)],
              ]),
      ),
    );
  }
}

/// The "—— OR ——" divider.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(color: AuthColors.fieldBorder.withValues(alpha: 0.7), thickness: 1)),
    const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text('OR', style: TextStyle(color: AuthColors.hint, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2))),
    Expanded(child: Divider(color: AuthColors.fieldBorder.withValues(alpha: 0.7), thickness: 1)),
  ]);
}

/// Dark rounded social button (icon + short label), sits side-by-side.
class AuthSocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  const AuthSocialButton({super.key, required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56,
      decoration: BoxDecoration(color: AuthColors.field, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthColors.fieldBorder, width: 1)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        icon, const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

/// Small white "G" Google glyph.
class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({super.key});
  @override
  Widget build(BuildContext context) => const Text('G',
    style: TextStyle(color: Color(0xFF4285F4), fontSize: 18, fontWeight: FontWeight.w800));
}

/// "Already have an account? Sign In"-style footer link.
class AuthFooterLink extends StatelessWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;
  const AuthFooterLink({super.key, required this.prefix, required this.action, required this.onTap});
  @override
  Widget build(BuildContext context) => Center(child: GestureDetector(
    onTap: onTap,
    child: Text.rich(TextSpan(children: [
      TextSpan(text: '$prefix ', style: const TextStyle(color: AuthColors.sub, fontSize: 14)),
      TextSpan(text: action, style: const TextStyle(color: AuthColors.purpleLight, fontSize: 14, fontWeight: FontWeight.w800)),
    ])),
  ));
}
