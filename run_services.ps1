# run_services.ps1
# Native Windows startup script using background processes, PID tracking, and venv isolation

echo "======================================================="
echo "Starting DevOps Platform Microservices (Windows)"
echo "======================================================="

$pids = @()
$RootDir = Get-Location
$PythonPath = "$RootDir\env\Scripts\python.exe"
$PipPath = "$RootDir\env\Scripts\pip.exe"

# Verify if venv exists
if (-not (Test-Path $PythonPath)) {
    Write-Host "Error: Virtual environment not found at $RootDir\env" -ForegroundColor Red
    Write-Host "Please create a venv named 'env' or update the `$PythonPath` in this script." -ForegroundColor Yellow
    exit 1
}

# Microservices configuration
$services = @(
    @{ name = "Vault Service"; dir = "backend\vault_service"; port = 8002 },
    @{ name = "GitHub Service"; dir = "backend\github_service"; port = 8001 },
    @{ name = "LLM Service"; dir = "backend\llm_service"; port = 8004 },
    @{ name = "Agent-1 (Assistant)"; dir = "backend\agent1_reasoning"; port = 8005 },
    @{ name = "Cluster Guardian"; dir = "backend\cluster_guardian"; port = 8006 },
    @{ name = "Cluster Observer"; dir = "backend\cluster_observer"; port = 8007 },
    @{ name = "Metrics Service"; dir = "backend\metrics_service"; port = 8008 },
    @{ name = "WebSocket Stream"; dir = "backend\websocket_stream"; port = 8009 },
    @{ name = "API Gateway"; dir = "backend\api_gateway"; port = 8003 },
    @{ name = "Backend Server"; dir = "backend\server"; port = 8000 }
)

# Cleanup function to stop all background processes
function Stop-Servers {
    echo "`nStopping all servers..."
    foreach ($p in $pids) {
        Stop-Process -Id $p -ErrorAction SilentlyContinue
    }
    Write-Host "All services stopped." -ForegroundColor Green
    exit
}



# Start Microservices
foreach ($service in $services) {
    $name = $service.name
    $workingDir = Join-Path $RootDir $service.dir
    $port = $service.port
    
    echo "Starting $name on Port $port..."
    
    # Run uvicorn using the venv python
    $process = Start-Process -FilePath $PythonPath -ArgumentList "-m uvicorn main:app --host 0.0.0.0 --port $port --reload" -WorkingDirectory $workingDir -PassThru -NoNewWindow
    if ($process) {
        $pids += $process.Id
    } else {
        Write-Host "Error: Failed to start $name" -ForegroundColor Red
    }
}

echo "`nAll services are starting in the background."
echo "- API Gateway (Entry): http://127.0.0.1:8000"
echo "- GitHub Service: http://127.0.0.1:8001"
echo "- Vault Service: http://127.0.0.1:8002"
echo "- LLM Service: http://127.0.0.1:8004"
echo "- Agent-1: http://127.0.0.1:8005"
echo "- Cluster Guardian: http://127.0.0.1:8006"
echo "- Cluster Observer: http://127.0.0.1:8007"
echo "- Metrics Service: http://127.0.0.1:8008"
echo "- WebSocket Stream: http://127.0.0.1:8009"

echo "`nWaiting for servers. Press Ctrl+C to stop all services."

# Keep script running to allow Ctrl+C cleanup
try {
    while ($true) { Start-Sleep -Seconds 1 }
} finally {
    Stop-Servers
}
