/// Service that provides AI-based suggestions.  In this simplified
/// implementation the service returns a fixed set of suggestions and
/// does not perform any network or model calls.
class AiSuggestionsService {
  Future<List<String>> getSuggestions(String prompt) async {
    return ['Take a walk', 'Read a book', 'Call a friend'];
  }
}