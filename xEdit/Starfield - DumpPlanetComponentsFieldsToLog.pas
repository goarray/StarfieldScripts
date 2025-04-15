unit DumpPlanetComponentsFieldsToLog;

var
  PlanetNameBase: string;
  PlanetIndex: Integer;
  eRecord, BaseFormComponents, Component, ComponentData: IInterface;
  countComponents: Integer;

procedure ProcessSubrecords(e: IInterface; level: Integer);
var
  i: Integer;
  child: IInterface;
  fieldName, fieldSignature, fieldValue, indent: string;
begin
  indent := StringOfChar(' ', level * 2);

  // Iterate through all elements (subrecords) in the selected record
  for i := 0 to ElementCount(e) - 1 do begin
    child := ElementByIndex(e, i);
    fieldName := Name(child);  // Get the name of the subrecord
    fieldSignature := Signature(child);  // Get the signature of the subrecord
    
    // Attempt to retrieve the field value (for known field types)
    fieldValue := GetEditValue(child);
    
    // If value is not available, just show the field signature
    if fieldValue = '' then
      fieldValue := 'No value or non-editable field';
    
    // Output detailed information to the log window
    AddMessage(Format('%s[%d] %s (%s): %s', [indent, i, fieldName, fieldSignature, fieldValue]));

    // Look for specific components (like Base Form Components)
    if fieldSignature = 'GRUP' then begin
      // Recursively process nested subrecords if it's a group record (e.g., Base Form Components)
      ProcessSubrecords(child, level + 1);
    end;

    // Check for specific component paths to identify component data like "Component Data - DATA"
    if fieldSignature = 'DATA' then begin
      // Look deeper into the component data
      ComponentData := ElementByPath(child, 'DATA - Data');
      if Assigned(ComponentData) then begin
        AddMessage(Format('%sFound DATA - Data at %s', [indent, fieldName]));
      end;

      // Check for additional component data like Mass or Catalogue ID
      if fieldName = 'Mass' then begin
        AddMessage(Format('%sFound Mass in %s', [indent, fieldName]));
      end;
      if fieldName = 'Catalogue ID' then begin
        AddMessage(Format('%sFound Catalogue ID in %s', [indent, fieldName]));
      end;
    end;

    // Further checks for other components or specific subfields if needed
    if fieldName = 'Component Data - Planet Model' then begin
      AddMessage(Format('%sFound Planet Model: %s', [indent, fieldName]));
    end;
  end;
end;

function Process(e: IInterface): Integer;
begin
  // Set the base name for the planets
  PlanetNameBase := 'Barren_';
  PlanetIndex := 0;  // Initialize the index for planets

  // Output the name and signature of the selected record
  AddMessage('--- RECORD STRUCTURE: ' + Name(e) + ' (' + Signature(e) + ') ---');

  // Get Base Form Components
  BaseFormComponents := ElementByPath(e, 'Base Form Components');
  if Assigned(BaseFormComponents) then begin
    countComponents := ElementCount(BaseFormComponents);
    for PlanetIndex := 0 to countComponents - 1 do begin
      Component := ElementByIndex(BaseFormComponents, PlanetIndex);
      if Assigned(Component) then begin
        // Process each component's sub-records
        ProcessSubrecords(Component, 1);
      end;
    end;
  end;

  AddMessage('----------------------------------');
end;

end.
