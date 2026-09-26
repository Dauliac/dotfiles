{ inputs, ... }: {
  # Top-level `ai` aggregate — one import per bounded context (workspace,
  # capability, session) plus the non-contextual packages leaf. Reads as
  # a feature menu; removing a context (rm -rf its dir) removes the whole
  # capability.
  flake.modules.homeManager.ai = {
    imports = with inputs.self.modules.homeManager; [
      ai-workspace
      ai-capability
      ai-session
      ai-packages
    ];
  };
}
