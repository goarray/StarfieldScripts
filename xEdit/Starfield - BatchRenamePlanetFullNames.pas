unit BatchRenamePlanetFullNames;

var
  PlanetNameBase: string;
  eRecord, Component, ComponentDataFullName: IInterface;
  BaseFormComponents: IInterface;
  i, ComponentIndex, CountComponents: Integer;
  GlobalIndex: Integer;

function Initialize: Integer;
begin
  PlanetNameBase := 'Barren_';
  GlobalIndex := 0;

  for i := 0 to RecordCount(FileByLoadOrder(2)) - 1 do begin
    eRecord := RecordByIndex(FileByLoadOrder(2), i);

    if not Assigned(eRecord) or (Signature(eRecord) <> 'PNDT') then Continue;

    BaseFormComponents := ElementByPath(eRecord, 'Base Form Components');
    if not Assigned(BaseFormComponents) then Continue;

    CountComponents := ElementCount(BaseFormComponents);

    for ComponentIndex := 0 to CountComponents - 1 do begin
      Component := ElementByIndex(BaseFormComponents, ComponentIndex);
      if not Assigned(Component) then Continue;

      ComponentDataFullName := ElementByPath(Component, 'Component Data - Fullname\FULL - Name');
      if Assigned(ComponentDataFullName) then begin
        SetEditValue(ComponentDataFullName, PlanetNameBase + Format('%.2d', [GlobalIndex]));
        AddMessage('Renamed component to: ' + PlanetNameBase + Format('%.2d', [GlobalIndex]) + ' in ' + Name(eRecord));
        Inc(GlobalIndex);
      end;
    end;
  end;

  Result := 0;
end;

end.
