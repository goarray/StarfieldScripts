unit FormID_EDID_Dump;

//Exports the FormID and EditorID of selected records to FormID_EDID_Dump.csv

var
  sl: TStringList;

function Initialize: Integer;
begin
  sl := TStringList.Create;
  sl.Add('FormID,EditorID');
  Result := 0;
end;

// Always returns full 8-digit hex FormID, including load order
function PaddedFormID(e: IInterface): string;
begin
  Result := IntToHex(FixedFormID(e), 8);
end;

function Process(e: IInterface): Integer;
var
  formIDStr, edid: string;
begin
  formIDStr := PaddedFormID(e);
  edid := GetElementEditValues(e, 'EDID - Editor ID');
  if edid = '' then edid := 'None';

  sl.Add(formIDStr + ',' + edid);
  Result := 0;
end;

function Finalize: Integer;
begin
  sl.SaveToFile(ProgramPath + 'FormID_EDID_Dump.csv');
  AddMessage('>> Dump complete. Output saved to FormID_EDID_Dump.csv');
  sl.Free;
  Result := 0;
end;

end.
