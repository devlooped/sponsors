function Write-Organization {
  [CmdletBinding()]
  param ([Parameter(Mandatory, ValueFromPipeline)] $node)
  # if $node.login or $node.AvatarUrl are null, return
  # for some reason, with our explicit gold sponsors query, this fails 
  # in CI but not locally :/
  if ($node.login -eq $null -or $node.avatarUrl -eq $null) { return; }
  
  $img = iwr ($node.avatarUrl + "&s=70");
  $type = $img.Headers["Content-Type"];
  $base64 = [convert]::ToBase64String($img.Content);
  $svg = "<svg xmlns='http://www.w3.org/2000/svg' style='background-color: white' fill='none' width='38' height='38'>
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

function Write-User {
  [CmdletBinding()]  
  param ([Parameter(Mandatory, ValueFromPipeline)] $node)

  $img = iwr ($node.avatarUrl + "&s=70");
  $type = $img.Headers["Content-Type"];
  $base64 = [convert]::ToBase64String($img.Content);
  $svg = "<svg xmlns='http://www.w3.org/2000/svg' style='background-color: white' fill='none' width='38' height='38'>
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
  Write-Organization $node
}

foreach ($node in $users) {
  Write-User $node
}

# add some hardcoded gold sponsors
$gold = @( "aws" );
$gold | %{ gh api graphql -f query="query { 
  organization(login: `"$_`") {
    login
    avatarUrl
  }
}" | ConvertFrom-Json | select @{ Name='node'; Expression={$_.data.organization}} | select -ExpandProperty node | Write-Organization }

$links = "";

foreach ($sponsor in $sponsors) {
  $links += "[![$($sponsor.sponsorEntity.name)](https://raw.githubusercontent.com/devlooped/sponsors/main/.github/avatars/$($sponsor.sponsorEntity.login).png `"$($sponsor.sponsorEntity.name)`")](https://github.com/$($sponsor.sponsorEntity.login))`n";
}

$links | Out-File .\sponsors.md -Force -Encoding UTF8

write-host "Using chrome from $env:chrome"

Push-Location .github\avatars
Get-ChildItem *.svg | %{ html2image --html "$($_.Name)" --save "$($_.BaseName).png" --chrome_path "$env:chrome" -v --size 38,38}
Pop-Location