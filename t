#!/bin/bash 
shopt -s extglob
export LC_COLLATE=C

mkdir DBs   # To create directory in the first time .. in the second time it will generate an error but it will disapear because (clear) in raw NO. 5!
cd DBs
clear

########################## DB level ##########################################
function Create_DB
{ 
    ReadDBNameFromUSer
    if test -d $DBname
    then
       echo "$DBname already exists!"
    else
        mkdir $DBname
        echo "Database $DBname has been created successfully :)"
    fi

    MainDB
}

function Open_DB
{
    ReadDBNameFromUSer  
    if test -d $DBname
    then
        cd $DBname
        pwd
        echo "Done."
        MainTables
    else
        echo "$DBname doesn't exist!"
    fi

    MainDB
}

function Drop_DB
{
    ReadDBNameFromUSer
    if [ -d $DBname ]
    then 
        echo "Are you sure? y|n "
        read choice
        if [ $choice = "y" ]
        then
            rm -r $DBname
            echo -e "Database $DBname has been removed successfully :)\n\n"
        else
            MainDB
        fi
    else
        echo -e "$DBname doesn't exist!\n\n"
    fi  

    MainDB       
}

function list_DBs
{
    if [ "$(ls -A)" ]
    then
        echo -e "Available Database/s: ";ls
        echo -e "\n"  
    else
        echo "No Databases to show!"
    fi

    MainDB 
}

#### Auxiliary function, Reading Database name from the user ####################
function ReadDBNameFromUSer
{
    echo -e "Enter Database name: \c"
	read DBname    
}

##################################  Tables level ###############################################
 
function List_All_Tables
{
    ls ; MainTables
}

function Open_Certain_table
{
    ReadTableNameFromUSer
    if [ -f $Tablename ]
    then
        #cat $Tablename
        Record_stage $Tablename
    else
        echo -e "$Tablename doesn't exist!\n"
    fi

    MainTables
}

function Create_table
{
    ReadTableNameFromUSer
    if [ -f $Tablename ]
    then
        echo -e "$Tablename already exist!\n"
    else
        echo -e "Number of Columns: \c"
        read columnsNumber
        seperator="|"
        raw_seperator="\n"
        pKey=""
        counter=1
        metaData="Column Name"$seperator"Type"$seperator"Primary Key"
        while [ $counter -le $columnsNumber ]
        do
            echo -e "Name of Column Number ($counter): \c"
            read columnName

            echo -e "Type of Column $columnName: "
            select type in "integer" "string"
            do
                case $type in
                    integer ) columnType="integer";
                    break
                    ;;
                    string ) columnType="string";
                    break
                    ;;
                    * ) echo "Invalid Input :(" 
                    ;;
                esac
            done

            if [[ $pKey == "" ]]; 
            then
                echo -e "Make Primary Key ?"
                select var in "yes" "no"
                do
                    case $var in
                        yes ) pKey="PK"; metaData+=$raw_seperator$columnName$seperator$columnType$seperator$pKey;
                        break
                        ;;
                        no ) metaData+=$raw_seperator$columnName$seperator$columnType$seperator"";
                        break
                        ;;
                        * ) echo "Invalid Input :(" 
                        ;;
                    esac
                done
            else
                metaData+=$raw_seperator$columnName$seperator$columnType$seperator""
            fi

            if [[ $counter == $columnsNumber ]]; 
            then
                data=$data$columnName
            else
                data=$data$columnName$seperator
            fi

            ((counter++))

        done
        
        touch .$Tablename
        echo -e $metaData >> .$Tablename
        touch $Tablename
        echo -e $data >> $Tablename

        if [[ $? == 0 ]]
        then
            echo -e "Table Created Successfully :)\n"
        else
            echo -e "NOT Successful Creation of Table $Tablename :(\n"
        fi
    fi

    MainTables
}

function Drop_table
{
    ReadTableNameFromUSer
    if [ -f $Tablename ]
    then 
        echo "Are you sure? y|n "
        read choice
        if [ $choice = "y" ]
        then
            rm $Tablename .$Tablename
            echo -e "$Tablename Table has been removed successfully :)\n\n"
        else
            clear; MainTables
        fi
    else
        echo -e "$Tablename Table doesn't exist!\n\n"
    fi  

    MainTables
}
#### Auxiliary function, Reading table name from the user #################### 
function ReadTableNameFromUSer
{
    echo -e "Enter Table name: \c"
	read Tablename
}

