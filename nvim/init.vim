" let s:vim_home = fnamemodify($MYVIMRC, ':p:h')

if has('win32')
  let s:vim_home = expand($USERPROFILE..'/.nvim')
elseif has('unix')
  let s:vim_home = expand($HOME..'/.config/nvim')
endif
let &runtimepath = s:vim_home..','..&runtimepath
let s:plug_file = expand(s:vim_home..'/autoload/plug.vim')
if empty(glob(s:plug_file))
  let s:curl = 'curl'
  if has('win32')
    let s:curl ..= '.exe'
  endif
  silent execute '!' .. s:curl .. ' -fLo ' .. s:plug_file .. ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
"   autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

let mapleader = " "
let maplocalleader = " "

call plug#begin()

Plug 'tpope/vim-surround'
Plug 'asvetliakov/vim-easymotion'
map s <plug>(easymotion-s2)

call plug#end()

noremap H ^
noremap L $

nnoremap <backspace> u

augroup search_hl
  autocmd!
  set nohlsearch
  autocmd CmdLineEnter /,\? set hlsearch
  autocmd CmdLineLeave /,\? set nohlsearch
augroup end

set clipboard+=unnamed

nnoremap <silent> [<cr> <cmd>call luaeval("require'edit'.insert_empty_lines(_A)", {"above": 1, "count": v:count1})<cr>
nnoremap <silent> ]<cr> <cmd>call luaeval("require'edit'.insert_empty_lines(_A)", {"count": v:count1})<cr>

" Experimental: autosave when leaving insert mode working in vscode
inoremap <esc> <c-o>:w<cr><esc>
