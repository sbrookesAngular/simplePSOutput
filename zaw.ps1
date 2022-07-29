# Get-CimInstance -Class CIM_NetworkAdapter -ComputerName localhost -ErrorAction Stop | Select-Object *
# Get-CimInstance -Class CIM_NetworkAdapter -ComputerName localhost -ErrorAction Stop | ConvertTo-Html | Out-File -FilePath .\ethernetInfo.html
# Get-CimInstance -Class CIM_NetworkAdapter -ComputerName localhost -ErrorAction Stop | ConvertTo-Json | Out-File -FilePath .\dataX.json

# Get-CimInstance -Class CIM_ComputerSystem -ComputerName localhost -ErrorAction Stop | Select-Object * | ConvertTo-Html | Out-File -FilePath .\ethernetInfo.html

Get-CimInstance -Class CIM_ComputerSystem -ComputerName localhost -ErrorAction Stop | Select-Object * | ConvertTo-Json | Out-File -FilePath .\dataX.json