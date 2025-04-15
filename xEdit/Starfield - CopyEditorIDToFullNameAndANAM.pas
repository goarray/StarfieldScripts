unit CopyEditorIDToFullNameAndANAM;

function Process(e: IInterface): Integer;
var
  i: Integer;
  child, BaseFormComponents, Component, ComponentDataFullName, BDST, ANAMNameRecord: IInterface;
  countComponents: Integer;
  EditorIDValue: String;
  countBDST: Integer;
begin
  if Signature(e) <> 'PNDT' then Exit;

  AddMessage('--- RECORD STRUCTURE: ' + Name(e) + ' ---');
  
  // Get Base Form Components and iterate through them
  BaseFormComponents := ElementByPath(e, 'Base Form Components');
  if Assigned(BaseFormComponents) then begin
    countComponents := ElementCount(BaseFormComponents);
    for i := 0 to countComponents - 1 do begin
      Component := ElementByIndex(BaseFormComponents, i);
      AddMessage('[' + IntToStr(i) + '] ' + Name(Component) + ' (' + Signature(Component) + ')');

      // Look for FULL - Name in the component
      ComponentDataFullName := ElementByPath(Component, 'Component Data - Fullname\FULL - Name');
      if Assigned(ComponentDataFullName) then begin
        // Get EditorID of the current record
        EditorIDValue := GetElementEditValues(e, 'EDID');
        AddMessage('EditorID found: ' + EditorIDValue);

        // Set the Full Name field in the component
        SetEditValue(ComponentDataFullName, EditorIDValue);
        AddMessage('Updated FULL - Name to: ' + EditorIDValue);
      end else begin
        AddMessage('No FULL - Name found in Component ' + Name(Component));
      end;
    end;
  end else begin
    AddMessage('No Base Form Components found in ' + Name(e));
  end;

  // Find the BDST (Body) component
  BDST := ElementByPath(e, 'Body');
  if Assigned(BDST) then begin
    countBDST := ElementCount(BDST);
    AddMessage('Body component contains ' + IntToStr(countBDST) + ' elements.');
    
    // Set ANAM - Name at index 1 of the Body component
    ANAMNameRecord := ElementByIndex(BDST, 1);  // ANAM - Name is at index 1
    if Assigned(ANAMNameRecord) then begin
      AddMessage('ANAM - Name found at Body\1');
      SetEditValue(ANAMNameRecord, EditorIDValue);
      AddMessage('Updated ANAM - Name to: ' + EditorIDValue);
    end else begin
      AddMessage('No ANAM - Name found in Body\1');
    end;
  end else begin
    AddMessage('No BDST (Body) found for ' + Name(e));
  end;

  AddMessage('----------------------------------');
end;

end.
