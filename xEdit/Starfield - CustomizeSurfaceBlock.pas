unit Build2KSurfaceBlock;

function Process(e: IInterface): Integer;
var
  i: Integer;
  fnamElement, entry: IInterface;
  newValues: array[0..675] of Integer;
  noise: Integer;
begin
  Result := 0;

  // Ensure the script is processing a valid SFBK record
  if Signature(e) <> 'SFBK' then begin
    AddMessage('Skipped: ' + Name(e));  // Log if not a valid SFBK
    Exit;
  end;

  // Reconstruct the FNAM (Connections) block in chunks:
  // 0–108  => Small variation around 0 (beachhead-like)
  // 109-330 => Wall footing (30000 with noise)
  // 331-493 => Trough (-30000 with noise)
  // 494-675 => Mound (10000 with noise)
  
  // Chunk 0–108: Small variation around 0 (irregular beachhead)
  // Generates noise values to simulate a small variation around 0, representing a beachhead or irregular terrain.
  for i := 0 to 108 do begin
    noise := RandomRange(-500, 500);  // Random noise in range -500 to 500
    newValues[i] := noise;  // Assign noise value to the current index
  end;

  // 109–330: Wall face (~30k stable with noise)
  // Simulates a more stable wall footing with a base value of 30,000, adding noise for irregularity.
  for i := 109 to 330 do begin
    noise := RandomRange(-250, 250);  // Random noise in range -250 to 250
    newValues[i] := 30000 + noise;  // Wall footing base value of 30,000 with noise
  end;

  // 331–493: Trough (~-30k with noise)
  // Simulates a trough or depression with a base value of -30,000, with noise for variation.
  for i := 331 to 493 do begin
    noise := RandomRange(-500, 500);  // Random noise in range -500 to 500
    newValues[i] := -30000 + noise;  // Trough base value of -30,000 with noise
  end;
  
  // 494–675: Mound (10000 with smooth transition noise)
  // Generates a mound with a base value of 10,000, adding noise to create smooth variations.
  for i := 494 to 675 do begin
    noise := RandomRange(-2000, 2000);  // Random noise in range -2000 to 2000
    newValues[i] := 10000 + noise;  // Mound base value of 10,000 with noise for smooth transition
  end;

  // Replace the FNAM element with the newly generated values
  fnamElement := ElementBySignature(e, 'FNAM');  // Retrieve the FNAM element
  if Assigned(fnamElement) then
    RemoveElement(e, 'FNAM');  // Remove the existing FNAM element if it exists

  fnamElement := Add(e, 'FNAM', True);  // Add a new FNAM element
  for i := 0 to 675 do begin
    entry := ElementAssign(fnamElement, HighInteger, nil, False);  // Assign a new entry in FNAM
    SetEditValue(entry, IntToStr(newValues[i]));  // Set the value for the new entry
  end;

  AddMessage('Rebuilt FNAM - Connections for: ' + Name(e));  // Log completion of the process
end;

end.
