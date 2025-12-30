# WinLoginAudit v2.0 - Updated 2024
# forked from @jacauc 

# Configurazione Telegram
$tokenID = "123456789:ABC-DEFghIJkLMNOPqrstUvWxYZ"
$chatsID = "-098765432", "-123456789"

# Forza l'uso di TLS 1.2 per le API di Telegram
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Mappatura Logon Types
$LogonTypeMap = @{
    2  = "Interactive (Locale)"
    3  = "Network (Condivisione)"
    4  = "Batch"
    5  = "Service"
    7  = "Unlock (Sblocco)"
    8  = "NetworkCleartext"
    9  = "NewCredentials"
    10 = "RemoteInteractive (RDP)"
    11 = "CachedInteractive"
    12 = "CachedRemoteInteractive"
}

# Filtro XML (Ultimi 60 secondi)
$filterXml = @"
<QueryList>
  <Query Id='0' Path='Security'>
    <Select Path='Security'>
        (*[System[EventID=4624]] and *[EventData[Data[@Name='LogonType'] != '4' and Data[@Name='LogonType'] != '5' and Data[@Name='SubjectUserSid'] != 'S-1-0-0']])
        or
        (*[System[EventID=4625]])
    </Select>
  </Query>
</QueryList>
"@

# Recupero Eventi
try {
    $events = Get-WinEvent -FilterXml $filterXml -ErrorAction SilentlyContinue
} catch {
    exit # Esce se non ci sono eventi o errore nel log
}

if ($null -eq $events) { exit }

$ResultMessages = @()

foreach ($event in $events) {
    # Parsing sicuro dei dati dell'evento tramite XML
    $eventXml = [xml]$event.ToXml()
    $eventData = @{}
    foreach ($data in $eventXml.Event.EventData.Data) {
        $eventData[$data.Name] = $data.'#text'
    }

    $id = $event.Id
    $time = $event.TimeCreated.ToString("dd-MM-yyyy HH:mm:ss")
    $user = "$($eventData['TargetDomainName'])\$($eventData['TargetUserName'])"
    $typeNum = [int]$eventData['LogonType']
    $typeDesc = $LogonTypeMap[$typeNum] ? $LogonTypeMap[$typeNum] : "Unknown ($typeNum)"
    $sourceIp = $eventData['IpAddress']

    $ipString = if ($sourceIp -and $sourceIp -ne "-" -and $sourceIp -ne "::1") { "`n*Source IP*: $sourceIp" } else { "" }
    
    if ($id -eq 4624) {
        $msg = "✅ *Login Success*`n*Time*: $time`n*User*: $user`n*Type*: $typeDesc$ipString"
    } else {
        $msg = "❌ *Login FAILED*`n*Time*: $time`n*User*: $user$ipString"
    }
    
    $ResultMessages += $msg
}

# Rimuove duplicati e invia
$uniqueMessages = $ResultMessages | Select-Object -Unique
$computerName = $env:COMPUTERNAME
$publicIp = (Invoke-RestMethod -Uri "https://api.ipify.org") # Opzionale: ottiene IP pubblico reale

foreach ($chatId in $chatsID) {
    foreach ($text in $uniqueMessages) {
        $fullMessage = "🖥 *System:* $computerName ($publicIp)`n$text"
        $payload = @{
            chat_id    = $chatId
            text       = $fullMessage
            parse_mode = "Markdown"
        }
        # Invio tramite POST (più sicuro e robusto)
        Invoke-RestMethod -Uri "https://api.telegram.org/bot$tokenID/sendMessage" -Method Post -Body ($payload | ConvertTo-Json) -ContentType "application/json"
    }
}
