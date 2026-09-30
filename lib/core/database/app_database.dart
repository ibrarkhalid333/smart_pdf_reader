import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _databaseName = 'smart_pdf_reader.db';
  static const _databaseVersion = 5;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasePath, _databaseName),
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedCatalog(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrate(db, oldVersion, newVersion);
      },
    );
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> upsertDocuments(List<PdfDocument> documents) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      for (final document in documents) {
        final existing = await txn.query(
          'documents',
          columns: ['id'],
          where: 'file_path = ?',
          whereArgs: [document.filePath],
          limit: 1,
        );
        final values = {
          'file_path': document.filePath,
          'title': document.title,
          'page_count': document.pages,
          'file_size_bytes': document.fileSizeBytes,
          'modified_at': document.date,
          'updated_at': now,
        };

        if (existing.isEmpty) {
          await txn.insert('documents', {...values, 'created_at': now});
        } else {
          await txn.update(
            'documents',
            values,
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        }
      }
    });
  }

  Future<Map<String, Map<String, int>>> loadDocumentProgress() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT documents.file_path, documents.page_count, document_progress.current_page,
             document_progress.pages_read
      FROM documents
      LEFT JOIN document_progress
        ON document_progress.document_id = documents.id
    ''');

    return {
      for (final row in rows)
        row['file_path'] as String: {
          'pageCount': (row['page_count'] as int?) ?? 0,
          'currentPage': (row['current_page'] as int?) ?? 0,
          'pagesRead': (row['pages_read'] as int?) ?? 0,
        },
    };
  }

  Future<void> updateDocumentPageCount(String filePath, int pageCount) async {
    if (filePath.trim().isEmpty || pageCount <= 0) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'documents',
      {'page_count': pageCount, 'updated_at': now},
      where: 'file_path = ?',
      whereArgs: [filePath],
    );
  }

  Future<List<Map<String, dynamic>>> loadFavouriteDocuments({
    int limit = 20,
  }) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT d.file_path, d.title, d.page_count, d.file_size_bytes, d.modified_at,
             d.is_favourite, dp.current_page, dp.pages_read, dp.last_opened_at
      FROM documents d
      LEFT JOIN document_progress dp ON dp.document_id = d.id
      WHERE d.is_favourite = 1
      ORDER BY COALESCE(dp.last_opened_at, d.updated_at) DESC, d.title ASC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<bool> isFavourite(String filePath) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT is_favourite FROM documents WHERE file_path = ? LIMIT 1',
      [filePath],
    );
    if (rows.isEmpty) return false;
    return (rows.first['is_favourite'] as int?) == 1;
  }

  Future<void> setFavourite(String filePath, bool favourite) async {
    if (filePath.trim().isEmpty) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final docId = await _ensureDocumentId(txn, filePath);
      await txn.update(
        'documents',
        {'is_favourite': favourite ? 1 : 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [docId],
      );
    });
  }

  /// Returns recently opened documents ordered by [last_opened_at] descending.
  /// Only documents that have a [document_progress] row (i.e. have been opened)
  /// are included. Limit defaults to 20.
  Future<List<Map<String, dynamic>>> loadRecentDocuments({
    int limit = 20,
  }) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT d.file_path, d.title, d.page_count, d.file_size_bytes, d.modified_at,
             dp.current_page, dp.pages_read, dp.last_opened_at
      FROM documents d
      INNER JOIN document_progress dp ON dp.document_id = d.id
      ORDER BY dp.last_opened_at DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  /// Records that [filePath] was opened right now so it surfaces at the top of
  /// Recent. Call this whenever the user selects a PDF (before navigating to
  /// the viewer so the timestamp is immediately persisted).
  Future<void> touchDocumentOpened(String filePath) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final rows = await txn.query(
        'documents',
        columns: ['id'],
        where: 'file_path = ?',
        whereArgs: [filePath],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final docId = rows.first['id'] as int;
      // Upsert a progress row with the current timestamp without changing page
      // progress (use INSERT OR IGNORE then UPDATE).
      await txn.execute(
        '''
        INSERT OR IGNORE INTO document_progress (document_id, current_page, pages_read, last_opened_at)
        VALUES (?, 0, 0, ?)
      ''',
        [docId, now],
      );
      await txn.execute(
        '''
        UPDATE document_progress SET last_opened_at = ? WHERE document_id = ?
      ''',
        [now, docId],
      );
    });
  }

  Future<int?> recordPageOpened(String filePath, int pageNumber) async {
    if (pageNumber < 1) return null;

    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      final documents = await txn.query(
        'documents',
        columns: ['id'],
        where: 'file_path = ?',
        whereArgs: [filePath],
        limit: 1,
      );
      if (documents.isEmpty) return null;

      final documentId = documents.first['id'] as int;
      await txn.insert('document_page_opens', {
        'document_id': documentId,
        'page_number': pageNumber,
        'first_opened_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      final count = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM document_page_opens WHERE document_id = ?',
          [documentId],
        ),
      )!;

      await txn.insert('document_progress', {
        'document_id': documentId,
        'current_page': pageNumber,
        'pages_read': count,
        'last_opened_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return count;
    });
  }

  Future<int> _ensureDocumentId(
    DatabaseExecutor db,
    String filePath, {
    String? title,
  }) async {
    final docs = await db.query(
      'documents',
      columns: ['id'],
      where: 'file_path = ?',
      whereArgs: [filePath],
      limit: 1,
    );
    if (docs.isNotEmpty) {
      return docs.first['id'] as int;
    }
    final now = DateTime.now().toIso8601String();
    final docTitle = title ?? filePath.split(RegExp(r'[/\\]')).last;
    return await db.insert('documents', {
      'file_path': filePath,
      'title': docTitle,
      'page_count': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Returns the set of all bookmarked page numbers (1-indexed) for [filePath].
  Future<Set<int>> getBookmarkedPages(String filePath) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT db.page_number
      FROM document_bookmarks db
      INNER JOIN documents d ON d.id = db.document_id
      WHERE d.file_path = ?
      ORDER BY db.page_number ASC
    ''',
      [filePath],
    );

    return {for (final r in rows) r['page_number'] as int};
  }

  /// Returns all bookmarks for [filePath] ordered by page number.
  Future<List<Map<String, dynamic>>> getBookmarks(String filePath) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT db.id, db.page_number, db.note, db.created_at
      FROM document_bookmarks db
      INNER JOIN documents d ON d.id = db.document_id
      WHERE d.file_path = ?
      ORDER BY db.page_number ASC
    ''',
      [filePath],
    );
  }

  /// Toggles bookmark for [pageNumber]. Returns `true` if added, `false` if removed.
  Future<bool> toggleBookmark(
    String filePath,
    int pageNumber, {
    String? note,
    String? title,
  }) async {
    if (pageNumber < 1) return false;
    final db = await database;
    return await db.transaction((txn) async {
      final docId = await _ensureDocumentId(txn, filePath, title: title);
      final existing = await txn.query(
        'document_bookmarks',
        columns: ['id'],
        where: 'document_id = ? AND page_number = ?',
        whereArgs: [docId, pageNumber],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        await txn.delete(
          'document_bookmarks',
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
        return false; // Removed
      } else {
        final now = DateTime.now().toIso8601String();
        await txn.insert('document_bookmarks', {
          'document_id': docId,
          'page_number': pageNumber,
          'note': note,
          'created_at': now,
        });
        return true; // Added
      }
    });
  }

  /// Removes bookmark for [pageNumber].
  Future<void> removeBookmark(String filePath, int pageNumber) async {
    if (pageNumber < 1) return;
    final db = await database;
    await db.transaction((txn) async {
      final docs = await txn.query(
        'documents',
        columns: ['id'],
        where: 'file_path = ?',
        whereArgs: [filePath],
        limit: 1,
      );
      if (docs.isEmpty) return;
      final docId = docs.first['id'] as int;
      await txn.delete(
        'document_bookmarks',
        where: 'document_id = ? AND page_number = ?',
        whereArgs: [docId, pageNumber],
      );
    });
  }

  /// Adds bookmark for [pageNumber].
  Future<void> addBookmark(
    String filePath,
    int pageNumber, {
    String? note,
    String? title,
  }) async {
    if (pageNumber < 1) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final docId = await _ensureDocumentId(txn, filePath, title: title);
      await txn.insert('document_bookmarks', {
        'document_id': docId,
        'page_number': pageNumber,
        'note': note,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> _createSchema(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE profiles (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          display_name TEXT NOT NULL,
          member_since TEXT NOT NULL,
          current_streak INTEGER NOT NULL DEFAULT 0,
          longest_streak INTEGER NOT NULL DEFAULT 0,
          last_open_date TEXT,
          total_pages_read INTEGER NOT NULL DEFAULT 0,
          total_pdfs_completed INTEGER NOT NULL DEFAULT 0,
          total_reading_seconds INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE documents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          file_path TEXT NOT NULL UNIQUE,
          title TEXT NOT NULL,
          page_count INTEGER NOT NULL DEFAULT 0,
          file_size_bytes INTEGER,
          modified_at TEXT,
          file_type TEXT NOT NULL DEFAULT 'pdf',
          is_favourite INTEGER NOT NULL DEFAULT 0 CHECK (is_favourite IN (0, 1)),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE document_progress (
          document_id INTEGER PRIMARY KEY,
          current_page INTEGER NOT NULL DEFAULT 0,
          pages_read INTEGER NOT NULL DEFAULT 0,
          last_opened_at TEXT,
          completed_at TEXT,
          FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
        )
      ''');

      await txn.execute('''
        CREATE TABLE document_page_opens (
          document_id INTEGER NOT NULL,
          page_number INTEGER NOT NULL,
          first_opened_at TEXT NOT NULL,
          PRIMARY KEY (document_id, page_number),
          FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
        )
      ''');

      await txn.execute('''
        CREATE TABLE reading_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          document_id INTEGER,
          started_at TEXT NOT NULL,
          ended_at TEXT,
          duration_seconds INTEGER NOT NULL DEFAULT 0,
          pages_turned INTEGER NOT NULL DEFAULT 0,
          completed INTEGER NOT NULL DEFAULT 0 CHECK (completed IN (0, 1)),
          FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE SET NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE daily_activity (
          activity_date TEXT PRIMARY KEY,
          bookmarks_added INTEGER NOT NULL DEFAULT 0,
          annotations_added INTEGER NOT NULL DEFAULT 0,
          ads_watched INTEGER NOT NULL DEFAULT 0,
          app_open_reward_claimed INTEGER NOT NULL DEFAULT 0,
          read_5_min_reward_claimed INTEGER NOT NULL DEFAULT 0,
          read_10_min_reward_claimed INTEGER NOT NULL DEFAULT 0,
          read_20_min_reward_claimed INTEGER NOT NULL DEFAULT 0,
          document_completed_reward_claimed INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await txn.execute('''
        CREATE TABLE coin_accounts (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          balance INTEGER NOT NULL DEFAULT 0,
          total_earned INTEGER NOT NULL DEFAULT 0,
          total_spent INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE coin_transactions (
          id TEXT PRIMARY KEY,
          amount INTEGER NOT NULL CHECK (amount <> 0),
          balance_after INTEGER NOT NULL,
          reason TEXT NOT NULL,
          type TEXT NOT NULL CHECK (type IN ('earn', 'spend', 'bonus', 'streak')),
          reference_type TEXT,
          reference_id TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE shop_items (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          cost INTEGER NOT NULL CHECK (cost >= 0),
          tier TEXT NOT NULL,
          unlock_type TEXT NOT NULL CHECK (unlock_type IN ('permanent', 'perUsePack', 'monthly')),
          uses_per_pack INTEGER NOT NULL DEFAULT 0,
          duration_days INTEGER,
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
        )
      ''');

      await txn.execute('''
        CREATE TABLE feature_unlocks (
          feature_id TEXT PRIMARY KEY,
          unlock_type TEXT NOT NULL CHECK (unlock_type IN ('permanent', 'perUsePack', 'monthly')),
          unlocked_at TEXT,
          expires_at TEXT,
          uses_remaining INTEGER NOT NULL DEFAULT 0 CHECK (uses_remaining >= 0),
          updated_at TEXT NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE achievements (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          reward INTEGER NOT NULL CHECK (reward >= 0),
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
        )
      ''');

      await txn.execute('''
        CREATE TABLE achievement_progress (
          achievement_id TEXT PRIMARY KEY,
          is_completed INTEGER NOT NULL DEFAULT 0 CHECK (is_completed IN (0, 1)),
          completed_at TEXT,
          FOREIGN KEY (achievement_id) REFERENCES achievements(id)
        )
      ''');

      await txn.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE document_bookmarks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          document_id INTEGER NOT NULL,
          page_number INTEGER NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL,
          UNIQUE(document_id, page_number),
          FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
        )
      ''');

      await txn.execute(
        'CREATE INDEX idx_bookmarks_doc ON document_bookmarks(document_id, page_number)',
      );
      await txn.execute(
        'CREATE INDEX idx_documents_recent ON documents(is_favourite, updated_at DESC)',
      );
      await txn.execute(
        'CREATE INDEX idx_sessions_document ON reading_sessions(document_id, started_at DESC)',
      );
      await txn.execute(
        'CREATE INDEX idx_coin_transactions_created ON coin_transactions(created_at DESC)',
      );
    });
  }

  Future<void> _seedCatalog(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('profiles', {
      'id': 1,
      'display_name': 'Alex Rahman',
      'member_since': 'Jan 2025',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('coin_accounts', {'id': 1, 'updated_at': now});

    final shopItems = <Map<String, Object?>>[
      {
        'id': 'area_screenshot_5',
        'name': 'Area Screenshots (5 uses)',
        'cost': 15,
        'tier': 'Tier 1',
        'unlock_type': 'perUsePack',
        'uses_per_pack': 5,
      },
      {
        'id': 'custom_highlight',
        'name': 'Custom highlight colors',
        'cost': 20,
        'tier': 'Tier 1',
        'unlock_type': 'permanent',
      },
      {
        'id': 'sticky_notes',
        'name': 'Sticky notes',
        'cost': 25,
        'tier': 'Tier 1',
        'unlock_type': 'permanent',
      },
      {
        'id': 'dark_theme',
        'name': 'Dark / Sepia themes',
        'cost': 30,
        'tier': 'Tier 1',
        'unlock_type': 'permanent',
      },
      {
        'id': 'area_screenshot_month',
        'name': 'Area Screenshot (Monthly)',
        'cost': 50,
        'tier': 'Tier 2',
        'unlock_type': 'monthly',
        'duration_days': 30,
      },
      {
        'id': 'freehand_drawing',
        'name': 'Freehand drawing',
        'cost': 70,
        'tier': 'Tier 2',
        'unlock_type': 'permanent',
      },
      {
        'id': 'page_reordering',
        'name': 'Page reordering',
        'cost': 75,
        'tier': 'Tier 2',
        'unlock_type': 'permanent',
      },
      {
        'id': 'export_annotations',
        'name': 'Export Annotations',
        'cost': 80,
        'tier': 'Tier 2',
        'unlock_type': 'permanent',
      },
      {
        'id': 'fill_sign_forms',
        'name': 'Fill and Sign Forms',
        'cost': 150,
        'tier': 'Tier 3',
        'unlock_type': 'permanent',
      },
      {
        'id': 'digital_signature',
        'name': 'Digital Signature pad',
        'cost': 150,
        'tier': 'Tier 3',
        'unlock_type': 'permanent',
      },
      {
        'id': 'split_pdf',
        'name': 'Split Pdf',
        'cost': 120,
        'tier': 'Tier 3',
        'unlock_type': 'permanent',
      },
      {
        'id': 'merge_pdf',
        'name': 'Merge pdfs',
        'cost': 120,
        'tier': 'Tier 3',
        'unlock_type': 'permanent',
      },
      {
        'id': 'read_aloud_tts',
        'name': 'Read Aloud / TTS',
        'cost': 140,
        'tier': 'Tier 3',
        'unlock_type': 'permanent',
      },
      {
        'id': 'pdf_compression',
        'name': 'Pdf Compression',
        'cost': 200,
        'tier': 'Tier 4',
        'unlock_type': 'permanent',
      },
      {
        'id': 'reflow_ebook',
        'name': 'Reflow / Ebook mode',
        'cost': 220,
        'tier': 'Tier 4',
        'unlock_type': 'permanent',
      },
      {
        'id': 'password_protect',
        'name': 'Password protect pdf',
        'cost': 200,
        'tier': 'Tier 4',
        'unlock_type': 'permanent',
      },
      {
        'id': 'multi_tab_viewer',
        'name': 'Multi Tab viewer',
        'cost': 300,
        'tier': 'Tier 4',
        'unlock_type': 'permanent',
      },
      {
        'id': 'full_annotation_suite',
        'name': 'Full Annotation Suite',
        'cost': 350,
        'tier': 'Tier 4',
        'unlock_type': 'permanent',
      },
    ];
    for (final item in shopItems) {
      await db.insert('shop_items', item);
    }

    const achievements = [
      ['first_pdf', 'First PDF opened', 20],
      ['first_bookmark', 'First bookmark', 10],
      ['first_annotation', 'First annotation', 10],
      ['read_5_pdfs', 'Read 5 PDFs', 50],
      ['read_10_pdfs', 'Read 10 PDFs', 100],
      ['read_100_pages', '100 pages read', 50],
      ['read_500_pages', '500 pages read', 150],
    ];
    for (final achievement in achievements) {
      await db.insert('achievements', {
        'id': achievement[0],
        'title': achievement[1],
        'reward': achievement[2],
      });
    }
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE documents ADD COLUMN file_type TEXT NOT NULL DEFAULT 'pdf'",
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE document_page_opens (
          document_id INTEGER NOT NULL,
          page_number INTEGER NOT NULL,
          first_opened_at TEXT NOT NULL,
          PRIMARY KEY (document_id, page_number),
          FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS document_bookmarks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          document_id INTEGER NOT NULL,
          page_number INTEGER NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL,
          UNIQUE(document_id, page_number),
          FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_bookmarks_doc ON document_bookmarks(document_id, page_number)',
      );
    }
    if (oldVersion < 5) {
      await db.delete(
        'shop_items',
        where: 'id = ?',
        whereArgs: ['auto_scroll'],
      );
    }
  }
}
