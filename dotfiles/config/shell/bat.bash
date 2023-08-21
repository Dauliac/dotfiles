# exa
# https://the.exa.website

command -v bat &> /dev/null
if [[ $? -eq 0 ]]
then
    alias cat="bat"
else
    command -v batcat &> /dev/null
    if [[ $? -eq 0 ]]
    then
        alias cat="batcat"
    fi
fi


