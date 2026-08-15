unit rcc_build;

{$mode objfpc}{$H+}

interface

const
  RCCVersion = '4.0.0';
{$if defined(CPUX86_64)}
  RCCBuildArchitecture = 'x86_64';
{$elseif defined(CPUAARCH64) or defined(CPUARM64)}
  RCCBuildArchitecture = 'aarch64';
{$elseif defined(CPURISCV64)}
  RCCBuildArchitecture = 'riscv64';
{$else}
  RCCBuildArchitecture = 'unknown';
{$endif}
{$if defined(DARWIN)}
  RCCBuildTargetPlatform = 'apple-darwin';
  RCCBuildHostPlatform = 'apple-darwin';
{$elseif defined(FREEBSD)}
  RCCBuildTargetPlatform = 'unknown-freebsd';
  RCCBuildHostPlatform = 'unknown-freebsd';
{$elseif defined(OPENBSD)}
  RCCBuildTargetPlatform = 'unknown-openbsd';
  RCCBuildHostPlatform = 'unknown-openbsd';
{$elseif defined(NETBSD)}
  RCCBuildTargetPlatform = 'unknown-netbsd';
  RCCBuildHostPlatform = 'unknown-netbsd';
{$elseif defined(LINUX)}
  RCCBuildTargetPlatform = 'unknown-linux';
  RCCBuildHostPlatform = 'unknown-linux-gnu';
{$else}
  RCCBuildTargetPlatform = 'unknown-unknown';
  RCCBuildHostPlatform = 'unknown-unknown';
{$endif}
  RCCTargetTriple = RCCBuildArchitecture + '-' + RCCBuildTargetPlatform + '-rcc';
  RCCHostTriple = RCCBuildArchitecture + '-' + RCCBuildHostPlatform;
  RCCResourceLayoutVersion = '1';
  RCCDefaultPrefix = '/usr/local';
  RCCProjectURL = 'https://github.com/RobertFlexx/rcc';

function RCCVersionNumber: LongWord;
function RCCVersionText: string;

implementation

function RCCVersionNumber: LongWord;
begin
  Result := 400000;
end;

function RCCVersionText: string;
begin
  Result := RCCVersion;
end;

end.
