inoremap <buffer> <c-\> λ

setlocal shiftwidth=1

if !exists("b:undo_ftplugin")
  let b:undo_ftplugin = ""
endif
let b:undo_ftplugin ..= "|setlocal shiftwidth<"
