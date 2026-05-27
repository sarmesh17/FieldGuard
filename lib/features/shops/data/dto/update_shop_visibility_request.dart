class UpdateShopVisibilityRequest {
  final List<int> visibleTo;

  const UpdateShopVisibilityRequest({required this.visibleTo});

  Map<String, dynamic> toJson() {
    return {
      'visibleTo': visibleTo,
    };
  }
}
