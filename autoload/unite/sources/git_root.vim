let s:save_cpo = &cpo
set cpo&vim

" Inherit from file_rec/git.
let s:origin = unite#sources#rec#define()[4]
let s:git_root = deepcopy(s:origin)
let s:git_root['name'] = 'git_root'
let s:git_root['description'] = 'candidates from git repository recursive'
let s:git_root['matchers'] = ['matcher_default', 'matcher_hide_hidden_files']

function! s:is_available()
    if !executable('git')
        return 0
    endif
    call unite#util#system('git rev-parse')
    return unite#util#get_last_status() == 0
endfunction

function! s:git_root.hooks.on_init(args, context)
    if !s:is_available()
        call unite#print_source_error('The directory is not in git repository.', s:git_root.name)
        return
    endif
    return s:origin.hooks.on_init(a:args, a:context)
endfunction

function! s:git_root.gather_candidates(args, context)
  if !unite#util#has_vimproc()
    call unite#print_source_message('vimproc plugin is not installed.', self.name)
    let a:context.is_async = 0
    return []
  endif

  let git_dir = finddir('.git', ';')
  if git_dir == ''
    " Not in git directory.
    call unite#print_source_message('Not in git directory.', self.name)
    let a:context.is_async = 0
    return []
  endif


  let directory = fnamemodify(git_dir, ':p:h:h')
  let directory_normpath = unite#util#substitute_path_separator(directory)
  let a:context.source__directory = directory_normpath . '/'
  
  call unite#print_source_message('repository: ' . directory_normpath, self.name)

  let command = g:unite_source_rec_git_command . ' ls-files --full-name ' . join(a:args) . ' ' . shellescape(directory)
  let args = vimproc#parser#split_args(command) + a:args
  if empty(args) || !executable(args[0])
    call unite#print_source_message('git command : "'. command.'" is not executable.', self.name)
    let a:context.is_async = 0
    return []
  endif

  let a:context.is_async = 1
  let a:context.source__proc = vimproc#popen3(command)
  call a:context.source__proc.stdin.close()

  return []
endfunction


function! s:git_root.async_gather_candidates(args, context)
  if !has_key(a:context, 'source__proc')
    let a:context.is_async = 0
    return []
  endif

  let stderr = a:context.source__proc.stderr
  if !stderr.eof
    let errors = filter(unite#util#read_lines(stderr, 200), "v:val !~ '^\\s*$'")
    if !empty(errors)
      call unite#print_source_error(errors, s:git_root.name)
    endif
  endif

  let stdout = a:context.source__proc.stdout
  let paths = map(filter(unite#util#read_lines(stdout, 2000), 'v:val != ""'),
                       \ "unite#util#iconv(v:val, 'char', &encoding)")
  
  if stdout.eof
    let a:context.is_async = 0
    call a:context.source__proc.waitpid()
  endif

  if unite#util#is_windows()
    let paths = map(paths, "unite#util#substitute_path_separator(v:val)")
  endif

  return map(paths, "{
        \   'word' : v:val,
        \   'action__path' : a:context.source__directory . v:val,
        \}")
endfunction

function! unite#sources#git_root#define()
    return s:git_root
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
