import 'package:flutter/material.dart';
import 'package:luxe_cart_admin/theme/theme.dart';

class GoogleCard extends StatelessWidget {
  final String image;
  final String text;
  final Function()? onTap;
  const GoogleCard({
    super.key,
    required this.image,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: darkCharcoalSurface),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 20),
            SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
