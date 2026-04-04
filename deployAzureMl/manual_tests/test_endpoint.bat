@echo off
REM ============================================================
REM  Przykladowe odpytanie modelu TorchScript na Azure ML
REM  Managed Online Endpoint za pomoca curl
REM ============================================================

REM --- Konfiguracja ---
REM Uzupelnij ponizsze wartosci po wykonaniu "tofu apply"
set SCORING_URI=https://torchscript-yolo-endpoint.polandcentral.inference.ml.azure.com/score
set ENDPOINT_NAME=torchscript-yolo-endpoint
set RESOURCE_GROUP=radian7-rg
set WORKSPACE_NAME=Workspace1

REM --- Pobranie klucza API ---
echo Pobieram klucz API endpointu...
for /f "delims=" %%K in ('az ml online-endpoint get-credentials --name %ENDPOINT_NAME% --resource-group %RESOURCE_GROUP% --workspace-name %WORKSPACE_NAME% --query primaryKey -o tsv') do set API_KEY=%%K

if "%API_KEY%"=="" (
    echo BLAD: Nie udalo sie pobrac klucza API. Sprawdz czy jestes zalogowany: az login
    exit /b 1
)
echo Klucz pobrany pomyslnie.

REM --- Przykladowe dane wejsciowe (base64) ---
REM Plik sample_input.json zawiera obraz testowy zakodowany w base64:
REM   {"image_base64": "<base64 string>"}
REM Aby wygenerowac payload z innego obrazu uzyj: python generate_payload.py sciezka/do/obrazu.jpg
set INPUT_FILE=%~dp0sample_input.json

if not exist "%INPUT_FILE%" (
    echo BLAD: Brak pliku %INPUT_FILE%
    echo Wygeneruj go: python generate_payload.py sciezka/do/obrazu.jpg
    exit /b 1
)

REM --- Wywolanie REST API ---
echo.
echo Wysylam zapytanie do: %SCORING_URI%
echo.

curl -s -X POST "%SCORING_URI%" ^
    -H "Content-Type: application/json" ^
    -H "Authorization: Bearer %API_KEY%" ^
    -d @"%INPUT_FILE%"

echo.
echo.
echo Gotowe.
