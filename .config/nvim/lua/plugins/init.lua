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
        requires = {
          'kyazdani42/nvim-web-devicons', --[[ requires patched font ]]
          'rktjmp/git-info.vim',
        },
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
                    local changes = fn['git_info#changes']()
                    if changes.changed + changes.untracked > 0 then
                      name = name .. '*'
                    end
                    return name
                  end,
                  cond = function() return optlocal.buftype:get() ~= 'terminal' end,
                },
              },
              lualine_c = {
                {
                  function()
                    local bufname = fn.bufname()
                    local filename = fn.fnamemodify(bufname, ':t')
                    if #filename == 0 then
                      return '[No Name]'
                    end
                    local filetype = optlocal.filetype:get()
                    if filetype == 'help' then
                      return filename
                    end
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
                    local venv = os.getenv('VIRTUAL_ENV')
                    if venv then
                      return '(' .. fn.fnamemodify(venv, ':t') .. ')'
                    end
                    return ''
                  end,
                  cond = function()
                    return optlocal.filetype:get() == 'python'
                  end,
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
            tabline = {
              lualine_a = {
                'tabs',
              }
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
              enable = true,
              additional_vim_regex_highlighting = true,
            },
          }
          opt.foldmethod = 'expr'
          opt.foldexpr = 'nvim_treesitter#foldexpr()'
          opt.foldenable = false
        end,
  }
  use { 'hrsh7th/nvim-cmp',
        requires = {
          'hrsh7th/cmp-buffer',
          'hrsh7th/cmp-nvim-lsp',
          'saadparwaiz1/cmp_luasnip',
          { 'L3MON4D3/LuaSnip',
            config = function()
              require('luasnip.loaders.from_vscode').lazy_load()
            end,
          },
        },
        config = function()
          local opt = vim.opt
          opt.completeopt = { 'menu', 'menuone', 'noselect' }
          local cmp = require('cmp')
          local luasnip = require('luasnip')
          cmp.setup {
            snippet = {
              expand = function(args)
                luasnip.lsp_expand(args.body)
              end,
            },
            sources = cmp.config.sources(
              {
                { name = 'nvim_lsp', keyword_length = 3 },
                { name = 'buffer', keyword_length = 3 },
                { name = 'luasnip', keyword_length = 2 },
              }
            ),
            mapping = cmp.mapping.preset.insert {
              ['<c-j>'] = cmp.mapping(function()
                if cmp.visible() then
                  cmp.select_next_item()
                else
                  cmp.complete()
                end
              end, { 'i', 's' }),
              ['<c-k>'] = cmp.mapping(function()
                if cmp.visible() then
                  cmp.select_prev_item()
                else
                  cmp.complete()
                end
              end, { 'i', 's' }),
              ['<c-u>'] = cmp.mapping.scroll_docs(-4),
              ['<c-d>'] = cmp.mapping.scroll_docs(4),
              ['<c-e>'] = cmp.mapping.abort(),
              ['<c-l>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.confirm { select = true }
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                else
                  fallback()
                end
              end, { 'i', 's' }),
              ['<c-h>'] = cmp.mapping(function(fallback)
                if luasnip.jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end, { 'i', 's' }),
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
          map('<leader>gb', builtin.git_branches)

          telescope.load_extension('fzf')
        end
  }
  use { 'lewis6991/gitsigns.nvim',
        config = function()
          require('gitsigns').setup {
            signs = {
              changedelete = { hl = 'GitSignsDelete', text = '┃' }
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
        config = function()
          require('diffview').setup {
            view = {
              merge_tool = {
                layout = 'diff3_mixed',
                disable_diagnostics = true,
              },
            },
          }
        end,
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
