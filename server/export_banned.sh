#!/usr/bin/env bash

server_name="My server name"
# Define the output directory and target user
target_user="USER"
base_dir="/home/${target_user}/utils/fail2ban_data"
fail2ban_client="/usr/bin/fail2ban-client" # Full path to fail2ban_client

show_banned_ips() {
    # @description Routine to display banned IP list per jail.
    # @description It shows the jail name and the list of banned IPs for each jail.
    $fail2ban_client status | grep "Jail list" | cut -d: -f2 | tr -d ' \t' | tr ',' '\n' | while read jail; do
        echo "== Jail: $jail =="
        $fail2ban_client status "$jail" | grep "Banned IP list"
        echo ""
    done
}

count_banned_ips() {
    # @description Routine to count banned IPs per jail and optionally display counts per jail.
    # @description It calculates the total number of banned IPs per jail and optionally exports the data to a JSON file.
    # @param show_counts: If "true", show per-jail counts; otherwise, just calculate the total
    # @param export_file: Optional path to export JSON data
    local show_counts="$1"
    local export_file="$2"
    total=0
    declare -A jail_counts # Array to store counts per jail

    while read jail; do
        # Get the banned IPs for each jail and count the number of IPs
                count=$($fail2ban_client status "$jail" | grep -oP "(?<=Banned IP list:\s).*" | wc -w)

        # Store the count in the array
        jail_counts["$jail"]=$count

        # If show_counts is true, print count per jail
        if [[ "$show_counts" == "true" ]]; then
            echo "$jail: $count"
        fi

        total=$((total + count))
        done < <($fail2ban_client status | grep "Jail list" | cut -d: -f2 | tr -d ' \t' | tr ',' '\n')

    echo "Total banned IPs: $total"

    # Export to JSON if export_file is provided
    if [[ -n "$export_file" ]]; then
        # Ensure the base directory exists and is writable by the target user
        mkdir -p "$base_dir"
        chown "${target_user}:${target_user}" "$base_dir"
        chmod 755 "$base_dir"

        # Create monthly directory and ensure it is readable/executable by others
        current_month=$(date +"%Y-%m")
        data_dir="${base_dir}/${current_month}"
        mkdir -p "$data_dir"
        chown "${target_user}:${target_user}" "$data_dir"
        chmod 755 "$data_dir"

        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        unique_id=$(date +"%Y%m%d_%H%M%S") # Unique ID based on timestamp

        # Build the JSON data
        json_data="{
            \"id\": \"$unique_id\",
            \"timestamp\": \"$timestamp\",
            \"server\": \"$server_name\",
            \"total_banned_ips\": $total,
            \"jails\": {"

        # Add jail counts to JSON
        for jail in "${!jail_counts[@]}"; do
            json_data+="\"$jail\": ${jail_counts[$jail]},"
        done
        json_data="${json_data%,}" # Remove trailing comma
        json_data+="}}"

        # Write JSON to file with permissions
        export_path="${data_dir}/${export_file}"
        echo "$json_data" > "${export_path}"
        echo "Data exported to ${export_path}"

        chown "${target_user}:${target_user}" "export_path"
        chmod 644 "export_path"
    fi
}

show_total() {
    # @description Routine to show only the total number of banned IPs
    count_banned_ips "false"
}

# Main script logic
if [[ "$1" == "show" ]]; then
    show_banned_ips
elif [[ "$1" == "count" ]]; then
    count_banned_ips "true"
elif [[ "$1" == "total" ]]; then
    show_total
elif [[ "$1" == "export" ]]; then
    timestamp=$(date +"%Y%m%d_%H%M%S")
    export_file="fail2ban_stats_${timestamp}.json"
    count_banned_ips "false" "$export_file"
else
    echo "Usage: $0 {show|count|total|export}"
    echo "  show   - Display banned IP list per jail"
    echo "  count  - Count banned IPs per jail and display the total"
    echo "  total  - Display only the total number of banned IPs"
    echo "  export - Export banned IP statistics to a JSON file"
    return 1  # Gracefully exit the script
fi