#!/bin/bash


runin() {
	# Runs the arguments, piping stderr to logfile
	{ "$@" 2>>../premium-install.log || return $?; } | while read -r line; do
		printf "%s\n" "$line" >>../premium-install.log
	done
}

runout() {
	# Runs the arguments, piping stderr to logfile
	{ "$@" 2>>premium-install.log || return $?; } | while read -r line; do
		printf "%s\n" "$line" >>premium-install.log
	done
}

errorin() {
	cat ../premium-install.log
}
errorout() {
	cat premium-install.log
}

SUDO_CMD=""
if [ ! x"$SUDO_USER" = x"" ]; then
	if command -v sudo >/dev/null; then
		SUDO_CMD="sudo -u $SUDO_USER "
	fi
fi

##############################################################################

clear
clear

printf "\n\e[1;35;47m                                   \e[0m"
printf "\n\e[1;35;47m          █ █ █           \e[0m"
printf "\n\e[1;35;47m          █▀█ █            \e[0m"
printf "\n\e[1;35;47m                   \e[0m"
printf "\n\n\e[3;34;40m O‘rnatilmoqda...\e[0m\n\n"

##############################################################################

printf "\r\033[0;34mO‘rnatishga tayyorgarlik ko'rilmoqda...\e[0m"

touch premium-install.log
if [ ! x"$SUDO_USER" = x"" ]; then
	chown "$SUDO_USER:" premium-install.log
fi

if [ -d "Premium/premium" ]; then
	cd Premium || {
		printf "\rXato: Git paketini o'rnating va o'rnatuvchini qayta ishga tushiring"
		exit 6
	}
	DIR_CHANGED="yes"
fi
if [ -f ".setup_complete" ]; then
	# If premium is already installed by this script
	PYVER=""
	if echo "$OSTYPE" | grep -qE '^linux-gnu.*'; then
		PYVER="3"
	fi
	printf "\rMavjud o'rnatish aniqlandi"
	clear
	"python$PYVER" -m premium "$@"
	exit $?
elif [ "$DIR_CHANGED" = "yes" ]; then
	cd ..
fi

##############################################################################

echo "Oʻrnatilmoqda..." >premium-install.log

if echo "$OSTYPE" | grep -qE '^linux-gnu.*' && [ -f '/etc/debian_version' ]; then
	PKGMGR="apt install -y"
	runout dpkg --configure -a
	runout apt update
	PYVER="3"
elif echo "$OSTYPE" | grep -qE '^linux-gnu.*' && [ -f '/etc/arch-release' ]; then
	PKGMGR="pacman -Sy --noconfirm"
	PYVER="3"
elif echo "$OSTYPE" | grep -qE '^linux-android.*'; then
	runout apt update
	PKGMGR="apt install -y"
	PYVER=""
elif echo "$OSTYPE" | grep -qE '^darwin.*'; then
	if ! command -v brew >/dev/null; then
		ruby <(curl -fsSk https://raw.github.com/mxcl/homebrew/go)
	fi
	PKGMGR="brew install"
	PYVER="3"
else
	printf "\r\033[1;31mUnrecognised OS.\e[0m Please follow 'Manual installation' at \033[0;94mhttps://github.com/pubgcrafton/Premium/#-installation\e[0m"
	exit 1
fi

##############################################################################

runout "$SUDO_CMD $PKGMGR python$PYVER" git || {
	errorout "Asosiy oʻrnatish amalga oshmadi."
	exit 2
}


printf "\r\033[K\033[0;32mTayyorgarlik tugallandi!\e[0m"
printf "\n\r\033[0;34mLinux paketlarini o‘rnatilmoqda...\e[0m"

if echo "$OSTYPE" | grep -qE '^linux-gnu.*'; then
	runout "$SUDO_CMD $PKGMGR python$PYVER-dev"
	runout "$SUDO_CMD $PKGMGR python$PYVER-pip"
	runout "$SUDO_CMD $PKGMGR python3 python3-pip git python3-dev \
		libwebp-dev libz-dev libjpeg-dev libopenjp2-7 libtiff5 \
		ffmpeg imamgemagick libffi-dev libcairo2"
elif echo "$OSTYPE" | grep -qE '^linux-android.*'; then
	runout "$SUDO_CMD $PKGMGR openssl libjpeg-turbo libwebp libffi libcairo build-essential libxslt libiconv git ncurses-utils"
elif echo "$OSTYPE" | grep -qE '^darwin.*'; then
	runout "$SUDO_CMD$ $PKGMGR jpeg webp"
fi

runout "$SUDO_CMD $PKGMGR neofetch dialog"

printf "\r\033[K\033[0;32mPaketlar o‘rnatilgan!\e[0m"
printf "\n\r\033[0;34mRepo klonlanmoqda...\e[0m"


##############################################################################

# shellcheck disable=SC2086
${SUDO_CMD}rm -rf Premium
# shellcheck disable=SC2086
runout ${SUDO_CMD}git clone https://github.com/pubgcrafton/Premium/ || {
	errorout "Klonlash amalga oshmadi."
	exit 3
}
cd Premium || {
	printf "\r\033[0;33mRun: \033[1;33mpkg install git\033[0;33m va restart installer"
	exit 7
}

printf "\r\033[K\033[0;32mRepo klonlangan!\e[0m"
printf "\n\r\033[0;34mPython bog‘liqliklarini o‘rnatilmoqda...\e[0m"

# shellcheck disable=SC2086
runin "$SUDO_CMD python$PYVER" -m pip install --upgrade pip setuptools wheel --user
# shellcheck disable=SC2086
runin "$SUDO_CMD python$PYVER" -m pip install -r requirements.txt --upgrade --user --no-warn-script-location --disable-pip-version-check || {
	errorin "Talablar bajarilmadi!"
	exit 4
}
rm -f ../premium-install.log
touch .setup_complete

printf "\r\033[K\033[0;32mBog‘liqliklar o‘rnatilgan!\e[0m"
printf "\n\033[0;32mBoshlanmoqda...\e[0m\n\n"

${SUDO_CMD}"python$PYVER" -m premium "$@" || {
	printf "\033[1;31mPython skriptlari muvaffaqiyatsiz tugadi\e[0m"
	exit 5
}
