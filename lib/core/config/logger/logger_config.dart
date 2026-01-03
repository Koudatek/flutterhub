import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as crypto;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Niveaux de log disponibles
enum LogLevel {
  verbose('VERBOSE', '', 300, '\x1B[90m'),
  debug('DEBUG', '', 400, '\x1B[36m'),
  info('INFO', '', 500, '\x1B[34m'),
  success('SUCCESS', '', 600, '\x1B[32m'),
  warning('WARNING', '', 700, '\x1B[33m'),
  error('ERROR', '', 800, '\x1B[31m'),
  wtf('WTF', '', 900, '\x1B[35m');

  final String name;
  final String emoji;
  final int level;
  final String color;
  
  const LogLevel(this.name, this.emoji, this.level, this.color);
}

/// Logger centralisé avec persistance et chiffrement
class AppLogger {
  static const String _appPrefix = '[FLUTTERHUB]';
  static const String _storageKey = 'app_logs';
  static const int _maxLogsInMemory = 100;
  static const int _maxLogsInStorage = 1000;
  static const Duration _flushInterval = Duration(seconds: 5);
  static const String _resetColor = '\x1B[0m';

  // Configuration
  static bool _isInitialized = false;
  static late final SharedPreferences _prefs;
  static final List<Map<String, dynamic>> _logBuffer = [];
  static Timer? _flushTimer;
  static crypto.Encrypter? _encrypter;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static Map<String, dynamic>? _deviceInfoCache;
  static String? _appVersion;

  /// Initialise le logger
  static Future<void> init({String? encryptionKey}) async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Initialisation du chiffrement si une clé est fournie
      if (encryptionKey != null) {
        final key = sha256.convert(utf8.encode(encryptionKey)).toString().substring(0, 32);
        _encrypter = crypto.Encrypter(crypto.AES(crypto.Key.fromUtf8(key)));
      }

      // Planification du vidage périodique du buffer
      _scheduleFlush();
      _isInitialized = true;
      
      // Nettoyage des logs trop anciens
      await _cleanupOldLogs();
      
