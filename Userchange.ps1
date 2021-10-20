# This is my first extensive powershell script while learning powershell. 
# Feel free to copy and adjust the code as you need it.
#
# I'm explainin the code for other new powershell users. 
#
#
# Mailsettings, change to your own settings. 
$smtp = "Mailserver"
$From = "report@example.com"
$To = "yourmail@example.com"
$Subject = "Userchange Active Directory"

# Get the current hour,day,month,year. Going to add this to the filename. 
$date = Get-date -Format hhddMMyyyy

# Filepath, Input your networkpath
$filepath = "\\sv1\share\"

# Referencefile, last change(s) are stored here. If you change filename, also change is here  
$refFile = (Get-ChildItem $filepath | Where-Object {$_.Name -like "aduser*.txt"}).FullName

# Filename, watch the $date. You can change the filename if you want.  
$filename = "ADusers$date.txt"

# Path and filename
$difFile = $filepath+$filename

# Get all ADusers from Active Directory
$GetADuser = Get-Aduser -Filter * | Select-Object -ExpandProperty Samaccountname

# Output data into a txt file
$GetADuser | Out-File -FilePath $difFile

# Variables for the RefferenceObject and DifferenceObject.
$difObject = Get-Content $difFile
$refObject = Get-Content $refFile

# Variable that saves the changes between the RefferenceObject and DifferenceObject into a vae
$Compare = Compare-Object $refObject $difObject

# This next part wil check if there are changes, so if there is a change in DifferenceObject then it will mail the diffirence and removes the old RefferenceObject.
# It will also remove the attatchment to the mail. The powershell format will be lost in the mail. Thats why there is an attatchment. 
# 
if ($Compare) 
{

# Tweaking the attachment format. Adjust the filepath, you can use temp folders.  
$Compare | Export-Csv -LiteralPath \\sv1\share\example.csv
$tempcsv = ( Import-Csv \\sv1\share\example.csv -Header "User","Change" | Select -Skip 1 )
$tempcsv | ForEach-Object { if ($_.User -contains "=>") { $_.User = $_.User.replace("=>","Added")} if ($_.Change -contains "<=") {$_.Change = $_.Change.replace("<=","Removed")}} 
$tempcsv | ft -AutoSize | Out-File \\sv1\share\adchange.txt
$tempbody = Get-Content \\sv1\share\adchange.txt
    
$Body = "The following changes have been made: $tempbody"
Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $smtp -Attachments "\\sv1\share\adchange.txt"

#Clean Up
Remove-item $refFile
Remove-Item -LiteralPath "\\sv1\share\example.csv"
Remove-Item -LiteralPath "\\sv1\share\adchange.txt"
}
Else {Remove-Item $difFile}

# End
