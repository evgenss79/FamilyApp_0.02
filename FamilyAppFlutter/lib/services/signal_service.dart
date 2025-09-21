/// Provides signalling for real-time communication (e.g. WebRTC).  In
/// this stub implementation methods are declared but not executed.
class SignalService {
  Future<void> connect() async {
    // In a real app this would open a signalling channel.
    return;
  }

  Future<void> disconnect() async {
    return;
  }
}