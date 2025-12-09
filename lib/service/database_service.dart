import 'package:postgres_pool/postgres_pool.dart';
import '../models/mechanic_model.dart';

class DatabaseService {
  // Singleton pattern to ensure only one instance of DatabaseService
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Connection parameters from your Neon DB URL
  final String host =
      'ep-super-feather-a40n6zqs-pooler.us-east-1.aws.neon.tech';
  final int port = 5432;
  final String database = 'neondb';
  final String username = 'neondb_owner';
  final String password = 'npg_rW8D4kNJqYyT';
  final bool useSSL = true;

  PgPool? _pool;

  // Initialize the database connection pool
  Future<PgPool> _getPool() async {
    if (_pool == null) {
      _pool = PgPool(
        PgEndpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
          requireSsl: useSSL,
        ),
        settings: PgPoolSettings(),
      );
      // Create mechanics table if it doesn't exist
      await _createMechanicsTable();
    }
    return _pool!;
  }

  // Create mechanics table if it doesn't exist
  Future<void> _createMechanicsTable() async {
    final pool = await _getPool();
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS mechanics (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        email VARCHAR(100) NOT NULL,
        address TEXT NOT NULL,
        years_of_experience INTEGER NOT NULL,
        specialty VARCHAR(200) NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Ensure legacy tables get the new columns
    await pool.execute(
      'ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION',
    );
    await pool.execute(
      'ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION',
    );
  }

  // Insert a new mechanic into the database
  Future<int> insertMechanic(Mechanic mechanic) async {
    final pool = await _getPool();
    final results = await pool.query(
      '''
      INSERT INTO mechanics 
        (name, phone, email, address, years_of_experience, specialty, status, latitude, longitude)
      VALUES 
        (@name, @phone, @email, @address, @years_of_experience, @specialty, @status, @latitude, @longitude)
      RETURNING id
    ''',
      substitutionValues: {
        'name': mechanic.name,
        'phone': mechanic.phone,
        'email': mechanic.email,
        'address': mechanic.address,
        'years_of_experience': mechanic.yearsOfExperience,
        'specialty': mechanic.specialty,
        'status': mechanic.status,
        'latitude': mechanic.latitude,
        'longitude': mechanic.longitude,
      },
    );
    // Return the new mechanic ID
    return results[0][0] as int;
  }

  // Get all mechanics from the database
  Future<List<Mechanic>> getAllMechanics() async {
    final pool = await _getPool();
    final results = await pool.query('''
      SELECT * FROM mechanics ORDER BY created_at DESC
    ''');
    return results.map((row) {
      return Mechanic.fromMap({
        'id': row[0],
        'name': row[1],
        'phone': row[2],
        'email': row[3],
        'address': row[4],
        'years_of_experience': row[5],
        'specialty': row[6],
        'status': row[7],
        'latitude': row.length > 8 ? row[8] : null,
        'longitude': row.length > 9 ? row[9] : null,
        'created_at':
            row.length > 10
                ? row[10].toString()
                : DateTime.now().toIso8601String(),
      });
    }).toList();
  }

  // Get mechanics filtered by specialty/content
  Future<List<Mechanic>> getMechanicsBySpecialty(String specialtyQuery) async {
    final pool = await _getPool();
    final queryLower = specialtyQuery.toLowerCase();
    final results = await pool.query('''
      SELECT * FROM mechanics 
      WHERE LOWER(specialty) LIKE @query 
         OR specialty LIKE @queryPattern
      ORDER BY created_at DESC
    ''', substitutionValues: {
      'query': '%$queryLower%',
      'queryPattern': '%,$queryLower,%',
    });
    return results.map((row) {
      return Mechanic.fromMap({
        'id': row[0],
        'name': row[1],
        'phone': row[2],
        'email': row[3],
        'address': row[4],
        'years_of_experience': row[5],
        'specialty': row[6],
        'status': row[7],
        'latitude': row.length > 8 ? row[8] : null,
        'longitude': row.length > 9 ? row[9] : null,
        'created_at':
            row.length > 10
                ? row[10].toString()
                : DateTime.now().toIso8601String(),
      });
    }).toList();
  }

  // Get mechanics filtered by specialty and location (within radius)
  Future<List<Mechanic>> getMechanicsBySpecialtyAndLocation({
    String? specialtyQuery,
    required double latitude,
    required double longitude,
    double radiusKm = double.infinity,
  }) async {
    final pool = await _getPool();
    String query = '''
      SELECT * FROM (
        SELECT *, 
          (6371 * acos(
            cos(radians(@lat)) * 
            cos(radians(latitude)) * 
            cos(radians(longitude) - radians(@lng)) + 
            sin(radians(@lat)) * 
            sin(radians(latitude))
          )) AS distance_km
        FROM mechanics
        WHERE latitude IS NOT NULL 
          AND longitude IS NOT NULL
          AND (status = 'approved' OR status = 'pending')
    ''';
    
    final Map<String, dynamic> params = {
      'lat': latitude,
      'lng': longitude,
    };

    if (specialtyQuery != null && specialtyQuery.isNotEmpty) {
      final queryLower = specialtyQuery.toLowerCase();
      query += '''
        AND (LOWER(specialty) LIKE @query 
         OR specialty LIKE @queryPattern)
      ''';
      params['query'] = '%$queryLower%';
      params['queryPattern'] = '%,$queryLower,%';
    }

    query += '''
      ) AS mechanics_with_distance
      WHERE distance_km <= @radius
      ORDER BY distance_km ASC
    ''';
    params['radius'] = radiusKm;

    final results = await pool.query(query, substitutionValues: params);
    return results.map((row) {
      return Mechanic.fromMap({
        'id': row[0],
        'name': row[1],
        'phone': row[2],
        'email': row[3],
        'address': row[4],
        'years_of_experience': row[5],
        'specialty': row[6],
        'status': row[7],
        'latitude': row.length > 8 ? row[8] : null,
        'longitude': row.length > 9 ? row[9] : null,
        'created_at':
            row.length > 10
                ? row[10].toString()
                : DateTime.now().toIso8601String(),
      });
    }).toList();
  }

  // Get a mechanic by ID
  Future<Mechanic?> getMechanicById(int id) async {
    final pool = await _getPool();
    final results = await pool.query(
      '''
      SELECT * FROM mechanics WHERE id = @id
    ''',
      substitutionValues: {'id': id},
    );
    if (results.isEmpty) {
      return null;
    }
    final row = results[0];
    return Mechanic.fromMap({
      'id': row[0],
      'name': row[1],
      'phone': row[2],
      'email': row[3],
      'address': row[4],
      'years_of_experience': row[5],
      'specialty': row[6],
      'status': row[7],
      'latitude': row.length > 8 ? row[8] : null,
      'longitude': row.length > 9 ? row[9] : null,
      'created_at':
          row.length > 10
              ? row[10].toString()
              : DateTime.now().toIso8601String(),
    });
  }

  // Close the database connection pool
  Future<void> close() async {
    if (_pool != null) {
      await _pool!.close();
    }
  }
}
