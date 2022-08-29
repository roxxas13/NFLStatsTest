#Categories
$CAT_MISC = 10
$CAT_RUSH = 2


$STAT_POSS = 9
$STAT_YPC = 28


##Types in the uri
$Preseason = 1
$RegSeason = 2
$PostSeason = 3
$OffSeason = 4



$teams= Invoke-RestMethod -uri https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/teams?limit=100 | foreach-object { $_.items } | foreach-object { invoke-restmethod $_.'$ref' } | ? { $_.isActive } 

#This line grabs the stats for every team
$teams | % { Add-Member -InputObject $_ -MemberType NoteProperty -Name 'stats' -Value (Invoke-RestMethod -uri https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2021/types/$RegSeason/teams/$($_.id)/statistics/0) }


#adds the teams schedule
$teams | % { Add-Member -InputObject $_ -MemberType NoteProperty -Name 'schedule' -Value (Invoke-RestMethod -uri https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/$($_.id)/schedule) }

remove-item c:\Scripts\espn.csv -erroraction silentlycontinue
$teams | foreach-object {
    $curTeam = $_
    $teamName = $curTeam.name
    $possTimeSeconds = $curTeam.stats.splits.categories[$CAT_MISC].stats[$STAT_POSS].displayValue
    $possRank = $curTeam.stats.splits.categories[$CAT_MISC].stats[$STAT_POSS].rankDisplayValue
    $YPC= $curTeam.stats.splits.categories[$CAT_RUSH].stats[$STAT_YPC].displayValue
    $YPCRANK = $curTeam.stats.splits.categories[$CAT_RUSH].stats[$STAT_YPC].rankDisplayValue
    "$teamName,$possTimeSeconds,$possRank,$YPC,$YPCRANK"
} | out-file -append c:\Scripts\espn.csv

