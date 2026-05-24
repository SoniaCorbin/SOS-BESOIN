class InvoiceModel {
  final String id;
  final String transactionId;
  final String requestId;
  final String clientId;
  final String providerId;
  final String invoiceNumber;
  final double amount;
  final double platformFee;
  final double providerAmount;
  final String requestTitle;
  final String requestCategory;
  final String providerName;
  final String clientName;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;

  const InvoiceModel({
    required this.id,
    required this.transactionId,
    required this.requestId,
    required this.clientId,
    required this.providerId,
    required this.invoiceNumber,
    required this.amount,
    required this.platformFee,
    required this.providerAmount,
    required this.requestTitle,
    required this.requestCategory,
    required this.providerName,
    required this.clientName,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map) => InvoiceModel(
    id:               map['id'] as String,
    transactionId:    map['transaction_id'] as String,
    requestId:        map['request_id'] as String,
    clientId:         map['client_id'] as String,
    providerId:       map['provider_id'] as String,
    invoiceNumber:    map['invoice_number'] as String,
    amount:           (map['amount'] as num).toDouble(),
    platformFee:      (map['platform_fee'] as num).toDouble(),
    providerAmount:   (map['provider_amount'] as num).toDouble(),
    requestTitle:     map['request_title'] as String,
    requestCategory:  map['request_category'] as String,
    providerName:     map['provider_name'] as String,
    clientName:       map['client_name'] as String,
    status:           map['status'] as String,
    createdAt:        DateTime.parse(map['created_at'] as String),
    paidAt:           map['paid_at'] != null
        ? DateTime.parse(map['paid_at'] as String)
        : null,
  );

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