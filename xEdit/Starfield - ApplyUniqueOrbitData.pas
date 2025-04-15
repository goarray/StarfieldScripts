unit ApplyUniqueOrbitData;

var
  PlanetID: Integer;

// Random float generator function
function RandomFloat(min, max: Double): Double;
var
  scale: Integer;
begin
  scale := 10000;  // simulate float precision
  Result := min + (Random(scale) / scale) * (max - min);
end;

function Process(e: IInterface): integer;
var
  Body, OrbitalData, HNAM: IInterface;
  MajorAxis, Eccentricity, MinorAxis, Aphelion, Perihelion, AxialTilt: Double;
begin
  if Signature(e) <> 'PNDT' then exit;

  Body := ElementByPath(e, 'Body');
  if not Assigned(Body) then begin
    AddMessage('ERROR: Could not find Body section for ' + Name(e));
    exit;
  end;

  OrbitalData := ElementByPath(Body, 'ENAM - Orbital Data');
  if not Assigned(OrbitalData) then begin
    AddMessage('ERROR: Could not find Orbital Data for ' + Name(e));
    exit;
  end;

  MajorAxis := StrToFloat(GetEditValue(ElementByPath(OrbitalData, 'Major Axis')));

  Eccentricity := RandomFloat(0.001, 0.5);
  MinorAxis := MajorAxis * Sqrt(1 - Eccentricity * Eccentricity);
  Aphelion := MajorAxis * (1 + Eccentricity);
  Perihelion := MajorAxis * (1 - Eccentricity);
  AxialTilt := RandomFloat(0.001, 60);

  SetEditValue(ElementByPath(OrbitalData, 'Eccentricity'), FloatToStr(Eccentricity));
  SetEditValue(ElementByPath(OrbitalData, 'Minor Axis'), FloatToStr(MinorAxis));
  SetEditValue(ElementByPath(OrbitalData, 'Aphelion'), FloatToStr(Aphelion));
  SetEditValue(ElementByPath(OrbitalData, 'Axial Tilt'), FloatToStr(AxialTilt));

  // Write Perihelion to HNAM
  HNAM := ElementByPath(Body, 'HNAM - Unknown');
  if Assigned(HNAM) then
    SetEditValue(ElementByPath(HNAM, 'Perihelion'), FloatToStr(Perihelion))
  else
    AddMessage('WARNING: Could not find HNAM block for ' + Name(e));

  AddMessage('Updated ' + Name(e) + ' with new orbit data:');
  AddMessage('Major Axis: ' + FloatToStr(MajorAxis) + ', Eccentricity: ' + FloatToStr(Eccentricity) +
             ', Minor Axis: ' + FloatToStr(MinorAxis) + ', Aphelion: ' + FloatToStr(Aphelion) +
             ', Perihelion: ' + FloatToStr(Perihelion) + ', Axial Tilt: ' + FloatToStr(AxialTilt));

  Result := 0;
end;

function Initialize: Integer;
begin
  PlanetID := 50;
  Result := 0;
end;

end.
