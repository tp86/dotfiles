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
          require('lualine').setup {
            -- TODO custom configuration
            -- - git dirty status (not detailed diff)
            -- - git branch shorter
            -- - filename with short path
            -- - right side rearrangement
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
                       -- requires cmake, make, gcc/clang
                       run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && \z
                              cmake --build build --config Release && \z
                              cmake --install build --prefix build'
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
  -- PLUGINS END

  if packerbootstrap then
    require('packer').sync()
  end
end)
