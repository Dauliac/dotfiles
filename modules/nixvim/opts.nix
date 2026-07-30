{
  flake.modules.nixvim.opts = {
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
      scrolloff = 8;
      sidescrolloff = 8;
      undofile = true;
      incsearch = true;
      splitbelow = true;
      splitright = true;
      sessionoptions = "tabpages,globals";
      ignorecase = true;
      smartcase = true;
      swapfile = false;
      conceallevel = 1;
      laststatus = 3;
      re = 0;
      eol = true;
      signcolumn = "yes";
      updatetime = 250;
      timeoutlen = 300;
      completeopt = "menu,menuone,noselect";
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
