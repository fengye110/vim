" File: myfind.vim
" Author: yao.j
" Version: 0.01
" Last Modified: April 20, 2013
" 
" Overview
" --------
"
" Usage
" -----
" The Find.vim plugin introduces the following Vim commands:
"
" :Filefind          - Search for the specified pattern in the specified files
"
"    :Filefind   [<Find_options>] [<search_pattern> [<file_name(s)>]]
"
"
" Configuration
" -------------
" The 'Find_Find_Path' variable is used to locate the find utility. By
" default, this is set to d:\tools\find.exe. You can change this using the let
" command:
"
"       :let Find_Path = 'd:\tools\find.exe'
"       :let Find_Xargs_Path = 'd:\tools\xargs.exe'
"
"       :let Find_Default_Filelist = '*.[chS]'
"       :let Find_Default_Filelist = '*.c *.cpp *.asm'
"       :let Find_Skip_Dirs = 'dir1 dir2 dir3'
"       :let Find_Skip_Files = '*.bak *~'
"
" By default, when you invoke the Find commands the quickfix window will be
" opened with the Find output.  You can disable opening the quickfix window,
" by setting the 'Find_OpenQuickfixWindow' variable  to zero:
"
"       :let Find_OpenQuickfixWindow = 0
"
" You can manually open the quickfix window using the :cwindow command.
"
" By default, for recursive searches, the 'find' and 'xargs' utilities are
" used.  If you don't have the 'xargs' utility or don't want to use the
" 'xargs' utility, " then you can set the 'Find_Find_Use_Xargs' variable to
" zero. If this is set to zero, then only the 'find' utility is used for
" recursive searches:
"
"       :let Find_Find_Use_Xargs = 0
" 
" To handle file names with space characters in them, the xargs utility is
" invoked with the '-0' argument. If the xargs utility in your system doesn't
" accept the '-0' argument, then you can change the Find_Xargs_Options
" variable. For example, to use the '--null' xargs argument, you can use the
" following command:
"
" 	:let Find_Xargs_Options = '--null'
"
" The Find_Cygwin_Find variable should be set to 1, if you are using the find
" utility from the cygwin package. This setting is used to handle the
" difference between the backslash and forward slash path separators.
"
"       :let Find_Cygwin_Find = 1
" 
" The 'Find_Null_Device' variable specifies the name of the null device to
" pass to the Find commands. This is needed to force the Find commands to
" print the name of the file in which a match is found, if only one filename
" is specified. For Unix systems, this is set to /dev/null and for MS-Windows
" systems, this is set to NUL. You can modify this by using the let command:
"
"       :let Find_Null_Device = '/dev/null'
"
" The 'Find_Shell_Quote_Char' variable specifies the quote character to use
" for protecting patterns from being interpreted by the shell. For Unix
" systems, this is set to "'" and for MS-Window systems, this is set to an
" empty string.  You can change this using the let command:
"
"       :let Find_Shell_Quote_Char = "'"
"
" The 'Find_Shell_Escape_Char' variable specifies the escape character to use
" for protecting special characters from being interpreted by the shell.  For
" Unix systems, this is set to '\' and for MS-Window systems, this is set to
" an empty string.  You can change this using the let command:
"
"       :let Find_Shell_Escape_Char = "'"
"
" --------------------- Do not modify after this line ---------------------
if exists("loaded_find")
    finish
endif
let loaded_find = 1

" Line continuation used here
let s:cpo_save = &cpo
set cpo&vim

" Location of the find utility
if !exists("Find_Path")
    let Find_Path = 'find'
endif

" Location of the xargs utility
if !exists("Find_Xargs_Path")
    let Find_Xargs_Path = 'xargs'
endif

" Open the Find output window.  Set this variable to zero, to not open
" the Find output window by default.  You can open it manually by using
" the :cwindow command.
if !exists("Find_OpenQuickfixWindow")
    let Find_OpenQuickfixWindow = 1
endif

" Default Find file list
if !exists("Find_Default_Filelist")
    let Find_Default_Filelist = '*'
endif

" Default Find options
if !exists("Find_Default_Options")
    let Find_Default_Options = ''
