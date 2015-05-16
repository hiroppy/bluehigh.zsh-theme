#!/usr/bin/env zsh
#local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

setopt promptsubst

autoload -Uz vcs_info
autoload -U add-zsh-hook
autoload -Uz is-at-least

# right prompt
RPROMPT="%{$FG[195]%}%*%{$reset_color%}$(ruby ~/.oh-my-zsh/themes/battery.rb)"

PROMPT_SUCCESS_COLOR=$FG[117]
PROMPT_FAILURE_COLOR=$FG[124]
PROMPT_VCS_INFO_COLOR=$FG[242]
PROMPT_PROMPT=$FG[077]
GIT_DIRTY_COLOR=$FG[133]
GIT_CLEAN_COLOR=$FG[118]
GIT_PROMPT_INFO=$FG[012]

PROMPT='%{$PROMPT_SUCCESS_COLOR%}%~%{$reset_color%} %{$GIT_PROMPT_INFO%}$(git_prompt_info)%{$GIT_DIRTY_COLOR%}$(git_prompt_status) %{$reset_color%}$PUSH_STATUS$MARGE_STATUS$STASH_STATUS$NOMERGE_MASTER_STATUS%{$PROMPT_PROMPT%} ᐅ%{$reset_color%} '

#RPS1="${return_code}"

ZSH_THEME_GIT_PROMPT_PREFIX="("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$GIT_PROMPT_INFO%})"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$GIT_DIRTY_COLOR%}✘"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$GIT_CLEAN_COLOR%}✔"

ZSH_THEME_GIT_PROMPT_ADDED="%{$FG[082]%}👻 %{$reset_color%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$FG[166]%}😱 %{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$FG[160]%}✖%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$FG[220]%}➜%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$FG[207]%} <!merge>%{$reset_color%}"
# ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$FG[190]%}✭%{$reset_color%}"


if is-at-least 4.3.10; then
  zstyle ':vcs_info:git:*' formats '(%s)-[%b]' '%c%u %m'
  zstyle ':vcs_info:git:*' check-for-changes true
fi

# hooks
if is-at-least 4.3.11; then
  zstyle ':vcs_info:git+set-message:*' hooks \
                                        git-hook-begin \
                                        git-untracked \
                                        git-push-status \
                                        git-nomerge-branch \
                                        git-nomerge-master \
                                        git-stash-count

  function +vi-git-hook-begin() {
    if [[ $(command git rev-parse --is-inside-work-tree 2> /dev/null) != 'true' ]]; then
      return 1
    fi
    return 0
  }

  function +vi-git-untracked() {
    if [[ "$1" != "1" ]]; then
      return 0
    fi

    if command git status --porcelain 2> /dev/null \
      | awk '{print $1}' \
      | command grep -F '??' > /dev/null 2>&1 ; then

      ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$FG[190]%}⚡️%{$reset_color%}"
    fi
  }

  function +vi-git-push-status() {
    if [[ "$1" != "1" ]]; then
      return 0
    fi

    if [[ "${hook_com[branch]}" != "master" ]]; then
      PUSH_STATUS=""
      return 0
    fi

    local ahead
    ahead=$(command git rev-list origin/master..master 2>/dev/null \
      | wc -l \
      | tr -d ' ')

    if [[ "$ahead" -gt 0 ]]; then
      PUSH_STATUS="%{$FG[148]%}🔔 :P${ahead}:%{$reset_color%}"
    else
      PUSH_STATUS=""
    fi
  }

  function +vi-git-nomerge-branch() {
    if [[ "$1" != "1" ]]; then
      return 0
    fi

    if [[ "${hook_com[branch]}" == "master" ]]; then
      MARGE_STATUS=""
      return 0
    fi

    local nomerged
    nomerged=$(command git rev-list master..${hook_com[branch]} 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$nomerged" -gt 0 ]] ; then
      MARGE_STATUS="%{$FG[208]%}🎃 :M${nomerged}:%{$reset_color%}"
    else
      MARGE_STATUS=""
    fi
  }

  function +vi-git-stash-count() {
    if [[ "$1" != "1" ]]; then
      return 0
    fi

    local stash
    stash=$(command git stash list 2>/dev/null | wc -l | tr -d ' ')
    if [[ "${stash}" -gt 0 ]]; then
      STASH_STATUS="%{$FG[033]%}📬 :S${stash}:%{$reset_color%}"
    else
      STASH_STATUS=""
    fi
  }

fi

function +vi-git-nomerge-master() {
  if [[ "$1" != "1" ]]; then
    return 0
  fi

  if [[ "${hook_com[branch]}" == "master" ]]; then
    NOMERGE_MASTER_STATUS=""
    return 0
  fi

  if command git branch --no-merged 2>/dev/null | command grep 'master' > /dev/null 2>&1 ; then
    NOMERGE_MASTER_STATUS="%{$FG[199]%}🚨 :R:%{$reset_color%}"
  else
    NOMERGE_MASTER_STATUS=""
  fi
}

function _update_vcs_info_msg() {
  LANG=en_US.UTF-8 vcs_info

  if [[ -z ${vcs_info_msg_0_} ]]; then
    STASH_STATUS=""
    MARGE_STATUS=""
    PUSH_STATUS=""
    NOMERGE_MASTER_STATUS=""
  fi
}

add-zsh-hook precmd _update_vcs_info_msg
