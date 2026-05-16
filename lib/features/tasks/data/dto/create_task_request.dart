class CreateTaskRequest {
  // Required by the API.
  final int assignedTo;
  final String title;
  final double shopLatitude;
  final double shopLongitude;

  // Optional.
  final int? managerId;
  final String description;
  final List<String> items;
  final String priority;
  final String dueDate;

  const CreateTaskRequest({
    required this.assignedTo,
    required this.title,
    required this.shopLatitude,
    required this.shopLongitude,
    this.managerId,
    required this.description,
    required this.items,
    required this.priority,
    required this.dueDate,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'assignedTo': assignedTo,
      'title': title,
      'shopLatitude': shopLatitude,
      'shopLongitude': shopLongitude,
      'description': description,
      'items': items,
      'priority': priority,
      'dueDate': dueDate,
    };
    if (managerId != null) map['managerId'] = managerId;
    return map;
  }
}