endif

" Use the 'xargs' utility in combination with the 'find' utility. Set this
" to zero to not use the xargs utility.
if !exists("Find_Find_Use_Xargs")
    let Find_Find_Use_Xargs = 1
endif

" The command-line arguments to supply to the xargs utility
if !exists('Find_Xargs_Options')
    let Find_Xargs_Options = '-0'
endif

" The find utility is from the cygwin package or some other find utility.
if !exists("Find_Cygwin_Find")
    let Find_Cygwin_Find = 0
endif

" NULL device name to supply to Find.  We need this because, Find will not
" print the name of the file, if only one filename is supplied. We need the
" filename for Vim quickfix processing.
if !exists("Find_Null_Device")
    if has("win32") || has("win16") || has("win95")
        let Find_Null_Device = 'NUL'
    else
        let Find_Null_Device = '/dev/null'
    endif
endif

" Character to use to quote patterns and filenames before passing to Find.
if !exists("Find_Shell_Quote_Char")
    if has("win32") || has("win16") || has("win95")
        let Find_Shell_Quote_Char = ''
    else
        let Find_Shell_Quote_Char = "'"
    endif
endif

" Character to use to escape special characters before passing to Find.
if !exists("Find_Shell_Escape_Char")
    if has("win32") || has("win16") || has("win95")
        let Find_Shell_Escape_Char = ''
    else
        let Find_Shell_Escape_Char = '\'
    endif
endif

" The list of directories to skip while searching for a pattern. Set this
" variable to '', if you don't want to skip directories.
if !exists("Find_Skip_Dirs")
    let Find_Skip_Dirs = 'RCS CVS SCCS .git'
endif

" The list of files to skip while searching for a pattern. Set this variable
" to '', if you don't want to skip any files.
if !exists("Find_Skip_Files")
    let Find_Skip_Files = '*~ *,v s.*'
endif

" Run the specified grep command using the supplied pattern
function! s:RunCmd(cmd, pattern, action)
    if has('win32') && !has('win32unix') && !has('win95')
                \ && (&shell =~ 'cmd.exe')
        " Windows does not correctly deal with commands that have more than 1
        " set of double quotes.  It will strip them all resulting in:
        " 'C:\Program' is not recognized as an internal or external command
        " operable program or batch file.  To work around this, place the
        " command inside a batch file and call the batch file.
        " Do this only on Win2K, WinXP and above.
        
        let s:find_tempfile = fnamemodify(tempname(), ':h') . '\myfind.cmd'
        if v:version >= 700
            if g:Find_Cygwin_Find == 1
                call writefile(['@echo off','set CYGWIN=nodosfilewarning',a:cmd], s:find_tempfile, "b")
            else
                call writefile([a:cmd], s:find_tempfile, "b")
            endif
        else
            exe 'redir! > ' . s:find_tempfile
            silent echo s:cmd
            redir END
        endif

	let cmd_output = system(s:find_tempfile)
    else
        let cmd_output = system(a:cmd)
    endif

    if exists('s:find_tempfile')
        " Delete the temporary cmd file created on MS-Windows
        "call delete(s:find_tempfile)
    endif

    " Do not check for the shell_error (return code from the command).
    " Even if there are valid matches, grep returns error codes if there
    " are problems with a few input files.

    if cmd_output == ""
        echohl WarningMsg | 
        \ echomsg "Error: Pattern " . a:pattern . " not found" | 
        \ echohl None
        return
    endif

    let tmpfile = tempname()

    let old_verbose = &verbose
    set verbose&vim

    exe "redir! > " . tmpfile
    silent echon '[Search results for pattern: ' . a:pattern . "]\n"
    silent echon cmd_output
    redir END

    let &verbose = old_verbose

    let old_efm = &efm
    set efm=%f:%\\s%#%l:%m

    if v:version >= 700 && a:action == 'add'
        execute "silent! caddfile " . tmpfile
    else
        if exists(":cgetfile")
            execute "silent! cgetfile " . tmpfile
        else
            execute "silent! cfile " . tmpfile
        endif
    endif

    let &efm = old_efm

    " Open the grep output window
    if g:Grep_OpenQuickfixWindow == 1
        " Open the quickfix window below the current window
        botright copen
    endif

    call delete(tmpfile)
