""
" This is my function. There are many like it, but this one is mine
function! s:SetGitIgnore()
  " First, figure out if this is a git repo

  " Set current dir (call function to silence output
  let l:cur_dir = system('pwd')
  let l:cur_dir = l:cur_dir[1:]

  " Change into the directory of the current file
  exe 'cd ' . expand('%:p:h')

  " Check for Git
  let l:git_dir = system('git rev-parse --git-dir 2>/dev/null')
  if empty(l:git_dir)
    echohl ErrorMsg
    echo 'Error: this is not a Git repository'
    echohl NONE
    exe 'cd ' . l:cur_dir
    return 1
  endif

  " Strip trailing newline
  let l:git_dir = l:git_dir[:-2]

  let l:root_dir = fnamemodify(l:git_dir, ':p:h:h')
  let l:root_ignore = l:root_dir . '/.gitignore'

  if filereadable(l:root_ignore)
    let b:gitignore = l:root_ignore
  else
    " Begin looking for .gitignore
    while !isdirectory('.git')
      if filereadable('.gitignore')
        " If we found a gitignore file here, let's choose it
        let b:gitignore = fnamemodify('.gitignore', ':p')
        exe 'cd ' . l:cur_dir
        break
      else
        " Try one directory up
        cd ..
      endif
    endwhile
  endif

  if !exists('b:gitignore')
    let b:gitignore = l:root_ignore
  endif

  return 0

endfunction

""
" This is my function. There are many like it, but this one is mine
function! vimignore#EditGitIgnore()
  " set split preference
  let l:make_split = 'split'
  if exists('g:gsplit_pref') && g:gsplit_pref == 1
    let l:make_split = 'vsp'
  endif

  " If we've already found the gitignore file, use it!
  if !exists('b:gitignore') || !filereadable(b:gitignore)
    let l:ret = s:SetGitIgnore()
    if l:ret != 0
      return 1
    endif
  endif

  if bufloaded(b:gitignore)
    let l:already_exists = 1
  endif

  if empty(expand('%'))
    exe 'edit ' . b:gitignore
  else
    exe l:make_split . ' ' . b:gitignore
  endif

  if !exists('l:already_exists')
    set bufhidden=delete
  endif

  return 0
endfunction

""
" This is my function. There are many like it, but this one is mine
function! vimignore#IgnoreFile(...)
  let l:orig_winnr = winnr()
  let l:win_pos = winsaveview()

  silent call vimignore#EditGitIgnore()
  let l:old_cursor = getpos('.')
  normal! G
  put=a:1
  call setpos('.', l:old_cursor)
  silent write | quit

  " Jump back to original file
  exe l:orig_winnr . 'wincmd w'
  call winrestview(l:win_pos)

  " Refresh the git status
  if &filetype == 'gitcommit'
    edit!
  endif
endfunction