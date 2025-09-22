_:
{
  programs.nixvim = {
    opts = {
      cc = "120";
      expandtab = true;
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      smartindent = true;
      softtabstop = 2;
      tabstop = 2;
      exrc = true;
      secure = true;
      termguicolors = true;
      hlsearch = false;
      hidden = true;
      guicursor = "";
      scrolloff = 0;
      undofile = true;
      incsearch = true;
      splitbelow = true;
      splitright = true;
      sessionoptions = "tabpages,globals";
      ignorecase = true;
      swapfile = false;
      conceallevel = 1;
      laststatus = 3;
      re = 0;
      eol = true;
      listchars = {
        tab = "▸ ";
        trail = "·";
        extends = "»";
        precedes = "«";
        nbsp = "␣";
        eol = "↲";
      };
    };
  };
}
