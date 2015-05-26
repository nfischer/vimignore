function! EditGitIgnore()
    " set split preference
    let make_split = 'split'
    if exists('g:gsplit_pref') && g:gsplit_pref == 1
        let make_split = 'vsp'
    endif

    " If we've already found the gitignore file, use it!
    if !exists('b:gitignore') || !filereadable(b:gitignore)
        " First, figure out if this is a git repo
        " Get current dir
        redir @z
        pwd
        redir END
        let cur_dir = @z
        let cur_dir = cur_dir[1:]

        " Change into the directory of the current file
        exe 'cd ' . expand('%:p:h')

        " Check for Git
        let git_dir = system('git rev-parse --git-dir 2>/dev/null')
        if git_dir == ''
            echohl ErrorMsg
            echo 'Error: this is not a Git repository'
            echohl NONE
            exe 'cd ' . cur_dir
            return
        endif

        " Strip trailing newline
        let git_dir = git_dir[:-2]

        let root_dir = fnamemodify(git_dir, ':p:h:h')
        let root_ignore = root_dir . '/.gitignore'

        if filereadable(root_ignore)
            let b:gitignore = root_ignore
        else
            " Begin looking for .gitignore
            while !isdirectory('.git')
                if filereadable('.gitignore')
                    " If we found a gitignore file here, let's choose it
                    let b:gitignore = fnamemodify('.gitignore', ':p')
                    exe 'cd ' . cur_dir
                    break
                else
                    " Try one directory up
                    cd ..
                endif
            endwhile
        endif

        if !exists('b:gitignore')
            let b:gitignore = root_ignore
        endif
    endif
    " edit ign_file
    if expand('%') == ''
        exe 'edit ' . b:gitignore
    else
        exe make_split . ' ' . b:gitignore
    endif
endfunction

function! SetCommands()
    command! -buffer Gignore call EditGitIgnore()
endfunction

augroup vimignore
    autocmd!
    autocmd BufWinEnter,BufReadPost * call SetCommands()
augroup END
