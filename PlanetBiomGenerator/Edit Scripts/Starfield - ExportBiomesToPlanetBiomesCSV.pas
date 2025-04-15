unit ExportPlanetBiomes;

var
  sl: TStringList;

function Process(e: IInterface): Integer;
var
  planetName, biomeFormID, biomeEDID: string;
  biomes, biomeEntry, biomeRef, biomRec: IInterface;
  i: Integer;
begin
  Result := 0;

  // Get planet name (EditorID)
  planetName := GetElementEditValues(e, 'EDID');

  // Get Biomes array
  biomes := ElementByPath(e, 'Biomes');

  if not Assigned(biomes) or (ElementCount(biomes) = 0) then begin
    sl.Add(Format('%s,%s,%s', [planetName, '0017B861', '']));
    Exit;
  end;

  // Loop through biome entries
  for i := 0 to ElementCount(biomes) - 1 do begin
    biomeEntry := ElementByIndex(biomes, i);
    biomeRef := LinksTo(ElementByIndex(biomeEntry, 0)); // Get actual BIOM record

    if Assigned(biomeRef) then begin
      biomeFormID := IntToHex(FormID(biomeRef), 8);
      biomeEDID := GetElementEditValues(biomeRef, 'EDID');
    end else begin
      biomeFormID := '00000000';
      biomeEDID := '';
    end;

    sl.Add(Format('%s,%s,%s', [planetName, biomeFormID, biomeEDID]));
  end;
end;

function Initialize: Integer;
begin
  sl := TStringList.Create;
  sl.Add('PlanetName,BIOM_FormID,BIOM_EditorID');  // CSV header
end;

function Finalize: Integer;
begin
  sl.SaveToFile(ProgramPath + 'PlanetBiomes.csv');
  sl.Free;
end;

end.
