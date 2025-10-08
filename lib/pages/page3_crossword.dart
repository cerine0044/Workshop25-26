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

class _Page3CrosswordState extends State<Page3Crossword> {
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

  @override
  void initState() {
    super.initState();
    _initializeGrid();
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
        title: const Text('Saisir une lettre'),
        content: TextField(
          maxLength: 1,
          textCapitalization: TextCapitalization.characters,
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
            child: const Text('Annuler'),
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
      builder: (context) => AlertDialog(
        title: const Text('Félicitations !'),
        content: const Text('Vous avez trouvé tous les mots RGPD !'),
        actions: [
          TextButton(
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
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showDefinition(CrosswordWord word) {
    setState(() {
      _selectedDefinition = word.definition;
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Définition'),
        content: Text(word.definition),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
            child: Text(
              '$_wordsFound/${_words.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: const Text(
                  'Trouve les 10 mots liés au RGPD et à la sensibilisation au harcèlement.\n'
                  'Clique sur une cellule pour saisir une lettre.\n'
                  'Un mot est validé quand toute la ligne est complète.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Grille de mots fléchés
              Expanded(
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
                          ),
                          child: Center(
                            child: Text(
                              cellValue,
                              style: TextStyle(
                                color: Colors.white,
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
              
              const SizedBox(height: 16),
              
              // Liste des définitions
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Définitions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _words.length,
                        itemBuilder: (context, index) {
                          final word = _words[index];
                          return ListTile(
                            title: Text(
                              word.word,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => _showDefinition(word),
                            dense: true,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
