// PageTransition provides a custom slide transition for navigation between pages.
import 'package:flutter/material.dart';

// Usage: Navigator.of(context).push(PageTransition(page: YourPage()));
class PageTransition extends PageRouteBuilder {
  final Widget page;
  PageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from right to left
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}
