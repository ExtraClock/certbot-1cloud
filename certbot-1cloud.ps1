#requires -PSEdition Core

# вызывающий скрипт должен установить переменные среды:
# домен для активации: CERTBOT_1CLOUD_DOMAIN=*.some-domain.xyz
# токен для доступа к API 1cloud: CERTBOT_1CLOUD_TOKEN=ffffffff12311321321321
# в качестве первого аргумента скрипта можно указать --dry-run для тестирования настроек без фактического выпуска сертификата
# вот как может выглядеть потенциальный вызывающий скрипт:
<#

#requires -PSEdition Core

$env:CERTBOT_1CLOUD_DOMAIN = '*.some-domain.xyz'
$env:CERTBOT_1CLOUD_TOKEN = '0123456789abcdef...fedcba9876543210'

& "C:\Dev\Scala\Scripts\Certbot\certbot-1cloud.ps1" --dry-run

$env:CERTBOT_1CLOUD_DOMAIN = $null
$env:CERTBOT_1CLOUD_TOKEN = $null

#>

if (($null -eq $env:CERTBOT_CERT_DOMAIN) -or ("" -eq $env:CERTBOT_CERT_DOMAIN))
{
    if (($null -ne $env:CERTBOT_1CLOUD_SUBDOMAIN) -and ("" -ne $env:CERTBOT_1CLOUD_SUBDOMAIN) -and ($null -ne $env:CERTBOT_REAL_DOMAIN) -and ("" -ne $env:CERTBOT_REAL_DOMAIN))
    {
        $env:CERTBOT_CERT_DOMAIN = "$($env:CERTBOT_1CLOUD_SUBDOMAIN).$($env:CERTBOT_REAL_DOMAIN)"
    } else {
        throw "env variable CERTBOT_CERT_DOMAIN is empty"    
    }
}

if (($null -eq $env:CERTBOT_1CLOUD_DOMAIN) -or ("" -eq $env:CERTBOT_1CLOUD_DOMAIN))
{
    throw "env variable CERTBOT_1CLOUD_DOMAIN is empty"    
}

if (($null -eq $env:CERTBOT_1CLOUD_TOKEN) -or ("" -eq $env:CERTBOT_1CLOUD_TOKEN))
{
    throw "env variable CERTBOT_1CLOUD_TOKEN is empty"    
}

$hook_1cloud_auth = [System.IO.Path]::Combine($PSScriptRoot, "certbot-1cloud-auth.ps1")
& "certbot" `
    certonly `
    --non-interactive `
    --no-eff-email `
    --agree-tos `
    -m $env:CERTBOT_EMAIL `
    --key-type rsa `
    --cert-name $env:CERTBOT_CERT_DOMAIN `
    --rsa-key-size 4096 `
    --manual `
    --preferred-challenges=dns `
    --manual-auth-hook "pwsh ""$hook_1cloud_auth""" `
    --domain $env:CERTBOT_CERT_DOMAIN `
    $args[0]
