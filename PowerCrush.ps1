
function Initialize-RawUI($fgColor, $bgColor)
{
  $script:ui=(get-host).ui
  $script:rui=$script:ui.rawui
  $script:rui.BackgroundColor=$bgColor
  $script:rui.ForegroundColor=$fgColor
  $script:cursor = new-object System.Management.Automation.Host.Coordinates
  cls
}


function Write-at-Position($x, $y, $text, $fgColor, $bgColor)
{
  # Write text to the given coordonates with given colors
  $script:cursor.x = $x
  $script:cursor.y = $y
  $script:rui.cursorposition = $script:cursor
  write-host -foregroundcolor $fgColor -backgroundcolor $bgColor -nonewline $text
}

function Initialize-Interface
{
  #Menu Display
  Write-at-Position 17 1 "PowerCrush par Emie Doucet" "White" "Black"
  Write-at-Position 3 2 "Projet de Veille Technologique Cegep de Shawinigan 2022" "White" "Black"
  Write-at-Position 6 37 "W, A, S, D pour bouger" "White" "Black"
  Write-at-Position 6 38 "Fleches pour echanger dans la direction souhaitee" "White" "Black"
  Write-at-Position 6 39 "Q pour melanger les pieces" "White" "Black"
  Write-at-Position 6 40 "Escape pour quitter" "White" "Black"
	$script:BoardXOffset = 14
	$script:BoardYOffset = 5
	$script:PlayerScore = 0
}

function Draw-Hilight($x, $y, $color)
{
  Write-at-Position $x $y "+---+" $color "black"
	Write-at-Position $x ($y+1) "|" $color "black"
	Write-at-Position $x ($y+2) "|" $color "black"
	Write-at-Position $x ($y+3) "|" $color "black"
	Write-at-Position ($x+4) ($y+1) "|" $color "black"
	Write-at-Position ($x+4) ($y+2) "|" $color "black"
	Write-at-Position ($x+4) ($y+3) "|" $color "black"
  Write-at-Position $x ($y+4) "+---+" $color "black"
}

function Draw-Gamepiece($x, $y, $pieceType, $phase)
{
  $c1="black"

  switch ($pieceType)
  {
    1 { $c2="cyan";  $s="!"; break; }
    2 { $c2="yellow";  $s="@"; break; }
    3 { $c2="magenta";  $s="#"; break; }
    4 { $c2="red";  $s="$"; break; }
    5 { $c2="green";  $s="%"; break; }
    6 { $c2="blue";  $s="&"; break; }
    7 { $c2="white";  $s="*"; break; }
    default { $c2="black"; $s=" "; break; }
  }

  if ($pieceType -eq -1)	
  {
    Write-at-Position $x $y "   " $c1 $c2;
    Write-at-Position $x ($y+1) "   " $c1 $c2;
    Write-at-Position $x ($y+2) "   " $c1 $c2;
  } 
  else 
  {
    if ($phase -eq 2)
    {
      $cTemp=$c1
      $c1=$c2
      $c2=$cTemp
    }

    Write-at-Position $x $y "   " $c1 $c2;
    Write-at-Position $x ($y+1) " $s " $c1 $c2;
    Write-at-Position $x ($y+2) "   " $c1 $c2;
  }
}


function Generate-Board
{
  $script:board = @()
  $script:boardPhase = @()

  for ($x=0; $x -lt 6; $x++)
  {
    for ($y=0; $y -lt 6; $y++)
    {
      $script:board += get-random -minimum 1 -maximum 8
      $script:boardPhase  += 1
      $script:oldBoard += -1
    }  
  }
}

function Get-PieceX($piece)
{
  # Get the X location of a piece, based on the board's width
  $piece % 6
}

function Get-PieceY($piece)
{
  # get the Y location of a piece, besed on the board's height
  [Math]::Floor($piece / 6)
}

function Draw-Board
{
  for ($x=0; $x -lt $script:board.count; $x++)
  {
    if ($script:oldBoard[$x] -ne $script:board[$x])
    {
      Draw-Gamepiece (((Get-PieceX $x) * 5) + ($script:BoardXOffset)) (((Get-PieceY $x) * 5)+ ($script:BoardYOffset)) $script:board[$x] $script:boardPhase[$x]
    }
  }
  
  $script:oldBoard = $script:board | foreach { $_ }

  #debug board
  #Write-at-Position 3 43 "           |           |           |           |           |          |" "Red" "Black"
  #Write-at-Position 3 44 $script:oldBoard "Red" "Black"
}


