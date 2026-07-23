#!/bin/bash

#we are installing 3 packages - mongodb, ngix, python3

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m" #or 0m

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #full path - /var/log/shell-script/16-logs.log
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





dnf module list nodejs &>>$LOG_FILE
VALIDATE $? "list of all nodejs available"

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable nodejs-20 version"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Adding a USER"

mkdir /app &>>$LOG_FILE
VALIDATE $? "create a /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Download the DEV written code"

cd /app &>>$LOG_FILE
VALIDATE $? "Moving towards /app"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Un-Zip the code in /app directory"

cd /app &>>$LOG_FILE
VALIDATE $? "Moving towards /app"

npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "copy systemctl service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable catalogue &>>$LOG_FILE 
VALIDATE $? "Enable catalogue"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Start catalogue"

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "copy mongo repo"


dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install mongodb client" #inorder to connect to mongodb server

mongosh --host MONGODB-SERVER-IPADDRESS </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load catalogue products"



