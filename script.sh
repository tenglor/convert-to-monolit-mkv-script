#!/bin/bash

# set -x

target_dir="${1:-.}"

find_by_glob(){
	local pattern="$1"
	shift
	local results=()

	for element in "$@"; do
        if [[ $element == *"$pattern"* ]]; then	
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

declare -a result_files
find_all_files(){
	local dir="$1"

	local pattern="$2"
	local -n array_ref="$3"	

	while IFS= read -r -d $'\0' file; do
    	array_ref+=("$file")
	done < <(find "${dir}" -type f -name "$pattern" -print0)		
}

fonts=()
audios=()
subtitles=()

find_all_files "${target_dir}" "*.ttf" fonts
find_all_files "${target_dir}" "*.otf" fonts
find_all_files "${target_dir}" "*.ttc" fonts

find_all_files "${target_dir}" "*.mka" audios

#subtitles=($(find "${target_dir}" -type f -name "*.ass"))
#subtitles+=($(find "${target_dir}" -type f -name "*.srt"))

find_all_files "${target_dir}" "*.ass" subtitles
find_all_files "${target_dir}" "*.srt" subtitles


font_args=()
for font in "${fonts[@]}"; do
    if [ -f "$font" ]; then
        echo "Добавляю: $(basename "$font")"
        font_args+=(--attach-file "$font")
    fi
done

mkdir -p "${target_dir}/converted"

for input in "${target_dir}"/*.mkv; do
	echo "Video $input"	
	input_base="$(basename "$input" .mkv)"
	if [ -e "${target_dir}/converted/${input_base}.mkv" ]; then
		echo "Output video ${target_dir}/converted/${input_base}.mkv exist. Passed"	
		continue
	fi		
	echo "$input_base"
	input_sub=()
	input_audio=()
	for sub in "${subtitles[@]}"; do
        sub_basename=$(basename "$sub")
        if [[ "$sub_basename" == *"$input_base"* ]]; then
            input_sub+=("$sub")
            echo "Найдены субтитры: $(basename "$sub")"
        fi
    done
	for audio in "${audios[@]}"; do
        audio_basename=$(basename "$audio")
        if [[ "$audio_basename" == *"$input_base"* ]]; then
            input_audio+=("$audio")
            echo "Найдено аудио: $(basename "$audio")"
        fi
    done
	output_mkv="${target_dir}/converted/${input_base}.mkv"
	output_mkv_tmp="${target_dir}/tmp.mkv"
	echo "input_mkv: $input"	
	echo "sub 0: ${input_sub[0]}"	
	echo "sub 1: ${input_sub[1]}"		
	echo "output_mkv: $output_mkv"
	if [[ ${#fonts[@]} -eq 0 ]]; then
		ffmpeg -v quiet  -stats -i "$input" -i "${input_sub[0]}" -i "${input_sub[1]}"  -y \
			-c:v hevc_nvenc -rc vbr -cq 22 -profile:v main -pix_fmt yuv420p  -preset slow -c:s copy \
			-c:a aac -b:a 192k -ac 2  \
			-map 0:v:0 -map 0:a  -map 2:s:0 -map 1:s:0 -ignore_unknown \
			"$output_mkv"
	else
		ffmpeg -i "$input" \
			-i "${input_sub[0]}" -i "${input_sub[1]}" -i "${input_sub[2]}"  -i "${input_sub[3]}" \
			-i "${input_audio[0]}" -i "${input_audio[1]}" -i "${input_audio[2]}"  -i "${input_audio[3]}" \
			-y \
			-c:v hevc_nvenc -rc vbr -cq 22 -profile:v main -pix_fmt yuv420p  -preset slow -c:s copy \
			-c:a aac -b:a 192k -ac 2  \
			-map 0:v:0 -map 0:a \
			-map 1:s:0 -map 2:s:0 -map 3:s:0 -map 4:s:0 \
			-map 5:a:0 -map 6:a:0 -map 7:a:0 -map 8:a:0 \
			-ignore_unknown \
			"$output_mkv_tmp"
		mkvmerge -o "$output_mkv" \
    		"$output_mkv_tmp" \
    		"${font_args[@]}"
    	rm "$output_mkv_tmp"    
	fi
done
