import 'package:flutter/material.dart';
import 'package:luxe_cart_admin/theme/theme.dart';

class MyTextfield extends StatefulWidget {
  final IconData leading;
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final IconData? suffixIcon;

  const MyTextfield({
    super.key,
    required this.leading,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.suffixIcon,
  });

  @override
  State<MyTextfield> createState() => _MyTextfieldState();
}

class _MyTextfieldState extends State<MyTextfield> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured =
        widget.obscureText; // initial value from parent
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _isObscured,
      decoration: InputDecoration(
        prefixIcon: Icon(
          widget.leading,
          color: Theme.of(
            context,
          ).colorScheme.inversePrimary,
        ),

        hintText: widget.hintText,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,

        // eye icon appears ONLY if it's a password textfield
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Theme.of(
                    context,
                  ).colorScheme.inversePrimary,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : null,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: darkCharcoalSurface,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.inversePrimary,
          ),
        ),
      ),
    );
  }
}
