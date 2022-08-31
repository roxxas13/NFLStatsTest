##Season Types in the uri
$Preseason = 1
$RegSeason = 2
$PostSeason = 3
$OffSeason = 4



$teams= Invoke-RestMethod -uri https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/teams?limit=100 | foreach-object { $_.items } | foreach-object { invoke-restmethod $_.'$ref' } | ? { $_.isActive } 



#get teams stats categories
#example $teams[0].stats.miscellaneous.possessionTimeSeconds
$teams | foreach-object {
    $teamObj = $_
    $teamID = $teamObj.id
    $teamStats = Invoke-RestMethod -uri https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2021/types/$RegSeason/teams/$teamID/statistics/0
    $statsCategories = @()
    $teamStats.splits.categories | foreach-object {
        $curCategory = $_
        $catStats = @()
        $curCategory.stats | foreach-object {
            $curCatStat = $_
            $catStats += @{$curCatStat.name=$curCatStat}
        }
        $statsCategories += @{$curCategory.name=$catStats}
    }
    Add-Member -InputObject $teamObj -MemberType NoteProperty -Name 'stats' -Value $statsCategories
}




#add odds record as an object to teams
$teams | % { Add-Member -inputObject $_ -MemberType NoteProperty -Name 'OddsRecord' -Value (Invoke-RestMethod -uri https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2022/types/2/teams/$($_.id)/odds-records)}
#add team recod as object to teams
$teams | % { Add-Member -inputObject $_ -MemberType NoteProperty -Name 'TeamRecord' -Value (Invoke-RestMethod -uri https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2022/types/1/teams/$($_.id)/record)}
#adds the teams schedule
$teams | % { Add-Member -InputObject $_ -MemberType NoteProperty -Name 'schedule' -Value (Invoke-RestMethod -uri https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/$($_.id)/schedule) }




#print out team stats to csv
remove-item "G:\My Drive\NFL Stats\espn.csv" -erroraction silentlycontinue
remove-item "G:\My Drive\NFL Stats\espn.gsheet" -erroraction silentlycontinue
"Team Name,Possession Time in Seconds,Possession Rank,Yards per carry,Yards per carry Rank,Yards per Pass Attempt(YPA),YPA Rank,Team Record,Against the Spread(ATS) Record,ML record, Odds Percentage" | out-file "G:\My Drive\NFL Stats\espn.csv"
$teams | foreach-object {
    $curTeam = $_
    $teamName = $curTeam.name
    $possTimeSeconds = $curTeam.stats.miscellaneous.possessionTimeSeconds.displayValue
    $possRank = $curTeam.stats.miscellaneous.possessionTimeSeconds.rankDisplayValue
    $YPC= $curTeam.stats.rushing.yardsPerRushAttempt.displayValue
    $YPCRANK = $curTeam.stats.rushing.yardsPerRushAttempt.rankDisplayValue
    $YPA= $curTeam.stats.passing.yardsPerPassAttempt.displayValue
    $YPARANK = $curTeam.stats.passing.yardsPerPassAttempt.rankDisplayValue
    $teamRecord= $curTeam.TeamRecord.items |?{$_.name -match "All Splits"}|%{$_.displayValue}
    $oddsWins = $curTeam.OddsRecord.items | ?{$_.displayName -match "Spread Overall Record"} | %{$_.stats} | ?{$_.displayName -match "Wins"} | %{$_.displayValue}
	$oddsLosses = $curTeam.OddsRecord.items | ?{$_.displayName -match "Spread Overall Record"} | %{$_.stats} | ?{$_.displayName -match "Losses"} | %{$_.displayValue}
	$oddsTies = $curTeam.OddsRecord.items | ?{$_.displayName -match "Spread Overall Record"} | %{$_.stats} | ?{$_.displayName -match "Ties"} | %{$_.displayValue}
    $oddsTotal= $oddsWins+$oddsLosses+$oddsTies
    $mlWins = $curTeam.OddsRecord.items | ?{$_.displayName -match "money line overall"} | %{$_.stats} | ?{$_.displayName -match "Wins"} | %{$_.displayValue}
    $mlLosses = $curTeam.OddsRecord.items | ?{$_.displayName -match "money line overall"} | %{$_.stats} | ?{$_.displayName -match "Losses"} | %{$_.displayValue}
    $mlTies = $curTeam.OddsRecord.items | ?{$_.displayName -match "money line overall"} | %{$_.stats} | ?{$_.displayName -match "Ties"} | %{$_.displayValue}

    "$teamName,$possTimeSeconds,$possRank,$YPC,$YPCRANK,$YPA,$YPARANK,$teamRecord,$oddsWins - $oddsLosses - $oddsTies,$mlWins - $mlLosses - $mlTies,$oddsTotal"
} | out-file -append "G:\My Drive\NFL Stats\espn.csv"