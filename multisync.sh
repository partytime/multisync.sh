#  ! /bin/bash

##multisync.sh
##Spawns multiple parallel rsync sessions for each directory it encounters, based on the number of CPU cores
##This will increase network throughput and allow saturation of a 10gig link 
##Lots of this is stolen from stackechange threads
##Also pretty ugly
##

#  source directory, no trailing slash
SRC_DIR=/src/dir

#  destination directory, no trailing slash, WILL BE CREATED IF IT DOESNT EXIST
DEST_DIR=/dest/dir
echo "Warming up"

#  create the list of directories to be synced, one rsync job for each dir, you may need to change what field this is awk'ing depending on your environment
LIST=`cd $SRC_DIR; find -type d -ls | awk '{print $11}'`

#  grab how many cpus the box has, this wont work on BSD
CPU_CNT=`cat /proc/cpuinfo|grep processor |wc -l`

# Number of rsync processes is core count times 3, minus 2 
let JOB_CNT=CPU_CNT*3 - 2

#Some logic and snapshot exclusion
[ -z "$LIST" ] && LIST="-tPavW --exclude .snapshot --exclude hourly.?"
echo "rsyncing From=$SRC_DIR To=$DEST_DIR"

#make the destination directory if it doesnt exist, if it does this will fail silently, more logic
mkdir -p $DEST_DIR
[ -z "$RSYNC_OPTS" ] && RSYNC_OPTS="-tPavW --delete-during --exclude .snapshot --exclude hourly.?"

#the final rsync command
cd $SRC_DIR
echo $LIST|xargs -n1 echo|xargs -n1 -P $JOB_CNT -I% rsync ${RSYNC_OPTS} ${SRC_DIR}/%/ ${DEST_DIR}/%/
