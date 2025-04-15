unit AddFaunaFromCSVs;

//Requires critters_predators.csv, critters_prey.csv and critters_generic.csv

var
  Predators, Prey, Critters: TStringList;  // Lists to store FormIDs of predators, prey, and critters

// Function to load a CSV file and return a list of FormIDs
function LoadCSV(FileName: string): TStringList;
var
  Lines, Parts: TStringList;
  i: Integer;
begin
  Result := TStringList.Create;  // Initialize the result list
  Lines := TStringList.Create;  // List to hold lines from the CSV
  Parts := TStringList.Create;  // List to hold split values from each line
  try
    // Load the CSV file into Lines
    Lines.LoadFromFile(ProgramPath + FileName);
    
    // Iterate through each line in the CSV (skip the header)
    for i := 1 to Lines.Count - 1 do begin
      Parts.Delimiter := ',';  // Set delimiter to comma
      Parts.DelimitedText := Lines[i];  // Split the line by the delimiter
      if Parts.Count > 0 then
        Result.Add(Trim(Parts[0]));  // Add the FormID (first column) to the result list
    end;
  finally
    Lines.Free;  // Free resources
    Parts.Free;
  end;
end;

// Function to pick a random FormID from a list and resolve it to an in-game record
function PickRandomRecord(FormIDList: TStringList): IInterface;
var
  HexID: string;
  ID: Cardinal;
  i: Integer;
begin
  Result := nil;
  if FormIDList.Count = 0 then begin
    AddMessage('FormID list is empty');  // Log if the list is empty
    Exit;
  end;
  
  // Pick a random FormID from the list
  HexID := FormIDList[Random(FormIDList.Count)];
  ID := StrToInt64('$' + HexID);  // Convert the FormID to a numeric ID
  
  // Try to resolve the FormID by searching through all loaded files
  for i := 0 to FileCount - 1 do begin
    Result := RecordByFormID(FileByIndex(i), ID, True);  // Look for the record by FormID
    if Assigned(Result) then begin
      AddMessage('Resolved FormID ' + HexID + ' to ' + Name(Result));  // Log the result
      Exit;
    end;
  end;
  
  // If we couldn't resolve the FormID, log an error
  AddMessage('Failed to resolve FormID: ' + HexID);
end;

// Procedure to add a new fauna entry to a Fauna list
procedure AddFaunaEntry(FaunaList: IInterface; Rec: IInterface);
var
  Entry: IInterface;
  j: Integer;
begin
  if not Assigned(Rec) then begin
    AddMessage('No record provided for Fauna entry');  // Log if the record is not assigned
    Exit;
  end;

  // Debug: Log the structure of the Fauna list
  AddMessage('FaunaList sub-elements:');
  for j := 0 to ElementCount(FaunaList) - 1 do
    AddMessage('  FaunaList sub-element ' + IntToStr(j) + ': ' + Name(ElementByIndex(FaunaList, j)));

  // Create a new Fauna entry at the end of the Fauna list
  Entry := ElementAssign(FaunaList, HighInteger, nil, False);
  if not Assigned(Entry) then begin
    AddMessage('Failed to create new Fauna entry');  // Log if creation fails
    Exit;
  end;
  AddMessage('Created new Fauna entry: ' + Name(Entry));

  // Debug: Show the sub-elements of the newly created Fauna entry
  AddMessage('Fauna entry sub-elements:');
  for j := 0 to ElementCount(Entry) - 1 do
    AddMessage('  Sub-element ' + IntToStr(j) + ': ' + Name(ElementByIndex(Entry, j)));

  // If the entry has no sub-elements (leaf node), directly set the FormID value
  if ElementCount(Entry) = 0 then begin
    SetEditValue(Entry, IntToHex(GetLoadOrderFormID(Rec), 8));  // Set FormID as a hex string
    AddMessage('Directly set FormID on Fauna entry: ' + IntToHex(GetLoadOrderFormID(Rec), 8));
  end else begin
    // Fallback in case future versions have sub-elements:
    SetEditValue(ElementByIndex(Entry, 0), IntToHex(GetLoadOrderFormID(Rec), 8));
    AddMessage('Assigned FormID via subelement to Fauna entry: ' + IntToHex(GetLoadOrderFormID(Rec), 8));
  end;
end;

// Procedure to add 9 entries (3 Predators, 3 Prey, 3 Critters) to a Fauna list
procedure AddFaunaEntries(FaunaList: IInterface);
var
  j: Integer;
begin
  // Add 3 predators to the Fauna list
  for j := 0 to 2 do
    AddFaunaEntry(FaunaList, PickRandomRecord(Predators));
  
  // Add 3 prey to the Fauna list
  for j := 0 to 2 do
    AddFaunaEntry(FaunaList, PickRandomRecord(Prey));
  
  // Add 3 critters to the Fauna list
  for j := 0 to 2 do
    AddFaunaEntry(FaunaList, PickRandomRecord(Critters));
end;

// Main processing function that adds fauna entries to biomes
function Process(e: IInterface): Integer;
var
  Biomes, Biome, FaunaList, OldFauna: IInterface;
  i, j: Integer;
begin
  Result := 0;

  // Load the CSV files for predators, prey, and critters
  Predators := LoadCSV('critters_predator.csv');
  Prey := LoadCSV('critters_prey.csv');
  Critters := LoadCSV('critters_generic.csv');

  // Log warnings if any lists are empty
  if Predators.Count = 0 then AddMessage('Warning: No predators loaded');
  if Prey.Count = 0 then AddMessage('Warning: No prey loaded');
  if Critters.Count = 0 then AddMessage('Warning: No critters loaded');

  // Get the 'Biomes' element from the provided record (e)
  Biomes := ElementByPath(e, 'Biomes');
  if not Assigned(Biomes) then begin
    AddMessage('No Biomes found in record: ' + Name(e));  // Log if no biomes are found
    Exit;
  end;

  // Iterate through each biome in the Biomes list
  for i := 0 to ElementCount(Biomes) - 1 do begin
    Biome := ElementByIndex(Biomes, i);
    AddMessage('Processing biome ' + IntToStr(i) + ': ' + Name(Biome));

    // Debug: Log the sub-elements of the biome
    AddMessage('Biome sub-elements:');
    for j := 0 to ElementCount(Biome) - 1 do
      AddMessage('  ' + Name(ElementByIndex(Biome, j)));

    // Check for an existing 'Fauna' list
    OldFauna := ElementByName(Biome, 'Fauna');
    if Assigned(OldFauna) then begin
      AddMessage('Found existing Fauna element');
      // Clear existing fauna entries
      while ElementCount(OldFauna) > 0 do
        RemoveElement(OldFauna, 0);
      FaunaList := OldFauna;
    end else begin
      // Create a new Fauna list if none exists
      FaunaList := Add(Biome, 'Fauna', True);
      if not Assigned(FaunaList) then begin
        AddMessage('Failed to create Fauna list in biome ' + IntToStr(i));
        FaunaList := ElementAssign(Biome, HighInteger, nil, False);
        if Assigned(FaunaList) then
          SetElementEditValues(FaunaList, 'Signature', 'Fauna');
        if not Assigned(FaunaList) then begin
          AddMessage('Also failed to create Fauna with ElementAssign. Skipping biome ' + IntToStr(i));
          Continue;
        end;
      end;
    end;

    // Add random fauna entries to the Fauna list
    AddFaunaEntries(FaunaList);
    AddMessage('Successfully processed fauna in biome ' + IntToStr(i));
  end;

  // Free the CSV lists after processing
  Predators.Free;
  Prey.Free;
  Critters.Free;
end;

end.
