$stats = Invoke-RestMethod -uri https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/seasons/2021/types/2/teams/11/statistics/0

$stats | %{$_.splits} |%{$_.categories -match "defensive"}| %{$_.stats} | ?{$_.name -match "yardsAllowed"}