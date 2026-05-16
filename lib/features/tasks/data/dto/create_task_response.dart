class CreateTaskResponse {
  final TaskData task;

  const CreateTaskResponse({required this.task});

  factory CreateTaskResponse.fromJson(Map<String, dynamic> json) {
    return CreateTaskResponse(
      task: TaskData.fromJson(json['task'] as Map<String, dynamic>),
    );
  }
}

class TaskData {
  final int id;
  final int? companyId;
  final int? assignedTo;
  final int? assignedBy;
  final int? managerId;
  final String title;
  final String description;
  final List<String> items;
  final String status;
  final String priority;
  final String? shopLatitude;
  final String? shopLongitude;
  final String dueDate;
  final String? completedAt;
  final String? remarks;
  final String createdAt;
  final String updatedAt;
  final Assignee assignee;
  final Creator creator;
  final Manager? manager;

  const TaskData({
    required this.id,
    this.companyId,
    this.assignedTo,
    this.assignedBy,
    this.managerId,
    required this.title,
    required this.description,
    required this.items,
    required this.status,
    required this.priority,
    this.shopLatitude,
    this.shopLongitude,
    required this.dueDate,
    this.completedAt,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    required this.assignee,
    required this.creator,
    this.manager,
  });

  factory TaskData.fromJson(Map<String, dynamic> json) {
    return TaskData(
      id: json['id'] as int,
      companyId: json['company_id'] as int?,
      assignedTo: json['assigned_to'] as int?,
      assignedBy: json['assigned_by'] as int?,
      managerId: json['manager_id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      items: (json['items'] as List<dynamic>).map((e) => e.toString()).toList(),
      status: json['status'] as String,
      priority: json['priority'] as String,
      shopLatitude: json['shop_latitude'] as String?,
      shopLongitude: json['shop_longitude'] as String?,
      dueDate: json['due_date'] as String,
      completedAt: json['completed_at'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      assignee: Assignee.fromJson(json['assignee'] as Map<String, dynamic>),
      creator: Creator.fromJson(json['creator'] as Map<String, dynamic>),
      manager: json['manager'] != null 
          ? Manager.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Assignee {
  final int id;
  final String fullName;
  final String employeeCode;

  const Assignee({
    required this.id,
    required this.fullName,
    required this.employeeCode,
  });

  factory Assignee.fromJson(Map<String, dynamic> json) {
    return Assignee(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      employeeCode: json['employee_code'] as String,
    );
  }
}

class Creator {
  final int id;
  final String fullName;

  const Creator({
    required this.id,
    required this.fullName,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
    );
  }
}

class Manager {
  final int id;
  final String fullName;
  final String? managerCode;

  const Manager({
    required this.id,
    required this.fullName,
    this.managerCode,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      managerCode: json['manager_code'] as String?,
    );
  }
}
