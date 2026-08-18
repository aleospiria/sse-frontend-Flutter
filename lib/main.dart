import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
