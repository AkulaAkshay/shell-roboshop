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


# $@ or $* - to display all the arguments

for package in $*
do
   # check whether that particular package is installed or not?
   dnf list installed $package &>>$LOG_FILE

   # check the exit status : if exit status is 0 - already installed; -ne 0 then not installed -> we need to install it 
   if [ $? -ne 0 ]; then
      dnf install $package -y &>>$LOG_FILE
      VALIDATE $? "$package" 
    else
      echo -e "$package is already installed .. so $Y SKIPPING $N"   
    fi
done


cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "Adding mongo repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Adding mongo repo"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enable mongodb"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "start mongodb"

