{
  flake.modules.homeManager.programs-base = {
    programs.home-manager.enable = true;
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    programs.tealdeer.enable = true;
    programs.navi = {
      enable = true;
      enableZshIntegration = true;
    };
    programs.jq.enable = true;
    programs.k9s = {
      enable = true;
      plugins.plugins = {
        debug = {
          shortCut = "Shift-D";
          description = "Add debug container";
          scopes = [ "containers" ];
          command = "kubectl";
          background = false;
          args = [
            "debug"
            "-it"
            "--context"
            "$CONTEXT"
            "-n"
            "$NAMESPACE"
            "$POD"
            "--target"
            "$NAME"
            "--image=nicolaka/netshoot:v0.13"
            "--share-processes"
            "--"
            "bash"
          ];
        };
        jqlogs = {
          shortCut = "Ctrl-J";
          confirm = false;
          description = "Logs (jq)";
          scopes = [ "pod" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "kubectl logs -f $NAME -n $NAMESPACE --context $CONTEXT |jq -SR '. as $line | try (fromjson) catch $line'"
          ];
        };
        jqlogsd = {
          shortCut = "Ctrl-J";
          confirm = false;
          description = "Logs (jq)";
          scopes = [ "deployment" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "kubectl logs -f deployment/$NAME -n $NAMESPACE --context $CONTEXT |jq -SR '. as $line | try (fromjson) catch $line'"
          ];
        };
        jqlogss = {
          shortCut = "Ctrl-J";
          confirm = false;
          description = "Logs (jq)";
          scopes = [ "service" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "kubectl logs -f service/$NAME -n $NAMESPACE --context $CONTEXT |jq -SR '. as $line | try (fromjson) catch $line'"
          ];
        };
        vcluster-list = {
          shortCut = "v";
          description = "vcluster list";
          scopes = [ "all" ];
          command = "bash";
          background = false;
          confirm = false;
          args = [
            "-c"
            "vcluster list --context $CONTEXT | less -K -r"
          ];
        };
        vcluster-connect = {
          shortCut = "w";
          description = "KC connect";
          scopes = [ "secret" ];
          command = "bash";
          background = false;
          confirm = false;
          args = [
            "-c"
            ''
              tmp=$(mktemp)
              echo "kubectl get -n $NAMESPACE $NAME $RESOURCE_NAME --template='{{index .data "kubeconfig-vcluster"}}' | base64 -d" > /tmp/test
              kubectl get -n $NAMESPACE $RESOURCE_NAME/$NAME --template='{{index .data "kubeconfig-vcluster"}}' | base64 -d > $tmp
              k9s --kubeconfig $tmp
              rm $tmp
            ''
          ];
        };
      };
    };
    programs.btop.enable = true;
  };
}