function Get-Neighbours($piece)
{
  # Get the neighbours associated with a piece.
  $nlist = @()

  # Left
  if ((Get-PieceX $piece)  -gt 0)
  {
    $nlist += ($piece - 1)
  }
  
  # Right
  if ((Get-PieceX $piece) -lt 5)
  {
    $nlist += ($piece + 1)
  }
  
  # Up
  if ((Get-PieceY $piece) -gt 1)
  {
    $nlist += ($piece - 6)
  }
  
  # Down
  if ((Get-PieceY $piece) -lt 5)
  {
    $nlist += ($piece + 6)
  }
  
  return $nlist
}

function CheckFor-Matches($piece)
{
  $script:MatchList = @()
  Build-MatchList $script:board[$piece] $piece (Get-PieceX $piece) (Get-PieceY $piece)
  Validate-MatchList $piece $script:MatchList
}

function Build-MatchList($pieceType, $piece, $x, $y)
{
  if ($script:board[$piece] -ne $pieceType)
  {
    return
  }
  
  if ($Script:MatchList -contains $piece)
  {
    return
  }
  
  $script:MatchList += $piece 
  
  if (($x -eq (Get-PieceX $piece)) -or ($y -eq (Get-PieceY $piece)))
  {
    foreach ($n in Get-Neighbours $piece)
    {
      Build-MatchList $pieceType $n $x $y
    }
  }
}

function Validate-MatchList($piece, $MatchList)
{
  $cols = @()
  $rows = @()
  
  for ($i=0; $i -lt $MatchList.Count; $i++)
  {
    if ((Get-PieceX $MatchList[$i]) -eq (Get-PieceX $piece))
    {
      $cols += $MatchList[$i]
    }
    if ((Get-PieceY $MatchList[$i]) -eq (Get-PieceY $piece))
    {
      $rows += $MatchList[$i]
    }
  }
  
  if ($rows.Count -ge 3)
  {
    $script:IsMatched = $true
    foreach ($p in $rows)
    {
      if ($script:boardPhase[$p] -ne 2)
      {
        $script:PlayerScore += 2;
      }
      $script:boardPhase[$p] = 2
      $script:oldBoard[$p] = -1
    }
  }
  
  if ($cols.Count -ge 3)
  {
    $script:IsMatched = $true
    foreach ($p in $cols)
    {
      if ($script:boardPhase[$p] -ne 2)
      {
        $script:PlayerScore += 2;
      }
      $script:boardPhase[$p] = 2
      $script:oldBoard[$p] = -1
    }
  }  
}

function Get-AreNeighbours($piece1, $piece2)
{
  if (Get-Neighbours($piece1) -contains $piece2)
  {
    return $true
  } else {
    return $false
  }
}


function Try-Swap($piece1, $piece2)
{
  $script:IsMatched = $false
  if (Get-AreNeighbours $piece1 $piece2)
  {
    $script:MatchList = @()
    $l1 = @()
    $l2 = @()

    Build-MatchList $script:board[$piece1] $piece1 (Get-PieceX $piece1) (Get-PieceY $piece1) 
    $l1 = $script:MatchList | foreach { $_ }
    $script:MatchList = @()
    Build-MatchList $script:board[$piece2] $piece2 (Get-PieceX $piece2) (Get-PieceY $piece2)
    $l2 = $script:MatchList | foreach { $_ }
    
    Validate-MatchList $piece1 $l1
    Validate-MatchList $piece2 $l2
  }

  return $script:IsMatched  
}

function Swap-Pieces($piece1, $piece2)
{
  $old_piece1 = $script:board[$piece1]
  $old_piece2 = $script:board[$piece2]
  $script:board[$piece1] = $old_piece2
  $script:board[$piece2] = $old_piece1
  
  if (Try-Swap $piece1 $piece2)
  {
    $script:animating = $true
  } 
  else 
  {
    $script:board[$piece1] = $old_piece1;
	  $script:board[$piece2] = $old_piece2;
  }
}

function CheckFor-ExistingMatches()
{
    for ($i=0; $i -lt $script:board.count; $i++)
    {
      CheckFor-Matches $i

	    if ($script:isMatched)
      {
        $script:animating = $true
      }
    }	
}


####################################
#
# Main script execution starts here
#
####################################


$done=$false

