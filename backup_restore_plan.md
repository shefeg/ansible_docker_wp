# Backup and recovery plan
This is a shot document about the procedure of creating and restoring backups
of dockerized Wordpress application

## Backup procedure
Backup procedure consists of making backup files of existing docker containers and volumes of containers

#### Steps:
  1. Create a cron job for running `docker-backup.sh` script with `backup` parameter every day at 24:00 (please see `docker-backup.sh -h` for details). For example:
      ````
      ./docker-backup.sh backup -p=/tmp/backup_full
      ````
  2. Cron job also should have commands to move created backups to AWS S3 bucket 
  (until this functional won't be implemented in the backup script). For example:
      ````
      aws s3 cp docker_backup_2018-04-23_15-21-44.tar.gz s3://mybucket/docker_backup_2018-04-23_15-21-44.tar.gz
      ````

## Restore procedure
Restore procedure consists of transfering backup files from AWS S3 bucket
into machine and running `docker-backup.sh` script to uncompress
backup archive files

#### Steps:
  1. Transfer (copy) backup files from AWS S3 bucket using AWS CLI.
      ````
      aws s3 cp s3://mybucket/docker_backup_2018-04-23_15-21-44.tar.gz docker_backup_2018-04-23_15-21-44.tar.gz
      ````
  2. Run `docker-backup.sh` script with `restore` parameter. For example:
      ````
      ./docker-backup.sh restore -b=/backup_full/docker_backup_2018-04-23_15-21-44.tar.gz -p=/backup_full/restore
      ````
  3. Make sure docker containers are restored with docker command: 
      ````
      docker images
      ````
  4. Restore volumes to containers:

      1. To restore a container using the backup of data volumes taken, first create a new container by providing data volume and container names. For example:
          ````
          docker run -v /data-directory --name new-container-name ubuntu /bin/bash
          ````
      2. Untar the backup file created, to the new container`s data volume. For example:
          ````
          docker run --rm --volumes-from new-container-name -v $(pwd):/backup ubuntu bash -c "cd /data-directory && tar xvf /backup/backup.tar --strip 1"
          ````
          You’ll get a new container with the data restored from the backup. It is also possible to restore the data to the existing container

#### Points to note..

1. Backups should be properly named for identification and easy restore
2. Backups should be rotated regularly or moved to another storage to avoid ‘disk full’ errors
3. Backups should include all relevant information such as the registry data and config files too
4. Backups should be routinely tested and verified for adequacy
5. Backup restore should be performed with utmost caution, or else you may end up destroying containers wrongly