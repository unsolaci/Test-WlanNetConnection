# Test-WlanNetConnection.ps1

## SYNOPSIS
Gets Wlan signal and packet loss details.

## PARAMETERS
| Parameter | Type  | Description                                                                         | Required? | Default Value |
|-----------|-------|-------------------------------------------------------------------------------------|-----------|---------------|
| Count     | Int32 | Specifies the number of tests. The default value is 4.                              | false     | 4             |
| Delay     | Int32 | Specifies the interval between tests, in seconds.                                   | false     | 0             |
| PingCount | Int32 | Specifies the number of echo requests to send in each test. The default value is 4. | false     | 4             |
