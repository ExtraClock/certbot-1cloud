#requires -PSEdition Core

$api_baseUrl = "https://api.1cloud.ru"
$certbot_1cloud_token = ConvertTo-SecureString $env:CERTBOT_1CLOUD_TOKEN -AsPlainText

#запрашиваем доступные домены из 1cloud
$dns_domains = Invoke-RestMethod -Method Get -Uri "$api_baseUrl/dns" -Authentication Bearer -Token $certbot_1cloud_token

if (-not $?)
{ 
    throw "Failed to request DNS zones from 1cloud" 
}

#$dns_domains

# ищем среди доменов тот что сейчас проверяется
$dns_domain = $dns_domains | Where-Object { $_.Name -eq $env:CERTBOT_1CLOUD_DOMAIN }

Write-Host "dns_domain_id = $($dns_domain.ID)"

if ($null -eq $dns_domain)
{ 
    throw "Failed to find domain '$($env:CERTBOT_1CLOUD_DOMAIN)' in 1cloud" 
}

# ищем среди имеющихся DNS записей _acme-challenge
$dns_record = $dns_domain.LinkedRecords | Where-Object { $_.HostName -eq "_acme-challenge.$($env:CERTBOT_1CLOUD_SUBDOMAIN).$($env:CERTBOT_1CLOUD_DOMAIN)."}

Write-Host "dns_record_id = $($dns_record.ID)"

if ($null -eq $dns_record)
{ 
    throw "Failed to find dns record '_acme-challenge.$($env:CERTBOT_1CLOUD_SUBDOMAIN).$($env:CERTBOT_1CLOUD_DOMAIN).' in 1cloud" 
}


if (($null -eq $env:CERTBOT_VALIDATION) -or ("" -eq $env:CERTBOT_VALIDATION))
{
    throw "env variable CERTBOT_VALIDATION is empty (should contain challenge, passed by certbot)"    
}

# составляем тело запроса для обновления записи
$dns_record_put_body = "{
    ""DomainId"": ""$($dns_domain.ID)"",
    ""Name"": ""_acme-challenge.$($env:CERTBOT_1CLOUD_SUBDOMAIN)"",
    ""TTL"": ""1"",
    ""Text"": ""$($env:CERTBOT_VALIDATION)""
}"

# обновляем запись
Invoke-RestMethod -Method Put -Uri "$api_baseUrl/dns/recordtxt/$($dns_record.ID)" -Authentication Bearer -Token $certbot_1cloud_token -Body $dns_record_put_body -ContentType "application/json"

$i = 1
Do
{
    Write-Host "$i try"
    Write-Host "Sleep 3 sec"
    Start-Sleep -Seconds 3
    
    $record = Invoke-RestMethod -Method Get -Uri "$api_baseUrl/dns/record/$($dns_record.ID)" -Authentication Bearer -Token $certbot_1cloud_token -SkipHttpErrorCheck
    $record_state = $record.State
    Write-Host "DNS record state = '$record_state'"

    $i += 1
} While (($record_state -ne 'Active') -and ($i -lt 50))
