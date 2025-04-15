unit ReplaceSurfaceBlockPatternInSurfaceTree;

var
  PluginFile: IInterface;
  PluginIndex, RawFormID, TargetFormID: Cardinal;
  StartIndex, EndIndex: Integer;

function Initialize: integer;
begin

  // === CONFIGURABLE VARIABLES ===
  PluginFile := FileByName('ArkCentral.x.esm');  // change to your plugin
  RawFormID := $00082E;                          // excluding the plugin ID, e.g., 000123
  StartIndex := 0;
  EndIndex := 65535;
  // ===============================

  if not Assigned(PluginFile) then begin
    AddMessage('ERROR: Could not find plugin.');
    Result := 1;
    Exit;
  end;

  PluginIndex := GetLoadOrder(PluginFile);
  TargetFormID := (PluginIndex shl 24) + RawFormID;

  AddMessage('Replacing with SFPT ' + IntToHex(TargetFormID, 8) + ' from ' + GetFileName(PluginFile));
end;

function Process(e: IInterface): integer;
var
  SurfaceData, SurfaceSet, FNAM, FormArrayEntry: IInterface;
  i, j, k, count: Integer;
begin
  if Signature(e) <> 'SFTR' then begin
    AddMessage('ERROR: Record is not a SFTR record.');
    Exit;
  end;

  SurfaceData := ElementByPath(e, 'Surface Pattern Data');
  if not Assigned(SurfaceData) then
    Exit;

  for i := 0 to ElementCount(SurfaceData) - 1 do begin
    SurfaceSet := ElementByIndex(SurfaceData, i);

    // Target both SurfaceSet[0] and SurfaceSet[1]
    for j := 0 to 1 do begin
      // Ensure we're targeting only FNAM, not GNAM
      FNAM := ElementByPath(SurfaceSet, 'FNAM');  // Explicitly target FNAM
      if not Assigned(FNAM) then
        Continue;

      count := ElementCount(FNAM);
      AddMessage('Found ' + IntToStr(count) + ' surface patterns at SurfaceSet index ' + IntToStr(j));

      // Modify this part to replace every 5th surface pattern
      for k := StartIndex to EndIndex do begin
        if k >= count then
          Break;

        // Replace only every 5th entry
        if (k - StartIndex) mod 10 = 0 then begin
          FormArrayEntry := ElementByIndex(FNAM, k);
          if Assigned(FormArrayEntry) then begin
            SetNativeValue(FormArrayEntry, TargetFormID);
            AddMessage('Set pattern #' + IntToStr(k) + ' to SFPT ' + IntToHex(TargetFormID, 8));
          end;
        end;
      end;
    end;
  end;
end;

end.
