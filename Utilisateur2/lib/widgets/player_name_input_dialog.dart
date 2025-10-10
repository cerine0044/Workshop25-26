import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/player_name_service.dart';

/// Widget pour la saisie du nom du joueur
class PlayerNameInputDialog extends StatefulWidget {
  final String? currentName;
  final bool isRequired;

  const PlayerNameInputDialog({
    super.key,
    this.currentName,
    this.isRequired = true,
  });

  @override
  State<PlayerNameInputDialog> createState() => _PlayerNameInputDialogState();
}

class _PlayerNameInputDialogState extends State<PlayerNameInputDialog> {
  final TextEditingController _nameController = TextEditingController();
  final PlayerNameService _playerNameService = PlayerNameService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.person,
            color: Colors.deepPurple,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Nom du Joueur',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entrez votre nom pour personnaliser votre expérience de jeu :',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          // Champ de saisie
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nom du joueur',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: 'Ex: Alex, Marie, Gamer123...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.deepPurple,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
            ),
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
            ],
            onChanged: (value) {
              setState(() {
                _errorMessage = null;
              });
            },
            onSubmitted: (value) {
              _savePlayerName();
            },
          ),
          
          // Message d'erreur
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Suggestions de noms
          const Text(
            'Suggestions :',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _playerNameService.getSuggestedNames().map((name) {
              return GestureDetector(
                onTap: () {
                  _nameController.text = name;
                  setState(() {
                    _errorMessage = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        // Bouton Annuler
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Annuler',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        
        // Bouton Sauvegarder
        ElevatedButton(
          onPressed: _isLoading ? null : _savePlayerName,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Sauvegarder'),
        ),
      ],
    );
  }

  Future<void> _savePlayerName() async {
    final name = _nameController.text.trim();
    
    if (!_playerNameService.isValidPlayerName(name)) {
      setState(() {
        if (name.isEmpty) {
          _errorMessage = 'Le nom ne peut pas être vide';
        } else if (name.length < 2) {
          _errorMessage = 'Le nom doit contenir au moins 2 caractères';
        } else if (name.length > 20) {
          _errorMessage = 'Le nom ne peut pas dépasser 20 caractères';
        }
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _playerNameService.setPlayerName(name);
      
      if (success) {
        HapticFeedback.lightImpact();
        if (mounted) {
          Navigator.of(context).pop(name);
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de la sauvegarde du nom';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur inattendue: $e';
        _isLoading = false;
      });
    }
  }
}
