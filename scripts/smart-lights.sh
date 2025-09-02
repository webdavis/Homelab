#!/usr/bin/env bash

# This script currently utilizes the following third-party tools:
#   - OpenHue (https://www.openhue.io/).
#   - jq (https://jqlang.org/)
#   - GNU getopt (https://formulae.brew.sh/formula/gnu-getopt)

# Exit immediately if any command fails.
set -euo pipefail

set_debug_log() {
  # Capture all messages to the debug log.

  script_debug_log='/tmp/smart_lights.log'

  # Save the original stdout to file descriptor 3.
  exec 3>&1

  # Redirect all output to the log file by default.
  exec >> "$script_debug_log" 2>&1

  # Log the script start time.
  echo "Script started at $(date '+%Y-%m-%d %H:%M:%S')"
}

log_message() {
  # Function to log and optionally print to stdout.
  local message="$1"
  local to_stdout="${2:-false}" # Default to not printing to stdout

  # Log the message to the debug log
  echo "$message"

  # If to_stdout is true, print to stdout using the original STDOUT descriptor.
  if [[ "$to_stdout" == "true" ]]; then
    # echo "$message" > /dev/tty
    echo "$message" >&3
  fi
}

function setup_signal_handling() {
    # Handle process interuption signals.
    trap cleanup SIGINT SIGTERM

    # Handle the EXIT signal for any script termination.
    trap cleanup EXIT
}

check_requirements() {
  # Ensure we're using GNU getopt.
  declare -g GETOPT_CMD
  GETOPT_CMD="$(which getopt)"

  local gnu_getopt_path='/opt/homebrew/opt/gnu-getopt/bin'

  if [[ "${GETOPT_CMD%/*}" != "$gnu_getopt_path" ]]; then
    if [[ -x "$gnu_getopt_path" ]]; then
      GETOPT_CMD="$gnu_getopt_path/getopt"
    else
      log_message "Error: GNU getopt not found. Please install it with 'brew install gnu-getopt'." true
      exit 1
    fi
  fi

  if ! command -v openhue &>/dev/null; then
    log_message "Error: 'openhue' command not found. Please install 'openhue' to continue (https://www.openhue.io/cli/installation)" true
    exit 1
  fi

  if ! command -v jq &>/dev/null; then
    log_message "Error: 'jq' command not found. Please install 'jq' to continue." true
    exit 1
  fi
}

get_room_status() {
  local id="$1"

  local json_path='.GroupedLight.HueData.on.on'

  local status
  status="$(openhue get room "$id" --json | jq "$json_path")"

  echo "$status"
}

set_room_power() {
  local room="$1"
  local id="$2"
  local state="$3"

  openhue set room "$id" "--${state}" >/dev/null
  log_message "$room: $state" true
}

toggle_power() {
  local room="$1"

  local id
  id="$(get_room_id "$room")"

  local status
  status="$(get_room_status "$id")"

  if [[ "$status" == 'false' ]]; then
    set_room_power "$room" "$id" "on"
  else
    set_room_power "$room" "$id" "off"
  fi
}

get_static_scene() {
  # 'static' is the term used by OpenHue to represent the current scene.
  # It essentially means "active."
  local room="$1"

  local name
  name="$(openhue get scene --room "$room" --json | jq -r '.[] | select(.HueData.status.active == "static") | .Name')" || {
    log_message "ERROR: Failed to get scene for room: '$room'" true
    return 1
  }

  echo "$name"
}

