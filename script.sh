#!/bin/bash

# set -x

target_dir="${1:-.}"

find_by_regex(){
	local regex="$1"
	shift
	local results=()

	for element in "$@"; do
        if [[ $element =~ $regex ]]; then
            results+=("$element")
        fi
    done

    echo "${results[@]}"
}

delete_by_value() {
    local value="$1"
    shift
    local array=("$@")
    local result=()
    
    for element in "${array[@]}"; do
        if [[ "$element" != "$value" ]]; then
            result+=("$element")
        fi
    done
    
    echo "${result[@]}"
}

fonts=()
fonts+=($(find . -type f -name "*.ttf"))
fonts+=($(find . -type f -name "*.otf"))
fonts+=($(find . -type f -name "*.ttc"))

audios=($(find . -type f -name "*.mka"))

subtitles=($(find . -type f -name "*.ass"))
subtitles+=($(find . -type f -name "*.srt"))


font_args=()
for font in "${fonts[@]}"; do
    if [ -f "$font" ]; then
        echo "Добавляю: $(basename "$font")"
        font_args+=(--attach-file "$font")
    fi
done

for input in ${target_dir}/*.{mkv,mp4,avi}; do
	echo "Video $input"
	input_sub=$(find_by_regex $(basename $input) $subtitles[@])
	input_audio=$(find_by_regex $(basename $input) $audios[@])	
	output_mkv="${target_dir}/${input}-out.mkv"
	output_mkv_tmp="${target_dir}/tmp.mkv"
	echo "input_mkv: $input_mkv"	
	echo "output_mkv: $output_mkv"
	if [[ ${#fonts[@]} -eq 0 ]]; then
		ffmpeg -i "$input" -i "${input_sub[0]}" -i "${input_sub[1]}" -i "${input_audio[0]}" -i "${input_audio[1]}" -y \
			-loglevel quiet \
			-c:v hevc_nvenc -rc vbr -cq 22 -profile:v main -pix_fmt yuv420p  -preset slow -c:s copy \
			-c:a aac -b:a 192k -ac 2  \
			-map 0:v:0 -map 0:a -map 3:a:0 -map 4:a:0 -map 2:s:0 -map 1:s:0 -ignore_unknown \
			"$output_mkv"
	elif
		ffmpeg -i "$input_mkv" -i "$input_sub1" -i "$input_sub2" -i "$input_audio1" -i "$input_audio2" -y \
			-loglevel quiet \
			-c:v hevc_nvenc -rc vbr -cq 22 -profile:v main -pix_fmt yuv420p  -preset slow -c:s copy \
			-c:a aac -b:a 192k -ac 2  \
			-map 0:v:0 -map 0:a -map 3:a:0 -map 4:a:0 -map 2:s:0 -map 1:s:0 -ignore_unknown \
			"$output_mkv_tmp"
		mkvmerge -o "$output_mkv" \
    		"$output_mkv_tmp" \
    		"${font_args[@]}"
    	rm "$output_mkv_tmp"    
	fi
done
