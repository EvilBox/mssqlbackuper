#!/bin/bash

MSSQL_HOST="localhost"
BACKUP_DIR="X:"
TMP_BACKUP_DIR="C:\sql_tmp"
MSSQL_USER="sa"
MSSQL_PASS="12345678"
MSSQL_EXEC="/opt/mssql-tools/bin/sqlcmd"
DATE_FULL=`date +%d.%m.%Y-%H.%M`
DATE=`date +%d.%m.%Y`
DBNAME=$1
SHARE_URL="\\\my.nas.com\sql_backup"
SHARE_USER="DOMAIN\User"
SHARE_PASS="passw0rd"
DUMP_TYPE=$2 #set parameter to CHECKSUM (full dump) or DIFFERENTIAL (diff dump)
[ ${DUMP_TYPE} = CHECKSUM ] && SUFFIX=Full || SUFFIX=Diff # Set suffix for dumps name

echo "Starting MSSQL backup with the following conditions:"
echo ""
echo "  Backup to: "$SHARE_URL"\\"$DATE"\\$DBNAME"
echo "  Backup database: $DBNAME"
echo "  MSSQL Server: $MSSQL_HOST"
echo ""
echo ""
echo "Create dump $DBNAME:" #SET NOCOUNT ON parameter removes (rows affected from the output)
$MSSQL_EXEC -h -1 -S $MSSQL_HOST -U $MSSQL_USER -P $MSSQL_PASS -Q "SET NOCOUNT ON; BACKUP DATABASE [$DBNAME] TO DISK = '$TMP_BACKUP_DIR\\$DBNAME-$DATE_FULL-$SUFFIX.bak' WITH $DUMP_TYPE"
echo ""
echo "Mount $SHARE_URL on $BACKUP_DIR"
$MSSQL_EXEC -h -1 -S $MSSQL_HOST -U $MSSQL_USER -P $MSSQL_PASS -Q """SET NOCOUNT ON; EXEC XP_CMDSHELL 'net use $BACKUP_DIR $SHARE_URL /user:$SHARE_USER $SHARE_PASS'"""
echo ""
echo "Create folder for MSSQL dump "$SHARE_URL"\\"$DATE"\\$DBNAME"
$MSSQL_EXEC -h -1 -S $MSSQL_HOST -U $MSSQL_USER -P $MSSQL_PASS -Q """SET NOCOUNT ON; EXEC XP_CMDSHELL 'mkdir $BACKUP_DIR\\$DATE\\$DBNAME'"""
echo ""
echo "Compress dump $DBNAME via 7zip:"
$MSSQL_EXEC -h -1 -S $MSSQL_HOST -U $MSSQL_USER -P $MSSQL_PASS -Q "SET NOCOUNT ON; EXEC XP_CMDSHELL '"C:\\Soft\\compressor\\7z.exe" a -mx7 $BACKUP_DIR\\$DATE\\$DBNAME\\$DBNAME-$DATE_FULL-$SUFFIX.7z $TMP_BACKUP_DIR\\$DBNAME-$DATE_FULL-$SUFFIX.bak'"
echo ""
echo "Unmount $BACKUP_DIR"
#and clean up $TMP_BACKUP_DIR"
$MSSQL_EXEC -h -1 -S $MSSQL_HOST -U $MSSQL_USER -P $MSSQL_PASS -Q "SET NOCOUNT ON; EXEC XP_CMDSHELL 'del $TMP_BACKUP_DIR\\$DBNAME-$DATE_FULL-$SUFFIX.bak'"
$MSSQL_EXEC -h -1 -S $MSSQL_HOST -U $MSSQL_USER -P $MSSQL_PASS -Q "SET NOCOUNT ON; EXEC XP_CMDSHELL 'net use $BACKUP_DIR /delete'"
echo ""
echo "Done! Backup complete"
exit 0
