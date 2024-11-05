#!/bin/bash


function log() {
    if [[ "$json_output" == true ]]; then
        return
    fi
    echo "$1"
}

# Define client headers
declare -A client_headers
client_headers=(
    ["User-Agent"]="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:53.0) Gecko/20100101 Firefox/53.0"
    ["Accept"]="text/html,application/xhtml+xml, application/xml;q=0.9,*/*;q=0.8"
    ["Accept-Language"]="en-US;q=0.8,en;q=0.3"
    ["Upgrade-Insecure-Requests"]="1"
)

# Security headers that should be enabled
declare -A sec_headers
sec_headers=(
    ["X-XSS-Protection"]="deprecated"
    ["X-Frame-Options"]="warning"
    ["X-Content-Type-Options"]="warning"
    ["Strict-Transport-Security"]="error"
    ["Content-Security-Policy"]="warning"
    ["X-Permitted-Cross-Domain-Policies"]="deprecated"
    ["Referrer-Policy"]="warning"
    ["Expect-CT"]="deprecated"
    ["Permissions-Policy"]="warning"
    ["Cross-Origin-Embedder-Policy"]="warning"
    ["Cross-Origin-Resource-Policy"]="warning"
    ["Cross-Origin-Opener-Policy"]="warning"
)

information_headers=("X-Powered-By" "Server" "X-AspNet-Version" "X-AspNetMvc-Version")
cache_headers=("Cache-Control" "Pragma" "Last-Modified" "Expires" "ETag")

declare -A headers

function banner() {
  echo -e "======================================================"
  echo -e "> SecHead - Rhovelz .............................."
  echo -e "A Magic Wand to check Security Headers "
  echo -e "======================================================"
}



function colorize() {
    local string="$1"
    local alert="$2"
    local color
    case "$alert" in
        "error") color="\e[91m" ;;      # Red
        "warning") color="\e[93m" ;;    # Yellow
        "ok") color="\e[92m" ;;         # Green
        "info") color="\e[94m" ;;       # Blue
        "deprecated") color="" ;;       # No color for deprecated
        *) color="" ;;
    esac
    echo -e "${color}${string}\e[0m"
}

function parse_headers() {
    while IFS= read -r line; do
        key="${line%%:*}"
        value="${line#*: }"
        headers["${key,,}"]="$value"
    done <<< "$1"
}

function append_port() {
    local target="$1"
    local port="$2"
    if [[ "${target: -1}" == "/" ]]; then
        echo "${target%/*}:$port/"
    else
        echo "$target:$port/"
    fi
}

function check_target() {
    local target="$1"
    local method="HEAD"
    [[ "$useget" == true ]] && method="GET"

    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "User-Agent: ${client_headers[User-Agent]}" \
        -H "Accept: ${client_headers[Accept]}" \
        -H "Accept-Language: ${client_headers[Accept-Language]}" \
        -H "Upgrade-Insecure-Requests: ${client_headers[Upgrade-Insecure-Requests]}" \
        --proxy "$proxy" "$target" --request "$method")

    if [[ "$response" -ge 200 && "$response" -lt 400 ]]; then
        echo "Success"
    else
        echo "Failure: $response"
        return 1
    fi
}

function report() {
    log "-------------------------------------------------------"
    log "[!] Headers analyzed for $(colorize "$1" 'info')"
    log "[+] There are $(colorize "$2" 'ok') security headers"
    log "[-] There are not $(colorize "$3" 'error') security headers"
    log ""
}

function main() {
    parse_options "$@"

    if [[ "$json_output" == true ]]; then
        exec > /dev/null
    fi

    banner


    if [[ -n "$cookie" ]]; then
        client_headers["Cookie"]=$cookie
    fi

    for header in "${custom_headers[@]}"; do
        IFS=': ' read -r key value <<< "$header"
        client_headers["$key"]="$value"
    done

    if [[ -n "$hfile" ]]; then
        mapfile -t targets < "$hfile"
    fi

    for target in "${targets[@]}"; do
        if [[ -n "$port" ]]; then
            target=$(append_port "$target" "$port")
        fi

        log "[*] Analyzing headers of $(colorize "$target" 'info')"

        response=$(check_target "$target")
        [[ $? -ne 0 ]] && continue

        log "[*] Effective URL: $(colorize "$target" 'info')"
        parse_headers "$response"

        safe=0
        unsafe=0

        for safeh in "${!sec_headers[@]}"; do
            lsafeh="${safeh,,}"
            if [[ -n "${headers[$lsafeh]}" ]]; then
                safe=$((safe + 1))
                log "[*] Header $safeh is present! (Value: ${headers[$lsafeh]})"
            else
                unsafe=$((unsafe + 1))
                log "[!] Missing security header: $(colorize "$safeh" "${sec_headers[$safeh]}")"
            fi
        done

        report "$target" "$safe" "$unsafe"
    done

    if [[ "$json_output" == true ]]; then
        exec >&-
    fi
}

function parse_options() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -p|--port) port="$2"; shift ;;
            -c|--cookie) cookie="$2"; shift ;;
            -a|--add-header) custom_headers+=("$2"); shift ;;
            -d|--disable-ssl-check) ssldisabled=true ;;
            -g|--use-get-method) useget=true ;;
            -m|--use-method) usemethod="$2"; shift ;;
            -j|--json-output) json_output=true ;;
            -i|--information) information=true ;;
            -x|--caching) cache_control=true ;;
            -k|--deprecated) show_deprecated=true ;;
            --proxy) proxy="$2"; shift ;;
            --hfile) hfile="$2"; shift ;;
            -*) echo "Invalid option: $key" ;;
            *) targets+=("$key") ;;
        esac
        shift
    done

    if [[ ${#targets[@]} -eq 0 && -z "$hfile" ]]; then
        echo "Usage: $0 [options] <target>"
        exit 12
    fi
}

main "$@"
