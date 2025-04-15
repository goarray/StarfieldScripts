unit ExtractSubRecordsFromForm;

var
  csvLines: TStringList;

procedure ProcessSubrecords(e: IInterface; level: Integer; path: string);
var
  i: Integer;
  child: IInterface;
  fieldName, fieldSignature, fieldValue: string;
  csvEntry: string;
begin
  if ElementCount(e) = 0 then Exit;

  for i := 0 to ElementCount(e) - 1 do begin
    child := ElementByIndex(e, i);
    if not Assigned(child) then Continue;

    fieldName := Name(child);
    fieldSignature := Signature(child);

    // Skip any subrecord with PCCC signature
    if fieldSignature = 'PCCC' then Continue;

    if (fieldSignature = '') or (Length(fieldSignature) > 4) then
      fieldSignature := 'Unknown';

    try
      fieldValue := GetEditValue(child);
    except
      fieldValue := 'No value or non-editable field';
    end;

    // Build CSV row: Combine previous path with new field name
    csvEntry := path + ',' + fieldName + ',' + fieldSignature + ',' + fieldValue;
    csvLines.Add(csvEntry);

    // Recursively process subrecords with updated path
    if ElementCount(child) > 0 then
      ProcessSubrecords(child, level + 1, path + ',' + fieldName);
  end;
end;

function GetRecordIdentifier(e: IInterface): string;
var
  sig, edid, formID: string;
begin
  sig := Signature(e);
  edid := GetEditValue(ElementByPath(e, 'EDID'));
  formID := IntToHex(GetLoadOrderFormID(e), 8);

  if edid = '' then
    edid := formID;

  Result := sig + '_' + edid;
end;

function Process(e: IInterface): Integer;
var
  filePath, recordID: string;
begin
  csvLines := TStringList.Create;
  try
    // Add CSV Header
    csvLines.Add('Root,Subrecord1,Subrecord2,Field Name,Signature,Value');

    // Start Recursive Processing
    ProcessSubrecords(e, 1, Name(e));

    // Define file path using record ID
    recordID := GetRecordIdentifier(e);
    filePath := ProgramPath + recordID + '_Extracted.csv';

    csvLines.SaveToFile(filePath);

    AddMessage('CSV Output Saved: ' + filePath);
  finally
    csvLines.Free;
  end;
end;

end.
