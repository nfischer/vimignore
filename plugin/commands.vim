""
" @section Introduction, intro
" @stylized Vimignore
" @order Introduction fugitive-integration commands
"
" I came up with the idea for this plugin when I was working on various projects
" with partners and would need to reconfigure the gitignore file for the
" project. I had to do this often enough that I felt that it should flow more
" natively in vim.
"
" I decided to make this plugin to facilitate the process. @plugin(stylized)
" offers a few different commands for making sure the appropriate files are
" ignored.

""
" @section Fugitive Integration
"
" The best way to use this plugin is in conjunction with Tim Pope's fugitive
" plugin (www.github.com/tpope/vim-fugitive). In particular, when using the
" |:Gstatus| command, @plugin(stylized) adds a mapping on I.
"
" Press 'I' when viewing the git index (|:Gstatus| window) to add the file on
" the current line to the gitignore list and update the git index accordingly.

""
" @private
" This is my function. There are many like it, but this one is mine
function! s:GIgnoreFileOnLine()
  let l:line_text = getline('.')
  let l:match = matchlist(l:line_text, '^#\t\S\+:\s\+\(\S\+\)$')
  try
    let l:fname = l:match[1]
    call vimignore#IgnoreFiles('', '', l:fname)
  catch /E684/
    echohl ErrorMsg | echo 'Could not detect filename' | echohl NONE
  endtry
endfunction

""
" Find and open the appropriate .gitignore file for editing.
"
" This also sets 'bufhidden' for this buffer as follows:
"  * If this file is already open, 'bufhidden' is not touched
"  * If the '!' is supplied, this will leave 'bufhidden' untouched
"  * Otherwise, 'bufhidden' will be set to delete
command! -nargs=0 -bang GEditIgnore call vimignore#EditGitIgnore('<bang>')

""
" Append the current file to the .gitignore list. This internally uses the
" |:GEditIgnore| command, so be aware of side effects due to compatibility
" issues with the 'hidden' option.
"
" By default, this will check the gitignore list to avoid adding duplicate
" entries. If the '!' is provided, this will not check for duplicates.
command! -nargs=0 -bang GIgnoreCurrentFile
    \ call vimignore#IgnoreFiles('<bang>', '' expand('%'))

""
" @usage {fname1} [fnames...]
" Add each file fname1, fname2, etc. to the .gitignore list. This takes one or
" more arguments
"
" By default, this will check the gitignore list to avoid adding duplicate
" entries. If the '!' is provided, this will not check for duplicates.
command! -nargs=+ -complete=file -bang GAddToIgnore call
    \ vimignore#IgnoreFiles('<bang>', '', <f-args>)

""
" Add sensible defaults to the .gitignore list. This adds .DS_Store, Vim swap
" files, and Vim backup files to the list to prevent these from winding up under
" version control.
"
" When the '!' is supplied, this will add them to the ignore list without
" checking for duplicates.
command! -nargs=0 -bang GIgnoreDefaults call vimignore#AddDefaults('<bang>')

""
" @private
" Set mappings for when we're in a git index file
" This is for fugitive integration with :Gstatus
function! s:SetIndexMappings()
  if expand('%:t') == 'index'
    nnoremap <buffer> <silent> I :call <SID>GIgnoreFileOnLine()<CR>
  endif
endfunction

""
" Set filetype mappings
augroup vimignore
  autocmd!
  autocmd FileType gitcommit call s:SetIndexMappings()
augroup END