      info('Logger initialisé');
    } catch (e) {
      developer.log('Erreur lors de l\'initialisation du logger: $e', name: _appPrefix);
      rethrow;
    }
  }

  // --- Méthodes de log publiques ---

  static void verbose(String message, {Map<String, dynamic>? data, String? category}) {
    _log(LogLevel.verbose, message, data: data, category: category);
  }

  static void debug(String message, {Map<String, dynamic>? data, String? category}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, data: data, category: category);
    }
  }

  static void info(String message, {Map<String, dynamic>? data, String? category}) {
    _log(LogLevel.info, message, data: data, category: category);
  }

  static void success(String message, {Map<String, dynamic>? data, String? category}) {
    _log(LogLevel.success, message, data: data, category: category);
  }

  static void warning(String message, {Map<String, dynamic>? data, String? category, Object? error}) {
    _log(LogLevel.warning, message, data: data, category: category, error: error);
  }

  static void error(
    String message, {
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? category,
  }) {
    _log(LogLevel.error, message, data: data, category: category, error: error, stackTrace: stackTrace);
  }

  static void wtf(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String? category,
  }) {
    _log(LogLevel.wtf, message, data: data, category: category, error: error, stackTrace: stackTrace);
  }

  // --- Gestion des logs ---

  /// Récupère les logs stockés
  static Future<List<Map<String, dynamic>>> getLogs({int? limit}) async {
    try {
      final logs = await _getStoredLogs();
      return limit != null ? logs.take(limit).toList() : logs;
    } catch (e) {
      developer.log('Erreur lors de la récupération des logs: $e', name: _appPrefix);
      return [];
    }
  }

  /// Supprime tous les logs
  static Future<void> clearLogs() async {
    try {
      await _prefs.remove(_storageKey);
    } catch (e) {
      developer.log('Erreur lors de la suppression des logs: $e', name: _appPrefix);
      rethrow;
    }
  }

  /// Exporte les logs dans un fichier
  static Future<File> exportLogs({String? directory, int? limit}) async {
    try {
      final logs = await getLogs(limit: limit);
      final exportData = {
        'app': 'FlutterHub',
        'version': await _getAppVersion(),
        'exportedAt': DateTime.now().toIso8601String(),
        'deviceInfo': await _getDeviceInfo(),
        'logCount': logs.length,
        'logs': logs,
      };

      final dir = directory != null ? Directory(directory) : await getTemporaryDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      final file = File('${dir.path}/flutterhub_logs_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(exportData));
      
      return file;
    } catch (e) {
      developer.log('Erreur lors de l\'export des logs: $e', name: _appPrefix);
      rethrow;
    }
  }

  // --- Méthodes privées ---

  static void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushBuffer());
  }

  static Future<void> _flushBuffer() async {
    if (_logBuffer.isEmpty) return;
    
    final logsToSave = List<Map<String, dynamic>>.from(_logBuffer);
    _logBuffer.clear();
    
    try {
      final existingLogs = await _getStoredLogs();
      final updatedLogs = [...existingLogs, ...logsToSave];
      
      // Tronquer si nécessaire
      if (updatedLogs.length > _maxLogsInStorage) {
        updatedLogs.removeRange(0, updatedLogs.length - _maxLogsInStorage);
      }
      
      await _saveLogs(updatedLogs);
    } catch (e) {
      developer.log('Erreur lors de l\'enregistrement des logs: $e', name: _appPrefix);
      // Si l'écriture échoue, on remet les logs dans le buffer
      _logBuffer.insertAll(0, logsToSave);
    }
  }

  static Future<List<Map<String, dynamic>>> _getStoredLogs() async {
    try {
      final logs = _prefs.getStringList(_storageKey) ?? [];
      return logs.map((e) {
        try {
          return jsonDecode(_decryptIfNeeded(e)) as Map<String, dynamic>;
        } catch (e) {
          return {'error': 'Failed to parse log: $e', 'raw': e};
        }
      }).toList();
    } catch (e) {
      developer.log('Erreur lors de la lecture des logs: $e', name: _appPrefix);
      return [];
    }
  }

  static Future<void> _saveLogs(List<Map<String, dynamic>> logs) async {
    try {
      final logsToSave = logs.map((e) => _encryptIfNeeded(jsonEncode(e))).toList();
      await _prefs.setStringList(_storageKey, logsToSave);
    } catch (e) {
      developer.log('Erreur lors de la sauvegarde des logs: $e', name: _appPrefix);
      rethrow;
    }
  }

  static String _encryptIfNeeded(String data) {
    if (_encrypter == null) return data;
    try {
      final iv = crypto.IV.fromSecureRandom(16);
      final encrypted = _encrypter!.encrypt(data, iv: iv);
      return jsonEncode({
        'iv': iv.bytes,
        'value': encrypted.bytes,
      });
    } catch (e) {
      developer.log('Erreur lors du chiffrement: $e', name: _appPrefix);
      return data;
    }
  }

  static String _decryptIfNeeded(String data) {
    if (_encrypter == null) return data;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      if (json['iv'] == null || json['value'] == null) return data;
      
      final iv = crypto.IV(Uint8List.fromList(List<int>.from(json['iv'])));
      final encrypted = crypto.Encrypted(Uint8List.fromList(List<int>.from(json['value'])));
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      developer.log('Erreur lors du déchiffrement: $e', name: _appPrefix);
      return data;
    }
  }

  static Future<void> _cleanupOldLogs() async {
    try {
      final logs = await _getStoredLogs();
      if (logs.length > _maxLogsInStorage) {
        final updatedLogs = logs.sublist(logs.length - _maxLogsInStorage);
        await _saveLogs(updatedLogs);
      }
    } catch (e) {
      developer.log('Erreur lors du nettoyage des logs: $e', name: _appPrefix);
    }
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    if (_deviceInfoCache != null) return _deviceInfoCache!;
    
    try {
      Map<String, dynamic> deviceData;
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData = {
          'platform': 'Android',
          'model': '${androidInfo.manufacturer} ${androidInfo.model}',
          'version': '${androidInfo.version.sdkInt} (${androidInfo.version.release})',
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData = {
          'platform': 'iOS',
          'model': '${iosInfo.model} (${iosInfo.utsname.machine})',
          'version': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceData = {
          'platform': 'Windows',
          'computerName': windowsInfo.computerName,
          'numberOfCores': windowsInfo.numberOfCores,
          'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
        };
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        deviceData = {
          'platform': 'macOS',
          'computerName': macInfo.computerName,
          'model': macInfo.model,
          'kernelVersion': macInfo.kernelVersion,
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceData = {
          'platform': 'Linux',
          'name': linuxInfo.name,
          'version': linuxInfo.version,
          'id': linuxInfo.id,
        };
      } else {
        deviceData = {'platform': Platform.operatingSystem};
      }
      
      deviceData.addAll({
        'localTime': DateTime.now().toIso8601String(),
        'locale': Platform.localeName,
        'isWeb': kIsWeb,
      });
      
      _deviceInfoCache = deviceData;
      return deviceData;
    } catch (e) {
      developer.log('Erreur lors de la récupération des infos du périphérique: $e', name: _appPrefix);
      return {'error': 'Failed to get device info: $e'};
    }
  }

  static Future<String> _getAppVersion() async {
    if (_appVersion != null) return _appVersion!;
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      return _appVersion!;
    } catch (e) {
      developer.log('Erreur lors de la récupération de la version: $e', name: _appPrefix);
      return 'unknown';
    }
  }

  static Map<String, dynamic> _sanitizeData(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    final sanitized = Map<String, dynamic>.from(data);
    const sensitiveKeys = [
      'password', 'token', 'authorization', 'key', 'secret',
      'pin', 'otp', 'email', 'phone', 'cvv', 'ssn', 'credit_card'
    ];

    for (final key in sensitiveKeys) {
      for (final entry in sanitized.keys.toList()) {
        if (entry.toString().toLowerCase().contains(key)) {
          sanitized[entry] = '***MASKED***';
        }
      }
    }
    return sanitized;
  }

  static Future<void> _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? data,
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (!_isInitialized) {
      developer.log('Logger non initialisé', name: _appPrefix);
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final categoryStr = category != null ? '[$category]' : '';
    final logMessage = '${level.emoji} $_appPrefix$categoryStr [${level.name}] $message';
    final sanitizedData = _sanitizeData(data);

    // Structure du log pour le stockage
    final logEntry = <String, dynamic>{
      'timestamp': timestamp,
      'level': level.name,
      'levelValue': level.level,
      'message': message,
      if (category != null) 'category': category,
      if (sanitizedData.isNotEmpty) 'data': sanitizedData,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };

    // Affichage en console (debug)
    if (kDebugMode) {
      final color = level.color;
      final reset = _resetColor;
      
      print('$color$timestamp $logMessage$reset');
      
      if (sanitizedData.isNotEmpty) {
        print('$color${const JsonEncoder.withIndent('  ').convert(sanitizedData)}$reset');
      }
      
      if (error != null) {
        print('${LogLevel.error.color}Error: $error$reset');
      }
      
      if (stackTrace != null) {
        print('${LogLevel.error.color}StackTrace:\n$stackTrace$reset');
      }
    } 
    // En mode release, on utilise le logger natif
    else {
      developer.log(
        message,
        name: '$_appPrefix$categoryStr [${level.name}]',
        level: level.level,
        error: error,
        stackTrace: stackTrace,
      );
    }

    // Ajout au buffer pour persistance asynchrone
    _logBuffer.add(logEntry);
    
    // Si le buffer devient trop grand, on force le flush
    if (_logBuffer.length >= _maxLogsInMemory) {
      await _flushBuffer();
    }
  }
}

