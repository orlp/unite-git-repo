let s:save_cpo = &cpo
set cpo&vim

" We call this to make sure g:unite_source_rec_git_command exists.
call unite#sources#rec#define()

let s:git_repo = {
  \ 'name' : 'file_rec/git_repo',
  \ 'description' : 'candidates from entire git repository, recursive',
  \ 'hooks' : {},
  \ 'default_kind' : 'file',
  \ 'max_candidates' : 50,
  \ 'ignore_globs' : [
  \         '.', '*~', '*.o', '*.exe', '*.bak',
  \         'DS_Store', '*.pyc', '*.sw[po]', '*.class',
  \         '.hg/**', '.git/**', '.bzr/**', '.svn/**',
  \         'tags', 'tags-*'
  \ ],
  \ 'matchers' : ['matcher_default', 'matcher_hide_hidden_files'],
  \ }

function! s:git_repo.gather_candidates(args, context)
    if !unite#util#has_vimproc()
        call unite#print_source_message('vimproc plugin is not installed.', self.name)
        let a:context.is_async = 0
        return []
    endif

    let git_dir = finddir('.git', ';')
    if git_dir == ''
        " Not in git repository.
        call unite#print_source_message('Not in git repository.', self.name)
        let a:context.is_async = 0
        return []
    endif

    let repo_root = fnamemodify(git_dir, ':p:h:h')
    let repo_root_normpath = unite#util#substitute_path_separator(repo_root)

    call unite#print_source_message('repository: ' . repo_root_normpath, self.name)

    let a:context.source__repo_root = repo_root_normpath . '/'
    let a:context.source__repos = ['']
    let a:context.is_async = 1

    return self.async_gather_candidates(a:args, a:context)
endfunction

function! s:git_repo.async_gather_candidates(args, context)
    if len(a:context.source__repos) == 0
        let a:context.is_async = 0
        return []
    endif

    let repo_prefix = remove(a:context.source__repos, 0)

    let command = g:unite_source_rec_git_command . ' ls-files --full-name ' . join(a:args)
    let old_cwd = getcwd()
    call unite#util#lcd(a:context.source__repo_root . repo_prefix)
    let paths = split(vimproc#system2(command), '\n')
    call unite#util#lcd(old_cwd)

    let candidates = []
    for relpath in paths
        let path = repo_prefix . relpath
        if path[-1:] ==# '/'
            call add(a:context.source__repos, path)
        else
            call add(candidates, {'word': path, 'action__path': a:context.source__repo_root . path})
        endif
    endfor

    return candidates
endfunction


function! unite#sources#repo_orlp#define()
    return s:git_repo
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
