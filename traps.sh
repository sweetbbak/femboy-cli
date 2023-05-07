#!/bin/sh
# shellcheck disable=SC2086

url="https://api.waifu.pics"
images_dir="$HOME/Pictures/waifu"
test -d "$images_dir" || mkdir -p "$images_dir"
image_protocol="kitty +kitten icat"
# alternatively you can use sixel, which is a superior protocol (not supported by kitty, but most terminals do support it)
# you need the libsixel package installed for it to work
# image_protocol="img2sixel -w 800"

endpoints="$(curl -s 'https://api.waifu.pics/endpoints')"
sfw_categories=$(printf "%s" "$endpoints" | tr -d \" | sed -nE "s@\{sfw:\[([^]*]*)\].*@sfw\/\1@p" | sed "s/,/\nsfw\//g")
nsfw_categories=$(printf "%s" "$endpoints" | tr -d \" | sed -nE "s@.*nsfw:\[([^]*]*)\].*@nsfw/\1@p" | sed "s/,/\nnsfw\//g")
both="${sfw_categories}
${nsfw_categories}"

print_help() {
    printf "%s\n" "USAGE:"
    printf "\t%s\n" "${0##*/} [OPTIONS]"
    printf "%s\n" "OPTIONS:"
    printf "\t%s\n" "-n,--nsfw"
    printf "\t%s\n" "-s,--sfw"
    printf "\t%s\n" "-t,--tag"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--nsfw) choice="$(gum choose $nsfw_categories)" ;;
        -s|--sfw) choice="$(gum choose $sfw_categories)" ;;
        -h|--help) print_help && exit 0 ;;
        -t|--tag) shift && choice="$1" ;;
        *) choice="$(gum choose $both)" ;;
    esac
    shift
done

[ -z "$1" ] && choice="$(gum choose $both)"
[ -z "$choice" ] && exit 1

main() {
    choice="${url}/${choice}"
    pic=$(curl -s "$choice" | sed -nE "s@.*\"url\":\"([^\"]*)\".*@\1@p")
    title=$(printf "%s" "$pic" | sed -nE "s@.*/([^\.]*\.(jpg|jpeg|png|webp|gif))@\1@p")
    out="${images_dir}/${title}"
    [ -z "$out" ] && printf "Couldn't get the image, exiting now." && exit 1
    curl -s "$pic" --output "$out"
    $image_protocol "$out"
}

main
