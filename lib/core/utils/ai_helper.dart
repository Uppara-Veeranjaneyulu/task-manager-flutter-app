class AIHelper {
  static bool shouldStarTask(String title) {
    title = title.toLowerCase();
    return title.contains("urgent") ||
        title.contains("exam") ||
        title.contains("submit");
  }

  static String suggestList(String title) {
    title = title.toLowerCase();
    if (title.contains("exam") || title.contains("study")) {
      return "Study";
    } else if (title.contains("meeting") || title.contains("project")) {
      return "Work";
    } else {
      return "My Tasks";
    }
  }
}
