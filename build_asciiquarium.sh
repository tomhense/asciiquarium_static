#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME='asciiquarium-static'
OUTPUT_NAME='asciiquarium'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

curl -o 'Asciiquarium.pm' 'https://robobunny.com/projects/asciiquarium/asciiquarium' || { echo 'Error downloading file' >&2; exit 1; }
curl -O 'https://fastapi.metacpan.org/source/KBAUCOM/Term-Animation-2.6/lib/Term/Animation/Entity.pm' || { echo 'Error downloading file' >&2; exit 1; }
curl -O 'https://fastapi.metacpan.org/source/KBAUCOM/Term-Animation-2.6/lib/Term/Animation.pm' || { echo 'Error downloading file' >&2; exit 1; }


echo "[1/2] Building Docker image ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" "${SCRIPT_DIR}"

echo "[2/2] Extracting ${OUTPUT_NAME} from image"
HOST_UID=$(id -u)
HOST_GID=$(id -g)
docker run --rm \
  -v "${SCRIPT_DIR}":/out \
  -e HOST_UID="${HOST_UID}" \
  -e HOST_GID="${HOST_GID}" \
  --entrypoint /bin/sh \
  "${IMAGE_NAME}" \
  -c "cp /asciiquarium_static /out/${OUTPUT_NAME} && chown \${HOST_UID}:\${HOST_GID} /out/${OUTPUT_NAME} && chmod 755 /out/${OUTPUT_NAME}"

echo "Done. Binary available at ${SCRIPT_DIR}/${OUTPUT_NAME}"
