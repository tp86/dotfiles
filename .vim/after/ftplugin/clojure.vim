"inoremap <buffer> <c-\> #()<esc>i
"nnoremap <buffer> K :call zepl#send('(doc ' .. expand('<cword>') .. ')')<cr>
"nnoremap <buffer> Y :call zepl#send('(source ' .. expand('<cword>') .. ')')<cr>

command! -buffer StartRepl term ++hidden clj -M:cider-clj

let g:clojure_align_subforms = 1

setlocal noshiftround

if !exists("b:undo_ftplugin")
  let b:undo_ftplugin = ""
endif
let b:undo_ftplugin ..= "|setlocal shiftround<"
