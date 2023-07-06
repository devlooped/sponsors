gh auth status

$query = gh api graphql --paginate -f owner='devlooped' -f query='
query ($owner: String!, $endCursor: String) {
  organization(login: $owner) {
    sponsorshipsAsMaintainer(first: 100, after: $endCursor, orderBy: {field: CREATED_AT, direction: ASC}, includePrivate: false) {
      nodes {
        sponsorEntity {
          ... on Organization {
            id
            login
            name
            avatarUrl
            teamsUrl
          }
          ... on User {
            id
            login
            name
            avatarUrl
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}'

$sponsors = $query | 
    ConvertFrom-Json | 
    select @{ Name='nodes'; Expression={$_.data.organization.sponsorshipsAsMaintainer.nodes}} | 
    select -ExpandProperty nodes;

$organizations = $sponsors | where { $_.sponsorEntity.teamsUrl -ne $null } | select -ExpandProperty sponsorEntity;
$users = $sponsors | where { $_.sponsorEntity.teamsUrl -eq $null } | select -ExpandProperty sponsorEntity;

mkdir ".github/avatars" -ErrorAction Ignore

foreach ($node in $organizations) {
  $img = iwr ($node.avatarUrl + "&s=70");
  $type = $img.Headers["Content-Type"];
  $base64 = [convert]::ToBase64String($img.Content);
  $svg = "<svg xmlns='http://www.w3.org/2000/svg' fill='none' width='38' height='38'>
	<foreignObject width='100%' height='100%'>
		<div xmlns='http://www.w3.org/1999/xhtml' style='padding-top: 2px; padding-left: 2px;'>
			<style>
        img {
          border-style: none;
          border-radius: 6px;
          box-shadow: 0 0 0 1px lightgrey;
        }
			</style>
      <img width='35' height='35' src='data:$($type);base64,$($base64)' />   
		</div>
	</foreignObject>
</svg>";

  $svg | Set-Content -Path ".github/avatars/$($node.login).svg";
  write-host "=> $($node.login).svg" -ForegroundColor Green;
}

foreach ($node in $users) {
  $img = iwr ($node.avatarUrl + "&s=70");
  $type = $img.Headers["Content-Type"];
  $base64 = [convert]::ToBase64String($img.Content);
  $svg = "<svg xmlns='http://www.w3.org/2000/svg' fill='none' width='38' height='38'>
	<foreignObject width='100%' height='100%'>
		<div xmlns='http://www.w3.org/1999/xhtml' style='padding-top: 2px; padding-left: 2px;'>
			<style>
        img {
          border-style: none;
          border-radius: 50% !important;
          box-shadow: 0 0 0 1px lightgrey;
        }            
			</style>
      <img width='35' height='35' src='data:$($type);base64,$($base64)' />
		</div>
	</foreignObject>
</svg>";

  $svg | Set-Content -Path ".github/avatars/$($node.login).svg";
  write-host "=> $($node.login).svg" -ForegroundColor DarkGray;
}

$links = "";

foreach ($sponsor in $sponsors) {
  $links += "[![$($sponsor.sponsorEntity.name)](https://raw.githubusercontent.com/devlooped/sponsors/main/.github/avatars/$($sponsor.sponsorEntity.login).png `"$($sponsor.sponsorEntity.name)`")](https://github.com/$($sponsor.sponsorEntity.login))`n";
}

$links | Out-File .\sponsors.md -Force -Encoding UTF8

Push-Location .github\avatars
Get-ChildItem *.svg | %{ html2image --html "$($_.Name)" --save "$($_.BaseName).png" --size 38,38 --browser $env:chrome }
Pop-Location