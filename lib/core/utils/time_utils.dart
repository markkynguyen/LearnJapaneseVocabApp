String formatNextReview(int nextReviewAt) {
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final diffSeconds = nextReviewAt - nowSeconds;

  if (diffSeconds <= 0) {
    return 'Cần ôn ngay';
  }

  final diffMinutes = diffSeconds ~/ 60;
  if (diffMinutes < 60) {
    return 'Còn $diffMinutes phút';
  }

  final diffHours = diffSeconds ~/ 3600;
  if (diffHours < 24) {
    return 'Còn $diffHours giờ';
  }

  final diffDays = diffSeconds ~/ 86400;
  if (diffDays < 30) {
    return 'Còn $diffDays ngày';
  }

  final diffMonths = diffDays ~/ 30;
  return 'Còn $diffMonths tháng';
}