################################# Record level #########################################
function InsertInto
{
      #Tablename=$1
      row=""
      if ! [ -f $1 ]
      then 
           echo "Table $1 doesn't exist!"
      else
      #Get num of rows stored in metadata file which represents the num of columns
      noOfCol=$(awk -F: 'END{print NR}' .$1)
      idx=2
      fs="|"
      colName=""
      colType=""
      colConstraint=""
      until [ $idx -gt $noOfCol ]
      do
         colName=`(awk -F'|' '{if(NR=='$idx') print $1}' .$1)`
         colType=`(awk -F'|' '{if(NR=='$idx') print $2 }' .$1)` 
         colConstraint=`(awk -F'|' '{if(NR=='$idx') print $3}' .$1)`
         echo -e "Enter data of column $colName : \c"
         read data
         
         #Validate data type 
         if [[ "$colType" == "string" ]]   
         then
           while [[ true ]]
            do
             case $data in
             +([a-z A-Z]) )
                  break
                  ;;
              *)
                 echo "Invalid data type!"
                 echo -e "Enter valid data type (string): \c"
                 read data
                 ;;
              esac
            done
         elif [[ "$colType" == "integer" ]]
         then
           while [[ true ]]
            do
                    case $data in 
                    +([0-9]) )
                            # Check if the entered PK already exists
                                if [[ "$colConstraint" == "PK" ]]
                                then
                                    flag2=1
                                    let exist=0
                                    while [[ true ]]
                                    do
                                        #set -x
                                        exist=`(awk -F'|' '{if('$data'==$('$idx'-1)) print $('$idx'-1)}' $Tablename)`  #hydrb
                                        #echo $exist
                                        #set +x
                                        if ! [[ $exist -eq 0 ]]
                                        then
                                            echo "PK already exists!"
                                            echo -e "Enter unique PK : \c"
                                            read data
                                            exist=0
                                        else 
                                            break 
                                        fi
                                    done
                                fi
                                break
                        ;;
                    *)
                        echo "Invalid data type!"
                        echo -e "Enter valid data type (int): \c"
                        read data
                        ;;
                    esac
            done
        fi
         
        # Set row data
        if ! [ $idx -eq $noOfCol ]
        then
            row=$row$data$fs  
        else
            row=$row$data
        fi
        ((idx++))
      done
     
      echo -e $row >> $1
      if [ $? -eq 0 ]
        then 
            echo "Data inserted successfully"
        else
            echo "Error !"
        fi
      fi
      row=""
     Record_stage
}


function MainDB
{  
    select choice in 'Create Database' 'Open Database' 'Drop Database' 'List Database' 'Exit'
    do 
        case $REPLY in 
            1 ) Create_DB
            ;;
            2 ) Open_DB 
            ;;
            3 ) Drop_DB
            ;;
            4 ) list_DBs 
            ;;
            5 ) clear; exit 0
            ;;
            * ) echo -e "Invalid Input :(\n" ; MainDB
        esac
        
    done
}

function MainTables
{
    select choice in 'List All Tables' 'Open Certain Table' 'Create Table' 'Drop Table' 'Back to DB Menu' 'Exit'
    do
        case $REPLY in 
            1 ) List_All_Tables 
            ;;
            2 ) Open_Certain_table 
            ;;
            3 ) Create_table 
            ;; 
            4 ) Drop_table
            ;;
            5 ) clear; cd ../; MainDB
            ;;
            6 ) clear; exit 0
            ;;
            * ) echo -e "Invalid Input :(\n" ; MainTables  
        esac
        
    done
}
function Record_stage
{
    Tablename=$1
    select choice in 'Insert New Record' 'Delete Record' 'Update Certain Cell' 'Back to Tables Menu' 'Exit'
    do
        case $REPLY in 
            1 ) InsertInto $Tablename
            ;;
            2 ) delete_record $Tablename
            ;;
            3 ) Update_cell $Tablename
            ;; 
            4 ) clear; MainTables  
            ;;
            5 ) clear; exit 0
            ;;
            * ) echo -e "Invalid Input :(\n" ; Record_stage $Tablename
        esac
    done
}


MainDB
#InsertInto $Tablename
