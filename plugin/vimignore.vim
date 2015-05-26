function! EditGitIgnore()
    " set split preference
    let make_split = 'split'
    if exists('g:gsplit_pref') && g:gsplit_pref == 1
        let make_split = 'vsp'
    endif

    " If we've already found the gitignore file, use it!
    if exists('g:gitignore') && filereadable(g:gitignore)
        " echo 'already has gitignore'
        " break
    else
        " echo 'finding .gitignore'
        " First, figure out if this is a git repo
        let git_dir = system('git rev-parse --git-dir 2>/dev/null')
        if git_dir == ''
            echohl ErrorMsg
            echo 'Error: this is not a Git repository'
            echohl NONE
            return
        endif

        " Strip trailing newline
        let git_dir = git_dir[:-2]

        let root_dir = fnamemodify(git_dir, ':p:h:h')
        let root_ignore = root_dir . '/.gitignore'

        if filereadable(root_ignore)
            let g:gitignore = root_ignore
        else
            redir @z
            pwd
            redir END
            let cur_dir = @z
            let cur_dir = cur_dir[1:]

            " Begin looking for .gitignore
            while !isdirectory('.git')
                if filereadable('.gitignore')
                    " If we found a gitignore file here, let's choose it
                    let g:gitignore = fnamemodify('.gitignore', ':p')
                    exe 'cd ' . cur_dir
                    break
                else
                    " Try one directory up
                    cd ..
                endif
            endwhile
        endif

        if !exists('g:gitignore')
            let g:gitignore = root_ignore
        endif
        " echo 'end'
    endif
    " edit ign_file
    if expand('%') == ''
        exe 'edit ' . g:gitignore
    else
        exe make_split . ' ' . g:gitignore
    endif
endfunction

function! SetCommands()
    command! -buffer Gignore call EditGitIgnore()
endfunction

augroup vimignore
    autocmd!
    autocmd BufNewFile,BufReadPost * call SetCommands()
augroup END
