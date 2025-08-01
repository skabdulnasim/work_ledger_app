class SubscriptionPlan {
  final int id;
  final String title;
  final double price;
  final int durationInDays;

  SubscriptionPlan(
      {required this.id,
      required this.title,
      required this.price,
      required this.durationInDays});

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      title: json['title'],
      price: double.parse(json['price'].toString()),
      durationInDays: json['duration_in_days'],
    );
  }
}
