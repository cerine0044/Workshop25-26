import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'page4_tram.dart';

class Page3Crossword extends StatefulWidget {
  final Function(Map<String, dynamic>)? onComplete;
  
  const Page3Crossword({super.key, this.onComplete});

  @override
  State<Page3Crossword> createState() => _Page3CrosswordState();
}

class _Page3CrosswordState extends State<Page3Crossword> with SingleTickerProviderStateMixin {
  // Grille de mots fléchés (10x10)
  late List<List<String>> _grid;
  late List<List<bool>> _isEditable;
  
  // Mots RGPD à trouver
  final List<CrosswordWord> _words = [
    CrosswordWord(
      word: 'CONSENTEMENT',
      definition: 'Autorisation explicite donnée par l\'utilisateur',
      row: 1,
      col: 1,
      isHorizontal: true,
    ),
    CrosswordWord(
      word: 'DONNEES',
      definition: 'Informations collectées sur les personnes',
      row: 3,
      col: 0,
      isHorizontal: false,
    ),
    CrosswordWord(
      word: 'RGPD',
      definition: 'Règlement général sur la protection des données',
      row: 5,
      col: 2,
      isHorizontal: true,
    ),
    CrosswordWord(
      word: 'PRIVACY',
      definition: 'Vie privée en anglais',
      row: 2,
      col: 4,
      isHorizontal: false,
    ),
    CrosswordWord(
      word: 'CYBERSECURITE',
      definition: 'Protection des systèmes informatiques',
      row: 7,
      col: 0,
      isHorizontal: true,
    ),
    CrosswordWord(
      word: 'HARCELEMENT',
      definition: 'Comportement répétitif visant à nuire',
      row: 0,
      col: 6,
      isHorizontal: false,
    ),
    CrosswordWord(
      word: 'RESPECT',
      definition: 'Considération envers les autres',
      row: 4,
      col: 8,
      isHorizontal: true,
    ),
    CrosswordWord(
      word: 'ETHIQUE',
      definition: 'Ensemble de principes moraux',
      row: 6,
      col: 3,
      isHorizontal: false,
    ),
    CrosswordWord(
      word: 'TRANSPARENCE',
      definition: 'Qualité de ce qui est clair et visible',
      row: 8,
      col: 1,
      isHorizontal: true,
    ),
    CrosswordWord(
      word: 'DIGNITE',
      definition: 'Respect de la valeur humaine',
      row: 9,
      col: 5,
      isHorizontal: false,
    ),
  ];
  
  int _wordsFound = 0;
  String? _selectedDefinition;
  bool _gameComplete = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeGrid();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeGrid() {
    _grid = List.generate(10, (_) => List.filled(10, ''));
    _isEditable = List.generate(10, (_) => List.filled(10, false));
    
    // Placer les mots dans la grille
    for (final word in _words) {
      _placeWord(word);
    }
  }

  void _placeWord(CrosswordWord word) {
    for (int i = 0; i < word.word.length; i++) {
      int row = word.row + (word.isHorizontal ? 0 : i);
      int col = word.col + (word.isHorizontal ? i : 0);
      
      if (row < 10 && col < 10) {
        _isEditable[row][col] = true;
        // Ne pas pré-remplir, laisser l'utilisateur saisir
      }
    }
  }

  void _onCellTap(int row, int col) {
    if (!_isEditable[row][col] || _gameComplete) return;
    
    setState(() {
      // Effacer la cellule pour permettre la saisie
      _grid[row][col] = '';
    });
    
    // Afficher le clavier pour saisie
    _showInputDialog(row, col);
  }

