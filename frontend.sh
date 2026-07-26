#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m" #or 0m

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #full path - /var/log/shell-script/frontend.log
MONGODB_HOST=mongodb.akshaysunny.space

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

dnf module list nginx &>>$LOG_FILE
VALIDATE $? "list of all nginx available"

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disable nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enable nginx-1.24 version"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Install nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enable nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Start nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Remove default content"    

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Download DEV provided frontend code"

cd /usr/share/nginx/html &>>$LOG_FILE
VALIDATE $? "Moving towards /usr/share/nginx/html"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzip frontend code" 

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE # its better to give full path while copying 
VALIDATE $? "copy nginx.conf file" #because we dont know where we are present right

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restart nginx"

