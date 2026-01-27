#!/bin/bash

ARGS=()
# Добавляем все поддерживаемые форматы
for font in "ENG Subs/fonts [Asenshi]"/*.{ttf,otf,ttc}; do
    if [ -f "$font" ]; then
        echo "Добавляю: $(basename "$font")"
        ARGS+=(--attach-file "$font")
    fi
done


for ((i=1; i<=12; i++)); do
	echo "Video  index: $i"
	input_mkv=$(printf "[Beatrice-Raws] Yuru Camp %02d [BDRip 1920x1080 x264 FLAC].mkv" $i)	
	input_sub1=$(printf "RUS Subs/[Beatrice-Raws] Yuru Camp %02d [BDRip 1920x1080 x264 FLAC].RUS.[CR].ass" $i)	
	input_sub2=$(printf "RUS Subs/надписи/[Beatrice-Raws] Yuru Camp %02d [BDRip 1920x1080 x264 FLAC].надписи.ass" $i)	
	input_audio1=$(printf "RUS Sound/AniDub/[Beatrice-Raws] Yuru Camp %02d [BDRip 1920x1080 x264 FLAC].RUS.[AniDUB].mka" $i)	
	input_audio2=$(printf "RUS Sound/Crunchyroll/[Beatrice-Raws] Yuru Camp %02d [BDRip 1920x1080 x264 FLAC].RUS.[Crunchyroll].mka" $i)	
	output_mkv=$(printf "Yuru Camp %02d.mkv" $i)
	output_mkv_tmp="tmp.mkv"
	echo "input_mkv: $input_mkv"	
	echo "output_mkv: $output_mkv"
	ffmpeg -i "$input_mkv" -i "$input_sub1" -i "$input_sub2" -i "$input_audio1" -i "$input_audio2" -y \
		-c:v hevc_nvenc -rc vbr -cq 22 -profile:v main -pix_fmt yuv420p  -preset slow -c:s copy \
		-c:a aac -b:a 192k -ac 2  \
		-map 0:v:0 -map 0:a -map 3:a:0 -map 4:a:0 -map 2:s:0 -map 1:s:0 -ignore_unknown \
		"$output_mkv_tmp"
	mkvmerge -o "$output_mkv" \
    	"$output_mkv_tmp" \
    	"${ARGS[@]}"
	#rm "$output_mkv_tmp"
done
