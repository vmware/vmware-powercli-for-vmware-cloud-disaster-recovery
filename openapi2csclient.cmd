@echo off
REM Create the C# client
REM NSWAG https://github.com/RicoSuter/NSwag has to be installed
set OUTPUT=/output:.\c#.netcode\VMware.VCDRService\Client.cs
set INPUT=/input:.\NSwag\vcdr.yaml

set CLASSNAME=/classname:VCDRServer
set NAMESPACE=/namespace:VMware.VCDRService
set INJECTHTTPCLIENT=/injectHttpClient:true
set GENERATEBASEURLPROPERTY=/generateBaseUrlProperty:false
set USEBASEURL=/useBaseUrl:true 
set GENERATESYNCMETHODS=/generateSyncMethods:false
nswag openapi2csclient %CLASSNAME%  %NAMESPACE%   %INJECTHTTPCLIENT% %GENERATESYNCMETHODS% %USEBASEURL% %GENERATEBASEURLPROPERTY% %INPUT% %OUTPUT%  