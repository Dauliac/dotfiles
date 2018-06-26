function fzf_select
{
    pattern=$(ratpoison -c "prompt > ")
    if [[ "$pattern" == "" ]];
    then
        exit 0
    fi

    window_list=$(ratpoison -c "windows %c")
    selected=$(echo "$window_list" | fzf -q "$pattern" -1 -0)

    if [[ "$selected" != "" ]];
    then
        ratpoison -c "select $selected"
    else
        ratpoison -c "echo [!] There is no a matching window for \"$pattern\""
    fi
}


case $1 in
    'ratmen')
        ratmen_select
        ;;
    'fzf')
        fzf_select
        ;;
esac
