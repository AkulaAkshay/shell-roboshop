#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m" #or 0m

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #full path - /var/log/shell-script/shipping.log
MONGODB_HOST=mongodb.akshaysunny.space
MYSQL_HOST=mysql.akshaysunny.space

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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Install maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE &>>$LOG_FILE
   VALIDATE $? "Adding a USER"
else
   echo -e "user roboshop already exists so .. $Y skipping $N" | tee -a $LOG_FILE
fi

#Inorder to make the script idempotent - we should check if "/app" directory is already present or not
mkdir -p /app &>>$LOG_FILE
VALIDATE $? "create an /app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Download the DEV written code"

cd /app &>>$LOG_FILE
VALIDATE $? "Moving towards /app"

#here the execution is struck because when we run the script for the 1st time it executed well, but for 2nd time when we execute it is asking that whether i should remove the previous code and put the new code or stick with the previous code ? - here human intervention is needed. There might be code change so we need to replace the code. what we can do safely is - remove the previous code and put the new code
rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Removing the existing code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Un-Zip the code in /app directory"

cd /app &>>$LOG_FILE
VALIDATE $? "Moving towards /app"

mvn clean package &>>$LOG_FILE
VALIDATE $? "maven clean package"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE


cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE # its better to give full path while copying 
#because we dont know where we are present right now, hence when we provide full path then we don't face any issues.
VALIDATE $? "copy systemctl service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload" 

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enable shipping"       

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Start shipping"    

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Install MySQL"

#check whether the shipping schema is already present or not, if it is present then we should not run the shipping.sql file again because it will throw an error saying that table already exists. Hence to avoid the error we are checking whether the shipping schema is already present or not.
#if schema is already present we will get the exit code as 0, if schema is not present we will get the exit code as 1. Hence we are checking the exit code and based on that we are running the shipping.sql file.

#interactive mode -
#mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 
# we wil log in to the mysql server and then we will run the schema.sql file. Hence we are using interactive mode.

#Non-interactive mode -
#mysql -h $MONGODB_HOST -uroot -pRoboShop@1 -e "use cities" --> when we don't have the schema --> for schema "cities" --> we will get the exit code as 1
#mysql -h $MONGODB_HOST -uroot -pRoboShop@1 -e "use mysql" --> when we have the schema --> for schema "shipping" --> we will get the exit code as 0
# what we do is - we will check whether the schema is already present or not by using the above command  (mysql -h $MONGODB_HOST -uroot -pRoboShop@1 -e "use shipping") and based on the exit code we will run the shipping.sql file.

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restart shipping"


