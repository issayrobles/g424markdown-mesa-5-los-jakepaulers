function enrich {
    flag=$1
    symbol=$2
    if [[ -n $3 ]]
    then
	coloron=$3
    else
	coloron=${on}
    fi
    if [[ $flag == true ]]; then color="${coloron}"; else color="${off}"; fi
    PS1="${PS1}${color}${symbol}${reset} "
}

function build_prompt {
    PS1=""
    # Symbols
    if [[ -z "${is_a_git_repo_symbol}" ]]; then is_a_git_repo_symbol="❤"; fi
    if [[ -z "${has_untracked_files_symbol}" ]]; then has_untracked_files_symbol="∿"; fi
    if [[ -z "${has_adds_symbol}" ]]; then has_adds_symbol="+"; fi
    if [[ -z "${has_deletions_symbol}" ]]; then has_deletions_symbol="-"; fi
    if [[ -z "${has_deletions_cached_symbol}" ]]; then has_deletions_cached_symbol="✖"; fi
    if [[ -z "${has_modifications_symbol}" ]]; then has_modifications_symbol="✎"; fi
    if [[ -z "${has_modifications_cached_symbol}" ]]; then has_modifications_cached_symbol="→"; fi
    if [[ -z "${is_on_a_tag_symbol}" ]]; then is_on_a_tag_symbol="⌫"; fi
    if [[ -z "${needs_to_merge_symbol}" ]]; then needs_to_merge_symbol="ᄉ"; fi
    if [[ -z "${has_upstream_symbol}" ]]; then has_upstream_symbol="⇅"; fi
    if [[ -z "${detached_symbol}" ]]; then detached_symbol="⚯"; fi
    if [[ -z "${can_fast_forward_symbol}" ]]; then can_fast_forward_symbol="»"; fi
    if [[ -z "${has_diverged_symbol}" ]]; then has_diverged_symbol="Ⴤ"; fi
    if [[ -z "${rebase_tracking_branch_symbol}" ]]; then rebase_tracking_branch_symbol="↶"; fi
    if [[ -z "${merge_tracking_branch_symbol}" ]]; then merge_tracking_branch_symbol="ᄉ"; fi

    # flags
    if [[ -z "${display_has_upstream}" ]]; then display_has_upstream=false; fi
    if [[ -z "${display_tag}" ]]; then display_tag=false; fi
    if [[ -z "${display_tag_name}" ]]; then display_tag_name=true; fi
    if [[ -z "${two_lines}" ]]; then two_lines=true; fi
    if [[ -z "${finally}" ]]; then finally="\w ∙ "; fi

    # Colors
    on="\[\033[0;37m\]"    
    off="\[\033[1;30m\]"
    alert="\[\033[0;31m\]"
    green="\[\033[0;32m\]"
    yellow="\[\033[0;33m\]"
    branch_color="\[\033[0;34m\]"
    blinking="\[\033[1;5;17m\]"
    reset="\[\033[0m\]"

    # Git info
    current_commit_hash=$(git rev-parse HEAD 2> /dev/null)
    current_commit_hash_abbrev=$(git rev-parse --short HEAD 2> /dev/null)
    if [[ -n $current_commit_hash ]]; then is_a_git_repo=true; else is_a_git_repo=false; fi

    number_of_logs=$(git log 2>/dev/null| wc -l)
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); 

    if [[ $current_branch == "HEAD" ]]; then detached=true; else detached=false; fi


    if [ $is_a_git_repo == true -a $number_of_logs == 0 ]; then just_init=true; fi

    if [ $is_a_git_repo == true -a $number_of_logs -gt 0 ]; then 

	upstream=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
	if [[ $upstream != "@{upstream}" ]]; then has_upstream=true; else has_upstream=false; upstream=""; fi
    
	number_of_modifications=$(git status --short 2> /dev/null|grep --count -e ^\.M)
	if [[ ${number_of_modifications} -gt 0 ]] ; then  has_modifications=true; else has_modifications=false;  fi
	
	number_of_adds=$(git status --short 2> /dev/null|grep --count -e ^\A)
	if [[ ${number_of_adds} -gt 0 ]] ; then  has_adds=true; else has_adds=false;  fi

	number_of_deletions=$(git status --short 2> /dev/null|grep --count -e ^.D)
	if [[ ${number_of_deletions} -gt 0 ]] ; then  has_deletions=true; else has_deletions=false;  fi
	number_of_deletions_cached=$(git status --short 2> /dev/null|grep --count -e ^D)
	if [[ ${number_of_deletions_cached} -gt 0 ]] ; then  has_deletions_cached=true; else has_deletions_cached=false;  fi

	number_of_modifications_cached=$(git status --short 2> /dev/null|grep --count -e ^[MA])
	if [[ ${number_of_modifications_cached} -gt 0 ]] ; then has_modifications_cached=true; else has_modifications_cached=false;  fi

	number_of_untracked_files=$(git status --short 2> /dev/null|grep --count -e ^\?\?)
	if [[ ${number_of_untracked_files} -gt 0 ]] ; then has_untracked_files=true; else has_untracked_files=false;  fi
	
	commits_ahead=$(git rev-list --left-right ${current_branch}...${upstream} -- 2>/dev/null | grep -c '^<')
	commits_behind=$(git rev-list --left-right ${current_branch}...${upstream} -- 2>/dev/null | grep -c '^>')


	tag_at_current_commit=$(git describe --exact-match --tags ${current_commit_hash} 2>/dev/null)
	if [[ -n "${tag_at_current_commit}" ]]; then is_on_a_tag=true; else is_on_a_tag=false; fi;

	has_diverged=true
	can_fast_forward=false
	if [[ $(git log --topo-order --format='%H' ${current_commit_hash}^..${upstream} | grep -c ${current_commit_hash}) == 1 ]]; then has_diverged=false; fi
	if [[ ${has_diverged} == false ]];
	then
	    commits_from_current_to_remote=$(git log --topo-order --format='%H' ${current_commit_hash}..${upstream} | wc -l )
	    if [[ ${commits_from_current_to_remote} -gt 0 ]]; then
		can_fast_forward=true
	    fi
	fi

	will_rebase=$(git config --get branch.${current_branch}.rebase 2>/dev/null)
    fi
	

    if [[ ${is_a_git_repo} == true ]]
    then
	enrich ${is_a_git_repo} "${is_a_git_repo_symbol}"
	enrich ${has_untracked_files} "${has_untracked_files_symbol}"
	enrich ${has_adds} "${has_adds_symbol}"

	enrich ${has_deletions} "${has_deletions_symbol}"
	enrich ${has_deletions_cached} "${has_deletions_cached_symbol}"

	enrich ${has_modifications} "${has_modifications_symbol}"
	enrich ${has_modifications_cached} "${has_modifications_cached_symbol}"


	if [[ ${display_tag} == true ]]; then
	    enrich ${is_on_a_tag} "${is_on_a_tag_symbol}"
	fi
	enrich ${detached} "${detached_symbol}" "${alert}"

	if [[ ${display_has_upstream} == true ]]; then
	    enrich ${has_upstream} "${has_upstream_symbol}"
	fi

	if [[ ${detached} == true ]]
	then
	    if [[ ${just_init} == true ]]; then
		PS1="${PS1} ${alert}detached"
	    else
		PS1="${PS1} ${on}(${current_commit_hash_abbrev})"
	    fi
	else
	    if [[ $has_upstream == true ]]
	    then
		if [[ ${will_rebase} ]]; 
		then 
		    type_of_upstream="${rebase_tracking_branch_symbol}"; 
		else
		    type_of_upstream="${merge_tracking_branch_symbol}"; 
		fi

		if [[ ${has_diverged} == true ]]; then
		    PS1="${PS1} ${has_diverged_symbol}"
		else

		    behind_ahead_value=""
		    if [[ ${commits_ahead} -gt 0 ]]; then
			behind_ahead_value="+${commits_ahead}"
		    fi
		    if [[ ${commits_behind} -gt 0 ]]; then
			behind_ahead_value="-${commits_behind}"
		    fi
		    PS1="${PS1} ${on} ${can_fast_forward_symbol} ${behind_ahead_value}"
		
		fi

		PS1="${PS1} (${green}${current_branch}${reset} ${type_of_upstream} ${upstream//\/$current_branch/})"
	    else
		PS1="${PS1} ${on}(${green}${current_branch}${reset})"
	    fi
	fi

	if [ ${display_tag_name} == true -a ${is_on_a_tag} == true ];
	then
	    PS1="${PS1} ${yellow}[${tag_at_current_commit}]${reset}"
	fi

    fi

    if [[ ${two_lines} ]]; then break="\n"; fi
    PS1="${PS1}${reset}${break}${finally}"

}


detached_symbol="D"
PROMPT_COMMAND=build_prompt

