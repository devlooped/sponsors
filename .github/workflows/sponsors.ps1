function Write-Organization {
  [CmdletBinding()]
  param ([Parameter(Mandatory, ValueFromPipeline)] $node)
  $img = iwr ($node.avatarUrl + "&s=70");
  $type = $img.Headers["Content-Type"];
  $base64 = [convert]::ToBase64String($img.Content);
  $svg = "<svg xmlns='http://www.w3.org/2000/svg' style='background: transparent' fill='none' width='39' height='39'>
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

  $svg | Set-Content -Encoding UTF8 -Path ".github/avatars/$($node.login).svg";
  write-host "=> $($node.login).svg" -ForegroundColor Green;
}

function Write-User {
  [CmdletBinding()]  
  param ([Parameter(Mandatory, ValueFromPipeline)] $node)

  $img = iwr ($node.avatarUrl + "&s=70");
  $type = $img.Headers["Content-Type"];
  $base64 = [convert]::ToBase64String($img.Content);
  $svg = "<svg xmlns='http://www.w3.org/2000/svg' style='background: transparent' fill='none' width='39' height='39'>
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

  $svg | Set-Content -Encoding UTF8 -Path ".github/avatars/$($node.login).svg";
  write-host "=> $($node.login).svg" -ForegroundColor DarkGray;
}

gh auth status

$sponsorable = $env:sponsorable

if ([string]::IsNullOrEmpty($sponsorable)) {
  throw "Environment variable 'sponsorable' is required."
}

write-host "Sponsorable account: $sponsorable" -ForegroundColor Cyan

$query = gh api graphql --paginate --jq '.data.organization.sponsorshipsAsMaintainer.nodes' -f owner=$sponsorable -f query='
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

$sponsors = $query | ConvertFrom-Json
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
$gold | %{ gh api graphql --jq '.data.organization' -f login=$_ -f query='query($login: String!) { 
  organization(login: $login) {
    login
    avatarUrl
  }
}' | ConvertFrom-Json | Write-Organization }

$links = "";

foreach ($sponsor in $sponsors) {
  $imgUrl = $sponsor.sponsorEntity.avatarUrl
  if ($imgUrl -notmatch "\?") {
    $imgUrl += "?s=39"
  } else {
    $imgUrl += "&s=39"
  }
  $img = Invoke-WebRequest $imgUrl
  Add-Type -AssemblyName System.Drawing
  $ms = New-Object System.IO.MemoryStream
  $ms.Write($img.Content, 0, $img.Content.Length)
  $image = [System.Drawing.Image]::FromStream($ms)
  
  if ($image.Width -ne 39 -or $image.Height -ne 39) {
    if ($sponsor.sponsorEntity.teamsUrl) {
      $imgUrl = "https://raw.githubusercontent.com/$sponsorable/sponsors/main/assets/team.png"
    } else {
      $imgUrl = "https://raw.githubusercontent.com/$sponsorable/sponsors/main/assets/user.png"
    }
  }
  
  $image.Dispose()
  $ms.Dispose()

  $links += "[![$($sponsor.sponsorEntity.name)]($imgUrl `"$($sponsor.sponsorEntity.name)`")](https://github.com/$($sponsor.sponsorEntity.login))`n";
}

$links | Out-File ./sponsors.md -Force -Encoding UTF8