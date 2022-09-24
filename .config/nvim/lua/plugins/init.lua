local function ensurepacker()
  local fn = vim.fn
  local installpath = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(installpath)) > 0 then
    fn.system { 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', installpath }
    vim.cmd 'packadd packer.nvim'
    return true
  end
  return false
end

local packerbootstrap = ensurepacker()

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- PLUGINS START
  use { 'EdenEast/nightfox.nvim',
        config = function()
          require('nightfox').setup {
            options = {
              styles = {
                comments = 'italic',
              }
            }
          }
          vim.cmd 'colorscheme duskfox'
        end
  }
  use { 'kyazdani42/nvim-tree.lua',
        requires = { 'kyazdani42/nvim-web-devicons' --[[ requires patched font ]] },
        setup = function()
          vim.g.loaded_netrwPlugin = 1
        end,
        opt = false,
        config = function()
          require('nvim-tree').setup {
            actions = {
              open_file = {
                quit_on_open = true
              }
            },
            view = {
              side = 'right',
              width = 40
            },
            filters = {
              custom = { '__pycache__' }
            },
            sync_root_with_cwd = true
          }
          local vim = vim
          vim.keymap.set('n', '<leader>t', function() vim.cmd 'NvimTreeOpen' end)
        end
  }
  use { 'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons' --[[ requires patched font ]] },
        config = function()
          local function disableforfts(fts)
            local contains = vim.tbl_contains
            local optlocal = vim.opt_local
            return function()
              return not contains(fts, optlocal.filetype:get())
            end
          end
          local function all(fns)
            return function()
              for _, func in ipairs(fns) do
                if not func() then return false end
              end
              return true
            end
          end
          local fn = vim.fn
          local str = string
          local tbl = table
          local optlocal = vim.opt_local
          local lsp = vim.lsp
          require('lualine').setup {
            sections = {
              lualine_a = {
                function()
                  return fn.pathshorten(fn.fnamemodify(fn.getcwd(), ':~'))
                end
              },
              lualine_b = {
                {
                  'branch',
                  fmt = function(s)
                    local name = s
                    if #name > 8 then
                      name = str.sub(name, 1, 8) .. '…'
                    end
                    return name
                  end,
                  padding = { right = 0, left = 1 },
                  separator = { right = nil },
                },
                {
                  'diff',
                  fmt = function(s)
                    if #s > 0 then
                      return '*'
                    else
                      return ''
                    end
                  end,
                  padding = { left = 0, right = 1 },
                },
              },
              lualine_c = {
                {
                  function()
                    local bufname = fn.bufname()
                    local bufnamefull = fn.fnamemodify(bufname, ':p')
                    if str.find(bufnamefull, '^term://') then
                      local splittedtermuri = fn.split(bufnamefull, ':')
                      local shellpid = fn.fnamemodify(splittedtermuri[2], ':t')
                      local shellexec = fn.fnamemodify(splittedtermuri[#splittedtermuri], ':t')
                      return tbl.concat({ splittedtermuri[1], shellpid, shellexec }, ':')
                    end
                    local cwdfull = fn.fnamemodify(fn.getcwd(), ':p')
                    local relativepath = fn.matchstr(bufnamefull, [[\v^]] .. cwdfull .. [[\zs.*$]])
                    if #relativepath == 0 then
                      relativepath = bufnamefull
                    end
                    local filename = fn.fnamemodify(bufname, ':t')
                    if #filename == 0 then
                      return '[No Name]'
                    end
                    local relativedir = fn.fnamemodify(relativepath, ':h')
                    if relativedir == '.' then
                      return filename
                    else
                      return fn.pathshorten(relativedir) .. '/' .. filename
                    end
                  end,
                  separator = {},
                  cond = disableforfts { 'NvimTree', 'DiffviewFiles' },
                },
                {
                  function()
                    if optlocal.readonly:get() or not optlocal.modifiable:get() then
                      return '[-]'
                    elseif optlocal.modified:get() then
                      return '[+]'
                    else
                      return ''
                    end
                  end,
                  cond = all {
                    disableforfts { 'NvimTree', 'DiffviewFiles', 'NeogitStatus' },
                    function() return optlocal.buftype:get() ~= 'terminal' end,
                  },
                }
              },
              lualine_x = {
                {
                  'filetype',
                  cond = disableforfts { 'NvimTree', 'DiffviewFiles', 'NeogitStatus' },
                },
                {
                  function()
                    local clientnames = {}
                    for _, client in pairs(lsp.buf_get_clients()) do
                      clientnames[#clientnames + 1] = client.config.name
                    end
                    return tbl.concat(clientnames, ', ')
                  end,
                },
              },
              lualine_y = {
                'diagnostics'
              },
              lualine_z = {}
            },
          }
        end
  }
  use 'neovim/nvim-lspconfig'
  use { 'nvim-treesitter/nvim-treesitter',
        run = function() require('nvim-treesitter.install').update { with_sync = true } end,
        config = function()
          local opt = vim.opt
          require('nvim-treesitter.configs').setup {
            ensure_installed = { 'python', 'lua' },
            sync_install = false,
            auto_install = true,
            highlight = {
              enable = true
            },
          }
          opt.foldmethod = 'expr'
          opt.foldexpr = 'nvim_treesitter#foldexpr()'
          opt.foldenable = false
        end,
  }
  use 'hrsh7th/cmp-nvim-lsp'
  use { 'hrsh7th/nvim-cmp',
        config = function()
          local opt = vim.opt
          opt.completeopt = { 'menu', 'menuone', 'noselect' }
          local cmp = require('cmp')
          cmp.setup {
            sources = cmp.config.sources(
              {
                { name = 'nvim_lsp' }
              }
            ),
            mapping = cmp.mapping.preset.insert {
              ['<c-j>'] = cmp.mapping.select_next_item(),
              ['<c-k>'] = cmp.mapping.select_prev_item()
            }
          }
        end
  }
  use { 'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        requires = { 'nvim-lua/plenary.nvim',
                     { 'nvim-telescope/telescope-fzf-native.nvim',
                       -- requires make, gcc/clang
                       run = 'make'
                     }
        },
        config = function()
          local telescope = require('telescope')

          telescope.setup {
            defaults = {
              file_ignore_patterns = { '.git/' }
            }
          }

          local builtin = require('telescope.builtin')
          local mapkey = vim.keymap.set
          local function map(keys, action)
            mapkey('n', keys, action, { noremap = true })
          end
          map('<leader>ff', function() builtin.find_files { hidden = true } end)
          map('<leader>fg', builtin.live_grep)
          map('<leader>fb', builtin.buffers)

          telescope.load_extension('fzf')
        end

  }
  use { 'lewis6991/gitsigns.nvim',
        config = function()
          require('gitsigns').setup {
            signs = {
              changedelete = { text = '\u{254B}' }
            },
            on_attach = function(bufnr)
              local gs = require('gitsigns')

              local mapkey = vim.keymap.set
              local function map(keys, action)
                mapkey('n', keys, action, { noremap = true, buffer = bufnr })
              end

              map('<leader>hp', gs.preview_hunk)
            end
          }
        end
  }
  use { 'sindrets/diffview.nvim',
        requires = 'nvim-lua/plenary.nvim',
  }
  use { 'TimUntersberger/neogit',
        requires = 'nvim-lua/plenary.nvim',
        config = function()
          require('neogit').setup {
            disable_commit_confirmation = true,
            integrations = {
              diffview = true,
            },
          }
        end
  }
  -- PLUGINS END

  if packerbootstrap then
    require('packer').sync()
  end
end)
