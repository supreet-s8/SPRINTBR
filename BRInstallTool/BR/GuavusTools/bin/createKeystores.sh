###############################################
################INSTRUCTIONS###################
# 1. populate the list with the IPs/Domains for which certificate needs to be generated
# 2. depending on the platform on which the script is being run, uncomment the appropriate keytool_command
# 3. if required, modify the optional parameters
# 4. run the script, it will generate individual keystores by the name server.store_IP/DOMAIN and a trust.store which will have keys from all the individual stores
# 5. don't use special characters as password
###############################################
#mandatory parameter
list="localhost 10.136.239.51 10.136.239.52 10.136.239.53 10.136.239.54"

#keytool for mac
#keytool_command="keytool"

#keytool for linux
keytool_command="/usr/java/latest/bin/keytool"

#optional params
pass="admin123"
organization_unit="RUBIX"
organization="GUAVUS"
city="GURGAON"
state="HARYANA"
country_code="IN"
importInput=$pass"\n"$pass"\nyes"
for ip in $list
    do
        #create keystore
	printf $pass
        printf $pass"\n"$pass"\n"$ip"\n"$organization_unit"\n"$organization"\n"$city"\n"$state"\n"$country_code"\nyes" | $keytool_command -keysize 2048 -genkey -alias tomcat -keyalg RSA -keystore "server.store_"$ip

        #export private key
        printf $pass | $keytool_command -export -keystore "server.store_"$ip -alias tomcat -file $ip.cer

	printf $pass
        #import private key into trust.store
        printf $importInput | $keytool_command -import -trustcacerts -keystore trust.store -keypass $pass -alias tomcat_$ip -file $ip.cer

        #change importInput after first run
        importInput=$pass"\nyes"
     done