endfunction

" Run specified Find command recursively
function! s:RunFindRecursive(cmd_name,  action, ...)
    if a:0 > 0 && (a:1 == "-?" || a:1 == "-h")
        echo 'Usage: ' . a:cmd_name . " [<Find_options>] [<search_pattern> " .
                        \ "[<file_name(s)>]]"
        return
    endif

    let Find_opt    = ""
    let pattern     = ""
    let filepattern = ""

    let argcnt = 1
    while argcnt <= a:0
        if a:{argcnt} =~ '^-'
            let Find_opt = Find_opt . " " . a:{argcnt}
        elseif pattern == ""
            let pattern = g:Find_Shell_Quote_Char . a:{argcnt} . 
                            \ g:Find_Shell_Quote_Char
        else
            let filepattern = filepattern . " " . a:{argcnt}
        endif
        let argcnt= argcnt + 1
    endwhile
    if Find_opt == ""
        let Find_opt = g:Find_Default_Options
    endif

    let Find_path = g:Find_Path
    let Find_expr_option = '--'


    let cwd = getcwd()
    if g:Find_Cygwin_Find == 1
        let cwd = substitute(cwd, "\\", "/", "g")
    endif
    if v:version >= 700
        let startdir = input("Start searching from directory: ", cwd, "dir")
    else
        let startdir = input("Start searching from directory: ", cwd)
    endif
    if startdir == ""
        return
    endif
    echo "\r"

    if filepattern == ""
        let filepattern = input("Search in files matching pattern: ", 
                                          \ g:Find_Default_Filelist)
        if filepattern == ""
            return
        endif
        echo "\r"
    endif

    let txt = filepattern . ' '
    let find_file_pattern = ''
    while txt != ''
        let one_pattern = strpart(txt, 0, stridx(txt, ' '))
        if find_file_pattern != ''
            let find_file_pattern = find_file_pattern . ' -o'
        endif
        let find_file_pattern = find_file_pattern . ' -name ' .
              \ g:Find_Shell_Quote_Char . one_pattern . g:Find_Shell_Quote_Char
        let txt = strpart(txt, stridx(txt, ' ') + 1)
    endwhile
    let find_file_pattern = g:Find_Shell_Escape_Char . '(' .
                    \ find_file_pattern . ' ' . g:Find_Shell_Escape_Char . ')'

    let txt = g:Find_Skip_Dirs
    let find_prune = ''
    if txt != ''
        let txt = txt . ' '
        while txt != ''
            let one_dir = strpart(txt, 0, stridx(txt, ' '))
            if find_prune != ''
                let find_prune = find_prune . ' -o'
            endif
            let find_prune = find_prune . ' -name ' . one_dir
            let txt = strpart(txt, stridx(txt, ' ') + 1)
        endwhile
        let find_prune = '-type d ' . g:Find_Shell_Escape_Char . '(' .
                         \ find_prune
        let find_prune = find_prune . ' ' . g:Find_Shell_Escape_Char . ')'
    endif

    let txt = g:Find_Skip_Files
    let find_skip_files = '-type f'
    if txt != ''
        let txt = txt . ' '
        while txt != ''
            let one_file = strpart(txt, 0, stridx(txt, ' '))
            let find_skip_files = find_skip_files . ' ! -name ' .
                                  \ g:Find_Shell_Quote_Char . one_file .
                                  \ g:Find_Shell_Quote_Char
            let txt = strpart(txt, stridx(txt, ' ') + 1)
        endwhile
    endif

    let cmd = g:Find_Find_Path . " " . startdir
    let cmd = cmd . " " . find_prune . " -prune -o"
    let cmd = cmd . " " . find_skip_files
    let cmd = cmd . " " . find_file_pattern
    "let cmd = cmd .  g:Find_Shell_Escape_Char . ';'

    call s:RunCmd(cmd, pattern, a:action)
endfunction


command! -nargs=* -complete=file Find
            \ call s:RunFindRecursive('Find', 'set', <f-args>)

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save
