vim.o.shell = "fish"
-- Over SSH, copy to the local clipboard with OSC 52. The terminal must support it.
-- LazyVim leaves the clipboard option empty over SSH, so set it here.
-- Paste uses the terminal paste shortcut, because most terminals block OSC 52 reads.
vim.opt.clipboard = "unnamedplus"
if vim.env.SSH_TTY then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

-- Setup LazyVim
require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- Load custom plugins from lua/plugins/*.lua
    -- Your custom plugin configs override or extend LazyVim defaults
    { import = "plugins" },
    -- Disable nil_ls and configure nixd for Nix files
    {
      "neovim/nvim-lspconfig",
      opts = {
        servers = {
          nil_ls = {
            enabled = false,
          },
          nixd = {
            enabled = true,
          },
        },
      },
    },
  },
  defaults = {},
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {},
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
