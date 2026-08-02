unit rcc_build;

{$mode objfpc}{$H+}

interface

const
  RCCVersion = '1.0.0';
  RCCTargetTriple = 'x86_64-unknown-linux-rcc';
  RCCHostTriple = 'x86_64-unknown-linux-gnu';
  RCCResourceLayoutVersion = '1';
  RCCDefaultPrefix = '/usr/local';
  RCCProjectURL = 'https://github.com/RobertFlexx/rcc';

function RCCVersionNumber: LongWord;
function RCCVersionText: string;

implementation

function RCCVersionNumber: LongWord;
begin
  Result := 100000;
end;

function RCCVersionText: string;
begin
  Result := RCCVersion;
end;

end.
