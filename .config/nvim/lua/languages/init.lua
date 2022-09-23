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
  local lspbuf = vim.lsp.buf

  map('gd', lspbuf.definition)
  map('K', lspbuf.hover)
  map('gi', lspbuf.implementation)
  map('gr', lspbuf.references)
  map('<localleader>la', lspbuf.code_action)
  map('<localleader>lr', lspbuf.rename)
  map('<localleader>l=', lspbuf.formatting)
end

-- integrations
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

-- server setups

local lspsetups = {
  pyls = {
    settings = {
      pyls = {
        configurationSources = { "flake8" }
      }
    }
  },
  sumneko_lua = {
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT'
        },
        diagnostics = {
          globals = { 'vim' },
        },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
        },
        telemetry = {
          enable = false
        },
      },
    }
  }
}

-- automation
for server, setup in pairs(lspsetups) do
  lspsetups[server].capabilities = capabilities
  lspsetups[server].on_attach = on_attach

  lsp[server].setup(setup)
end
