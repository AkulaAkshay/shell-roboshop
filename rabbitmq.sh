#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m" #or 0m

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #full path - /var/log/shell-script/16-logs.log
SCRIPT_DIR=$PWD

START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "script started executed at : $(date)" | tee -a $LOG_FILE #tee is used because by echo statemnet it prints in the terminal but dosen't
# store in the logs, in order to print in the terminal and store in the logs we use tee command.

if [ $USERID -ne 0 ]; then 
    echo "Error: please run the command with the root privilages"
    exit 1 # when we have a probability of failure we need to provide exit code as non-zero
fi

VALIDATE(){

    if [ $1 -ne 0 ]; then
      echo -e "ERROR $2 is $R failed $N" | tee -a $LOG_FILE
      exit 1
    else
      echo -e "$2 is $G success $N" | tee -a $LOG_FILE
      #exit 0 -- if we want we can prvide but by default it takes 0 only
    fi

}

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding rabbitmq repo"

dnf install rabbitmq-server -y
VALIDATE $? "Installing rabbitmq"

systemctl enable rabbitmq-server
VALIDATE $? "Enabling rabbitmq"

systemctl start rabbitmq-server
VALIDATE $? "starting rabbitmq"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Setting up permissions"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"