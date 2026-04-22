{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule {
  pname = "mermaid-ascii";
  version = "unstable-2026-02-21";

  src = fetchFromGitHub {
    owner = "AlexanderGrooff";
    repo = "mermaid-ascii";
    rev = "b5d02c35decfab219bd6cc79094b117d8079bd63";
    hash = "sha256-bFqlMwBfvm75aKiUU1GZadGtMWppCabwdvguMzK/KBo=";
  };

  vendorHash = "sha256-aB9sbTtlHbptM2995jizGFtSmEIg3i8zWkXz1zzbIek=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "Render Mermaid diagrams as ASCII art in the terminal";
    homepage = "https://github.com/AlexanderGrooff/mermaid-ascii";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "mermaid-ascii";
  };
}
