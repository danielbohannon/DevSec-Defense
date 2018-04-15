#This script will compare the names of the people you follow on Twitter
#and the people following you.  It returns a comparison object consisting 
#of the Twitter name of a subject and a side indicator - 
#"<=" means that you are following a subject who is not following you, 
#"=>" means that you are followed by someone who you are not following.

function GetTwitterNames([string]$query)
{   
    $wc = new-object System.Net.WebClient
    $wc.Credentials = $script:credential.GetNetworkCredential()

    $nbrofpeople = 0
    $page = "&page="
    $names = @()

    do 
    {
        $url = $query
        if ($nbrofpeople -gt 0)
        {
            $url = $url+$page+($nbrofpeople/100 +1)
        }

        [xml]$nameslist = $wc.DownloadString($url)

        $names += $nameslist.users.user | select name

        $nbrofpeople += 100
    } while ($names.count -eq $nbrofpeople)

    return $names
}

$twitter = "http://twitter.com/statuses/"
$friends = $twitter + "friends.xml?lite=true"
$followers = $twitter + "followers.xml?lite=true"

$credential = Get-Credential

$friendslist = GetTwitterNames($friends)
$followerslist = GetTwitterNames($followers)

compare-object $friendslist $followerslist -SyncWindow (($friendslist.count)/2) -Property name
