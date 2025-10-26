#!/bin/bash

# Function to query brain atlas coordinates
# Usage: mniCoords <x,y,z> OR mniCoords <x> <y> <z>
# Examples:
#   mniCoords 28,-74,20
#   mniCoords 28, -74, 20
#   mniCoords 28 -74 20

mniCoords() {
    # Parse coordinates from arguments
    local x y z coords

    if [ $# -eq 0 ]; then
        echo "Error: Please provide coordinates"
        echo "Usage: mniCoords <x,y,z> OR mniCoords <x> <y> <z>"
        echo "Examples:"
        echo "  mniCoords 28,-74,20"
        echo "  mniCoords 28, -74, 20"
        echo "  mniCoords 28 -74 20"
        return 1
    elif [ $# -eq 1 ]; then
        # Single argument: parse comma-separated values
        coords="$1"

        # Validate that the argument contains commas (comma-separated format)
        if [[ ! "$coords" =~ , ]]; then
            echo "Error: Single argument must be comma-separated"
            echo "Usage: mniCoords <x,y,z> OR mniCoords <x> <y> <z>"
            echo "Examples:"
            echo "  mniCoords 28,-74,20"
            echo "  mniCoords \"28, -74, 20\""
            echo "For single values, use three-argument format: mniCoords 28 28 28"
            return 1
        fi

        # Remove spaces around commas
        coords=$(echo "$coords" | sed 's/ //g')
        # Extract x, y, z
        x=$(echo "$coords" | cut -d',' -f1)
        y=$(echo "$coords" | cut -d',' -f2)
        z=$(echo "$coords" | cut -d',' -f3)
    elif [ $# -eq 3 ]; then
        # Three arguments: x y z
        # Strip commas and spaces from each argument (handles "40, -77, 5" as three args)
        x=$(echo "$1" | sed 's/[, ]//g')
        y=$(echo "$2" | sed 's/[, ]//g')
        z=$(echo "$3" | sed 's/[, ]//g')
        coords="$x,$y,$z"
    else
        echo "Error: Invalid number of arguments"
        echo "Usage: mniCoords <x,y,z> OR mniCoords <x> <y> <z>"
        return 1
    fi

    # Validate that we have three coordinates
    if [ -z "$x" ] || [ -z "$y" ] || [ -z "$z" ]; then
        echo "Error: Could not parse three coordinates"
        echo "Please provide coordinates in format: x,y,z or x y z"
        return 1
    fi

    # Validate that coordinates are numeric (integer or decimal, positive or negative)
    # Regex: optional minus, digits, optional decimal point and more digits
    local num_regex='^-?[0-9]+\.?[0-9]*$'

    if ! [[ "$x" =~ $num_regex ]]; then
        echo "Error: X coordinate '$x' is not a valid number"
        echo "Coordinates must be numeric (e.g., 28, -74, 20.5)"
        return 1
    fi

    if ! [[ "$y" =~ $num_regex ]]; then
        echo "Error: Y coordinate '$y' is not a valid number"
        echo "Coordinates must be numeric (e.g., 28, -74, 20.5)"
        return 1
    fi

    if ! [[ "$z" =~ $num_regex ]]; then
        echo "Error: Z coordinate '$z' is not a valid number"
        echo "Coordinates must be numeric (e.g., 28, -74, 20.5)"
        return 1
    fi

    # URL encode the coordinates (commas -> %2C, spaces -> %20)
    local encoded_coords="${x}%2C%20${y}%2C%20${z}"

    # Array of templates to query
    local templates=("NMM1103" "HOA06")

    echo "Querying coordinates: $coords"
    echo ""

    # Query each template
    for template in "${templates[@]}"; do
        local api_url="https://scalablebrainatlas.incf.org/services/coord2region.php?template=${template}&coord=${encoded_coords}&output=json"

        echo "=== Template: $template ==="

        # Make the API call with error handling
        local response
        local http_code

        # Use curl with --fail to detect HTTP errors
        # Using --insecure to bypass SSL certificate verification issues with the INCF server
        response=$(curl -s -w "\n%{http_code}" --connect-timeout 10 --max-time 30 --insecure "$api_url" 2>&1)
        local curl_exit=$?

        # Extract HTTP code from last line
        http_code=$(echo "$response" | tail -n1)
        response=$(echo "$response" | sed '$d')

        # Check for errors
        if [ $curl_exit -ne 0 ]; then
            echo "Error: Network request failed (curl exit code: $curl_exit)"
            echo ""
            continue
        fi

        if [ "$http_code" -ge 400 ]; then
            echo "Error: HTTP $http_code - Request failed"
            echo ""
            continue
        fi

        # Check if response is empty
        if [ -z "$response" ]; then
            echo "Error: Empty response from server"
            echo ""
            continue
        fi

        # Format and display JSON output
        if command -v jq &> /dev/null; then
            echo "$response" | jq . 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Error: Invalid JSON response"
                echo "Raw response: $response"
            fi
        else
            echo "$response"
            echo ""
            echo "(Install 'jq' for pretty-printed JSON output)"
        fi

        echo ""
    done
}

# If script is executed directly (not sourced), run the function
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    mniCoords "$@"
fi
