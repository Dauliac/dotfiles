{ ... }:
{
  # Corp identifiers — vault endpoint template, AD email, AWS profile name,
  # Jira URL, self-hosted GitLab hostname, `includeIf` gitdir glob, and
  # extra ssh_config Include path — live in `secrets.yaml` and are
  # materialized at activation as sops templates under
  # `~/.config/sops-nix/secrets/rendered/<name>` (mode 0400).
  #
  # Consumers reference the rendered path via
  # `config.sops.templates."corp/<name>".path` so no corp-specific string
  # ever lands in the world-readable Nix store.
  flake.modules.homeManager.user-juliendauliac-corp =
    { config, lib, ... }:
    let
      corpKeys = [
        "corp_email"
        "corp_aws_profile"
        "corp_vault_addr_template"
        "corp_jira_url"
        "corp_gitlab_host"
        "corp_git_include_gitdir_glob"
        "corp_ssh_config_include"
      ];
    in
    {
      sops.secrets = lib.genAttrs corpKeys (_name: {
        format = "yaml";
        sopsFile = ../../secrets.yaml;
      });

      # 1) vault_all shell function + AWS_DEFAULT_PROFILE — sourced by zsh.
      # $ENV is substituted by the shell (envsubst), not by sops.
      sops.templates."corp/vault-alias.sh".content = ''
        vault_all() {
          local ENV
          for ENV in int stg prd support ist; do
            export VAULT_ADDR="$(ENV=$ENV envsubst <<< '${config.sops.placeholder.corp_vault_addr_template}')"
            export VAULT_''${ENV}_TOKEN=$(vault login -token-only -path=sso -method=oidc role=sre | grep hvs)
          done
        }
        export AWS_DEFAULT_PROFILE='${config.sops.placeholder.corp_aws_profile}'
      '';

      # 2) git includeIf — the gitdir glob (contains corp name) lives in a
      # sops-rendered ini fragment that git reads via `include.path`.
      sops.templates."corp/gitconfig-includes.ini".content = ''
        [includeIf "gitdir:${config.sops.placeholder.corp_git_include_gitdir_glob}"]
            path = ${config.sops.secrets.gitJulienDauliac.path}
      '';

      # 3) ssh matchBlock for the corp GitLab — standalone ssh_config fragment
      # that the main ~/.ssh/config Includes at the wildcard level.
      sops.templates."corp/ssh-config".content = ''
        Host ${config.sops.placeholder.corp_gitlab_host}
            IdentityFile ~/.ssh/${config.systemConstants.ssh.keys.corp.filename}
            IdentitiesOnly yes

        Include ${config.sops.placeholder.corp_ssh_config_include}
      '';

      # 4) lazyjira profile config.
      sops.templates."corp/lazyjira-config.toml".content = ''
        default_profile = "corp"

        [[profiles]]
        name = "corp"
        url = "${config.sops.placeholder.corp_jira_url}"
        email = "${config.sops.placeholder.corp_email}"
      '';
    };
}
