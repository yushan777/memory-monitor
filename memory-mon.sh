#!/bin/bash

max_vram=0
max_ram=0

# Print header
printf "%-18s %-18s %-12s %-12s\n" "VRAM (MiB)" "RAM (MiB)" "Peak VRAM" "Peak RAM"
printf "%-18s %-18s %-12s %-12s\n" "------------------" "------------------" "----------" "---------"
printf "%-18s %-18s %-12s %-12s\n" "" "" "" ""
printf "(Press 'r' to reset max, Ctrl+C to quit)\n"

while true; do
    # Non-blocking keypress check (1s timeout)
    read -t 1 -n 1 key
    if [[ $key == "r" || $key == "R" ]]; then
        max_vram=0
        max_ram=0
        # Move cursor to data row and show reset message
        printf "\033[2A\r%-50s\n" "Max values reset!"
        sleep 1
        printf "\033[1A\r%-50s\r" ""
    fi
    
    # Query current VRAM usage and total
    current_vram=0
    total_vram=0
    new_vram_peak=false
    
    while IFS= read -r line; do
        used=$(echo "$line" | cut -d',' -f1)
        total=$(echo "$line" | cut -d',' -f2)
        if (( used > current_vram )); then
            current_vram=$used
            total_vram=$total
        fi
        if (( used > max_vram )); then
            max_vram=$used
            new_vram_peak=true
        fi
    done < <(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null)
    
    # Query current RAM usage and total (in MB)
    ram_info=$(free -m | awk 'NR==2{printf "%d,%d", $3, $2}')
    current_ram=$(echo "$ram_info" | cut -d',' -f1)
    total_ram=$(echo "$ram_info" | cut -d',' -f2)
    new_ram_peak=false
    if (( current_ram > max_ram )); then
        max_ram=$current_ram
        new_ram_peak=true
    fi
    
    # Display table row (overwrite data line, move up 2 lines from bottom)
    printf "\033[2A\r%-18s %-18s %-12d %-12d\033[2B\r" "${current_vram}/${total_vram}" "${current_ram}/${total_ram}" "$max_vram" "$max_ram"
    
    # Add indicators for new peaks
    if [[ $new_vram_peak == true || $new_ram_peak == true ]]; then
        printf "\033[2A\r%-18s %-18s %-12d %-12d <- NEW PEAK!\033[2B\r" "${current_vram}/${total_vram}" "${current_ram}/${total_ram}" "$max_vram" "$max_ram"
        sleep 1
        printf "\033[2A\r%-18s %-18s %-12d %-12d               \033[2B\r" "${current_vram}/${total_vram}" "${current_ram}/${total_ram}" "$max_vram" "$max_ram"
    fi
done

echo ""
echo "(Press 'r' to reset max, Ctrl+C to quit)"
