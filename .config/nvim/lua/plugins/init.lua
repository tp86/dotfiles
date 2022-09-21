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
              side = 'right'
            }
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
            }
          }
        end,
  }
  -- PLUGINS END

  if packerbootstrap then
    require('packer').sync()
  end
end)
