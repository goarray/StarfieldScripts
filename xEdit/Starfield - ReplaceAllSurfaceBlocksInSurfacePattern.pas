unit ReplaceSurfacePatternBlocks;

var
  TargetFormID: Cardinal;

function Initialize: integer;
begin
  // === CONFIGURABLE VARIABLES ===
  TargetFormID := $0200082F;  // Replacement FormID for Surface Blocks
  // ===============================

  AddMessage('Starting Surface Blocks replacement for selected SFPT record.');
end;

function Process(e: IInterface): integer;
var
  FNAM, Rows, Columns, SurfaceBlock: IInterface;
  i, j: Integer;
begin
  // Only process SFPT records
  if Signature(e) <> 'SFPT' then begin
    AddMessage('Skipping non-SFPT record: ' + Name(e));
    Exit;
  end;

  AddMessage('Processing SFPT: ' + Name(e) + ' [' + IntToHex(GetLoadOrderFormID(e), 8) + ']');

  // Access FNAM - Surface Blocks
  FNAM := ElementByName(e, 'FNAM - Surface Blocks');
  if not Assigned(FNAM) then begin
    AddMessage('ERROR: FNAM - Surface Blocks not found.');
    Exit;
  end;

  // Debug: Log FNAM subrecords
  AddMessage('DEBUG: FNAM subrecords:');
  for i := 0 to ElementCount(FNAM) - 1 do
    AddMessage('  FNAM[' + IntToStr(i) + ']: ' + Name(ElementByIndex(FNAM, i)));

  // Access Rows
  Rows := ElementByName(FNAM, 'Rows');
  if not Assigned(Rows) then begin
    AddMessage('ERROR: Rows not found in FNAM.');
    Exit;
  end;

  // Debug: Log Rows subrecords
  AddMessage('DEBUG: Rows subrecords:');
  for i := 0 to ElementCount(Rows) - 1 do
    AddMessage('  Rows[' + IntToStr(i) + ']: ' + Name(ElementByIndex(Rows, i)));

  // Loop through 16 columns (try as array instead of named Columns #X)
  for i := 0 to 15 do begin
    Columns := ElementByIndex(Rows, i);
    if not Assigned(Columns) then begin
      AddMessage('Warning: Column #' + IntToStr(i) + ' not found.');
      Continue;
    end;

    // Debug: Log Columns subrecords
    AddMessage('DEBUG: Columns #' + IntToStr(i) + ' subrecords:');
    for j := 0 to ElementCount(Columns) - 1 do
      AddMessage('  Columns[' + IntToStr(j) + ']: ' + Name(ElementByIndex(Columns, j)));

    // Loop through 16 Surface Blocks
    for j := 0 to 15 do begin
      SurfaceBlock := ElementByIndex(Columns, j);
      if Assigned(SurfaceBlock) then begin
        // Replace the Surface Block with the target FormID
        try
          SetNativeValue(SurfaceBlock, TargetFormID);
          AddMessage('Replaced Surface Block #' + IntToStr(j) + ' in Column #' + IntToStr(i) + ' with FormID ' + IntToHex(TargetFormID, 8));
        except
          on E: Exception do
            AddMessage('ERROR: Failed to replace Surface Block #' + IntToStr(j) + ' in Column #' + IntToStr(i) + ': ' + E.Message);
        end;
      end else begin
        AddMessage('Warning: Surface Block #' + IntToStr(j) + ' in Column #' + IntToStr(i) + ' not found.');
      end;
    end;
  end;

  AddMessage('Surface Blocks replacement complete for SFPT ' + Name(e));
  Result := 0;
end;

end.
