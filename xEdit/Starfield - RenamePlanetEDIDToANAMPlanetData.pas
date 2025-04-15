unit RenamePlanetEDIDToANAMPlanetData;

function Initialize: Integer;
begin
end;

function Process(e: IInterface): Integer;
var
  ANAMName, NewEDID, OldEDID: string;
begin
  if Signature(e) <> 'PNDT' then
    Exit;

  ANAMName := GetElementEditValues(e, 'Body\ANAM');
  if ANAMName = '' then begin
    AddMessage('Skipping ' + Name(e) + ': Empty ANAM');
    Exit;
  end;

  ANAMName := StringReplace(ANAMName, ' ', '', [rfReplaceAll]);
  NewEDID := ANAMName + 'PlanetData';

  OldEDID := GetElementEditValues(e, 'EDID');
  SetElementEditValues(e, 'EDID', NewEDID);
  AddMessage('Renamed ' + OldEDID + ' ? ' + NewEDID);
end;

function Finalize: Integer;
begin
end;

end.
