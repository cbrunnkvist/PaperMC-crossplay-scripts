#!/bin/bash
set -e -u -o pipefail

# Check if instance directory was provided
if [ $# -ne 1 ]; then
  echo "Error: Instance directory is required as an argument" >&2
  echo "Usage: $0 <instance_directory>" >&2
  echo "Example: $0 ~/.lodestone/instances/MyServer" >&2
  exit 1
fi

CURL="curl --show-error --progress-bar --fail --location"
INSTANCE_DIR="$1"

# Ensure the instance directory exists
if [ ! -d "$INSTANCE_DIR" ]; then
  echo "Error: Instance directory '${INSTANCE_DIR}' does not exist." >&2
  exit 1
fi

# Create plugins directory if it doesn't exist
mkdir -p "${INSTANCE_DIR}/plugins"

download_papermc() {
  echo "Downloading PaperMC..."

  PROJECT="paper"
  PAPERMC_VERSION="1.21.4"

  # Get the latest build for the specified Minecraft version
  echo "  Fetching latest PaperMC build for version ${PAPERMC_VERSION}..."
  builds_response=$(${CURL} -s "https://api.papermc.io/v2/projects/${PROJECT}/versions/${PAPERMC_VERSION}/builds" 2>&1)
  if [ $? -ne 0 ]; then
    echo "  Error: Failed to fetch PaperMC builds for version ${PAPERMC_VERSION}." >&2
    echo "  Command failed: curl https://api.papermc.io/v2/projects/${PROJECT}/versions/${PAPERMC_VERSION}/builds" >&2
    echo "  Error output: ${builds_response}" >&2
    exit 1
  fi

  latest_build=$(echo "${builds_response}" | jq -r '.builds | map(select(.channel == "default") | .build) | .[-1]')
  if [ -z "${latest_build}" ]; then
    echo "  Error: Could not determine the latest PaperMC build for version ${PAPERMC_VERSION}." >&2
    exit 1
  fi

  # Construct download URL
  jar_name="${PROJECT}-${PAPERMC_VERSION}-${latest_build}.jar"
  download_url="https://api.papermc.io/v2/projects/${PROJECT}/versions/${PAPERMC_VERSION}/builds/${latest_build}/downloads/${jar_name}"

  # Download PaperMC
  echo "Downloading PaperMC server from ${download_url}..."
  if [[ ! -f "${INSTANCE_DIR}/${jar_name}" ]]; then
    ${CURL} -o "${INSTANCE_DIR}/${jar_name}" "${download_url}" 2>&1
    if [ $? -ne 0 ]; then
      echo "  Error: Failed to download PaperMC." >&2
      echo "  Command failed: curl ${download_url}" >&2
      exit 1
    fi
  else
    echo "  (skipped, file already exists)"
  fi
  ln -svf ${jar_name} "${INSTANCE_DIR}/server.jar"
  echo "PaperMC server '${jar_name}' downloaded successfully."
  echo
}

download_bluemap() {
  PROJECT="BlueMap"
  echo "Downloading BlueMap..."
  GITHUB_REPO="BlueMap-Minecraft/BlueMap"

  echo "  Fetching latest BlueMap plugin release..."
  releases_response=$(${CURL} -s "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" 2>&1)
  if [ $? -ne 0 ]; then
    echo "  Error: Failed to fetch BlueMap releases." >&2
    echo "  Command failed: curl https://api.github.com/repos/${GITHUB_REPO}/releases/latest" >&2
    echo "  Error output: ${releases_response}" >&2
    exit 1
  fi

  # Extract the tag for the latest version
  tag_name=$(echo "${releases_response}" | jq -r '.tag_name')
  # Extract the download URL for the PaperMC-compatible version
  download_url=$(echo "${releases_response}" | jq -r '.assets | .[] | select(.name | startswith("bluemap-") and endswith("paper.jar")) | .browser_download_url')
  if [ -z "${download_url}" ]; then
    echo "  Error: Could not find a download URL for the PaperMC-compatible BlueMap release ${tag_name}." >&2
    exit 1
  fi

  jar_name=$(basename "${download_url}")
  echo "Downloading BlueMap from ${download_url}..."
  if [[ ! -f "${INSTANCE_DIR}/plugins/${jar_name}" ]]; then
    ${CURL} -o "${INSTANCE_DIR}/plugins/${jar_name}" "${download_url}" 2>&1
    if [ $? -ne 0 ]; then
      echo "  Error: Failed to download BlueMap." >&2
      echo "  Command failed: curl ${download_url}" >&2
      exit 1
    fi
  else
    echo "  (skipped, file already exists)"
  fi

  move_older_jars_out_of_the_way "${INSTANCE_DIR}/plugins/" "${PROJECT}" "${jar_name}"
  echo "Successfully saved ${PROJECT} as '${jar_name}'".
  echo
}

download_geysermc_subproject() {
  # Require one parameter
  [[ $# -eq 1 ]]
  local PROJECT="$1"

  echo "Downloading ${PROJECT}..."

  echo "  Determining latest ${PROJECT} version..."
  latest_version_builds=$(${CURL} -s https://download.geysermc.org/v2/projects/${PROJECT}/versions/latest)
  VERSION=$(echo ${latest_version_builds} | jq -r '.version')
  BUILD=$(echo ${latest_version_builds} | jq -r '.builds[-1]')
  download_url="https://download.geysermc.org/v2/projects/${PROJECT}/versions/${VERSION}/builds/${BUILD}/downloads/spigot"

  jar_name="${PROJECT}_${VERSION}-${BUILD}.jar"
  echo "  Downloading ${PROJECT} from ${download_url}..."
  if [[ ! -f "${INSTANCE_DIR}/plugins/${jar_name}" ]]; then
    ${CURL} -o "${INSTANCE_DIR}/plugins/${jar_name}" "${download_url}" 2>&1

    if [ $? -ne 0 ]; then
      echo "  Error: Failed to download ${PROJECT}." >&2
      echo "  Command failed: curl ${download_url}" >&2
      exit 1
    fi
  else
    echo "  (skipped, file already exists)"
  fi

  move_older_jars_out_of_the_way "${INSTANCE_DIR}/plugins/" "${PROJECT}" "${jar_name}"
  echo "Successfully saved ${PROJECT} as '${jar_name}'".
  echo
}

download_viaversion() {
  PROJECT="ViaVersion"
  echo "Downloading ViaVersion..."
  GITHUB_REPO="ViaVersion/ViaVersion"

  echo "  Fetching latest ViaVersion release..."
  releases_response=$(${CURL} -s "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" 2>&1)
  if [ $? -ne 0 ]; then
    echo "  Error: Failed to fetch ViaVersion releases." >&2
    echo "  Command failed: curl https://api.github.com/repos/${GITHUB_REPO}/releases/latest" >&2
    echo "  Error output: ${releases_response}" >&2
    exit 1
  fi

  # Extract the tag for the latest version
  tag_name=$(echo "${releases_response}" | jq -r '.tag_name')
  # Extract the download URL for the PaperMC-compatible version
  download_url=$(echo "${releases_response}" | jq -r '.assets | .[] | select(.name | startswith("ViaVersion-") and endswith(".jar")) | .browser_download_url')
  if [ -z "${download_url}" ]; then
    echo "  Error: Could not find a download URL for ViaVersion release tag ${tag_name}." >&2
    exit 1
  fi

  jar_name=$(basename "${download_url}")
  echo "Downloading ViaVersion from ${download_url}..."
  if [[ ! -f "${INSTANCE_DIR}/plugins/${jar_name}" ]]; then
    ${CURL} -o "${INSTANCE_DIR}/plugins/${jar_name}" "${download_url}" 2>&1
    
    if [ $? -ne 0 ]; then
      echo "  Error: Failed to download ViaVersion ${tag_name}." >&2
      echo "  Command failed: curl ${download_url}" >&2
      exit 1
    fi
  else
    echo "  (skipped, file already exists)"
  fi
  move_older_jars_out_of_the_way "${INSTANCE_DIR}/plugins/" "${PROJECT}" "${jar_name}"
  echo "Successfully saved ${PROJECT} as '${jar_name}'".
  echo
}

move_older_jars_out_of_the_way() {
  # Require three parameters
  [[ $# -eq 3 ]]
  local plugin_dir="$1"
  local starts_with="$2"
  local jar_file="$3"

  # Find pre-existing versions and rename them ".jar_old"
  find "${plugin_dir}" \
    -maxdepth 1 -type f -iname "${starts_with}*.jar" -not -name "${jar_file}" -print0 \
    | xargs -0 -I{} mv -v {} {}_old
}

# Run all download functions
download_papermc
download_geysermc_subproject "geyser"
download_geysermc_subproject "floodgate"
download_bluemap
download_viaversion
