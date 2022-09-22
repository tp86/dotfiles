local lsp = require('lspconfig')
local configs = require('lspconfig.configs')
local util = require('lspconfig.util')

-- custom servers

if not configs.pyls then
  configs.pyls = {
    default_config = {
      cmd = { "pyls" },
      filetypes = { "python" },
      root_dir = util.root_pattern("requirements.txt", "setup.py", ".git"),
      settings = {}
    }
  }
end

-- LSP mappings
local on_attach = function(client, bufnr)
  -- enable manually-triggered autocompletion
  --vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  local bufopts = { noremap = true, silent = true, buffer=bufnr }
  local map = function(keys, command)
    vim.keymap.set('n', keys, command, bufopts)
  end
  local lsp = vim.lsp.buf

  map('gd', lsp.definition)
  map('K', lsp.hover)
  map('gi', lsp.implementation)
  map('gr', lsp.references)
  map('<localleader>la', lsp.code_action)
  map('<localleader>lr', lsp.rename)
  map('<localleader>l=', lsp.formatting)
end

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

lsp.pyls.setup {
  settings = {
    pyls = {
      configurationSources = { "flake8" }
    }
  },
  capabilities = capabilities,
  on_attach = on_attach
}
