#!/bin/bash

obtain_kerberos_ticket () {
	
	KEYTAB_FILE="/etc/pwdreminder/binddn.keytab"
	PRINCIPAL="binddn@PE-TOOLS.CLOUD"

	kinit -kt $KEYTAB_FILE $PRINCIPAL

	if klist -s; then
    		echo "Kerberos ticket successfully obtained or renewed."
	else
    		echo "Failed to obtain or renew Kerberos ticket."
    	exit 1
	fi

}

all_users_to_csv () {

	OUTPUT_FILE="/etc/pwdreminder/freeipa_users.csv"

	for user in $(ipa user-find --all --raw | grep 'uid:' | awk '{print $2}'); do
   
	    email=$(ipa user-show $user | grep -E "Email address:" | awk '{print $3}')
	    
	    password_expiration=$(ipa user-show $user --all | grep -E "User password expiration:"| awk '{print $4}' | cut -c 1-8)
	    
	    if [ -z "$password_expiration" ]; then
		password_expiration="N/A"
	    fi
	    
	    echo "$user,$email,$password_expiration" >> $OUTPUT_FILE
	done
	
	echo "CSV file created: $OUTPUT_FILE"

}	 

check_if_password_expired () {
     	
    CSV_FILE="/etc/pwdreminder/freeipa_users.csv"
    TEMP_FILE="/etc/pwdreminder/temp.csv"

    while IFS=',' read -r column1 column2 column3; do

        password_setup_date=$(echo "$column3" | sed 's/\(....\)\(..\)\(..\)/\1-\2-\3/')
        
        current_date=$(date +"%Y-%m-%d")
	timestamp_current=$(date -d "$current_date" +%s)
        
	if [ "$password_setup_date" != "N/A" ]; then
		timestamp_pwd_setup=$(date -d "$password_setup_date" +%s)
        	seconds_in_91_days=$((91 * 24 * 60 * 60))
        	timestamp_expiration=$(($timestamp_pwd_setup + $seconds_in_91_days))
        	seconds_in_15_days=$((15 * 24 * 60 * 60))
	else 
		password_status="FALSE"
		new_line="$column1,$column2,$column3,$password_status"
		echo "$new_line" >> "$TEMP_FILE"
		continue
	fi
      

        if (( $timestamp_expiration - $timestamp_current <= $seconds_in_15_days )); then
            password_status="TRUE"
        else
            password_status="FALSE"
        fi

        new_line="$column1,$column2,$column3,$password_status"

        echo "$new_line" >> "$TEMP_FILE"
    done < "$CSV_FILE"

    mv "$TEMP_FILE" "$CSV_FILE"
    rm -rf "$TEMP_FILE"
}

days_to_pwd_expiration () {

	CSV_FILE="/etc/pwdreminder/freeipa_users.csv"
	TEMP_FILE="/etc/pwdreminder/temp2.csv"
	current_date=$(date +"%Y-%m-%d")
        timestamp_current=$(date -d "$current_date" +%s)
	seconds_in_91_days=$((91 * 24 * 60 * 60))

	while IFS=',' read -r username email pwd_date pwd_expired; do 
		if [[ $pwd_date =~ ^[0-9]+$ ]]; then
			timestamp_pwd_created=$(date -d "$pwd_date" +%s)
		else
			timestamp_pwd_created=0
		fi
		timestamp_pwd_expiration=$(($timestamp_pwd_created + $seconds_in_91_days))
		
		days_to_expire=$(( ($timestamp_pwd_expiration - $timestamp_current) / 60 / 60 / 24 ))

	# I used numbers as 'error' codes to easy deal with sending specific mails 	
	# 100001 - NOT EXPIRING
	# 100002 - EXPIRED
	# 100003 - NOT USED
		not_expiring=(100001)
		expired=(100002)
		not_used=(100003)

		if [[ "$days_to_expire" -gt 92 ]] ; then
			new_line="$username,$email,$pwd_date,$pwd_expired,$not_expiring"
		elif [[ "$days_to_expire" -lt 1 && "$days_to_expire" -ge -3 ]] ; then	
			new_line="$username,$email,$pwd_date,$pwd_expired,$expired"
		elif [[ "$days_to_expire" -lt -3 ]] ; then	
			new_line="$username,$email,$pwd_date,$pwd_expired,$not_used"
		else
			new_line="$username,$email,$pwd_date,$pwd_expired,$days_to_expire"
			
		fi

		echo "$new_line" >> "$TEMP_FILE"
	done < "$CSV_FILE"

	mv "$TEMP_FILE" "$CSV_FILE"
	rm -rf "$TEMP_FILE"

}


send_email () {

        CSV_FILE="/etc/pwdreminder/freeipa_users.csv"
        subject="Playbook Engineering VPN password expiration"
        while IFS=',' read -r username email pwd_date pwd_expired days_to_expire ; do
                if [ "$pwd_expired" == "TRUE" ]; then
                         if [ "$days_to_expire" -eq 1 ]; then
                                 message="Your Playbook Engineering VPN password will expire in $days_to_expire day. Please use the following link to reset it: https://user-portal.pe-tools.cloud/index.php?action=sendtoken"
                                echo "$message" | mutt -s "$subject" "$email"
                        elif [[ "$days_to_expire" -gt 1 && "$days_to_expire" -lt 15 ]]; then
                                message="Your Playbook Engineering VPN password will expire in $days_to_expire days. Please use the following link to reset it: https://user-portal.pe-tools.cloud/index.php?action=sendtoken"
                                echo "$message" | mutt -s "$subject" "$email"
                        elif [ "$days_to_expire" -eq 100002 ]; then
                                message="Your Playbook Engineering VPN password expired. Please use the following link to reset it: https://user-portal.pe-tools.cloud/index.php?action=sendtoken"
                                 echo "$message" | mutt -s "$subject" "$email"
                        fi
                fi

        done < "$CSV_FILE"

}


remove_csv () {
	CSV_FILE="/etc/pwdreminder/freeipa_users.csv"
	rm -rf "$CSV_FILE"
}






obtain_kerberos_ticket
all_users_to_csv
check_if_password_expired
days_to_pwd_expiration
#send_email
#remove_csv



