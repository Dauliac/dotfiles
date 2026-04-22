{
  lib,
  python312Packages,
  fetchFromGitHub,
}:
python312Packages.buildPythonApplication {
  pname = "mempalace";
  version = "3.3.0";

  src = fetchFromGitHub {
    owner = "MemPalace";
    repo = "mempalace";
    tag = "v3.3.0";
    hash = "sha256-nmU3d4Jj00YwpNl31tL9xsyDGXsGUM9Wp0tBWB9+p7E=";
  };

  build-system = [ python312Packages.hatchling ];

  dependencies = with python312Packages; [
    chromadb
    pyyaml
  ];

  pythonImportsCheck = [ "mempalace" ];

  meta = {
    description = "Give your AI a memory — mine projects and conversations into a searchable palace";
    homepage = "https://github.com/MemPalace/mempalace";
    license = lib.licenses.mit;
    mainProgram = "mempalace";
  };
}
