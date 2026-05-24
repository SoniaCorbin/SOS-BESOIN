enum TransactionStatus { pending, completed, cancelled, refunded }

enum TransactionType { payment, refund }

class TransactionModel {
  final String id;
  final String requestId;
  final String offerId;
  final String clientId;
  final String providerId;
  final double amount;
  final double platformFee;
  final double providerAmount;
  final TransactionStatus status;
  final TransactionType type;
  final String requestTitle;
  final String requestCategory;
  final String providerName;
  final String clientName;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TransactionModel({
    required this.id,
    required this.requestId,
    required this.offerId,
    required this.clientId,
    required this.providerId,
    required this.amount,
    required this.platformFee,
    required this.providerAmount,
    required this.status,
    required this.type,
    required this.requestTitle,
    required this.requestCategory,
    required this.providerName,
    required this.clientName,
    required this.createdAt,
    this.completedAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) =>
      TransactionModel(
        id:               map['id'] as String,
        requestId:        map['request_id'] as String,
        offerId:          map['offer_id'] as String,
        clientId:         map['client_id'] as String,
        providerId:       map['provider_id'] as String,
        amount:           (map['amount'] as num).toDouble(),
        platformFee:      (map['platform_fee'] as num).toDouble(),
        providerAmount:   (map['provider_amount'] as num).toDouble(),
        status:           _statusFromString(map['status'] as String),
        type:             map['type'] == 'refund'
            ? TransactionType.refund
            : TransactionType.payment,
        requestTitle:     map['request_title'] as String,
        requestCategory:  map['request_category'] as String,
        providerName:     map['provider_name'] as String,
        clientName:       map['client_name'] as String,
        createdAt:        DateTime.parse(map['created_at'] as String),
        completedAt:      map['completed_at'] != null
            ? DateTime.parse(map['completed_at'] as String)
            : null,
      );

  static TransactionStatus _statusFromString(String s) {
    switch (s) {
      case 'completed':  return TransactionStatus.completed;
      case 'cancelled':  return TransactionStatus.cancelled;
      case 'refunded':   return TransactionStatus.refunded;
      default:           return TransactionStatus.pending;
    }
  }

  bool get isCompleted  => status == TransactionStatus.completed;
  bool get isCancelled  => status == TransactionStatus.cancelled;
  bool get isRefunded   => status == TransactionStatus.refunded;
  bool get isPending    => status == TransactionStatus.pending;

  String get statusLabel {
    switch (status) {
      case TransactionStatus.completed:  return 'Complétée';
      case TransactionStatus.cancelled:  return 'Annulée';
      case TransactionStatus.refunded:   return 'Remboursée';
      default:                           return 'En attente';
    }
  }

  String get categoryEmoji {
    switch (requestCategory) {
      case 'tech':       return '💻';
      case 'music':      return '🎵';
      case 'repair':     return '🔧';
      case 'transport':  return '🚚';
      case 'courses':    return '📚';
      case 'design':     return '🎨';
      case 'legal':      return '⚖️';
      case 'health':     return '🏥';
      default:           return '📦';
    }
  }
}