using namespace Microsoft.PowerShell.SHiPS

[SHiPSProvider(UseCache = $false)]
class PSConfAsia : SHiPSDirectory
{
    #Default constructor
    PSConfAsia([string]$name): base($name)
    {        
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $agenda = Get-Content -Path "$PSScriptRoot\data.json" -raw | ConvertFrom-Json

        $obj += [PSConfAsiaDay]::new('Days', $agenda)
        $obj += [PSConfAsiaOrganizers]::new('Oragnizers',$agenda)        
        $obj += [PSConfAsiaSpeaker]::new('Speakers',$agenda)
        $obj += [PSConfAsiaTrack]::new('Tracks',$agenda)
        
        return $obj
    }
}

[SHiPSProvider(UseCache = $false)]
class PSConfAsiaDay : SHiPSDirectory
{
    hidden [Object] $agenda

    PSConfAsiaDay([string]$name, [object]$agenda): base($name)
    {
        $this.agenda = $agenda
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $days = @()
        
        $days += $this.agenda.Tracks.Day | Select-Object -Unique
        $days += $this.agenda.Tracks2.Day | Select-Object -Unique

        foreach ($day in $days)
        {
            $obj += [PSConfAsiaDaySession]::new($day, $this.agenda)
        }
        return $obj
    }
}

[SHiPSProvider(UseCache = $false)]
class PSConfAsiaDaySession : SHiPSDirectory
{
    hidden [Object] $agenda

    PSConfAsiaDaySession([string]$name, [Object]$agenda): base($name)
    {
        $this.agenda = $agenda
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $daySessions = @()
        $daySessions += ($this.Agenda.Tracks | Where-Object { $_.Day -eq $this.Name}).Sessions 
        $daySessions += ($this.Agenda.Tracks2 | Where-Object { $_.Day -eq $this.Name}).Sessions
        foreach ($session in $daySessions)
        {
            if ($null -ne $session.SessionId)
            {
                $obj += [PSConfAsiaSession]::new($session.sessionId,$this.Name,$session.Time,$session.Title,$session.Speaker.Name)
            }
        }
        return $obj
    }
}

[SHiPSProvider(UseCache = $false)]
class PSConfAsiaOrganizers : SHiPSDirectory
{
    hidden [Object] $agenda
    PSConfAsiaOrganizers([string]$name, [object] $agenda): base($name)
    {
        $this.agenda = $agenda
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        foreach ($organizer in $this.agenda.Organizers)
        {
            $obj += [PSConfAsiaOrganizer]::new($organizer.Name, $organizer.social)
        }
        return $obj
    }
}

[SHiPSProvider(UseCache = $false)]
class PSConfAsiaOrganizer : SHiPSLeaf
{
    [string] $social
    PSConfAsiaOrganizer([string]$name, [string]$social): base($name)
    {
        $this.social = $social
    }
}

[SHiPSProvider(UseCache = $false)]
class PSConfAsiaSpeaker : SHiPSDirectory
{
    hidden [Object] $agenda

    PSConfAsiaSpeaker([string]$name, [Object]$agenda): base($name)
    {
        $this.agenda = $agenda
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $speakers = @()
    
        $speakers += $this.agenda.Tracks.Sessions.Speaker.Name
        $speakers += $this.agenda.Tracks2.Sessions.Speaker.Name

        $uniqueSpeakers = $speakers | Select-Object -Unique

        foreach ($speaker in $uniqueSpeakers)
        {
            $detail = $null
            if (($speaker.trim() -ne '') -or ($null -eq $speaker))
            {
                $detail = $this.agenda.Tracks.Sessions.speaker.Where({$_.Name -eq $speaker})
                $detail = $this.agenda.Tracks2.Sessions.speaker.Where({$_.Name -eq $speaker})
                $social = $detail.Social
                $obj += [PSConfAsiaSpeakerSession]::new($speaker, $this.agenda, $social)
            }
        }
        return $obj
    }
}

[SHiPSProvider(UseCache = $false)]
class PSConfAsiaSpeakerSession : SHiPSDirectory
{
    hidden [Object] $agenda
    [string] $social

    PSConfAsiaSpeakerSession([string]$name, [Object]$agenda, [string]$social): base($name)
    {
        $this.agenda = $agenda
        $this.social = $social
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $track = @()
        $track += $this.agenda.Tracks.Where({$_.Sessions.Speaker.Name -eq $this.Name})
        $track += $this.agenda.Tracks2.Where({$_.Sessions.Speaker.Name -eq $this.Name})

        $uniqueDays = $track.Day | Select-Object -Unique

        foreach ($day in $uniqueDays)
        {
            $trackSessions = $track.Where({$_.Day -eq $day}).Sessions
            foreach ($session in $trackSessions)
            {
                if ($session.Speaker.Name -eq $this.Name)
                {
                    if ($null -ne $session.SessionId)
                    {
                        $obj += [PSConfAsiaSession]::new($session.sessionId,$day,$session.Time,$session.Title,$session.Speaker.Name)
                    }
                }
            }
        }
        return $obj
    }
}

[SHiPSProvider(UseCache = $false)]
class PSConfAsiaTrack : SHiPSDirectory
{
    hidden [Object] $agenda
    PSConfAsiaTrack([string]$name, [Object]$agenda): base($name)
    {
        $this.agenda = $agenda
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $tracks = @()
        $tracks += $this.agenda.Tracks.Name
        $tracks += $this.agenda.Tracks2.Name

        $uniqueTracks = $tracks | Select-Object -Unique
        foreach ($trackName in $uniqueTracks)
        {
            $obj += [PSConfAsiaTrackSession]::new($trackName, $this.agenda)
        }
        return $obj
    }
}

[SHiPSProvider(UseCache = $false)]
class PSConfAsiaTrackSession : SHiPSDirectory
{
    hidden [Object] $agenda
    PSConfAsiaTrackSession([string]$name, [Object]$agenda): base($name)
    {
        $this.agenda = $agenda
    }
    [object[]] GetChildItem()
    {
        $obj = @()
        $track = @()
        $track += $this.agenda.Tracks.Where({$_.Name -eq $this.Name})
        $track += $this.agenda.Tracks2.Where({$_.Name -eq $this.Name})

        $uniqueDays = $track.Day | Select-Object -Unique

        foreach ($day in $uniqueDays)
        {
            $trackSessions = $track.Where({$_.Day -eq $day}).Sessions
            foreach ($session in $trackSessions)
            {
                if ($null -ne $session.SessionId)
                {
                    $obj += [PSConfAsiaSession]::new($session.sessionId,$day,$session.Time,$session.Title,$session.Speaker.Name)
                }
            }
        }
        return $obj
    }
}

[SHiPSProvider(UseCache = $false)]
class PSConfAsiaSession : SHiPSLeaf
{
    [string] $Day
    [string] $Time
    [string] $Speaker
    [String] $Title

    PSConfAsiaSession([string]$name, [string]$Day, [String] $Time, [String] $Title, [String] $Speaker): base($name)
    {
        $this.Day = $Day
        $this.Time = $Time
        $this.Title = $Title
        $this.Speaker = $speaker
    }
}