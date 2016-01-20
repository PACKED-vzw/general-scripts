#!/bin/bash

function usage {
  printf 'This script can be used to compare the output of two Fixity
  <https://www.avpreserve.com/tools/fixity/> checks on the same set of files.
  It requires Fixity output files using tab separation as input and stores
  the results as a CSV file called "$input_1_result.csv".\n\n'
}

if [[ "$1" == "" || "$2" == "" ]]; then
  usage
  printf 'Please enter the first file to compare:\n'
  read left_file
  printf 'Please enter the second file to compare:\n'
  read right_file
else
  left_file="$1"
  right_file="$2"
fi

check_files=( "$left_file" "$right_file" )
files_to_join=()

for file_to_check in "${check_files[@]}"; do
  parsed_file_name=$(basename "$file_to_check")
  parsed_file="/tmp/$parsed_file_name""_parsed"
  if [[ -f "$parsed_file" ]]; then
    rm "$parsed_file"
  fi
  tmp_file_name=$(basename "$file_to_check")
  tail -n +7 "$file_to_check" > "/tmp/$tmp_file_name"
  while IFS=$'\t' read checksum filepath f_size; do
    if [[ ! -f "$parsed_file" ]]; then
      touch "$parsed_file"
    fi
    file_name=$(basename "$filepath")
    printf '%s\t%s\n' "$checksum" "$file_name" >> "$parsed_file"
  done < "/tmp/$tmp_file_name"
  sorted_file_name=$(basename "$file_to_check")
  sorted_file="/tmp/$sorted_file_name""_sorted"
  cat "$parsed_file" | sort -k 1 -t $'\t' -f > "$sorted_file"
files_to_join+=( "$sorted_file" )
done

join_file_name=$(basename "$left_file")
join_file="/tmp/$join_file""_join"
join -j 2 -t $'\t' "${files_to_join[@]}" > "$join_file"

result_file="$left_file""_result.csv"

if [[ -f "$result_file" ]]; then
  rm "$result_file"
fi
printf '"Filename";"Checksums match"\n' > "$result_file"

while IFS=$'\t' read file_name checksum1 checksum2; do
  if [[ "$checksum1" == "$checksum2" ]]; then
    printf '"%s";"1"\n' "$file_name" >> "$result_file"
  else
    printf '"%s";"0"\n' "$file_name" >> "$result_file"
  fi
done < "$join_file"

printf 'Results saved in %s\n' "$result_file"

exit 0
