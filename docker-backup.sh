#!/bin/bash

cur="$(pwd)"
tmp="$(mktemp -d)"
script_name="$(basename $0)"
date="$(date +%Y-%m-%d_%H-%M-%S)"

# Help Screen
help() 
{
  echo -n "${script_name} [OPTIONS]
Backup|Restore of docker containers and|or docker volumes
 Options:
  backup               Perform backup action
  restore              Perform restore action
  -p|--backup_path     Path to directory where backup files will be created or
                       where backup files will be restored
  -b|--backup_file     Path to backup file for restoring
  -h|--help            Display this help and exit

 Examples:
  ./${script_name} backup -p=/path/to/backup/directory
  ./${script_name} restore -b=/path/to/backup/file.tar.gz -p=/paht/to/restore/directory
  "
}

# TODO: implements backup|restore of certain containers and volumes

# Init
init() 
{
  cd "${tmp}"
  pwd
}

test_output_path() 
{
  if ! [ -d "${OUTPATH}" ]; then
    echo "The specified directory \"${OUTPATH}\" does not exist"
    exit 1
  fi
}

test_backup_path()
{
    if ! [ -f "${BACKUP_FILE}" ]; then
    echo "The specified file \"${BACKUP_FILE}\" does not exist"
    exit 1
  fi
}

# Cleanup
cleanup() {
  echo "Cleaning up"
  cd "${cur}"
  rm -rf "${tmp}"
}

safe_exit() 
{
  if [ -d "${tmp}" ]; then
    rm -rf "${tmp}"
  fi

  trap - INT TERM EXIT
  exit
}

control_c() 
{
  echo -en "\n## Caught SIGINT; Clean up and Exit \n"
  cleanup
  exit 1
}

trap control_c SIGINT INT TERM

# Process Arguments
while [ "$2" != "" ]; do
  PARAM="$(echo "$2" | awk -F= '{print $1}')"
  VALUE="$(echo "$2" | awk -F= '{print $2}')"
  case ${PARAM} in
    backup) ACTION="${PARAM}" ;;
    restore) ACTION="${PARAM}" ;;
    -p|--backup_path) OUTPATH="${VALUE}"; test_output_path ;;
    -b|--backup_file) BACKUP_FILE="${VALUE}"; test_backup_path ;;
    -h|--help) help; safeExit ;;
    *) echo "ERROR: unknown parameter \"${PARAM}\""; help; exit 1 ;;
  esac
  shift
done

# Backup full
backup_full()
{
  BACKUP_NAME="docker_backup_$date"
  
  # Containers backup
  init
  for i in $(docker ps -q); do
    container_name="$(docker ps -f "id=${i}" --format '{{.Names}}')"
    echo "Creating backup for container ID ${i}..."
    docker commit -p "${i}" "backup-container-${container_name}"
    docker save -o "backup-container-${container_name}.tar" "backup-container-${container_name}"
    docker image rm $(docker images -q "backup-container-${container_name}")
    echo
  done

  # Volumes backup
  for i in $(docker ps -q); do
    container_name="$(docker ps -f "id=${i}" --format '{{.Names}}')"
    volume_destination="$(docker inspect --format '{{range .Mounts}}{{println .Destination}}{{end}}' "${i}")"
    echo "Creating volumes backups for container ID ${i}..."
    for k in ${volume_destination}; do
      docker run --rm --volumes-from "${i}" -v "${tmp}:/backup" ubuntu \
      tar -cvf "/backup/backup_volume.tar" -C "${k}" . > /dev/null
      mv "${tmp}/backup_volume.tar" "${tmp}/backup-volume-${container_name}-${k//\//_}.tar"
    done
  done
  
  # Compressing backup files to an archive
  echo
  echo "Compressing backup files into an archive '${BACKUP_NAME}.tar.gz'..."
  tar -cvzf "${OUTPATH}/${BACKUP_NAME}.tar.gz" -C "${tmp}" ./* && \
  echo "Backup archive '${BACKUP_NAME}.tar.gz' created successfully"

  cleanup
}

restore_full()
{
  # Unarchive all backup files
  echo "Uncompressing backup files..."
  echo
  tar -xf "${BACKUP_FILE}" -C "${OUTPATH}" || \
  echo -e "\nMake sure to specify all parameters correctly\n" && help && exit 1

  # Restore containers
  for i in ${OUTPATH}/backup-container-*.tar; do
    echo "Restoring backup file ${i}..."
    docker load -i "${i}"
    echo
  done

  # Verify that restore completed successfully
  [ "$(docker images backup-container* | wc -l)" -gt 1 ] && \
  echo "Restore of containers finished successfully" || \
  echo "Containers were not restored"

  cleanup
}

if [ "$#" -lt 1 ]; then
  help; exit 1
fi

if [ "${ACTION}" == "backup" ]; then
  backup_full
elif [ "${ACTION}" == "restore" ]; then
  restore_full
else
  help; exit 1
fi