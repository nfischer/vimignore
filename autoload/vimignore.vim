function! s:FindGitDir()
  if exists('b:git_dir')
    return b:git_dir
  else
    let l:git_dir = system('git rev-parse --git-dir 2>/dev/null')
    if empty(l:git_dir)
      throw 'vimignore'
    endif
    " Strip trailing newline
    let l:git_dir = l:git_dir[:-2]
    return fnamemodify(l:git_dir, ':p:h')
  endif
endfunction

""
" Figure out the gitignore file and set the global variable
function! s:SetGitIgnore()
  " First, figure out if this is a git repo

  " Set current dir (call function to silence output
  let l:cur_dir = system('pwd')
  let l:old_autochdir = &l:autochdir

  " Change into the directory of the current file
  setlocal autochdir

  " Check for Git
  try
    let l:git_dir = s:FindGitDir()
  catch /vimignore/
    exe 'cd ' . l:cur_dir
    echohl ErrorMsg
    echo 'This is not a Git repository'
    echohl NONE
    throw 'vimignore'
  endtry

  let l:root_dir = fnamemodify(l:git_dir, ':h')
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

  let &l:autochdir = l:old_autochdir
  exe 'cd ' . l:cur_dir
  return 0
endfunction

function! s:RefreshGitFiles()
  if &filetype == 'gitcommit'
    silent! edit
  endif
endfunction

function! vimignore#ReloadGitIndex()
  let l:orig_buf = bufnr('%')
  bufdo call s:RefreshGitFiles()
  exe 'buffer ' . l:orig_buf
  " Restore syntax hilighting
  if !empty(&syntax)
    syntax on
  endif
endfunction

""
" @private
" This opens a file based on my preference:
"   * If I don't have a file open currently, open this with |:edit|
"   * If I'm already editing something useful, open this in a split
function! s:OpenIgnoreFile(fname)
  if empty(expand('%'))
    exe 'edit ' . a:fname
  else
    if exists('g:gsplit_pref') && g:gsplit_pref == 1
      let l:make_split = 'vsp'
    else
      let l:make_split = 'split'
    endif
    exe l:make_split . ' ' . a:fname
  endif
endfunction

""
" Open the gitignore file for edit
function! vimignore#EditGitIgnore(bang)
  " If we've already found the gitignore file, use it!
  if !exists('b:gitignore') || !filereadable(b:gitignore)
    try
      let l:ret = s:SetGitIgnore()
    catch /vimignore/
      return 1
    endtry
  endif

  if bufloaded(b:gitignore)
    call s:OpenIgnoreFile(b:gitignore)
  else
    call s:OpenIgnoreFile(b:gitignore)
    if (exists('a:bang') && empty(a:bang))
      set bufhidden=delete
    endif
  endif
  return 0
endfunction

""
" Add several files to the ignore list
function! vimignore#IgnoreFiles(...)
  let l:win_pos = winsaveview()
  let l:orig_winnr = winnr()

  silent call vimignore#EditGitIgnore()
  let l:old_cursor = getpos('.')
  normal! G
  for l:fname in a:000
    put=l:fname
  endfor
  call setpos('.', l:old_cursor)
  silent write | quit

  " Jump back to original file
  exe l:orig_winnr . 'wincmd w'
  call winrestview(l:win_pos)

  call vimignore#ReloadGitIndex()
endfunction
