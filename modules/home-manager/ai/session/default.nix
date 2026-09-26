{ inputs, ... }:
{
  # Session bounded context — the terminal surface where the agent's work
  # becomes visible: the split-pane runner, the herdr TUI wrapper, and the
  # starship indicator that shows a live claude session at the prompt.
  # Session observes capability + coordination one-way; it must not push
  # into either.
  flake.modules.homeManager.ai-session = {
    imports = with inputs.self.modules.homeManager; [
      ai-session-runner
      ai-session-tui
      ai-session-indicator
      ai-session-post-activate
    ];
  };
}
