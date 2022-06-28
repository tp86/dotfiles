inoremap <buffer> <c-\> #()<esc>i
nnoremap <buffer> K :call zepl#send("(doc " .. expand("<cword>") .. ")")<cr>
nnoremap <buffer> Y :call zepl#send("(source " .. expand("<cword>") .. ")")<cr>
