unit ReplaceFirstSetBlockPatternsFromCSV;

//Requires BlockPatterns.CSV (a single row containing desired block pattern IDs)

var
  RandomForms: TStringList;
  StarfieldFile: IInterface;

function Initialize: integer;
var
  CSVFile: TStringList;
  i: integer;
  FormID: string;
begin
  RandomForms := TStringList.Create;
  StarfieldFile := FileByIndex(0); // Cache the file

  // Load FormIDs from BlockPatterns.csv
  CSVFile := TStringList.Create;
  try
    CSVFile.LoadFromFile('BlockPatterns.csv');
    for i := 0 to CSVFile.Count - 1 do begin
      FormID := Trim(CSVFile[i]);
      if Length(FormID) > 0 then
        RandomForms.AddObject('', TObject(StrToInt64('$' + FormID)));
    end;
  finally
    CSVFile.Free;
  end;

  if RandomForms.Count = 0 then begin
    AddMessage('Error: No FormIDs loaded from BlockPatterns.csv');
    Halt;
  end;
  AddMessage('Loaded ' + IntToStr(RandomForms.Count) + ' FormIDs from BlockPatterns.csv');
end;

function GetRandomFormGroup: TList;
var
  StartIndex, GroupSize, i: integer;
begin
  Result := TList.Create;
  StartIndex := Random(RandomForms.Count);
  GroupSize := 3 + Random(3); // Random group size between 3 and 5

  for i := 0 to GroupSize - 1 do begin
    Result.Add(RandomForms.Objects[(StartIndex + i) mod RandomForms.Count]);
  end;
end;

function Process(e: IInterface): integer;
var
  SurfaceData, SurfaceSet, FNAM, FormArrayEntry, NewForm: IInterface;
  i, j, count: integer;
  FormGroup: TList;
  FormIndex: integer;
begin
  if Signature(e) <> 'SFTR' then
    Exit;

  SurfaceData := ElementByPath(e, 'Surface Pattern Data');
  if not Assigned(SurfaceData) then begin
    AddMessage('Surface Pattern Data not found');
    Exit;
  end;

  AddMessage('Found ' + IntToStr(ElementCount(SurfaceData)) + ' Surface Pattern sets.');

  SurfaceSet := ElementByIndex(SurfaceData, 0); // Target the first Surface Pattern set
  FNAM := ElementByIndex(SurfaceSet, 0); // FNAM - Surface Patterns
  if not Assigned(FNAM) then begin
    AddMessage('Warning: FNAM not found');
    Exit;
  end;

  count := ElementCount(FNAM);
  AddMessage('Updating ' + IntToStr(count) + ' entries in FNAM');

  FormGroup := GetRandomFormGroup;
  try
    FormIndex := 0;
    for j := 0 to count - 1 do begin
      FormArrayEntry := ElementByIndex(FNAM, j);
      if Assigned(FormArrayEntry) then begin
        AddMessage('Processing SFPT at [' + IntToStr(j) + ']');
        
        NewForm := RecordByFormID(StarfieldFile, Integer(FormGroup[FormIndex]), False);
        if Assigned(NewForm) then
          SetEditValue(FormArrayEntry, Name(NewForm))
        else
          AddMessage('Warning: Could not resolve FormID at index ' + IntToStr(FormIndex));
          
        Inc(FormIndex);
        if FormIndex >= FormGroup.Count then begin
          FormGroup.Free;
          FormGroup := GetRandomFormGroup;
          FormIndex := 0;
        end;
      end else begin
        AddMessage('Warning: Expected SFPT, found ' + Signature(FormArrayEntry) + ' at [' + IntToStr(j) + '], skipping.');
      end;
    end;
  finally
    FormGroup.Free;
  end;

  AddMessage('All FNAM surface patterns updated in ' + Name(e));
end;

function Finalize: integer;
begin
  RandomForms.Free;
end;

end.
