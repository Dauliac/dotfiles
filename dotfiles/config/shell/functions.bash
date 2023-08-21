# Global
function extract {
	if [ -f "$1" ]; then
		case $1 in
		*.tar.bz2) tar xvjf "$1" ;;
		*.tar.gz) tar xvf "$1" ;;
		*.bz2) bunzip2 "$1" ;;
		*.rar) rar x "$1" ;;
		*.gz) gunzip "$1" ;;
		*.tar) tar xvf "$1" ;;
		*.tbz2) tar xvjf "$1" ;;
		*.tgz | *.tar.gz) tar xvzf "$1" ;;
		*.zip) unzip "$1" ;;
		*.Z) uncompress "$1" ;;
		*.7z) 7z x "$1" ;;
		*.xz) unxz "$1" ;;
		*) echo "don't know how to extract '$1'..." ;;
		esac
	else
		echo "'$1' is not a valid file!"
	fi
}

function replace {
	find . -type f -exec sed -i "s/$1/$2/g" {} +
}

function notif() {
	"$@" && notify-send "Job finished!" || notify-send "Job failed!"
}

# Screenshot
function screenshot {
	file="/tmp/$(date '+%Y-%m-%d-%M-%S')_screenshot.png"
	scrot -s "$file"
	de
	xclip -selection clipboard -t image/png -i "$file"
	rm -f "$file"
}

# Tmux
function tns {
	label=$(basename "$PWD" | sed -E "s/\.|\\|\/|\:|\~|\-|\|//g")
	if [ ! -z "$1" ]; then
		label=$1
	fi
	tmux new-session -d -s "$label" && [[ -n "$TMUX" ]] &&
		tmux switch-client -t "$label" ||
		tmux attach
}
# Docker
#docker remove all
function dra {
	docker rm "$(docker ps -aq)"
}
#docker stop all
function dsa {
	docker stop "$(docker ps -aq)"
}

#docker prune all
function dpa {
	echo stop containers
	dsa
	echo remove containers
	dra
	echo prune networks..
	docker network prune -f
	echo prune volumes..
	docker volume prune -f
}

# Fzf
function gfb {
	# git checkout $(git branch | fzf | awk '{print $2}')
	local tags branches target
	tags=$(
		git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}'
	) || return
	branches=$(
		git branch --all | grep -v HEAD |
			sed "s/.* //" | sed "s#remotes/[^/]*/##" |
			sort -u | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}'
	) || return
	target=$(
		(
			echo "$tags"
			echo "$branches"
		) |
			fzf --no-hscroll --no-multi --delimiter="\t" -n 2 \
				--ansi --preview="git log -200 --pretty=format:%s $(echo {+2..} | sed 's/$/../')"
	) || return
	git checkout "$(echo "$target" | awk '{print $2}')"
}

function scratch {
	"$EDITOR" "$(openssl rand -base64 10 | tr -dc 'a-zA-Z')"
}

function work {
	cd "$(ghq root)/$(ghq list | fzf)"
}
