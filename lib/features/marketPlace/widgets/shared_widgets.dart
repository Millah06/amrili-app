import 'package:everywhere/shared/widgets/net_image.dart';
import 'package:flutter/material.dart';
import '../../../constraints/vendor_theme.dart';

// ─── VNetworkImage ────────────────────────────────────────────────────────────
// Use this everywhere instead of Image.network

class VNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const VNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return fallback ?? _placeholder();
    return NetImage(
      url: url,
      width: width,
      height: height,
      fit: fit,
      errorChild: fallback ?? _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: VendorTheme.surfaceVariant,
    child: const Icon(Icons.image_outlined, color: VendorTheme.textMuted),
  );
}

// ─── VSurface ─────────────────────────────────────────────────────────────────

class VSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color color;
  final VoidCallback? onTap;

  const VSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color = VendorTheme.surface,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: child,
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }
    return container;
  }
}

// ─── VButton ──────────────────────────────────────────────────────────────────

class VButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Color color;
  final Color textColor;
  final double? width;
  final IconData? icon;

  const VButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.color = VendorTheme.primary,
    this.textColor = Colors.black,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: textColor, strokeWidth: 2),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ─── VSmallButton ─────────────────────────────────────────────────────────────

class VSmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const VSmallButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = VendorTheme.surfaceVariant,
    this.textColor = VendorTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── VStatusBadge ─────────────────────────────────────────────────────────────

class VStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const VStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── VTextField ───────────────────────────────────────────────────────────────

class VTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final Icon?  prefixIcon;
  final Widget ? suffixIcon;
  final bool obscure;
  final Function(String)? onChange;
  final Function()? onTap;
  final FormFieldValidator<String>? validator;
  final Widget? prefix;
  final TextCapitalization capitalization;

  const VTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.obscure = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChange,
    this.onTap,
    this.validator, this.prefix, this.capitalization = TextCapitalization.none
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 14),
      cursorColor: Colors.white,
      textCapitalization: capitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefix: prefix,
        labelStyle: const TextStyle(color: VendorTheme.textMuted),
        hintStyle: const TextStyle(color: VendorTheme.textMuted),
        filled: true,
        fillColor: VendorTheme.surface,
        prefixIconColor: Colors.white,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VendorTheme.primary, width: 1.5),
        ),
      ),
      onChanged: onChange,
      onTap: onTap,
      validator: validator,
    );
  }
}

// ─── VDropdown ────────────────────────────────────────────────────────────────

class VDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const VDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VendorTheme.divider),

      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          hint: Text(label,
              style: const TextStyle(color: VendorTheme.textMuted, fontSize: 14)),
          value: value,
          isExpanded: true,
          dropdownColor: VendorTheme.surface,
          style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 14),
          disabledHint: Text(label,
              style: const TextStyle(color: VendorTheme.textMuted, fontSize: 14)),
          items: enabled ? items : null,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

// ─── VEmptyState ──────────────────────────────────────────────────────────────

class VEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;
  final Color ? iconColor;

  const VEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButton,
    this.iconColor
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? VendorTheme.textMuted, size: 56),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: VendorTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: VendorTheme.textSecondary, fontSize: 13)),
            ],
            if (buttonLabel != null && onButton != null) ...[
              const SizedBox(height: 20),
              VButton(
                label: buttonLabel!,
                onTap: onButton,
                width: 180,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── VErrorState ──────────────────────────────────────────────────────────────

class VErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const VErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: VendorTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: VendorTheme.textSecondary)),
          const SizedBox(height: 16),
          VButton(label: 'Retry', onTap: onRetry, width: 120),
        ],
      ),
    );
  }
}

// ─── VSectionTitle ────────────────────────────────────────────────────────────

class VSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const VSectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

// ─── VStatChip ────────────────────────────────────────────────────────────────

class VStatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String? label;

  const VStatChip({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 3),
        Text(
          label != null ? '$value $label' : value,
          style: const TextStyle(
              color: VendorTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
