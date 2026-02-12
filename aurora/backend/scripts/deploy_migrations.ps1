# Simple PowerShell helper to apply SQL schema to Postgres/Supabase via psql
param(
  [string]$dbHost = $env:SUPABASE_DB_HOST,
  [int]$dbPort = 5432,
  [string]$dbUser = $env:SUPABASE_DB_USER,
  [string]$dbName = $env:SUPABASE_DB_NAME,
  [string]$dbPassword = $env:SUPABASE_DB_PASSWORD,
  [string]$schemaFile = "./sql/supabase_schema_v1.sql"
)

if (-not (Test-Path $schemaFile)) {
  Write-Error "Schema file not found: $schemaFile"
  exit 1
}

$env:PGPASSWORD = $dbPassword
psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -f $schemaFile
