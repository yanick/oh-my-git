# Symbols
set -l is_a_git_repo_symbol '❤'
set -l has_untracked_files_symbol '∿'
set -l has_adds_symbol '+'
set -l has_deletions_symbol '-'
set -l has_deletions_cached_symbol '✖'
set -l has_modifications_symbol '✎'
set -l has_modifications_cached_symbol '☲'
set -l ready_to_commit_symbol '→'
set -l is_on_a_tag_symbol '⌫'
set -l needs_to_merge_symbol 'ᄉ'
set -l has_upstream_symbol '⇅'
set -l detached_symbol '⚯ '
set -l can_fast_forward_symbol '»'
set -l has_diverged_symbol 'Ⴤ'
set -l rebase_tracking_branch_symbol '↶'
set -l merge_tracking_branch_symbol 'ᄉ'
set -l should_push_symbol '↑'
set -l has_stashes_symbol '★'

    # Flags
set -l display_has_upstream false
set -l display_tag false
set -l display_tag_name true
set -l two_lines true
set -l finally '\w ∙ '
set -l use_color_off false

    # Colors
set -l on "\[\033[1;37m\]"
set -l off black #"\[\033[0m\]"
set -l red red #'(set_color red)' #"\[\033[0;31m\]"
set -l green green  #"\[\033[0;32m\]"
set -l yellow yellow # "\[\033[1;33m\]"
set -l violet purple  # "\[\033[0;35m\]"
set -l branch_color brown  # "\[\033[1;34m\]"
set -l reset  "\[\033[0m\]"

function enrich 
    set -l flag $argv[1]
    set -l symbol $argv[2]
    if test (count $argv) -eq 3;
        set_color $argv[3]
    else
        set_color normal
    end

    if test $use_color_off = false -a $flag = false 
        set symbol ' '
    end

    echo -n $symbol " "
    set_color normal
    set_color -b normal
end

function build_git_prompt

    # Git info
    set current_commit_hash (git rev-parse HEAD 2> /dev/null)
    if test -n $current_commit_hash
        set is_a_git_repo true
    else
        return
    end
    
    set current_branch (git rev-parse --abbrev-ref HEAD 2> /dev/null)

    if test $current_branch = 'HEAD'
        set detached true
    else
        set detached false
    end

    set number_of_logs (git log --pretty=oneline -n1 2> /dev/null | wc -l)
    if test $number_of_logs -eq 0
        set just_init true
    else
        set upstream (git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
        if test -n "$upstream" -a "$upstream" != "@{upstream}"
            set has_upstream true
        else 
            set has_upstream false;
        end

        set git_status (git status --porcelain 2> /dev/null)
    
        if echo $git_status | grep -q -E '($\n|^).M'
            set has_modifications true
        else
            set has_modifications false
        end
    
        if echo $git_status | grep -q -E '($\n|^)M'
            set has_modifications_cached true
        else 
            set has_modifications_cached false
        end
    
        if echo $git_status | grep -q -E '($\n|^)A'
            set has_adds true
        else 
            set has_adds false
        end
    
        if echo $git_status | grep -q -E '($\n|^).D'
            set has_deletions true
        else 
            set has_deletions false
        end

        if echo $git_status | grep -q -E '($\n|^)D'
            set has_deletions_cached true
        else 
            set has_deletions_cached false
        end

        if begin
                echo $git_status | grep -q -E '($\n|^)[MAD]'; 
                and not echo $git_status | grep -q -E '($\n|^)[MAD?]';  
            end;
            set ready_to_commit true
        else
            set ready_to_commit false
        end
    
    
        set number_of_untracked_files (echo $git_status | grep -c "^??")

        if test $number_of_untracked_files -gt 0 
            set has_untracked_files true
        else 
            set has_untracked_files false
        end
    
        set tag_at_current_commit (git describe --exact-match --tags $current_commit_hash 2> /dev/null)
        if test -n $tag_at_current_commit
            set is_on_a_tag true
        else 
            set is_on_a_tag false
        end
    
        set has_diverged false
        set can_fast_forward false

        if test $has_upstream = true 
            set commits_diff (git log --pretty=oneline --topo-order --left-right {$current_commit_hash}...{$upstream} 2> /dev/null)
            set commits_ahead (echo $commits_diff | grep -c "^<" )
            set commits_behind ( echo $commits_diff | grep -c "^>")
        end

        if test $commits_ahead -gt 0 -a $commits_behind -gt 0 
            set has_diverged true
        end

        if test $commits_ahead -eq 0 -a $commits_behind -gt 0
            set can_fast_forward true
        end
    
        set will_rebase (git config --get branch.{$current_branch}.rebase 2> /dev/null)
    
        set git_dir (git rev-parse --show-toplevel)
        set stash_file = $git_dir/refs/stash
        if test -f $stash_file
            set number_of_stashes (wc -l 2> /dev/null < $stash_file )
        else
            set number_of_stashes 0
        end

        if test $number_of_stashes -gt 0
            set has_stashes true
        else 
            set has_stashes false
        end
    end
    
    enrich $is_a_git_repo $is_a_git_repo_symbol $violet
    enrich $has_stashes $has_stashes_symbol $yellow
    enrich $has_untracked_files $has_untracked_files_symbol $red
    enrich $has_adds $has_adds_symbol $yellow

    enrich $has_deletions $has_deletions_symbol $red
    enrich $has_deletions_cached $has_deletions_cached_symbol $yellow

    enrich $has_modifications $has_modifications_symbol $red
    enrich $has_modifications_cached $has_modifications_cached_symbol $yellow
    enrich $ready_to_commit $ready_to_commit_symbol $green
    
    enrich $detached $detached_symbol $red
    
    if test $display_has_upstream = true
        enrich $has_upstream $has_upstream_symbol
    end

    if test $detached = true
        if test $just_init = true
            enrich true 'detached' $red
        else
            enrich true $current_commit_hash
        end
    else
        if test $has_upstream = 'true'
            if test "$will_rebase" = true 
                set type_of_upstream $rebase_tracking_branch_symbol
            else
                set type_of_upstream $merge_tracking_branch_symbol
            end

            if test $has_diverged = true
                echo -n " -$commits_behind $has_diverged_symbol +$commits_ahead"
            else
                if test $commits_behind -gt 0 
                    echo -n " -{$commits_behind} {$can_fast_forward_symbol} "
                end
                if test $commits_ahead -gt 0
                    echo -n " {$should_push_symbol} +{$commits_ahead} "
                end
            end

            enrich true $current_branch $green
            enrich true "$type_of_upstream {$upstream}"
        else
            enrich true $current_branch $green
        end
    end

#    if [[ $display_tag == true && $is_on_a_tag == true ]]; then
#        PS1="${PS1} ${yellow}${is_on_a_tag_symbol}${reset}"
#    fi
#    if [[ $display_tag_name == true && $is_on_a_tag == true ]]; then
#        PS1="${PS1} ${yellow}[${tag_at_current_commit}]${reset}"
#    fi
#    PS1="${PS1}      "
#    
#    if [[ $two_lines == true && $is_a_git_repo == true ]]; then
#        break='\n'
#    else
#        break=''
#    fi
    
    echo -n $break $finally
end


build_git_prompt
