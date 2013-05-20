" Only do this when not done yet for this buffer
if exists("b:did_ftplugin") | finish | endif

" Don't load another plugin for this buffer
let b:did_ftplugin = 1

"setlocal ffs=unix
setlocal tabstop=4
setlocal noexpandtab
setlocal shiftwidth=4