Initialize-RawUI "White" "Black" 
Initialize-Interface
Generate-Board
$hdir = -1
$hilight = 0
$hilightwas = 2
$sdir = -1
$script:animating = $false

while (!$done)
{
  if (!$script:animating) 
  {
		$script:animCount = 0

	  if ($rui.KeyAvailable)
	  {
			$key = $rui.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")

	    while ($script:rui.KeyAvailable)
	    {
	      $q = $script:rui.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
	    }

			if ($key.keydown)
			{
        #debug
        #Write-at-Position 60 10 "Key: $key.virtualkeycode" "Red" "Black"
				switch ($key.virtualkeycode)
				{
					27 { $done = $true; break; } # Escape
          37 { $sdir = 0; break; } # Left Arrow
          38 { $sdir = 1; break; } # Up Arrow
          39 { $sdir = 2; break; } # Right Arrow
          40 { $sdir = 3; break; } # Down Arrow
          65 { $hdir = 0; break; } # A (Left)
          87 { $hdir = 1; break; } # W (Up)
          68 { $hdir = 2; break; } # D (Right)
          83 { $hdir = 3; break; } # S (Down)
          81 { Generate-Board; break; } # Q - Regenerate Board
          default { }
				}
			}
	  }
	  
	  if ($hdir -eq 0)
	  {
		  if (($hilight % 6) -gt 0)
		  {
			$hilight--
		  }
	  }
	  
	  if ($hdir -eq 1)
	  {
      if ($hilight -gt 5)
      {
        $hilight -= 6
      }
	  }
	  
	  if ($hdir -eq 2)
	  {
      if (($hilight % 6) -lt 5)
      {
        $hilight++
      }
	  }
	  
	  if ($hdir -eq 3)
	  {
      if ($hilight -lt  30)
      {
        $hilight += 6
      }
	  }
	  
	  if ($sdir -eq 0)
	  { 
	    if (($hilight % 6) -gt 0)
      {
        Swap-Pieces $hilight ($hilight-1)
      }
	  }
	  
	  if ($sdir -eq 1)
	  {
	    if ($hilight -gt 5)
      {
        Swap-Pieces $hilight ($hilight - 6)
      }
	  }
	  
	  if ($sdir -eq 2)
	  {
      if (($hilight % 6) -lt 5)
      {
        Swap-Pieces $hilight ($hilight + 1)
      }
	  }
	  
	  if ($sdir -eq 3)
	  {
      if ($hilight -lt 30)
      {
        Swap-Pieces $hilight ($hilight + 6)
      }
	  }

	  $sdir=-1
	  $hdir=-1	  
	  
	  Draw-Board
	  
	  if ($hilight -ne $hilightwas) 
    {
      Draw-Hilight ((($hilightwas % 6) * 5) + ($script:BoardXOffset-1)) (([Math]::Floor($hilightwas / 6) * 5)+ ($script:BoardYOffset-1)) "black"
      Draw-Hilight ((($hilight % 6) * 5) + ($script:BoardXOffset-1)) (([Math]::Floor($hilight / 6) * 5)+ ($script:BoardYOffset-1)) "white"
      $hilightwas=$hilight
	  }	 
  }
  else
  {

    $script:animCount++
    
    if ($script:animCount -eq 3)
    {
      for ($i=0; $i -lt $script:board.count; $i++)
      {
        if ($script:boardPhase[$i] -eq 2)
        {
          $script:board[$i] = -1
          $script:boardPhase[$i] = 1
        }
      }
    }
    
    if ($script:animCount -ge 6)
    {
      for ($i=35; $i -gt 5; $i--)
      {
        if ($script:board[$i] -eq -1)
        {
          $script:board[$i] = $script:board[$i-6]
          $script:board[$i-6] = -1
        }
      }
    }
    
    if ($script:animCount -eq 12)
    {
      for ($i=0; $i -lt $script:board.count; $i++)
      {
        if ($script:board[$i] -eq -1)
        {
          $script:board[$i] = get-random -minimum 1 -maximum 8
        }
      }  
      $script:IsMatched=$false
      $script:animating=$false	  
      $script:animcount=0
    }
    Draw-Board
  }
  
  start-sleep -mil 100

  Write-at-Position 50 19 "Score: $script:PlayerScore           " "Green" "Black"
  
  if (!$script:IsMatched)
  {
    CheckFor-ExistingMatches
  }
}

cls
