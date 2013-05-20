"========================================================
" Highlight All Function
"========================================================
"highlight Functions
syn match cFuntions display "[a-zA-Z_]\{-1,}\s\{-0,}(\{1}"ms=s,me=e-1
hi def link cFuntions Title
syn match   cFunction "\<[a-zA-Z_][a-zA-Z_0-9]*\>[^()]*)("me=e-2
syn match   cFunction "\<[a-zA-Z_][a-zA-Z_0-9]*\>\s*("me=e-1

"hi cFunction cterm=bold ctermfg=4 gui=NONE guifg=#504301
"hi cFunction cterm=bold ctermfg=4 gui=NONE guifg=#504301
