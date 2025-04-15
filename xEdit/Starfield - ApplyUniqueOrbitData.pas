unit ApplyUniqueOrbitData;

var
  PlanetID: Integer;
  
  // Random float generator function
function RandomFloat(min, max: Double): Double;
var
  scale: Integer;
begin
  // Scale up to 10000 to simulate float precision
  scale := 10000;
  Result := min + (Random(scale) / scale) * (max - min);
end;

function Process(e: IInterface): integer;
var
  Body, OrbitalData, PlanetElement: IInterface;
  MajorAxis, Eccentricity, MinorAxis, Aphelion, AxialTilt: Double;
begin
  if Signature(e) <> 'PNDT' then exit;  // Check for Planet Data record

  // Get Body structure
  Body := ElementByPath(e, 'Body');
  if not Assigned(Body) then begin
    AddMessage('ERROR: Could not find Body section for ' + Name(e));
    exit;
  end;

  // Get Orbital Data structure
  OrbitalData := ElementByPath(Body, 'ENAM - Orbital Data');
  if not Assigned(OrbitalData) then begin
    AddMessage('ERROR: Could not find Orbital Data for ' + Name(e));
    exit;
  end;

  // Get Major Axis value
  MajorAxis := StrToFloat(GetEditValue(ElementByPath(OrbitalData, 'Major Axis')));

  // Generate a random Eccentricity (between 0.001 and 0.5)
  Eccentricity := RandomFloat(0.001, 0.5);

  // Calculate Minor Axis based on Major Axis and Eccentricity
  MinorAxis := MajorAxis * Sqrt(1 - Eccentricity * Eccentricity);

  // Calculate Aphelion (Major Axis * (1 + Eccentricity))
  Aphelion := MajorAxis * (1 + Eccentricity);

  // Generate a random Axial Tilt (between 0.001 and 60 degrees)
  AxialTilt := RandomFloat(0.001, 60);

  // Set the new values in the Orbital Data structure
  SetEditValue(ElementByPath(OrbitalData, 'Eccentricity'), FloatToStr(Eccentricity));
  SetEditValue(ElementByPath(OrbitalData, 'Minor Axis'), FloatToStr(MinorAxis));
  SetEditValue(ElementByPath(OrbitalData, 'Aphelion'), FloatToStr(Aphelion));
  SetEditValue(ElementByPath(OrbitalData, 'Axial Tilt'), FloatToStr(AxialTilt));

  // Output the updated values for debugging
  AddMessage('Updated ' + Name(e) + ' with new orbit data:');
  AddMessage('Major Axis: ' + FloatToStr(MajorAxis) + ', Eccentricity: ' + FloatToStr(Eccentricity) + 
             ', Minor Axis: ' + FloatToStr(MinorAxis) + ', Aphelion: ' + FloatToStr(Aphelion) + 
             ', Axial Tilt: ' + FloatToStr(AxialTilt));

  Result := 0;
end;

function Initialize: Integer;
begin
  PlanetID := 50;  // Start at 50
  Result := 0;
end;

end.
