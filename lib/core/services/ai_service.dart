
import 'package:flutter/foundation.dart';

class AIService {
  // Simple heuristic-based priority prediction
  static String predictPriority(String title, String description) {
    final text = '$title $description'.toLowerCase();
    if (text.contains('urgent') || text.contains('asap') || text.contains('important') || text.contains('deadline') || text.contains('now') || text.contains('today')) {
      return 'High';
    } else if (text.contains('later') || text.contains('low') || text.contains('maybe') || text.contains('whenever')) {
      return 'Low';
    }
    return 'Medium'; // Default
  }

  // Simple heuristic-based category suggestion
  static String suggestCategory(String title) {
    final text = title.toLowerCase();
    if (text.contains('buy') || text.contains('grocer') || text.contains('shop') || text.contains('store') || text.contains('milk') || text.contains('food')) {
      return 'Shopping';
    } else if (text.contains('work') || text.contains('meet') || text.contains('presentation') || text.contains('office') || text.contains('boss') || text.contains('email')) {
      return 'Work';
    } else if (text.contains('study') || text.contains('read') || text.contains('learn') || text.contains('exam') || text.contains('class')) {
      return 'Education';
    } else if (text.contains('doctor') || text.contains('gym') || text.contains('health') || text.contains('med') || text.contains('walk') || text.contains('run')) {
      return 'Health';
    } else if (text.contains('bill') || text.contains('pay') || text.contains('bank') || text.contains('money')) {
      return 'Finance';
    }
     else if (text.contains('movie') || text.contains('game') || text.contains('play') || text.contains('fun')) {
      return 'Entertainment';
    }
    return 'Personal'; // Default
  }
}
