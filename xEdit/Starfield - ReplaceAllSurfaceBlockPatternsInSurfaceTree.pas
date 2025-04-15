unit ReplaceSurfaceBlockPatternInSurfaceTree;

var
  PluginFile: IInterface;
  PluginIndex, RawFormID, TargetFormID: Cardinal;
  StartIndex, EndIndex: Integer;

function Initialize: integer;
begin
  // === CONFIGURABLE VARIABLES ===
  PluginFile := FileByName('ArkCentral.x.esm');  // your plugin
  RawFormID := $00082E;                         // just the last 6 digits of 02000BCC
  StartIndex := 0;                               // Adjust these to the desired range
  EndIndex := 65535;
  // ===============================

  if not Assigned(PluginFile) then begin
    AddMessage('ERROR: Could not find plugin. Currently set to: <None>');
    Result := 1;
    Exit;
  end
  else begin
    AddMessage('Plugin currently set to: ' + GetFileName(PluginFile));
  end;

  PluginIndex := GetLoadOrder(PluginFile);
  TargetFormID := (PluginIndex shl 24) + RawFormID;

  AddMessage('Replacing with SFPT ' + IntToHex(TargetFormID, 8) + ' from ' + GetFileName(PluginFile));
  Result := 0;
end;

function Process(e: IInterface): integer;
var
  SurfaceData, SurfaceSet, FNAM, FormArrayEntry: IInterface;
  i, j, k, count: Integer;
begin
  if Signature(e) <> 'SFTR' then
    Exit;

  SurfaceData := ElementByPath(e, 'Surface Pattern Data');
  if not Assigned(SurfaceData) then
    Exit;

  for i := 0 to ElementCount(SurfaceData) - 1 do begin
    SurfaceSet := ElementByIndex(SurfaceData, i);

    for j := 0 to ElementCount(SurfaceSet) - 1 do begin
      FNAM := ElementByIndex(SurfaceSet, j);
      if Signature(FNAM) <> 'FNAM' then
        Continue;

      count := ElementCount(FNAM);
      AddMessage('Found ' + IntToStr(count) + ' surface patterns in FNAM[' + IntToStr(j) + '] of SurfaceSet[' + IntToStr(i) + ']');

      for k := StartIndex to EndIndex do begin
        if k >= count then
          Break;

        FormArrayEntry := ElementByIndex(FNAM, k);
        if Assigned(FormArrayEntry) then begin
          SetNativeValue(FormArrayEntry, TargetFormID);
          AddMessage('Set pattern #' + IntToStr(k) + ' to SFPT ' + IntToHex(TargetFormID, 8));
        end;
      end;
    end;
  end;

  Result := 0;
end;

end.