  void _showInputDialog(int row, int col) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'Saisir une lettre',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          maxLength: 1,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            hintText: 'A-Z',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _grid[row][col] = value.toUpperCase();
              });
              Navigator.of(context).pop();
              _checkWords();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _checkWords() {
    int foundCount = 0;
    
    for (final word in _words) {
      bool wordComplete = true;
      String currentWord = '';
      
      for (int i = 0; i < word.word.length; i++) {
        int row = word.row + (word.isHorizontal ? 0 : i);
        int col = word.col + (word.isHorizontal ? i : 0);
        
        if (row < 10 && col < 10) {
          String cellValue = _grid[row][col];
          if (cellValue.isEmpty) {
            wordComplete = false;
            break;
          }
          currentWord += cellValue;
        }
      }
      
      if (wordComplete && currentWord == word.word) {
        foundCount++;
      }
    }
    
    setState(() {
      _wordsFound = foundCount;
    });
    
    if (foundCount == _words.length && !_gameComplete) {
      _gameComplete = true;
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Text(
              'Félicitations !',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ],
        ),
        content: const Text(
          'Vous avez trouvé tous les mots RGPD !\n'
          'Vous maîtrisez maintenant les concepts clés.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onComplete != null) {
                widget.onComplete!({
                  'wordsFound': _wordsFound,
                  'totalWords': _words.length,
                  'completionTime': DateTime.now().toIso8601String(),
                });
              } else {
                // Mode standalone (ancien comportement)
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const Page4Tram()),
                );
              }
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continuer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDefinition(CrosswordWord word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          word.word,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          word.definition,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mots Fléchés RGPD'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$_wordsFound/${_words.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Instructions compactes
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Trouve les 10 mots RGPD. Clique sur une cellule pour saisir une lettre.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Contenu principal en Row
                    Expanded(
                      child: Row(
                        children: [
                          // Grille de mots fléchés
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: GridView.builder(
                                padding: const EdgeInsets.all(8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10,
                                  childAspectRatio: 1,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                ),
                                itemCount: 100,
                                itemBuilder: (context, index) {
                                  int row = index ~/ 10;
                                  int col = index % 10;
                                  bool isEditable = _isEditable[row][col];
                                  String cellValue = _grid[row][col];
                                  
                                  return GestureDetector(
                                    onTap: () => _onCellTap(row, col),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isEditable 
                                          ? Colors.blueAccent.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.1),
                                        border: Border.all(
                                          color: isEditable 
                                            ? Colors.blueAccent.withOpacity(0.5)
                                            : Colors.grey.withOpacity(0.3),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: isEditable && cellValue.isNotEmpty
                                          ? [
                                              BoxShadow(
                                                color: Colors.greenAccent.withOpacity(0.3),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          cellValue,
                                          style: TextStyle(
                                            color: cellValue.isNotEmpty 
                                              ? Colors.white 
                                              : Colors.white54,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Liste des définitions
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.list, color: Colors.blueAccent, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Définitions',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '$_wordsFound/${_words.length}',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _words.length,
                                      itemBuilder: (context, index) {
                                        final word = _words[index];
                                        bool isFound = _isWordFound(word);
                                        
                                        return Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isFound 
                                              ? Colors.greenAccent.withOpacity(0.2)
                                              : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isFound 
                                                ? Colors.greenAccent.withOpacity(0.5)
                                                : Colors.transparent,
                                            ),
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            leading: Icon(
                                              isFound ? Icons.check_circle : Icons.help_outline,
                                              color: isFound ? Colors.greenAccent : Colors.white54,
                                              size: 16,
                                            ),
                                            title: Text(
                                              word.word,
                                              style: TextStyle(
                                                color: isFound ? Colors.greenAccent : Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                decoration: isFound ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            subtitle: Text(
                                              word.definition,
                                              style: TextStyle(
                                                color: isFound ? Colors.white70 : Colors.white54,
                                                fontSize: 10,
                                                height: 1.2,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            onTap: () => _showDefinition(word),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isWordFound(CrosswordWord word) {
    String currentWord = '';
    
    for (int i = 0; i < word.word.length; i++) {
      int row = word.row + (word.isHorizontal ? 0 : i);
      int col = word.col + (word.isHorizontal ? i : 0);
      
      if (row < 10 && col < 10) {
        String cellValue = _grid[row][col];
        if (cellValue.isEmpty) return false;
        currentWord += cellValue;
      }
    }
    
    return currentWord == word.word;
  }
}

class CrosswordWord {
  final String word;
  final String definition;
  final int row;
  final int col;
  final bool isHorizontal;

  CrosswordWord({
    required this.word,
    required this.definition,
    required this.row,
    required this.col,
    required this.isHorizontal,
  });
}