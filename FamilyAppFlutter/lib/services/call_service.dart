/// Service responsible for initiating and managing calls between
/// family members.  This stub implementation does not actually
/// connect calls but defines the interface used by the UI.
class CallService {
  Future<void> startCall({required List<String> participantIds, required String type}) async {
    // In a real app this would interface with a backend or signalling
    // service.  Here it does nothing.
    return;
  }
}