function fish_greeting
  string join "" -- "Welcome to the " (set_color brred) "Fantastic " (set_color brgreen) "Fancy "  (set_color brblue) "Fish " (set_color brcyan) "Shell"
end

function fish_prompt
  set -g __fish_git_prompt_color blue
  set -g __fish_git_prompt_showcolorhints true
  set -g __fish_git_prompt_color_branch blue

  set -g __fish_git_prompt_showdirtystate true
  set -g __fish_git_prompt_showuntrackedfiles true
  set -g __fish_git_prompt_showupstream auto

  if set -q SHELL_NAME
    set_color -i magenta
    echo -n "[$SHELL_NAME] "
  end
  set_color normal
  echo -n (prompt_pwd --full-length-dirs=2)
  echo -n (fish_git_prompt)
  set_color --bold bryellow
  echo ""
  echo -n "♱ "
  set_color normal
end

function fish_right_prompt
  set -l last_status $status

  # Prompt status only if its not 0
  set -l stat
  if test $last_status -ne 0
      set stat (set_color red)"[$last_status]"(set_color normal)
  end

  echo -n "$stat"
end
