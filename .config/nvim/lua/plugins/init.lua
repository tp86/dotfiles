local function ensurepacker()
  local fn = vim.fn
  local installpath = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(installpath)) > 0 then
    fn.system {'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', installpath}
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
          vim.keymap.set('n', '<leader>t', function() vim.cmd 'NvimTreeOpen' end)
        end
  }
  use { 'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons' --[[ requires patched font ]] },
        config = function()
          local function disableforfts(fts)
            return function()
              return not vim.tbl_contains(fts, vim.opt_local.filetype:get())
            end
          end
          require('lualine').setup {
            sections = {
              lualine_a = {
                function()
                  return vim.fn.pathshorten(vim.fn.fnamemodify(vim.fn.getcwd(), ':~'))
                end
              },
              lualine_b = {
                {
                  'branch',
                  fmt = function(s)
                    local name = s
                    if #name > 8 then
                      name = string.sub(name, 1, 8) .. '…'
                    end
                    local status = vim.fn.system(
                      [[git -C ]] .. vim.fn.fnamemodify(vim.fn.bufname(), ':p:h') .. [[ status --porcelain 2>/dev/null]]
                    )
                    if #status > 0 then
                      name = name .. '*'
                    end
                    return name
                  end,
                },
              },
              lualine_c = {
                {
                  function()
                    local bufname = vim.fn.bufname()
                    local bufnamefull = vim.fn.fnamemodify(bufname, ':p')
                    if string.find(bufnamefull, '^term://') then
                      local splittedtermuri = vim.fn.split(bufnamefull, ':')
                      local shellpid = vim.fn.fnamemodify(splittedtermuri[2], ':t')
                      local shellexec = vim.fn.fnamemodify(splittedtermuri[#splittedtermuri], ':t')
                      return table.concat({ splittedtermuri[1], shellpid, shellexec }, ':')
                    end
                    local cwdfull = vim.fn.fnamemodify(vim.fn.getcwd(), ':p')
                    local relativepath = vim.fn.matchstr(bufnamefull, [[\v^]] .. cwdfull .. [[\zs.*$]])
                    if #relativepath == 0 then
                      relativepath = bufnamefull
                    end
                    local filename = vim.fn.fnamemodify(bufname, ':t')
                    if #filename == 0 then
                      return '[No Name]'
                    end
                    local relativedir = vim.fn.fnamemodify(relativepath, ':h')
                    if relativedir == '.' then
                      return filename
                    else
                      return vim.fn.expand(vim.fn.pathshorten(relativedir) .. '/' .. filename)
                    end
                  end,
                  separator = {},
                  cond = disableforfts { 'NvimTree', 'DiffviewFiles' },
                },
                {
                  function()
                    if vim.opt_local.readonly:get() or not vim.opt_local.modifiable:get() then
                      return '[-]'
                    elseif vim.opt_local.modified:get() then
                      return '[+]'
                    else
                      return ''
                    end
                  end,
                  cond = disableforfts { 'NvimTree', 'DiffviewFiles', 'NeogitStatus' },
                }
              },
              lualine_x = {
                {
                  'filetype',
                  cond = disableforfts { 'NvimTree', 'DiffviewFiles', 'NeogitStatus' },
                },
                {
                  function()
                    local lspclients = {}
                    for _, client in pairs(vim.lsp.buf_get_clients()) do
                      lspclients[#lspclients + 1] = client.config.name
                    end
                    return table.concat(lspclients, ', ')
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
        run = function() require('nvim-treesitter.install').update{ with_sync = true} end,
        config = function()
          require('nvim-treesitter.configs').setup {
            ensure_installed = { 'python', 'lua' },
            sync_install = false,
            auto_install = true,
            highlight = {
              enable = true
            },
          }
          vim.opt.foldmethod = 'expr'
          vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
          vim.opt.foldenable = false
        end,
  }
  use 'hrsh7th/cmp-nvim-lsp'
  use { 'hrsh7th/nvim-cmp',
        config = function()
          vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
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
          local function map(keys, action)
            vim.keymap.set('n', keys, action, { noremap = true })
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
              changedelete = { text = '┻' }
            },
            on_attach = function(bufnr)
              local gs = require('gitsigns')

              local function map(keys, action)
                vim.keymap.set('n', keys, action, { noremap = true, buffer = bufnr })
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