rotate_scene() {
  local scene_name="$1"
  local direction="$2"

  local scenes=('Nightlight' 'Rest' 'Dimmed' 'Relax' 'Read' 'Energize' 'Concentrate')

  local index
  for i in "${!scenes[@]}"; do
    if [[ "${scenes[i]}" == "$scene_name" ]]; then
      index=$i
      break
    fi
  done

  if [[ -z "$index" ]]; then
    # Fallback to "Read" if the scene is not recognized.
    echo 'Read'
    return
  fi

  local next_index
  if [[ "$direction" == 'next' ]]; then
    next_index=$(( (index + 1) % ${#scenes[@]} ))
  else
    next_index=$(( (index - 1) % ${#scenes[@]} ))
  fi

  echo "${scenes[next_index]}"
}

get_room_id() {
  local room="$1"

  local id
  id="$(openhue get room --json | jq -r --arg room "$room" 'limit(1; .. | select(.Name? == $room) | .Id)')"

  echo "$id"
}

get_scene_id() {
  local room_id="$1"
  local scene_name="$2"

  local scene_id
  scene_id="$(openhue get room "$room_id" --json | jq -r --arg scene "$scene_name" '.. | select(.metadata?.name == $scene) | .id')"

  echo "$scene_id"
}

get_brightness() {
  local room="$1"

  local json_path='.GroupedLight.HueData.dimming.brightness'

  local brightness
  brightness="$(openhue get room "$room" --json | jq "$json_path")"

  echo "${brightness%%.*}"
}

set_brightness() {
  local room="$1"
  local id="$2"
  local brightness="$3"

  openhue set room "$id" -b "$brightness"

  log_message "🔆 Room: $room | Current brightness: ${brightness}%" true
}

validate_room_id() {
  # Check if the room ID was found.

  local room="$1"
  local id="$2"

  if [[ -z "$id" ]]; then
    log_message "Error: Room ID for '$room' not found. Please ensure the room name is correct." true
    exit 1
  fi
}

manage_brightness() {
  local direction="$1"
  local room="$2"

  # Validate inputs
  if [[ -z "$direction" || -z "$room" ]]; then
    log_message "Error: Both direction and room must be provided." true
    return 1
  fi

  if [[ ! "$direction" =~ ^(up|down)$ ]]; then
    log_message "Error: Direction must be 'up' or 'down'." true
    return 1
  fi

  local id
  id="$(get_room_id "$room")"

  validate_room_id "$room" "$id"

  local current_brightness
  current_brightness="$(get_brightness "$room")"

  # Calculate new brightness.
  local adjustment=15
  local brightness="$current_brightness"
  if [[ "$direction" == 'up' ]]; then
    brightness=$(( brightness + adjustment ))
  else
    brightness=$(( brightness - adjustment ))
  fi

  if (( brightness < 0 )); then
    brightness=0
  elif (( brightness > 100 )); then
    brightness=100
  fi

  set_brightness "$room" "$id" "$brightness"
}

validate_scene_id() {
  # Check if the scene ID was found.

  local scene="$1"
  local id="$2"
  local room="$3"

  if [[ -z "$id" ]]; then
    log_message "Error: Unable to find the Scene ID for scene '$scene' in room '$room'." true
    exit 1
  fi
}

set_scene() {
  local room="$1"
  local id="$2"
  local scene="$3"

  openhue set scene "$id" >/dev/null
  log_message "Room: $room | Scene: $scene" true
}

handle_scene_logic() {
  local scene_name="$1"
  local room="$2"

  if [[ "$scene_name" =~ ^(next|previous)$ ]]; then
    local current_scene
    current_scene="$(get_static_scene "$room")"

    scene_name="$(rotate_scene "$current_scene" "$scene_name")"
  fi

  local room_id
  room_id="$(get_room_id "$room")"

  validate_room_id "$room" "$room_id"

  local scene_id
  scene_id="$(get_scene_id "$room_id" "$scene_name")"

  validate_scene_id "$scene_name" "$scene_id" "$room"

  set_scene "$room" "$scene_id" "$scene_name"
}

parse_command_line_arguments() {
  local short='pr:b:nls:'
  local long='power,room:,brightness:,next,last,scene:'

  # Default values
  local power='false'
  local brightness=''
  local scene=''
  local room='Master Bedroom'

  # Parse options
  OPTIONS="$($GETOPT_CMD -o "$short" --long "$long" -- "$@")"
  eval set -- "$OPTIONS"

  while true; do
    case "$1" in
      -p | --power)
        power='true'
        shift
        ;;
      -r | --room)
        room="$2"
        shift 2
        ;;
      -b | --brightness)
        brightness="$2"
        shift 2
        ;;
      -s | --scene)
        scene="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        log_message "Unknown option: $1" true
        exit 1
        ;;
    esac
  done

  if [[ "$power" == 'true' ]]; then
    toggle_power "$room"
  elif [[ -n "$brightness" ]]; then
    manage_brightness "$brightness" "$room"
  elif [[ -n "$scene" ]]; then
    handle_scene_logic "$scene" "$room"
  fi
}

function cleanup() {
  # Exit with the exit status of the last command before trap was triggered.
  local status=$?

  if [[ $status -gt 0 ]]; then
    printf "FAILED: Script encountered an error.\n\n" >&2
  else
    printf "SUCCESS: Script ended successfully.\n\n"
  fi

  exit $status
}

main() {
  set_debug_log
  setup_signal_handling
  check_requirements
  parse_command_line_arguments "$@"
}

if [[ $# -eq 0 ]]; then
  main "-p"
else
  main "$@"
fi
