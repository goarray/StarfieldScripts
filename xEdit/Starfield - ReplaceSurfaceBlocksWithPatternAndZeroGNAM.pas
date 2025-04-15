unit ReplaceSurfaceBlocksWithPatternAndZeroGNAM;

var
  StarfieldFile: IInterface;
  SurfaceBlockFormID: Cardinal;

function Initialize: integer;
begin
  StarfieldFile := FileByIndex(0);
  SurfaceBlockFormID := $00082F; // Replace with your actual FormID
  AddMessage('Surface Block FormID set to: ' + IntToHex(SurfaceBlockFormID, 8));
end;

function Process(e: IInterface): integer;
var
  FNAM, GNAM, Rows, Columns, SurfaceBlock: IInterface;
  i, j, rowCount, columnCount: Integer;
begin
  if Signature(e) <> 'SFPT' then
    Exit;

  AddMessage('Inspecting SFPT form: ' + Name(e));
  
  // Debug the full structure
  for i := 0 to ElementCount(e) - 1 do begin
    AddMessage('Element ' + IntToStr(i) + ': ' + Name(ElementByIndex(e, i)));
  end;

  // --- Handle FNAM - Surface Blocks ---
  FNAM := ElementByPath(e, 'FNAM - Surface Blocks');
  if not Assigned(FNAM) then begin
    AddMessage('FNAM - Surface Blocks not found in ' + Name(e));
  end else begin
    Rows := ElementByPath(FNAM, 'Rows');
    if not Assigned(Rows) then begin
      AddMessage('Rows not found under FNAM - Surface Blocks');
    end else begin
      rowCount := ElementCount(Rows);
      AddMessage('Found ' + IntToStr(rowCount) + ' rows under FNAM - Surface Blocks');

      for i := 0 to rowCount - 1 do begin
        Columns := ElementByIndex(Rows, i);
        if not Assigned(Columns) then begin
          AddMessage('Columns not found at FNAM row [' + IntToStr(i) + ']');
          Continue;
        end;

        columnCount := ElementCount(Columns);
        AddMessage('FNAM Row [' + IntToStr(i) + '] has ' + IntToStr(columnCount) + ' columns');

        for j := 0 to columnCount - 1 do begin
          SurfaceBlock := ElementByIndex(Columns, j);
          if Assigned(SurfaceBlock) and (GetNativeValue(SurfaceBlock) <> 0) then begin
            AddMessage('Replacing FNAM Surface Block at [Row ' + IntToStr(i) + ', Column ' + IntToStr(j) + '], FormID: ' + IntToHex(GetNativeValue(SurfaceBlock), 8));
            SetNativeValue(SurfaceBlock, SurfaceBlockFormID);
          end;
        end;
      end;
    end;
  end;

  // --- Handle GNAM - Surface Blocks ---
  GNAM := ElementByPath(e, 'GNAM - Surface Blocks');
  if not Assigned(GNAM) then begin
    AddMessage('GNAM - Surface Blocks not found in ' + Name(e));
  end else begin
    Rows := ElementByPath(GNAM, 'Rows');
    if not Assigned(Rows) then begin
      AddMessage('Rows not found under GNAM - Surface Blocks');
    end else begin
      rowCount := ElementCount(Rows);
      AddMessage('Found ' + IntToStr(rowCount) + ' rows under GNAM - Surface Blocks');

      for i := 0 to rowCount - 1 do begin
        Columns := ElementByIndex(Rows, i);
        if not Assigned(Columns) then begin
          AddMessage('Columns not found at GNAM row [' + IntToStr(i) + ']');
          Continue;
        end;

        columnCount := ElementCount(Columns);
        AddMessage('GNAM Row [' + IntToStr(i) + '] has ' + IntToStr(columnCount) + ' columns');

        for j := 0 to columnCount - 1 do begin
          SurfaceBlock := ElementByIndex(Columns, j);
          if Assigned(SurfaceBlock) and (GetNativeValue(SurfaceBlock) <> 0) then begin
            AddMessage('Setting GNAM Surface Block at [Row ' + IntToStr(i) + ', Column ' + IntToStr(j) + '] to 0, Previous Value: ' + IntToStr(GetNativeValue(SurfaceBlock)));
            SetNativeValue(SurfaceBlock, 0);
          end;
        end;
      end;
    end;
  end;

  AddMessage('Processing complete for ' + Name(e));
  Result := 1;
end;

end.
