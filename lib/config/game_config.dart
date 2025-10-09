class GameConfig {
  // Configuration générale
  static const String gameTitle = 'PANDORA BOX';
  static const String gameSubtitle = 'Libère l\'influenceur du stress numérique';
  
  // Configuration des pages
  static const int page1RequiredButtons = 4; // Nombre de boutons à trouver
  static const int page2StressThreshold = 65; // Seuil de stress en pourcentage
  static const int page3RequiredWords = 10; // Nombre de mots RGPD à trouver
  static const int page4QuestionCount = 20; // Nombre de questions tramway
  static const int page4SecondsPerQuestion = 12; // Temps par question
  static const int page5NotificationCount = 30; // Nombre de notifications à décocher
  
  // Configuration du chronomètre
  static const bool enableGlobalTimer = true;
  static const int countdownSeconds = 3;
  
  // Configuration des effets
  static const bool enableEpilepsyWarning = true;
  static const bool enableHapticFeedback = true;
  static const bool enableSoundEffects = true;
  static const bool enableFlashEffects = true;
  
  // Configuration multijoueur
  static const int maxPlayersPerRoom = 2;
  static const int roomTimeoutMinutes = 30;
  
  // Messages et textes
  static const Map<String, String> messages = {
    'epilepsy_warning': 'Attention: Effets lumineux pouvant déclencher une crise d\'épilepsie',
    'game_start': 'Le chronomètre commence dès que tu appuies sur START',
    'page1_instruction': 'Trouve tous les boutons cachés pour continuer',
    'page2_instruction': 'Secoue le téléphone pour faire monter le stress',
    'page3_instruction': 'Trouve les 10 mots RGPD dans la grille',
    'page4_instruction': 'Réponds aux dilemmes du tramway rapidement',
    'page5_instruction': 'Décoche toutes les notifications pour trouver la paix',
    'success_message': 'En décochant le vacarme, tu viens de choisir la paix',
  };
  
  // Couleurs du thème
  static const Map<String, int> themeColors = {
    'primary': 0xFF673AB7, // Deep Purple
    'secondary': 0xFF2196F3, // Blue
    'success': 0xFF4CAF50, // Green
    'warning': 0xFFFF9800, // Orange
    'error': 0xFFF44336, // Red
    'info': 0xFF00BCD4, // Cyan
  };
  
  // Configuration des sons
  static const Map<String, String> soundEffects = {
    'button_click': 'sounds/button_click.mp3',
    'success': 'sounds/success.mp3',
    'error': 'sounds/error.mp3',
    'notification': 'sounds/notification.mp3',
    'horn': 'sounds/horn.mp3',
  };
  
  // Configuration des images
  static const Map<String, String> imageAssets = {
    'tram1': 'assets/images/tram1.jpg',
    'tram2': 'assets/images/tram2.jpg',
    'tram3': 'assets/images/tram3.jpg',
    'tram4': 'assets/images/tram4.jpg',
    'tram5': 'assets/images/tram5.jpg',
  };
}
