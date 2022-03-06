wallpaper="$HOME/wp/wallpapers/wallhaven-l3vyjr.jpg"
picom="$HOME/.dwm/picom.conf"


bash $HOME/.dwm/dwm-status-refresh.sh &

feh --bg-fill $wallpaper &

picom -b --config $picom &

sleep 5
fcitx5 &
