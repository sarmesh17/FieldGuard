class CreateTaskRequest {
  // Required by the API. The server now resolves the shop's coordinates
  // from `shopId`, so they no longer need to be sent from the client.
  final int assignedTo;
  final int shopId;
  final String title;

  // Optional.
  final int? managerId;
  final String description;
  final List<String> items;
  final String priority;
  final String dueDate;

  const CreateTaskRequest({
    required this.assignedTo,
    required this.shopId,
    required this.title,
    this.managerId,
    required this.description,
    required this.items,
    required this.priority,
    required this.dueDate,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'assignedTo': assignedTo,
      'shopId': shopId,
      'title': title,
      'description': description,
      'items': items,
      'priority': priority,
      'dueDate': dueDate,
    };
    if (managerId != null) map['managerId'] = managerId;
    return map;
  }
}
