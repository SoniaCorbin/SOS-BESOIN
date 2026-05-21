class RequestModel {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final String category;
  final double? budget;
  final String location;
  final String? neighborhood;
  final String urgency;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const RequestModel({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.category,
    this.budget,
    required this.location,
    this.neighborhood,
    required this.urgency,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  factory RequestModel.fromMap(Map<String, dynamic> map) => RequestModel(
    id:           map['id'] as String,
    clientId:     map['client_id'] as String,
    title:        map['title'] as String,
    description:  map['description'] as String,
    category:     map['category'] as String,
    budget:       (map['budget'] as num?)?.toDouble(),
    location:     map['location'] as String,
    neighborhood: map['neighborhood'] as String?,
    urgency:      map['urgency'] as String,
    status:       map['status'] as String,
    createdAt:    DateTime.parse(map['created_at'] as String),
    expiresAt:    DateTime.parse(map['expires_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    'client_id':    clientId,
    'title':        title,
    'description':  description,
    'category':     category,
    'budget':       budget,
    'location':     location,
    'neighborhood': neighborhood,
    'urgency':      urgency,
    'status':       status,
  };
}

// ── Modèle catégorie (depuis Supabase) ────────────────────
class CategoryModel {
  final String id;
  final String slug;
  final String label;
  final String emoji;
  final bool isActive;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.slug,
    required this.label,
    required this.emoji,
    required this.isActive,
    required this.sortOrder,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
    id:        map['id'] as String,
    slug:      map['slug'] as String,
    label:     map['label'] as String,
    emoji:     map['emoji'] as String,
    isActive:  map['is_active'] as bool? ?? true,
    sortOrder: map['sort_order'] as int? ?? 0,
  );
}

// ── Urgences (statique, ça change pas) ───────────────────
const kUrgencies = [
  {'id': 'asap',     'label': 'Dès que possible', 'emoji': '🔴'},
  {'id': 'today',    'label': 'Aujourd\'hui',      'emoji': '🟠'},
  {'id': 'tomorrow', 'label': 'Demain',            'emoji': '🟡'},
  {'id': 'week',     'label': 'Cette semaine',     'emoji': '🟢'},
];