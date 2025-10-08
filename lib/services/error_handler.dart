import 'package:flutter/material.dart';
import 'dart:async';

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final StreamController<String> _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  void handleError(String error, {bool showDialog = true}) {
    _errorController.add(error);
    
    if (showDialog) {
      // Afficher un message d'erreur et rediriger vers l'accueil
      _showErrorDialog(error);
    }
  }

  void _showErrorDialog(String error) {
    // Cette méthode sera appelée depuis le contexte de l'application
    // pour afficher le dialogue d'erreur
  }

  void dispose() {
    _errorController.close();
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(String error)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  String? _error;

  @override
  void initState() {
    super.initState();
    ErrorHandler().errorStream.listen((error) {
      if (mounted) {
        setState(() {
          _error = error;
        });
        _showErrorAndRedirect(error);
      }
    });
  }

  void _showErrorAndRedirect(String error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Erreur de Connexion'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Une erreur s\'est produite :\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Redémarrage automatique du serveur...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        );

        // Redémarrage automatique après 3 secondes
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
            _restartServer();
          }
        });
      }
    });
  }

  void _restartServer() {
    // Cette méthode déclenchera le redémarrage du serveur
    // via une API ou un mécanisme de communication
    print('🔄 Redémarrage automatique du serveur...');
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }
    
    return widget.child;
  }
}
