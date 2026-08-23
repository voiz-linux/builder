#!/bin/bash

# PixelDrain Upload Utility for CI/CD Pipelines
# Usage: ./pixeldrain-upload.sh <file_or_directory> [output_format]
# Formats: json, markdown, plain (default: json)

set -euo pipefail

# Configuration
PIXELDRAIN_API="https://pixeldrain.com/api/file/"
PIXELDRAIN_PUBLICITY="https://pixeldrain.com/api/file/{id}/publicity"
OUTPUT_FORMAT="${2:-json}"
RESULTS=()

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validate PixelDrain token
if [[ -z "${PIXELDRAIN:-}" ]]; then
    echo -e "${RED}Error: PIXELDRAIN environment variable not set${NC}" >&2
    exit 1
fi

# Validate input
if [[ $# -lt 1 ]]; then
    echo -e "${RED}Usage: $0 <file_or_directory> [output_format]${NC}" >&2
    echo "Formats: json, markdown, plain" >&2
    exit 1
fi

TARGET="${1}"

pixeldrain_upload() {
    local FILE="${1}"

    if [ -f "$FILE" ]; then
        echo -e "${BLUE}Uploading: $FILE${NC}" >&2
        
        RESPONSE=$(curl -s -u ":$PIXELDRAIN" -T "$FILE" "$PIXELDRAIN_API")
        FILE_ID=$(echo "$RESPONSE" | jq -r '.id // empty' 2>/dev/null)

        if [[ -n "$FILE_ID" && "$FILE_ID" != "null" ]]; then
            # Mark file public
            curl -s -u ":$PIXELDRAIN" -X POST "${PIXELDRAIN_PUBLICITY//{id}/$FILE_ID}" \
                 -H "Content-Type: application/json" \
                 -d '{"public": true}' > /dev/null 2>&1 || true

            PD_URL="https://pixeldrain.com/u/$FILE_ID"
            FILE_SIZE=$(stat -f%z "$FILE" 2>/dev/null || stat -c%s "$FILE" 2>/dev/null || echo "unknown")
            
            # Store result with metadata
            RESULTS+=("$FILE|$FILE_ID|$PD_URL|$FILE_SIZE")
            echo -e "${GREEN}✓ Uploaded: $(basename "$FILE")${NC}" >&2
            
            return 0
        else
            echo -e "${RED}✗ PixelDrain API Error: $RESPONSE${NC}" >&2
            return 1
        fi
    else
        echo -e "${RED}Error: File not found: $FILE${NC}" >&2
        return 1
    fi
}

format_output() {
    local format="${1}"
    
    case "$format" in
        json)
            echo "{"
            echo '  "uploads": ['
            for i in "${!RESULTS[@]}"; do
                IFS='|' read -r file id url size <<< "${RESULTS[$i]}"
                echo "    {"
                echo "      \"filename\": \"$(basename "$file")\","
                echo "      \"file_id\": \"$id\","
                echo "      \"url\": \"$url\","
                echo "      \"size\": \"$size\""
                [[ $i -lt $((${#RESULTS[@]} - 1)) ]] && echo "    }," || echo "    }"
            done
            echo '  ],'
            echo '  "count": '${#RESULTS[@]}
            echo "}"
            ;;
        markdown)
            echo "# PixelDrain Upload Results"
            echo ""
            echo "| Filename | Link | File ID | Size |"
            echo "|----------|------|---------|------|"
            for result in "${RESULTS[@]}"; do
                IFS='|' read -r file id url size <<< "$result"
                echo "| $(basename "$file") | [$id]($url) | $id | $size |"
            done
            echo ""
            echo "**Total files uploaded:** ${#RESULTS[@]}"
            ;;
        plain)
            for result in "${RESULTS[@]}"; do
                IFS='|' read -r file id url size <<< "$result"
                echo "$url"
            done
            ;;
    esac
}

# Main execution
if [ -d "$TARGET" ]; then
    # Upload all files in directory
    echo -e "${BLUE}Uploading directory: $TARGET${NC}" >&2
    while IFS= read -r -d '' file; do
        pixeldrain_upload "$file" || true
    done < <(find "$TARGET" -type f -print0)
elif [ -f "$TARGET" ]; then
    # Upload single file
    pixeldrain_upload "$TARGET"
else
    echo -e "${RED}Error: Target not found: $TARGET${NC}" >&2
    exit 1
fi

# Output results
if [[ ${#RESULTS[@]} -gt 0 ]]; then
    format_output "$OUTPUT_FORMAT"
    exit 0
else
    echo -e "${RED}No files uploaded successfully${NC}" >&2
    exit 1
fi
