param(
    [string]$PrivateKey = $env:DEPLOYER_PRIVATE_KEY
)

if (-not $PrivateKey) {
    Write-Error "Please set `$env:DEPLOYER_PRIVATE_KEY or pass -PrivateKey 0x..."
    exit 1
}

if (-not $PrivateKey.StartsWith("0x")) {
    $PrivateKey = "0x$PrivateKey"
}

$RpcUrl = "https://rpc.test.mezo.org"
$Deployer = (cast wallet address --private-key $PrivateKey).Trim()
$Balance = (cast balance $Deployer --rpc-url $RpcUrl).Trim()
$Nonce = [int](cast nonce $Deployer --rpc-url $RpcUrl)

$PredictedVault = ((cast compute-address $Deployer --nonce $Nonce) -split " ")[-1].Trim()
$PredictedRouter = ((cast compute-address $Deployer --nonce ($Nonce + 1)) -split " ")[-1].Trim()

Write-Host "Deployer Address : $Deployer"
Write-Host "Testnet BTC (wei): $Balance"
Write-Host "Current Nonce    : $Nonce"
Write-Host "Predicted Vault  : $PredictedVault"
Write-Host "Predicted Router : $PredictedRouter"

if ($Balance -eq "0") {
    Write-Error "Deployer wallet ($Deployer) has 0 BTC on Mezo Testnet. Fund it before deploying."
    exit 1
}

Write-Host "`n[1/2] Deploying MezoCreditVault..."
forge create contracts/MezoCreditVault.sol:MezoCreditVault `
  --rpc-url $RpcUrl `
  --private-key $PrivateKey `
  --broadcast `
  --constructor-args `
    0x118917a40FAF1CD7a13dB0Ef56C86De7973Ac503 `
    0x86bCF0841622a5dAC14A313a15f96A95421b9366 `
    0xCdF7028ceAB81fA0C6971208e83fa7872994beE5 `
    0x1CCA7E410eE41739792eA0A24e00349Dd247680e `
    $PredictedRouter

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n[2/2] Deploying X402SettlementRouter..."
forge create contracts/X402SettlementRouter.sol:X402SettlementRouter `
  --rpc-url $RpcUrl `
  --private-key $PrivateKey `
  --broadcast `
  --constructor-args `
    $PredictedVault
