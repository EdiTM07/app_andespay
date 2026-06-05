import 'package:cloud_firestore/cloud_firestore.dart';

/// Wrapper aislado de Cloud Firestore
/// Provee métodos genéricos de CRUD. Cada repository usa esta capa.
class FirestoreService {
  FirestoreService._();

  static final FirestoreService _instance = FirestoreService._();
  factory FirestoreService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Crear / Actualizar ──

  /// Guarda o sobreescribe un documento en la colección indicada
  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection(collection).doc(docId).set(data);
  }

  /// Actualiza campos específicos de un documento existente
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  // ── Leer ──

  /// Obtiene un documento por ID como mapa de datos
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    final snapshot = await _db.collection(collection).doc(docId).get();
    return snapshot.data();
  }

  /// Stream de un documento en tiempo real
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDocument({
    required String collection,
    required String docId,
  }) {
    return _db.collection(collection).doc(docId).snapshots();
  }

  /// Obtiene una colección con filtros opcionales
  Future<List<Map<String, dynamic>>> getCollection({
    required String collection,
    String? whereField,
    dynamic whereValue,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(collection);

    if (whereField != null && whereValue != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Stream de una colección filtrada en tiempo real
  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollection({
    required String collection,
    String? whereField,
    dynamic whereValue,
    String? orderByField,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collection);

    if (whereField != null && whereValue != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    return query.snapshots();
  }

  // ── Eliminar ──

  /// Elimina un documento por ID
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    await _db.collection(collection).doc(docId).delete();
  }

  // ── Batch / Transacciones ──

  /// Ejecuta una operación atómica (debit + credit)
  Future<void> runTransaction(
    Future<void> Function(Transaction tx) transactionHandler,
  ) async {
    await _db.runTransaction(transactionHandler);
  }

  /// Referencia directa a un documento (útil para transacciones)
  DocumentReference<Map<String, dynamic>> docRef({
    required String collection,
    required String docId,
  }) {
    return _db.collection(collection).doc(docId);
  }
}
