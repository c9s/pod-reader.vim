

fun! s:renderPodFile(path)
  silent exec 'silent read !pod2text ' . a:path
endf

fun! s:openPod(module)
  let mod = a:module
  " translate to related path
  " XXX: or just call perldoc to read module file from @INC
  "
  " XXX: write a pod translator to translate L< > tag, so that we can bind a
  " key map on them.
  let basepath = b:basepath

  let possible_paths = [ ]
  cal add(possible_paths, basepath . '/' . substitute( mod , '::' , '/' , 'g' ) . '.pod' )
  cal add(possible_paths, basepath . '/' . substitute( mod , '::' , '/' , 'g' ) . '.pm' )
  cal add(possible_paths, basepath . '/lib/' . substitute( mod , '::' , '/' , 'g' ) . '.pod' )
  cal add(possible_paths, basepath . '/lib/' . substitute( mod , '::' , '/' , 'g' ) . '.pm' )


  for f in possible_paths
    if filereadable(expand(f))
      let file_found = expand(f)
      break
    endif
  endfor

  if ! exists('file_found')
    echo "Pod not found."
    return
  endif

  new
  let b:basepath = basepath
  wincmd _
  setlocal buftype=nofile bufhidden=wipe


  let bufindex = 0
  while bufexists( mod . '-' . bufindex )
    let bufindex += 1
  endwhile

  exec 'file ' . mod . '-' . bufindex

  if filereadable( file_found )
    cal s:renderPodFile( file_found )
  else
    silent exec 'read !perldoc -T ' . mod
  endif

  " move cursor to head
  nmap <buffer><script> <CR>  :cal <SID>textLink()<CR>
  vmap <buffer><script> <CR>  :cal <SID>vtextLink()<CR>
  normal gg
endf

" get module name from visual block text
fun! s:vtextLink()
  let text = getreg('*')
  cal s:openPod(text)
endf

fun! s:textLink()
  let cword = expand('<cWORD>')
  let mod = matchstr( cword , '[A-Z]\([a-zA-Z_0-9]\+\(::\)\?\)*' )
  cal s:openPod(mod)
endf

fun! s:readPodFromLine()
  let mod = getline('.')
  cal s:openPod(mod)
endf

fun! s:startPodReader(path)

  if strlen(a:path) && isdirectory(expand(a:path))
    let basepath = expand(a:path)
  else
    if isdirectory('lib')
      let basepath = 'lib'
    else
      echo "lib directory not found."
      return 
      " XXX: find pods from perl @INC ?
    endif
  endif

  redraw
  echo "Searching pod files..."

  let pod_files = split(system('find "'. basepath .'" -type f -iname "*.pod" -or -iname "*.pm" '),"\n")
  if len(pod_files) == 0
    echo "pod file not found."
    return
  endif


  if !exists( 'g:podListIndex' )
    let g:podListIndex = 0
  endif

  while bufexists( 'PodList' . g:podListIndex )
    let g:podListIndex += 1
  endwhile

  silent tabnew
  setlocal buftype=nofile bufhidden=wipe 
  silent exec 'silent file PodList' . g:podListIndex

  let b:basepath = basepath

  cal map( pod_files , 'substitute( v:val , "'.basepath.'/\\?" , "" , "" )'  )
  cal map( pod_files , 'substitute( v:val , "^.*lib/\\?" , "" , "" )'  )
  cal map( pod_files , 'substitute( v:val , "/" , "::" , "g" )'  )
  cal map( pod_files , 'substitute( v:val , "\\.\(pod\|pm\)$" , "" , "" )'  )

  " silent 1,$delete _
  cal append(0, pod_files)

  setlocal cursorline
  setlocal nonu

  nmap <script><buffer> <CR> :cal <SID>readPodFromLine()<CR>

  normal Gddgg
endf

com! -complete=dir -narg=? PodReader :cal s:startPodReader(<q-args>)

