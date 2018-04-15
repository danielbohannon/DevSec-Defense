$rootDir = 'C:\\Documents and Settings\\buddyl\\My Documents\\Powershell Scripts\\';
$temp = $rootDir + 'temp'
mkdir $temp

$tempDir = $temp + '\\'

$targetFolder1 = $rootDir + 'test'
$zip1 = $tempDir + 'test1.zip'
gi $targetFolder1 | out-zip $zip1 $_

$targetFolder2 = $rootDir + 'test2'
$zip2 = $tempDir + 'test2.zip'
gi $targetFolder2 | out-zip $zip2 $_


$day = (Get-Date).get_day();
$month =  (Get-Date).get_Month();
$year = (Get-Date).get_Year();
$date = $month.ToString() + "-" + $day.ToString() + "-" + $year.ToString();


$file = $rootDir + 'backup' + $date + '.zip'

gi $temp | out-zip $file $_

rmdir $temp -r