/// Simple logger interface
abstract class Logger {
  void verbose(String message, {Map<String, dynamic>? data, String? category});
  void debug(String message, {Map<String, dynamic>? data, String? category});
  void info(String message, {Map<String, dynamic>? data, String? category});
  void success(String message, {Map<String, dynamic>? data, String? category});
  void warning(String message, {Map<String, dynamic>? data, String? category, Object? error});
  void error(String message, {required Object error, StackTrace? stackTrace, Map<String, dynamic>? data, String? category});
  void wtf(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data, String? category});
}

/// Implementation of Logger using AppLogger
class AppLoggerImpl implements Logger {
  @override
  void verbose(String message, {Map<String, dynamic>? data, String? category}) {
    AppLogger.verbose(message, data: data, category: category);
  }

  @override
  void debug(String message, {Map<String, dynamic>? data, String? category}) {
    AppLogger.debug(message, data: data, category: category);
  }

  @override
  void info(String message, {Map<String, dynamic>? data, String? category}) {
    AppLogger.info(message, data: data, category: category);
  }

  @override
  void success(String message, {Map<String, dynamic>? data, String? category}) {
    AppLogger.success(message, data: data, category: category);
  }

  @override
  void warning(String message, {Map<String, dynamic>? data, String? category, Object? error}) {
    AppLogger.warning(message, data: data, category: category, error: error);
  }

  @override
  void error(String message, {required Object error, StackTrace? stackTrace, Map<String, dynamic>? data, String? category}) {
    AppLogger.error(message, error: error, stackTrace: stackTrace, data: data, category: category);
  }

  @override
  void wtf(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data, String? category}) {
    AppLogger.wtf(message, error: error, stackTrace: stackTrace, data: data, category: category);
  }
}

/// Wrapper for AppLogger to provide a simple interface
class LoggerConfig {
  Logger get logger => AppLoggerImpl();
}
